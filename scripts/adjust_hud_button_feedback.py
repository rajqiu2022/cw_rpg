from __future__ import annotations

from collections import deque
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/raw/ui/field_hud/candidates"
GAME_OUT = ROOT / "game/art/ui/field_hud/v1"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/skill_frame_recomposed_buttons"
PREVIEW = ROOT / "tools/ui_field_hud_v1/skill_frame_recomposed_buttons_preview.png"
SIZE = (241, 93)

# One reusable textless frame. It is recolored below to the same cold blue-gray
# family as the accepted "武学" button, then reused by every button.
FRAME_SOURCE = RAW / "ui_field_hud_skill_frame_textless_candidate_b_v1.png"

BUTTON_SOURCES = {
    "inventory": ROOT / "tools/ui_field_hud_v1/closeup_redraw_candidate_a/hud_btn_inventory_redraw_a_normal.png",
    "equipment": RAW / "ui_field_hud_btn_equipment_feedback_fix_candidate_a_v1.png",
    "skill": RAW / "ui_field_hud_btn_skill_closeup_redraw_candidate_c_v1.png",
    "quest": RAW / "ui_field_hud_btn_quest_closeup_redraw_candidate_c_v1.png",
    "system": RAW / "ui_field_hud_btn_system_closeup_ref_candidate_c_v1.png",
}

LABELS = {
    "inventory": "背包",
    "equipment": "装备",
    "skill": "武学",
    "quest": "任务",
    "system": "系统",
}

ICON_CROPS = {
    "inventory": (24, 10, 108, 82),
    "equipment": (24, 10, 108, 82),
    "skill": (24, 10, 108, 82),
    "quest": (4, 3, 118, 88),
    "system": (24, 10, 108, 82),
}
ICON_CENTER = (64, 47)
ICON_MAX_SIZE = (58, 58)
TEXT_CENTER = (151, 48)
FONT_SIZE = 35


def _font(size: int) -> ImageFont.FreeTypeFont:
    for path in [
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
        Path("C:/Windows/Fonts/STKAITI.TTF"),
        Path("C:/Windows/Fonts/simkai.ttf"),
    ]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise FileNotFoundError("missing Chinese font")


