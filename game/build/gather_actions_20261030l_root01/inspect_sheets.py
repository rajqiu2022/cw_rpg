from PIL import Image
from pathlib import Path
import json, hashlib
base=Path('F:/Code/RPG_GAME')
rows=[]
for name in ['gather_herb_right_4f','mine_ore_right_4f']:
    path=base/'assets/raw/gather_actions_20261030l'/f'{name}.png'
    im=Image.open(path).convert('RGBA'); w,h=im.size
    cells=[]
    for i in range(4):
        # Inspection only. No source or processed image is written.
        a=im.getchannel('A').crop((i*w//4,0,(i+1)*w//4,h))
        core=a.point(lambda n:255 if n>=128 else 0)
        box=core.getbbox(); bottoms=[]
        if box:
            for y in range(box[3]-12,box[3]):
                xs=[x for x in range(w//4) if a.getpixel((x,y))>=128]
                if xs:bottoms.append([y,min(xs),max(xs)])
        cells.append({'index':i,'alpha_any_bbox':a.getbbox(),'core128_bbox':box,'last12row_extents':bottoms,'alpha_extrema':a.getextrema()})
    rows.append({'name':name,'size':[w,h],'mode':im.mode,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'frames':cells})
out=base/'game/build/gather_actions_20261030l_root01/sheets_inspect_ACTUAL.json'
out.write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows))
