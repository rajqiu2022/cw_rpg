from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
RAW_LAYERS = ROOT / "assets/raw/ui/field_hud/layers"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/single_frame_v3"
PREVIEW = ROOT / "tools/ui_field_hud_v1/single_frame_v3_preview.png"
SIZE = (241, 93)

FRAME_SOURCE = RAW_LAYERS / "ui_field_hud_frame_layer_v2_candidate_a.png"
SYSTEM_TEXT_GLYPH_SOURCE = ROOT / "tools/ui_field_hud_v1/layered_v2_candidates/text_system.png"
SYSTEM_TEXT_STYLE_SOURCE = ROOT / "tools/ui_field_hud_v1/layered_v2_candidates/text_equipment.png"
ICON_SOURCES = {
    "inventory": RAW_LAYERS / "ui_field_hud_icon_inventory_layer_v2_candidate_a.png",
    "equipment": RAW_LAYERS / "ui_field_hud_icon_equipment_layer_v2_candidate_a.png",
    "skill": RAW_LAYERS / "ui_field_hud_icon_skill_layer_v2_candidate_a.png",
    "quest": RAW_LAYERS / "ui_field_hud_icon_quest_layer_v2_candidate_a.png",
    "system": RAW_LAYERS / "ui_field_hud_icon_system_layer_v2_candidate_a.png",
}
LABELS = {
    "inventory": "背包",
    "equipment": "装备",
    "skill": "武学",
    "quest": "任务",
    "system": "系统",
}

ICON_CENTER = (62, 48)
ICON_MAX_SIZE = (54, 54)
TEXT_CENTER = (158, 49)
TEXT_CANVAS_SIZE = (220, 110)
TEXT_MAX_SIZE = (102, 56)
TEXT_FONT_SIZE = 62
TEXT_STROKE = 1
TEXT_BODY_COLOR = np.array([228, 218, 196], dtype=np.uint8)
TEXT_EDGE_COLOR = np.array([108, 110, 113], dtype=np.uint8)


