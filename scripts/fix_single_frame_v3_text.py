"""修复 single_frame_v3 按钮文字颜色过浅问题。

使用 PIL 重新渲染高对比度的行楷中文文字，替换 AI 生成的灰暗文字。
保留底框和图标不变，仅重做文字层和三态按钮。
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
V3_DIR = ROOT / "tools/ui_field_hud_v1/single_frame_v3"
TOOLS_OUT = ROOT / "tools/ui_field_hud_v1/single_frame_v3_fixed"
GAME_OUT = ROOT / "game/art/ui/field_hud/v1"
PREVIEW = ROOT / "tools/ui_field_hud_v1/single_frame_v3_fixed_preview.png"

SIZE = (241, 93)

BUTTONS = {
    "inventory": "背包",
    "equipment": "装备",
    "skill": "武学",
    "quest": "任务",
    "system": "系统",
}

# ——— Text layout (derived from single_frame_v3 analysis) ———
TEXT_CENTER = (155, 49)
FONT_SIZE = 36


def _font(size: int) -> ImageFont.FreeTypeFont:
    for path in [
        Path("C:/Windows/Fonts/STXINGKA.TTF"),   # 华文行楷
        Path("C:/Windows/Fonts/STKAITI.TTF"),     # 华文楷体
        Path("C:/Windows/Fonts/simkai.ttf"),       # 楷体
        Path("C:/Windows/Fonts/STLITI.TTF"),       # 华文隶书
    ]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    raise FileNotFoundError("missing Chinese font")


def _clean(image: Image.Image) -> Image.Image:
    arr = np.array(image.convert("RGBA"))
    low = arr[:, :, 3] <= 2
    arr[low, 0:4] = 0
    return Image.fromarray(arr, "RGBA")


def _make_text_layer(key: str) -> Image.Image:
    """Generate engraved/incised text: inner shadow at top-left, rim light at bottom-right.

    Also adds subtle noise to match the frame's gritty metal texture.
    """
    label = BUTTONS[key]
    font = _font(FONT_SIZE)
    bbox = ImageDraw.Draw(Image.new("RGBA", SIZE)).textbbox((0, 0), label, font=font, stroke_width=2)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = TEXT_CENTER[0] - tw // 2
    y = TEXT_CENTER[1] - th // 2 - 3

    # --- Colour palette for engraved metal ---
    # The frame's base is dark blue-gray (avg ~37,41,51); the edge bevel exposes
    # silvery blue-gray highlights (~128,142,146). We target a tone between the two
    # — like scratched-off paint revealing raw metal — with slight warmth.
    cavity_shadow = (10, 16, 20)       # deep shadow inside the top-left of the recess
    metal_fill = (198, 190, 172)       # raw exposed metal base (slightly brighter for readability)
    rim_light = (228, 220, 202)        # thin highlight at bottom-right edge of the recess
    dark_stroke = (24, 30, 34)         # outlines anchor text into the frame

    # Layer 0 — cavity shadow (offset up-left, the dark inner wall of the recess)
    cavity = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    cd = ImageDraw.Draw(cavity)
    cd.text((x - 2, y - 2), label, font=font,
            fill=cavity_shadow + (210,),
            stroke_width=1, stroke_fill=cavity_shadow + (160,))
    cavity = cavity.filter(ImageFilter.GaussianBlur(0.7))

    # Layer 1 — main engraved metal fill (at center position)
    main = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    md = ImageDraw.Draw(main)
    md.text((x, y), label, font=font,
            fill=metal_fill + (255,),
            stroke_width=1, stroke_fill=dark_stroke + (220,))

    # Layer 2 — rim light (offset down-right, simulates light catching bottom edge)
    rim = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    rd.text((x + 1, y + 2), label, font=font,
            fill=rim_light + (85,))
    # Only keep rim light where main text alpha exists (clip to text shape)
    rim_arr = np.array(rim).astype(np.float32)
    main_a = np.array(main)[:, :, 3].astype(np.float32) / 255.0
    rim_arr[:, :, 3] = (rim_arr[:, :, 3] * main_a).astype(np.uint8)
    rim = Image.fromarray(np.clip(rim_arr, 0, 255).astype("uint8"), "RGBA")

    # Composite layers: cavity behind → main → rim on top
    result = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    result.alpha_composite(cavity)
    result.alpha_composite(main)
    result.alpha_composite(rim)

    # Add subtle grain/noise to match the frame's gritty metal texture
    noise_arr = np.random.RandomState(hash(key) % (2**31)).randint(0, 18, (SIZE[1], SIZE[0]), dtype=np.uint8)
    noise_rgba = np.zeros((SIZE[1], SIZE[0], 4), dtype=np.uint8)
    noise_rgba[:, :, :3] = noise_arr[:, :, None]
    text_a = np.array(result)[:, :, 3]
    noise_rgba[:, :, 3] = (text_a.astype(np.uint16) * noise_arr // 255).astype(np.uint8)
    noise_tex = Image.fromarray(noise_rgba, "RGBA")
    result.alpha_composite(noise_tex)

    return _clean(result)


def _derive_state(base: Image.Image, state: str) -> Image.Image:
    alpha = base.getchannel("A")
    rgb = base.convert("RGB")
    if state == "hover":
        rgb = ImageEnhance.Brightness(rgb).enhance(1.12)
        rgb = ImageEnhance.Color(rgb).enhance(1.06)
    elif state == "pressed":
        rgb = ImageEnhance.Brightness(rgb).enhance(0.74)
        rgb = ImageEnhance.Color(rgb).enhance(0.92)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    if state == "hover":
        glow = Image.new("RGBA", SIZE, (120, 165, 180, 0))
        glow.putalpha(
            alpha.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.25))
        )
        out = Image.alpha_composite(glow, out)
        out.putalpha(alpha)
    return _clean(out)


def _compose_button(frame: Image.Image, key: str) -> dict[str, Image.Image]:
    icon = Image.open(V3_DIR / f"icon_{key}.png").convert("RGBA")
    text = _make_text_layer(key)
    normal = Image.alpha_composite(Image.alpha_composite(frame, icon), text)
    normal = _clean(normal)
    return {
        "normal": normal,
        "hover": _derive_state(normal, "hover"),
        "pressed": _derive_state(normal, "pressed"),
    }


def _make_preview(
    v3_buttons: dict[str, dict[str, Image.Image]],
    fixed_buttons: dict[str, dict[str, Image.Image]],
) -> None:
    keys = ["inventory", "equipment", "skill", "quest", "system"]
    states = ["normal", "hover", "pressed"]
    n_keys = len(keys)
    n_states = len(states)
    btn_w, btn_h = SIZE
    col_w = btn_w + 28
    row_h = btn_h + 18

    margin_x = 32
    margin_y = 40
    label_w = 140

    canvas_w = margin_x + label_w + n_states * col_w * 2 + 24 + margin_x
    canvas_h = margin_y + n_keys * row_h + 16 + margin_y
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (18, 24, 30, 255))
    draw = ImageDraw.Draw(canvas)

    # Section titles
    x_v3 = margin_x + label_w
    x_fix = x_v3 + n_states * col_w + 24
    draw.text((x_v3, 10), "v3 原始 (AI 文字)", fill=(255, 180, 100, 255))
    draw.text((x_fix, 10), "修复后 (PIL 文字)", fill=(100, 220, 160, 255))

    state_labels = {"normal": "normal", "hover": "hover", "pressed": "pressed"}
    for row, key in enumerate(keys):
        y = margin_y + row * row_h
        draw.text((12, y + btn_h // 2 - 8), key, fill=(210, 210, 210, 255))
        for col, state in enumerate(states):
            x_v = x_v3 + col * col_w
            x_f = x_fix + col * col_w
            if key in v3_buttons:
                canvas.alpha_composite(v3_buttons[key][state], (x_v, y))
            canvas.alpha_composite(fixed_buttons[key][state], (x_f, y))
    canvas.save(PREVIEW)
    print(f"Preview saved to {PREVIEW}")


def main() -> None:
    TOOLS_OUT.mkdir(parents=True, exist_ok=True)
    GAME_OUT.mkdir(parents=True, exist_ok=True)

    frame = Image.open(V3_DIR / "shared_frame_normal.png").convert("RGBA")

    # Load v3 original buttons for preview comparison
    v3_buttons: dict[str, dict[str, Image.Image]] = {}
    for key in BUTTONS:
        v3_buttons[key] = {}
        for state in ("normal", "hover", "pressed"):
            src = V3_DIR / f"hud_btn_{key}_{state}.png"
            if src.exists():
                v3_buttons[key][state] = Image.open(src).convert("RGBA")

    fixed_buttons: dict[str, dict[str, Image.Image]] = {}
    for key in BUTTONS:
        states = _compose_button(frame, key)
        fixed_buttons[key] = states
        for state, img in states.items():
            filename = f"hud_btn_{key}_{state}.png"
            img.save(TOOLS_OUT / filename)
            img.save(GAME_OUT / filename)
            print(f"  {filename}")

    _make_preview(v3_buttons, fixed_buttons)
    print(f"\nOutput: {TOOLS_OUT}")
    print(f"Game output: {GAME_OUT}")


if __name__ == "__main__":
    main()
