"""Read-only full source-alpha scan; no image or source writes."""
from pathlib import Path
from PIL import Image
import json
base = Path('game/art/characters/weapon_variants/lengguyun/v7_idle_stable')
rows, union, frames = [], [160,160,0,0], 0
for path in sorted(base.rglob('*.png')):
    with Image.open(path) as image:
        assert image.height == 160 and image.width % 160 == 0, str(path)
        alpha = image.convert('RGBA').getchannel('A')
        for index in range(image.width//160):
            box = alpha.crop((index*160,0,(index+1)*160,160)).getbbox()
            if box:
                union = [min(union[0],box[0]),min(union[1],box[1]),max(union[2],box[2]),max(union[3],box[3])]
            frames += 1
        rows.append({'path':str(path),'size':[image.width,image.height]})
print(json.dumps({'png_count':len(rows),'frames':frames,'nonzero_alpha_union':union,'cell_size':[160,160], 'visual_scale':.945,'room_multiplier':1.18,'full_cell_bounds_world':[-89.208,-169.4952,178.416,178.416],'linear_half_texel_world':.55755,'conservative_world_envelope':[-90,-171,180,181],'rows':rows}))
