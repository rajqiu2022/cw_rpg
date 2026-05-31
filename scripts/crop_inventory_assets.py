"""
crop_inventory_assets.py — 将已生成的背包UI素材裁切/缩放到实际使用尺寸

从 assets/raw/ui/cold_wuxia/v2/inventory/ 读取原始大图，
auto-crop 透明边距后缩放到设计稿对应尺寸，
输出到 game/art/ui/inventory/ 覆盖旧文件。

设计稿参照：ui_display_inventory_bright.png (1280x720)
- 底部按钮（使用/装备/丢弃/关闭）：约 120×50 px
- +/- 按钮：约 36×36 px
- Tab 标签（全部/消耗/装备/剧情/材料）：约 100×40 px，左侧纵向
- 道具格子：约 88×88 px
- 品质角标：约 20×20 px
- 详情大框：约 140×140 px
- 分隔线：约 300×6 px
"""

from __future__ import annotations
import sys
from pathlib import Path

for _s in (sys.stdout, sys.stderr):
    if hasattr(_s, "reconfigure"):
        try:
            _s.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

import numpy as np
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "assets" / "raw" / "ui" / "cold_wuxia" / "v2" / "inventory"
OUT_DIR = PROJECT_ROOT / "game" / "art" / "ui" / "inventory"


def remove_black_background(img: Image.Image, threshold: int = 30) -> Image.Image:
    """Remove near-black background via flood-fill from corners.
    
    Only removes connected dark regions touching image edges,
    preserving dark content in the interior (like cell interiors).
    """
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    # Create mask of near-black pixels
    is_dark = (arr[:, :, 0] < threshold) & (arr[:, :, 1] < threshold) & (arr[:, :, 2] < threshold)
    
    # Flood fill from edges — only mark connected dark pixels as bg
    from scipy.ndimage import label
    # All dark pixels that are connected to the image border
    visited = np.zeros((h, w), dtype=bool)
    queue = []
    
    # Seed from all edge pixels that are dark
    for x in range(w):
        if is_dark[0, x]:
            queue.append((0, x))
        if is_dark[h - 1, x]:
            queue.append((h - 1, x))
    for y in range(h):
        if is_dark[y, 0]:
            queue.append((y, 0))
        if is_dark[y, w - 1]:
            queue.append((y, w - 1))
    
    # BFS flood fill
    for pos in queue:
        if visited[pos[0], pos[1]]:
            continue
        visited[pos[0], pos[1]] = True
    
    # Use a proper BFS with deque for performance
    from collections import deque
    bfs_queue = deque()
    for y, x in queue:
        if not visited[y, x]:
            visited[y, x] = True
        bfs_queue.append((y, x))
    
    # Re-init visited properly
    visited = np.zeros((h, w), dtype=bool)
    bfs_queue = deque()
    for x in range(w):
        if is_dark[0, x] and not visited[0, x]:
            visited[0, x] = True
            bfs_queue.append((0, x))
        if is_dark[h - 1, x] and not visited[h - 1, x]:
            visited[h - 1, x] = True
            bfs_queue.append((h - 1, x))
    for y in range(h):
        if is_dark[y, 0] and not visited[y, 0]:
            visited[y, 0] = True
            bfs_queue.append((y, 0))
        if is_dark[y, w - 1] and not visited[y, w - 1]:
            visited[y, w - 1] = True
            bfs_queue.append((y, w - 1))
    
    while bfs_queue:
        cy, cx = bfs_queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_dark[ny, nx]:
                visited[ny, nx] = True
                bfs_queue.append((ny, nx))
    
    # Only zero alpha for edge-connected dark pixels
    arr[visited, 3] = 0
    return Image.fromarray(arr)


