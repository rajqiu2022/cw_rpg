"""Only missing immutable NG byte-count declarations + new Stage output root."""
from pathlib import Path
import json,hashlib,copy
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(n,b):
 p=P/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=R+n,sha256=sha(b),bytes=len(b))
bp=R+'unified28_candidates01/unified28_all_candidates_and_inverse_NOT_STAGE.json';oldb=(G/bp[6:]).read_bytes();assert sha(oldb)=='db48da89a35c3763748be77b3b71f2a591ed6aff1cda40908090cfaed06e54a9'
old=json.loads(oldb);new=copy.deepcopy(old);target='res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd'
r=new['records'][target]['candidate'];raw=(G/r['path'][6:]).read_bytes();assert sha(raw)==r['sha256']=='1d11051c4ed6f90d4555518449d496234efa032d0b43e33b5051e7b58fe0edc5'and len(raw)==14529 and 'bytes'not in r
r['bytes']=14529;row=next(t for t in new['targets']if t['target']==target);assert 'bytes'not in row['candidate'];row['candidate']['bytes']=14529
back=copy.deepcopy(new);del back['records'][target]['candidate']['bytes'];del next(t for t in back['targets']if t['target']==target)['candidate']['bytes'];assert enc(back)==oldb
bundle=out('NG_bytes_residual02/unified28_candidates_exact_bytes.json',enc(new))
ip=R+'source_input_service_garden_exact28_ROOT_REVIEW.json';oldi=(G/ip[6:]).read_bytes();assert sha(oldi)=='461a7185aab610066a0e20ed7bdf50ac82981d0cde01be40140c004c9ab8eb67'
original=json.loads(oldi);v=copy.deepcopy(original)
candidatepin=next(p for p in v['pinned_inputs']if p['id']=='candidates');assert candidatepin['path']==bp;candidatepin.update(path=bundle['path'],sha256=bundle['sha256'])
assert 'bytes'not in v['declared_candidates'][target];v['declared_candidates'][target]['bytes']=14529
v['output_root']=R+'outputs/root_services_garden_exact28_stage02/'
inverse=copy.deepcopy(v);inverse['pinned_inputs']=copy.deepcopy(original['pinned_inputs']);del inverse['declared_candidates'][target]['bytes'];inverse['output_root']=original['output_root'];assert enc(inverse)==oldi
inp=out('NG_bytes_residual02/source_input_ROOT_REVIEW.json',enc(v))
proof=out('NG_bytes_residual02/exact_missing_bytes_whole_inverse_NOT_STAGE.json',enc(dict(status='ONLY_NG_IMMUTABLE_BYTES_DECLARATION_REPAIR_NOT_EXECUTED',old_bundle=dict(path=bp,sha256=sha(oldb)),bundle=bundle,old_input=dict(path=ip,sha256=sha(oldi)),input=inp,driver=next(p for p in v['pinned_inputs']if p['id']=='driver'),changed_bundle_pointers=[['records',target,'candidate','bytes'],['targets','only matching NG row','candidate','bytes']],new_fixed_value=14529,whole_typed_serialized_inverse_bundle_and_input=True,all_candidate_bytes_and_SHA_unchanged=True,all_gates_and_driver_unchanged=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(input=inp,bundle=bundle,proof=proof,driver_unchanged=True)))
