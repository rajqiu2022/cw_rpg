"""Non-destructive navigation QA crops of the adopted background."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
im = Image.open(ROOT / 'game/art/backgrounds/region_masters_v2/bg_world_map_jianghu_v8_2304.png').resize((1920,1280))
out = ROOT / 'assets/processed/scene/world_map_v8'
out.mkdir(parents=True, exist_ok=True)
grid=im.copy(); gd=ImageDraw.Draw(grid)
for x in range(0,1920,100):
    gd.line((x,0,x,1280),fill=(255,100,100),width=1)
for y in range(0,1280,100):
    gd.line((0,y,1920,y),fill=(255,100,100),width=1)
    for x in range(0,1920,100):
        gd.text((x+2,y+2),f'{x},{y}',fill='white',stroke_width=1,stroke_fill='black')
grid.save(out/'qa_grid.png')
for name, box in [('north',(640,100,1520,380)),('west',(160,180,840,640)),('south',(780,640,1740,1180)),('east',(1400,420,1910,820))]:
    crop = im.crop(box).resize(((box[2]-box[0])*2,(box[3]-box[1])*2))
    crop.save(out / f'qa_{name}.png')
