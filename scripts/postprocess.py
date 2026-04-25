"""
postprocess.py — 资产后处理流水线

输入：assets/raw/{category}/{name}.png（GPT Image 2 直出，纯色背景）
输出：assets/processed/{category}/{name}.png（透明背景 + 标准化尺寸）

可选：将同角色 sprite 自动拼装为横向 sprite sheet。

用法：
    python scripts/postprocess.py                # 处理 raw/ 全部新文件
    python scripts/postprocess.py --category sprite/bujingyun
    python scripts/postprocess.py --no-rembg     # 跳过抠图（已经是透明的素材）
    python scripts/postprocess.py --pack-sheets  # 处理后拼 sprite sheet
    python scripts/postprocess.py --force        # 重处理已存在的输出
"""

from __future__ import annotations

import argparse
import os
import sys
from collections import defaultdict
from pathlib import Path
from typing import Iterable

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
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TextColumn,
    TimeElapsedColumn,
)
from rich.table import Table

PROJECT_ROOT = Path(__file__).resolve().parent.parent
console = Console()

# 各类别的目标输出尺寸（None 表示保持原图尺寸）
TARGET_SIZES = {
    "sprite": (256, 256),       # sprite 全部 256×256 网格
    "ui/icon/skill": (128, 128),
    "ui/icon/item": (128, 128),
    "ui/button": (512, 170),    # 3:1 长宽比
    "ui/dialog": None,
    "scene": None,
    "tileset": None,            # tileset 不抠图，单独切
    "character": None,
}


def get_target_size(category: str) -> tuple[int, int] | None:
    """根据类别匹配目标尺寸（前缀匹配）"""
    for prefix, size in TARGET_SIZES.items():
        if category == prefix or category.startswith(prefix + "/"):
            return size
    return None


def remove_background(img_bytes: bytes) -> bytes:
    """
    用 rembg 抠透明背景。
    rembg 首次调用会下载 onnx 模型（~170MB），缓存在 ~/.u2net/。
    """
    from rembg import remove
    return remove(img_bytes)


def normalize_size(img: Image.Image, target: tuple[int, int]) -> Image.Image:
    """
    保持宽高比缩放到 target 内部，居中粘贴到透明画布。
    """
    img = img.convert("RGBA")
    img.thumbnail(target, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", target, (0, 0, 0, 0))
    offset = ((target[0] - img.width) // 2, (target[1] - img.height) // 2)
    canvas.paste(img, offset, img)
    return canvas


def process_single(
    src: Path,
    dst: Path,
    category: str,
    use_rembg: bool,
) -> dict:
    """处理单张图，返回 result dict"""
    dst.parent.mkdir(parents=True, exist_ok=True)
    raw_bytes = src.read_bytes()

    # 抠背景（tileset 类除外）
    if use_rembg and not category.startswith("tileset"):
        try:
            cut_bytes = remove_background(raw_bytes)
        except Exception as e:
            return {"src": str(src), "status": "rembg_error", "error": str(e)}
        from io import BytesIO
        img = Image.open(BytesIO(cut_bytes))
    else:
        img = Image.open(src)

    # 标准化尺寸
    target = get_target_size(category)
    if target is not None:
        img = normalize_size(img, target)
    else:
        img = img.convert("RGBA")

    img.save(dst, "PNG", optimize=True)
    return {"src": str(src), "dst": str(dst), "status": "ok", "size": img.size}


def pack_sprite_sheet(sprites: list[Path], out: Path, cols: int = 0) -> dict:
    """
    将一组同尺寸 sprite 拼成横向 sprite sheet。
    cols=0 表示全部排在一行；否则按 cols 列网格。
    """
    if not sprites:
        return {"status": "empty"}
    images = [Image.open(p).convert("RGBA") for p in sprites]
    w, h = images[0].size
    # 校验尺寸一致
    for i, im in enumerate(images[1:], start=1):
        if im.size != (w, h):
            return {
                "status": "size_mismatch",
                "error": f"{sprites[i].name} 尺寸 {im.size} 与首张 {(w, h)} 不一致",
            }

    if cols <= 0:
        cols = len(images)
    rows = (len(images) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * w, rows * h), (0, 0, 0, 0))
    for i, im in enumerate(images):
        r, c = divmod(i, cols)
        sheet.paste(im, (c * w, r * h), im)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, "PNG", optimize=True)
    return {"status": "ok", "out": str(out), "frames": len(images), "tile": (w, h)}


