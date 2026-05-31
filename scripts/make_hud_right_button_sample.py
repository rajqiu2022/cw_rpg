from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "tools/ui_field_hud_v1/right_button_sample"
PREVIEW = ROOT / "tools/ui_field_hud_v1/right_button_sample_preview.png"
REFERENCE = ROOT / "assets/raw/ui/field_hud/reference/hud_right_buttons_design_ref.png"

SIZE = (241, 93)
SCALE = 4


def _font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        Path("C:/Windows/Fonts/STKAITI.TTF"),
        Path("C:/Windows/Fonts/simkai.ttf"),
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise FileNotFoundError("No suitable Chinese font found")


def _s(v: float) -> int:
    return round(v * SCALE)


def _poly(points: list[tuple[float, float]]) -> list[tuple[int, int]]:
    return [(_s(x), _s(y)) for x, y in points]


def _clean_transparent_pixels(image: Image.Image, threshold: int = 2) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low = arr[:, :, 3] <= threshold
    arr[low, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _button_points(left: float, top: float, right: float, bottom: float, point: float) -> list[tuple[float, float]]:
    mid = (top + bottom) / 2
    return [
        (left + 14, top),
        (right - point, top),
        (right, mid),
        (right - point, bottom),
        (left + 14, bottom),
        (left, bottom - 12),
        (left, top + 12),
    ]


def _draw_plate(draw: ImageDraw.ImageDraw, offset_y: float = 0.0, fill_shift: int = 0) -> None:
    # Shape follows the close-up reference: a compact blue-gray plaque with a
    # clipped left edge, right arrow tip, and soft stacked bevels.
    outer = _button_points(5, 9 + offset_y, 235, 80 + offset_y, 23)
    mid = _button_points(11, 15 + offset_y, 225, 74 + offset_y, 18)
    inner = _button_points(19, 22 + offset_y, 215, 67 + offset_y, 13)

    draw.polygon(_poly(outer), fill=(18, 30, 36, 248))
    draw.line(_poly(outer + [outer[0]]), fill=(65, 83, 91, 245), width=_s(2.4), joint="curve")
    draw.line(_poly([(9, 14 + offset_y), (216, 14 + offset_y), (231, 45 + offset_y)]), fill=(103, 126, 135, 120), width=_s(1.1))
    draw.line(_poly([(9, 76 + offset_y), (216, 76 + offset_y), (231, 45 + offset_y)]), fill=(6, 12, 16, 115), width=_s(1.4))

    draw.polygon(_poly(mid), fill=(34, 48, 56, 252))
    draw.line(_poly(mid + [mid[0]]), fill=(84, 105, 113, 205), width=_s(1.2))

    face_color = (37 + fill_shift, 55 + fill_shift, 63 + fill_shift, 255)
    draw.polygon(_poly(inner), fill=face_color)
    draw.line(_poly(inner + [inner[0]]), fill=(16, 25, 30, 235), width=_s(2.0))
    draw.line(_poly([(24, 25 + offset_y), (198, 25 + offset_y), (213, 45 + offset_y)]), fill=(63, 81, 89, 125), width=_s(1.0))
    draw.line(_poly([(24, 65 + offset_y), (198, 65 + offset_y), (213, 45 + offset_y)]), fill=(12, 18, 23, 135), width=_s(1.0))


def _draw_bag_icon(draw: ImageDraw.ImageDraw, offset_y: float = 0.0) -> None:
    # Hand-drawn icon, not cropped from the reference.
    cx, cy = 58, 47 + offset_y
    draw.ellipse((_s(cx - 20), _s(cy + 0), _s(cx + 20), _s(cy + 25)), fill=(222, 218, 203, 255), outline=(90, 88, 80, 235), width=_s(1.2))
    draw.rounded_rectangle((_s(cx - 15), _s(cy - 28), _s(cx + 15), _s(cy + 6)), radius=_s(9), fill=(235, 232, 218, 255), outline=(95, 92, 83, 235), width=_s(1.1))
    draw.rectangle((_s(cx - 15), _s(cy - 2), _s(cx + 15), _s(cy + 8)), fill=(229, 225, 211, 255))
    draw.line(_poly([(cx - 16, cy - 2), (cx + 16, cy - 2)]), fill=(90, 78, 61, 255), width=_s(1.8))
    draw.line(_poly([(cx - 12, cy - 7), (cx - 2, cy - 1), (cx - 11, cy + 7)]), fill=(66, 55, 41, 255), width=_s(2.0))
    draw.line(_poly([(cx + 12, cy - 7), (cx + 2, cy - 1), (cx + 11, cy + 7)]), fill=(66, 55, 41, 255), width=_s(2.0))
    draw.arc((_s(cx - 20), _s(cy - 27), _s(cx + 1), _s(cy - 1)), start=30, end=150, fill=(73, 62, 47, 255), width=_s(1.6))
    draw.arc((_s(cx - 1), _s(cy - 27), _s(cx + 20), _s(cy - 1)), start=30, end=150, fill=(73, 62, 47, 255), width=_s(1.6))
    draw.ellipse((_s(cx - 10), _s(cy + 4), _s(cx + 13), _s(cy + 20)), fill=(247, 244, 231, 62))


def _draw_label(draw: ImageDraw.ImageDraw, label: str, offset_y: float = 0.0) -> None:
    font = _font(36 * SCALE)
    # Draw at high resolution directly because font size is also scaled.
    text_layer = Image.new("RGBA", (SIZE[0] * SCALE, SIZE[1] * SCALE), (0, 0, 0, 0))
    td = ImageDraw.Draw(text_layer)
    bbox = td.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = _s(148) - tw // 2
    y = _s(45 + offset_y) - th // 2 - _s(4)
    td.text((x + _s(2), y + _s(3)), label, font=font, fill=(4, 8, 10, 190), stroke_width=_s(1), stroke_fill=(4, 8, 10, 170))
    td.text((x, y), label, font=font, fill=(238, 236, 222, 255), stroke_width=_s(1), stroke_fill=(62, 70, 70, 165))
    return text_layer


def make_normal() -> Image.Image:
    canvas = Image.new("RGBA", (SIZE[0] * SCALE, SIZE[1] * SCALE), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(_poly(_button_points(5, 9, 235, 80, 23)), fill=(0, 0, 0, 105))
    shadow = shadow.filter(ImageFilter.GaussianBlur(_s(1.8)))
    canvas.alpha_composite(shadow, (_s(1), _s(2)))

    draw = ImageDraw.Draw(canvas, "RGBA")
    _draw_plate(draw)
    _draw_bag_icon(draw)
    canvas.alpha_composite(_draw_label(draw, "背包"))
    # Slight blur after downscale better matches the soft, low-res painted source.
    return _clean_transparent_pixels(canvas.resize(SIZE, Image.Resampling.LANCZOS).filter(ImageFilter.GaussianBlur(0.18)))


def derive_state(base: Image.Image, state: str) -> Image.Image:
    alpha = base.getchannel("A")
    rgb = base.convert("RGB")
    if state == "hover":
        rgb = ImageEnhance.Brightness(rgb).enhance(1.13)
        rgb = ImageEnhance.Color(rgb).enhance(1.06)
    elif state == "pressed":
        rgb = ImageEnhance.Brightness(rgb).enhance(0.78)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    if state == "hover":
        glow = Image.new("RGBA", SIZE, (114, 171, 183, 0))
        glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(3)).point(lambda a: int(a * 0.22)))
        out = Image.alpha_composite(glow, out)
        out.putalpha(alpha)
    return _clean_transparent_pixels(out)


def make_preview(outputs: dict[str, Image.Image]) -> None:
    ref = Image.open(REFERENCE).convert("RGBA")
    ref = ref.resize((round(ref.width * 0.75), round(ref.height * 0.75)), Image.Resampling.LANCZOS)
    w = max(ref.width, SIZE[0] * 3 + 48)
    h = ref.height + SIZE[1] + 60
    preview = Image.new("RGBA", (w, h), (18, 24, 30, 255))
    preview.alpha_composite(ref, ((w - ref.width) // 2, 12))
    x0 = (w - (SIZE[0] * 3 + 48)) // 2
    y = ref.height + 36
    for idx, state in enumerate(("normal", "hover", "pressed")):
        preview.alpha_composite(outputs[state], (x0 + idx * (SIZE[0] + 24), y))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    normal = make_normal()
    outputs = {
        "normal": normal,
        "hover": derive_state(normal, "hover"),
        "pressed": derive_state(normal, "pressed"),
    }
    for state, image in outputs.items():
        image.save(OUT_DIR / f"hud_btn_inventory_sample_{state}.png")
    make_preview(outputs)
    print(OUT_DIR)
    print(PREVIEW)


if __name__ == "__main__":
    main()
