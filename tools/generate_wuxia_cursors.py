from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json

ROOT = Path('f:/Code/RPG_GAME')
OUT_GAME = ROOT / 'game/art/ui/cursors'
OUT_RAW = ROOT / 'assets/raw/ui/cold_wuxia/v2/cursors'
OUT_GAME.mkdir(parents=True, exist_ok=True)
OUT_RAW.mkdir(parents=True, exist_ok=True)

SIZE = 48
STEEL = (170, 220, 232, 255)
JADE = (72, 190, 170, 255)
CRIMSON = (128, 38, 50, 255)
DARK = (8, 18, 24, 245)
GLOW = (65, 190, 175, 110)
GOLD = (190, 220, 232, 255)


def glow_layer(points=None, ellipse=None, width=5):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if points:
        d.line(points, fill=GLOW, width=width, joint='curve')
    if ellipse:
        d.ellipse(ellipse, outline=GLOW, width=width)
    return img.filter(ImageFilter.GaussianBlur(3))


def save_all(name, img, meta):
    for out in (OUT_GAME, OUT_RAW):
        img.save(out / name, 'PNG')
    (OUT_RAW / f'{Path(name).stem}.meta.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding='utf-8')


def cursor_arrow():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    body = [(6, 4), (35, 28), (23, 31), (30, 43), (22, 46), (15, 34), (7, 43)]
    img.alpha_composite(glow_layer(points=body + [body[0]], width=7))
    d = ImageDraw.Draw(img)
    d.polygon(body, fill=DARK, outline=STEEL)
    d.line([(10, 10), (28, 26), (20, 28), (26, 41)], fill=JADE, width=2)
    d.line([(7, 5), (34, 28), (23, 31), (30, 43)], fill=GOLD, width=2)
    return img


def cursor_hand():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    pts = [(15, 8), (20, 8), (21, 24), (24, 18), (28, 19), (29, 27), (32, 22), (36, 23), (36, 33), (31, 43), (18, 43), (11, 31), (11, 22), (15, 22)]
    img.alpha_composite(glow_layer(points=pts + [pts[0]], width=7))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((14, 7, 21, 31), radius=3, fill=DARK, outline=STEEL, width=2)
    d.rounded_rectangle((20, 18, 28, 35), radius=3, fill=DARK, outline=STEEL, width=2)
    d.rounded_rectangle((27, 21, 35, 36), radius=3, fill=DARK, outline=STEEL, width=2)
    d.rounded_rectangle((10, 22, 19, 36), radius=3, fill=DARK, outline=STEEL, width=2)
    d.rounded_rectangle((16, 30, 36, 44), radius=5, fill=DARK, outline=STEEL, width=2)
    d.line((17, 9, 18, 27), fill=JADE, width=2)
    d.line((23, 20, 24, 34), fill=JADE, width=1)
    d.line((31, 24, 31, 35), fill=JADE, width=1)
    return img


def cursor_wait():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    img.alpha_composite(glow_layer(ellipse=(11, 9, 37, 39), width=7))
    d = ImageDraw.Draw(img)
    d.ellipse((11, 9, 37, 39), outline=STEEL, width=3)
    d.arc((13, 11, 35, 37), 300, 85, fill=JADE, width=4)
    d.arc((13, 11, 35, 37), 120, 215, fill=CRIMSON, width=4)
    d.polygon([(34, 10), (42, 13), (36, 19)], fill=JADE)
    d.line((24, 14, 24, 25, 31, 31), fill=GOLD, width=2)
    d.ellipse((21, 22, 27, 28), fill=DARK, outline=STEEL)
    return img


assets = {
    'cursor_arrow.png': (cursor_arrow(), {'id': 'cursor_arrow', 'hotspot': [6, 4], 'usage': 'Input.CURSOR_ARROW'}),
    'cursor_hand.png': (cursor_hand(), {'id': 'cursor_hand', 'hotspot': [17, 9], 'usage': 'Input.CURSOR_POINTING_HAND'}),
    'cursor_wait.png': (cursor_wait(), {'id': 'cursor_wait', 'hotspot': [24, 24], 'usage': 'Input.CURSOR_WAIT'}),
}
for filename, (image, meta) in assets.items():
    meta.update({
        'style': 'bright cold wuxia UI, steel blue, jade glow, dark crimson accent',
        'size': [SIZE, SIZE],
        'generated_by': 'tools/generate_wuxia_cursors.py',
        'note': '像素级透明 PNG 光标，适合 Godot 自定义鼠标。'
    })
    save_all(filename, image, meta)
print('generated cursors:')
for path in sorted(OUT_GAME.glob('cursor_*.png')):
    print(path)
