"""
gen_hud_buttons_inv_equip.py — 从 system_normal 提取底框，生成背包/装备按钮三态

流程（按 producing-ui-button-states skill）：
1. 从 specimen (system_normal) 提取底框（去文字去图标）
2. 渲染文字层（华文行楷 "背包" "装备"）
3. 从现有 equipment_normal 提取图标层
4. 合成 normal → 程序派生 hover/pressed
5. 输出预览大图到 tools/
"""

from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SPECIMEN = ROOT / "tools/ui_field_hud_v1/feedback_adjusted_buttons/hud_btn_system_normal.png"
EQUIP_SRC = ROOT / "tools/ui_field_hud_v1/feedback_adjusted_buttons/hud_btn_equipment_normal.png"
SKILL_SRC = ROOT / "game/art/ui/field_hud/v1/hud_btn_skill_normal.png"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/inv_equip_preview"
GAME_OUT = ROOT / "game/art/ui/field_hud/v1"
PREVIEW = ROOT / "tools/ui_field_hud_v1/inv_equip_preview.png"
SIZE = (241, 93)

LABELS = {"inventory": "背包", "equipment": "装备"}
ICON_CENTER = (64, 47)
ICON_MAX = (56, 56)
TEXT_CENTER = (151, 48)
FONT_SIZE = 35


def _font(size: int) -> ImageFont.FreeTypeFont:
    for p in ["C:/Windows/Fonts/STXINGKA.TTF", "C:/Windows/Fonts/STKAITI.TTF", "C:/Windows/Fonts/simkai.ttf"]:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    raise FileNotFoundError("missing Chinese font")


def _clean(img: Image.Image) -> Image.Image:
    a = np.array(img)
    a[a[:, :, 3] <= 2, :] = 0
    return Image.fromarray(a, "RGBA")


def _extract_frame(specimen: Image.Image) -> Image.Image:
    """Extract textless/iconless base frame from specimen."""
    arr = np.array(specimen.convert("RGBA")).astype(np.float32)
    h, w = arr.shape[:2]
    gray = arr[:, :, 0] * 0.299 + arr[:, :, 1] * 0.587 + arr[:, :, 2] * 0.114

    # Mask: keep dark/medium pixels (the frame), exclude bright text/icon areas
    alpha = arr[:, :, 3]
    frame_mask = (gray < 130) & (alpha > 40)

    # Find the largest rectangular frame region
    ys, xs = np.where(frame_mask)
    if len(xs) > 0:
        min_x, max_x = int(xs.min()), int(xs.max())
        min_y, max_y = int(ys.min()), int(ys.max())
        # Expand slightly to capture the full frame
        min_x = max(0, min_x - 4)
        min_y = max(0, min_y - 4)
        max_x = min(w - 1, max_x + 4)
        max_y = min(h - 1, max_y + 4)

        # Inpaint text/icon areas with nearby frame pixels
        text_icon_mask = ~frame_mask & (alpha > 10)
        ys2, xs2 = np.where(text_icon_mask)
        if len(xs2) > 0:
            # Simple inpainting: replace bright pixels with median of border pixels
            border_mask = np.zeros_like(text_icon_mask, dtype=bool)
            border_mask[min_y:max_y+1, min_x:max_x+1] = True
            border_mask[frame_mask] = False
            border_mask &= text_icon_mask

            for y, x in zip(ys2, xs2):
                # Sample nearby dark pixels
                samples = []
                for dy in [-5, -3, 0, 3, 5]:
                    for dx in [-5, -3, 0, 3, 5]:
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < w and frame_mask[ny, nx]:
                            samples.append(arr[ny, nx, :3])
                if samples:
                    arr[y, x, :3] = np.mean(samples, axis=0)

    # Recolor to match cold steel blue-gray tone
    dark = np.array([30, 42, 52], dtype=np.float32)
    light = np.array([82, 100, 112], dtype=np.float32)
    t = np.clip((gray - 50) / max(1.0, 240 - 50), 0, 1)
    recolored = dark + (light - dark) * t[:, :, None]
    arr[:, :, :3] = np.clip(recolored, 0, 255)

    result = _clean(Image.fromarray(arr.astype("uint8"), "RGBA"))
    result.save(TOOLS_OUT / "base_frame.png")
    return result


def _make_text_layer(label: str) -> Image.Image:
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    font = _font(FONT_SIZE)
    bbox = draw.textbbox((0, 0), label, font=font, stroke_width=1)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = TEXT_CENTER[0] - tw // 2
    y = TEXT_CENTER[1] - th // 2 - 4
    # Shadow
    draw.text((x + 3, y + 4), label, font=font, fill=(4, 8, 9, 185))
    # Main text
    draw.text((x, y), label, font=font, fill=(229, 224, 207, 255), stroke_width=1, stroke_fill=(82, 86, 82, 165))
    return _clean(layer)


