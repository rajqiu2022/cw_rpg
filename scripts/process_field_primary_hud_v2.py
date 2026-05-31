from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v1.png"
V1 = ROOT / "game/art/ui/field_hud/v1"
GAME_OUT = ROOT / "game/art/ui/field_hud/v2"
TOOLS_PREVIEW = ROOT / "tools/field_primary_hud_v2_preview.png"
TOOLS_ANNOTATED = ROOT / "tools/field_primary_hud_reference_measure.png"
TOOLS_COMPARE = ROOT / "tools/field_primary_hud_design_compare.png"


REF_SIZE = (819, 548)
DESIGN_SIZE = (1920, 1080)
SX = DESIGN_SIZE[0] / REF_SIZE[0]
SY = DESIGN_SIZE[1] / REF_SIZE[1]

# Coordinates measured on assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_field_hud_screen_gpt_v1.png.
# They are deliberately kept in source-image pixels so later reviews can compare
# against the design without guessing from 1080P coordinates.
REF_RECTS: dict[str, tuple[int, int, int, int]] = {
    "player_panel": (9, 10, 309, 124),
    "avatar": (23, 25, 87, 95),
    "name": (103, 26, 165, 43),
    "hp_caption": (104, 51, 131, 64),
    "hp_bar": (134, 48, 240, 58),
    "hp_value": (243, 47, 298, 60),
    "mp_caption": (104, 74, 131, 87),
    "mp_bar": (134, 70, 240, 81),
    "mp_value": (243, 70, 298, 83),
    "level": (102, 96, 162, 112),
    "gold_panel": (20, 122, 97, 149),
    "map_panel": (542, 18, 765, 49),
    "quest_panel": (571, 334, 800, 462),
    "right_menu": (704, 78, 817, 288),
}

LAYOUT_1080 = {
    key: tuple(round(v * (SX if idx % 2 == 0 else SY)) for idx, v in enumerate(rect))
    for key, rect in REF_RECTS.items()
}


