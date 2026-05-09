"""
合成主菜单按钮：底框 + 去白底文字叠加
- 底框来自 game/art/ui/button/btn_menu_{normal,hover,pressed}_v1.png
- 文字来自 assets/raw/ui_button/ui_btn_main_text_{new_game,load,quit}_v1.png
- 去白底、缩放文字、居中叠加
- 输出到 game/art/ui/main_menu/buttons/final/
"""
import sys
from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parent.parent

# 底框路径
FRAME_DIR = ROOT / "game" / "art" / "ui" / "button"
FRAME_STATES = {
    "normal": FRAME_DIR / "btn_menu_normal_v1.png",
    "hover": FRAME_DIR / "btn_menu_hover_v1.png",
    "pressed": FRAME_DIR / "btn_menu_pressed_v1.png",
}

# 文字路径
TEXT_DIR = ROOT / "assets" / "raw" / "ui_button"
TEXT_FILES = {
    "new_game": TEXT_DIR / "ui_btn_main_text_new_game_v1.png",
    "load": TEXT_DIR / "ui_btn_main_text_load_v1.png",
    "quit": TEXT_DIR / "ui_btn_main_text_quit_v1.png",
}

# 输出目录
OUTPUT_DIR = ROOT / "game" / "art" / "ui" / "main_menu" / "buttons" / "final"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def remove_white_background(img: Image.Image, threshold: int = 240) -> Image.Image:
    """去除白色/近白色背景，转为透明"""
    img = img.convert("RGBA")
    arr = np.array(img, dtype=np.float32)
    
    # 计算每个像素与白色的距离
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    
    # 如果 R、G、B 都大于 threshold，认为是白色背景
    white_mask = (r > threshold) & (g > threshold) & (b > threshold)
    
    # 渐变处理：接近白色的区域逐渐变透明
    # 计算亮度
    brightness = (r + g + b) / 3.0
    
    # 在 threshold-20 到 threshold 之间做渐变
    fade_start = threshold - 40
    fade_mask = brightness > fade_start
    
    # 计算新的 alpha
    new_alpha = np.where(
        white_mask,
        0,  # 完全白色 -> 完全透明
        np.where(
            fade_mask,
            # 渐变区域
            ((threshold - brightness) / (threshold - fade_start)).clip(0, 1) * a,
            a  # 保持原 alpha
        )
    )
    
    arr[:,:,3] = new_alpha
    return Image.fromarray(arr.astype(np.uint8))


def brighten_text(img: Image.Image, factor: float = 1.4) -> Image.Image:
    """增亮文字像素，使其在深色背景上更醒目"""
    arr = np.array(img, dtype=np.float32)
    # 只处理有内容的像素（alpha > 0）
    mask = arr[:,:,3] > 0
    for c in range(3):  # R, G, B
        channel = arr[:,:,c]
        channel[mask] = np.clip(channel[mask] * factor, 0, 255)
        arr[:,:,c] = channel
    return Image.fromarray(arr.astype(np.uint8))


def compose_button(frame_path: Path, text_path: Path, output_path: Path,
                   text_scale: float = 0.55):
    """将文字缩放后居中叠加到底框上"""
    frame = Image.open(frame_path).convert("RGBA")
    text_img = Image.open(text_path).convert("RGBA")
    
    # 去除文字的白色背景
    text_clean = remove_white_background(text_img, threshold=235)
    
    # 增亮文字使其在深色底框上更清晰
    text_clean = brighten_text(text_clean, factor=2.2)
    
    # 计算文字缩放尺寸 - 文字高度为底框高度的 text_scale 比例
    frame_w, frame_h = frame.size
    target_h = int(frame_h * text_scale)
    
    # 按比例缩放，保持宽高比
    text_w, text_h = text_clean.size
    scale_ratio = target_h / text_h
    target_w = int(text_w * scale_ratio)
    
    # 确保文字宽度不超过底框宽度的 70%
    max_w = int(frame_w * 0.70)
    if target_w > max_w:
        target_w = max_w
        scale_ratio = target_w / text_w
        target_h = int(text_h * scale_ratio)
    
    text_resized = text_clean.resize((target_w, target_h), Image.LANCZOS)
    
    # 居中叠加
    x = (frame_w - target_w) // 2
    y = (frame_h - target_h) // 2
    
    # 创建输出图
    result = frame.copy()
    result.paste(text_resized, (x, y), text_resized)
    
    result.save(output_path)
    print(f"  [OK] {output_path.name} ({frame_w}x{frame_h})")


def main():
    print("[compose] Composing main menu buttons...")
    print(f"[compose] Output dir: {OUTPUT_DIR}")
    
    # 检查所有文件存在
    for name, path in {**FRAME_STATES, **TEXT_FILES}.items():
        if not path.exists():
            print(f"[ERROR] Missing: {path}")
            sys.exit(1)
    
    # 对每个按钮名 × 每个状态生成
    btn_names = ["new_game", "load", "quit"]
    states = ["normal", "hover", "pressed"]
    
    for btn_name in btn_names:
        text_path = TEXT_FILES[btn_name]
        print(f"\n[compose] Button: {btn_name}")
        for state in states:
            frame_path = FRAME_STATES[state]
            output_name = f"btn_{btn_name}_{state}.png"
            output_path = OUTPUT_DIR / output_name
            compose_button(frame_path, text_path, output_path)
    
    print(f"\n[compose] Done! Generated {len(btn_names) * len(states)} button images.")
    print(f"[compose] Output directory: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
