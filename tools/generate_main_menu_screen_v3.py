from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageFont, ImageEnhance

ROOT = Path(r"f:/Code/RPG_GAME")
STYLE = ROOT / "assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_battle_hud_v1.png"
OUT_DIR = ROOT / "assets/raw/ui/cold_wuxia/v2"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT = OUT_DIR / "ui_cold_wuxia_main_menu_screen_v3.png"
META = OUT_DIR / "ui_cold_wuxia_main_menu_screen_v3.meta.json"
GAME_BG = ROOT / "game/art/backgrounds/bg_main_menu_v3.png"

W, H = 1536, 1024
style = Image.open(STYLE).convert("RGBA")

# Crops from the approved HUD atlas.
# Coordinates are in the 1080x720 reference image.
title_bar = style.crop((25, 38, 515, 122))
button_blue = style.crop((285, 470, 535, 553))
button_cyan = style.crop((26, 470, 275, 553))
wide_panel = style.crop((35, 300, 1010, 455))
small_panel = style.crop((535, 30, 770, 255))

canvas = Image.new("RGBA", (W, H), (5, 12, 20, 255))
d = ImageDraw.Draw(canvas, "RGBA")

# Cold wuxia background: ink gradient, bamboo silhouettes, distant mountains.
for y in range(H):
    t = y / H
    r = int(5 + 10 * t)
    g = int(13 + 20 * t)
    b = int(24 + 38 * t)
    d.line([(0, y), (W, y)], fill=(r, g, b, 255))