def _clean_transparent_edges(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    arr[arr[:, :, 3] <= 2, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _resized_crop(source: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int]) -> Image.Image:
    return source.crop(box).resize(size, Image.Resampling.LANCZOS).convert("RGBA")


def _make_bar(size: tuple[int, int], fill: tuple[int, int, int], edge: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=size[1] // 2, fill=(*edge, 210))
    draw.rounded_rectangle((3, 3, size[0] - 4, size[1] - 4), radius=max(1, size[1] // 2 - 3), fill=(*fill, 238))
    return image


def _make_panel(size: tuple[int, int], alpha: int = 186, corner: int = 18, border_alpha: int = 165) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    base_draw = ImageDraw.Draw(base)
    base_draw.rounded_rectangle((6, 6, w - 7, h - 7), radius=corner, fill=(7, 17, 23, alpha))
    # Subtle top-to-bottom cold steel wash.
    wash = Image.new("RGBA", size, (0, 0, 0, 0))
    pix = wash.load()
    for y in range(h):
        t = y / max(1, h - 1)
        for x in range(w):
            edge = min(x / max(1, w), (w - x) / max(1, w), y / max(1, h), (h - y) / max(1, h))
            edge_dark = max(0.0, min(1.0, edge * 7.0))
            a = int((52 * (1.0 - t) + 18 * t) * edge_dark)
            pix[x, y] = (52, 78, 90, a)
    base.alpha_composite(wash)
    image.alpha_composite(base)

    draw.rounded_rectangle((6, 6, w - 7, h - 7), radius=corner, outline=(79, 108, 120, border_alpha), width=2)
    draw.rounded_rectangle((12, 12, w - 13, h - 13), radius=max(6, corner - 6), outline=(5, 10, 15, 130), width=2)
    draw.line((22, 12, w - 23, 12), fill=(133, 160, 168, 72), width=1)
    draw.line((22, h - 13, w - 23, h - 13), fill=(0, 0, 0, 112), width=1)
    return _clean_transparent_edges(image)


def _make_player_panel() -> Image.Image:
    size = (704, 225)
    image = _make_panel(size, 178, 18, 170)
    draw = ImageDraw.Draw(image)

    # Avatar medallion, matching the reference left placement.
    draw.polygon([(18, 78), (62, 18), (168, 18), (212, 78), (168, 168), (62, 168)], fill=(8, 16, 22, 218), outline=(83, 116, 130, 190))
    draw.ellipse((36, 34, 162, 160), fill=(5, 12, 17, 234), outline=(92, 128, 142, 210), width=3)
    draw.ellipse((45, 43, 153, 151), outline=(18, 35, 45, 220), width=2)

    # Name tag and three text/value lanes.
    draw.rounded_rectangle((232, 20, 390, 56), radius=7, fill=(7, 15, 20, 196), outline=(64, 94, 108, 140), width=2)
    draw.rounded_rectangle((222, 70, 675, 101), radius=9, fill=(8, 17, 22, 166), outline=(33, 57, 66, 120), width=1)
    draw.rounded_rectangle((222, 112, 675, 143), radius=9, fill=(8, 17, 22, 156), outline=(33, 57, 66, 110), width=1)
    draw.rounded_rectangle((222, 154, 392, 190), radius=8, fill=(8, 16, 22, 164), outline=(55, 80, 90, 128), width=1)

    # Gold strip below, like the reference but not baked text.
    draw.rounded_rectangle((22, 174, 190, 213), radius=10, fill=(9, 18, 24, 184), outline=(79, 100, 95, 130), width=1)
    draw.ellipse((34, 183, 60, 209), fill=(92, 78, 42, 225), outline=(190, 168, 95, 180), width=2)
    return _clean_transparent_edges(image)


def _make_map_panel() -> Image.Image:
    image = _make_panel((522, 62), 116, 13, 105)
    draw = ImageDraw.Draw(image)
    draw.polygon([(0, 31), (30, 7), (492, 7), (522, 31), (492, 55), (30, 55)], outline=(90, 118, 126, 115), fill=None)
    return image


def _make_quest_panel() -> Image.Image:
    image = _make_panel((536, 252), 148, 15, 130)
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((38, 22, 232, 54), radius=10, fill=(8, 17, 23, 180), outline=(68, 98, 110, 125), width=1)
    draw.rounded_rectangle((36, 70, 500, 220), radius=8, fill=(6, 13, 18, 108), outline=(18, 36, 45, 100), width=1)
    return image


def _annotated_reference(source: Image.Image) -> Image.Image:
    out = source.convert("RGBA")
    draw = ImageDraw.Draw(out)
    colors = {
        "player_panel": (255, 80, 80, 230),
        "map_panel": (255, 220, 80, 230),
        "quest_panel": (80, 220, 140, 230),
        "right_menu": (90, 170, 255, 230),
    }
    for name, rect in REF_RECTS.items():
        color = colors.get(name, (255, 255, 255, 200))
        draw.rectangle(rect, outline=color, width=2)
        draw.text((rect[0] + 2, rect[1] + 2), name, fill=color)
    return out


def _save(image: Image.Image, name: str) -> Image.Image:
    GAME_OUT.mkdir(parents=True, exist_ok=True)
    image.save(GAME_OUT / name)
    return image


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")

    TOOLS_ANNOTATED.parent.mkdir(parents=True, exist_ok=True)
    _annotated_reference(source).save(TOOLS_ANNOTATED)

    player_panel = _save(_make_player_panel(), "hud_player_panel.png")
    _save(player_panel, "hud_player_panel.png")

    avatar = _resized_crop(source, REF_RECTS["avatar"], (150, 164))
    _save(avatar, "hud_avatar_lengguyun.png")

    scene_panel = _make_map_panel()
    _save(scene_panel, "hud_map_info_panel.png")

    quest_panel = _make_quest_panel()
    _save(quest_panel, "hud_quest_summary_panel.png")

    _save(_make_bar((250, 20), (165, 36, 35), (54, 12, 14)), "hud_hp_fill.png")
    _save(_make_bar((250, 20), (34, 129, 158), (10, 42, 56)), "hud_mp_fill.png")
    _save(_make_bar((250, 20), (24, 37, 43), (8, 12, 15)), "hud_bar_bg.png")

    preview = Image.new("RGBA", (1920, 1080), (18, 27, 34, 255))
    preview.alpha_composite(player_panel, LAYOUT_1080["player_panel"][:2])
    preview.alpha_composite(scene_panel, LAYOUT_1080["map_panel"][:2])
    preview.alpha_composite(quest_panel, LAYOUT_1080["quest_panel"][:2])
    for idx, key in enumerate(["inventory", "equipment", "skill", "quest", "system"]):
        src = ROOT / f"game/art/ui/field_hud/v1/hud_btn_{key}_normal.png"
        if src.exists():
            preview.alpha_composite(Image.open(src).convert("RGBA"), (1650, 154 + idx * 98))
    dialog_path = GAME_OUT / "hud_dialog_frame.png"
    if dialog_path.exists():
        preview.alpha_composite(Image.open(dialog_path).convert("RGBA"), (160, 760))
    draw = ImageDraw.Draw(preview)
    draw.text((LAYOUT_1080["name"][0], LAYOUT_1080["name"][1]), "冷孤云", fill=(232, 232, 216, 255))
    draw.text((LAYOUT_1080["hp_caption"][0], LAYOUT_1080["hp_caption"][1]), "生命", fill=(220, 224, 210, 255))
    draw.text((LAYOUT_1080["mp_caption"][0], LAYOUT_1080["mp_caption"][1]), "内力", fill=(220, 224, 210, 255))
    TOOLS_PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(TOOLS_PREVIEW)
    reference_1080 = source.resize(DESIGN_SIZE, Image.Resampling.LANCZOS)
    compare = Image.new("RGBA", (1920, 540), (0, 0, 0, 255))
    compare.alpha_composite(reference_1080.resize((960, 540), Image.Resampling.LANCZOS), (0, 0))
    compare.alpha_composite(preview.resize((960, 540), Image.Resampling.LANCZOS), (960, 0))
    compare.save(TOOLS_COMPARE)
    print(GAME_OUT)
    print(TOOLS_PREVIEW)
    print(TOOLS_ANNOTATED)
    print(TOOLS_COMPARE)
    print(LAYOUT_1080)


if __name__ == "__main__":
    main()
