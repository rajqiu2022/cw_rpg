"""
slice_quest_atlas.py — 切分用户生成的 UI 控件集合图

从 AI 生成的控件集合图中，按区域位置切出独立 PNG 组件。
"""

from pathlib import Path
from PIL import Image

SRC = Path("images/01KTHBMWPZTTC5GMDTK550BGG9.png")
DST = Path("game/art/ui/quest")

# 手动标注组件区域（从自动检测的 57 个区域中挑选）
REGIONS = {
    "panel_bg":            (30,   20,  537, 373),   # 面板底框
    "title_plaque":        (602,  89,  309,  67),   # 标题匾额
    "btn_close_strip":     (953, 141,  129, 246),   # 关闭按钮三态竖排
    "tab_normal":          (44,  438,  195,  66),   # 筛选标签 normal
    "tab_selected":        (272, 443,  177,  57),   # 筛选标签 selected
    "tab_hover":           (489, 443,  176,  57),   # 筛选标签 hover
    "tab_pressed":         (602, 361,  176,  57),   # 筛选标签 pressed (estimated)
    "dropdown_chapter":    (990, 548,  212,  41),   # 章节下拉框
    "quest_row_normal":    (31,  562,  454,  69),   # 任务行 normal
    "quest_row_selected":  (515, 570,  433,  57),   # 任务行 selected
    "detail_panel":        (50,  942,  524,  42),   # 详情面板（宽条）
    "btn_track_strip":     (32, 1015,  163, 125),   # 追踪按钮三态竖排
    "summary_label":       (628, 949,  267,  31),   # 卷宗统计
}

def slice_strip(img, region, count, horizontal=False):
    """将竖排/横排条带切成 N 个等份"""
    x, y, w, h = region
    if horizontal:
        each = w // count
        return [img.crop((x + i*each, y, x + (i+1)*each, y + h)) for i in range(count)]
    else:
        each = h // count
        return [img.crop((x, y + i*each, x + w, y + (i+1)*each)) for i in range(count)]


def main():
    DST.mkdir(parents=True, exist_ok=True)
    img = Image.open(SRC).convert("RGBA")
    print(f"Source: {SRC} ({img.size[0]}x{img.size[1]})")

    for name, (x, y, w, h) in REGIONS.items():
        if x < 0: continue
        crop = img.crop((x, y, x + w, y + h))
        path = DST / f"{name}.png"
        crop.save(path)
        print(f"  ✓ {name}: {w}x{h}")

    # 切三态条带
    strips = [
        ("btn_close", REGIONS["btn_close_strip"], 3),
        ("btn_track", REGIONS["btn_track_strip"], 3),
    ]
    for base, region, count in strips:
        parts = slice_strip(img, region, count)
        for i, part in enumerate(parts):
            state = ["normal", "hover", "pressed"][i]
            path = DST / f"{base}_{state}.png"
            part.save(path)
            print(f"  ✓ {base}_{state}: {part.size[0]}x{part.size[1]} (from strip)")

    print(f"\nDone → {DST}/")


if __name__ == "__main__":
    main()
