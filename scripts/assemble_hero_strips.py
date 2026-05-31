"""
将 images/hero_frames/ 中的切图帧组装成水平精灵条。
命名规则: {方向}_walk_01~09.png (走路9帧), {方向}_idle_01~04.png (站立4帧)
"""
from PIL import Image
import os
import sys

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAMES_DIR = os.path.join(PROJECT, 'images', 'hero_frames')
OUT_DIR = os.path.join(PROJECT, 'game', 'art', 'characters')

DIRECTIONS = ['right', 'left', 'up', 'down']
WALK_COUNT = 9
IDLE_COUNT = 4


def normalize_frames(frames, pad=2):
    """将一组帧归一化到统一画布大小，帧居中放置"""
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
    """将帧组装成水平条带"""
    w = frames[0].width
    h = frames[0].height
    strip = Image.new('RGBA', (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * w, 0), f)
    strip.save(out_path, 'PNG')
    return strip.size


def main():
    for direction in DIRECTIONS:
        # 读取 walk 帧
        walk_frames = []
        for i in range(1, WALK_COUNT + 1):
            path = os.path.join(FRAMES_DIR, f'{direction}_walk_{i:02d}.png')
            if not os.path.exists(path):
                print(f'MISSING: {path}')
                sys.exit(1)
            walk_frames.append(Image.open(path).convert('RGBA'))

        # 读取 idle 帧
        idle_frames = []
        for i in range(1, IDLE_COUNT + 1):
            path = os.path.join(FRAMES_DIR, f'{direction}_idle_{i:02d}.png')
            if not os.path.exists(path):
                print(f'MISSING: {path}')
                sys.exit(1)
            idle_frames.append(Image.open(path).convert('RGBA'))

        # 归一化 walk
        norm_walk, fw, fh = normalize_frames(walk_frames)
        print(f'{direction} walk: {WALK_COUNT} frames normalized to {fw}x{fh}')

        # 归一化 idle
        norm_idle, iw, ih = normalize_frames(idle_frames)
        print(f'{direction} idle: {IDLE_COUNT} frames normalized to {iw}x{ih}')

        # 生成 walk strip
        walk_path = os.path.join(OUT_DIR, f'hero_walk_{direction}_9f.png')
        walk_size = make_strip(norm_walk, walk_path)
        print(f'  -> walk strip: {walk_size}')

        # 生成 idle strip
        idle_path = os.path.join(OUT_DIR, f'hero_idle_{direction}_4f.png')
        idle_size = make_strip(norm_idle, idle_path)
        print(f'  -> idle strip: {idle_size}')

    print('\nDone.')


if __name__ == '__main__':
    main()
