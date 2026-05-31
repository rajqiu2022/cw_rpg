from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/raw/ui/field_hud/candidates"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/right_buttons_redraw_v1"
GAME_OUT = ROOT / "game/art/ui/field_hud/v1"
PREVIEW = ROOT / "tools/ui_field_hud_v1/right_buttons_redraw_v1_preview.png"
REFERENCE = ROOT / "assets/raw/ui/field_hud/reference/hud_right_buttons_design_ref.png"
SIZE = (241, 93)


SELECTIONS = {
    "inventory": ROOT / "tools/ui_field_hud_v1/closeup_redraw_candidate_a/hud_btn_inventory_redraw_a_normal.png",
    "equipment": RAW / "ui_field_hud_btn_equipment_closeup_redraw_candidate_a_v1.png",
    "skill": RAW / "ui_field_hud_btn_skill_closeup_redraw_candidate_c_v1.png",
    "quest": RAW / "ui_field_hud_btn_quest_closeup_redraw_candidate_c_v1.png",
}


def _connected_background_mask(image: Image.Image) -> np.ndarray:
    arr = np.array(image.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3]
    h, w = alpha.shape
    corners = np.array([rgb[0, 0], rgb[0, w - 1], rgb[h - 1, 0], rgb[h - 1, w - 1]])
    bg_color = np.median(corners, axis=0)
    diff = np.abs(rgb - bg_color).max(axis=2)
    brightness = rgb.mean(axis=2)

    # White or black single-color generation backgrounds are removed only when
    # connected to the image edge, so dark button interiors are preserved.
    if bg_color.mean() > 160:
        bg = (diff < 36) & (brightness > 210) & (alpha > 0)
    else:
        bg = (diff < 26) & (brightness < 36) & (alpha > 0)

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
    bg = _connected_background_mask(image)
    arr[bg, 0:4] = 0
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        raise ValueError("image has no visible alpha")
    pad = 8
    box = (
        max(0, int(xs.min()) - pad),
        max(0, int(ys.min()) - pad),
        min(image.width, int(xs.max()) + pad + 1),
        min(image.height, int(ys.max()) + pad + 1),
    )
    return Image.fromarray(arr, "RGBA").crop(box)


def _normalize(image: Image.Image) -> Image.Image:
    crop = _crop_to_alpha(image)
    canvas = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    scale = min(SIZE[0] / crop.width, SIZE[1] / crop.height)
    resized = crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))), Image.Resampling.LANCZOS)
    x = (SIZE[0] - resized.width) // 2
    y = (SIZE[1] - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return _clean(canvas)


def _clean(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low = arr[:, :, 3] <= 2
    arr[low, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _state(base: Image.Image, state: str) -> Image.Image:
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


def _write_button(key: str, image: Image.Image) -> dict[str, Image.Image]:
    normal = _normalize(image)
    outputs = {
        "normal": normal,
        "hover": _state(normal, "hover"),
        "pressed": _state(normal, "pressed"),
    }
    for state, out in outputs.items():
        filename = f"hud_btn_{key}_{state}.png"
        out.save(TOOLS_OUT / filename)
        out.save(GAME_OUT / filename)
    return outputs


def _make_preview(all_buttons: dict[str, dict[str, Image.Image]]) -> None:
    ref = Image.open(REFERENCE).convert("RGBA")
    ref.thumbnail((250, 360), Image.Resampling.LANCZOS)
    width = 250 + 32 + SIZE[0] * 3 + 56
    height = max(ref.height + 36, len(all_buttons) * (SIZE[1] + 16) + 60)
    canvas = Image.new("RGBA", (width, height), (18, 24, 30, 255))
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 10), "Reference", fill=(230, 230, 230, 255))
    canvas.alpha_composite(ref, (12, 32))
    x0 = 282
    draw.text((x0, 10), "normal / hover / pressed", fill=(230, 230, 230, 255))
    labels = {"inventory": "inventory", "equipment": "equipment", "skill": "skill", "quest": "quest"}
    for row, key in enumerate(labels):
        y = 34 + row * (SIZE[1] + 16)
        draw.text((x0, y - 14), labels[key], fill=(210, 210, 210, 255))
        for col, state in enumerate(("normal", "hover", "pressed")):
            canvas.alpha_composite(all_buttons[key][state], (x0 + col * (SIZE[0] + 24), y))
    canvas.save(PREVIEW)


def main() -> None:
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    GAME_OUT.mkdir(parents=True, exist_ok=True)
    all_buttons: dict[str, dict[str, Image.Image]] = {}
    for key, path in SELECTIONS.items():
        if not path.exists():
            raise FileNotFoundError(path)
        all_buttons[key] = _write_button(key, Image.open(path).convert("RGBA"))
    _make_preview(all_buttons)
    print(TOOLS_OUT)
    print(GAME_OUT)
    print(PREVIEW)


if __name__ == "__main__":
    main()
