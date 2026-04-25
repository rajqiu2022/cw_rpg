"""
verify.py — 资产规范校验器

检查 assets/processed/ 下所有 PNG 是否符合规范：
  - alpha 通道存在且非全不透明（确保 rembg 抠了）
  - 尺寸符合该类别的目标值
  - 命名只含小写字母、数字、下划线、斜杠
  - 元数据 .meta.json 存在且字段齐全（仅对 raw/ 检查）

输出：终端表格 + reports/verify_{timestamp}.json

用法：
    python scripts/verify.py
    python scripts/verify.py --strict   # 任何 warn 都视为 fail
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

# Force UTF-8 stdout / stderr on Windows (default cp936/GBK can't encode
# Chinese + symbols used by Rich).
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from dotenv import load_dotenv
from PIL import Image
from rich.console import Console
from rich.table import Table

PROJECT_ROOT = Path(__file__).resolve().parent.parent
console = Console()

NAME_PATTERN = re.compile(r"^[a-z0-9_]+$")

EXPECTED_SIZES = {
    "sprite": (256, 256),
    "ui/icon/skill": (128, 128),
    "ui/icon/item": (128, 128),
    "ui/button": (512, 170),
}


def expected_size(category: str) -> tuple[int, int] | None:
    for prefix, sz in EXPECTED_SIZES.items():
        if category == prefix or category.startswith(prefix + "/"):
            return sz
    return None


def check_alpha(img: Image.Image) -> tuple[bool, str]:
    """alpha 通道存在且至少有 5% 像素半透明或全透明"""
    if img.mode != "RGBA":
        return False, f"无 alpha 通道（mode={img.mode}）"
    alpha = img.getchannel("A")
    transparent = sum(1 for p in alpha.getdata() if p < 250)
    total = alpha.width * alpha.height
    ratio = transparent / total
    if ratio < 0.05:
        return False, f"几乎无透明像素（{ratio:.1%}），可能未抠图"
    return True, f"透明像素占比 {ratio:.1%}"


def check_name(filename: str) -> tuple[bool, str]:
    stem = Path(filename).stem
    if not NAME_PATTERN.match(stem):
        return False, f"命名含非法字符（仅允许 a-z 0-9 _）：{stem}"
    return True, "命名规范"


def check_size(img: Image.Image, category: str) -> tuple[bool, str]:
    target = expected_size(category)
    if target is None:
        return True, f"无强制尺寸（{img.size}）"
    if img.size != target:
        return False, f"尺寸 {img.size} ≠ 期望 {target}"
    return True, f"尺寸符合 {target}"


def check_meta_for_raw(raw_png: Path) -> tuple[bool, str]:
    meta = raw_png.with_suffix(".meta.json")
    if not meta.exists():
        return False, "缺少 .meta.json"
    try:
        d = json.loads(meta.read_text(encoding="utf-8"))
    except Exception as e:
        return False, f"meta.json 解析失败：{e}"
    required = {"prompt", "size", "quality", "generated_at"}
    missing = required - set(d.keys())
    if missing:
        return False, f"meta.json 缺字段：{missing}"
    return True, "meta 完整"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--strict", action="store_true", help="warn 也视为 fail")
    return p.parse_args()


def main() -> int:
    load_dotenv(PROJECT_ROOT / ".env")
    args = parse_args()

    raw_dir = PROJECT_ROOT / os.getenv("RAW_DIR", "assets/raw")
    proc_dir = PROJECT_ROOT / os.getenv("PROCESSED_DIR", "assets/processed")
    reports_dir = PROJECT_ROOT / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    findings: list[dict] = []

    # 校验 raw/
    if raw_dir.exists():
        for p in raw_dir.rglob("*.png"):
            rel = p.relative_to(raw_dir)
            category = str(rel.parent).replace("\\", "/")
            ok_meta, msg_meta = check_meta_for_raw(p)
            findings.append({
                "scope": "raw",
                "file": str(rel),
                "check": "meta",
                "ok": ok_meta,
                "msg": msg_meta,
            })

    # 校验 processed/
    if proc_dir.exists():
        for p in proc_dir.rglob("*.png"):
            if "_sheets" in p.parts:
                continue
            rel = p.relative_to(proc_dir)
            category = str(rel.parent).replace("\\", "/")
            try:
                img = Image.open(p)
            except Exception as e:
                findings.append({
                    "scope": "processed",
                    "file": str(rel),
                    "check": "open",
                    "ok": False,
                    "msg": f"无法打开：{e}",
                })
                continue

            for check_name_, fn in [
                ("alpha", lambda: check_alpha(img)),
                ("size", lambda: check_size(img, category)),
                ("name", lambda: check_name(p.name)),
            ]:
                ok, msg = fn()
                findings.append({
                    "scope": "processed",
                    "file": str(rel),
                    "check": check_name_,
                    "ok": ok,
                    "msg": msg,
                })

    if not findings:
        console.print("[yellow]raw/ 与 processed/ 都为空，无可校验内容[/yellow]")
        return 0

    # 汇总
    by_status = Counter("ok" if f["ok"] else "fail" for f in findings)
    table = Table(title="校验结果汇总", show_header=True, header_style="bold magenta")
    table.add_column("状态")
    table.add_column("数量", justify="right")
    table.add_row("通过", str(by_status.get("ok", 0)))
    table.add_row("失败", str(by_status.get("fail", 0)))
    console.print(table)

    # 失败清单
    failures = [f for f in findings if not f["ok"]]
    if failures:
        ftable = Table(title="失败明细", show_header=True, header_style="bold red")
        ftable.add_column("Scope")
        ftable.add_column("File")
        ftable.add_column("Check")
        ftable.add_column("Message")
        for f in failures[:50]:
            ftable.add_row(f["scope"], f["file"], f["check"], f["msg"])
        if len(failures) > 50:
            ftable.add_row("…", f"还有 {len(failures) - 50} 条", "…", "…")
        console.print(ftable)

    # 落盘报告
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = reports_dir / f"verify_{ts}.json"
    report_path.write_text(
        json.dumps(
            {"timestamp": ts, "summary": dict(by_status), "findings": findings},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    console.print(f"详细报告：{report_path}")

    if failures and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
