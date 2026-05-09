from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

try:
    from rembg import remove as remove_background
except Exception:  # pragma: no cover - optional local asset tooling dependency
    remove_background = None


ROOT = Path(__file__).resolve().parent.parent
RAW_FRAME_DIR = ROOT / "assets" / "raw" / "ui" / "button" / "main_menu" / "frame" / "v1"
RAW_TEXT_DIR = ROOT / "assets" / "raw" / "ui" / "button" / "main_menu" / "text" / "v1"
V5_FULL_MENU = ROOT / "assets" / "raw" / "scene_background" / "ui_main_menu_full_v5.png"
GAME_BUTTON_DIR = ROOT / "game" / "art" / "ui" / "button"
PREVIEW_PATH = ROOT / "tools" / "main_menu_button_layers_preview.png"
PREVIEW_BG = ROOT / "game" / "art" / "backgrounds" / "bg_main_menu_v6_clean.png"

CANVAS_SIZE = (512, 128)

FRAME_FILES = {
    "normal": "ui_btn_main_frame_normal_v1.png",
    "hover": "ui_btn_main_frame_hover_v1.png",
    "pressed": "ui_btn_main_frame_pressed_v1.png",
}

TEXT_FILES = {
    "new_game": "ui_btn_main_text_new_game_v1.png",
    "load": "ui_btn_main_text_load_v1.png",
    "quit": "ui_btn_main_text_quit_v1.png",
}

TEXT_OUTPUTS = {
    "new_game": "btn_menu_text_new_game.png",
    "load": "btn_menu_text_load.png",
    "quit": "btn_menu_text_quit.png",
}

V5_BUTTON_CROPS = {
    "new_game": (895, 390, 1470, 545),
    "load": (895, 575, 1470, 730),
    "quit": (895, 735, 1470, 890),
}

V5_BUTTON_OUTPUTS = {
    "new_game": "btn_menu_v5_new_game",
    "load": "btn_menu_v5_load",
    "quit": "btn_menu_v5_quit",
}


