"""Mechanical NEW constructor successor: only final C header/path/SHA propagation."""
from pathlib import Path
import hashlib
HERE=Path(__file__).resolve().parent
old=(HERE/'prepare_layered_ordinary_C_AA_AC_candidates_BUILD.py').read_bytes()
text=old.decode()
a="OUT=HERE/'ordinary_layers01';OUT.mkdir(exist_ok=False);PREFIX=S+'ordinary_layers01/'"
b="OUT=HERE/'ordinary_layers02_READY';OUT.mkdir(exist_ok=False);PREFIX=S+'ordinary_layers02_READY/'"
assert text.count(a)==1;text=text.replace(a,b,1)
a="cr=sysproof['candidates']['C'];cbytes=read(cr['candidate_path'],cr['candidate_sha256']);cparent=read('res://build/luoyang_city_space_20261024b_source01/C_finite_packed_polygon_CANDIDATE.gd',cr['parent_sha256']);assert len(cr['replacements'])==3"
b="""cr=sysproof['candidates']['C']
cr['candidate_path']='res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/C_READY.gd'
cr['candidate_sha256']='f389b2e12e839d9005c3ac7643b69921ea31d9b7cc66d9194be0ab18c0d8b5d1'
for row in cr['replacements']:
    row['new']=row['new'].replace('res://build/luoyang_yamen_courts_20261024c_system01/runtime02/courts_session_NOTREADY.gd','res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/courts_session_READY.gd').replace('ab031d7c6f9630a91f2e2c8ba705d1eb753d3c5df04f7c421d8fcbd0ee70ed49','791ae73e97623e71c0a0445f7a60cd14b6bf8f17453e7fa77dd9d0a89a873c4a')
cbytes=read(cr['candidate_path'],cr['candidate_sha256']);cparent=read('res://build/luoyang_city_space_20261024b_source01/C_finite_packed_polygon_CANDIDATE.gd',cr['parent_sha256']);assert len(cr['replacements'])==3"""
assert text.count(a)==1;text=text.replace(a,b,1)
assert text.count('final_runtime_READY_SHA_propagation_pending=True')==1
text=text.replace('final_runtime_READY_SHA_propagation_pending=True','final_runtime_READY_SHA_propagation_pending=False',1)
compile(text,'prepare_final_ordinary_layers02_BUILD.py','exec')
p=HERE/'prepare_final_ordinary_layers02_BUILD.py'
with p.open('xb') as f:f.write(text.encode())
print(hashlib.sha256(p.read_bytes()).hexdigest())
