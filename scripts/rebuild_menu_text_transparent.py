#!/usr/bin/env python3
"""
重建主菜单按钮文字贴图：白底转透明

原始文字图 (assets/raw/ui/button/main_menu/text/v1/) 是白底暗色文字。
直接用亮度反转作为 alpha 通道：越暗的像素（文字）alpha 越高，白底 alpha=0。

输出：透明底彩色文字 PNG 到 game/art/ui/main_menu/buttons/text/v1/
"""
from PIL import Image, ImageFilter
import numpy as np
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

TEXT_DIR = os.path.join(PROJECT_ROOT, 'assets', 'raw', 'ui', 'button', 'main_menu', 'text', 'v1')
OUT_DIR = os.path.join(PROJECT_ROOT, 'game', 'art', 'ui', 'main_menu', 'buttons', 'text', 'v1')

os.makedirs(OUT_DIR, exist_ok=True)

# 输出尺寸 — 适配按钮底框 620x186 的中央区域
OUT_W, OUT_H = 480, 140


def remove_white_bg(src_path: str, out_path: str):
    """白底去除：用亮度反转做 alpha，裁剪到文字区域"""
    img = Image.open(src_path).convert('RGB')
    arr = np.array(img).astype(np.float32)

    # 计算亮度
    lum = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]

    # Alpha = 255 - lum（白色变透明，暗色变不透明）
    # 用一个更激进的映射：接近白色的快速归零
    # threshold: 亮度 > 240 视为纯背景
    alpha = np.clip((255.0 - lum) * (255.0 / 215.0), 0, 255).astype(np.uint8)
    # 极浅的区域（背景边缘噪点）直接清零
    alpha[lum > 245] = 0

    # 找到文字的包围框
    mask = alpha > 15
    ys, xs = np.where(mask)
    if len(xs) == 0:
        print(f'  ⚠ 未找到文字区域: {os.path.basename(src_path)}')
        return False

    x1, x2 = int(xs.min()), int(xs.max())
    y1, y2 = int(ys.min()), int(ys.max())

    # 加一点边距
    pad = 8
    x1 = max(0, x1 - pad)
    x2 = min(arr.shape[1] - 1, x2 + pad)
    y1 = max(0, y1 - pad)
    y2 = min(arr.shape[0] - 1, y2 + pad)

    # 裁剪
    crop_rgb = arr[y1:y2 + 1, x1:x2 + 1].astype(np.uint8)
    crop_alpha = alpha[y1:y2 + 1, x1:x2 + 1]

    # 文字颜色调亮为冷银白色 — 原始文字是暗色（用于白底），需反转为亮色（用于深色底框）
    text_pixels = crop_alpha > 30
    if text_pixels.any():
        # 将暗色文字反转为亮色：冷银白色调
        for c in range(3):
            channel = crop_rgb[:, :, c].astype(np.float32)
            # 反转亮度：暗→亮，保持层次感
            channel[text_pixels] = np.clip(255 - (255 - channel[text_pixels]) * 0.35, 200, 250)
            crop_rgb[:, :, c] = channel.astype(np.uint8)
        # 稍微降低 R 通道增加冷色调
        r_ch = crop_rgb[:, :, 0].astype(np.float32)
        r_ch[text_pixels] = np.clip(r_ch[text_pixels] * 0.92, 0, 255)
        crop_rgb[:, :, 0] = r_ch.astype(np.uint8)

    # 合成 RGBA
    rgba = np.dstack([crop_rgb, crop_alpha])
    result = Image.fromarray(rgba, 'RGBA')

    # 缩放到输出尺寸
    result = result.resize((OUT_W, OUT_H), Image.LANCZOS)

    # 最终再清理一次极低 alpha 像素（缩放可能引入）
    final_arr = np.array(result)
    final_arr[final_arr[:, :, 3] < 10, 3] = 0
    result = Image.fromarray(final_arr, 'RGBA')

    result.save(out_path)
    print(f'  [OK] {os.path.basename(out_path)} ({OUT_W}x{OUT_H})')
    print(f'       裁剪区域: ({x1},{y1})-({x2},{y2}), 文字像素: {mask.sum()}')
    return True


# 映射表：原始文件名 -> 输出文件名
FILE_MAP = [
    ('ui_btn_main_text_new_game_v1.png', 'btn_menu_text_new_game_v1.png'),
    ('ui_btn_main_text_load_v1.png', 'btn_menu_text_load_v1.png'),
    ('ui_btn_main_text_quit_v1.png', 'btn_menu_text_quit_v1.png'),
]

print('=== 重建主菜单文字贴图（白底→透明）===')
print(f'输出尺寸: {OUT_W}x{OUT_H}')
print()

for src_name, dst_name in FILE_MAP:
    src_path = os.path.join(TEXT_DIR, src_name)
    dst_path = os.path.join(OUT_DIR, dst_name)

    if not os.path.exists(src_path):
        print(f'  ✗ 源文件不存在: {src_name}')
        continue

    print(f'处理: {src_name}')
    remove_white_bg(src_path, dst_path)
    print()

print('完成！输出目录:', OUT_DIR)
