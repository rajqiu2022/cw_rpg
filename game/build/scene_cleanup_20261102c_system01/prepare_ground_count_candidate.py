"""One exact-count consumer successor for the new real 40px ground strip."""
from pathlib import Path
import hashlib,json
TASK=Path(__file__).resolve().parent;GAME=TASK.parents[1]
path='res://build/luoyang_quality_20261101b_ground01/ground_visual.gd'
raw=(GAME/path[6:]).read_bytes()
old=b'"luoyang_civic_market_region_27d": 21,';new=b'"luoyang_civic_market_region_27d": 22,'
assert raw.count(old)==1
child=raw.replace(old,new,1);assert child.replace(new,old,1)==raw
candidate='res://build/scene_cleanup_20261102c_system01/ground_visual_READY.gd'
out=TASK/'ground_visual_READY.gd'
with out.open('xb')as f:f.write(child)
sha=lambda b:hashlib.sha256(b).hexdigest()
plan={'status':'EXACT_ONE_COUNT_SUCCESSOR_NOT_DEPLOYED','target':'game/'+path[6:],'candidate':'game/'+candidate[6:],'old_sha256':sha(raw),'old_bytes':len(raw),'new_sha256':sha(child),'bytes':len(child),'whole_inverse':True,'old':old.decode(),'new':new.decode(),'reason':'Published Civic has exactly 22 surfaces, original21 plus fixed real40px floor join; strict equality retained; no material,UV,sort or render logic changed.','SceneArt60_required_helper_pin_sha256':sha(child),'canonical_writes':0}
with (TASK/'ground_count_successor_READY.json').open('xb')as f:f.write((json.dumps(plan,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(plan))
