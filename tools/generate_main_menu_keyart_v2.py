from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageFont

ROOT = Path(r"f:/Code/RPG_GAME")
out_dir = ROOT / "assets" / "raw" / "ui" / "cold_wuxia" / "v2"
out_dir.mkdir(parents=True, exist_ok=True)
out_png = out_dir / "ui_cold_wuxia_main_menu_keyart_v2.png"
out_meta = out_dir / "ui_cold_wuxia_main_menu_keyart_v2.meta.json"

# Sources
bg_path = ROOT / "game" / "art" / "backgrounds" / "bg_zhuwei_forest.png"
hero_path = ROOT / "assets" / "raw" / "character" / "v2" / "portrait_lengguyun_neutral.png"
heroine_path = ROOT / "assets" / "raw" / "character" / "v2" / "portrait_yuewuxing_meeting.png"
enemy_path = ROOT / "assets" / "raw" / "character" / "v2" / "portrait_killer_leader_combat.png"

W, H = 1536, 1024
canvas = Image.new("RGBA", (W, H), (10, 16, 24, 255))

# Base background
if bg_path.exists():
    bg = Image.open(bg_path).convert("RGBA")
    bg = ImageOps.fit(bg, (W, H), method=Image.Resampling.LANCZOS)
    canvas.alpha_composite(bg)

# Cold tone grading overlay
grade = Image.new("RGBA", (W, H), (16, 36, 58, 110))
canvas.alpha_composite(grade)

# Vignette
vig = Image.new("L", (W, H), 0)
vd = ImageDraw.Draw(vig)
vd.ellipse((-220, -180, W + 220, H + 160), fill=210)
vig = ImageOps.invert(vig).filter(ImageFilter.GaussianBlur(120))
shadow = Image.new("RGBA", (W, H), (3, 7, 12, 210))
shadow.putalpha(vig)
canvas.alpha_composite(shadow)

# Character layer helper

def paste_character(path: Path, box: tuple[int, int, int, int], tint=(220, 235, 255, 255), alpha=215):
    if not path.exists():
        return
    img = Image.open(path).convert("RGBA")
    img = ImageOps.fit(img, (box[2]-box[0], box[3]-box[1]), method=Image.Resampling.LANCZOS)
    # soft mask
    m = Image.new("L", img.size, 0)
    md = ImageDraw.Draw(m)
    md.rounded_rectangle((0, 0, img.size[0]-1, img.size[1]-1), radius=34, fill=255)
    m = m.filter(ImageFilter.GaussianBlur(6))
    img.putalpha(m)

    # cold tint
    tint_img = Image.new("RGBA", img.size, tint)
    img = Image.blend(img, tint_img, 0.12)

    # opacity
    a = img.getchannel("A").point(lambda p: int(p * (alpha / 255.0)))
    img.putalpha(a)
    canvas.alpha_composite(img, (box[0], box[1]))

# Back characters first
paste_character(heroine_path, (860, 250, 1180, 760), tint=(190, 215, 255, 255), alpha=180)
paste_character(enemy_path, (1180, 230, 1460, 760), tint=(165, 190, 230, 255), alpha=170)
# Main hero
paste_character(hero_path, (930, 170, 1370, 860), tint=(220, 235, 255, 255), alpha=235)

# UI framing
d = ImageDraw.Draw(canvas)

def panel(xy, r=18, fill=(10, 22, 35, 175), outline=(120, 175, 220, 220), w=3):
    d.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=w)

# Top title beam
panel((280, 26, 1256, 126), r=14, fill=(8, 20, 34, 205), outline=(158, 210, 245, 245), w=3)
# Left menu block
panel((140, 220, 640, 860), r=20, fill=(7, 18, 30, 190), outline=(102, 160, 205, 225), w=3)
# Right news block
panel((1220, 236, 1460, 838), r=18, fill=(8, 18, 30, 180), outline=(92, 145, 195, 215), w=2)
# Bottom beam
panel((70, 930, 1465, 995), r=10, fill=(6, 16, 28, 180), outline=(80, 132, 180, 190), w=2)

# Menu placeholders
panel((180, 330, 600, 410), r=10, fill=(12, 28, 44, 200), outline=(116, 176, 220, 230), w=2)
panel((180, 438, 600, 518), r=10, fill=(12, 28, 44, 170), outline=(95, 150, 192, 210), w=2)
panel((180, 546, 600, 626), r=10, fill=(12, 28, 44, 170), outline=(95, 150, 192, 210), w=2)

# Text (prefer Chinese font)
font_paths = [
    Path(r"C:/Windows/Fonts/msyh.ttc"),
    Path(r"C:/Windows/Fonts/simhei.ttf"),
    Path(r"C:/Windows/Fonts/simsun.ttc"),
]
font_title = None
font_sub = None
font_body = None
for fp in font_paths:
    if fp.exists():
        font_title = ImageFont.truetype(str(fp), 68)
        font_sub = ImageFont.truetype(str(fp), 26)
        font_body = ImageFont.truetype(str(fp), 30)
        break
if font_title is None:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()
    font_body = ImageFont.load_default()

# Title + sub
d.text((768, 64), "云影侠传", font=font_title, fill=(228, 242, 255, 255), anchor="mm")
d.text((768, 118), "风起云涌，剑入江湖", font=font_sub, fill=(168, 205, 232, 255), anchor="mm")

# Section labels
d.text((390, 270), "江湖行程", font=font_body, fill=(210, 233, 250, 255), anchor="mm")
d.text((390, 310), "请择一途，执剑入世", font=font_sub, fill=(142, 178, 205, 255), anchor="mm")
d.text((1340, 286), "江湖快报", font=font_body, fill=(210, 233, 250, 255), anchor="mm")

# Save
canvas = canvas.convert("RGB")
canvas.save(out_png, "PNG", optimize=True)

meta = {
    "id": "ui_cold_wuxia_main_menu_keyart_v2",
    "type": "ui_main_menu_keyart",
    "style": "cold_wuxia",
    "resolution": [W, H],
    "generated_by": "local_composite_pipeline",
    "source_refs": [
        str(bg_path),
        str(hero_path),
        str(heroine_path),
        str(enemy_path),
    ],
    "note": "原创重构版主界面视觉稿；非参考图直拷。",
}
out_meta.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
print(out_png)