def _clean(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low = arr[:, :, 3] <= 2
    arr[low, 0:4] = 0
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
        bg = (diff < 44) & (brightness > 205) & (alpha > 0)
    else:
        bg = (diff < 28) & (brightness < 42) & (alpha > 0)

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


def _crop_to_alpha(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    arr[_connected_background_mask(image), 0:4] = 0
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        raise ValueError("image has no visible alpha")
    pad = 8
    return Image.fromarray(arr, "RGBA").crop(
        (
            max(0, int(xs.min()) - pad),
            max(0, int(ys.min()) - pad),
            min(image.width, int(xs.max()) + pad + 1),
            min(image.height, int(ys.max()) + pad + 1),
        )
    )


def _normalize(image: Image.Image) -> Image.Image:
    crop = _crop_to_alpha(image)
    canvas = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    scale = min(SIZE[0] / crop.width, SIZE[1] / crop.height)
    resized = crop.resize(
        (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas.alpha_composite(resized, ((SIZE[0] - resized.width) // 2, (SIZE[1] - resized.height) // 2))
    return _clean(canvas)


def _load_shared_frame() -> Image.Image:
    if not FRAME_SOURCE.exists():
        raise FileNotFoundError(FRAME_SOURCE)
    frame = _normalize(Image.open(FRAME_SOURCE).convert("RGBA"))
    arr = np.array(frame).astype(np.float32)
    alpha = arr[:, :, 3]
    visible = alpha > 8
    gray = (
        arr[:, :, 0] * 0.299
        + arr[:, :, 1] * 0.587
        + arr[:, :, 2] * 0.114
    )
    if visible.any():
        lo, hi = np.percentile(gray[visible], [8, 96])
    else:
        lo, hi = 0, 255
    t = np.clip((gray - lo) / max(1.0, hi - lo), 0, 1)
    dark = np.array([23, 31, 36], dtype=np.float32)
    light = np.array([92, 105, 110], dtype=np.float32)
    recolored = dark + (light - dark) * (t[:, :, None] ** 0.85)
    # Keep the edge highlights slightly cooler and brighter.
    edge = cv2.Canny(alpha.astype("uint8"), 40, 120)
    edge = cv2.GaussianBlur(edge, (3, 3), 0).astype(np.float32) / 255.0
    recolored = recolored * (1 - edge[:, :, None] * 0.35) + np.array([128, 142, 146]) * edge[:, :, None] * 0.35
    arr[:, :, :3] = recolored
    out = _clean(Image.fromarray(np.clip(arr, 0, 255).astype("uint8"), "RGBA"))
    out.save(TOOLS_OUT / "shared_frame_normal.png")
    return out


def _trim_to_alpha(image: Image.Image) -> Image.Image:
    alpha = np.array(image.getchannel("A"))
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        raise ValueError("empty icon")
    return image.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))


def _extract_icon(key: str) -> Image.Image:
    source = BUTTON_SOURCES[key]
    if not source.exists():
        raise FileNotFoundError(source)
    button = _normalize(Image.open(source).convert("RGBA"))
    crop = button.crop(ICON_CROPS[key])
    arr = np.array(crop)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]

    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    saturation = hsv[:, :, 1]
    value = hsv[:, :, 2]
    # Icons are the bright or chroma-rich parts in the fixed icon slot. Avoid
    # low-saturation blue-gray pixels, because those belong to the old frame.
    mask = ((((saturation > 28) & (value > 45)) | (value > 126)) & (alpha > 8)).astype("uint8") * 255
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    base_mask = mask.copy()

    count, labels, stats, centroids = cv2.connectedComponentsWithStats(mask, 8)
    kept = np.zeros_like(mask)
    cx, cy = crop.width / 2, crop.height / 2
    for idx in range(1, count):
        area = stats[idx, cv2.CC_STAT_AREA]
        x = stats[idx, cv2.CC_STAT_LEFT]
        y = stats[idx, cv2.CC_STAT_TOP]
        w = stats[idx, cv2.CC_STAT_WIDTH]
        h = stats[idx, cv2.CC_STAT_HEIGHT]
        ccx, ccy = centroids[idx]
        near_icon_slot = abs(ccx - cx) < crop.width * 0.42 and abs(ccy - cy) < crop.height * 0.44
        plausible_icon_piece = area > 16 and w <= crop.width * 0.78 and h <= crop.height * 0.86
        if plausible_icon_piece and near_icon_slot:
            kept[labels == idx] = 255
    mask = kept if int(kept.sum()) > 32 * 255 else base_mask
    mask = cv2.GaussianBlur(mask, (3, 3), 0)

    icon_arr = arr.copy()
    icon_arr[:, :, 3] = np.minimum(alpha, mask)
    icon = _trim_to_alpha(_clean(Image.fromarray(icon_arr, "RGBA")))
    icon.thumbnail(ICON_MAX_SIZE, Image.Resampling.LANCZOS)

    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.alpha_composite(icon, (ICON_CENTER[0] - icon.width // 2, ICON_CENTER[1] - icon.height // 2))
    layer.save(TOOLS_OUT / f"icon_{key}.png")
    return layer


def _make_text_layer(key: str) -> Image.Image:
    label = LABELS[key]
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font = _font(FONT_SIZE)
    bbox = draw.textbbox((0, 0), label, font=font, stroke_width=1)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = TEXT_CENTER[0] - tw // 2
    y = TEXT_CENTER[1] - th // 2 - 4
    draw.text((x + 3, y + 4), label, font=font, fill=(4, 8, 9, 185), stroke_width=1, stroke_fill=(4, 8, 9, 150))
    draw.text((x, y), label, font=font, fill=(229, 224, 207, 255), stroke_width=1, stroke_fill=(82, 86, 82, 165))
    layer = _clean(layer)
    layer.save(TOOLS_OUT / f"text_{key}.png")
    return layer


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


def _compose_button(frame: Image.Image, key: str) -> dict[str, Image.Image]:
    normal = Image.alpha_composite(Image.alpha_composite(frame, _extract_icon(key)), _make_text_layer(key))
    outputs = {
        "normal": _clean(normal),
        "hover": _derive_state(normal, "hover"),
        "pressed": _derive_state(normal, "pressed"),
    }
    for state, image in outputs.items():
        filename = f"hud_btn_{key}_{state}.png"
        image.save(GAME_OUT / filename)
        image.save(TOOLS_OUT / filename)
    return outputs


def _make_preview(buttons: dict[str, dict[str, Image.Image]]) -> None:
    keys = ["inventory", "equipment", "skill", "quest", "system"]
    states = ["normal", "hover", "pressed"]
    canvas = Image.new("RGBA", (32 + len(states) * 265, 34 + len(keys) * 112), (18, 24, 30, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 8), "single frame + icon layer + text layer", fill=(230, 230, 230, 255))
    for row, key in enumerate(keys):
        y = 34 + row * 112
        draw.text((12, y + 4), key, fill=(210, 210, 210, 255))
        for col, state in enumerate(states):
            canvas.alpha_composite(buttons[key][state], (90 + col * 265, y))
    canvas.save(PREVIEW)


def main() -> None:
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    frame = _load_shared_frame()
    buttons = {key: _compose_button(frame, key) for key in LABELS}
    _make_preview(buttons)
    print(TOOLS_OUT)
    print(PREVIEW)


if __name__ == "__main__":
    main()
