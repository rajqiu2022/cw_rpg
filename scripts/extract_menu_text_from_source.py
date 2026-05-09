#!/usr/bin/env python3
"""
从 assets/raw/ui/button/main_menu/text/v1 原始图提取文字层
保留原图的文字风格和颜色，输出透明底 PNG 到 game/art/ui/main_menu/buttons/text/v1
"""
from PIL import Image, ImageFilter
import numpy as np
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

TEXT_DIR = os.path.join(PROJECT_ROOT, 'assets/raw/ui/button/main_menu/text/v1')
FRAME_DIR = os.path.join(PROJECT_ROOT, 'assets/raw/ui/button/main_menu/frame/v1')
OUT_DIR = os.path.join(PROJECT_ROOT, 'game/art/ui/main_menu/buttons/text/v1')

os.makedirs(OUT_DIR, exist_ok=True)

# 底框基准图（三态文字位置相同，用 normal 做差分）
FRAME_PATH = os.path.join(FRAME_DIR, 'ui_btn_main_frame_normal_v1.png')

# 输出尺寸（适配当前按钮底框 496x149）
OUT_W, OUT_H = 420, 120

def extract_text(text_path: str, frame_path: str, out_path: str):
    text_img = Image.open(text_path).convert('RGB')
    frame_img = Image.open(frame_path).convert('RGB')

    text_rgb = np.array(text_img)
    frame_rgb = np.array(frame_img)

    h, w = text_rgb.shape[:2]

    # 计算差异（文字区域与底框的不同）
    diff = np.abs(text_rgb.astype(np.int16) - frame_rgb.astype(np.int16)).sum(axis=2)

    # 用亮度+饱和度辅助识别文字像素（文字通常偏亮或偏暗，与底框不同）
    lum = 0.299 * text_rgb[:, :, 0] + 0.587 * text_rgb[:, :, 1] + 0.114 * text_rgb[:, :, 2]
    sat = np.max(text_rgb, axis=2) - np.min(text_rgb, axis=2)

    # 文字掩码：与底框有差异，且不是纯白/纯灰边框
    # 放宽条件，保留更多文字细节
    mask = (diff > 20) | ((lum < 200) & (diff > 12))

    ys, xs = np.where(mask)
    if len(xs) == 0:
        print(f'  ⚠ 未找到文字区域: {os.path.basename(text_path)}')
        return False

    x1, x2 = int(xs.min()), int(xs.max())
    y1, y2 = int(ys.min()), int(ys.max())

    # 加边距
    pad_x = max(12, int((x2 - x1 + 1) * 0.08))
    pad_y = max(10, int((y2 - y1 + 1) * 0.10))

    x1 = max(0, x1 - pad_x)
    x2 = min(w - 1, x2 + pad_x)
    y1 = max(0, y1 - pad_y)
    y2 = min(h - 1, y2 + pad_y)

    # 裁剪文字区域
    crop_rgb = text_rgb[y1:y2 + 1, x1:x2 + 1]
    crop_diff = diff[y1:y2 + 1, x1:x2 + 1]

    # 生成 alpha 通道：差异大的地方不透明
    alpha = np.clip((crop_diff - 10) * 8, 0, 255).astype(np.uint8)
    # 过滤掉差异很小（接近底框）的像素
    alpha[alpha < 25] = 0

    # 创建 RGBA 图像
    rgba = np.dstack([crop_rgb, alpha])

    # 保存为临时 PNG（不缩放，保留原风格）
    tmp_img = Image.fromarray(rgba, 'RGBA')

    # 缩放到输出尺寸
    tmp_img = tmp_img.resize((OUT_W, OUT_H), Image.LANCZOS)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    tmp_img.save(out_path)
    print('  [OK] %s (%dx%d)' % (os.path.basename(out_path), OUT_W, OUT_H))
    return True


# 映射表：原始文件名 -> 输出文件名
FILE_MAP = [
    ('ui_btn_main_text_new_game_v1.png', 'btn_menu_text_new_game_v1.png'),
    ('ui_btn_main_text_load_v1.png', 'btn_menu_text_load_v1.png'),
    ('ui_btn_main_text_quit_v1.png', 'btn_menu_text_quit_v1.png'),
]

print('从原始图提取文字层（保留原风格）...')
print(f'输出尺寸: {OUT_W}x{OUT_H}')
print()

for src_name, dst_name in FILE_MAP:
    src_path = os.path.join(TEXT_DIR, src_name)
    dst_path = os.path.join(OUT_DIR, dst_name)

    if not os.path.exists(src_path):
        print(f'  ✗ 源文件不存在: {src_name}')
        continue

    print(f'处理: {src_name}')
    extract_text(src_path, FRAME_PATH, dst_path)

print()
print('完成！输出目录:', OUT_DIR)
