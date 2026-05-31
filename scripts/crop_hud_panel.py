"""crop_hud_panel.py — 自动检测 + 精确裁切 HUD 面板

从 1024×1024 生成图中自动找到面板区域（非纯白像素边界），
按预期宽高比和已知元素坐标比例裁切各个子区域。

用法：
    python scripts/crop_hud_panel.py [--input PATH] [--output-dir PATH] [--preview]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# ── 面板预期尺寸和元素比例 ──
# 面板在 1024 画布中预期为 1000×375，以下坐标全相对于面板左上角
PANEL_EXPECTED_W = 1000
PANEL_EXPECTED_H = 375

# 各元素相对于面板左上角的边界 (left, top, right, bottom) —— 单位: 面板像素
PANEL_REGIONS: dict[str, tuple[int, int, int, int]] = {
    "avatar_frame":   (24,  24,  192, 192),   # 头像圆框 168×168，起点 (36-12, 36-12)
    "name_nameplate": (220, 24,  556, 72),    # 名字铭牌 (232-12, 36-12)→(568-12, 84-12)
    "sect_nameplate": (220, 84,  556, 120),   # 门派铭牌 (232-12, 96-12)→(568-12, 132-12)
    "qi_label":       (220, 192, 268, 232),   # 气字 (232-12, 204-12)→(280-12, 244-12)
    "hp_slot":        (280, 196, 912, 228),   # 血槽 (292-12, 208-12)→(924-12, 240-12)
    "nei_label":      (220, 248, 268, 288),   # 内字 (232-12, 260-12)→(280-12, 300-12)
    "mp_slot":        (280, 252, 912, 284),   # 蓝槽 (292-12, 264-12)→(924-12, 296-12)
    "coin_icon":      (36,  320, 72,  356),   # 铜钱 (48-12, 332-12)→(84-12, 368-12)
    "coin_nameplate": (80,  320, 260, 356),   # 金币铭牌 (92-12, 332-12)→(272-12, 368-12)
    "level_nameplate":(776, 320, 956, 356),   # 等级铭牌 (788-12, 332-12)→(968-12, 368-12)
}


def find_panel_bounds(img: np.ndarray, white_threshold: int = 250) -> tuple[int, int, int, int]:
    """在 1024×1024 图中找到非纯白区域的外接矩形作为面板边界。"""
    h, w = img.shape[:2]
    # 考虑 RGB 三通道都 > threshold 为"白"
    if img.ndim == 3 and img.shape[2] >= 3:
        white_mask = np.all(img[:, :, :3] >= white_threshold, axis=2)
    else:
        white_mask = img >= white_threshold

    non_white_rows = np.any(~white_mask, axis=1)
    non_white_cols = np.any(~white_mask, axis=0)

    if not non_white_rows.any() or not non_white_cols.any():
        print("WARNING: 全图纯白，未检测到面板！使用预期坐标。")
        return (12, 12, 12 + PANEL_EXPECTED_W, 12 + PANEL_EXPECTED_H)

    top = int(np.argmax(non_white_rows))
    bottom = int(h - np.argmax(non_white_rows[::-1]))
    left = int(np.argmax(non_white_cols))
    right = int(w - np.argmax(non_white_cols[::-1]))

    return (left, top, right, bottom)


def rescale_region(
    bounds: tuple[int, int, int, int],
    src_w: int, src_h: int,
) -> dict[str, tuple[int, int, int, int]]:
    """根据检测到的面板实际边界，按比例重算各子区域坐标。"""
    left, top, right, bottom = bounds
    actual_w = right - left
    actual_h = bottom - top

    if actual_w <= 0 or actual_h <= 0:
        return dict(PANEL_REGIONS)

    scale_x = actual_w / PANEL_EXPECTED_W
    scale_y = actual_h / PANEL_EXPECTED_H

    scaled = {}
    for name, (rl, rt, rr, rb) in PANEL_REGIONS.items():
        sl = int(left + rl * scale_x)
        st = int(top + rt * scale_y)
        sr = int(left + rr * scale_x)
        sb = int(top + rb * scale_y)
        scaled[name] = (sl, st, sr, sb)
    return scaled


def crop_region(src: np.ndarray, bounds: tuple[int, int, int, int], dst: Path) -> None:
    """裁切并保存 PNG。"""
    from PIL import Image
    l, t, r, b = bounds
    # clamp to image bounds
    h, w = src.shape[:2]
    l, t = max(0, l), max(0, t)
    r, b = min(w, r), min(h, b)
    cropped = Image.fromarray(src[t:b, l:r])
    dst.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(dst, format="PNG")
    print(f"  [OK] {dst.name}  {r-l}x{b-t}")


def main() -> None:
    parser = argparse.ArgumentParser(description="自动检测并裁切 HUD 面板像素区域")
    parser.add_argument("--input", type=Path, help="输入 1024×1024 PNG")
    parser.add_argument("--output-dir", type=Path, help="输出目录")
    parser.add_argument("--preview", action="store_true", help="生成坐标标注预览")
    args = parser.parse_args()

    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("需要 Pillow: pip install Pillow")
        sys.exit(1)

    src_path = args.input or (
        PROJECT_ROOT / "assets/raw/ui/field_hud/pixelperfect"
        / "ui_field_hud_player_panel_pixelperfect_v1.png"
    )
    out_dir = args.output_dir or (PROJECT_ROOT / "assets/processed/ui/field_hud")

    if not src_path.exists():
        print(f"找不到: {src_path}")
        sys.exit(1)

    print(f"输入: {src_path}")
    img = np.array(Image.open(src_path).convert("RGB"))

    # 1. 自动检测面板边界
    bounds = find_panel_bounds(img)
    l, t, r, b = bounds
    actual_w, actual_h = r - l, b - t
    print(f"检测到面板: ({l},{t})→({r},{b}) = {actual_w}x{actual_h}")
    print(f"预期: 1000x375, 比例 x={actual_w/PANEL_EXPECTED_W:.3f} y={actual_h/PANEL_EXPECTED_H:.3f}")

    # 2. 按比例重算子区域
    regions = rescale_region(bounds, img.shape[1], img.shape[0])

    if args.preview:
        _make_preview(img, bounds, regions, out_dir)
    else:
        print("裁切面板部件:")
        crop_region(img, bounds, out_dir / "hud_player_panel.png")
        crop_region(img, regions["avatar_frame"], out_dir / "hud_avatar_frame.png")
        crop_region(img, regions["hp_slot"], out_dir / "hud_hp_slot.png")
        crop_region(img, regions["mp_slot"], out_dir / "hud_mp_slot.png")
        print(f"\n面板: {actual_w}x{actual_h}")
        print("完成。需要手动缩放到游戏分辨率 (400x150 或其他)。")


def _make_preview(
    img: np.ndarray,
    bounds: tuple[int, int, int, int],
    regions: dict[str, tuple[int, int, int, int]],
    out_dir: Path,
) -> None:
    from PIL import Image, ImageDraw

    pil_img = Image.fromarray(img).convert("RGBA")
    draw = ImageDraw.Draw(pil_img)

    colors = {
        "avatar_frame":   (255, 200, 0),
        "name_nameplate": (0, 255, 200),
        "sect_nameplate": (200, 200, 255),
        "qi_label":       (255, 100, 100),
        "hp_slot":        (255, 0, 0),
        "nei_label":      (100, 150, 255),
        "mp_slot":        (0, 100, 255),
        "coin_icon":      (255, 200, 100),
        "coin_nameplate": (255, 200, 200),
        "level_nameplate":(200, 255, 200),
    }

    # 面板总边界 — 绿色
    l, t, r, b = bounds
    draw.rectangle((l, t, r, b), outline=(0, 255, 0), width=3)
    draw.text((l + 6, t + 6), f"PANEL {r-l}x{b-t}", fill=(0, 255, 0))

    for name, (rl, rt, rr, rb) in regions.items():
        color = colors.get(name, (255, 255, 255))
        draw.rectangle((rl, rt, rr, rb), outline=color, width=2)
        # 短标籤
        short = name.split("_")[0]
        draw.text((rl + 2, rt + 2), short, fill=color)

    preview_path = out_dir / "hud_panel_crop_preview.png"
    out_dir.mkdir(parents=True, exist_ok=True)
    pil_img.save(preview_path, format="PNG")
    print(f"预览: {preview_path}")


if __name__ == "__main__":
    main()
