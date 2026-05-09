"""
gen_buttons_from_v5.py — 从 v5 主菜单整图裁切按钮 + 生成三态变体

策略：
1. 从 ui_main_menu_full_v5.png 裁切出三个按钮区域
2. Normal = 原图直切
3. Hover = 增加亮度 + 外发光边缘
4. Pressed = 略微变暗 + 缩小 2px 模拟按下

同时生成一张去按钮的纯背景图供 Godot 使用。
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

from PIL import Image, ImageEnhance, ImageFilter, ImageDraw
import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# --- Paths ---
SRC_IMG = PROJECT_ROOT / "assets" / "raw" / "scene_background" / "ui_main_menu_full_v5.png"
BTN_OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "main_menu" / "buttons" / "final"
BG_OUTPUT_DIR = PROJECT_ROOT / "game" / "art" / "backgrounds"

BTN_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
BG_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# --- Button regions (precisely measured from v5 image: 1536x1024) ---
# 三个按钮在右半侧垂直排列：
# 新游戏（绿色）：y=425-545, x≈920-1440
# 读取存档（青色）：y=590-710, x≈920-1440
# 离开（红色）：y=755-870, x≈910-1440
# 
# 给额外 padding 让 trim 来精确处理
BUTTON_REGIONS = [
    ("btn_new_game",  (900, 420, 1450, 545)),
    ("btn_continue",  (900, 585, 1450, 715)),
    ("btn_quit",      (900, 755, 1450, 875)),
]

# 最终按钮尺寸
BTN_W, BTN_H = 480, 140


def crop_button(img: Image.Image, region: tuple) -> Image.Image:
    """Crop a button region and smart-trim to the button boundary."""
    cropped = img.crop(region)
    arr = np.array(cropped).astype(float)
    
    # 按钮特征：边框和填充区域比山水背景暗很多
    # 找到比较暗的连续区域作为按钮本体
    brightness = arr[:, :, :3].mean(axis=2)
    
    # 用行/列平均亮度找边界
    col_avg = brightness.mean(axis=0)  # 每列的平均亮度
    row_avg = brightness.mean(axis=1)  # 每行的平均亮度
    
    # 按钮内部普遍很暗（<80），背景较亮（>100）
    # 找列方向上暗区域
    dark_cols = col_avg < 100
    dark_rows = row_avg < 100
    
    col_idx = np.where(dark_cols)[0]
    row_idx = np.where(dark_rows)[0]
    
    if len(col_idx) > 10 and len(row_idx) > 10:
        x1 = max(0, col_idx[0] - 5)
        x2 = min(cropped.width, col_idx[-1] + 5)
        y1 = max(0, row_idx[0] - 5)
        y2 = min(cropped.height, row_idx[-1] + 5)
        cropped = cropped.crop((x1, y1, x2, y2))
    
    return cropped


def create_hover(btn: Image.Image) -> Image.Image:
    """Create hover state: brighter + subtle glow edge."""
    # 增加亮度
    enhancer = ImageEnhance.Brightness(btn)
    bright = enhancer.enhance(1.25)
    
    # 增加对比度
    enhancer2 = ImageEnhance.Contrast(bright)
    result = enhancer2.enhance(1.1)
    
    # 加一层淡金色外发光
    arr = np.array(result).astype(np.float32)
    # 检测边缘像素（alpha > 0 且接近边界）
    alpha = arr[:, :, 3]
    
    # 创建发光层
    glow = Image.new("RGBA", result.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    
    # 绘制边框发光
    w, h = result.size
    # 外边框发光（金色半透明）
    for offset in range(3, 0, -1):
        alpha_val = int(40 * (4 - offset))
        glow_draw.rectangle(
            [offset, offset, w - offset - 1, h - offset - 1],
            outline=(255, 215, 100, alpha_val)
        )
    
    # 合成
    result = Image.alpha_composite(result, glow)
    return result


def create_pressed(btn: Image.Image) -> Image.Image:
    """Create pressed state: darker + slight inward offset."""
    # 变暗
    enhancer = ImageEnhance.Brightness(btn)
    dark = enhancer.enhance(0.8)
    
    # 增加饱和度表示按下
    enhancer2 = ImageEnhance.Color(dark)
    result = enhancer2.enhance(1.15)
    
    # 稍微缩小然后放回原尺寸（模拟按下位移）
    w, h = result.size
    shrink = result.resize((w - 4, h - 4), Image.LANCZOS)
    
    # 放回居中
    final = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    final.paste(shrink, (2, 2))
    
    return final


def create_clean_background(img: Image.Image, regions: list) -> Image.Image:
    """Create background with buttons area inpainted (simple fill with surrounding colors)."""
    bg = img.copy()
    
    for _, region in regions:
        x1, y1, x2, y2 = region
        # 用按钮区域周围的背景色填充（取上方一行的平均色）
        # 简单方案：用内容感知填充的简化版 —— 取周围像素的均值渐变
        
        # 取按钮区域左右两侧的像素做渐变填充
        left_strip = np.array(bg.crop((x1 - 20, y1, x1, y2)))
        right_strip = np.array(bg.crop((x2, y1, x2 + 20, y2)))
        top_strip = np.array(bg.crop((x1, y1 - 20, x2, y1)))
        bottom_strip = np.array(bg.crop((x1, y2, x2, y2 + 20)))
        
        # 计算周围平均色
        all_border = np.concatenate([
            left_strip.reshape(-1, left_strip.shape[-1]),
            right_strip.reshape(-1, right_strip.shape[-1]),
            top_strip.reshape(-1, top_strip.shape[-1]),
            bottom_strip.reshape(-1, bottom_strip.shape[-1]),
        ], axis=0)
        avg_color = tuple(all_border.mean(axis=0).astype(int)[:3])
        
        # 渐变填充：从边缘向中心渐变
        region_w = x2 - x1
        region_h = y2 - y1
        fill_img = Image.new("RGB", (region_w, region_h), avg_color)
        
        # 简单高斯模糊使过渡更自然
        bg.paste(fill_img, (x1, y1))
    
    # 对填充区域做模糊柔化
    bg_arr = np.array(bg)
    # 整体不动，只对按钮区域做一次大范围模糊
    for _, region in regions:
        x1, y1, x2, y2 = region
        # 扩大模糊范围
        bx1 = max(0, x1 - 30)
        by1 = max(0, y1 - 30)
        bx2 = min(bg.width, x2 + 30)
        by2 = min(bg.height, y2 + 30)
        
        patch = bg.crop((bx1, by1, bx2, by2))
        patch = patch.filter(ImageFilter.GaussianBlur(15))
        bg.paste(patch, (bx1, by1))
    
    return bg


def main():
    print("=" * 60)
    print("  Button Extractor from v5 Main Menu")
    print("=" * 60)
    
    if not SRC_IMG.exists():
        print(f"[ERROR] Source image not found: {SRC_IMG}")
        return
    
    # Load source
    print(f"\nLoading: {SRC_IMG.name}")
    src = Image.open(SRC_IMG).convert("RGBA")
    w, h = src.size
    print(f"  Size: {w}x{h}")
    
    # Scale regions if image is not exactly 1536x1024
    scale_x = w / 1536
    scale_y = h / 1024
    
    scaled_regions = []
    for name, (x1, y1, x2, y2) in BUTTON_REGIONS:
        sx1 = int(x1 * scale_x)
        sy1 = int(y1 * scale_y)
        sx2 = int(x2 * scale_x)
        sy2 = int(y2 * scale_y)
        scaled_regions.append((name, (sx1, sy1, sx2, sy2)))
    
    # Step 1: Crop buttons and generate 3 states
    print("\n### STEP 1: Crop & Generate Button States ###")
    
    for btn_name, region in scaled_regions:
        print(f"\n  [{btn_name}] region={region}")
        
        # Crop
        btn_raw = crop_button(src, region)
        
        # Resize to target
        btn_normal = btn_raw.resize((BTN_W, BTN_H), Image.LANCZOS)
        
        # Generate states
        btn_hover = create_hover(btn_normal)
        btn_pressed = create_pressed(btn_normal)
        
        # Save
        for state, img in [("normal", btn_normal), ("hover", btn_hover), ("pressed", btn_pressed)]:
            out_path = BTN_OUTPUT_DIR / f"{btn_name}_{state}.png"
            img.save(out_path, "PNG")
            print(f"    [{state}] saved: {out_path.name} ({img.size[0]}x{img.size[1]})")
    
    # Step 2: Generate clean background (without buttons)
    print("\n### STEP 2: Generate Clean Background ###")
    bg_clean = create_clean_background(src.convert("RGB"), scaled_regions)
    bg_out = BG_OUTPUT_DIR / "bg_main_menu_v5.png"
    bg_clean.save(bg_out, "PNG")
    print(f"  Saved: {bg_out.name} ({bg_clean.size[0]}x{bg_clean.size[1]})")
    
    print(f"\n{'=' * 60}")
    print("  [DONE] 9 button PNGs + 1 clean background generated!")
    print(f"  Buttons: {BTN_OUTPUT_DIR}")
    print(f"  Background: {bg_out}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
