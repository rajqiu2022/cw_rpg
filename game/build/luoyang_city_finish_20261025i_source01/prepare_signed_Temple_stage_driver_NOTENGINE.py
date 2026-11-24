"""Mechanical approved Stage driver successor. Only prepare/compile Python, never run Stage."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
p=N/'stage_visual_material_loading31_ROOT_ONLY.py';parent=p.read_bytes();assert hashlib.sha256(parent).hexdigest()=='a510b0496548f58d986fc0a47ad9879a3d4fa756ff15c9805d3445cbabafbfee'
t=parent.decode();changes=[]
def change(a,b):
 global t
 assert t.count(a)==1,(a,t.count(a));t=t.replace(a,b,1);changes.append(dict(old=a,new=b))
for a,b in [
 ('class VisualLoading31(M.Stage):','class TempleSigned31(M.Stage):'),
 ('ROOT_CURRENT_F67E_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_377B_FULL31_BACKUP_AND_FRESH_OBSERVATION'),
 ("self.backup['total_backups']==372","self.backup['total_backups']==403"),
 ('family_visual_material_loading_repair01/root_only_current31_backup/','temple_signed_iid_repair01/root_only_current31_backup/'),
 ("len(prior['source_sha256'])==206 and len(self.authority['source_sha256'])==212,'OWNED10_206_PLUS6'","len(prior['source_sha256'])==212 and len(self.authority['source_sha256'])==218,'OWNED10_212_PLUS6'"),
 ('ALL_OLD206_FIXED_SIX_NEW','ALL_OLD212_FIXED_SIX_NEW'),
 ('F67E_VISUAL_MATERIAL_LOADING_EXACT31_STAGED_NOT_DEPLOYED','CURRENT377B_SIGNED_TEMPLE_EXACT31_STAGED_NOT_DEPLOYED'),
 ('VisualLoading31(spec).run()','TempleSigned31(spec).run()'),
 ('Pinned F67E/6A56 current increment. Only strict Artisan139 material, original Garden water visual, exactEstate depth bootstrap and one loading NPC source row. Old206 evidence/all edges retained+6; F120 finite registered-edge traversal/visited unchanged. Router/native/geometry/masks unchanged. CT26/Temple196 exact prospective semantic pins.','Pinned377B/2B095 current increment. Only exactTemple signed raw IID domain in adapter/runtime; other functions and positive serial domains unchanged. BIND26B8/eight payloads/masks/NPCs/portals/allgeometry unchanged. Old212 evidence/all edges retained+6, F120 bounded registered-edge walk/visited unchanged. CT26/Temple196 all exact prospective values retained.'),
]:change(a,b)
back=t
for h in reversed(changes):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(t,'stage_signed_Temple31_ROOT_ONLY.py','exec')
sha=lambda b:hashlib.sha256(b).hexdigest();child=t.encode()
proof=dict(status='CURRENT377B_SIGNED_TEMPLE_ONLY_THIN_DRIVER_NOT_EXECUTED',parent=dict(path='res://build/luoyang_city_finish_20261025i_source01/'+p.name,sha256=sha(parent)),candidate_sha256=sha(child),changes=changes,whole_byte_inverse=True,all_five_gates_full_source_classes_peredge_inverse_and_CT26_Temple196_preserved=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
for name,b in [('stage_signed_Temple31_ROOT_ONLY.py',child),('temple_signed_iid_repair01/Stage31_driver_full_inverse_NOT_STAGE.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())]:
 dest=N/name
 with dest.open('xb')as stream:stream.write(b)
 print(name,sha(b),len(b))
