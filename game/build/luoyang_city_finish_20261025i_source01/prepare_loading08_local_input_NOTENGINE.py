"""Only NEW frozen CPU input/self header preparation; never launches Godot."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
S='res://build/luoyang_city_finish_20261025i_source01/'
base=N/'docks_loading08_local01_NOTREADY'
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
oldspec=json.loads((N/'docks_gallery_retirement01/isolated_ROOT_READY02/input_ROOT_READY.json').read_bytes())
binding=json.loads((N/'docks_gallery_family_repair01/closure_READY01/finish8_binding_READY.json').read_bytes())
row=binding['scenes']['ch4_s2_canal_docks']
assert row['payload']['sha256']=='76577ebe4246926124973aba0adcd014226f4a1c2f3afede6837294ab969154d'
parent_author={'path':S+'author_adjacent_four_fields07_final_dry_bank_routes_NOTREADY.json','sha256':'fcbfa06b2347bf89e0c86cb4c7817be6781b6e574e01507e6098446afb419d20'}
author={'path':S+'author_adjacent_four_fields08_loading_clear_portal_NOTREADY.json','sha256':'faf779e271859b267d5ee05f8cf364320e8b2bf6acbc3866355ba4caca4ccfde'}
pins=[parent_author,author,row['payload'],row['mask']]
sources={p['path']:p['sha256']for p in pins}
data=dict(status='ROOT_REVIEW_ONE_NPC08_SOURCE_DELTA_FINITE_LOCAL_CPU_NOT_RUNTIME',ready=False,root_run_authorized=False,scene_id='ch4_s2_canal_docks',whole_budget_ms=20000,sources=sources,parent_author=parent_author,author=author,parent_payload=row['payload'],mask=row['mask'],save_absolute_paths=oldspec['save_absolute_paths'],output_root=S+'docks_loading08_local01_NOTREADY/output_NOTREADY/',limits=['No old geometry compilation/raster or full city route replay','All39 inherited solids include original office; only new NPC/packing approach queried','Source self-check, not independent QA or actual Field result','Root external guard retains exactticks; internal Godot facts are seconds only'])
p=base/'input_NOTREADY.json';assert not p.exists()
raw=enc(data)
with p.open('xb')as f:f.write(raw)
code=base/'publish_loading_delta_NOTREADY.gd';parent=code.read_bytes();needle=b'PENDING_INPUT_FREEZE';assert parent.count(needle)==1
# Mechanical first inputSHA fill, before this BUILD key has been handed off.
child=parent.replace(needle,sha(raw).encode())
assert child.replace(sha(raw).encode(),needle)==parent
print(json.dumps({'input':{'path':S+'docks_loading08_local01_NOTREADY/'+p.name,'sha256':sha(raw)},'code_pending_input_sha_fill':sha(raw),'code_unfilled_sha256':sha(parent),'save_paths':len(data['save_absolute_paths'])}))
