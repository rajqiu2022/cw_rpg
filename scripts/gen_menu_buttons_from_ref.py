"""
gen_menu_buttons_from_ref.py — 从 btn_menu_3states.png 裁切底框 + 合成书法文字

btn_menu_3states.png 包含三个按钮底框（从左到右）:
  1. Normal (银灰边框)
  2. Hover (青色发光边框)
  3. Pressed (金色边框)

本脚本：
1. 裁切出三个底框
2. 用华文行楷/书法字体渲染白色文字
3. 合成最终 9 张按钮贴图

输出：game/art/ui/main_menu/buttons/final/btn_<name>_<state>.png
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
REF_IMG_PATH = PROJECT_ROOT / "assets" / "raw" / "ui" / "btn_menu_3states.png"
OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "main_menu" / "buttons" / "final"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# --- Button config ---
BUTTONS = [
    ("new_game", "新游戏"),
    ("continue", "读取存档"),
    ("quit", "离开"),
]

# Target button size in game
BTN_W, BTN_H = 550, 165


def find_chinese_font(size: int = 60) -> ImageFont.FreeTypeFont:
    """Find a suitable Chinese calligraphy font."""
    font_candidates = [
        "C:/Windows/Fonts/STXINGKA.TTF",     # 华文行楷
        "C:/Windows/Fonts/STCAIYUN.TTF",     # 华文彩云
        "C:/Windows/Fonts/STLITI.TTF",       # 华文隶书
        "C:/Windows/Fonts/STZHONGS.TTF",     # 华文中宋
        "C:/Windows/Fonts/STSONG.TTF",       # 华文宋体
        "C:/Windows/Fonts/simhei.ttf",       # 黑体
        "C:/Windows/Fonts/simsun.ttc",       # 宋体
        "C:/Windows/Fonts/msyh.ttc",         # 微软雅黑
    ]
    
    for fp in font_candidates:
        if Path(fp).exists():
            print(f"  Using font: {fp}")
            return ImageFont.truetype(fp, size)
    
    # Fallback
    print("  [WARN] No suitable Chinese font found, using default")
    return ImageFont.load_default()


def remove_gray_background(img: Image.Image, threshold: int = 30) -> Image.Image:
    """Remove near-gray background pixels (the checkered/solid gray bg) and make them transparent."""
    import numpy as np
    
    arr = np.array(img).astype(np.float32)
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    
    # Detect gray-ish pixels: R≈G≈B and value > 180 (light gray background)
    # The bg is around (217-220, 217-220, 217-220)
    avg = (r + g + b) / 3.0
    spread = np.maximum(np.abs(r - avg), np.maximum(np.abs(g - avg), np.abs(b - avg)))
    
    # Gray = low spread between channels AND high brightness (background gray is ~218)
    is_bg = (spread < threshold) & (avg > 180)
    
    # Make background pixels transparent
    result = arr.copy()
    result[is_bg, 3] = 0  # Set alpha to 0 for background pixels
    
    return Image.fromarray(result.astype(np.uint8))


def extract_frames_from_reference() -> dict[str, Image.Image]:
    """Extract 3 button frames from the reference sprite sheet."""
    
    print(f"Loading reference: {REF_IMG_PATH.name}")
    ref = Image.open(REF_IMG_PATH).convert("RGBA")
    w, h = ref.size
    print(f"  Reference size: {w}x{h}")
    
    # Step 1: Remove the gray background
    print("  Removing gray background...")
    ref = remove_gray_background(ref)
    
    # The reference has 3 buttons side by side
    # Split into thirds
    btn_w = w // 3
    
    frames = {}
    state_names = ["normal", "hover", "pressed"]
    
    for i, state in enumerate(state_names):
        left = i * btn_w
        right = (i + 1) * btn_w
        frame = ref.crop((left, 0, right, h))
        
        # Trim transparent edges to get just the button
        bbox = frame.getbbox()
        if bbox:
            frame = frame.crop(bbox)
        
        frames[state] = frame
        print(f"  Frame [{state}]: {frame.size[0]}x{frame.size[1]}")
    
    return frames


def render_text_on_frame(frame: Image.Image, text: str, font: ImageFont.FreeTypeFont) -> Image.Image:
    """Render calligraphy text centered on the button frame."""
    
    # Resize frame to target button size
    btn = frame.resize((BTN_W, BTN_H), Image.LANCZOS)
    
    # Create text layer
    text_layer = Image.new("RGBA", (BTN_W, BTN_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(text_layer)
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    
    # Center text (slightly lower to account for top ornament)
    x = (BTN_W - text_w) // 2
    y = (BTN_H - text_h) // 2 + 8  # offset down slightly for the top gem decoration
    
    # Draw subtle shadow/glow
    shadow_layer = Image.new("RGBA", (BTN_W, BTN_H), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_draw.text((x, y), text, font=font, fill=(0, 0, 0, 180))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(3))
    
    # Draw main text in white/silver
    draw.text((x, y), text, font=font, fill=(240, 240, 255, 255))
    
    # Composite: frame + shadow + text
    result = btn.copy()
    result = Image.alpha_composite(result, shadow_layer)
    result = Image.alpha_composite(result, text_layer)
    
    return result


def main():
    print("=" * 60)
    print("  Wuxia Button Generator (from reference)")
    print("=" * 60)
    print(f"  Reference: {REF_IMG_PATH}")
    print(f"  Output: {OUTPUT_DIR}")
    print(f"  Target size: {BTN_W}x{BTN_H}")
    print("=" * 60)
    
    if not REF_IMG_PATH.exists():
        print(f"[ERROR] Reference image not found: {REF_IMG_PATH}")
        return
    
    # Step 1: Extract frames
    print("\n### STEP 1: Extract Button Frames ###")
    frames = extract_frames_from_reference()
    
    # Step 2: Find font
    print("\n### STEP 2: Load Font ###")
    font = find_chinese_font(size=56)
    
    # Step 3: Composite
    print("\n### STEP 3: Generate Final Buttons ###")
    for btn_key, btn_text in BUTTONS:
        print(f"\n  Button: {btn_text}")
        for state in ["normal", "hover", "pressed"]:
            if state not in frames:
                print(f"    [SKIP] No frame for {state}")
                continue
            
            result = render_text_on_frame(frames[state], btn_text, font)
            
            out_name = f"btn_{btn_key}_{state}.png"
            out_path = OUTPUT_DIR / out_name
            result.save(out_path, "PNG")
            print(f"    [OK] {out_name} ({result.size[0]}x{result.size[1]})")
    
    print(f"\n{'=' * 60}")
    print("  [DONE] All 9 buttons generated!")
    print(f"  Output: {OUTPUT_DIR}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
