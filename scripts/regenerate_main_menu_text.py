from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os


def pick_font() -> str:
    candidates = [
        r"C:/Windows/Fonts/STZHONGS.TTF",
        r"C:/Windows/Fonts/msyhbd.ttc",
        r"C:/Windows/Fonts/simhei.ttf",
        r"C:/Windows/Fonts/msyh.ttc",
    ]
    for p in candidates:
        if os.path.exists(p):
            return p
    raise FileNotFoundError("No Chinese font found in C:/Windows/Fonts")


def render_text_png(text: str, output_path: str, font_path: str) -> None:
    w, h = 420, 120
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    size = 96
    while size > 28:
        font = ImageFont.truetype(font_path, size)
        stroke = max(2, size // 16)
        bbox = draw.textbbox((0, 0), text, font=font, stroke_width=stroke)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        if tw <= 360 and th <= 84:
            break
        size -= 2

    font = ImageFont.truetype(font_path, size)
    stroke = max(2, size // 16)
    bbox = draw.textbbox((0, 0), text, font=font, stroke_width=stroke)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (w - tw) // 2 - bbox[0]
    y = (h - th) // 2 - bbox[1]

    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.text(
        (x + 2, y + 2),
        text,
        font=font,
        fill=(18, 28, 40, 170),
        stroke_width=stroke,
        stroke_fill=(8, 12, 18, 210),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(1.2))
    img.alpha_composite(shadow)

    draw = ImageDraw.Draw(img)
    draw.text(
        (x, y),
        text,
        font=font,
        fill=(236, 246, 255, 255),
        stroke_width=stroke,
        stroke_fill=(36, 60, 86, 255),
    )

    highlight = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight)
    hdraw.text((x, y - 1), text, font=font, fill=(255, 255, 255, 55))
    highlight = highlight.filter(ImageFilter.GaussianBlur(0.6))
    img.alpha_composite(highlight)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)
    print(f"generated {output_path} size={img.size} font_size={size}")


if __name__ == "__main__":
    font = pick_font()
    targets = [
        ("新游戏", "game/art/ui/main_menu/buttons/text/v1/btn_menu_text_new_game_v1.png"),
        ("读取存档", "game/art/ui/main_menu/buttons/text/v1/btn_menu_text_load_v1.png"),
        ("离开", "game/art/ui/main_menu/buttons/text/v1/btn_menu_text_quit_v1.png"),
    ]
    for txt, out in targets:
        render_text_png(txt, out, font)
