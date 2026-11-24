"""Read-only source-coordinate bay crops; not processed game assets."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
for ident,box in [('pottery_kiln_house_v2',(390,490,790,880)),('chinese_open_ironwork_v2',(170,410,940,830))]:
    source=Image.open(ROOT/f'assets/raw/luoyang_city_finish_20261025i/{ident}.png').convert('RGBA')
    crop=source.crop(box);im=Image.alpha_composite(Image.new('RGBA',crop.size,(225,225,220,255)),crop).convert('RGB');d=ImageDraw.Draw(im)
    x0,y0,x1,y1=box
    for y in range((y0//20+1)*20,y1,20):
        d.line([(0,y-y0),(x1-x0-1,y-y0)],fill=(0,140,160));d.text((2,y-y0+2),str(y),fill=(255,255,255))
    for x in range((x0//40+1)*40,x1,40):
        d.line([(x-x0,0),(x-x0,y1-y0-1)],fill=(0,140,160));d.text((x-x0+2,2),str(x),fill=(255,255,255))
    with (OUT/f'{ident}_bay_raw_coordinates_DIAGNOSTIC.png').open('xb') as f:im.save(f,format='PNG')