def white_to_alpha(image: Image.Image, threshold: int = 246, feather: int = 34) -> Image.Image:
    rgba = image.convert("RGBA")
    arr = np.array(rgba).astype(np.float32)
    rgb = arr[:, :, :3]
    brightness = rgb.mean(axis=2)
    distance_from_white = 255.0 - brightness
    alpha = np.clip((distance_from_white / feather) * 255.0, 0, 255)
    alpha[brightness >= threshold] = 0
    alpha = np.minimum(alpha, arr[:, :, 3])
    arr[:, :, 3] = alpha
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def white_to_alpha_keep_colored(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    arr = np.array(rgba).astype(np.float32)
    rgb = arr[:, :, :3]
    brightness = rgb.mean(axis=2)
    max_channel = rgb.max(axis=2)
    chroma = rgb.max(axis=2) - rgb.min(axis=2)

    # 金色文字高光也很亮，不能只按亮度扣白底；只有“高亮且低饱和”的像素才视作白底。
    bright_score = np.clip((max_channel - 220.0) / 35.0, 0.0, 1.0)
    low_chroma_score = np.clip((42.0 - chroma) / 42.0, 0.0, 1.0)
    background_score = bright_score * low_chroma_score
    alpha = 255.0 * (1.0 - background_score)
    alpha[chroma >= 34.0] = 255.0
    alpha[brightness <= 218.0] = 255.0
    alpha[(max_channel >= 235.0) & (chroma <= 30.0)] = 0.0
    alpha = np.minimum(alpha, arr[:, :, 3])
    arr[:, :, 3] = alpha
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    arr = np.array(image)
    alpha = arr[:, :, 3]
    ys, xs = np.where(alpha > 12)
    if len(xs) == 0:
        return (0, 0, image.width, image.height)
    pad = 8
    return (
        max(0, int(xs.min()) - pad),
        max(0, int(ys.min()) - pad),
        min(image.width, int(xs.max()) + pad + 1),
        min(image.height, int(ys.max()) + pad + 1),
    )


def fit_on_canvas(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    crop = image.crop(alpha_bbox(image))
    scale = min(max_size[0] / crop.width, max_size[1] / crop.height)
    new_size = (max(1, int(crop.width * scale)), max(1, int(crop.height * scale)))
    resized = crop.resize(new_size, Image.LANCZOS)
    x = (CANVAS_SIZE[0] - resized.width) // 2
    y = (CANVAS_SIZE[1] - resized.height) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def v5_button_alpha(size: tuple[int, int]) -> Image.Image:
    width, height = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)

    # The v5 buttons have a long plaque plus side ornaments. This mask keeps the
    # button silhouette stable while trimming most of the screenshot background.
    draw.rounded_rectangle((48, 26, width - 48, height - 8), radius=24, fill=255)
    draw.ellipse((12, 38, 138, height - 2), fill=255)
    draw.ellipse((width - 138, 38, width - 12, height - 2), fill=255)
    draw.rounded_rectangle((92, 18, width - 92, 58), radius=12, fill=255)
    draw.rounded_rectangle((92, height - 38, width - 92, height - 1), radius=12, fill=255)

    mask = mask.filter(ImageFilter.GaussianBlur(0.7))
    return mask


def fit_v5_button_on_canvas(crop: Image.Image) -> Image.Image:
    rgba = crop.convert("RGBA")
    if remove_background is not None:
        rgba = remove_background(rgba).convert("RGBA")
    else:
        rgba.putalpha(v5_button_alpha(rgba.size))

    # v5 三枚按钮来自同一张整图，裁图尺寸一致。这里必须按固定裁图
    # 尺寸统一缩放，不能按各自 alpha bbox 缩放，否则 rembg 边界差异会
    # 让“新游戏 / 读取存档 / 离开”的视觉大小不一致。
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    scale = min(504 / rgba.width, 122 / rgba.height)
    new_size = (max(1, int(rgba.width * scale)), max(1, int(rgba.height * scale)))
    resized = rgba.resize(new_size, Image.LANCZOS)
    x = (CANVAS_SIZE[0] - resized.width) // 2
    y = (CANVAS_SIZE[1] - resized.height) // 2
    canvas.paste(resized, (x, y), resized)
    return clean_transparent_pixels(canvas, 4)


def tint_visible_pixels(image: Image.Image, brightness: float, color: float = 1.0) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    rgb = ImageEnhance.Color(rgb).enhance(color)
    result = rgb.convert("RGBA")
    result.putalpha(alpha)
    return result


def clean_transparent_pixels(image: Image.Image, alpha_threshold: int = 4) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low_alpha = arr[:, :, 3] <= alpha_threshold
    arr[low_alpha, 0] = 0
    arr[low_alpha, 1] = 0
    arr[low_alpha, 2] = 0
    arr[low_alpha, 3] = 0
    return Image.fromarray(arr, "RGBA")


def harden_text_alpha(image: Image.Image, solid_threshold: int = 48) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    alpha = arr[:, :, 3]
    alpha[(alpha > 0) & (alpha < solid_threshold)] = np.minimum(alpha[(alpha > 0) & (alpha < solid_threshold)] * 2, 255)
    alpha[alpha >= solid_threshold] = 255
    arr[:, :, 3] = alpha
    return Image.fromarray(arr, "RGBA")


def make_hover_frame(base: Image.Image) -> Image.Image:
    alpha = base.getchannel("A")
    bright = tint_visible_pixels(base, brightness=1.22, color=1.15)
    cyan_overlay = Image.new("RGBA", base.size, (38, 245, 220, 22))
    result = Image.alpha_composite(bright, cyan_overlay)
    result.putalpha(alpha)
    return clean_transparent_pixels(result, 4)


def make_pressed_frame(base: Image.Image) -> Image.Image:
    dark = tint_visible_pixels(base, brightness=0.72, color=0.95)
    dark.putalpha(base.getchannel("A"))
    return clean_transparent_pixels(dark, 4)


def process_frames() -> None:
    GAME_BUTTON_DIR.mkdir(parents=True, exist_ok=True)
    # 三态必须同源，否则 hover/click 时按钮轮廓会跳变。AI 只用于母版；
    # hover/pressed 由程序后处理派生，保证外形完全一致。
    src = RAW_FRAME_DIR / FRAME_FILES["normal"]
    base = fit_on_canvas(white_to_alpha(Image.open(src), threshold=247, feather=42), (504, 122))
    outputs = {
        "normal": clean_transparent_pixels(base, 4),
        "hover": make_hover_frame(base),
        "pressed": make_pressed_frame(base),
    }
    for state, result in outputs.items():
        out = GAME_BUTTON_DIR / f"btn_menu_frame_{state}.png"
        result.save(out)
        print(f"[frame] {out.relative_to(ROOT)}")


def process_texts() -> None:
    for key, filename in TEXT_FILES.items():
        src = RAW_TEXT_DIR / filename
        text = white_to_alpha_keep_colored(Image.open(src))
        result = harden_text_alpha(clean_transparent_pixels(fit_on_canvas(text, (382, 92)), 4))
        out = GAME_BUTTON_DIR / TEXT_OUTPUTS[key]
        result.save(out)
        print(f"[text]  {out.relative_to(ROOT)}")


def process_v5_full_buttons() -> None:
    if not V5_FULL_MENU.exists():
        print(f"[v5]    missing {V5_FULL_MENU.relative_to(ROOT)}")
        return

    source = Image.open(V5_FULL_MENU).convert("RGBA")
    for key, box in V5_BUTTON_CROPS.items():
        base = fit_v5_button_on_canvas(source.crop(box))
        outputs = {
            "normal": base,
            "hover": make_hover_frame(base),
            "pressed": make_pressed_frame(base),
        }
        prefix = V5_BUTTON_OUTPUTS[key]
        for state, result in outputs.items():
            out = GAME_BUTTON_DIR / f"{prefix}_{state}.png"
            result.save(out)
            print(f"[v5]    {out.relative_to(ROOT)}")


def make_preview() -> None:
    if PREVIEW_BG.exists():
        preview = Image.open(PREVIEW_BG).convert("RGBA")
    else:
        preview = Image.new("RGBA", (1536, 1024), (15, 23, 32, 255))

    x = 900
    y0 = 420
    gap = 37
    labels = ["new_game", "load", "quit"]
    states = ["normal", "hover", "pressed"]
    for idx, label in enumerate(labels):
        state = states[idx]
        v5_button = GAME_BUTTON_DIR / f"{V5_BUTTON_OUTPUTS[label]}_{state}.png"
        if v5_button.exists():
            button = Image.open(v5_button).convert("RGBA")
        else:
            frame = Image.open(GAME_BUTTON_DIR / f"btn_menu_frame_{state}.png").convert("RGBA")
            text = Image.open(GAME_BUTTON_DIR / TEXT_OUTPUTS[label]).convert("RGBA")
            button = Image.alpha_composite(frame, text)
        y = y0 + idx * (CANVAS_SIZE[1] + gap)
        preview.paste(button, (x, y), button)

    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.convert("RGB").save(PREVIEW_PATH)
    print(f"[preview] {PREVIEW_PATH.relative_to(ROOT)}")


def main() -> None:
    process_frames()
    process_texts()
    process_v5_full_buttons()
    make_preview()


if __name__ == "__main__":
    main()
