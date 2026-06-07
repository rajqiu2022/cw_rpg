"""
slice_quest_panel.py — 任务面板 UI kit 切图

将 AI 生成的组件 atlas 切分为独立 PNG 素材，
输出到 game/art/ui/quest/ 供 Godot 直接使用。

用法：
    python scripts/slice_quest_panel.py
    python scripts/slice_quest_panel.py --input assets/raw/ui/quest/ui_quest_panel_kit.png
    python scripts/slice_quest_panel.py --preview   # 仅预览检测到的区域，不切图
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


INPUT_DEFAULT = "assets/raw/ui/quest/ui_quest_panel_kit.png"
OUTPUT_DIR = Path("game/art/ui/quest")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# 期望的组件列表（按区域大小匹配）
COMPONENTS = [
    {"name": "panel_bg",           "label": "面板底图",        "min_w": 400, "min_h": 300},
    {"name": "title_plaque",       "label": "标题匾额",        "min_w": 200, "min_h": 40},
    {"name": "btn_close_normal",   "label": "关闭按钮 normal",  "min_w": 80,  "min_h": 30},
    {"name": "btn_close_hover",    "label": "关闭按钮 hover",   "min_w": 80,  "min_h": 30},
    {"name": "btn_close_pressed",  "label": "关闭按钮 pressed", "min_w": 80,  "min_h": 30},
    {"name": "tab_normal",         "label": "筛选标签 normal",  "min_w": 70,  "min_h": 25},
    {"name": "tab_selected",       "label": "筛选标签 selected","min_w": 70,  "min_h": 25},
    {"name": "tab_hover",          "label": "筛选标签 hover",   "min_w": 70,  "min_h": 25},
    {"name": "tab_pressed",        "label": "筛选标签 pressed", "min_w": 70,  "min_h": 25},
    {"name": "dropdown_chapter",   "label": "章节下拉框",       "min_w": 120, "min_h": 25},
    {"name": "quest_row_normal",   "label": "任务列表项 normal","min_w": 250, "min_h": 60},
    {"name": "quest_row_selected", "label": "任务列表项 selected","min_w":250,"min_h": 60},
    {"name": "detail_panel",       "label": "详情区面板",       "min_w": 300, "min_h": 200},
    {"name": "btn_track_normal",   "label": "追踪按钮 normal",  "min_w": 100, "min_h": 30},
    {"name": "btn_track_hover",    "label": "追踪按钮 hover",   "min_w": 100, "min_h": 30},
    {"name": "btn_track_pressed",  "label": "追踪按钮 pressed", "min_w": 100, "min_h": 30},
    {"name": "summary_label",      "label": "卷宗统计标签",     "min_w": 100, "min_h": 15},
]


def detect_regions(img: Image.Image) -> list[dict[str, Any]]:
    """
    自动检测组件区域。
    如果背景是白色(>240)，找非白连通区域；
    如果背景是黑色(<30)，找非黑连通区域。
    """
    from collections import deque

    rgba = img.convert("RGBA")
    w, h = rgba.size
    pix = rgba.load()

    # 判断背景色
    sample_r = sum(pix[x, h // 2][0] for x in range(0, w, 10)) / max(1, w // 10)
    is_dark_bg = sample_r < 60

    visited: set[tuple[int, int]] = set()
    regions: list[dict[str, Any]] = []

    for y in range(0, h, 2):  # 跳行加速
        for x in range(0, w, 2):
            if (x, y) in visited:
                continue
            r, g, b, a = pix[x, y]
            if a < 30:
                visited.add((x, y))
                continue
            is_fg = (r < 200 and g < 200 and b < 200) if not is_dark_bg else (r > 30 or g > 30 or b > 30)
            if not is_fg:
                visited.add((x, y))
                continue

            # BFS 连通区域
            q: deque[tuple[int, int]] = deque()
            q.append((x, y))
            visited.add((x, y))
            min_x, min_y, max_x, max_y = x, y, x, y

            while q:
                cx, cy = q.popleft()
                min_x = min(min_x, cx); max_x = max(max_x, cx)
                min_y = min(min_y, cy); max_y = max(max_y, cy)
                for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
                        nr, ng, nb, na = pix[nx, ny]
                        if na > 30:
                            n_fg = (nr < 200 and ng < 200 and nb < 200) if not is_dark_bg else (nr > 30 or ng > 30 or nb > 30)
                            if n_fg:
                                visited.add((nx, ny))
                                q.append((nx, ny))

            rw, rh = max_x - min_x + 1, max_y - min_y + 1
            if rw > 10 and rh > 10:
                regions.append({
                    "x": min_x, "y": min_y, "w": rw, "h": rh,
                    "cx": min_x + rw // 2, "cy": min_y + rh // 2,
                })

    # 按 y 坐标排序（从上到下），再按 x 排序（从左到右）
    regions.sort(key=lambda r: (r["y"] // 50, r["x"]))
    return regions


def match_components(
    regions: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    """将检测区域匹配到组件列表。"""
    matched: list[dict[str, Any]] = []
    used: set[int] = set()

    for comp in COMPONENTS:
        best_idx = -1
        best_score = float("inf")
        for i, reg in enumerate(regions):
            if i in used:
                continue
            # 面积接近度
            target_area = comp["min_w"] * comp["min_h"]
            reg_area = reg["w"] * reg["h"]
            score = abs(reg_area - target_area) / max(1, target_area)
            if score < best_score and reg["w"] >= comp["min_w"] * 0.5 and reg["h"] >= comp["min_h"] * 0.5:
                best_score = score
                best_idx = i

        if best_idx >= 0:
            used.add(best_idx)
            matched.append({**comp, **regions[best_idx], "match_score": round(best_score, 2)})
        else:
            matched.append({**comp, "x": -1, "y": -1, "w": 0, "h": 0, "match_score": -1})

    return matched


def preview_regions(img: Image.Image, regions: list[dict[str, Any]], output_path: Path) -> None:
    """生成标注预览图。"""
    preview = img.convert("RGBA")
    draw = ImageDraw.Draw(preview)

    colors = ["red", "lime", "blue", "yellow", "cyan", "magenta", "orange", "white"]
    for i, reg in enumerate(regions):
        if reg.get("x", -1) < 0:
            continue
        color = colors[i % len(colors)]
        x, y, w, h = reg["x"], reg["y"], reg["w"], reg["h"]
        draw.rectangle([x, y, x + w, y + h], outline=color, width=2)
        label = reg.get("name", f"#{i}")
        draw.text((x + 2, y + 2), label, fill=color)

    preview.save(output_path)
    print(f"预览图已保存: {output_path}")


def slice_image(
    img: Image.Image,
    matched: list[dict[str, Any]],
    output_dir: Path,
) -> None:
    """切图并保存各组件。"""
    results: list[dict[str, Any]] = []
    for comp in matched:
        name = comp["name"]
        x, y, w, h = comp["x"], comp["y"], comp["w"], comp["h"]
        if x < 0 or w <= 0:
            print(f"  ✗ {name}: 未匹配到区域")
            results.append({"name": name, "status": "unmatched"})
            continue

        crop = img.crop((x, y, x + w, y + h))
        out_path = output_dir / f"{name}.png"
        crop.save(out_path)
        print(f"  ✓ {name}: {w}×{h} → {out_path}")
        results.append({"name": name, "size": [w, h], "path": str(out_path), "status": "ok"})

    # 保存切图元数据
    meta = {
        "source": str(INPUT_DEFAULT),
        "components": results,
    }
    (output_dir / "slice_meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="任务面板 UI kit 切图")
    parser.add_argument("--input", type=str, default=INPUT_DEFAULT, help="输入 atlas 图片")
    parser.add_argument("--preview", action="store_true", help="仅预览检测区域")
    parser.add_argument("--manual", type=str, default="", help="手动坐标 JSON 文件路径")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[ERROR] 文件不存在: {input_path}")
        return

    img = Image.open(input_path).convert("RGBA")
    print(f"输入: {input_path} ({img.size[0]}×{img.size[1]})")

    regions = detect_regions(img)
    print(f"检测到 {len(regions)} 个前景区域")

    matched = match_components(regions)

    # 预览
    preview_path = OUTPUT_DIR / "preview_regions.png"
    preview_regions(img, matched, preview_path)

    if args.preview:
        # 打印区域表格
        print(f"\n{'组件':<20} {'位置':<15} {'尺寸':<12} {'匹配':<8}")
        print("-" * 55)
        for comp in matched:
            if comp["x"] >= 0:
                print(f"{comp['name']:<20} ({comp['x']},{comp['y']}){'':<6} {comp['w']}×{comp['h']}{'':<4} {comp.get('match_score','?'):.2f}")
            else:
                print(f"{comp['name']:<20} ❌ 未匹配")
    else:
        slice_image(img, matched, OUTPUT_DIR)

    print(f"\n预览图: {preview_path}")


if __name__ == "__main__":
    main()
