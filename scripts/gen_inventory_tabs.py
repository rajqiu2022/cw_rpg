"""
gen_inventory_tabs.py — 复用主菜单按钮底框风格生成背包Tab按钮

使用 assets/raw/ui/btn_menu_3states.png 作为底框来源（金属边框+宝石角饰+深绿渐变），
缩放为 Tab 大小(140x48) 后叠加华文行楷文字。

输出：game/art/ui/inventory/tabs/tab_<name>_<state>.png (共15张)
"""

from __future__ import annotations

import sys
from pathlib import Path

for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# --- Paths ---
# 直接用已有的主菜单按钮final图作为底框来源
FINAL_BTN_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "main_menu" / "buttons" / "final"
OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "inventory" / "tabs"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# 底框来源映射（用quit因为文字最少，缩小后不明显）
FRAME_SOURCES = {
    "normal": FINAL_BTN_DIR / "btn_quit_normal.png",
    "hover": FINAL_BTN_DIR / "btn_quit_hover.png",
    "pressed": FINAL_BTN_DIR / "btn_quit_pressed.png",
}

# --- Tab config ---
TABS = [
    ("all", "全部"),
    ("consumable", "消耗"),
    ("equipment", "装备"),
    ("key", "剧情"),
    ("material", "材料"),
]

# Tab尺寸 — 比主菜单按钮小
TAB_W, TAB_H = 140, 48


def find_chinese_font(size: int = 24) -> ImageFont.FreeTypeFont:
    """Find a suitable Chinese calligraphy font."""
    font_candidates = [
        "C:/Windows/Fonts/STXINGKA.TTF",     # 华文行楷
        "C:/Windows/Fonts/STCAIYUN.TTF",     # 华文彩云
        "C:/Windows/Fonts/STLITI.TTF",       # 华文隶书
        "C:/Windows/Fonts/STZHONGS.TTF",     # 华文中宋
        "C:/Windows/Fonts/simhei.ttf",       # 黑体
        "C:/Windows/Fonts/msyh.ttc",         # 微软雅黑
    ]

    for fp in font_candidates:
        if Path(fp).exists():
            print(f"  Using font: {fp}")
            return ImageFont.truetype(fp, size)

    print("  [WARN] No suitable Chinese font found, using default")
    return ImageFont.load_default()


def remove_gray_background(img: Image.Image, threshold: int = 30) -> Image.Image:
    """Remove near-gray background pixels, making them transparent."""
    arr = np.array(img).astype(np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    avg = (r + g + b) / 3.0
    spread = np.maximum(np.abs(r - avg), np.maximum(np.abs(g - avg), np.abs(b - avg)))

    is_bg = (spread < threshold) & (avg > 180)

    result = arr.copy()
    result[is_bg, 3] = 0
    return Image.fromarray(result.astype(np.uint8))


def load_frames() -> dict[str, Image.Image]:
    """Load 3 button frames from final main menu buttons."""
    frames = {}
    for state, path in FRAME_SOURCES.items():
        if not path.exists():
            print(f"  [WARN] Frame not found: {path}")
            continue
        img = Image.open(path).convert("RGBA")
        # 中间区域用半透明深色填充覆盖原文字
        # 取底框中心区域颜色平均值来盖掉文字
        arr = np.array(img)
        h, w = arr.shape[:2]
        # 文字大概在中间 60% 区域
        cy, cx = h // 2, w // 2
        region_h, region_w = int(h * 0.4), int(w * 0.5)
        y1, y2 = cy - region_h // 2, cy + region_h // 2
        x1, x2 = cx - region_w // 2, cx + region_w // 2
        # 用边框内侧的颜色填充文字区（取上方边框下面的颜色）
        sample_y = y1 - 5
        if sample_y > 0:
            sample_row = arr[sample_y, x1:x2]
            avg_color = sample_row[sample_row[:, 3] > 128].mean(axis=0).astype(np.uint8) if (sample_row[:, 3] > 128).any() else np.array([20, 50, 40, 255], dtype=np.uint8)
        else:
            avg_color = np.array([20, 50, 40, 255], dtype=np.uint8)
        
        # 用渐变填充覆盖文字区
        fill_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        fill_arr = np.array(fill_layer)
        for y in range(y1, y2):
            for x in range(x1, x2):
                if arr[y, x, 3] > 128:  # 只填充不透明区域
                    fill_arr[y, x] = avg_color
        
        filled = Image.alpha_composite(img, Image.fromarray(fill_arr))
        frames[state] = filled
        print(f"  Frame [{state}]: {w}x{h} (from {path.name})")

    return frames


def render_text_on_frame(frame: Image.Image, text: str, font: ImageFont.FreeTypeFont) -> Image.Image:
    """Render text centered on the tab frame."""
    # Resize frame to tab size
    tab = frame.resize((TAB_W, TAB_H), Image.LANCZOS)

    # Create text layer
    text_layer = Image.new("RGBA", (TAB_W, TAB_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(text_layer)

    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]

    # Center text
    x = (TAB_W - text_w) // 2
    y = (TAB_H - text_h) // 2 + 2

    # Shadow
    shadow_layer = Image.new("RGBA", (TAB_W, TAB_H), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_draw.text((x + 1, y + 1), text, font=font, fill=(0, 0, 0, 160))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(2))

    # Main text — white/silver
    draw.text((x, y), text, font=font, fill=(235, 235, 250, 255))

    # Composite
    result = tab.copy()
    result = Image.alpha_composite(result, shadow_layer)
    result = Image.alpha_composite(result, text_layer)

    return result


def main():
    print("=" * 60)
    print("  Inventory Tab Button Generator (wuxia style)")
    print("=" * 60)
    print(f"  Source frames: {FINAL_BTN_DIR}")
    print(f"  Output: {OUTPUT_DIR}")
    print(f"  Target size: {TAB_W}x{TAB_H}")
    print("=" * 60)

    # Load frames from main menu buttons
    print("\n### STEP 1: Load Tab Frames ###")
    frames = load_frames()

    if not frames:
        print("[ERROR] No frames loaded!")
        return

    # Load font (smaller for tab)
    print("\n### STEP 2: Load Font ###")
    font = find_chinese_font(size=22)

    # Generate: normal → frame[normal], selected → frame[hover], pressed → frame[pressed]
    state_mapping = {
        "normal": "normal",
        "selected": "hover",
        "pressed": "pressed",
    }

    print("\n### STEP 3: Generate Tab Buttons ###")
    for tab_key, tab_text in TABS:
        print(f"\n  Tab: {tab_text}")
        for out_state, frame_state in state_mapping.items():
            if frame_state not in frames:
                print(f"    [SKIP] No frame for {frame_state}")
                continue

            result = render_text_on_frame(frames[frame_state], tab_text, font)

            out_name = f"tab_{tab_key}_{out_state}.png"
            out_path = OUTPUT_DIR / out_name
            result.save(out_path, "PNG")
            print(f"    [OK] {out_name} ({result.size[0]}x{result.size[1]})")

    print(f"\n{'=' * 60}")
    print(f"  [DONE] All {len(TABS) * 3} tab buttons generated!")
    print(f"  Output: {OUTPUT_DIR}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
