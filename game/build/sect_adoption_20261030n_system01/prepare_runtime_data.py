"""Read frozen geometry/business audit; write only new30n runtime data."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
source=GAME/'build/sect_adoption_20261030n_source01/business_geometry_READY.json'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(source)=='a95e8713086f8c9243bfded7ee7458cd06448fec7b9731e0c1d80f72bb3de32d'
audit=json.loads(source.read_text(encoding='utf-8-sig'))
specs=[('wudang','openworld_wudang_gate','武当派','res://scenes/drafts/sect_maps_20261029k/wudang.tscn','res://art/modules/sect_maps_20261029k/wudang.json',[5200,4400],'openworld_wudang_taiji_court',[.5,.205],'return_world','to_wudang_taiji_court',[.11393229,.6820928]),('huashan','openworld_huashan_forecourt','华山派','res://scenes/drafts/huashan_map_20261029m/huashan.tscn','res://art/modules/huashan_map_20261029m/huashan.json',[5800,5000],'openworld_huashan_sword_terrace',[.5,.225],'huashan_leave_gate','huashan_to_sword_terrace',[.056966145,.26887628])]
towns={}
for key,id,label,scene,layout,size,inner,old_return,leave_id,inner_id,world_uv in specs:
 points=audit['native_points'][key];terrain=audit['native_topology'][key]
 source_scene=next(r for r in audit['original_scenes'] if r['id']==id)
 towns[id]={'key':key,'id':id,'label':label,'scene':scene,'native_layout':layout,'size':size,'arrival':points['arrival']['foot'],'leave_arrow':points['leave_arrow']['foot'],'inner_arrow':points['inner_arrow']['foot'],'inner_return':points['inner_return']['foot'],'inner_source':inner,'old_inner_return_uv':old_return,'world_uv':world_uv,'world_portal_id':key,'portal_feet':{leave_id:points['leave_arrow']['foot'],inner_id:points['inner_arrow']['foot']},'npc_feet':{'wudang_gate_disciple':points['wudang_gate_disciple']['foot']} if key=='wudang' else {},'original_npcs':source_scene['npc_rows'],'original_portals':source_scene['portals'],'original_interactions':source_scene['interactions'],'original_hotspots':source_scene['hotspots'],'terrain':terrain,'solids':audit['native_collider_polygons'][key],'base_outline':terrain.get('base_outline',[[110,110],[size[0]-110,110],[size[0]-110,size[1]-110],[110,size[1]-110]]),'route':audit['routes'][key]['polyline'],'negative':audit['house_body_negative_controls'][key]}
out=HERE/'adoption_data.json'
assert not out.exists()
data={'schema_version':1,'layout_version':3005,'scope':'ONLY_TWO_EXISTING_WORLD_OUTDOOR_IDS; ORIGINAL_INNER_MAPS_UNCHANGED','geometry_proof':{'path':source.relative_to(GAME.parent).as_posix(),'sha256':sha(source),'not_engine_or_Physics':True},'towns':towns}
b=(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps({'path':str(out),'sha256':sha(out),'bytes':len(b),'towns':list(towns)}))
