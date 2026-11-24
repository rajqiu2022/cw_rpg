"""One new outside-range test setup foot only; no old route matrix."""
from pathlib import Path
import json
library=Path('F:/Code/RPG_GAME/game/build/adventure_20261030k_qa01/static_maps_READONLY.py')
text=library.read_text(encoding='utf-8'); marker='parser=argparse.ArgumentParser()'; assert text.count(marker)==1
scope={};exec(compile(text[:text.index(marker)],str(library),'exec'),scope)
doc=scope['tres']('res://data/maps/adventure_20261030k/forest_layout.tres')['props'];size=doc['design_size']
mask=scope['Mask'](doc['walkable_mask_path'],size);body=[1102.5,2127.5,35,25];hits=[]
for blocker in doc['blockers']:
    p=scope['vec'](blocker['pos'],size);s=scope['vec'](blocker['size'],size)
    if scope['rect_hit'](body,[p[0]-s[0]/2,p[1]-s[1]/2,*s]):hits.append(blocker['id'])
print(json.dumps({'foot':[1120,2140],'distance_to_site':90,'whole35x25_mask_clear':mask.whole(body),'physical_hits':hits,'passed':mask.whole(body) and not hits,'engine_calls':0,'save_access':0,'production_writes':0}))
