"""Diagnostic previews only: never modifies a source image or produces game media."""
from pathlib import Path
from PIL import Image, ImageDraw
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
source=ROOT/"game/art/modules/world_map_v13/bridge_stone_northsouth_v1.png"
im=Image.open(source).convert("RGBA")
bg=Image.new("RGBA",im.size,(96,96,96,255))
d=ImageDraw.Draw(bg)
for y in range(0,im.height,64):
    for x in range(0,im.width,64):
        if (x//64+y//64)%2:d.rectangle([x,y,x+63,y+63],fill=(130,130,130,255))
bg.alpha_composite(im)
d=ImageDraw.Draw(bg)
for x in range(0,1024,100):
    d.line([(x,0),(x,1536)],fill=(40,180,220,110),width=1)
    for y in (0,500,1000,1500):d.text((x+2,y),str(x),fill=(255,220,40))
for y in range(0,1536,100):
    d.line([(0,y),(1024,y)],fill=(40,180,220,110),width=1)
    d.text((5,y+2),str(y),fill=(255,220,40))
bg.convert("RGB").save(HERE/"ns_bridge_source_grid_DIAGNOSTIC.jpg",quality=94)
