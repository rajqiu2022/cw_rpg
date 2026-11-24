"""Root-approved same-path single-depth-flag successor; no production write."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
before=HERE/'art01_E261_before_EXACT.gd.source'
after=HERE/'art01_samepath_z_relative_CANDIDATE.gd.source'
a=before.read_bytes()
sha=lambda b:hashlib.sha256(b).hexdigest()
assert sha(a)=='e261426562db34f3edeb400b1c85e05e5a496ffb09995dd0e25bd2922a05f394'
old=b'_quad.z_as_relative=false;_quad.z_index=int(floor(FRONT/8.0));'
new=b'_quad.z_as_relative=true;_quad.z_index=int(floor(FRONT/8.0));'
assert a.count(old)==1
b=a.replace(old,new,1)
assert b.count(new)==1 and b.replace(new,old,1)==a
with after.open('xb') as stream:stream.write(b)
report={'schema':'ART01_SAMEPATH_SINGLE_DEPTH_FLAG_SUCCESSOR_V1','canonical_path':'res://build/luoyang_temple_adult_20261101d_art01/live_art_view.gd','before_backup':before.relative_to(ROOT).as_posix(),'before_sha256':sha(a),'before_bytes':len(a),'candidate':after.relative_to(ROOT).as_posix(),'after_sha256':sha(b),'after_bytes':len(b),'old_offset':a.index(old),'new_offset':b.index(new),'old':old.decode(),'new':new.decode(),'wholebyte_forward_inverse':True,'SELF_path_unchanged':True,'only_behavior_change':'same original parent-relative depth basis; world parent-100 preserved','production_writes':0,'engine_runs':0}
with (HERE/'samepath_singleline_proof_READY.json').open('x',encoding='utf-8',newline='\n') as stream:stream.write(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report))
