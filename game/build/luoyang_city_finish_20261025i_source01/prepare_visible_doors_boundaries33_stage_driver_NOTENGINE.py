"""Mechanical current Stage successor. Compile Python only; never instantiate/run Stage."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
source=N/'stage_signed_Temple31_ROOT_ONLY.py'
old=source.read_bytes()
assert hashlib.sha256(old).hexdigest()=='c5b64d27b14f3a79936ae1fb1dbaf739b4dad9807cc0ab8e30904c34175125b8'
text=old.decode();changes=[]
def change(a,b):
    global text
    assert a in text,a
    changes.append(dict(old=a,new=b,count=text.count(a)))
    text=text.replace(a,b)
for a,b in [
    ('class TempleSigned31(M.Stage):','class VisibleDoors33(M.Stage):'),
    ('TempleSigned31(spec).run()','VisibleDoors33(spec).run()'),
    ("self.scope['count']==len(self.parents)==31 and self.scope['partition']==dict(GD=17,JSON=14)","self.scope['count']==len(self.parents)==33 and self.scope['partition']==dict(GD=18,JSON=15)"),
    ('EXACT31_17GD14JSON_SCOPE','EXACT33_18GD15JSON_SCOPE'),
    ('ROOT_CURRENT_377B_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_SIGNED31_FULL33_BACKUP_AND_FRESH_OBSERVATION'),
    ("self.backup['total_backups']==403","self.backup['total_backups']==436"),
    ('len(rows)==31','len(rows)==33'),
    ('temple_signed_iid_repair01/root_only_current31_backup/','visible_doors_boundaries33_repair01/root_only_current33_backup/'),
    ("len(prior['source_sha256'])==212 and len(self.authority['source_sha256'])==218,'OWNED10_212_PLUS6'","len(prior['source_sha256'])==218 and len(self.authority['source_sha256'])==224,'OWNED10_218_PLUS6'"),
    ('ALL_OLD212_FIXED_SIX_NEW','ALL_OLD218_FIXED_SIX_NEW'),
    ("len(self.targets)==31,'EXACT31_NO_NOOP_TARGETS'","len(self.targets)==33,'EXACT33_NO_NOOP_TARGETS'"),
    ("len(copies)==14 and len(reconstruction)==31,'EXACT17_GD_PATCH14_JSON_COPY'","len(copies)==15 and len(reconstruction)==33,'EXACT18_GD_PATCH15_JSON_COPY'"),
    ('target_count=14','target_count=15'),
    ('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=18,copy_count=15,total=33)'),
    ('targets=31,map_nodes=4','targets=33,map_nodes=4'),
    ('CURRENT377B_SIGNED_TEMPLE_EXACT31_STAGED_NOT_DEPLOYED','CURRENT_SIGNED31_VISIBLE_DOORS_BOUNDARIES_EXACT33_STAGED_NOT_DEPLOYED'),
    ('Pinned377B/2B095 current increment. Only exactTemple signed raw IID domain in adapter/runtime; other functions and positive serial domains unchanged. BIND26B8/eight payloads/masks/NPCs/portals/allgeometry unchanged. Old212 evidence/all edges retained+6, F120 bounded registered-edge walk/visited unchanged. CT26/Temple196 all exact prospective values retained.',
     'Pinned signed31/6400 current increment. Two Yamen boundaries and one promoted mask tuple; three finite source-derived visible Temple portal payloads; Estate/Temple source-bound door-depth children; existing cart-rut center only; one bell portrait tuple. Elder entire pair stays old. Original native storage/old masks/other geometry and NPC body/task/feet remain unchanged. Old218 values/all edges retained+6, OWNED10 and F120 bounded registered-edge walk/visited unchanged. CT26/Temple196 all exact prospective values retained.'),
]:change(a,b)
back=text
for h in reversed(changes):
    assert back.count(h['new'])==h['count'],h['new']
    back=back.replace(h['new'],h['old'])
assert back.encode()==old
compile(text,'stage_visible_doors_boundaries33_ROOT_ONLY.py','exec')
raw=text.encode();sha=lambda b:hashlib.sha256(b).hexdigest()
proof=dict(status='MECHANICAL_THIN_STAGE_DRIVER_NOT_EXECUTED',parent=dict(path='res://build/luoyang_city_finish_20261025i_source01/'+source.name,sha256=sha(old)),candidate_sha256=sha(raw),changes=changes,whole_byte_inverse=True,all_five_gates_source_classes_peredge_inverse_CT26_Temple196_unchanged=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
for path,b in [(N/'stage_visible_doors_boundaries33_ROOT_ONLY.py',raw),(N/'visible_doors_boundaries33_repair01/Stage33_driver_full_inverse_NOT_STAGE.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())]:
    assert not path.exists()
    with path.open('xb')as stream:stream.write(b)
    print(path.name,sha(b),len(b))
