from __future__ import annotations

from collections import deque
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/raw/ui/field_hud/layers"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/layered_v2_candidates"
PREVIEW = ROOT / "tools/ui_field_hud_v1/layered_v2_candidates_preview.png"
SIZE = (241, 93)

FRAME_SOURCE = RAW / "ui_field_hud_frame_layer_v2_candidate_a.png"

ICON_SOURCES = {
    "inventory": RAW / "ui_field_hud_icon_inventory_layer_v2_candidate_a.png",
    "equipment": RAW / "ui_field_hud_icon_equipment_layer_v2_candidate_a.png",
    "skill": RAW / "ui_field_hud_icon_skill_layer_v2_candidate_a.png",
    "quest": RAW / "ui_field_hud_icon_quest_layer_v2_candidate_a.png",
    "system": RAW / "ui_field_hud_icon_system_layer_v2_candidate_a.png",
}

TEXT_FULL_BUTTON_SOURCES = {
    "inventory": ROOT / "tools/ui_field_hud_v1/closeup_redraw_candidate_a/hud_btn_inventory_redraw_a_normal.png",
    "equipment": ROOT / "tools/ui_field_hud_v1/right_buttons_redraw_v1/hud_btn_equipment_normal.png",
    "skill": ROOT / "tools/ui_field_hud_v1/right_buttons_redraw_v1/hud_btn_skill_normal.png",
    "quest": ROOT / "tools/ui_field_hud_v1/right_buttons_redraw_v1/hud_btn_quest_normal.png",
}
SYSTEM_TEXT_SOURCE = RAW / "ui_field_hud_text_system_layer_v2_candidate_a.png"

TEXT_BOXES = {
    "inventory": (114, 17, 205, 70),
    "equipment": (105, 16, 211, 72),
    "skill": (118, 17, 208, 70),
    "quest": (106, 16, 214, 73),
}

ICON_CENTER = (64, 47)
ICON_MAX_SIZE = (52, 52)
TEXT_CENTER = (154, 49)
TEXT_MAX_SIZE = (88, 48)


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
    bg = ((diff < 36) & (brightness > 205) & (alpha > 0)) if bg_color.mean() > 160 else ((diff < 28) & (brightness < 42) & (alpha > 0))
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


def _fit_layer(image: Image.Image, max_size: tuple[int, int], center: tuple[int, int]) -> Image.Image:
    layer_img = _crop_to_alpha(image)
    layer_img.thumbnail(max_size, Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.alpha_composite(layer_img, (center[0] - layer_img.width // 2, center[1] - layer_img.height // 2))
    return _clean(layer)


def _normalize_frame(image: Image.Image) -> Image.Image:
    crop = _crop_to_alpha(image)
    canvas = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    scale = min(SIZE[0] / crop.width, SIZE[1] / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((SIZE[0] - resized.width) // 2, (SIZE[1] - resized.height) // 2))
    return _clean(canvas)


def _icon_layer(key: str) -> Image.Image:
    return _fit_layer(Image.open(ICON_SOURCES[key]).convert("RGBA"), ICON_MAX_SIZE, ICON_CENTER)


def _text_from_button(key: str) -> Image.Image:
    crop = Image.open(TEXT_FULL_BUTTON_SOURCES[key]).convert("RGBA").crop(TEXT_BOXES[key])
    arr = np.array(crop)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    saturation = hsv[:, :, 1]
    value = hsv[:, :, 2]
    mask = (((value > 132) & (saturation < 85)) | ((value > 112) & (saturation < 58))).astype("uint8") * 255
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    keep = np.zeros_like(mask)
    components = []
    for idx in range(1, count):
        area = stats[idx, cv2.CC_STAT_AREA]
        x = stats[idx, cv2.CC_STAT_LEFT]
        y = stats[idx, cv2.CC_STAT_TOP]
        w = stats[idx, cv2.CC_STAT_WIDTH]
        h = stats[idx, cv2.CC_STAT_HEIGHT]
        if area > 18 and h > 10 and w > 5:
            components.append((area, idx))
    for _, idx in sorted(components, reverse=True)[:3]:
        keep[labels == idx] = 255
    mask = keep if int(keep.sum()) > 32 * 255 else mask
    mask = cv2.GaussianBlur(mask, (3, 3), 0)
    arr[:, :, 3] = np.minimum(alpha, mask)
    return _fit_layer(Image.fromarray(arr, "RGBA"), TEXT_MAX_SIZE, TEXT_CENTER)


def _system_text_layer() -> Image.Image:
    for path in [
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
        Path("C:/Windows/Fonts/STKAITI.TTF"),
        Path("C:/Windows/Fonts/simkai.ttf"),
    ]:
        if path.exists():
            font = ImageFont.truetype(str(path), 62)
            break
    else:
        raise FileNotFoundError("missing Chinese font")

    text_canvas = Image.new("RGBA", (220, 110), (0, 0, 0, 0))
    draw = ImageDraw.Draw(text_canvas)
    label = "系统"
    bbox = draw.textbbox((0, 0), label, font=font, stroke_width=3)
    x = (text_canvas.width - (bbox[2] - bbox[0])) // 2
    y = (text_canvas.height - (bbox[3] - bbox[1])) // 2 - 8

    shadow = Image.new("RGBA", text_canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.text((x + 4, y + 6), label, font=font, fill=(0, 0, 0, 130), stroke_width=2, stroke_fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(1.0))
    text_canvas = Image.alpha_composite(text_canvas, shadow)

    draw = ImageDraw.Draw(text_canvas)
    draw.text((x, y), label, font=font, fill=(246, 237, 206, 255), stroke_width=2, stroke_fill=(66, 59, 49, 175))
    draw.text((x - 1, y - 1), label, font=font, fill=(255, 249, 226, 105), stroke_width=0)
    return _fit_layer(text_canvas, TEXT_MAX_SIZE, TEXT_CENTER)


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
    frame.save(TOOLS_OUT / "shared_frame_candidate_a.png")

    buttons: dict[str, dict[str, Image.Image]] = {}
    for key in ["inventory", "equipment", "skill", "quest", "system"]:
        icon = _icon_layer(key)
        text = _system_text_layer() if key == "system" else _text_from_button(key)
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

    canvas = Image.new("RGBA", (32 + 3 * 265, 34 + 5 * 112), (18, 24, 30, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 8), "layered v2 candidates: normal / hover / pressed", fill=(230, 230, 230, 255))
    for row, key in enumerate(buttons):
        y = 34 + row * 112
        draw.text((12, y + 4), key, fill=(210, 210, 210, 255))
        for col, state in enumerate(["normal", "hover", "pressed"]):
            canvas.alpha_composite(buttons[key][state], (90 + col * 265, y))
    canvas.save(PREVIEW)
    print(TOOLS_OUT)
    print(PREVIEW)


if __name__ == "__main__":
    main()
