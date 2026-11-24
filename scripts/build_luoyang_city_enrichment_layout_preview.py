#!/usr/bin/env python3
"""Build read-only/offline Luoyang enrichment layout boards.

This tool does not edit any Godot scene, layout, navigation mask, collision,
portal, NPC, or production art.  It only annotates frozen full-region captures
and writes review PNGs plus a provenance manifest under assets/previews/.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013"
GATE_SOURCE = ROOT / "game/build/luoyang_enclosure_v13_export_preview/root_full_v14_ch4_s0_luoyang_gate_01/full_region.png"
MARKET_SOURCE = ROOT / "game/build/luoyang_enclosure_v13_export_preview/root_full_v14_ch4_s3_luoyang_market_01/full_region.png"
FONT_PATH = Path("C:/Windows/Fonts/msyh.ttc")

INK = (10, 18, 24, 245)
WHITE = (240, 247, 250, 255)
CYAN = (59, 214, 240, 230)
GREEN = (72, 219, 149, 190)
GOLD = (242, 174, 70, 190)
RED = (242, 83, 86, 215)
BLUE = (33, 118, 181, 180)
PURPLE = (183, 116, 255, 220)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    selected = Path("C:/Windows/Fonts/msyhbd.ttc") if bold else FONT_PATH
    if not selected.exists():
        selected = FONT_PATH
    return ImageFont.truetype(str(selected), size=size)


def layer_for(base: Image.Image, darkness: int = 92) -> Image.Image:
    rgba = base.convert("RGBA")
    veil = Image.new("RGBA", rgba.size, (5, 12, 16, darkness))
    return Image.alpha_composite(rgba, veil)


def label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, *,
          fill=INK, outline=CYAN, size: int = 35, anchor: str = "la") -> None:
    fnt = font(size, bold=True)
    box = draw.multiline_textbbox(xy, text, font=fnt, spacing=8, anchor=anchor, stroke_width=1)
    pad = 12
    bg = (box[0] - pad, box[1] - pad, box[2] + pad, box[3] + pad)
    draw.rounded_rectangle(bg, radius=10, fill=fill, outline=outline, width=3)
    draw.multiline_text(xy, text, font=fnt, fill=WHITE, spacing=8, anchor=anchor, stroke_width=1, stroke_fill=(0, 0, 0, 180))


def title(draw: ImageDraw.ImageDraw, heading: str, sub: str) -> None:
    draw.rounded_rectangle((36, 28, 1760, 160), radius=18, fill=(7, 16, 22, 238), outline=CYAN, width=4)
    draw.text((72, 50), heading, font=font(52, True), fill=WHITE)
    draw.text((74, 112), sub, font=font(26), fill=(183, 218, 226, 255))


def arrow(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], color=CYAN, width: int = 15) -> None:
    draw.line((start, end), fill=color, width=width)
    x1, y1 = start
    x2, y2 = end
    dx, dy = x2 - x1, y2 - y1
    mag = max((dx * dx + dy * dy) ** 0.5, 1.0)
    ux, uy = dx / mag, dy / mag
    px, py = -uy, ux
    tip = (x2, y2)
    left = (int(x2 - ux * 42 + px * 24), int(y2 - uy * 42 + py * 24))
    right = (int(x2 - ux * 42 - px * 24), int(y2 - uy * 42 - py * 24))
    draw.polygon((tip, left, right), fill=color)


def build_gate() -> dict:
    base = Image.open(GATE_SOURCE)
    canvas = layer_for(base)
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay, "RGBA")
    title(d, "洛阳城门区 · 城防逻辑离线样板", "仅布局建议；正式 layout / walk / 碰撞 / portal 均未改")

    # The actual portal is fixed at (1536, 500).  The visual fortress is moved
    # to that domain in the proposal, while the formal portal remains untouched.
    d.rectangle((110, 300, 2962, 545), fill=(31, 44, 50, 205), outline=CYAN, width=8)
    d.rectangle((1168, 110, 1904, 545), outline=GOLD, width=10)
    d.rectangle((1368, 450, 1704, 1990), fill=(43, 183, 149, 72), outline=GREEN, width=6)
    d.rectangle((80, 650, 2992, 900), fill=BLUE, outline=(95, 190, 238, 255), width=6)
    d.rectangle((1388, 520, 1684, 1035), fill=(172, 146, 104, 205), outline=GOLD, width=8)
    d.rectangle((270, 960, 1180, 1240), fill=(110, 137, 148, 92), outline=(175, 207, 215, 230), width=5)
    d.rectangle((1892, 960, 2802, 1240), fill=(110, 137, 148, 92), outline=(175, 207, 215, 230), width=5)

    # Existing wrong visual domain retained in red as a removal/move note.
    d.rectangle((720, 1280, 2350, 1775), fill=(188, 37, 43, 35), outline=RED, width=8)
    d.line((1536, 1660, 1536, 500), fill=RED, width=6)
    arrow(d, (1536, 1590), (1536, 600), RED, 11)

    # Candidate crowd markers: observers only, no NPC data changes.
    crowd = [(1260, 1045), (1810, 1045), (1170, 1160), (1900, 1160),
             (1280, 430), (1790, 430), (1450, 1110), (1620, 1110)]
    for x, y in crowd:
        d.ellipse((x - 14, y - 14, x + 14, y + 14), fill=PURPLE, outline=WHITE, width=3)

    arrow(d, (1536, 1900), (1536, 1070), GREEN, 14)
    label(d, (1980, 230), "A  实际入口 [1536,500]\n城楼＋连续横墙横贯视野", outline=GOLD)
    label(d, (1840, 690), "B  护城河结构域\n桥外水面不可走；桥面保留 296px 轴线", outline=(95, 190, 238, 255))
    label(d, (1880, 1000), "C  候检区\n门吏 / 守卫 / 旅客；不放普通商宅", outline=PURPLE, size=31)
    label(d, (420, 1310), "当前大灰砖城门 [1536,1660]\n与入口不绑定：样板中迁移，不在此继续放大", outline=RED, size=31)
    label(d, (90, 1810), "南侧：江湖大地图返回脚点 [1536,1860]", outline=GREEN, size=30)
    label(d, (90, 210), "北侧：城内（进入府衙 / 街坊）", outline=CYAN, size=31)

    result = Image.alpha_composite(canvas, overlay)
    out = OUT / "luoyang_gate_defense_layout_blockout_v1.png"
    result.save(out, optimize=True)
    return {"path": out.relative_to(ROOT).as_posix(), "sha256": sha256(out), "size_px": list(result.size)}


def build_market() -> dict:
    base = Image.open(MARKET_SOURCE)
    canvas = layer_for(base)
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay, "RGBA")
    title(d, "洛阳南市 · 密街坊离线样板", "首轮 12 组立面＋6 摊点；先实看密度，再扩到 18–24 组")

    # Fixed portal/main-road reserves.
    d.rectangle((165, 930, 2905, 1190), fill=(54, 210, 160, 72), outline=GREEN, width=7)
    d.rectangle((1390, 650, 1682, 1920), fill=(54, 210, 160, 72), outline=GREEN, width=7)
    # Ring alleys, 2-person minimum concept width (not a nav claim).
    for box in [(860, 640, 1000, 1760), (2070, 640, 2210, 1760),
                (300, 760, 2770, 875), (300, 1350, 2770, 1470)]:
        d.rectangle(box, fill=(65, 170, 215, 45), outline=CYAN, width=4)

    blocks = [
        (120, 190, 690, 730), (730, 180, 1325, 730),
        (1745, 180, 2340, 730), (2380, 200, 2950, 730),
        (210, 1190, 800, 1340), (1020, 1190, 1340, 1340),
        (1730, 1190, 2050, 1340), (2270, 1190, 2860, 1340),
        (110, 1485, 670, 2010), (710, 1485, 1290, 2010),
        (1780, 1485, 2360, 2010), (2400, 1485, 2960, 2010),
    ]
    for idx, box in enumerate(blocks, 1):
        d.rectangle(box, fill=(220, 145, 52, 42), outline=GOLD, width=5)
        d.text((box[0] + 14, box[1] + 12), f"{idx:02d}", font=font(27, True), fill=WHITE,
               stroke_width=2, stroke_fill=(0, 0, 0, 190))

    stalls = [(1080, 900), (1280, 900), (1780, 900), (1980, 900), (1120, 1235), (1940, 1235)]
    for idx, (x, y) in enumerate(stalls, 1):
        d.rounded_rectangle((x - 58, y - 34, x + 58, y + 34), radius=12, fill=(133, 87, 39, 210), outline=GOLD, width=4)
        d.text((x, y), f"摊{idx}", font=font(23, True), fill=WHITE, anchor="mm")

    # 18 visual-only population markers, clustered by function rather than evenly scattered.
    crowd = [(520, 890), (620, 910), (780, 1030), (900, 1070), (1120, 1080),
             (1280, 1040), (1760, 1040), (1930, 1080), (2110, 1050), (2360, 910),
             (2520, 900), (480, 1280), (690, 1290), (2380, 1280), (2580, 1270),
             (1450, 820), (1600, 840), (1530, 1550)]
    for x, y in crowd:
        d.ellipse((x - 13, y - 13, x + 13, y + 13), fill=PURPLE, outline=WHITE, width=2)

    arrow(d, (1536, 800), (1536, 690), CYAN, 12)
    arrow(d, (260, 1060), (150, 1060), CYAN, 12)
    arrow(d, (2810, 1060), (2930, 1060), CYAN, 12)
    arrow(d, (1536, 1810), (1536, 1940), CYAN, 12)

    label(d, (1780, 790), "十字主街：保留四门户直达\n宽 260–292px，不被摊位或NPC堵住", outline=GREEN, size=30)
    label(d, (90, 790), "蓝线：两人并行回环小巷\n不是 nav / Physics 通过声明", outline=CYAN, size=29)
    label(d, (1810, 1395), "金框：独立街坊立面组\n不烘焙成整片背景；不旋转正面楼冒充侧墙", outline=GOLD, size=29)
    label(d, (90, 1410), "紫点：18名首轮氛围NPC视觉配额\n分簇激活，不新增全天Physics", outline=PURPLE, size=29)
    label(d, (90, 195), "北：府衙", outline=CYAN, size=28)
    label(d, (2500, 195), "东：码头", outline=CYAN, size=28)
    label(d, (90, 1905), "南：古寺 / 城外", outline=CYAN, size=28)

    result = Image.alpha_composite(canvas, overlay)
    out = OUT / "luoyang_market_dense_blocks_layout_blockout_v1.png"
    result.save(out, optimize=True)
    return {"path": out.relative_to(ROOT).as_posix(), "sha256": sha256(out), "size_px": list(result.size)}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    outputs = [build_gate(), build_market()]
    manifest = {
        "schema_version": 1,
        "status": "OFFLINE_LAYOUT_BLOCKOUT_NOT_FIELD_OR_PRODUCTION_APPROVAL",
        "generated_images": 0,
        "engine_executed": False,
        "production_files_modified": False,
        "formal_layout_collision_portal_modified": False,
        "sources": [
            {"path": GATE_SOURCE.relative_to(ROOT).as_posix(), "sha256": sha256(GATE_SOURCE)},
            {"path": MARKET_SOURCE.relative_to(ROOT).as_posix(), "sha256": sha256(MARKET_SOURCE)},
        ],
        "outputs": outputs,
        "notes": [
            "Colored domains are authoring guidance, not walk-mask or Physics evidence.",
            "Moat and bridge are deliberately schematic because no approved city-scale matching module exists.",
            "All labels and markers are review overlays; no gameplay identity, NPC position, or route changed.",
        ],
    }
    manifest_path = OUT / "layout_preview_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
