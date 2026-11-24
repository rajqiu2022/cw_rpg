"""Read-only diagnostic crop with raw source coordinates; not a processed asset."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
p=ROOT/'assets/raw/luoyang_city_finish_20261025i/ordinary_kitchen_rear_body_v2.png'
im=Image.open(p).convert('RGBA');crop=im.crop((670,490,930,890))
preview=Image.alpha_composite(Image.new('RGBA',crop.size,(225,225,220,255)),crop).convert('RGB')
d=ImageDraw.Draw(preview)
for y in range(500,890,20):
    d.line([(0,y-490),(259,y-490)],fill=(0,140,160));d.text((2,y-488),str(y),fill=(0,0,0))
for x in range(680,930,40):
    d.line([(x-670,0),(x-670,399)],fill=(0,140,160));d.text((x-668,1),str(x),fill=(0,0,0))
with (OUT/'kitchen_door_raw_coordinates_DIAGNOSTIC.png').open('xb') as f:preview.save(f,format='PNG')
