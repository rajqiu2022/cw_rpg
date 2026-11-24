from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).with_name("existing_shore_assets_review_preview.png")

FIELD = ROOT / "game/build/luoyang_docks08_formal_field_20261019ab/113316/ordinary_docks08_default_after32px.png"
SOURCES = [
    (
        "REUSE: existing dry wharf + 2 mooring posts",
        ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/entities/dry_loading_wharf.png",
    ),
    (
        "REJECT: 54x25 flat quest mud marker",
        ROOT / "game/art/maps/luoyang_modular_v3/ch4_s2_canal_docks/entities/native_mud_trace.png",
    ),
    (
        "REJECT AS BOLLARD: 30x340 quay rail segment",
        ROOT / "game/art/maps/luoyang_modular_v3/ch4_s2_canal_docks/entities/native_quay_rail.png",
    ),
]


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
    image = Image.new("RGBA", size, (55, 59, 63, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(82, 87, 92, 255))
    return image


canvas = Image.new("RGB", (1600, 900), (23, 27, 31))
draw = ImageDraw.Draw(canvas)
font = ImageFont.load_default()

field = Image.open(FIELD).convert("RGB")
field.thumbnail((1040, 820), Image.Resampling.LANCZOS)
canvas.paste(field, (20, 50))
draw.text((20, 20), "ACTUAL DOCKS REFERENCE - hard straight shore, current boats, no wet gradient / tie line", fill=(230, 235, 240), font=font)

panel_x = 1090
panel_w = 490
panel_h = 250
for index, (label, path) in enumerate(SOURCES):
    top = 30 + index * 285
    panel = checker((panel_w, panel_h))
    source = Image.open(path).convert("RGBA")
    maximum = (430, 190)
    scale = min(maximum[0] / source.width, maximum[1] / source.height)
    if source.width <= 128 and source.height <= 384:
        scale = max(1.0, min(scale, 6.0))
        resized = source.resize((max(1, round(source.width * scale)), max(1, round(source.height * scale))), Image.Resampling.NEAREST)
    else:
        resized = source.resize((max(1, round(source.width * scale)), max(1, round(source.height * scale))), Image.Resampling.LANCZOS)
    x = (panel_w - resized.width) // 2
    y = 42 + (panel_h - 52 - resized.height) // 2
    panel.alpha_composite(resized, (x, y))
    pd = ImageDraw.Draw(panel)
    pd.rectangle((0, 0, panel_w - 1, 31), fill=(15, 18, 21, 235))
    pd.text((10, 10), label, fill=(240, 240, 235), font=font)
    canvas.paste(panel.convert("RGB"), (panel_x, top))

canvas.save(OUT, format="PNG", optimize=False)
print(OUT)
