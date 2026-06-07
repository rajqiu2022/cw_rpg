"""
gen_assets.py — GPT Image 2 批量异步生成器

读取 prompts/tasks.yaml，对每个任务加载模板、渲染变量、调图像模型，
落盘原图 + 元数据。内置预算硬上限、并发限流、失败重试。

后端：OpenAI 兼容（DMXAPI 等）走 AsyncOpenAI；若 OPENAI_BASE_URL 含 alapi.cn
则走 ALAPI 直连（HTTP 头 token，见 docs/alapi-image-api.md）。

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
import io
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

import httpx
import yaml
from PIL import Image
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
DRY_RUN_DIR = PROJECT_ROOT / "logs" / "dry_run"

console = Console()


# ---------------------------------------------------------------------------
# 价格表 —— 区分官方直连（USD）和 DMXAPI 中转（CNY）
# OpenAI 官方价格：2026-04-21 发布的 gpt-image-2 token-based 计费
# DMXAPI 价格：来自 https://www.dmxapi.cn 集采 7 折后单图价
# ---------------------------------------------------------------------------

# OpenAI 官方：(size, quality) -> usd
PRICE_OPENAI_USD = {
    # 896² 约 0.77×1024²，token 计价下为粗估（无 usage 时 fallback）
    ("896x896", "low"): 0.005,
    ("896x896", "medium"): 0.042,
    ("896x896", "high"): 0.165,
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

# OpenAI token 单价（USD per 1M）— 响应带 usage 时换算
TEXT_INPUT_PER_M = 5.0
IMAGE_INPUT_PER_M = 8.0
IMAGE_OUTPUT_PER_M = 30.0

# DMXAPI 中转：单价 (CNY)
# 来源：https://www.dmxapi.cn/pricing（2026-04-27 核实）
# 重要：gpt-image 系列在 DMXAPI 现行定价是 token-based（¥/M tokens），
#       响应带 usage 时走 cost_from_usage()，否则 fallback 到此处估值（保守 medium quality）
PRICE_DMXAPI_CNY = {
    "gpt-image-1": 1.0,           # ¥25 in / ¥200 out per M tokens, ≈ ¥1/张 medium
    "gpt-image-1-mini": 0.5,      # ¥12.5 in / ¥40 out per M tokens
    "gpt-image-1.5": 1.0,         # ¥25 in / ¥160 out per M tokens
    "gpt-image-1.5-ssvip": 2.5,   # OpenAI 直连版，更贵
    "gpt-image-2": 1.2,           # ¥24.82 in / ¥148.92 out per M tokens（2026-04 上线）
    "dall-e-3": 0.5,
    "flux-kontext-pro": 0.2,
    "flux-kontext-max": 0.4,
    "seedream-3.0": 0.08,
    "imagen4": 0.5,
}

# DMXAPI gpt-image 系列 token 单价（CNY per 1M tokens）— 响应带 usage 时换算
DMX_IMAGE_TOKEN_PRICES_CNY = {
    "gpt-image-1":          {"text_in": 25.0, "image_in": 25.0, "image_out": 200.0},
    "gpt-image-1-mini":     {"text_in": 12.5, "image_in": 12.5, "image_out": 40.0},
    "gpt-image-1.5":        {"text_in": 25.0, "image_in": 25.0, "image_out": 160.0},
    "gpt-image-1.5-ssvip":  {"text_in": 58.4, "image_in": 58.4, "image_out": 233.6},
    "gpt-image-2":          {"text_in": 24.82, "image_in": 24.82, "image_out": 148.92},
}


def detect_backend(base_url: str | None) -> str:
    """根据 base_url 判断 backend，决定价格表和币种"""
    if not base_url:
        return "openai"
    u = base_url.lower()
    if "dmxapi" in u:
        return "dmxapi"
    if "alapi.cn" in u:
        return "alapi"
    return "openai_compat"  # 其他兼容站点，用 OpenAI 计价做估算


def currency_for(backend: str) -> str:
    return "CNY" if backend in ("dmxapi", "alapi") else "USD"


def currency_symbol(backend: str) -> str:
    return "¥" if backend in ("dmxapi", "alapi") else "$"


def estimate_cost_from_size_quality(
    size: str, quality: str, backend: str = "openai", model: str = "gpt-image-2"
) -> float:
    """根据 backend + size + quality + model 估算单张成本（fallback）。
    返回值的币种由 backend 决定（openai=USD，dmxapi=CNY）。"""
    if backend == "dmxapi":
        # DMXAPI 是 per-image 计费，与 size/quality 无关
        return PRICE_DMXAPI_CNY.get(model, 1.0)
    if backend == "alapi":
        # alapi 当前按兼容站处理，先用 RMB 估算，后续可按实测修正
        return PRICE_DMXAPI_CNY.get(model, 1.0)
    return PRICE_OPENAI_USD.get((size, quality), 0.053)


def cost_from_usage(
    usage: Any | None, backend: str = "openai", model: str = "gpt-image-2"
) -> float:
    """如果响应带 usage 信息，按 token 换算。
    OpenAI 官方端点用 USD 价格表，DMXAPI 用 CNY 价格表（同接口字段）。"""
    if not usage:
        return 0.0
    try:
        usage_dict = usage if isinstance(usage, dict) else usage.model_dump()
    except AttributeError:
        return 0.0
    # DMXAPI 实测某些字段可能存在但值为 None，必须 or 0 兜底
    details = usage_dict.get("input_tokens_details") or {}
    text_in = details.get("text_tokens") or 0
    image_in = details.get("image_tokens") or 0
    image_out = usage_dict.get("output_tokens") or 0

    if backend == "dmxapi":
        prices = DMX_IMAGE_TOKEN_PRICES_CNY.get(model)
        if not prices:
            return 0.0  # 非 token 计费的模型，fallback 到 per-image 价
        return (
            text_in * prices["text_in"] / 1_000_000
            + image_in * prices["image_in"] / 1_000_000
            + image_out * prices["image_out"] / 1_000_000
        )

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
    declared_refs = tpl.get("reference_images", []) or []
    for r in declared_refs:
        p = (PROJECT_ROOT / r).resolve()
        if p.exists():
            refs.append(p)
        else:
            console.print(
                f"  [yellow][warn] 参考图缺失：{p}（跳过该参考）[/yellow]"
            )

    # 续帧类模板：声明 require_reference_images 时必须齐套，否则 edits 会静默退回 generations，外观漂移。
    if tpl.get("require_reference_images") and declared_refs and len(refs) != len(declared_refs):
        missing = [
            str((PROJECT_ROOT / r).resolve())
            for r in declared_refs
            if not (PROJECT_ROOT / r).resolve().exists()
        ]
        raise FileNotFoundError(
            f"模板 {template_name} 要求参考图齐套，但文件不存在：{missing}。"
            " 请先产出关键帧 PNG 再跑续帧任务。"
        )

    return {
        "prompt": prompt.strip(),
        "size": tpl.get("size") or defaults.get("size", "1024x1024"),
        "quality": tpl.get("quality") or defaults.get("quality", "medium"),
        "background": tpl.get("background") or defaults.get("background", "opaque"),
        "resolution": tpl.get("resolution") or defaults.get("resolution", "1k"),
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


# ---------------------------------------------------------------------------
# 容错：错误分类 + 全局 IP-block pause + 退避策略
# 对应 ADR-001 §6.4 L2 容错工程清单
# ---------------------------------------------------------------------------

# 错误分类
ERR_MODERATION = "moderation"     # Azure 内容审核拒绝，不重试
ERR_FATAL = "fatal"               # 4xx 不可重试
ERR_CHANNEL_503 = "channel_503"   # 上游渠道熔断 / 502 / 504，长退避
ERR_IP_BLOCK = "ip_block"         # TLS / connection 失败，疑似 IP 封禁，触发全局 pause
ERR_RATE_LIMIT = "rate_limit"     # 显式 429
ERR_EMPTY = "empty"               # HTTP 200 但响应空数据，3 次内 retry
ERR_TRANSIENT = "transient"       # 默认可重试


def classify_error(e: Exception, backend: str = "openai") -> str:
    """根据异常返回错误分类，决定退避策略"""
    msg = str(e).lower()

    # 余额不足 / 账户欠费：永久错误，立刻停（不浪费重试和 fallback）
    # DMXAPI 表现为 403 PermissionDeniedError + insufficient_user_quota
    # OpenAI 官方表现为 InsufficientQuotaError
    if (
        "insufficient_user_quota" in msg
        or "用户额度不足" in msg
        or "insufficient_quota" in msg
        or "billing" in msg and "insufficient" in msg
    ):
        return ERR_FATAL

    # BadRequest（400）：moderation 或不可恢复
    if isinstance(e, BadRequestError):
        if "moderation" in msg or "blocked" in msg or "safety" in msg:
            return ERR_MODERATION
        return ERR_FATAL

    if isinstance(e, RateLimitError):
        return ERR_RATE_LIMIT

    # 503 / 502 / 504 渠道熔断
    if isinstance(e, APIError):
        sc = getattr(e, "status_code", None)
        if sc in (502, 503, 504):
            return ERR_CHANNEL_503
        if "no available channels" in msg or "无可用渠道" in msg or "上游" in msg:
            return ERR_CHANNEL_503

    if isinstance(e, httpx.HTTPStatusError):
        if e.response.status_code in (502, 503, 504):
            if backend == "alapi":
                return ERR_TRANSIENT
            return ERR_CHANNEL_503
        if e.response.status_code == 429:
            return ERR_RATE_LIMIT
        if 400 <= e.response.status_code < 500:
            return ERR_FATAL

    # 200 但空数据（call_image_model 抛的 RuntimeError）
    if isinstance(e, RuntimeError) and ("未返回图像数据" in str(e) or "no image data" in msg):
        return ERR_EMPTY

    # TLS / Connection 错误：疑似 IP 风控
    if isinstance(e, (httpx.ConnectError, httpx.ReadTimeout, httpx.ConnectTimeout,
                      httpx.RemoteProtocolError, httpx.WriteTimeout)):
        if backend == "alapi":
            return ERR_TRANSIENT
        return ERR_IP_BLOCK
    if any(s in msg for s in ("schannel", "sec_e_invalid_token", "ssl", "handshake",
                              "remotedisconnected", "connection reset")):
        if backend == "alapi":
            return ERR_TRANSIENT
        return ERR_IP_BLOCK

    return ERR_TRANSIENT


class IPBlockGate:
    """全局放行信号——检测到疑似 IP 封禁时，所有 task 暂停 N 分钟。

    重复触发不叠加：第一个发现的 task 进入 pause，后续 task 直接 await 同一个事件。
    pause 到期后自动恢复，所有等待的 task 一起放行。
    """

    def __init__(self, pause_seconds: float = 1800.0) -> None:
        self._event = asyncio.Event()
        self._event.set()  # 初始放行
        self._lock = asyncio.Lock()
        self.pause_seconds = pause_seconds

    async def wait(self) -> None:
        await self._event.wait()

    async def trigger_pause(self) -> None:
        """疑似 IP 风控，全局暂停。被多个 task 同时调用是安全的。"""
        async with self._lock:
            if self._event.is_set():
                self._event.clear()
                console.print(
                    f"[bold red]>>> 检测到疑似 IP 风控 / TLS 错误，"
                    f"全局暂停 {int(self.pause_seconds)}s ({int(self.pause_seconds // 60)} 分钟) <<<[/bold red]"
                )
                asyncio.create_task(self._resume_after(self.pause_seconds))
        await self._event.wait()

    async def _resume_after(self, seconds: float) -> None:
        await asyncio.sleep(seconds)
        async with self._lock:
            self._event.set()
            console.print("[bold green]>>> IP 风控暂停结束，恢复跑批 <<<[/bold green]")


async def backoff_for(category: str, attempt: int, gate: IPBlockGate) -> bool:
    """按错误分类做退避。返回 True=可重试，False=放弃。"""
    if category in (ERR_MODERATION, ERR_FATAL):
        return False

    if category == ERR_IP_BLOCK:
        # 全局暂停 30 分钟，所有 task 一起等
        await gate.trigger_pause()
        return True

    if category == ERR_CHANNEL_503:
        # 5 / 10 / 20 分钟
        wait = min(300 * (2 ** attempt), 1800)
        console.print(f"  [yellow]渠道熔断 503，退避 {wait}s 后重试[/yellow]")
        await asyncio.sleep(wait)
        return True

    if category == ERR_RATE_LIMIT:
        wait = min(30 * (2 ** attempt), 600)
        console.print(f"  [yellow]rate limit 429，退避 {wait}s 后重试[/yellow]")
        await asyncio.sleep(wait)
        return True

    if category == ERR_EMPTY:
        wait = 5 * (2 ** attempt)
        console.print(f"  [yellow]200 空响应，{wait}s 后重试[/yellow]")
        await asyncio.sleep(wait)
        return True

    # transient
    wait = 5 * (2 ** attempt)
    await asyncio.sleep(wait)
    return True


async def _extract_first_image_bytes(response: Any) -> tuple[bytes, str]:
    """兼容多种 OpenAI-compatible 返回格式，提取首张图二进制。"""
    data_field = getattr(response, "data", None)

    items: list[Any] = []
    if isinstance(data_field, list):
        items = data_field
    elif isinstance(data_field, dict):
        nested = data_field.get("data")
        if isinstance(nested, list):
            items = nested

    if not items:
        code = getattr(response, "code", None)
        message = getattr(response, "message", None)
        success = getattr(response, "success", None)
        detail = f"success={success}, code={code}, message={message}" if (success is not None or code is not None or message is not None) else "无详细错误字段"
        raise RuntimeError(f"API 未返回可用图像列表（{detail}）")

    first = items[0]
    if hasattr(first, "model_dump"):
        first = first.model_dump()

    b64_val = None
    url_val = None
    if isinstance(first, dict):
        b64_val = first.get("b64_json")
        url_val = first.get("url")
    else:
        b64_val = getattr(first, "b64_json", None)
        url_val = getattr(first, "url", None)

    if b64_val:
        return base64.b64decode(b64_val), "b64"

    if url_val:
        async with httpx.AsyncClient(timeout=httpx.Timeout(120.0, connect=20.0)) as hc:
            r = await hc.get(str(url_val))
            r.raise_for_status()
            return r.content, f"url:{url_val}"

    raise RuntimeError("API 返回中既无 b64_json 也无 url")


def _alapi_generations_url(base_url: str | None) -> str:
    """Return ALAPI's images/generations endpoint.

    ALAPI is not fully OpenAI-SDK compatible: auth uses a `token` header and
    the caller may configure either the API root or the full endpoint.
    """
    root = (base_url or "https://v3.alapi.cn/api/ai").rstrip("/")
    if root.endswith("/images/generations"):
        return root
    return f"{root}/images/generations"


def _alapi_reference_base64(path: Path, max_side: int = 1280, quality: int = 88) -> str:
    """Compress reference images before sending to ALAPI.

    The ALAPI generations endpoint may close chunked responses when the JSON
    payload is too large. Existing ALAPI scripts in this repo compress refs
    first, so keep the shared generator consistent with that behavior.
    """
    image = Image.open(path).convert("RGB")
    image.thumbnail((max_side, max_side), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=quality, optimize=True)
    return base64.b64encode(buffer.getvalue()).decode("ascii")


async def _call_alapi_generation(
    api_key: str,
    base_url: str | None,
    spec: dict,
    model: str,
) -> tuple[bytes, dict]:
    image_refs: list[dict[str, str]] = []
    for path in spec["reference_images"]:
        image_refs.append(
            {
                "type": "base64",
                "data": _alapi_reference_base64(path),
            }
        )

    payload: dict[str, Any] = {
        "model": model,
        "prompt": spec["prompt"],
        "n": 1,
        "size": spec["size"],
        "quality": spec["quality"],
        "resolution": spec.get("resolution", "1k"),
    }
    if image_refs:
        payload["image"] = image_refs

    async with httpx.AsyncClient(timeout=httpx.Timeout(300.0, connect=30.0)) as hc:
        response = await hc.post(
            _alapi_generations_url(base_url),
            headers={"token": api_key, "Content-Type": "application/json"},
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

    if data.get("code") not in (None, 200):
        raise RuntimeError(f"ALAPI error code={data.get('code')} message={data.get('message')}")

    items: list[Any] = []
    data_field = data.get("data")
    if isinstance(data_field, dict) and isinstance(data_field.get("data"), list):
        items = data_field["data"]
    elif isinstance(data_field, list):
        items = data_field
    elif isinstance(data_field, dict):
        items = [data_field]

    if not items:
        raise RuntimeError(f"ALAPI 未返回可用图像列表：{str(data)[:500]}")

    first = items[0]
    b64_val = first.get("b64_json") if isinstance(first, dict) else None
    url_val = first.get("url") if isinstance(first, dict) else None
    if b64_val:
        img_bytes = base64.b64decode(b64_val)
        image_source = "b64"
    elif url_val:
        async with httpx.AsyncClient(timeout=httpx.Timeout(120.0, connect=20.0)) as hc:
            img_response = await hc.get(str(url_val))
            img_response.raise_for_status()
            img_bytes = img_response.content
            image_source = f"url:{url_val}"
    else:
        raise RuntimeError("ALAPI 返回中既无 b64_json 也无 url")

    meta = {
        "model": model,
        "size": spec["size"],
        "quality": spec["quality"],
        "background": spec["background"],
        "image_source": image_source,
        "n_reference_images": len(spec["reference_images"]),
        "reference_images": [str(p) for p in spec["reference_images"]],
        "usage": data.get("usage"),
    }
    return img_bytes, meta


async def startup_ping(
    client: Any,
    model: str,
    timeout: float = 60.0,
    backend: str = "openai",
    api_key: str = "",
    base_url: str | None = None,
) -> tuple[bool, str]:
    """跑批前最小调用探活：单张极简图请求，确认渠道可用。"""
    try:
        if backend == "alapi":
            img_bytes, meta = await asyncio.wait_for(
                _call_alapi_generation(
                    api_key,
                    base_url,
                    {
                        "prompt": "a single white circle on plain background",
                        "size": "1024x1024",
                        "quality": "high",
                        "background": "opaque",
                        "reference_images": [],
                    },
                    model,
                ),
                timeout=timeout,
            )
            source = meta["image_source"]
        else:
            rsp = await asyncio.wait_for(
                client.images.generate(
                    model=model,
                    prompt="a single white circle on plain background",
                    size="1024x1024",
                    n=1,
                ),
                timeout=timeout,
            )
            img_bytes, source = await _extract_first_image_bytes(rsp)
        return True, f"ok ({source}, bytes={len(img_bytes)})"
    except asyncio.TimeoutError:
        return False, f"探活超时（>{int(timeout)}s）"
    except Exception as e:
        return False, f"{type(e).__name__}: {e}"


async def call_image_model(
    client: Any,
    spec: dict,
    model: str,
    backend: str = "openai",
) -> tuple[bytes, dict]:
    """
    调用图像模型（OpenAI gpt-image-2 / DMXAPI gpt-image-1 / flux 等都走同协议）
    有 reference_images 走 edits，否则走 generations
    """
    common_kwargs: dict[str, Any] = {
        "model": model,
        "prompt": spec["prompt"],
        "size": spec["size"],
        "quality": spec["quality"],
        "n": 1,
    }

    # DMXAPI 后端接 Azure OpenAI，moderation 默认偏严，
    # 武侠/写实题材的中文 prompt 容易被误判（"剑"、"暗红"、"畸形"等）。
    # 通过 extra_body 透传 moderation=low 给 DMXAPI（文档支持）。
    extra_body: dict[str, Any] = {}
    if backend == "dmxapi" and model.startswith("gpt-image"):
        extra_body["moderation"] = "low"

    if backend == "alapi":
        return await _call_alapi_generation(
            client["api_key"],
            client["base_url"],
            spec,
            model,
        )

    if spec["reference_images"]:
        # edits 端点需要传文件；alapi 当前只走 generations 接口
        files = [open(p, "rb") for p in spec["reference_images"]]
        try:
            response = await client.images.edit(
                image=files, extra_body=extra_body or None, **common_kwargs
            )
        finally:
            for f in files:
                f.close()
    else:
        response = await client.images.generate(
            extra_body=extra_body or None, **common_kwargs
        )

    img_bytes, image_source = await _extract_first_image_bytes(response)
    usage_raw = getattr(response, "usage", None)
    if isinstance(usage_raw, dict):
        usage_value: Any = usage_raw
    elif hasattr(usage_raw, "model_dump"):
        usage_value = usage_raw.model_dump()
    elif usage_raw is not None:
        usage_value = {"raw": usage_raw}
    else:
        usage_value = None

    meta = {
        "model": model,
        "size": spec["size"],
        "quality": spec["quality"],
        "background": spec["background"],
        "image_source": image_source,
        "n_reference_images": len(spec["reference_images"]),
        "reference_images": [str(p) for p in spec["reference_images"]],
        "usage": usage_value,
    }
    return img_bytes, meta


async def _try_one_model(
    client: Any,
    task_id: str,
    spec: dict,
    model: str,
    backend: str,
    budget: Budget,
    sem: asyncio.Semaphore,
    max_retries: int,
    gate: IPBlockGate,
    est: float,
) -> tuple[bool, dict | None, dict | None, Exception | None, str | None]:
    """用单个 model 跑一个 task，做 max_retries+1 次重试。

    返回 (ok, img_meta, save_payload, last_err, last_category)
        ok=True  → save_payload 可以 .write_bytes() 入磁盘
        ok=False → last_err / last_category 解释为何放弃
    """
    last_err: Exception | None = None
    last_cat: str | None = None

    for attempt in range(max_retries + 1):
        # 全局放行检查（IP 风控期间所有 task 等同一个 event）
        await gate.wait()

        async with sem:
            try:
                img_bytes, meta = await call_image_model(client, spec, model, backend)
                actual_cost = cost_from_usage(meta.get("usage"), backend, model) or est
                await budget.add(actual_cost)
                payload = {
                    "img_bytes": img_bytes,
                    "meta": meta,
                    "actual_cost": actual_cost,
                    "attempt": attempt + 1,
                    "model_used": model,
                }
                return True, meta, payload, None, None
            except BudgetExceeded:
                raise
            except Exception as e:
                last_err = e
                last_cat = classify_error(e, backend)
                # 仅在非致命情况下尝试退避并重试
                if last_cat in (ERR_MODERATION, ERR_FATAL):
                    console.print(
                        f"  [red][x] {task_id} ({model}) {last_cat}：{type(e).__name__}: {e}[/red]"
                    )
                    return False, None, None, last_err, last_cat
                console.print(
                    f"  [yellow]{task_id} ({model}) attempt {attempt + 1}/{max_retries + 1} "
                    f"failed [{last_cat}]: {type(e).__name__}: {e}[/yellow]"
                )
        # 退避在锁外做，避免独占信号量
        can_retry = await backoff_for(last_cat, attempt, gate)
        if not can_retry:
            break

    return False, None, None, last_err, last_cat


async def process_task(
    client: Any,
    task: dict,
    shared: dict,
    raw_dir: Path,
    budget: Budget,
    sem: asyncio.Semaphore,
    max_retries: int,
    dry_run: bool,
    progress: Progress,
    task_pb_id: int,
    backend: str,
    default_model: str,
    fallback_model: str | None,
    gate: IPBlockGate,
) -> dict:
    """处理单个任务，返回 result dict。

    重试策略（ADR-001 §6.4）：
        1. 主 model 跑 max_retries+1 次，每次按 classify_error 退避
        2. 全部失败且不是 moderation/fatal → 切 fallback_model 再跑 1 次
        3. 仍失败 → 写 failed.log
    """
    task_id = task["id"]
    template = task["template"]
    category = task.get("category", "misc")
    vars_ = task.get("vars", {}) or {}

    out_dir = raw_dir / category
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{task_id}.png"
    out_meta = out_dir / f"{task_id}.meta.json"

    if out_png.exists() and not task.get("_force", False):
        progress.update(task_pb_id, advance=1)
        return {"id": task_id, "status": "skipped_exists", "cost": 0.0}

    try:
        spec = render_template(template, vars_, shared)
    except Exception as e:
        progress.update(task_pb_id, advance=1)
        return {"id": task_id, "status": "template_error", "error": str(e), "cost": 0.0}

    primary_model = task.get("model") or default_model

    est = estimate_cost_from_size_quality(spec["size"], spec["quality"], backend, primary_model)
    if budget.remaining < est:
        progress.update(task_pb_id, advance=1)
        return {
            "id": task_id,
            "status": "budget_skip",
            "error": f"预算余额不足（需 ~{est:.4f}，余 {budget.remaining:.4f}）",
            "cost": 0.0,
        }

    if dry_run:
        progress.update(task_pb_id, advance=1)
        DRY_RUN_DIR.mkdir(parents=True, exist_ok=True)
        dry_run_meta = DRY_RUN_DIR / f"{task_id}.meta.json"
        dry_run_meta.write_text(
            json.dumps(
                {"id": task_id, "dry_run": True, "spec": {**spec, "reference_images": [str(p) for p in spec["reference_images"]]}},
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        return {"id": task_id, "status": "dry_run", "cost": 0.0, "meta": str(dry_run_meta)}

    # 主 model
    ok, _meta, payload, last_err, last_cat = await _try_one_model(
        client, task_id, spec, primary_model, backend,
        budget, sem, max_retries, gate, est,
    )

    # fallback model（moderation/fatal 不降级；预算余额不足也不降级）
    if not ok and fallback_model and fallback_model != primary_model \
            and last_cat not in (ERR_MODERATION, ERR_FATAL) \
            and budget.remaining > 0:
        console.print(
            f"  [cyan]{task_id} 主模型 {primary_model} 全部失败，"
            f"切 fallback {fallback_model} 再试 1 次[/cyan]"
        )
        ok, _meta, payload, last_err, last_cat = await _try_one_model(
            client, task_id, spec, fallback_model, backend,
            budget, sem, 0, gate, est,
        )

    progress.update(task_pb_id, advance=1)

    if ok and payload:
        meta = payload["meta"]
        cur = currency_for(backend)
        out_png.write_bytes(payload["img_bytes"])
        out_meta.write_text(
            json.dumps(
                {
                    "id": task_id,
                    "template": template,
                    "category": category,
                    "model": payload["model_used"],
                    "backend": backend,
                    "vars": vars_,
                    "prompt": spec["prompt"],
                    "size": spec["size"],
                    "quality": spec["quality"],
                    "background": spec["background"],
                    "reference_images": meta["reference_images"],
                    "usage": meta["usage"],
                    "cost": round(payload["actual_cost"], 6),
                    "currency": cur,
                    "generated_at": datetime.now(timezone.utc).isoformat(),
                    "attempt": payload["attempt"],
                    "fallback_used": payload["model_used"] != primary_model,
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        return {
            "id": task_id,
            "status": "ok",
            "cost": payload["actual_cost"],
            "attempt": payload["attempt"],
            "model": payload["model_used"],
        }

    return {
        "id": task_id,
        "status": "failed",
        "category": last_cat or "unknown",
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
    p.add_argument("--concurrency", type=int, help="覆盖 .env 中的并发数（默认 1）")
    p.add_argument("--dry-run", action="store_true", help="只渲染 prompt 不调 API")
    p.add_argument("--force", action="store_true", help="覆盖已存在的资产")
    p.add_argument(
        "--retry-failed",
        action="store_true",
        help="只重跑 logs/failed.log 里出现过的 task id",
    )
    p.add_argument(
        "--skip-ping",
        action="store_true",
        help="跳过启动时的渠道存活探测（不推荐）",
    )
    p.add_argument(
        "--fallback-model",
        type=str,
        help="主模型重试用尽后切到此模型再试 1 次（默认读 FALLBACK_MODEL，否则 gpt-image-1.5）",
    )
    p.add_argument(
        "--ip-pause-seconds",
        type=float,
        help="IP 风控触发后全局暂停秒数（默认 1800=30 分钟）",
    )
    return p.parse_args()


def load_retry_failed_ids() -> set[str]:
    """从 logs/failed.log 读出曾经失败过的 task id 集合（用于 --retry-failed）"""
    if not FAILED_LOG.exists():
        return set()
    ids: set[str] = set()
    for line in FAILED_LOG.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if obj.get("id"):
                ids.add(str(obj["id"]))
        except Exception:
            continue
    return ids


def filter_tasks(all_tasks: list[dict], args: argparse.Namespace,
                 retry_failed_ids: set[str] | None = None) -> list[dict]:
    out = []
    explicit_ids: set[str] | None = None
    if args.task:
        explicit_ids = set(args.task)
    if retry_failed_ids:
        explicit_ids = (explicit_ids or set()) | retry_failed_ids

    for t in all_tasks:
        if t.get("skip"):
            continue
        if explicit_ids is not None and t["id"] not in explicit_ids:
            continue
        if args.priority is not None and t.get("priority", 99) > args.priority:
            continue
        if args.force or retry_failed_ids:
            # --retry-failed 隐含 force（重跑必须覆盖已存在的失败留档）
            t["_force"] = True
        out.append(t)
    return out


async def main_async(args: argparse.Namespace) -> int:
    load_dotenv(PROJECT_ROOT / ".env")
    load_dotenv(PROJECT_ROOT / ".env.local", override=True)

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or api_key.startswith("sk-..."):
        console.print("[red][x] 未配置 OPENAI_API_KEY，请先复制 .env.example 为 .env 并填入[/red]")
        return 2

    base_url = os.getenv("OPENAI_BASE_URL") or None
    backend = detect_backend(base_url)
    cur_sym = currency_symbol(backend)

    # 默认模型：
    #   - DMXAPI：gpt-image-2（2026-04 上线，最新）；
    #     如需更便宜可改 gpt-image-1.5 / gpt-image-1
    #   - OpenAI 官方：gpt-image-2
    default_model = os.getenv(
        "OPENAI_IMAGE_MODEL",
        "gpt-image-2" if backend == "dmxapi" else "gpt-image-2",
    )

    # 预算上限：OpenAI 模式下读 BUDGET_LIMIT_USD（USD），DMXAPI 模式下读 BUDGET_LIMIT_CNY（CNY）
    if backend == "dmxapi":
        budget_limit = args.budget or float(
            os.getenv("BUDGET_LIMIT_CNY", os.getenv("BUDGET_LIMIT_USD", "100.0"))
        )
    else:
        budget_limit = args.budget or float(os.getenv("BUDGET_LIMIT_USD", "80.0"))

    concurrency = args.concurrency or int(os.getenv("GEN_CONCURRENCY", "1"))
    max_retries = int(os.getenv("MAX_RETRIES", "2"))
    raw_dir = PROJECT_ROOT / os.getenv("RAW_DIR", "assets/raw")
    raw_dir.mkdir(parents=True, exist_ok=True)
    FAILED_LOG.parent.mkdir(parents=True, exist_ok=True)

    # Fallback model：主 model 重试用尽后再试 1 次
    fallback_model = (
        args.fallback_model
        or os.getenv("FALLBACK_MODEL")
        or ("gpt-image-1.5" if backend == "dmxapi" else None)
    )

    # IP 风控暂停时长（默认 30 分钟）
    ip_pause = args.ip_pause_seconds or float(os.getenv("IP_PAUSE_SECONDS", "1800"))

    # 加载 shared + tasks
    shared = load_yaml(SHARED_FILE)
    tasks_doc = load_yaml(TASKS_FILE)
    all_tasks = tasks_doc.get("tasks", [])

    retry_ids: set[str] | None = None
    if args.retry_failed:
        retry_ids = load_retry_failed_ids()
        if not retry_ids:
            console.print("[yellow]--retry-failed 指定但 logs/failed.log 没有可重跑的失败记录[/yellow]")
            return 0
        console.print(f"[cyan]--retry-failed: 从 logs/failed.log 读到 {len(retry_ids)} 个失败 task[/cyan]")

    tasks = filter_tasks(all_tasks, args, retry_ids)

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
    backend_label = {
        "openai": "OpenAI 官方",
        "dmxapi": "DMXAPI 中转",
        "alapi": f"ALAPI 兼容 ({base_url})",
        "openai_compat": f"OpenAI 兼容 ({base_url})",
    }.get(backend, backend)
    console.print(
        f"[bold]后端[/bold]：{backend_label} | "
        f"[bold]主模型[/bold]：{default_model} | "
        f"[bold]Fallback[/bold]：{fallback_model or '（无）'} | "
        f"[bold]预算上限[/bold]：{cur_sym}{budget_limit:.2f} | "
        f"[bold]并发[/bold]：{concurrency} | "
        f"[bold]Dry-Run[/bold]：{args.dry_run}"
    )

    if not args.dry_run:
        # 关键修复（经验记录）：
        # OpenAI SDK 默认 connect timeout = 5s，DMXAPI 中转的 TLS 握手 + 图像
        # 生成首字节响应往往需要 30-60s。必须显式设长超时，否则所有请求会
        # 在 ~16s 内失败重试 3 次。
        connect_timeout = float(os.getenv("HTTP_CONNECT_TIMEOUT", "30"))
        total_timeout = float(os.getenv("HTTP_TOTAL_TIMEOUT", "300"))
        http_timeout = httpx.Timeout(total_timeout, connect=connect_timeout)
        if backend == "alapi":
            client = {"api_key": api_key, "base_url": base_url}
        else:
            client = AsyncOpenAI(
                api_key=api_key,
                base_url=base_url,
                timeout=http_timeout,
                max_retries=0,  # 自己实现重试逻辑（带退避），关掉 SDK 内置的
            )

        # 启动探活：跑批前确认渠道可用，避免浪费 token + 时间
        if not args.skip_ping:
            console.print(f"[cyan]>>> 启动探活 ({default_model}) ...[/cyan]")
            ok, info = await startup_ping(
                client,
                default_model,
                backend=backend,
                api_key=api_key,
                base_url=base_url,
            )
            if ok:
                console.print(f"[green]>>> 渠道存活：{info}[/green]")
            else:
                console.print(f"[red]>>> 渠道不可用：{info}[/red]")
                if fallback_model and fallback_model != default_model:
                    console.print(f"[yellow]>>> 尝试 fallback {fallback_model} 探活 ...[/yellow]")
                    ok2, info2 = await startup_ping(
                        client,
                        fallback_model,
                        backend=backend,
                        api_key=api_key,
                        base_url=base_url,
                    )
                    if ok2:
                        console.print(
                            f"[green]>>> Fallback 渠道存活（{fallback_model}）：{info2}[/green]"
                        )
                        console.print(
                            f"[yellow]>>> 主模型不可用，本次跑批会大量 fallback。"
                            f"建议过几小时后再跑。继续？继续 = 5s 后开始[/yellow]"
                        )
                        await asyncio.sleep(5)
                    else:
                        console.print(f"[red]>>> Fallback 也不可用：{info2}[/red]")
                        console.print("[red]>>> 终止跑批。建议稍后重试或换 backend。[/red]")
                        return 3
                else:
                    console.print("[red]>>> 终止跑批。建议稍后重试或换 backend。[/red]")
                    return 3
    else:
        client = None  # type: ignore

    budget = Budget(budget_limit)
    sem = asyncio.Semaphore(concurrency)
    gate = IPBlockGate(pause_seconds=ip_pause)
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
                backend,
                default_model,
                fallback_model,
                gate,
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
    summary.add_row("总花费", f"{cur_sym}{budget.spent:.4f}")
    summary.add_row("剩余预算", f"{cur_sym}{budget.remaining:.4f}")
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