def auto_crop(img: Image.Image, padding: int = 2) -> Image.Image:
    """Crop transparent borders, keep a small padding."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def process_and_save(src: Path, dst: Path, target_size: tuple[int, int], remove_bg: bool = True):
    """Remove black bg → auto-crop → resize to target → save PNG with alpha."""
    if not src.exists():
        print(f"  [SKIP] not found: {src.name}")
        return
    img = Image.open(src).convert("RGBA")
    if remove_bg:
        img = remove_black_background(img, threshold=30)
    img = auto_crop(img)
    img = img.resize(target_size, Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG")
    print(f"  [OK] {dst.relative_to(OUT_DIR)} ({target_size[0]}x{target_size[1]})")


def main():
    print("=" * 60)
    print("  背包UI素材裁切处理")
    print("=" * 60)
    print(f"  源目录: {RAW_DIR}")
    print(f"  输出目录: {OUT_DIR}")
    print()

    # ── A. 底部按钮 ──
    BTN_SIZE = (120, 50)
    BTN_SMALL_SIZE = (36, 36)
    btn_dir = OUT_DIR / "buttons"
    
    print("[PHASE A] 底部操作按钮")
    for btn_key in ["btn_use", "btn_equip", "btn_drop", "btn_close"]:
        for state in ["normal", "hover", "pressed"]:
            src = RAW_DIR / "buttons" / f"{btn_key}_{state}.png"
            dst = btn_dir / f"{btn_key}_{state}.png"
            process_and_save(src, dst, BTN_SIZE)

    for btn_key in ["btn_plus", "btn_minus"]:
        for state in ["normal", "hover", "pressed"]:
            src = RAW_DIR / "buttons" / f"{btn_key}_{state}.png"
            dst = btn_dir / f"{btn_key}_{state}.png"
            process_and_save(src, dst, BTN_SMALL_SIZE)

    # ── B. 左侧Tab标签 ──
    TAB_SIZE = (100, 40)
    tab_dir = OUT_DIR / "tabs"

    print("\n[PHASE B] 左侧Tab标签")
    for tab_key in ["tab_all", "tab_consumable", "tab_equipment", "tab_key", "tab_material"]:
        for state in ["normal", "selected"]:
            src = RAW_DIR / "tabs" / f"{tab_key}_{state}.png"
            dst = tab_dir / f"{tab_key}_{state}.png"
            process_and_save(src, dst, TAB_SIZE)

    # ── C. 道具图标 ──
    ICON_SIZE = (80, 80)
    icon_dir = OUT_DIR / "icons"

    print("\n[PHASE C] 道具图标")
    for icon_key in ["icon_sword", "icon_armor", "icon_potion", "icon_ore",
                     "icon_scroll", "icon_key", "icon_ring", "icon_talisman"]:
        src = RAW_DIR / "icons" / f"{icon_key}.png"
        dst = icon_dir / f"{icon_key}.png"
        process_and_save(src, dst, ICON_SIZE)

    # ── D. 道具格子 ──
    CELL_SIZE = (88, 88)
    BADGE_SIZE = (20, 20)
    cell_dir = OUT_DIR / "cells"

    print("\n[PHASE D] 道具格子")
    for cell_key in ["cell_default", "cell_selected", "cell_empty"]:
        src = RAW_DIR / "cells" / f"{cell_key}.png"
        dst = cell_dir / f"{cell_key}.png"
        process_and_save(src, dst, CELL_SIZE)

    for badge_key in ["badge_common", "badge_epic", "badge_equipment", "badge_rare"]:
        src = RAW_DIR / "cells" / f"{badge_key}.png"
        dst = cell_dir / f"{badge_key}.png"
        process_and_save(src, dst, BADGE_SIZE)

    # ── E. 详情框 ──
    FRAME_SIZE = (140, 140)
    SEP_SIZE = (300, 6)
    frame_dir = OUT_DIR / "frames"

    print("\n[PHASE E] 详情区框架")
    process_and_save(RAW_DIR / "frames" / "frame_large_item.png",
                     frame_dir / "frame_large_item.png", FRAME_SIZE)
    process_and_save(RAW_DIR / "frames" / "separator_line.png",
                     frame_dir / "separator_line.png", SEP_SIZE)

    # ── F. 面板底框（从设计稿提取暗色底板） ──
    print("\n[PHASE F] 面板底框")
    _generate_panel_bg()

    print("\n" + "=" * 60)
    print("  裁切处理完成！")
    print("=" * 60)
    _show_summary()


def _generate_panel_bg():
    """
    从设计稿 ui_display_inventory_bright.png 提取面板底框区域，
    去掉道具/文字只保留底板框架。
    
    如果底框提取困难，生成一个纯色+边框的占位底板，
    方便你手动调整后再替换。
    """
    design_src = PROJECT_ROOT / "game" / "art" / "ui" / "cold_wuxia" / "v2" / "ui_display_inventory_bright.png"
    out_path = OUT_DIR / "panel_bg.png"
    
    if not design_src.exists():
        print(f"  [WARN] 设计稿不存在: {design_src.name}")
        return
    
    # 直接从设计稿裁切面板区域作为底框（保留整体布局感）
    img = Image.open(design_src).convert("RGBA")
    # 设计稿本身就是 1280x720 的完整面板，直接用
    if img.width >= 1200 and img.height >= 600:
        panel_bg = img.resize((1280, 720), Image.LANCZOS)
    else:
        panel_bg = img
    
    out_path.parent.mkdir(parents=True, exist_ok=True)
    panel_bg.save(out_path, "PNG")
    print(f"  [OK] panel_bg.png (1280x720) — 设计稿底框")


def _show_summary():
    """Show output statistics."""
    total = 0
    for subdir in OUT_DIR.iterdir():
        if subdir.is_dir():
            pngs = list(subdir.glob("*.png"))
            if pngs:
                print(f"  {subdir.name}/ — {len(pngs)} files")
                total += len(pngs)
    root_pngs = list(OUT_DIR.glob("*.png"))
    if root_pngs:
        print(f"  (root) — {len(root_pngs)} files")
        total += len(root_pngs)
    print(f"\n  总计: {total} 张素材")


if __name__ == "__main__":
    main()
