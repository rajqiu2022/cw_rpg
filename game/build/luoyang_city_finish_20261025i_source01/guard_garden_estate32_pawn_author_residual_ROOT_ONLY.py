"""One-fact oracle correction. Inherits the original guard's other checks; no replay."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
ROOT=N.parents[2]
P=N/'garden_estate_exit_repair_20261027c01'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
 b=p.read_bytes();assert sha(b)==h,(str(p),sha(b));return json.loads(b)
def main():
 prior=load(P/'final_guard_ROOT_ACTUAL.json','3cc4d733a341b1c047fa9010403d9c7d63022c4aad42511c2f7afc53d3497e98')
 proof=load(N.parent/'luoyang_pawnshop_repair_20261026a_system01/three_files_direct_parent_whole_inverse_BUILD.json','a262558b30f63958d722ffc08303d942c67c07a5cbfb1a7ab820939f783122e5')
 row=next(r for r in proof['files']if r['label']=='author')
 path='res://build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json'
 fixed=dict(exists=True,sha256='44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e',bytes=80026)
 assert row['candidate']=='game/'+path[6:]and row['candidate_sha256']==fixed['sha256']and row['candidate_bytes']==fixed['bytes']
 assert prior['passed']is False and len(prior['differences'])==1
 old=prior['differences'][0]
 assert old['path']==path and old['group']=='pawn_author_unchanged'
 assert old['expected']==dict(fixed,bytes=19525)and old['current']==fixed
 p=ROOT/row['candidate'];a=p.stat();raw=p.read_bytes();b=p.stat()
 assert(a.st_size,a.st_mtime_ns)==(b.st_size,b.st_mtime_ns)
 current=dict(exists=True,sha256=sha(raw),bytes=len(raw));assert current==fixed
 report=dict(status='ROOT_GARDEN_ESTATE32_SINGLE_ORACLE_RESIDUAL_PASS',passed=True,prior_guard=dict(path='res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/final_guard_ROOT_ACTUAL.json',sha256='3cc4d733a341b1c047fa9010403d9c7d63022c4aad42511c2f7afc53d3497e98',original_passed=False,original_FAIL_preserved=True),fixed_source_proof_sha256='a262558b30f63958d722ffc08303d942c67c07a5cbfb1a7ab820939f783122e5',oracle_correction=dict(path=path,old_expected_bytes=19525,declared_expected_bytes=80026,current=current),inherited_unchanged_checks=prior['checked'],stage=prior['stage'],deployment=prior['deployment'],residual_files_checked=1,full_guard_replays=0,engine_calls=0,collector_calls=0,canonical_writes=0,save_writes=0)
 dest=P/'final_guard_pawn_author_residual_ROOT_ACTUAL.json';assert not dest.exists()
 data=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf8')
 with dest.open('xb')as f:f.write(data)
 print(json.dumps(dict(path=str(dest),sha256=sha(data),passed=True,residual_files_checked=1,full_guard_replays=0)))
if __name__=='__main__':main()