def discover_raw_files(raw_dir: Path, category_filter: str | None) -> Iterable[tuple[Path, str]]:
    """递归找 raw/ 下所有 PNG，返回 (path, category)"""
    for p in raw_dir.rglob("*.png"):
        rel = p.relative_to(raw_dir)
        # category = 除文件名外的相对父路径
        category = str(rel.parent).replace("\\", "/")
        if category == ".":
            category = "misc"
        if category_filter and not (
            category == category_filter or category.startswith(category_filter + "/")
        ):
            continue
        yield p, category


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="资产后处理（rembg + 标准化 + sprite sheet）")
    p.add_argument("--category", help="只处理指定类别（如 sprite/bujingyun）")
    p.add_argument("--no-rembg", action="store_true", help="跳过抠图")
    p.add_argument("--pack-sheets", action="store_true", help="处理后将 sprite/* 拼为 sheet")
    p.add_argument("--force", action="store_true", help="覆盖已存在的输出")
    return p.parse_args()


def main() -> int:
    load_dotenv(PROJECT_ROOT / ".env")
    args = parse_args()

    raw_dir = PROJECT_ROOT / os.getenv("RAW_DIR", "assets/raw")
    proc_dir = PROJECT_ROOT / os.getenv("PROCESSED_DIR", "assets/processed")
    raw_dir.mkdir(parents=True, exist_ok=True)
    proc_dir.mkdir(parents=True, exist_ok=True)

    files = list(discover_raw_files(raw_dir, args.category))
    if not files:
        console.print("[yellow]未在 raw/ 找到匹配的 PNG[/yellow]")
        return 0

    # 跳过已存在
    pending = []
    for src, cat in files:
        rel = src.relative_to(raw_dir)
        dst = proc_dir / rel
        if dst.exists() and not args.force:
            continue
        pending.append((src, dst, cat))

    if not pending:
        console.print("[green]所有文件均已处理（如需重处理用 --force）[/green]")
    else:
        console.print(f"待处理：{len(pending)} 张")

    results = []
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("{task.completed}/{task.total}"),
        TimeElapsedColumn(),
        console=console,
    ) as progress:
        pb = progress.add_task("后处理…", total=len(pending))
        for src, dst, cat in pending:
            r = process_single(src, dst, cat, use_rembg=not args.no_rembg)
            results.append(r)
            progress.update(pb, advance=1)

    # 汇总
    ok = [r for r in results if r["status"] == "ok"]
    failed = [r for r in results if r["status"] != "ok"]
    summary = Table(title="后处理结果", show_header=True, header_style="bold magenta")
    summary.add_column("状态")
    summary.add_column("数量", justify="right")
    summary.add_row("成功", str(len(ok)))
    summary.add_row("失败", str(len(failed)))
    console.print(summary)
    for r in failed:
        console.print(f"  [red][x] {r['src']}: {r.get('error', r['status'])}[/red]")

    # 拼 sprite sheet
    if args.pack_sheets:
        console.print("\n[bold]拼装 sprite sheet…[/bold]")
        # 按 character 分组：sprite/<character>/<id>.png
        groups: dict[str, list[Path]] = defaultdict(list)
        for p in proc_dir.rglob("*.png"):
            rel = p.relative_to(proc_dir)
            parts = rel.parts
            if len(parts) >= 2 and parts[0] == "sprite":
                char = parts[1]
                groups[char].append(p)

        sheet_table = Table(title="Sprite Sheet 拼装", show_header=True)
        sheet_table.add_column("角色")
        sheet_table.add_column("帧数", justify="right")
        sheet_table.add_column("输出")
        for char, sprites in sorted(groups.items()):
            sprites.sort(key=lambda p: p.name)
            sheet_out = proc_dir / "_sheets" / f"{char}_sheet.png"
            r = pack_sprite_sheet(sprites, sheet_out, cols=8)
            if r["status"] == "ok":
                sheet_table.add_row(char, str(r["frames"]), str(sheet_out))
            else:
                sheet_table.add_row(char, "-", f"[red]{r.get('error', r['status'])}[/red]")
        console.print(sheet_table)

    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
