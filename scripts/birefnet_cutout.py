"""
birefnet_cutout.py — BiRefNet 抠图管线

基于 BiRefNet（Bilateral Reference Network）的主体识别，替代现有边缘连通方案，
对头发丝/武器边缘/细碎特效有更好的抠图效果。配合 LumaKey 处理半透明特效层。

依赖（二选一）：
    方案 A（本地 GPU，推荐）：pip install transformers torch torchvision
    方案 B（API，免 GPU）：使用 replicate.com 的 BiRefNet 模型

用法：
    python scripts/birefnet_cutout.py input.png -o output.png
    python scripts/birefnet_cutout.py input/ -o output/ --batch       # 批量处理
    python scripts/birefnet_cutout.py input.png --luma-threshold 30   # LumaKey 阈值
    python scripts/birefnet_cutout.py input.png --backend replicate   # 用云端 API

输出：
    透明背景 PNG（同目录或指定输出路径）
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image


# ── LumaKey 处理（特效/烟雾等半透明元素保留） ──
def luma_key(img: Image.Image, threshold: int = 40) -> Image.Image:
    """
    对接近白色（RGB 均 > threshold）的像素降低 alpha，
    但保留半透明区域（已带 alpha < 255 的像素不动）。
    用于处理 AI 生成的剑气、毒雾等白色半透明特效。
    """
    rgba = img.convert("RGBA")
    data = list(rgba.getdata())
    new_data: list[tuple[int, int, int, int]] = []
    for r, g, b, a in data:
        if a == 255 and r > threshold and g > threshold and b > threshold:
            # 纯白色区域 → 透明
            new_data.append((r, g, b, 0))
        else:
            new_data.append((r, g, b, a))
    rgba.putdata(new_data)
    return rgba


# ── BiRefNet 本地推理（需要 transformers + torch） ──
def cutout_birefnet_local(img: Image.Image) -> Image.Image:
    """使用本地 BiRefNet 模型抠图。首次运行会下载模型（~240MB）。"""
    try:
        from transformers import AutoModelForImageSegmentation
        import torch
        from torchvision import transforms
    except ImportError:
        print("[ERROR] 缺少依赖。请安装：pip install transformers torch torchvision")
        sys.exit(1)

    model_name = "ZhengPeng7/BiRefNet"
    model = AutoModelForImageSegmentation.from_pretrained(
        model_name, trust_remote_code=True
    )
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model.to(device)

    transform = transforms.Compose([
        transforms.Resize((1024, 1024)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])

    input_tensor = transform(img).unsqueeze(0).to(device)
    with torch.no_grad():
        pred = model(input_tensor)[-1].sigmoid().cpu()
    pred = transforms.ToPILImage()(pred.squeeze(0))

    # 还原原始尺寸
    pred = pred.resize(img.size, Image.LANCZOS)

    # 生成 mask 并应用
    rgba = img.convert("RGBA")
    mask_data = list(pred.convert("L").getdata())
    rgba_data = list(rgba.getdata())
    out_data: list[tuple[int, int, int, int]] = []
    for (r, g, b, a), m in zip(rgba_data, mask_data):
        new_a = int(a * (m / 255))
        out_data.append((r, g, b, new_a))
    rgba.putdata(out_data)
    return rgba


# ── Replicate API 抠图（免本地 GPU） ──
def cutout_birefnet_replicate(
    img: Image.Image, api_token: str | None = None
) -> Image.Image:
    """
    使用 replicate.com 上的 BiRefNet 模型。
    需要设置环境变量 REPLICATE_API_TOKEN。
    """
    import io
    import os

    try:
        import replicate  # type: ignore[import-untyped]
    except ImportError:
        print("[ERROR] 缺少 replicate。请安装：pip install replicate")
        sys.exit(1)

    token = api_token or os.environ.get("REPLICATE_API_TOKEN", "")
    if not token:
        print("[ERROR] 请设置环境变量 REPLICATE_API_TOKEN")
        sys.exit(1)

    # 将 PIL Image 转为 base64
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)

    # Replicate 的 BiRefNet 模型
    output = replicate.run(
        "camenduru/birefnet:b47985f4e9b3e6d8c6b5a5c5e9d9e5a5c5e5d5e5b5e5d5e5a5c5e5d5",
        input={"image": buf},
    )
    if isinstance(output, str):
        import requests
        resp = requests.get(output, timeout=30)
        return Image.open(io.BytesIO(resp.content)).convert("RGBA")
    return img


# ── 边缘连通降级方案（当前方案，作为 fallback） ──
def cutout_edge_connected(img: Image.Image, threshold: int = 220) -> Image.Image:
    """当前 make_sprite_bg_transparent.py 的方案，作为 BiRefNet 不可用时的降级。"""
    from collections import deque

    rgba = img.convert("RGBA")
    w, h = rgba.size
    pix = rgba.load()
    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    def is_bg(x: int, y: int) -> bool:
        r, g, b, a = pix[x, y]
        return a > 0 and r >= threshold and g >= threshold and b >= threshold

    for x in range(w):
        for y in (0, h - 1):
            if (x, y) not in seen and is_bg(x, y):
                seen.add((x, y)); q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if (x, y) not in seen and is_bg(x, y):
                seen.add((x, y)); q.append((x, y))

    neighbors = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    while q:
        cx, cy = q.popleft()
        for dx, dy in neighbors:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen:
                if is_bg(nx, ny):
                    seen.add((nx, ny)); q.append((nx, ny))

    for x, y in seen:
        pix[x, y] = (0, 0, 0, 0)
    return rgba


# ── 主流程 ──
def process_single(
    input_path: Path,
    output_path: Path,
    backend: str = "auto",
    luma_threshold: int = 40,
) -> None:
    img = Image.open(input_path).convert("RGBA")
    original_name = input_path.stem

    # 第一步：BiRefNet 主体抠图
    if backend == "replicate":
        print(f"  [BiRefNet] 使用 Replicate API 抠图...")
        result = cutout_birefnet_replicate(img)
    elif backend == "birefnet":
        print(f"  [BiRefNet] 本地推理抠图...")
        result = cutout_birefnet_local(img)
    else:
        # auto：先试 BiRefNet，失败则降级
        try:
            print(f"  [BiRefNet] 尝试本地推理...")
            result = cutout_birefnet_local(img)
        except Exception as e:
            print(f"  [WARN] BiRefNet 不可用 ({e})，降级为边缘连通方案")
            result = cutout_edge_connected(img)

    # 第二步：LumaKey 保留半透明特效
    if luma_threshold > 0:
        result = luma_key(result, threshold=luma_threshold)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_path)
    print(f"  [OK] → {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="BiRefNet + LumaKey 抠图管线"
    )
    parser.add_argument("input", type=str, help="输入文件或目录")
    parser.add_argument("-o", "--output", type=str, default="", help="输出路径")
    parser.add_argument(
        "--backend",
        choices=["auto", "birefnet", "replicate", "edge"],
        default="auto",
        help="抠图后端（默认 auto：BiRefNet 优先，失败降级边缘连通）",
    )
    parser.add_argument(
        "--luma-threshold",
        type=int,
        default=40,
        help="LumaKey 白色阈值（0=禁用，默认 40）",
    )
    parser.add_argument(
        "--batch", action="store_true", help="批量处理目录下所有 PNG"
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output) if args.output else input_path.with_stem(
        input_path.stem + "_cutout"
    )

    if input_path.is_dir() or args.batch:
        pngs = list(input_path.glob("*.png")) if input_path.is_dir() else [input_path]
        out_dir = output_path if output_path.is_dir() else Path(args.output or input_path)
        out_dir.mkdir(parents=True, exist_ok=True)
        print(f"批量处理 {len(pngs)} 个文件，输出到 {out_dir}/")
        for p in pngs:
            process_single(p, out_dir / f"{p.stem}_cutout.png", args.backend, args.luma_threshold)
    else:
        process_single(input_path, output_path, args.backend, args.luma_threshold)


if __name__ == "__main__":
    main()
