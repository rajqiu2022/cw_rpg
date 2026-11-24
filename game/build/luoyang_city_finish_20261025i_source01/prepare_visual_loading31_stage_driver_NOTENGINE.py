"""Mechanical thin Stage31 successor, retaining full CT26/Temple196 semantic gates."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
p=N/'stage_culture_Router_pin24_ROOT_ONLY.py';parent=p.read_bytes();assert hashlib.sha256(parent).hexdigest()=='41904c4c3abd0fd774ecd2db04b60e597f549bc8d5aed9f153332fc45dfb6f83'
t=parent.decode();hunks=[]
def change(a,b):
 global t
 assert t.count(a)==1,(a,t.count(a));t=t.replace(a,b,1);hunks.append(dict(old=a,new=b))
for a,b in [
 ('class CulturePin24(M.Stage):','class VisualLoading31(M.Stage):'),
 ("self.scope['count']==len(self.parents)==24 and self.scope['partition']==dict(GD=10,JSON=14),'EXACT24_10GD14JSON_SCOPE'","self.scope['count']==len(self.parents)==31 and self.scope['partition']==dict(GD=17,JSON=14),'EXACT31_17GD14JSON_SCOPE'"),
 ('ROOT_CURRENT_D581_FULL24_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_F67E_FULL31_BACKUP_AND_FRESH_OBSERVATION'),
 ("self.backup['total_backups']==341","self.backup['total_backups']==372"),
 ("len(rows)==24 and {r['target']for r in rows}==set(self.parents)","len(rows)==31 and {r['target']for r in rows}==set(self.parents)"),
 ('culture_Router_pin_repair01/root_only_current24_backup/','family_visual_material_loading_repair01/root_only_current31_backup/'),
 ("len(prior['source_sha256'])==202 and len(self.authority['source_sha256'])==206,'OWNED10_202_PLUS4'","len(prior['source_sha256'])==206 and len(self.authority['source_sha256'])==212,'OWNED10_206_PLUS6'"),
 ("len(changed)==2,'ONLY_TWO_REAL_OWNED_EDGES'","len(changed)==4,'ONLY_FOUR_REAL_OWNED_EDGES'"),
 ('OTHER_EIGHT_OWNED_IDENTICAL','OTHER_SIX_OWNED_IDENTICAL'),
 ('len(extra)==4 and all','len(extra)==6 and all'),
 ('ALL_OLD202_FIXED_FOUR_NEW','ALL_OLD206_FIXED_SIX_NEW'),
 ("set(contract['changes'])=={'res://scripts/autoload/scene_router.gd'},'ONLY_CT_ROUTER_ONE_LITERAL'","set(contract['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd'},'ONLY_CT_C_FIELD_TWO_LITERALS_ROUTER_CURRENT_RETAINED'"),
 ("set(temple['changes'])=={'res://scripts/autoload/scene_router.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'},'TEMPLE_ONLY_ROUTER_CT_COORDINATOR_SOURCE_VALUES'","set(temple['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'},'TEMPLE_ONLY_C_FIELD_CT_COORDINATOR_ROUTER_CURRENT_RETAINED'"),
 ("len(self.targets)==24,'EXACT24_NO_NOOP_TARGETS'","len(self.targets)==31,'EXACT31_NO_NOOP_TARGETS'"),
 ("len(reconstruction)==24,'EXACT10_GD_PATCH14_JSON_COPY'","len(reconstruction)==31,'EXACT17_GD_PATCH14_JSON_COPY'"),
 ('CULTURE_ROUTER_EXACT24_STAGED_NOT_DEPLOYED','F67E_VISUAL_MATERIAL_LOADING_EXACT31_STAGED_NOT_DEPLOYED'),
 ('dict(patch_count=10,copy_count=14,total=24)','dict(patch_count=17,copy_count=14,total=31)'),
 ('targets=24,map_nodes=4','targets=31,map_nodes=4'),
 ('CulturePin24(spec).run()','VisualLoading31(spec).run()'),
 ('Pinned D581/CE3E exact current source counter increment only. All owned10/old202 values/edges preserved+4. CT full26 and Temple merged196 exact prospective source equality. No geometry/runtime/Router/Family/Field logic changes.','Pinned F67E/6A56 current increment. Only strict Artisan139 material, original Garden water visual, exactEstate depth bootstrap and one loading NPC source row. Old206 evidence/all edges retained+6; F120 finite registered-edge traversal/visited unchanged. Router/native/geometry/masks unchanged. CT26/Temple196 exact prospective semantic pins.'),
]:change(a,b)
back=t
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(t,'stage_visual_material_loading31_ROOT_ONLY.py','exec')
sha=lambda b:hashlib.sha256(b).hexdigest();child=t.encode()
proof=dict(status='F67E_NECESSARY_VISUAL_LOADING31_THIN_DRIVER_WHOLE_BYTE_INVERSE_NOT_STAGE',parent=dict(path='res://build/luoyang_city_finish_20261025i_source01/'+p.name,sha256=sha(parent)),candidate_sha256=sha(child),hunks=hunks,whole_byte_inverse=True,all_original_five_gates_source_classes_edge_checks_retained=True,CT26_and_Temple196_no_historical_fallback_retained=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
for name,b in [('stage_visual_material_loading31_ROOT_ONLY.py',child),('family_visual_material_loading_repair01/Stage31_driver_full_inverse_NOT_STAGE.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())]:
 dest=N/name;assert not dest.exists()
 with dest.open('xb')as f:f.write(b)
 print(name,sha(b),len(b))
