from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / "game/art/ui/button/btn_menu_frame_normal.png"
OUT = ROOT / "tools/ui_field_hud_v1/system_button_mainmenu_style_candidate.png"
FONT_CANDIDATES = [
    Path("C:/Windows/Fonts/STXINGKA.TTF"),
    Path("C:/Windows/Fonts/FZSTK.TTF"),
    Path("C:/Windows/Fonts/STKAITI.TTF"),
    Path("C:/Windows/Fonts/simkai.ttf"),
]


def _font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise FileNotFoundError("missing Chinese font")


def _clean_old_text(image: Image.Image) -> Image.Image:
    if BASE.name == "btn_menu_frame_normal.png":
        return image.convert("RGBA")

    img = image.convert("RGBA")
    arr = np.array(img).astype(np.float32)

    # Only touch the central plaque area. The surrounding metal frame and gems are
    # preserved from the approved main-menu v5 button.
    x1, y1, x2, y2 = 138, 28, 376, 98
    region = arr[y1:y2, x1:x2]
    rgb = region[:, :, :3]
    alpha = region[:, :, 3]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    gold = (rgb[:, :, 0] > 120) & (rgb[:, :, 1] > 90) & (rgb[:, :, 2] < 125) & (chroma > 35) & (alpha > 20)

    # Expand the mask enough to remove bright edges and shadow residue.
    mask_img = Image.fromarray((gold * 255).astype("uint8"), "L").filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(1.4))
    mask = np.array(mask_img).astype(np.float32) / 255.0

    # Replace glyph pixels with a blurred copy of the same plaque, preserving its
    # teal texture rather than drawing a flat rectangle.
    blurred = np.array(Image.fromarray(region.astype("uint8"), "RGBA").filter(ImageFilter.GaussianBlur(12))).astype(np.float32)
    region[:, :, :3] = region[:, :, :3] * (1.0 - mask[:, :, None]) + blurred[:, :, :3] * mask[:, :, None]
    arr[y1:y2, x1:x2] = region
    return Image.fromarray(np.clip(arr, 0, 255).astype("uint8"), "RGBA")


def _gold_text_layer(size: tuple[int, int], text: str) -> Image.Image:
    font = _font(66)
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (size[0] - tw) // 2
    y = 61 - th // 2 - 4
    draw.text((x, y), text, font=font, fill=255)

    # Slightly thicken the strokes to approach the approved main-menu art.
    body = mask.filter(ImageFilter.MaxFilter(3))
    edge = body.filter(ImageFilter.MaxFilter(7))

    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (32, 17, 4, 0))
    shadow_mask = body.filter(ImageFilter.GaussianBlur(2.2))
    shadow.putalpha(shadow_mask.point(lambda a: int(a * 0.72)))
    layer.alpha_composite(shadow, (4, 5))

    stroke = Image.new("RGBA", size, (94, 44, 12, 0))
    stroke.putalpha(edge.point(lambda a: int(a * 0.72)))
    layer.alpha_composite(stroke)

    grad = Image.new("RGBA", size, (0, 0, 0, 0))
    grad_arr = np.array(grad)
    body_arr = np.array(body)
    rng = np.random.default_rng(7)
    for yy in range(size[1]):
        t = yy / max(1, size[1] - 1)
        # Top highlight, warm gold mid, darker lower edge.
        if t < 0.45:
            k = t / 0.45
            color = np.array([255, 242, 154]) * (1 - k) + np.array([230, 169, 62]) * k
        else:
            k = (t - 0.45) / 0.55
            color = np.array([230, 169, 62]) * (1 - k) + np.array([142, 77, 24]) * k
        noise = rng.normal(0, 5, size[0])
        grad_arr[yy, :, :3] = np.clip(color + noise[:, None], 0, 255)
    grad_arr[:, :, 3] = body_arr
    layer.alpha_composite(Image.fromarray(grad_arr.astype("uint8"), "RGBA"))

    highlight = Image.new("RGBA", size, (255, 252, 190, 0))
    top_mask = body.point(lambda a: int(a * 0.36)).filter(ImageFilter.GaussianBlur(0.4))
    highlight.putalpha(top_mask)
    layer.alpha_composite(highlight, (0, -2))
    return layer


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    base = _clean_old_text(Image.open(BASE))
    text = _gold_text_layer(base.size, "系统")
    result = Image.alpha_composite(base, text)
    result.save(OUT)
    print(OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
