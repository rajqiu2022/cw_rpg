"""Only correct proof prose count (8 scenes minus4 changed =4); candidates same."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent/'finite10_yamen_classification'
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite10_yamen_classification/'
def sha(b):return hashlib.sha256(b).hexdigest()
raw=(H/'four_leaf_classification_and_two_owner_headers_proof_READY.json').read_bytes()
assert sha(raw)=='7524c053bd2ca29e94acabb376823207d0c39be12cb79756d1b633fc056b7d58'
v=json.loads(raw);assert v.pop('all_other_five_scenes_and_five_rooms_unchanged') is True
v['all_other_four_scenes_and_five_rooms_unchanged']=True
v['proof_descriptor_successor']='Only corrects an incorrect prose count; ten source-map value deltas, actual8 scene/5room structures and both production candidates are unchanged. Original7524 proof preserved.'
b=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
name='four_leaf_classification_and_two_owner_headers_proof02_READY.json'
with (H/name).open('xb') as f:f.write(b)
rawhand=(H/'handoff_CANDIDATES_READY_NOT_DEPLOYED.json').read_bytes()
assert sha(rawhand)=='065071bf7e57ea95298ca32a516cef014be3478046e75f64864c40d0f70c5abd'
h=json.loads(rawhand);h['proof']={'path':S+name,'sha256':sha(b),'bytes':len(b)}
out=(json.dumps(h,ensure_ascii=False,indent=2)+'\n').encode();hn='handoff02_CANDIDATES_READY_NOT_DEPLOYED.json'
with (H/hn).open('xb') as f:f.write(out)
print(json.dumps({'handoff_path':S+hn,'handoff_sha256':sha(out),'proof_sha256':sha(b),'candidates_unchanged':True}))