def _clean(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    arr[arr[:, :, 3] <= 2, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _connected_background_mask(image: Image.Image) -> np.ndarray:
    arr = np.array(image.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3]
    h, w = alpha.shape
    corners = np.array([rgb[0, 0], rgb[0, w - 1], rgb[h - 1, 0], rgb[h - 1, w - 1]])
    bg_color = np.median(corners, axis=0)
    diff = np.abs(rgb - bg_color).max(axis=2)
    brightness = rgb.mean(axis=2)
    if bg_color.mean() > 160:
        bg = (diff < 38) & (brightness > 204) & (alpha > 0)
    else:
        bg = (diff < 30) & (brightness < 46) & (alpha > 0)

    seen = np.zeros(bg.shape, dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if bg[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if bg[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((x, y))
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and bg[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                q.append((nx, ny))
    return seen


def _crop_to_alpha(image: Image.Image, threshold: int = 8) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    arr[_connected_background_mask(image), 0:4] = 0
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > threshold)
    if len(xs) == 0:
        raise ValueError("image has no visible alpha")
    return Image.fromarray(arr, "RGBA").crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def _normalize_frame(image: Image.Image) -> Image.Image:
    crop = _crop_to_alpha(image)
    canvas = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    scale = min(SIZE[0] / crop.width, SIZE[1] / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((SIZE[0] - resized.width) // 2, (SIZE[1] - resized.height) // 2))
    return _clean(canvas)


def _fit_layer(image: Image.Image, max_size: tuple[int, int], center: tuple[int, int]) -> Image.Image:
    item = _crop_to_alpha(image)
    item.thumbnail(max_size, Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.alpha_composite(item, (center[0] - item.width // 2, center[1] - item.height // 2))
    return _clean(layer)


def _normalize_text_color(layer: Image.Image) -> Image.Image:
    arr = np.array(layer.convert("RGBA"))
    alpha = arr[:, :, 3]
    body = alpha >= 72
    edge = (alpha >= 18) & (alpha < 72)
    arr[body, :3] = TEXT_BODY_COLOR
    arr[edge, :3] = (
        TEXT_EDGE_COLOR.astype(np.float32) * 0.55
        + TEXT_BODY_COLOR.astype(np.float32) * 0.45
    ).astype(np.uint8)
    return _clean(Image.fromarray(arr, "RGBA"))


def _system_text_layer() -> Image.Image:
    glyph = _fit_layer(Image.open(SYSTEM_TEXT_GLYPH_SOURCE).convert("RGBA"), TEXT_MAX_SIZE, TEXT_CENTER)
    style = np.array(Image.open(SYSTEM_TEXT_STYLE_SOURCE).convert("RGBA"))
    style_rgb = style[:, :, :3].astype(np.float32)
    style_alpha = style[:, :, 3]

    body_samples = style_rgb[style_alpha >= 150]
    mid_samples = style_rgb[(style_alpha >= 48) & (style_alpha < 150)]
    edge_samples = style_rgb[(style_alpha >= 12) & (style_alpha < 48)]
    body_color = np.percentile(body_samples, 70, axis=0)
    mid_color = np.median(mid_samples, axis=0)
    edge_color = np.median(edge_samples, axis=0)

    arr = np.array(glyph.convert("RGBA"))
    alpha = arr[:, :, 3]
    body = alpha >= 112
    mid = (alpha >= 42) & (alpha < 112)
    edge = (alpha >= 10) & (alpha < 42)
    arr[body, :3] = body_color.astype(np.uint8)
    arr[mid, :3] = (body_color * 0.42 + mid_color * 0.58).astype(np.uint8)
    arr[edge, :3] = (edge_color * 0.75 + mid_color * 0.25).astype(np.uint8)
    return _clean(Image.fromarray(arr, "RGBA"))


def _font() -> ImageFont.FreeTypeFont:
    for path in [
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
        Path("C:/Windows/Fonts/STKAITI.TTF"),
        Path("C:/Windows/Fonts/simkai.ttf"),
    ]:
        if path.exists():
            return ImageFont.truetype(str(path), TEXT_FONT_SIZE)
    raise FileNotFoundError("missing Chinese font")


def _icon_layer(key: str) -> Image.Image:
    return _fit_layer(Image.open(ICON_SOURCES[key]).convert("RGBA"), ICON_MAX_SIZE, ICON_CENTER)


def _text_layer(key: str) -> Image.Image:
    if key == "system":
        return _system_text_layer()

    label = LABELS[key]
    font = _font()
    canvas = Image.new("RGBA", TEXT_CANVAS_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((0, 0), label, font=font, stroke_width=TEXT_STROKE)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (TEXT_CANVAS_SIZE[0] - text_w) // 2
    y = (TEXT_CANVAS_SIZE[1] - text_h) // 2 - 8

    shadow = Image.new("RGBA", TEXT_CANVAS_SIZE, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.text(
        (x + 4, y + 6),
        label,
        font=font,
        fill=(0, 0, 0, 88),
        stroke_width=TEXT_STROKE,
        stroke_fill=(0, 0, 0, 54),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(1.0))
    canvas = Image.alpha_composite(canvas, shadow)

    draw = ImageDraw.Draw(canvas)
    draw.text(
        (x, y),
        label,
        font=font,
        fill=(240, 230, 202, 255),
        stroke_width=TEXT_STROKE,
        stroke_fill=(72, 63, 52, 118),
    )
    draw.text((x - 1, y - 1), label, font=font, fill=(255, 247, 221, 76), stroke_width=0)
    return _normalize_text_color(_fit_layer(canvas, TEXT_MAX_SIZE, TEXT_CENTER))


def _derive_state(base: Image.Image, state: str) -> Image.Image:
    alpha = base.getchannel("A")
    rgb = base.convert("RGB")
    if state == "hover":
        rgb = ImageEnhance.Brightness(rgb).enhance(1.12)
        rgb = ImageEnhance.Color(rgb).enhance(1.05)
    elif state == "pressed":
        rgb = ImageEnhance.Brightness(rgb).enhance(0.76)
        rgb = ImageEnhance.Color(rgb).enhance(0.95)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    if state == "hover":
        glow = Image.new("RGBA", SIZE, (90, 145, 155, 0))
        glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.22)))
        out = Image.alpha_composite(glow, out)
        out.putalpha(alpha)
    return _clean(out)


def main() -> None:
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    frame = _normalize_frame(Image.open(FRAME_SOURCE).convert("RGBA"))
    frame.save(TOOLS_OUT / "shared_frame_normal.png")

    buttons: dict[str, dict[str, Image.Image]] = {}
    for key in LABELS:
        icon = _icon_layer(key)
        text = _text_layer(key)
        icon.save(TOOLS_OUT / f"icon_{key}.png")
        text.save(TOOLS_OUT / f"text_{key}.png")
        normal = _clean(Image.alpha_composite(Image.alpha_composite(frame, icon), text))
        buttons[key] = {
            "normal": normal,
            "hover": _derive_state(normal, "hover"),
            "pressed": _derive_state(normal, "pressed"),
        }
        for state, image in buttons[key].items():
            image.save(TOOLS_OUT / f"hud_btn_{key}_{state}.png")

    canvas = Image.new("RGBA", (32 + 3 * 265, 34 + len(LABELS) * 112), (18, 24, 30, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 8), "single shared frame v3: normal / hover / pressed", fill=(230, 230, 230, 255))
    for row, key in enumerate(LABELS):
        y = 34 + row * 112
        draw.text((12, y + 4), key, fill=(210, 210, 210, 255))
        for col, state in enumerate(["normal", "hover", "pressed"]):
            canvas.alpha_composite(buttons[key][state], (90 + col * 265, y))
    canvas.save(PREVIEW)
    print(TOOLS_OUT)
    print(PREVIEW)


if __name__ == "__main__":
    main()
