"""
gen_menu_buttons.py — 生成主菜单按钮三态 sprite sheet 并自动切割

用法：
    python scripts/gen_menu_buttons.py              # 生成 + 切割
    python scripts/gen_menu_buttons.py --dry-run    # 只打印 prompt，不调 API
"""

from __future__ import annotations

import argparse
import base64
import sys
import os
from pathlib import Path

# Fix Windows encoding
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from dotenv import load_dotenv
from openai import OpenAI

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

# --- Config ---
PROMPT = """A horizontal sprite sheet showing 3 versions of the SAME ornate Chinese wuxia-style button frame,
arranged in a single row (3 columns, 1 row), with equal spacing between them.
Each button frame is approximately 480x140 pixels.

TRANSPARENT background (alpha channel, no solid bg).

Style: dark Gothic Chinese martial arts aesthetic, iron and jade ornamental frame,
cloud/wave motifs at corners, subtle bamboo leaf silhouettes inside the dark panel,
thin metallic border with slight glow.

The 3 states from LEFT to RIGHT:
1. NORMAL: Dark slate-blue interior, silver-grey metallic border, jade/teal gemstone accent on top center, muted tones.
2. HOVER: Same frame but border glows brighter cyan/teal, interior slightly lighter with faint luminous mist, teal gemstone glows.
3. PRESSED: Same frame but border turns warm gold/amber, interior darkens further, gemstone glows gold, slight inward shadow effect.

NO text on the buttons. Pure decorative frame only.
The frames should look identical in shape and size, differing only in color/glow treatment.
High detail, game UI asset quality, crisp edges suitable for sprite slicing."""

OUTPUT_RAW = PROJECT_ROOT / "assets" / "raw" / "ui" / "btn_menu_3states.png"
OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "buttons"

SIZE = "1536x512"
QUALITY = "high"
MODEL = os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-1")


def generate_image(dry_run: bool = False) -> Path | None:
    """调 API 生成图片并保存到 assets/raw/ui/"""
    print(f"[config] model={MODEL}, size={SIZE}, quality={QUALITY}")
    print(f"[config] base_url={os.getenv('OPENAI_BASE_URL', 'default')}")
    print(f"[prompt] {PROMPT[:80]}...")
    print()

    if dry_run:
        print("[dry-run] 不调 API，仅打印 prompt。")
        return None

    client = OpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        base_url=os.getenv("OPENAI_BASE_URL"),
    )

    print("[generating] 正在调用 AI 生成按钮 sprite sheet...")
    
    # Build kwargs
    kwargs = {
        "model": MODEL,
        "prompt": PROMPT,
        "size": SIZE,
        "quality": QUALITY,
        "n": 1,
    }
    
    # DMXAPI: lower moderation for wuxia content
    base_url = os.getenv("OPENAI_BASE_URL", "")
    extra_body = {}
    if "dmxapi" in base_url.lower() and MODEL.startswith("gpt-image"):
        extra_body["moderation"] = "low"
    
    response = client.images.generate(**kwargs, extra_body=extra_body or None)

    if not response.data or not response.data[0].b64_json:
        print("[error] API 未返回图像数据！")
        return None

    img_bytes = base64.b64decode(response.data[0].b64_json)
    OUTPUT_RAW.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_RAW.write_bytes(img_bytes)
    print(f"[saved] {OUTPUT_RAW} ({len(img_bytes) // 1024} KB)")

    # Print usage/cost info if available
    if hasattr(response, "usage") and response.usage:
        print(f"[usage] {response.usage}")

    return OUTPUT_RAW


def slice_sprite_sheet(src: Path) -> None:
    """将 3 列 sprite sheet 切割为 3 张独立按钮图"""
    from PIL import Image

    img = Image.open(src).convert("RGBA")
    w, h = img.size
    col_w = w // 3

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    names = ["btn_menu_normal.png", "btn_menu_hover.png", "btn_menu_pressed.png"]

    for i, name in enumerate(names):
        x0 = i * col_w
        x1 = x0 + col_w
        cell = img.crop((x0, 0, x1, h))

        # Trim transparent edges
        bbox = cell.getbbox()
        if bbox:
            cell = cell.crop(bbox)

        out_path = OUTPUT_DIR / name
        cell.save(out_path, "PNG")
        print(f"  [slice] {name}: {cell.size[0]}x{cell.size[1]}")

    print(f"[done] 按钮图已保存到 {OUTPUT_DIR}")


def main():
    parser = argparse.ArgumentParser(description="生成主菜单按钮三态")
    parser.add_argument("--dry-run", action="store_true", help="只打印不调 API")
    parser.add_argument("--slice-only", type=str, default=None,
                        help="仅切割已有图片（传路径）")
    args = parser.parse_args()

    if args.slice_only:
        slice_sprite_sheet(Path(args.slice_only))
        return

    result = generate_image(dry_run=args.dry_run)
    if result:
        slice_sprite_sheet(result)


if __name__ == "__main__":
    main()
