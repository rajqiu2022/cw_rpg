"""
精灵表（Sprite Sheet）切割工具

功能：
  - 自动检测行列边界（去棋盘格背景后基于alpha通道）
  - 按方向+动作+序号命名输出帧
  - 支持统一帧尺寸（居中对齐）
  - 支持命令行参数配置

用法：
  python split_spritesheet.py <输入图片> [选项]

  选项：
    --output, -o     输出目录（默认: 输入图片同目录/hero_frames）
    --rows, -r       从上到下各行的方向名，逗号分隔（默认: right,left,up,down）
    --walk           每行走动帧数（默认: 9）
    --idle           每行站立帧数（默认: 4），walk+idle=每行总帧数
    --uniform        统一所有帧尺寸为最大帧的宽高（默认开启）
    --no-uniform     不统一帧尺寸
    --padding        trim后保留的边距像素（默认: 2）
    --min-gap        行间最小空白像素（默认: 10）
    --min-frame-gap  帧间最小空白像素（默认: 5）
    --min-frame-w    最小帧宽度像素（默认: 40）

示例：
  python split_spritesheet.py ../images/hero.png -r right,left,up,down --walk 9 --idle 4
  python split_spritesheet.py ../images/npc.png -o ../images/npc_frames -r down,left,right,up
"""

import argparse
from collections import deque
from PIL import Image
import numpy as np
import os
import sys


