"""生成野外 HUD 组件纹理 —— 面板底框、头像框、血条/内力条底槽与填充条、场景名牌。
所有组件输出到 game/art/ui/field_hud/v1/，在 Godot 中通过 TextureRect 组装。
"""

import sys
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        try:
            _stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "game" / "art" / "ui" / "field_hud" / "v1"

# —— 色调参考（寒铁冷钢武侠风） ——
BG_DEEP = (10, 17, 23, 255)          # #0a1117 深黑蓝底
BG_PANEL = (14, 22, 30, 255)         # #0e161e 面板中间色
BORDER_COLD = (38, 68, 82, 255)       # #264452 冷钢边
BORDER_LIGHT = (58, 96, 112, 255)    # #3a6070 冷钢高光边
GROOVE_DARK = (8, 12, 16, 255)       # #080c10 凹槽暗色
HP_FILL_LOW = (92, 20, 18, 255)      # #5c1412 暗血红
HP_FILL_HIGH = (130, 28, 22, 255)    # #821c16 血红亮
MP_FILL_LOW = (22, 66, 96, 255)      # #164260 寒蓝
MP_FILL_HIGH = (30, 88, 124, 255)    # #1e587c 寒蓝亮
GOLD_TEXT = (210, 190, 120, 255)     # #d2be78 暗金
AVATAR_RING_OUTER = (32, 56, 72, 255)  # #203848
AVATAR_RING_INNER = (14, 22, 30, 255)  # #0e161e


def _round_corners(im: Image.Image, radius: int) -> Image.Image:
    """对 RGBA 图像四角做圆形裁切"""
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=radius, fill=255)
    out = im.copy()
    out.putalpha(mask)
    return out


def _h_gradient(w: int, h: int, left: tuple, right: tuple) -> Image.Image:
    """横向渐变色条"""
    im = Image.new("RGBA", (w, h))
    for x in range(w):
        t = x / max(w - 1, 1)
        r = int(left[0] + (right[0] - left[0]) * t)
        g = int(left[1] + (right[1] - left[1]) * t)
        b = int(left[2] + (right[2] - left[2]) * t)
        a = int(left[3] + (right[3] - left[3]) * t)
        for y in range(h):
            im.putpixel((x, y), (r, g, b, a))
    return im


def make_panel_frame() -> Image.Image:
    """面板底框 340×100 —— 寒铁匾额，冷钢边框，暗刻内凹"""
    w, h = 340, 100
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # 外层底
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=10, fill=BG_PANEL)

    # 内凹区域（比外层稍暗，留出边框宽度）
    border_w = 4
    inner_rect = [(border_w, border_w), (w - 1 - border_w, h - 1 - border_w)]
    draw.rounded_rectangle(inner_rect, radius=8, fill=BG_DEEP)

    # 冷钢边框 —— 用两个叠加矩形模拟 bevel
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=10,
                           outline=BORDER_COLD, width=2)
    draw.rounded_rectangle([(1, 1), (w - 2, h - 2)], radius=9,
                           outline=BORDER_LIGHT, width=1)

    # 四角装饰小铆钉
    rivet_r = 3
    rivet_positions = [(12, 12), (w - 12, 12), (12, h - 12), (w - 12, h - 12)]
    for rx, ry in rivet_positions:
        draw.ellipse([(rx - rivet_r, ry - rivet_r), (rx + rivet_r, ry + rivet_r)],
                     fill=BORDER_COLD, outline=BORDER_LIGHT)

    return im


def make_avatar_frame() -> Image.Image:
    """头像圆形框 52×52 —— 冷钢圆环，中心透明用于放置头像"""
    size = 52
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    cx = cy = size // 2
    outer_r = size // 2 - 1
    inner_r = outer_r - 4

    # 外圆环
    draw.ellipse([(cx - outer_r, cy - outer_r), (cx + outer_r, cy + outer_r)],
                 fill=AVATAR_RING_OUTER)
    # 内圆（挖空）
    draw.ellipse([(cx - inner_r, cy - inner_r), (cx + inner_r, cy + inner_r)],
                 fill=(0, 0, 0, 0))
    # 高光环
    draw.ellipse([(cx - outer_r, cy - outer_r), (cx + outer_r, cy + outer_r)],
                 outline=BORDER_LIGHT, width=1)

    return im


def make_bar_bg(w: int = 160, h: int = 14) -> Image.Image:
    """长条凹槽底框 —— 深色槽底，细边框"""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # 凹槽底
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=5, fill=GROOVE_DARK)
    # 边框
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=5,
                           outline=BORDER_COLD, width=1)

    return im


def make_hp_fill(w: int = 160, h: int = 14) -> Image.Image:
    """生命值填充条 —— 暗血红渐变，两边稍暗"""
    im = _h_gradient(w, h, HP_FILL_HIGH, HP_FILL_LOW)
    # 上下加暗边模拟立体
    draw = ImageDraw.Draw(im)
    for x in range(w):
        im.putpixel((x, 0), tuple(int(c * 0.55) for c in HP_FILL_LOW))
        im.putpixel((x, 1), tuple(int(c * 0.72) for c in HP_FILL_LOW))
        im.putpixel((x, h - 1), tuple(int(c * 0.55) for c in HP_FILL_LOW))
        im.putpixel((x, h - 2), tuple(int(c * 0.72) for c in HP_FILL_LOW))
    return _round_corners(im, 4)


def make_mp_fill(w: int = 160, h: int = 14) -> Image.Image:
    """内力值填充条 —— 寒蓝渐变，两边稍暗"""
    im = _h_gradient(w, h, MP_FILL_HIGH, MP_FILL_LOW)
    draw = ImageDraw.Draw(im)
    for x in range(w):
        im.putpixel((x, 0), tuple(int(c * 0.55) for c in MP_FILL_LOW))
        im.putpixel((x, 1), tuple(int(c * 0.72) for c in MP_FILL_LOW))
        im.putpixel((x, h - 1), tuple(int(c * 0.55) for c in MP_FILL_LOW))
        im.putpixel((x, h - 2), tuple(int(c * 0.72) for c in MP_FILL_LOW))
    return _round_corners(im, 4)


def make_scene_badge() -> Image.Image:
    """场景名牌 180×26 —— 半透明暗底，细边框"""
    w, h = 180, 26
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    # 半透明底
    badge_bg = (6, 12, 18, 110)  # ~43% opacity
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=7, fill=badge_bg)
    im = Image.alpha_composite(im, overlay)

    draw = ImageDraw.Draw(im)
    draw.rounded_rectangle([(0, 0), (w - 1, h - 1)], radius=7,
                           outline=(34, 54, 68, 128), width=1)
    return im


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    textures = {
        "hud_player_frame.png": make_panel_frame(),
        "hud_avatar_frame.png": make_avatar_frame(),
        "hud_hp_bg.png": make_bar_bg(160, 14),
        "hud_hp_fill.png": make_hp_fill(160, 14),
        "hud_mp_bg.png": make_bar_bg(160, 14),
        "hud_mp_fill.png": make_mp_fill(160, 14),
        "hud_scene_badge.png": make_scene_badge(),
    }

    for name, img in textures.items():
        path = OUT_DIR / name
        img.save(path)
        print(f"  OK {name}  ({img.size[0]}x{img.size[1]})")

    print(f"\nDone. Output: {OUT_DIR}")


if __name__ == "__main__":
    main()
