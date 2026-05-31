"""
将 AI 生成的精灵条自动处理为 Godot 可用格式。
支持:
  - 13帧 strip (9 walk + 4 idle) → 单方向 walk_9f + idle_4f
  - 4帧 strip (4 idle) → 单方向 idle_4f

流程: 品红抠图 → 裁切 → 缩小到2/3 → 归一化 → 输出strip到 game/art/characters/
"""
from PIL import Image
import os
import sys
import json

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OUT = os.path.join(PROJECT, 'game', 'art', 'characters')
SCALE = 2/3

# 品红色键抠图参数
KEY_COLOR = (255, 0, 255)  # #FF00FF
KEY_TOLERANCE = 80  # 色差容忍度（高一点防止残留粉边）


def remove_magenta(image):
    """移除品红色背景，替换为透明。
    遍历每个像素，若颜色接近 #FF00FF 则设为透明。
    对靠近边界的像素做半透明混合防止粉边。"""
    img = image.convert('RGBA')
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r > 180 and g < 100 and b > 180:
                # 品红色区域：直接透明
                pixels[x, y] = (0, 0, 0, 0)
            elif r > 150 and b > 150 and r + b - g > 280:
                # 靠近品红的边缘像素：按接近程度做半透明
                magenta_dist = max(0, r - g) + max(0, b - g)
                alpha = max(0, min(255, int(255 * (1 - magenta_dist / 300))))
                pixels[x, y] = (r, g, b, alpha)
    return img


def split_strip(image_path, frame_count):
    """将水平条带切分为 frame_count 等宽的帧"""
    img = Image.open(image_path).convert('RGBA')
    w, h = img.size
    frame_w = w // frame_count
    frames = []
    for i in range(frame_count):
        left = i * frame_w
        right = (i + 1) * frame_w
        frame = img.crop((left, 0, right, h))
        frames.append(frame)
    print(f'  split {image_path}: {w}x{h} → {frame_count} frames, each {frame_w}x{h}')
    return frames


def scale_frames(frames, scale=SCALE):
    """所有帧缩小"""
    result = []
    for f in frames:
        w, h = f.size
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        result.append(f.resize((new_w, new_h), Image.LANCZOS))
    return result


def normalize_frames(frames, pad=2):
    """归一化到统一画布大小"""
    max_w = max(f.width for f in frames) + pad * 2
    max_h = max(f.height for f in frames) + pad * 2
    result = []
    for f in frames:
        canvas = Image.new('RGBA', (max_w, max_h), (0, 0, 0, 0))
        ox = (max_w - f.width) // 2
        oy = (max_h - f.height) // 2
        canvas.paste(f, (ox, oy), f)
        result.append(canvas)
    return result, max_w, max_h


def make_strip(frames, out_path):
    """帧拼成水平条带"""
    w = frames[0].width
    h = frames[0].height
    strip = Image.new('RGBA', (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * w, 0), f)
    strip.save(out_path, 'PNG')
    return strip.size


def save_frames(frames, out_dir, prefix):
    """保存单帧到目录"""
    os.makedirs(out_dir, exist_ok=True)
    for i, f in enumerate(frames):
        path = os.path.join(out_dir, f'{prefix}_{i+1:02d}.png')
        f.save(path, 'PNG')
    print(f'  saved {len(frames)} frames to {out_dir}/')


def process_13f(image_path, direction, out_dir=DEFAULT_OUT, frames_dir=None):
    """
    处理 13帧 strip: 前9帧 walk + 后4帧 idle
    输出: hero_walk_{direction}_9f.png + hero_idle_{direction}_4f.png
    """
    frames = split_strip(image_path, 13)
    walk_frames = frames[:9]
    idle_frames = frames[9:13]

    walk_frames = scale_frames(walk_frames)
    idle_frames = scale_frames(idle_frames)

    walk_norm, _, _ = normalize_frames(walk_frames)
    idle_norm, _, _ = normalize_frames(idle_frames)

    walk_path = os.path.join(out_dir, f'hero_walk_{direction}_9f.png')
    idle_path = os.path.join(out_dir, f'hero_idle_{direction}_4f.png')
    make_strip(walk_norm, walk_path)
    make_strip(idle_norm, idle_path)

    if frames_dir:
        save_frames(walk_frames, os.path.join(frames_dir, direction), 'walk')
        save_frames(idle_frames, os.path.join(frames_dir, direction), 'idle')


def process_4f_idle(image_path, direction, npc_id, out_dir=DEFAULT_OUT):
    """
    处理 4帧 idle strip → npc_{npc_id}_idle_{direction}_4f.png
    """
    frames = split_strip(image_path, 4)
    frames = scale_frames(frames)
    frames_norm, _, _ = normalize_frames(frames)
    out_path = os.path.join(out_dir, f'npc_{npc_id}_idle_{direction}_4f.png')
    make_strip(frames_norm, out_path)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='处理 AI 精灵条')
    parser.add_argument('image', help='输入 strip 图片路径')
    parser.add_argument('--mode', choices=['13f', '4f'], default='13f', help='模式: 13f=9walk+4idle, 4f=4idle')
    parser.add_argument('--direction', default='right', choices=['right', 'left', 'up', 'down'], help='方向')
    parser.add_argument('--npc-id', default='', help='NPC ID（4f模式用）')
    parser.add_argument('--frames-dir', default='', help='保存单帧的目录')
    parser.add_argument('--out-dir', default=DEFAULT_OUT, help='输出目录')
    args = parser.parse_args()

    if args.mode == '13f':
        process_13f(args.image, args.direction, args.out_dir, args.frames_dir or None)
        print(f'Done: {args.direction} walk_9f + idle_4f → {args.out_dir}')
    else:
        if not args.npc_id:
            print('ERROR: --npc-id required for 4f mode')
            sys.exit(1)
        process_4f_idle(args.image, args.direction, args.npc_id, args.out_dir)
        print(f'Done: npc_{args.npc_id}_idle_{args.direction}_4f → {args.out_dir}')
