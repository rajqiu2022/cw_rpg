"""Bounded visual/layout successor; preserve the first native render and author."""
import json,shutil
from pathlib import Path
import bianzhou_city_remodel_20261022 as b

ROOT=b.ROOT;PARENT=b.BASE;BASE=PARENT/'revision2'
if BASE.exists():raise RuntimeError('Revision already exists; do not overwrite its evidence')
BASE.mkdir();(BASE/'artifacts').mkdir()
for name in ['media','originals']:shutil.copytree(PARENT/name,BASE/name)
for name in ['project.godot','preview.tscn','preview.gd','capture.gd','physics_check.gd']:shutil.copyfile(PARENT/name,BASE/name)
author=json.loads((PARENT/'author.json').read_text('utf-8'))
author['parent_author_sha256']=b.sha(PARENT/'author.json')
author['revision']='revision2'
author['changes']=['Remove the two cropped decorative north-wall objects and their paired solids','Move the south gate 215px north so the initial actor is visible south of it','Reduce existing earth texture tile scale .25 -> .08; no source pixels edited','Narrow the central paving from 460px to 360px, preserving both exits and all target points']
removed={'northwest_wall','northeast_corner'}
author['objects']=[o for o in author['objects'] if o['id'] not in removed]
author['solids']=[s for s in author['solids'] if s['owner'] not in removed]
gate=next(o for o in author['objects'] if o['id']=='south_market_gate')
gate['foot_px'][1]-=215;gate['origin_px'][1]-=215
gate['full_alpha_world_bbox'][1]-=215;gate['full_alpha_world_bbox'][3]-=215
for s in author['solids']:
    if s['owner']=='south_market_gate':s['rect'][1]-=215
author['terrain'][0]['tile_scale']=.08
author['terrain'][1]['rect']=[1370,36,360,1976]
b.BASE=BASE;b.dump(BASE/'author.json',author);b.make_navigation(author);b.verify(author)
b.dump(PARENT/'artifacts/visual-first-review.json',{'status':'NOT_ART_READY','image':'artifacts/overview.png','issues':['Two decorative north walls visibly clipped by the frame','Earth clods too large relative to actors','Gate overlaps the arrival view','Hard rectangular paving edges and sparse life remain','Cottage bright ground fringe remains source art and was not locally erased'],'successor':'revision2'})
print(str(BASE))
