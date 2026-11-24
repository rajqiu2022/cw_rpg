"""Only two new action-test near feet; do not replay old map connectivity checks."""
from pathlib import Path
import json

library=Path('F:/Code/RPG_GAME/game/build/adventure_20261030k_qa01/static_maps_READONLY.py')
text=library.read_text(encoding='utf-8');marker='parser=argparse.ArgumentParser()'
assert text.count(marker)==1
scope={};exec(compile(text[:text.index(marker)],str(library),'exec'),scope)
rows=[]
for key,site in [('forest',[1120,2050]),('mine',[1040,1680])]:
    doc=scope['tres']('res://data/maps/adventure_20261030k/'+key+'_layout.tres')['props'];size=doc['design_size'];mask=scope['Mask'](doc['walkable_mask_path'],size)
    options=[]
    for dx,dy in [(0,50),(0,-50),(50,0),(-50,0)]:
        foot=[site[0]+dx,site[1]+dy];body=[foot[0]-17.5,foot[1]-12.5,35,25];hits=[]
        for blocker in doc['blockers']:
            p=scope['vec'](blocker['pos'],size);s=scope['vec'](blocker['size'],size);rect=[p[0]-s[0]/2,p[1]-s[1]/2,*s]
            if scope['rect_hit'](body,rect):hits.append(blocker['id'])
        options.append({'actor_foot':foot,'distance_to_site':50,'full35x25_mask_clear':mask.whole(body),'physical_hits':hits,'clear':mask.whole(body) and not hits})
    rows.append({'map':key,'site_foot':site,'options':options})
print(json.dumps({'scope':'TWO_NEW_ACTION_TEST_ACTOR_FEET_ONLY_NOT_OLD_MAP_MATRIX','rows':rows,'engine_calls':0,'save_access':0,'source_writes':0},ensure_ascii=False,indent=2))
