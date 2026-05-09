#!/usr/bin/env python3
"""
Sprite Sheet Slicer — UI 素材切图工具
=====================================

用途：把一张大图（sprite sheet）按网格或指定区域切割成独立小图。

三种模式：
1. grid    — 按固定行列数均匀切割
2. size    — 按固定像素尺寸切割（自动计算行列）
3. auto    — 自动检测非透明区域，智能切割（适合间距不规则的图）

用法示例：
---------
# 按 4 列 x 6 行网格切割
python tools/sprite_slicer.py grid assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png --cols 6 --rows 4

# 按 128x128 像素尺寸切割
python tools/sprite_slicer.py size assets/raw/ui/sheet.png --width 128 --height 128

# 自动检测并切割（适合不规则排列）
python tools/sprite_slicer.py auto assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_battle_hud_v1.png

# 指定输出目录和前缀
python tools/sprite_slicer.py grid input.png --cols 3 --rows 3 --output game/art/ui/buttons/ --prefix btn_

# 指定 padding（元素间距）
python tools/sprite_slicer.py size input.png --width 64 --height 64 --padding 4

通用选项：
  --output, -o   输出目录（默认在源图同目录下创建 <文件名>_sliced/）
  --prefix, -p   输出文件名前缀（默认用源图文件名）
  --format, -f   输出格式 png/webp（默认 png）
  --trim         裁切每块周边的透明像素（默认不裁）
  --padding      元素间 padding 像素数（grid/size 模式用）
  --margin       整图四周 margin 像素数
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("错误：需要安装 Pillow。运行: pip install Pillow")
    sys.exit(1)


def trim_transparent(img: Image.Image) -> Image.Image:
    """裁切图片周边的透明像素"""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.getbbox()
    if bbox is None:
        return img
    return img.crop(bbox)


def find_bounding_boxes(img: Image.Image, min_size: int = 10) -> list:
    """
    自动检测非透明连通区域的包围盒。
    返回 [(x, y, w, h), ...] 列表，按从上到下、从左到右排序。
    """
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    width, height = img.size
    alpha = img.split()[3]
    pixels = alpha.load()

    visited = [[False] * width for _ in range(height)]
    boxes = []

    def flood_fill_bbox(start_x, start_y):
        """BFS 找连通区域包围盒"""
        stack = [(start_x, start_y)]
        min_x, min_y = start_x, start_y
        max_x, max_y = start_x, start_y

        while stack:
            cx, cy = stack.pop()
            if cx < 0 or cx >= width or cy < 0 or cy >= height:
                continue
            if visited[cy][cx]:
                continue
            if pixels[cx, cy] < 10:  # 近全透明视为空
                continue

            visited[cy][cx] = True
            min_x = min(min_x, cx)
            min_y = min(min_y, cy)
            max_x = max(max_x, cx)
            max_y = max(max_y, cy)

            # 8 方向连通（用较大步长加速，适合 UI 元素）
            for dx in [-1, 0, 1]:
                for dy in [-1, 0, 1]:
                    if dx == 0 and dy == 0:
                        continue
                    stack.append((cx + dx, cy + dy))

        return min_x, min_y, max_x, max_y

    # 扫描（每隔几个像素采样加速）
    step = max(1, min_size // 4)
    for y in range(0, height, step):
        for x in range(0, width, step):
            if not visited[y][x] and pixels[x, y] >= 10:
                x1, y1, x2, y2 = flood_fill_bbox(x, y)
                bw = x2 - x1 + 1
                bh = y2 - y1 + 1
                if bw >= min_size and bh >= min_size:
                    boxes.append((x1, y1, bw, bh))

    # 按行（y）再按列（x）排序
    boxes.sort(key=lambda b: (b[1], b[0]))
    return boxes


def merge_nearby_boxes(boxes: list, gap: int = 5) -> list:
    """合并距离很近的包围盒（处理描边/阴影断开的情况）"""
    if not boxes:
        return boxes

    merged = [list(boxes[0])]

    for box in boxes[1:]:
        bx, by, bw, bh = box
        did_merge = False

        for i, m in enumerate(merged):
            mx, my, mw, mh = m
            # 检查是否重叠或间距很小
            if (bx <= mx + mw + gap and bx + bw >= mx - gap and
                by <= my + mh + gap and by + bh >= my - gap):
                # 合并
                nx = min(mx, bx)
                ny = min(my, by)
                nw = max(mx + mw, bx + bw) - nx
                nh = max(my + mh, by + bh) - ny
                merged[i] = [nx, ny, nw, nh]
                did_merge = True
                break

        if not did_merge:
            merged.append(list(box))

    # 递归合并直到稳定
    merged_tuples = [tuple(m) for m in merged]
    if len(merged_tuples) == len(boxes):
        return merged_tuples
    return merge_nearby_boxes(merged_tuples, gap)


def slice_grid(img: Image.Image, cols: int, rows: int,
               padding: int = 0, margin: int = 0) -> list:
    """按行列网格切割，返回 [(片段Image, 行号, 列号), ...]"""
    w, h = img.size
    content_w = w - 2 * margin
    content_h = h - 2 * margin

    cell_w = (content_w - (cols - 1) * padding) // cols
    cell_h = (content_h - (rows - 1) * padding) // rows

    slices = []
    for r in range(rows):
        for c in range(cols):
            x = margin + c * (cell_w + padding)
            y = margin + r * (cell_h + padding)
            piece = img.crop((x, y, x + cell_w, y + cell_h))
            slices.append((piece, r, c))

    return slices


def slice_by_size(img: Image.Image, cell_w: int, cell_h: int,
                  padding: int = 0, margin: int = 0) -> list:
    """按固定像素尺寸切割"""
    w, h = img.size
    content_w = w - 2 * margin
    content_h = h - 2 * margin

    cols = (content_w + padding) // (cell_w + padding)
    rows = (content_h + padding) // (cell_h + padding)

    return slice_grid(img, cols, rows, padding, margin)


def slice_auto(img: Image.Image, min_size: int = 10, gap: int = 5) -> list:
    """自动检测连通区域并切割"""
    print(f"  Detecting regions (min_size={min_size}, gap={gap})...")
    boxes = find_bounding_boxes(img, min_size)
    print(f"  Found {len(boxes)} initial regions")

    boxes = merge_nearby_boxes(boxes, gap)
    print(f"  After merge: {len(boxes)} regions")

    slices = []
    for i, (x, y, w, h) in enumerate(boxes):
        piece = img.crop((x, y, x + w, y + h))
        slices.append((piece, i, 0))

    return slices


def save_slices(slices: list, output_dir: Path, prefix: str,
                fmt: str = "png", do_trim: bool = False) -> list:
    """保存切片到文件，返回文件路径列表"""
    output_dir.mkdir(parents=True, exist_ok=True)
    saved = []

    for piece, row, col in slices:
        if do_trim:
            piece = trim_transparent(piece)

        # 跳过全透明的空片段
        if piece.mode == "RGBA":
            bbox = piece.getbbox()
            if bbox is None:
                continue

        idx = row * 100 + col if len(slices) > 100 else len(saved)
        filename = f"{prefix}{len(saved):03d}.{fmt}"
        filepath = output_dir / filename
        piece.save(filepath, fmt.upper())
        saved.append(filepath)
        print(f"  + {filepath.name} ({piece.size[0]}x{piece.size[1]})")

    return saved


def main():
    parser = argparse.ArgumentParser(
        description="Sprite Sheet 切图工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    subparsers = parser.add_subparsers(dest="mode", help="切割模式")

    # --- grid 模式 ---
    p_grid = subparsers.add_parser("grid", help="按行列网格切割")
    p_grid.add_argument("input", help="输入图片路径")
    p_grid.add_argument("--cols", type=int, required=True, help="列数")
    p_grid.add_argument("--rows", type=int, required=True, help="行数")
    p_grid.add_argument("--padding", type=int, default=0, help="元素间距(px)")
    p_grid.add_argument("--margin", type=int, default=0, help="四周边距(px)")

    # --- size 模式 ---
    p_size = subparsers.add_parser("size", help="按固定像素尺寸切割")
    p_size.add_argument("input", help="输入图片路径")
    p_size.add_argument("--width", "-W", type=int, required=True, help="单元宽(px)")
    p_size.add_argument("--height", "-H", type=int, required=True, help="单元高(px)")
    p_size.add_argument("--padding", type=int, default=0, help="元素间距(px)")
    p_size.add_argument("--margin", type=int, default=0, help="四周边距(px)")

    # --- auto 模式 ---
    p_auto = subparsers.add_parser("auto", help="自动检测区域切割")
    p_auto.add_argument("input", help="输入图片路径")
    p_auto.add_argument("--min-size", type=int, default=20, help="最小区域尺寸(px)")
    p_auto.add_argument("--gap", type=int, default=8, help="合并间距(px)")

    # --- rect 模式 ---
    p_rect = subparsers.add_parser("rect", help="按指定矩形坐标切割")
    p_rect.add_argument("input", help="输入图片路径")
    p_rect.add_argument("--rects", required=True,
                        help="矩形列表 'x,y,w,h;x,y,w,h;...'")
    p_rect.add_argument("--names",
                        help="对应名字列表 'name1;name2;...'（可选，默认序号）")

    # --- 通用选项 ---
    for p in [p_grid, p_size, p_auto, p_rect]:
        p.add_argument("--output", "-o", help="输出目录")
        p.add_argument("--prefix", "-p", help="文件名前缀")
        p.add_argument("--format", "-f", choices=["png", "webp"], default="png")
        p.add_argument("--trim", action="store_true", help="裁切透明边缘")

    args = parser.parse_args()

    if args.mode is None:
        parser.print_help()
        sys.exit(1)

    # 解析路径
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"错误：找不到文件 {input_path}")
        sys.exit(1)

    # 输出目录
    if args.output:
        output_dir = Path(args.output)
    else:
        output_dir = input_path.parent / f"{input_path.stem}_sliced"

    # 前缀
    prefix = args.prefix if args.prefix else f"{input_path.stem}_"

    # 打开图片
    print(f"\n[Sprite Slicer]")
    print(f"   Input: {input_path}")
    print(f"   Mode:  {args.mode}")
    img = Image.open(input_path).convert("RGBA")
    print(f"   Size:  {img.size[0]}x{img.size[1]}")

    # 切割
    if args.mode == "grid":
        slices = slice_grid(img, args.cols, args.rows, args.padding, args.margin)
        print(f"   Grid:  {args.cols} cols x {args.rows} rows = {len(slices)} cells")
    elif args.mode == "size":
        slices = slice_by_size(img, args.width, args.height, args.padding, args.margin)
        print(f"   Cell:  {args.width}x{args.height}px")
    elif args.mode == "auto":
        slices = slice_auto(img, args.min_size, args.gap)
    elif args.mode == "rect":
        rects_str = args.rects.split(";")
        names_list = args.names.split(";") if args.names else None
        slices = []
        for i, r in enumerate(rects_str):
            parts = [int(x.strip()) for x in r.split(",")]
            if len(parts) != 4:
                print(f"  ERROR: rect '{r}' must be 'x,y,w,h'")
                continue
            x, y, w, h = parts
            piece = img.crop((x, y, x + w, y + h))
            slices.append((piece, i, 0))
        print(f"   Rects: {len(slices)} regions specified")
        # 如果有自定义名字，用命名保存
        if names_list:
            output_dir.mkdir(parents=True, exist_ok=True)
            saved = []
            for idx, (piece, _, _) in enumerate(slices):
                if args.trim:
                    piece = trim_transparent(piece)
                name = names_list[idx] if idx < len(names_list) else f"{idx:03d}"
                filename = f"{prefix}{name}.{args.format}"
                filepath = output_dir / filename
                piece.save(filepath, args.format.upper())
                saved.append(filepath)
                print(f"  + {filepath.name} ({piece.size[0]}x{piece.size[1]})")
            print(f"\n[Done] {len(saved)} slices saved")
            return
    else:
        sys.exit(1)

    # 保存
    print(f"\n   Output: {output_dir}/")
    saved = save_slices(slices, output_dir, prefix, args.format, args.trim)
    print(f"\n[Done] {len(saved)} slices saved")


if __name__ == "__main__":
    main()
