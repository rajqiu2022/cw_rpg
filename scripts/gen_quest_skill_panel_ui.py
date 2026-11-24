"""Generate clean quest and skill panel UI components.

This is a deterministic fallback for the task/skill panels: images provide
material, borders, and state frames; Godot renders all real text and data.
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
QUEST_OUT = ROOT / "game" / "art" / "ui" / "quest"
SKILL_OUT = ROOT / "game" / "art" / "ui" / "skill"
TOOLS_OUT = ROOT / "tools" / "ui_quest_skill_v2"
INV_BTN_DIR = ROOT / "game" / "art" / "ui" / "inventory" / "buttons"

INK = (8, 13, 17, 255)
PANEL = (15, 24, 30, 248)
PANEL_2 = (22, 35, 43, 245)
EDGE = (54, 82, 99, 255)
EDGE_DIM = (30, 48, 58, 255)
FROST = (132, 190, 220, 255)
JADE = (44, 104, 85, 255)
JADE_HI = (70, 150, 118, 255)
GOLD = (184, 154, 88, 255)
CRIMSON = (116, 34, 36, 255)
CRIMSON_HI = (162, 54, 50, 255)
SHADOW = (0, 0, 0, 110)


def _mask(size: tuple[int, int], radius: int) -> Image.Image:
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return m


def _apply_alpha(img: Image.Image, alpha: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    img.putalpha(alpha)
    return img


def _noise(size: tuple[int, int], opacity: int = 18) -> Image.Image:
    w, h = size
    n = Image.effect_noise((w, h), 38).convert("L")
    a = n.point(lambda p: int(max(0, p - 120) * opacity / 135))
    layer = Image.new("RGBA", size, (180, 220, 230, 0))
    layer.putalpha(a)
    return layer


def _glow(size: tuple[int, int], color: tuple[int, int, int, int], inset: int, blur: int) -> Image.Image:
    w, h = size
    g = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    d.rounded_rectangle((inset, inset, w - inset - 1, h - inset - 1), radius=18, fill=color)
    return g.filter(ImageFilter.GaussianBlur(blur))


def _panel(size: tuple[int, int], radius: int = 18, accent: tuple[int, int, int, int] = FROST) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((10, 12, w - 10, h - 8), radius=radius, fill=SHADOW)
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(shadow)

    base = Image.new("RGBA", size, PANEL)
    base.alpha_composite(_glow(size, (94, 135, 158, 38), 60, 70))
    base.alpha_composite(_noise(size, 15))
    img.alpha_composite(_apply_alpha(base, _mask(size, radius)))

    d = ImageDraw.Draw(img)
    d.rounded_rectangle((5, 5, w - 6, h - 6), radius=radius, outline=(5, 9, 12, 255), width=3)
    d.rounded_rectangle((10, 10, w - 11, h - 11), radius=radius - 3, outline=EDGE, width=2)
    d.rounded_rectangle((17, 17, w - 18, h - 18), radius=radius - 6, outline=(accent[0], accent[1], accent[2], 90), width=1)
    for x, y, sx, sy in [(22, 22, 1, 1), (w - 22, 22, -1, 1), (22, h - 22, 1, -1), (w - 22, h - 22, -1, -1)]:
        d.line((x, y, x + sx * 42, y), fill=(accent[0], accent[1], accent[2], 150), width=2)
        d.line((x, y, x, y + sy * 42), fill=(accent[0], accent[1], accent[2], 150), width=2)
        d.ellipse((x - 4, y - 4, x + 4, y + 4), outline=(accent[0], accent[1], accent[2], 170), width=1)
    return img


def _button(size: tuple[int, int], base: tuple[int, int, int, int], state: str = "normal") -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    color = base
    edge = EDGE
    if state == "hover":
        color = tuple(min(255, c + 22) for c in base[:3]) + (base[3],)
        edge = FROST
        img.alpha_composite(_glow(size, (90, 180, 205, 70), 3, 5))
    elif state == "pressed":
        color = tuple(max(0, c - 28) for c in base[:3]) + (base[3],)
        edge = (80, 88, 92, 255)
    elif state == "selected":
        color = tuple(min(255, c + 12) for c in base[:3]) + (base[3],)
        edge = GOLD
        img.alpha_composite(_glow(size, (180, 150, 80, 58), 4, 6))

    base_img = Image.new("RGBA", size, color)
    base_img.alpha_composite(_noise(size, 8))
    img.alpha_composite(_apply_alpha(base_img, _mask(size, 8)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((1, 1, w - 2, h - 2), radius=8, outline=(3, 8, 10, 255), width=2)
    d.rounded_rectangle((4, 4, w - 5, h - 5), radius=6, outline=edge, width=1)
    d.line((14, 7, w - 14, 7), fill=(220, 245, 255, 42), width=1)
    return img


def _row(size: tuple[int, int], state: str, accent: tuple[int, int, int, int]) -> Image.Image:
    base = PANEL_2 if state == "normal" else (25, 43, 51, 250)
    img = _button(size, base, "selected" if state == "selected" else "normal")
    d = ImageDraw.Draw(img)
    d.line((size[0] - 86, 14, size[0] - 86, size[1] - 14), fill=(accent[0], accent[1], accent[2], 70), width=1)
    d.polygon((24, size[1] // 2, 42, size[1] // 2 - 12, 60, size[1] // 2, 42, size[1] // 2 + 12), outline=accent)
    return img


def _detail(size: tuple[int, int]) -> Image.Image:
    img = _panel(size, 13, FROST)
    d = ImageDraw.Draw(img)
    for y in (78, 210, 350):
        d.line((28, y, size[0] - 28, y), fill=(75, 105, 120, 95), width=1)
    return img


def _plaque(size: tuple[int, int]) -> Image.Image:
    img = _button(size, (18, 28, 34, 245), "normal")
    d = ImageDraw.Draw(img)
    d.line((40, size[1] // 2, size[0] - 40, size[1] // 2), fill=(118, 170, 194, 45), width=1)
    return img


def _save(path: Path, img: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print(f"[OK] {path.relative_to(ROOT)} {img.size[0]}x{img.size[1]}")


def _font(size: int) -> object:
    candidates = [
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/STZHONGS.TTF"),
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
    ]
    for p in candidates:
        if p.exists():
            from PIL import ImageFont
            return ImageFont.truetype(str(p), size)
    from PIL import ImageFont
    return ImageFont.load_default()


def _fit_cover(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    tw, th = size
    scale = max(tw / w, th / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def _inventory_button_state(kind: str, state: str, size: tuple[int, int]) -> Image.Image:
    if kind == "drop":
        return _button(size, CRIMSON, state)
    frame_path = ROOT / "game" / "art" / "ui" / "inventory" / "btn_frame_150x40.png"
    if frame_path.exists():
        img = _fit_cover(Image.open(frame_path), size)
        if state == "hover":
            img = Image.alpha_composite(_glow(size, (92, 185, 210, 80), 2, 5), img)
            return img.point(lambda p: min(255, int(p * 1.18)))
        if state == "pressed":
            return img.point(lambda p: int(p * 0.72))
        return img
    return _button(size, JADE, state)


def _text_button(label: str, kind: str, state: str, size: tuple[int, int], selected: bool = False) -> Image.Image:
    source_state = "hover" if selected and state == "normal" else state
    img = _inventory_button_state(kind, source_state, size)
    if selected:
        glow = _glow(size, (210, 180, 95, 80), 2, 5)
        img = Image.alpha_composite(glow, img)
    d = ImageDraw.Draw(img)
    font = _font(22 if size[0] >= 130 else 19)
    bbox = d.textbbox((0, 0), label, font=font)
    tx = (size[0] - (bbox[2] - bbox[0])) // 2
    ty = (size[1] - (bbox[3] - bbox[1])) // 2 - 2
    shadow_color = (3, 8, 12, 220)
    fill = (238, 228, 200, 255) if selected else (230, 238, 236, 255)
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1), (2, 2)]:
        d.text((tx + dx, ty + dy), label, font=font, fill=shadow_color)
    d.text((tx, ty), label, font=font, fill=fill)
    return img


def _quest_text_buttons() -> list[tuple[str, Image.Image]]:
    specs = [
        ("qtab_active", "进行中", "equip", (126, 42)),
        ("qtab_done", "已完成", "equip", (126, 42)),
        ("qfilter_all", "全部", "use", (96, 38)),
        ("qfilter_main", "主线", "use", (96, 38)),
        ("qfilter_side", "支线", "use", (96, 38)),
        ("qbtn_track", "追踪", "equip", (150, 42)),
        ("qbtn_untrack", "取消追踪", "drop", (150, 42)),
    ]
    items: list[tuple[str, Image.Image]] = []
    for base, label, kind, size in specs:
        for state in ["normal", "hover", "pressed"]:
            items.append((f"{base}_{state}.png", _text_button(label, kind, state, size, False)))
        items.append((f"{base}_selected.png", _text_button(label, kind, "normal", size, True)))
    for name, img in items:
        _save(QUEST_OUT / name, img)
    return items


def generate_quest() -> list[tuple[str, Image.Image]]:
    items = [
        ("panel_bg_v2.png", _panel((1280, 720), 20, FROST)),
        ("title_plaque_v2.png", _plaque((350, 80))),
        ("detail_panel_v2.png", _detail((660, 560))),
        ("quest_row_normal.png", _row((520, 70), "normal", FROST)),
        ("quest_row_hover.png", _row((520, 70), "selected", FROST)),
        ("quest_row_selected.png", _row((520, 70), "selected", GOLD)),
        ("dropdown_chapter.png", _button((170, 38), (13, 22, 27, 245), "normal")),
        ("summary_label.png", _button((240, 28), (16, 28, 36, 210), "normal")),
    ]
    for base in ["tab_all", "tab_main", "tab_done", "tab"]:
        for state in ["normal", "hover", "pressed", "selected"]:
            items.append((f"{base}_{state}.png", _button((86, 36), (18, 30, 38, 245), state)))
    for state in ["normal", "hover", "pressed"]:
        items.append((f"btn_track_{state}.png", _button((190, 46), JADE, state)))
        items.append((f"btn_close_{state}.png", _button((92, 34), CRIMSON, state)))
    for name, img in items:
        _save(QUEST_OUT / name, img)
    items.extend(_quest_text_buttons())
    return items


def generate_skill() -> list[tuple[str, Image.Image]]:
    items = [
        ("panel_bg.png", _panel((1280, 700), 20, FROST)),
        ("title_plaque.png", _plaque((320, 70))),
        ("detail_panel.png", _detail((610, 500))),
        ("skill_row_normal.png", _row((430, 86), "normal", FROST)),
        ("skill_row_selected.png", _row((430, 86), "selected", FROST)),
    ]
    for state in ["normal", "hover", "pressed", "selected"]:
        items.append((f"tab_{state}.png", _button((96, 38), (18, 30, 38, 245), state)))
    for state in ["normal", "hover", "pressed"]:
        items.append((f"btn_quick_{state}.png", _button((170, 44), JADE, state)))
        items.append((f"btn_practice_{state}.png", _button((150, 44), (32, 64, 92, 245), state)))
        items.append((f"btn_close_{state}.png", _button((92, 34), CRIMSON, state)))
    for name, img in items:
        _save(SKILL_OUT / name, img)
    return items


def make_preview(quest_items: list[tuple[str, Image.Image]], skill_items: list[tuple[str, Image.Image]]) -> None:
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    samples = [
        ("quest panel", quest_items[0][1].resize((640, 360), Image.Resampling.LANCZOS)),
        ("quest detail", quest_items[2][1].resize((330, 280), Image.Resampling.LANCZOS)),
        ("quest row", quest_items[3][1]),
        ("skill panel", skill_items[0][1].resize((640, 350), Image.Resampling.LANCZOS)),
        ("skill detail", skill_items[2][1].resize((305, 250), Image.Resampling.LANCZOS)),
        ("skill row", skill_items[3][1]),
    ]
    out = Image.new("RGBA", (980, 760), (16, 20, 24, 255))
    d = ImageDraw.Draw(out)
    positions = [(20, 20), (690, 20), (690, 320), (20, 400), (690, 400), (690, 665)]
    for (label, img), pos in zip(samples, positions):
        out.alpha_composite(img, pos)
        d.text((pos[0], pos[1] + img.height + 4), label, fill=(210, 220, 220, 255))
    _save(TOOLS_OUT / "preview.png", out)


def main() -> None:
    quest = generate_quest()
    skill = generate_skill()
    make_preview(quest, skill)


if __name__ == "__main__":
    main()
