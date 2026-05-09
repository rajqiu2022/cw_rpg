from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
import os

OUT_DIR = "game/art/ui/main_menu/buttons/text/v1"
RAW_DIR = "assets/raw/ui/button/main_menu/text/v1"

TASKS = [
    ("新游戏", "ui_btn_main_text_new_game_v1.png", "btn_menu_text_new_game_v1.png"),
    ("读取存档", "ui_btn_main_text_load_v1.png", "btn_menu_text_load_v1.png"),
    ("离开", "ui_btn_main_text_quit_v1.png", "btn_menu_text_quit_v1.png"),
]


def pick_font() -> str:
    cands = [
        r"C:/Windows/Fonts/STZHONGS.TTF",
        r"C:/Windows/Fonts/simhei.ttf",
        r"C:/Windows/Fonts/msyhbd.ttc",
    ]
    for p in cands:
        if os.path.exists(p):
            return p
    raise FileNotFoundError("No suitable Chinese font found.")


def fit_font(draw: ImageDraw.ImageDraw, text: str, font_path: str, max_w: int, max_h: int) -> tuple:
    size = 86
    while size >= 34:
        font = ImageFont.truetype(font_path, size)
        stroke = max(2, size // 18)
        box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke)
        tw, th = box[2] - box[0], box[3] - box[1]
        if tw <= max_w and th <= max_h:
            return font, stroke, box
        size -= 2
    font = ImageFont.truetype(font_path, 34)
    stroke = 2
    box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke)
    return font, stroke, box


def build_texture_fill(raw_img: Image.Image, w: int, h: int) -> np.ndarray:
    arr = np.array(raw_img.convert("RGB").resize((w, h), Image.Resampling.LANCZOS)).astype(np.float32)
    lum = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    # 将旧图里的裂纹明暗作为纹理权重
    tex = np.clip((255.0 - lum) / 255.0, 0.0, 1.0)
    return tex


def render_one(text: str, raw_name: str, out_name: str, font_path: str) -> None:
    w, h = 560, 170
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    font, stroke, box = fit_font(draw, text, font_path, max_w=430, max_h=92)
    tw, th = box[2] - box[0], box[3] - box[1]
    x = (w - tw) // 2 - box[0]
    y = (h - th) // 2 - box[1]

    # 字形mask（用于裁切，彻底避免白底块）
    mask_img = Image.new("L", (w, h), 0)
    mask_draw = ImageDraw.Draw(mask_img)
    mask_draw.text((x, y), text, font=font, fill=255, stroke_width=stroke, stroke_fill=255)

    # 外描边（深蓝）
    outline = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    o_draw = ImageDraw.Draw(outline)
    o_draw.text(
        (x, y),
        text,
        font=font,
        fill=(0, 0, 0, 0),
        stroke_width=stroke + 2,
        stroke_fill=(24, 44, 68, 240),
    )
    canvas.alpha_composite(outline)

    # 使用旧素材纹理填充到字形内部，保持“旧风格”质感
    raw_path = os.path.join(RAW_DIR, raw_name)
    raw_img = Image.open(raw_path)
    tex = build_texture_fill(raw_img, w, h)

    base = np.zeros((h, w, 4), dtype=np.uint8)
    m = np.array(mask_img).astype(np.float32) / 255.0

    # 冷白主色 + 裂纹纹理
    r = 220 + (30 * (1 - tex))
    g = 232 + (22 * (1 - tex))
    b = 244 + (10 * (1 - tex))

    # 叠加轻微噪声层让笔画更“旧”
    grain = (np.sin(np.linspace(0, 30, w))[None, :] + np.cos(np.linspace(0, 24, h))[:, None]) * 0.04
    r = np.clip(r * (1.0 - grain), 0, 255)
    g = np.clip(g * (1.0 - grain), 0, 255)
    b = np.clip(b * (1.0 - grain), 0, 255)

    base[:, :, 0] = (r * m).astype(np.uint8)
    base[:, :, 1] = (g * m).astype(np.uint8)
    base[:, :, 2] = (b * m).astype(np.uint8)
    base[:, :, 3] = (255 * m).astype(np.uint8)

    txt_img = Image.fromarray(base, "RGBA")
    canvas.alpha_composite(txt_img)

    # 顶部高光
    hl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(hl)
    h_draw.text((x, y - 1), text, font=font, fill=(255, 255, 255, 70), stroke_width=stroke, stroke_fill=(255, 255, 255, 22))
    hl = hl.filter(ImageFilter.GaussianBlur(0.8))
    canvas.alpha_composite(hl)

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, out_name)
    canvas.save(out_path)
    print(f"generated {out_path} size={canvas.size}")


if __name__ == "__main__":
    font = pick_font()
    for text, raw_name, out_name in TASKS:
        render_one(text, raw_name, out_name, font)
