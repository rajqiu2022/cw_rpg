from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/raw/ui/field_hud/candidates"
GAME_OUT = ROOT / "game/art/ui/field_hud/v1"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/primary_ui_redraw_v1"
PREVIEW = ROOT / "tools/ui_field_hud_v1/primary_ui_redraw_v1_preview.png"
PREVIEW_BG = ROOT / "game/art/backgrounds/bg_linxi_tutorial_full.png"

PLAYER_SRC = RAW / "ui_field_hud_player_panel_closeup_candidate_a_v1.png"
BOTTOM_SRC = RAW / "ui_field_hud_bottom_bar_closeup_candidate_a_v1.png"
SYSTEM_SRC = RAW / "ui_field_hud_btn_system_closeup_ref_candidate_a_v1.png"

PLAYER_SIZE = (650, 188)
BOTTOM_SIZE = (1920, 143)
BUTTON_SIZE = (241, 93)


def _clean(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low = arr[:, :, 3] <= 2
    arr[low, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _connected_bg_mask(image: Image.Image) -> np.ndarray:
    arr = np.array(image.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3]
    h, w = alpha.shape
    corners = np.array([rgb[0, 0], rgb[0, w - 1], rgb[h - 1, 0], rgb[h - 1, w - 1]])
    bg_color = np.median(corners, axis=0)
    diff = np.abs(rgb - bg_color).max(axis=2)
    brightness = rgb.mean(axis=2)
    if bg_color.mean() > 160:
        bg = (diff < 36) & (brightness > 210) & (alpha > 0)
    else:
        bg = (diff < 30) & (brightness < 42) & (alpha > 0)

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


def _crop_visible(image: Image.Image, pad: int = 8) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    arr[_connected_bg_mask(image), 0:4] = 0
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        raise ValueError("no visible pixels")
    box = (
        max(0, int(xs.min()) - pad),
        max(0, int(ys.min()) - pad),
        min(image.width, int(xs.max()) + pad + 1),
        min(image.height, int(ys.max()) + pad + 1),
    )
    return Image.fromarray(arr, "RGBA").crop(box)


def _normalize_fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    crop = _crop_visible(image)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    scale = min(size[0] / crop.width, size[1] / crop.height)
    resized = crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return _clean(canvas)


def _normalize_fill(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    crop = _crop_visible(image)
    return _clean(crop.resize(size, Image.Resampling.LANCZOS))


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
        glow = Image.new("RGBA", BUTTON_SIZE, (90, 145, 155, 0))
        glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.22)))
        out = Image.alpha_composite(glow, out)
        out.putalpha(alpha)
    return _clean(out)


def _font(size: int) -> ImageFont.FreeTypeFont:
    for path in [
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
        Path("C:/Windows/Fonts/STKAITI.TTF"),
        Path("C:/Windows/Fonts/simkai.ttf"),
    ]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise FileNotFoundError("missing Chinese font")


def _replace_system_text(button: Image.Image) -> Image.Image:
    base = button.convert("RGBA")
    arr = np.array(base).astype(np.float32)
    region_box = (86, 24, 214, 74)
    x1, y1, x2, y2 = region_box
    region = arr[y1:y2, x1:x2]
    rgb = region[:, :, :3]
    alpha = region[:, :, 3]
    brightness = rgb.mean(axis=2)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    text_mask = (brightness > 105) & (chroma < 90) & (alpha > 20)
    mask_img = Image.fromarray((text_mask * 255).astype("uint8"), "L").filter(ImageFilter.MaxFilter(11)).filter(ImageFilter.GaussianBlur(1.2))
    mask = np.array(mask_img).astype(np.float32) / 255.0
    blurred = np.array(Image.fromarray(region.astype("uint8"), "RGBA").filter(ImageFilter.GaussianBlur(10))).astype(np.float32)
    region[:, :, :3] = region[:, :, :3] * (1 - mask[:, :, None]) + blurred[:, :, :3] * mask[:, :, None]
    arr[y1:y2, x1:x2] = region
    cleaned = Image.fromarray(np.clip(arr, 0, 255).astype("uint8"), "RGBA")

    layer = Image.new("RGBA", BUTTON_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font = _font(39)
    text = "系统"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = 152 - tw // 2
    y = 47 - th // 2 - 3
    draw.text((x + 2, y + 3), text, font=font, fill=(4, 8, 10, 205), stroke_width=1, stroke_fill=(4, 8, 10, 190))
    draw.text((x, y), text, font=font, fill=(232, 228, 214, 255), stroke_width=1, stroke_fill=(70, 75, 74, 170))
    return _clean(Image.alpha_composite(cleaned, layer))


def _write_button(key: str, normal: Image.Image) -> None:
    outputs = {
        "normal": normal,
        "hover": _state(normal, "hover"),
        "pressed": _state(normal, "pressed"),
    }
    for state, image in outputs.items():
        filename = f"hud_btn_{key}_{state}.png"
        image.save(TOOLS_OUT / filename)
        image.save(GAME_OUT / filename)


def _make_preview(player: Image.Image, bottom: Image.Image, system: Image.Image) -> None:
    if PREVIEW_BG.exists():
        canvas = Image.open(PREVIEW_BG).convert("RGBA").resize((1920, 1080), Image.Resampling.LANCZOS)
    else:
        canvas = Image.new("RGBA", (1920, 1080), (30, 40, 48, 255))
    canvas.alpha_composite(player, (0, 0))
    canvas.alpha_composite(bottom, (0, 937))
    canvas.alpha_composite(system, (1656, 439))
    canvas.save(PREVIEW)


def main() -> None:
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    GAME_OUT.mkdir(parents=True, exist_ok=True)
    player = _normalize_fit(Image.open(PLAYER_SRC).convert("RGBA"), PLAYER_SIZE)
    bottom = _normalize_fill(Image.open(BOTTOM_SRC).convert("RGBA"), BOTTOM_SIZE)
    system = _replace_system_text(_normalize_fit(Image.open(SYSTEM_SRC).convert("RGBA"), BUTTON_SIZE))

    player.save(TOOLS_OUT / "hud_player_panel.png")
    player.save(GAME_OUT / "hud_player_panel.png")
    bottom.save(TOOLS_OUT / "hud_bottom_bar.png")
    bottom.save(GAME_OUT / "hud_bottom_bar.png")
    _write_button("system", system)
    _make_preview(player, bottom, system)
    print(TOOLS_OUT)
    print(PREVIEW)


if __name__ == "__main__":
    main()
