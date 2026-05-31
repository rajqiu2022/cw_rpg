from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "assets/raw/ui/field_hud/v1"
OUT_DIR = ROOT / "game/art/ui/field_hud/v1"
PREVIEW_DIR = ROOT / "tools/ui_field_hud_v1"
PREVIEW_BG = ROOT / "game/art/backgrounds/bg_linxi_tutorial_full.png"

PANEL_SPECS = {
    "player_panel": ("ui_field_hud_player_panel_v1.png", (650, 188)),
    "gold_panel": ("ui_field_hud_gold_panel_v1.png", (210, 73)),
    "scene_title": ("ui_field_hud_scene_title_v1.png", (543, 63)),
    "quest_panel": ("ui_field_hud_quest_panel_v1.png", (559, 360)),
    "bottom_bar": ("ui_field_hud_bottom_bar_v1.png", (1920, 143)),
}

BUTTON_SPECS = {
    "inventory": ("ui_field_hud_btn_inventory_v1.png", "背包"),
    "equipment": ("ui_field_hud_btn_equipment_v1.png", "装备"),
    "skill": ("ui_field_hud_btn_skill_v1.png", "武学"),
    "quest": ("ui_field_hud_btn_quest_v1.png", "任务"),
    "system": ("ui_field_hud_btn_system_v1.png", "系统"),
}

BUTTON_SIZE = (241, 93)


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/simhei.ttf"),
        Path("C:/Windows/Fonts/STXINGKA.TTF"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def _clean_transparent_pixels(image: Image.Image, alpha_threshold: int = 3) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low = arr[:, :, 3] <= alpha_threshold
    arr[low, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _largest_alpha_bbox(image: Image.Image, threshold: int = 24, pad: int = 8) -> tuple[int, int, int, int]:
    alpha = np.array(image.convert("RGBA"))[:, :, 3]
    mask = alpha > threshold
    h, w = mask.shape
    seen = np.zeros(mask.shape, dtype=bool)
    best: tuple[int, int, int, int, int] | None = None

    for y in range(h):
        xs = np.where(mask[y] & ~seen[y])[0]
        for x0 in xs:
            if seen[y, x0] or not mask[y, x0]:
                continue
            q: deque[tuple[int, int]] = deque([(x0, y)])
            seen[y, x0] = True
            min_x = max_x = x0
            min_y = max_y = y
            count = 0
            while q:
                x, cy = q.popleft()
                count += 1
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in ((x + 1, cy), (x - 1, cy), (x, cy + 1), (x, cy - 1)):
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if seen[ny, nx] or not mask[ny, nx]:
                        continue
                    seen[ny, nx] = True
                    q.append((nx, ny))
            if best is None or count > best[0]:
                best = (count, min_x, min_y, max_x + 1, max_y + 1)

    if best is None:
        return (0, 0, image.width, image.height)
    _, left, top, right, bottom = best
    return (
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )


def _fit_on_canvas(image: Image.Image, size: tuple[int, int], threshold: int = 24) -> Image.Image:
    crop = image.convert("RGBA").crop(_largest_alpha_bbox(image, threshold=threshold, pad=10))
    # UI controls are normalized to the exact runtime rectangle. The source image
    # is an AI master, not a photograph, so controlled non-uniform scaling is
    # preferable to leaving large transparent margins that make Godot placement
    # look wrong.
    return _clean_transparent_pixels(crop.resize(size, Image.LANCZOS))


def _derive_button_state(base: Image.Image, state: str) -> Image.Image:
    alpha = base.getchannel("A")
    rgb = base.convert("RGB")
    if state == "hover":
        rgb = ImageEnhance.Brightness(rgb).enhance(1.18)
        rgb = ImageEnhance.Color(rgb).enhance(1.08)
    elif state == "pressed":
        rgb = ImageEnhance.Brightness(rgb).enhance(0.78)
        rgb = ImageEnhance.Color(rgb).enhance(0.95)
    result = rgb.convert("RGBA")
    result.putalpha(alpha)
    if state == "hover":
        glow = Image.new("RGBA", result.size, (74, 230, 220, 0))
        glow_alpha = alpha.filter(ImageFilter.GaussianBlur(5)).point(lambda a: int(a * 0.30))
        glow.putalpha(glow_alpha)
        result = Image.alpha_composite(glow, result)
        result.putalpha(alpha)
    return _clean_transparent_pixels(result)


def _render_button_label(image: Image.Image, label: str) -> Image.Image:
    result = image.copy()
    draw = ImageDraw.Draw(result, "RGBA")
    # Clear the AI-generated text area while preserving left icon and ornamental frame.
    draw.rounded_rectangle((103, 25, 213, 69), radius=13, fill=(14, 35, 52, 225))
    font = _font(30)
    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = 158 - tw / 2
    y = 47 - th / 2 - 3
    draw.text((x + 2, y + 2), label, font=font, fill=(0, 0, 0, 180))
    draw.text((x, y), label, font=font, fill=(232, 246, 250, 255))
    return result


def process_panels() -> None:
    for key, (filename, size) in PANEL_SPECS.items():
        src = RAW_DIR / filename
        if not src.exists():
            raise SystemExit(f"missing source: {src}")
        threshold = 64 if key == "bottom_bar" else 24
        output = _fit_on_canvas(Image.open(src), size, threshold=threshold)
        output.save(OUT_DIR / f"hud_{key}.png")


def process_buttons() -> None:
    for key, (filename, label) in BUTTON_SPECS.items():
        src = RAW_DIR / filename
        if not src.exists():
            raise SystemExit(f"missing source: {src}")
        normal = _render_button_label(_fit_on_canvas(Image.open(src), BUTTON_SIZE, threshold=24), label)
        normal.save(OUT_DIR / f"hud_btn_{key}_normal.png")
        _derive_button_state(normal, "hover").save(OUT_DIR / f"hud_btn_{key}_hover.png")
        _derive_button_state(normal, "pressed").save(OUT_DIR / f"hud_btn_{key}_pressed.png")


def make_preview() -> None:
    if PREVIEW_BG.exists():
        preview = Image.open(PREVIEW_BG).convert("RGBA").resize((1920, 1080), Image.LANCZOS)
    else:
        preview = Image.new("RGBA", (1920, 1080), (30, 40, 48, 255))
    placements = {
        "hud_player_panel.png": (0, 0),
        "hud_gold_panel.png": (27, 158),
        "hud_scene_title.png": (1262, 21),
        "hud_quest_panel.png": (1331, 677),
        "hud_bottom_bar.png": (0, 937),
        "hud_btn_inventory_normal.png": (1656, 93),
        "hud_btn_equipment_normal.png": (1656, 179),
        "hud_btn_skill_normal.png": (1656, 266),
        "hud_btn_quest_normal.png": (1656, 352),
        "hud_btn_system_normal.png": (1656, 439),
    }
    for filename, pos in placements.items():
        piece = Image.open(OUT_DIR / filename).convert("RGBA")
        preview.alpha_composite(piece, pos)
    preview.save(PREVIEW_DIR / "field_hud_formal_v1_preview.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    process_panels()
    process_buttons()
    make_preview()
    print(f"[field-hud] wrote {OUT_DIR}")
    print(f"[field-hud] preview {PREVIEW_DIR / 'field_hud_formal_v1_preview.png'}")


if __name__ == "__main__":
    main()