def _extract_icon(src_path: Path) -> Image.Image:
    """Extract icon from a source button by isolating bright/saturated pixels in left region."""
    if not src_path.exists():
        # Fallback: create a simple icon placeholder
        return _make_placeholder_icon()

    img = Image.open(src_path).convert("RGBA")
    img = img.resize(SIZE, Image.LANCZOS)
    arr = np.array(img)

    # Focus on left icon area
    icon_area = arr[10:82, 24:108]
    alpha = icon_area[:, :, 3]
    rgb = icon_area[:, :, :3]

    # Keep bright or colorful pixels (icon), discard dark/desaturated (frame)
    import cv2
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    sat = hsv[:, :, 1]
    val = hsv[:, :, 2]
    mask = (((sat > 25) & (val > 40)) | (val > 120)) & (alpha > 10)
    mask = mask.astype("uint8") * 255
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8))

    result = np.zeros_like(icon_area)
    result[:, :, :3] = rgb
    result[:, :, 3] = np.minimum(alpha, mask)

    icon = _clean(Image.fromarray(result, "RGBA"))
    # Trim to content
    a = np.array(icon)[:, :, 3]
    ys, xs = np.where(a > 8)
    if len(xs) > 0:
        icon = icon.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))

    icon.thumbnail(ICON_MAX, Image.LANCZOS)
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.alpha_composite(icon, (ICON_CENTER[0] - icon.width // 2, ICON_CENTER[1] - icon.height // 2))
    return layer


def _make_placeholder_icon() -> Image.Image:
    """Fallback: simple geometric icon."""
    icon = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.rectangle([4, 4, 44, 44], outline=(160, 180, 190, 220), width=2)
    draw.rectangle([14, 14, 34, 34], fill=(140, 165, 175, 120))
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    layer.alpha_composite(icon, (ICON_CENTER[0] - 24, ICON_CENTER[1] - 24))
    return layer


def _derive_state(normal: Image.Image, state: str) -> Image.Image:
    alpha = normal.getchannel("A")
    rgb = normal.convert("RGB")
    if state == "hover":
        rgb = ImageEnhance.Brightness(rgb).enhance(1.14)
        rgb = ImageEnhance.Color(rgb).enhance(1.06)
    elif state == "pressed":
        rgb = ImageEnhance.Brightness(rgb).enhance(0.74)
        rgb = ImageEnhance.Color(rgb).enhance(0.93)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)

    if state == "hover":
        glow = Image.new("RGBA", SIZE, (80, 135, 150, 0))
        glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.24)))
        out = Image.alpha_composite(glow, out)
        out.putalpha(alpha)

    return _clean(out)


def _compose(frame: Image.Image, key: str, icon_path: Path, label: str) -> dict:
    icon = _extract_icon(icon_path)
    icon.save(TOOLS_OUT / f"icon_{key}.png")

    text = _make_text_layer(label)
    text.save(TOOLS_OUT / f"text_{key}.png")

    normal = Image.alpha_composite(Image.alpha_composite(frame, icon), text)
    result = {
        "normal": _clean(normal),
        "hover": _derive_state(normal, "hover"),
        "pressed": _derive_state(normal, "pressed"),
    }
    for state, img in result.items():
        fp = GAME_OUT / f"hud_btn_{key}_{state}.png"
        img.save(fp)
        img.save(TOOLS_OUT / f"hud_btn_{key}_{state}.png")
    return result


def _make_preview(buttons: dict[str, dict[str, Image.Image]]) -> None:
    keys = ["inventory", "equipment"]
    states = ["normal", "hover", "pressed"]
    cw = SIZE[0] + 24
    ch = SIZE[1] + 16
    left_margin = 20
    canvas = Image.new("RGBA", (left_margin + len(states) * cw + 40, 16 + len(keys) * ch + 16), (20, 26, 32, 255))
    for row, key in enumerate(keys):
        y = 16 + row * ch
        for col, state in enumerate(states):
            canvas.alpha_composite(buttons[key][state], (left_margin + col * cw, y))
    canvas.save(PREVIEW)
    print(f"Preview: {PREVIEW}")


def main():
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    GAME_OUT.mkdir(parents=True, exist_ok=True)

    print(f"Specimen: {SPECIMEN}")
    specimen = Image.open(SPECIMEN).convert("RGBA").resize(SIZE, Image.LANCZOS)

    print("Extracting base frame...")
    frame = _extract_frame(specimen)

    buttons = {}
    icon_sources = {
        "inventory": SKILL_SRC,   # reuse skill icon as inventory placeholder
        "equipment": EQUIP_SRC,
    }
    for key, label in LABELS.items():
        print(f"Composing {key} ({label})...")
        buttons[key] = _compose(frame, key, icon_sources[key], label)

    _make_preview(buttons)
    print(f"Output: {TOOLS_OUT}")
    print(f"Game assets: {GAME_OUT}")


if __name__ == "__main__":
    main()
