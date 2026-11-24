"""Only finish the missing NEW owner recipe; preserve successful input/proof bytes."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
raw=(H/'review_finite09_actual_stage_and_prepare_owners_READY.py').read_bytes()
assert sha(raw)=='71716a6af5a4ca4f7deb7b79ad307b3f17b7fbb0efc270388e3e51fd0d049d44'
inp=(H/'finite09_input02_ROOT_LOCKED.json').read_bytes()
proofraw=(H/'finite09_tool_review/input02_real_map_order_proof_READY.json').read_bytes();proof=json.loads(proofraw)
assert proof['candidate_input']['sha256']==sha(inp) and proof['removed_total']==18
text=raw.decode()
for a,b,count in [('root_finite09_two_domain_stage01','root_finite09_two_domain_stage02',1),('finite09_input01_ROOT_LOCKED.json','finite09_input02_ROOT_LOCKED.json',1),('498fc80eeedb9e443631b3e01d196491acacda5101eadc15fe0b9f5cd22d21cb',sha(inp),1),('finite09_independent_review','finite09_stage02_independent_review',2)]:
 assert text.count(a)==count;text=text.replace(a,b)
p=H/'review_finite09_stage02_and_prepare_owners_READY.py';assert not p.exists()
with p.open('xb') as f:f.write(text.encode())
print(json.dumps({'input_path':S+'finite09_input02_ROOT_LOCKED.json','input_sha256':sha(inp),'proof_sha256':sha(proofraw),'owner_recipe_path':S+p.name,'owner_recipe_sha256':sha(text.encode()),'removed_total':18,'stage_runs':0}))
