"""Materialize approved Art data with exact padded pond coordinates; no PNG edits."""
from pathlib import Path
import json,hashlib,copy
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
art=GAME/'build/luoyang_estate_garden_20261029q_art01/garden_reuse_spec.json'
raw=art.read_bytes();a=json.loads(raw)
assets=copy.deepcopy(a['assets']);p=a['pond']
assets.append({'id':'garden29q_lotus_pond','texture':'res://art/modules/luoyang_estate_garden_20261029q/lotus_pond_v1.png','texture_size_px':[1792,1280],'anchor_px':[896,1066],'foot_px':[950,860],'scale':.46,'ground_polygons_px':[[[x+128,y+128]for x,y in p['raw_ground_polygon_px']]],'sort_by_feet':False,'z_index':-5})
routes=copy.deepcopy(a['garden_routes'])
for r in routes:
 r['texture_period_px']=[384,256]
 r['points']=[p for i,p in enumerate(r['points'])if i==0 or p!=r['points'][i-1]]
 # Keep the existing south peony bases on the inside of the path, not in its
 # walking center. Both circuits still join the original central axis.
 r['points']=[[x,1136 if y in (1096,1100)else y]for x,y in r['points']]
value={'schema':'ESTATE29Q_GARDEN_DELTA_V1','region_id':'luoyang_estate_region_27d','source_art_spec':str(art.relative_to(GAME.parent)).replace('\\','/'),'source_art_sha256':hashlib.sha256(raw).hexdigest(),'groundcover':a['groundcover'],'assets':assets,'existing_changes':[{'id':'estate_tree_nw','original_foot_px':[620,570],'new_foot_px':[580,340],'solid_index':2}],'garden_routes':routes,'routes':[{'id':r['id'],'points_px':r['points']}for r in routes]+[{'id':'rear_door_to_circuits','points_px':[[1536,1450],[1536,1256],[1536,1136]]},{'id':'west_30px_link','points_px':[[530,1256],[328,1256]]},{'id':'east_30px_link','points_px':[[2560,1256],[2744,1256]]}],'preserve_no_intrusion':a['preserve_no_intrusion']}
data=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
with (BASE/'garden_definition_READY.json').open('xb')as f:f.write(data)
print(json.dumps({'assets':len(assets),'definition_sha256':hashlib.sha256(data).hexdigest(),'png_writes':0,'canonical_writes':0}))