def remove_checker_background(img, threshold=240, soften=1):
    """去除背景（边缘连通域 flood-fill 方法，不会误删角色内部白色衣物）

    从图像四条边缘出发，BFS 扩展所有 R/G/B 均 >= threshold 的像素，
    只有与边缘连通的白色区域才被设为透明。
    """
    rgba = img.convert('RGBA')
    w, h = rgba.size
    arr = np.array(rgba)

    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = arr[y, x]
            if r >= threshold and g >= threshold and b >= threshold and a > 0:
                if not visited[y, x]:
                    visited[y, x] = True
                    queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, a = arr[y, x]
            if r >= threshold and g >= threshold and b >= threshold and a > 0:
                if not visited[y, x]:
                    visited[y, x] = True
                    queue.append((x, y))

    while queue:
        cx, cy = queue.popleft()
        for nx, ny in ((cx-1, cy), (cx+1, cy), (cx, cy-1), (cx, cy+1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h:
                continue
            if visited[ny, nx]:
                continue
            r, g, b, a = arr[ny, nx]
            if r >= threshold and g >= threshold and b >= threshold and a > 0:
                visited[ny, nx] = True
                queue.append((nx, ny))

    bg_mask = visited

    if soften > 0:
        from scipy import ndimage
        dilated = ndimage.binary_dilation(bg_mask, iterations=soften)
        edge_zone = dilated & ~bg_mask
        soften_thresh = threshold - 15
        edge_is_bg = (
            (arr[:, :, 0] >= soften_thresh) &
            (arr[:, :, 1] >= soften_thresh) &
            (arr[:, :, 2] >= soften_thresh)
        )
        bg_mask = bg_mask | (edge_zone & edge_is_bg)

    result = arr.copy()
    result[bg_mask, 3] = 0
    return Image.fromarray(result, 'RGBA')


def detect_row_boundaries(alpha, min_gap=10):
    """通过alpha通道检测行边界，返回 [(top, bottom), ...]"""
    row_density = np.sum(alpha > 20, axis=1).astype(float) / alpha.shape[1]
    threshold = 0.005

    in_content = False
    rows = []
    start = 0
    gap_count = 0

    for y in range(len(row_density)):
        if row_density[y] > threshold:
            if not in_content:
                start = y
                in_content = True
            gap_count = 0
        else:
            if in_content:
                gap_count += 1
                if gap_count > min_gap:
                    rows.append((start, y - gap_count))
                    in_content = False
                    gap_count = 0

    if in_content:
        rows.append((start, len(row_density)))

    return rows


def detect_frame_columns(alpha_row, min_frame_width=40, min_gap=5):
    """检测一行中各帧的x范围，返回 [(left, right), ...]"""
    col_density = np.sum(alpha_row > 20, axis=0)
    height = alpha_row.shape[0]
    threshold = height * 0.01

    in_content = False
    frames = []
    start = 0
    gap_count = 0

    for x in range(len(col_density)):
        if col_density[x] > threshold:
            if not in_content:
                start = x
                in_content = True
            gap_count = 0
        else:
            if in_content:
                gap_count += 1
                if gap_count > min_gap:
                    end = x - gap_count
                    if end - start >= min_frame_width:
                        frames.append((start, end))
                    in_content = False
                    gap_count = 0

    if in_content:
        end = len(col_density)
        if end - start >= min_frame_width:
            frames.append((start, end))

    return frames


def uniform_frame_size(frame_images, target_size=None):
    """
    将所有帧统一为相同尺寸（居中放置，透明填充）。
    如果不指定 target_size，则使用所有帧中的最大宽高。
    """
    if not frame_images:
        return frame_images

    if target_size is None:
        max_w = max(f.width for f in frame_images)
        max_h = max(f.height for f in frame_images)
    else:
        max_w, max_h = target_size

    result = []
    for frame in frame_images:
        if frame.width == max_w and frame.height == max_h:
            result.append(frame)
        else:
            new_frame = Image.new('RGBA', (max_w, max_h), (0, 0, 0, 0))
            offset_x = (max_w - frame.width) // 2
            offset_y = max_h - frame.height  # 底部对齐（角色脚着地）
            new_frame.paste(frame, (offset_x, offset_y))
            result.append(new_frame)

    return result


def main():
    parser = argparse.ArgumentParser(description='精灵表（Sprite Sheet）切割工具')
    parser.add_argument('input', help='输入精灵表图片路径')
    parser.add_argument('--output', '-o', help='输出目录（默认: 输入图同目录/hero_frames）')
    parser.add_argument('--rows', '-r', default='right,left,up,down',
                        help='从上到下各行方向名，逗号分隔（默认: right,left,up,down）')
    parser.add_argument('--walk', type=int, default=9, help='每行走动帧数（默认: 9）')
    parser.add_argument('--idle', type=int, default=4, help='每行站立帧数（默认: 4）')
    parser.add_argument('--uniform', action='store_true', default=True,
                        help='统一所有帧尺寸（默认开启）')
    parser.add_argument('--no-uniform', action='store_true', help='不统一帧尺寸')
    parser.add_argument('--padding', type=int, default=2, help='trim后保留边距（默认: 2px）')
    parser.add_argument('--min-gap', type=int, default=10, help='行间最小空白像素（默认: 10）')
    parser.add_argument('--min-frame-gap', type=int, default=5, help='帧间最小空白像素（默认: 5）')
    parser.add_argument('--min-frame-w', type=int, default=40, help='最小帧宽度（默认: 40px）')

    args = parser.parse_args()

    # 解析路径
    input_path = os.path.abspath(args.input)
    if not os.path.exists(input_path):
        print(f"错误: 文件不存在: {input_path}")
        sys.exit(1)

    if args.output:
        output_dir = os.path.abspath(args.output)
    else:
        output_dir = os.path.join(os.path.dirname(input_path), 'hero_frames')

    row_names = [n.strip() for n in args.rows.split(',')]
    walk_count = args.walk
    idle_count = args.idle
    do_uniform = args.uniform and not args.no_uniform
    padding = args.padding

    print(f"输入: {input_path}")
    print(f"输出: {output_dir}")
    print(f"方向: {row_names}")
    print(f"帧分配: walk={walk_count}, idle={idle_count}, 每行共{walk_count + idle_count}帧")
    print(f"统一尺寸: {'是' if do_uniform else '否'}")
    print()

    # 加载图片
    img = Image.open(input_path)
    print(f"精灵表尺寸: {img.width} x {img.height}")

    # 去除棋盘格背景
    print("去除棋盘格背景...")
    img = remove_checker_background(img)

    arr = np.array(img)
    alpha = arr[:, :, 3]

    # 检测行边界
    rows = detect_row_boundaries(alpha, min_gap=args.min_gap)
    print(f"\n检测到 {len(rows)} 行:")
    for i, (top, bot) in enumerate(rows):
        name = row_names[i] if i < len(row_names) else f"row{i}"
        print(f"  行{i} ({name}): y={top}~{bot} (高度{bot - top}px)")

    expected_rows = len(row_names)
    if len(rows) != expected_rows:
        print(f"\n警告: 期望{expected_rows}行但检测到{len(rows)}行，尝试调整...")
        for gap in [8, 5, 3, 2]:
            rows = detect_row_boundaries(alpha, min_gap=gap)
            if len(rows) == expected_rows:
                print(f"  min_gap={gap} 时检测到 {len(rows)} 行 ✓")
                break
        if len(rows) != expected_rows:
            print(f"  无法自动检测到{expected_rows}行，使用等分")
            h = img.height // expected_rows
            rows = [(i * h, (i + 1) * h) for i in range(expected_rows)]

    # 清空输出目录
    os.makedirs(output_dir, exist_ok=True)
    for f in os.listdir(output_dir):
        fp = os.path.join(output_dir, f)
        if os.path.isfile(fp):
            os.remove(fp)

    # 切割
    all_frames = []  # (filename, PIL.Image)
    total_expected = walk_count + idle_count

    for row_idx, (row_top, row_bottom) in enumerate(rows):
        if row_idx >= len(row_names):
            break
        direction = row_names[row_idx]
        row_alpha = alpha[row_top:row_bottom, :]

        # 检测帧列
        frame_cols = detect_frame_columns(row_alpha,
                                          min_frame_width=args.min_frame_w,
                                          min_gap=args.min_frame_gap)

        print(f"\n行 {row_idx} ({direction}): 检测到 {len(frame_cols)} 帧", end='')
        if len(frame_cols) != total_expected:
            print(f" (期望{total_expected})", end='')
        print()

        if len(frame_cols) == 0:
            print(f"  [!] 帧检测失败，跳过此行")
            continue

        widths = [f[1] - f[0] for f in frame_cols]
        print(f"  帧宽: min={min(widths)} max={max(widths)} avg={sum(widths) // len(widths)}")

        for frame_idx, (col_left, col_right) in enumerate(frame_cols):
            frame = img.crop((col_left, row_top, col_right, row_bottom))

            # trim 透明边距
            bbox = frame.getbbox()
            if bbox:
                x0 = max(0, bbox[0] - padding)
                y0 = max(0, bbox[1] - padding)
                x1 = min(frame.width, bbox[2] + padding)
                y1 = min(frame.height, bbox[3] + padding)
                frame = frame.crop((x0, y0, x1, y1))
            else:
                print(f"  跳过空帧: 第{frame_idx}帧")
                continue

            # 命名：walk or idle
            if frame_idx < walk_count:
                filename = f"{direction}_walk_{frame_idx + 1:02d}.png"
            elif frame_idx < walk_count + idle_count:
                idle_idx = frame_idx - walk_count + 1
                filename = f"{direction}_idle_{idle_idx:02d}.png"
            else:
                # 超出预期的帧，用 extra 前缀
                extra_idx = frame_idx - walk_count - idle_count + 1
                filename = f"{direction}_extra_{extra_idx:02d}.png"

            all_frames.append((filename, frame))

    # 统一帧尺寸
    if do_uniform and all_frames:
        print(f"\n统一帧尺寸...")
        images = [f[1] for f in all_frames]
        max_w = max(f.width for f in images)
        max_h = max(f.height for f in images)
        print(f"  目标尺寸: {max_w} x {max_h}")
        images = uniform_frame_size(images, (max_w, max_h))
        all_frames = [(all_frames[i][0], images[i]) for i in range(len(all_frames))]

    # 保存
    for filename, frame in all_frames:
        frame.save(os.path.join(output_dir, filename))

    print(f"\n完成! 共输出 {len(all_frames)} 帧")
    print(f"  输出目录: {output_dir}")

    # 汇总
    directions_summary = {}
    for filename, _ in all_frames:
        parts = filename.split('_')
        key = f"{parts[0]}_{parts[1]}"
        directions_summary[key] = directions_summary.get(key, 0) + 1
    print(f"\n  帧分布:")
    for key, count in sorted(directions_summary.items()):
        print(f"    {key}: {count} 帧")


if __name__ == '__main__':
    main()