# Moon glow / mist.
for radius, alpha in [(520, 28), (360, 30), (220, 34)]:
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    gd.ellipse((W//2-radius, 60-radius//2, W//2+radius, 60+radius//2), fill=(80, 135, 170, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(70))
    canvas.alpha_composite(glow)

# Distant mountain shapes.
for i, base in enumerate([620, 700, 790]):
    color = [(12, 30, 45, 130), (8, 23, 36, 150), (5, 17, 29, 170)][i]
    pts = []
    for x in range(-80, W + 120, 120):
        y = base - int(90 * math.sin((x + i * 80) / 210.0)) - (x % 240) // 8
        pts.append((x, y))
    pts += [(W + 120, H), (-80, H)]
    d.polygon(pts, fill=color)

# Bamboo silhouettes.
for x, h, tilt, a in [(70, 820, -25, 90), (145, 700, -10, 70), (1320, 760, 18, 84), (1435, 850, 32, 95), (1510, 680, 15, 65)]:
    d.line((x, H, x + tilt, H - h), fill=(3, 12, 18, a), width=9)
    for k in range(8):
        yy = H - 90 - k * 78
        xx = x + int(tilt * (H - yy) / h)
        sign = -1 if k % 2 else 1
        d.line((xx, yy, xx + sign * 115, yy - 42), fill=(8, 26, 34, a - 10), width=4)
        d.polygon([(xx + sign*115, yy-42), (xx + sign*155, yy-55), (xx + sign*122, yy-27)], fill=(9, 33, 42, a - 16))

# Subtle vignette.
mask = Image.new("L", (W, H), 0)
md = ImageDraw.Draw(mask)
md.ellipse((-260, -180, W + 260, H + 180), fill=230)
mask = ImageOps.invert(mask).filter(ImageFilter.GaussianBlur(100))
v = Image.new("RGBA", (W, H), (0, 0, 0, 190))
v.putalpha(mask)
canvas.alpha_composite(v)

# Helper: paste atlas element preserving style.
def paste_fit(src, box, alpha=255):
    img = src.resize((box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
    if alpha < 255:
        a = img.getchannel("A").point(lambda p: int(p * alpha / 255))
        img.putalpha(a)
    canvas.alpha_composite(img, (box[0], box[1]))

# Top ornate title frame, scaled from style atlas.
paste_fit(title_bar, (388, 36, 1148, 164), 255)
# Central atmospheric backing panel.
panel = wide_panel.resize((1050, 305), Image.Resampling.LANCZOS)
panel = ImageEnhance.Contrast(panel).enhance(1.12)
a = panel.getchannel("A").point(lambda p: int(p * 0.94))
panel.putalpha(a)
canvas.alpha_composite(panel, (243, 198))

# Two side portrait-style decorative panels, but no reused character portraits.
paste_fit(small_panel, (110, 250, 355, 670), 185)
paste_fit(small_panel, (1180, 250, 1425, 670), 185)
# Ink silhouettes for characters to suggest Jianghu without copied portraits.
d.ellipse((180, 330, 275, 425), fill=(4, 12, 19, 210), outline=(86, 140, 175, 145), width=3)
d.polygon([(160, 660), (230, 420), (315, 660)], fill=(5, 13, 21, 220))
d.line((205, 465, 120, 620), fill=(155, 205, 230, 130), width=5)
d.ellipse((1255, 325, 1345, 415), fill=(4, 10, 16, 218), outline=(95, 145, 175, 130), width=3)
d.polygon([(1210, 660), (1300, 410), (1390, 660)], fill=(4, 11, 18, 225))
d.line((1360, 440, 1235, 640), fill=(145, 195, 220, 120), width=5)

# Menu block made from approved HUD button frames.
menu_x = 508
button_w, button_h = 520, 108
button_ys = [392, 522, 652]
for i, y in enumerate(button_ys):
    src = button_cyan if i == 0 else button_blue
    paste_fit(src, (menu_x, y, menu_x + button_w, y + button_h), 255)

# Fonts.
font_paths = [Path(r"C:/Windows/Fonts/msyh.ttc"), Path(r"C:/Windows/Fonts/simhei.ttf"), Path(r"C:/Windows/Fonts/simsun.ttc")]
font_title = font_sub = font_btn = None
for fp in font_paths:
    if fp.exists():
        font_title = ImageFont.truetype(str(fp), 72)
        font_sub = ImageFont.truetype(str(fp), 28)
        font_btn = ImageFont.truetype(str(fp), 38)
        break
if font_title is None:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()
    font_btn = ImageFont.load_default()

# Text with subtle glow.
def glow_text(pos, text, font, fill, glow=(80, 170, 210, 150), anchor="mm"):
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.text(pos, text, font=font, fill=glow, anchor=anchor)
    layer = layer.filter(ImageFilter.GaussianBlur(4))
    canvas.alpha_composite(layer)
    d.text(pos, text, font=font, fill=fill, anchor=anchor)

# Required title and buttons.
glow_text((W // 2, 86), "云影侠传", font_title, (228, 242, 250, 255))
d.text((W // 2, 156), "寒山入梦 · 一剑照江湖", font=font_sub, fill=(150, 190, 212, 230), anchor="mm")
for text, y in zip(["新游戏", "读取存档", "离开"], button_ys):
    glow_text((menu_x + button_w // 2, y + button_h // 2 - 2), text, font_btn, (225, 242, 250, 255), glow=(70, 165, 210, 120))

# Decorative mist over bottom.
mist = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ms = ImageDraw.Draw(mist, "RGBA")
for i in range(12):
    y = 760 + i * 18
    ms.ellipse((-150 + i*60, y, W + 120 - i*30, y + 90), fill=(95, 145, 170, 10))
mist = mist.filter(ImageFilter.GaussianBlur(22))
canvas.alpha_composite(mist)

canvas = canvas.convert("RGB")
canvas.save(OUT, "PNG", optimize=True)
GAME_BG.parent.mkdir(parents=True, exist_ok=True)
canvas.save(GAME_BG, "PNG", optimize=True)
META.write_text(json.dumps({
    "id": "ui_cold_wuxia_main_menu_screen_v3",
    "source_style": str(STYLE),
    "output": str(OUT),
    "game_copy": str(GAME_BG),
    "required_labels": ["新游戏", "读取存档", "离开"],
    "note": "按 ui_cold_wuxia_battle_hud_v1.png 的冷色玄铁 UI 风格重新设计的主菜单整图。",
}, ensure_ascii=False, indent=2), encoding="utf-8")
print(OUT)
