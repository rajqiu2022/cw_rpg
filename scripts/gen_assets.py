"""
gen_assets.py — GPT Image 2 批量异步生成器

读取 prompts/tasks.yaml，对每个任务加载模板、渲染变量、调 OpenAI gpt-image-2，
落盘原图 + 元数据。内置预算硬上限、并发限流、失败重试。

用法：
    python scripts/gen_assets.py                 # 跑全部任务
    python scripts/gen_assets.py --priority 1    # 仅跑 priority=1
    python scripts/gen_assets.py --task portrait_bujingyun_neutral
    python scripts/gen_assets.py --dry-run       # 只渲染 prompt，不调 API
    python scripts/gen_assets.py --budget 20     # 临时设预算上限
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# On Windows the default console codepage is often GBK / cp936 which cannot
# encode many of the characters Rich uses (Chinese text + the occasional
# Unicode symbol). Force stdout/stderr to UTF-8 so the script runs cleanly
# in any PowerShell / cmd / Cursor terminal.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

import yaml
from dotenv import load_dotenv
from openai import AsyncOpenAI, APIError, BadRequestError, RateLimitError
from rich.console import Console
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TextColumn,
    TimeElapsedColumn,
)
from rich.table import Table

PROJECT_ROOT = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = PROJECT_ROOT / "prompts" / "templates"
TASKS_FILE = PROJECT_ROOT / "prompts" / "tasks.yaml"
SHARED_FILE = TEMPLATES_DIR / "_shared.yaml"
FAILED_LOG = PROJECT_ROOT / "logs" / "failed.log"

console = Console()


# ---------------------------------------------------------------------------
# GPT Image 2 价格（USD），来自 OpenAI 官方 2026-04-21 发布信息
# 1024x1024 价格作为默认估算依据；其它尺寸用 token 公式更准
# ---------------------------------------------------------------------------
PRICE_PER_IMAGE = {
    # (size, quality) -> usd
    ("1024x1024", "low"): 0.006,
    ("1024x1024", "medium"): 0.053,
    ("1024x1024", "high"): 0.211,
    ("1024x1536", "low"): 0.005,
    ("1024x1536", "medium"): 0.041,
    ("1024x1536", "high"): 0.165,
    ("1536x1024", "low"): 0.005,
    ("1536x1024", "medium"): 0.041,
    ("1536x1024", "high"): 0.165,
}

# Token 单价（USD per 1M）— 当响应包含 usage 时优先用此换算
TEXT_INPUT_PER_M = 5.0
IMAGE_INPUT_PER_M = 8.0
IMAGE_OUTPUT_PER_M = 30.0


def estimate_cost_from_size_quality(size: str, quality: str) -> float:
    """根据 size + quality 估算单张成本（fallback）"""
    return PRICE_PER_IMAGE.get((size, quality), 0.053)


def cost_from_usage(usage: Any | None) -> float:
    """如果响应带 usage，更准确换算"""
    if not usage:
        return 0.0
    try:
        usage_dict = usage if isinstance(usage, dict) else usage.model_dump()
    except AttributeError:
        return 0.0
    text_in = usage_dict.get("input_tokens_details", {}).get("text_tokens", 0)
    image_in = usage_dict.get("input_tokens_details", {}).get("image_tokens", 0)
    image_out = usage_dict.get("output_tokens", 0)
    return (
        text_in * TEXT_INPUT_PER_M / 1_000_000
        + image_in * IMAGE_INPUT_PER_M / 1_000_000
        + image_out * IMAGE_OUTPUT_PER_M / 1_000_000
    )


# ---------------------------------------------------------------------------
# Prompt 渲染
# ---------------------------------------------------------------------------
def load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def render_template(template_name: str, vars_: dict, shared: dict) -> dict:
    """
    加载模板，渲染 prompt_template，返回完整 spec：
        {
            "prompt": "...",
            "size": "1024x1024",
            "quality": "medium",
            "reference_images": [Path, ...],
            "background": "opaque",
        }
    """
    template_path = TEMPLATES_DIR / f"{template_name}.yaml"
    if not template_path.exists():
        raise FileNotFoundError(f"模板不存在：{template_path}")
    tpl = load_yaml(template_path)

    style_anchor = shared.get("style_anchor", "").strip()
    negative = shared.get("negative", "").strip()
    defaults = shared.get("defaults", {})

    # 先合并 vars 到 identity_anchor
    identity_raw = tpl.get("identity_anchor", "")
    identity_rendered = _safe_format(identity_raw, vars_)

    # 再渲染 prompt_template
    prompt_template = tpl.get("prompt_template", "")
    full_vars = {
        **vars_,
        "style_anchor": style_anchor,
        "identity_anchor": identity_rendered,
        "negative": negative,
    }
    prompt = _safe_format(prompt_template, full_vars)

    # 解析 reference 图片为绝对路径
    refs: list[Path] = []
    for r in tpl.get("reference_images", []) or []:
        p = (PROJECT_ROOT / r).resolve()
        if p.exists():
            refs.append(p)
        else:
            console.print(
                f"  [yellow][warn] 参考图缺失：{p}（跳过该参考）[/yellow]"
            )

    return {
        "prompt": prompt.strip(),
        "size": tpl.get("size") or defaults.get("size", "1024x1024"),
        "quality": tpl.get("quality") or defaults.get("quality", "medium"),
        "background": tpl.get("background") or defaults.get("background", "opaque"),
        "reference_images": refs,
    }


def _safe_format(template: str, vars_: dict) -> str:
    """
    支持 {var} 和 {{var}} 两种占位符。
    {{var}} 是模板内显式标注的"变量位"；{var} 用于注入 style/identity/negative。
    """
    out = template
    # 先处理 {{var}}
    for k, v in vars_.items():
        out = out.replace("{{" + k + "}}", str(v))
    # 再处理 {var}
    for k, v in vars_.items():
        out = out.replace("{" + k + "}", str(v))
    return out


# ---------------------------------------------------------------------------
# 异步生成
# ---------------------------------------------------------------------------
class BudgetExceeded(Exception):
    pass


class Budget:
    def __init__(self, limit_usd: float) -> None:
        self.limit = limit_usd
        self.spent = 0.0
        self._lock = asyncio.Lock()

    async def add(self, amount: float) -> None:
        async with self._lock:
            self.spent += amount
            if self.spent >= self.limit:
                raise BudgetExceeded(
                    f"预算上限触发：已花费 ${self.spent:.4f} / 上限 ${self.limit:.2f}"
                )

    @property
    def remaining(self) -> float:
        return self.limit - self.spent


async def call_gpt_image_2(
    client: AsyncOpenAI,
    spec: dict,
) -> tuple[bytes, dict]:
    """
    调 gpt-image-2，返回 (PNG bytes, response 元数据 dict)
    有 reference_images 走 edits，否则走 generations
    """
    common_kwargs: dict[str, Any] = {
        "model": "gpt-image-2",
        "prompt": spec["prompt"],
        "size": spec["size"],
        "quality": spec["quality"],
        "n": 1,
    }

    if spec["reference_images"]:
        # edits 端点需要传文件
        files = [open(p, "rb") for p in spec["reference_images"]]
        try:
            response = await client.images.edit(image=files, **common_kwargs)
        finally:
            for f in files:
                f.close()
    else:
        response = await client.images.generate(**common_kwargs)

    if not response.data or not response.data[0].b64_json:
        raise RuntimeError("API 未返回图像数据")

    img_bytes = base64.b64decode(response.data[0].b64_json)
    meta = {
        "model": "gpt-image-2",
        "size": spec["size"],
        "quality": spec["quality"],
        "background": spec["background"],
        "n_reference_images": len(spec["reference_images"]),
        "reference_images": [str(p) for p in spec["reference_images"]],
        "usage": (
            response.usage.model_dump()
            if hasattr(response, "usage") and response.usage
            else None
        ),
    }
    return img_bytes, meta


async def process_task(
    client: AsyncOpenAI,
    task: dict,
    shared: dict,
    raw_dir: Path,
    budget: Budget,
    sem: asyncio.Semaphore,
    max_retries: int,
    dry_run: bool,
    progress: Progress,
    task_pb_id: int,
) -> dict:
    """处理单个任务，返回 result dict"""
    task_id = task["id"]
    template = task["template"]
    category = task.get("category", "misc")
    vars_ = task.get("vars", {}) or {}

    out_dir = raw_dir / category
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{task_id}.png"
    out_meta = out_dir / f"{task_id}.meta.json"

    # 已存在就跳过（除非显式 --force）
    if out_png.exists() and not getattr(task, "_force", False):
        progress.update(task_pb_id, advance=1)
        return {"id": task_id, "status": "skipped_exists", "cost": 0.0}

    try:
        spec = render_template(template, vars_, shared)
    except Exception as e:
        progress.update(task_pb_id, advance=1)
        return {"id": task_id, "status": "template_error", "error": str(e), "cost": 0.0}

    # 预算预检
    est = estimate_cost_from_size_quality(spec["size"], spec["quality"])
    if budget.remaining < est:
        progress.update(task_pb_id, advance=1)
        return {
            "id": task_id,
            "status": "budget_skip",
            "error": f"预算余额不足（需 ~${est:.4f}，余 ${budget.remaining:.4f}）",
            "cost": 0.0,
        }

    if dry_run:
        progress.update(task_pb_id, advance=1)
        out_meta.write_text(
            json.dumps(
                {"id": task_id, "dry_run": True, "spec": {**spec, "reference_images": [str(p) for p in spec["reference_images"]]}},
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        return {"id": task_id, "status": "dry_run", "cost": 0.0}

    last_err: Exception | None = None
    for attempt in range(max_retries + 1):
        async with sem:
            try:
                img_bytes, meta = await call_gpt_image_2(client, spec)
                actual_cost = cost_from_usage(meta.get("usage")) or est
                await budget.add(actual_cost)

                out_png.write_bytes(img_bytes)
                out_meta.write_text(
                    json.dumps(
                        {
                            "id": task_id,
                            "template": template,
                            "category": category,
                            "vars": vars_,
                            "prompt": spec["prompt"],
                            "size": spec["size"],
                            "quality": spec["quality"],
                            "background": spec["background"],
                            "reference_images": meta["reference_images"],
                            "usage": meta["usage"],
                            "cost_usd": round(actual_cost, 6),
                            "generated_at": datetime.now(timezone.utc).isoformat(),
                            "attempt": attempt + 1,
                        },
                        ensure_ascii=False,
                        indent=2,
                    ),
                    encoding="utf-8",
                )
                progress.update(task_pb_id, advance=1)
                return {
                    "id": task_id,
                    "status": "ok",
                    "cost": actual_cost,
                    "attempt": attempt + 1,
                }
            except BudgetExceeded:
                raise
            except (RateLimitError, APIError) as e:
                last_err = e
                wait = 2 ** attempt * 5
                console.print(
                    f"  [yellow]限流/API 错误，{task_id} 第 {attempt + 1} 次失败，{wait}s 后重试[/yellow]"
                )
                await asyncio.sleep(wait)
            except BadRequestError as e:
                last_err = e
                console.print(
                    f"  [red][x] {task_id} 请求被拒（不重试）：{e}[/red]"
                )
                break
            except Exception as e:
                last_err = e
                console.print(
                    f"  [yellow]异常，{task_id} 第 {attempt + 1} 次失败：{e}[/yellow]"
                )
                await asyncio.sleep(3)

    progress.update(task_pb_id, advance=1)
    return {
        "id": task_id,
        "status": "failed",
        "error": str(last_err) if last_err else "unknown",
        "cost": 0.0,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="GPT Image 2 批量生成器")
    p.add_argument("--task", action="append", help="只跑指定 task id（可多次）")
    p.add_argument("--priority", type=int, help="只跑优先级 <= N 的任务")
    p.add_argument("--budget", type=float, help="覆盖 .env 中的预算上限")
    p.add_argument("--concurrency", type=int, help="覆盖 .env 中的并发数")
    p.add_argument("--dry-run", action="store_true", help="只渲染 prompt 不调 API")
    p.add_argument("--force", action="store_true", help="覆盖已存在的资产")
    return p.parse_args()


def filter_tasks(all_tasks: list[dict], args: argparse.Namespace) -> list[dict]:
    out = []
    for t in all_tasks:
        if t.get("skip"):
            continue
        if args.task and t["id"] not in args.task:
            continue
        if args.priority is not None and t.get("priority", 99) > args.priority:
            continue
        if args.force:
            t["_force"] = True
        out.append(t)
    return out


async def main_async(args: argparse.Namespace) -> int:
    load_dotenv(PROJECT_ROOT / ".env")

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or api_key.startswith("sk-..."):
        console.print("[red][x] 未配置 OPENAI_API_KEY，请先复制 .env.example 为 .env 并填入[/red]")
        return 2

    budget_limit = args.budget or float(os.getenv("BUDGET_LIMIT_USD", "80.0"))
    concurrency = args.concurrency or int(os.getenv("GEN_CONCURRENCY", "4"))
    max_retries = int(os.getenv("MAX_RETRIES", "2"))
    raw_dir = PROJECT_ROOT / os.getenv("RAW_DIR", "assets/raw")
    raw_dir.mkdir(parents=True, exist_ok=True)
    FAILED_LOG.parent.mkdir(parents=True, exist_ok=True)

    # 加载 shared + tasks
    shared = load_yaml(SHARED_FILE)
    tasks_doc = load_yaml(TASKS_FILE)
    all_tasks = tasks_doc.get("tasks", [])
    tasks = filter_tasks(all_tasks, args)

    if not tasks:
        console.print("[yellow]没有匹配的任务[/yellow]")
        return 0

    # 头表
    table = Table(title="本次任务", show_header=True, header_style="bold cyan")
    table.add_column("ID")
    table.add_column("Template")
    table.add_column("Category")
    table.add_column("Priority", justify="right")
    for t in tasks:
        table.add_row(t["id"], t["template"], t.get("category", "-"), str(t.get("priority", "-")))
    console.print(table)
    console.print(
        f"[bold]预算上限[/bold]：${budget_limit:.2f} | "
        f"[bold]并发[/bold]：{concurrency} | "
        f"[bold]Dry-Run[/bold]：{args.dry_run}"
    )

    if not args.dry_run:
        client = AsyncOpenAI(
            api_key=api_key,
            base_url=os.getenv("OPENAI_BASE_URL") or None,
        )
    else:
        client = None  # type: ignore

    budget = Budget(budget_limit)
    sem = asyncio.Semaphore(concurrency)
    results: list[dict] = []

    started = time.time()
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("{task.completed}/{task.total}"),
        TimeElapsedColumn(),
        console=console,
    ) as progress:
        pb_id = progress.add_task("生成中…", total=len(tasks))
        coros = [
            process_task(
                client,  # type: ignore[arg-type]
                t,
                shared,
                raw_dir,
                budget,
                sem,
                max_retries,
                args.dry_run,
                progress,
                pb_id,
            )
            for t in tasks
        ]
        try:
            results = await asyncio.gather(*coros, return_exceptions=False)
        except BudgetExceeded as e:
            console.print(f"[red][x] {e}[/red]")

    elapsed = time.time() - started

    # 统计
    ok = [r for r in results if r.get("status") == "ok"]
    skipped = [r for r in results if r.get("status") in ("skipped_exists", "budget_skip", "dry_run")]
    failed = [r for r in results if r.get("status") in ("failed", "template_error")]

    summary = Table(title="结果汇总", show_header=True, header_style="bold magenta")
    summary.add_column("状态")
    summary.add_column("数量", justify="right")
    summary.add_row("成功", str(len(ok)))
    summary.add_row("跳过 / Dry-Run", str(len(skipped)))
    summary.add_row("失败", str(len(failed)))
    summary.add_row("总花费", f"${budget.spent:.4f}")
    summary.add_row("剩余预算", f"${budget.remaining:.4f}")
    summary.add_row("耗时", f"{elapsed:.1f}s")
    console.print(summary)

    # 失败日志
    if failed:
        with FAILED_LOG.open("a", encoding="utf-8") as f:
            for r in failed:
                f.write(
                    json.dumps(
                        {**r, "ts": datetime.now(timezone.utc).isoformat()},
                        ensure_ascii=False,
                    )
                    + "\n"
                )
        console.print(f"[yellow]失败明细已写入 {FAILED_LOG}[/yellow]")

    return 0 if not failed else 1


def main() -> int:
    args = parse_args()
    return asyncio.run(main_async(args))


if __name__ == "__main__":
    sys.exit(main())
