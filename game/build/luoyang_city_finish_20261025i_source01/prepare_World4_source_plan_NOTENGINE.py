"""Separate World ordinary visual atom: two old hooks plus two NEW files. No city authority."""
from pathlib import Path
import json,hashlib,re,copy
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/';A='res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04/';OUT=N/'world4_READY01';P=NS+OUT.name+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,h,sha(b));return b
def load(pin):return json.loads(read(pin['path'],pin['sha256']))
hp=dict(path=A+'world18_ROOT_TRIAL_source_handoff01.json',sha256='6eecf2f353d62646ec2160c382a885f3dca6247340f0a8155875d718bfdf3038');handoff=load(hp)
backup_pin=dict(path=NS+'world2_old_backup_ROOT_EXECUTED.json',sha256='73ad11107810e6abb5d61956e6e2bebc773c4e4af81e6dcfd6d53422149d729f');backup=load(backup_pin);assert backup['count']==2 and backup['canonical_writes']==0
assert handoff['approved']is True and len(handoff['54_actual_media'])==54
def rp(p):return 'res://'+Path(p).relative_to('game').as_posix()
targets=[];sources={};unchanged=dict(handoff['unchanged_source_pins'])
def add(p,h):
 assert p not in sources or sources[p]==h,(p,h,sources.get(p));sources[p]=h;read(p,h)
for row in handoff['two_hook_exact_parents_and_candidates']:
 target=rp(row['production_target']);br=next(r for r in backup['rows']if r['target']==target);old=read(target,row['old_sha256']);assert sha(Path(br['backup']).read_bytes())==row['old_sha256']==br['expected_sha256']and len(old)==br['bytes']
 path=rp(row['candidate']);new=read(path,row['candidate_sha256']);f,v=old.decode(),new.decode()
 for h in row['swaps']:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'])
 for h in reversed(row['swaps']):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'])
 assert f.encode()==new and v.encode()==old
 targets.append(dict(target=target,old_sha256=sha(old),parent_backup=br['backup'],candidate=dict(path=path,sha256=sha(new),bytes=len(new)),hunks=row['swaps'],kind='EXISTING_HOOK_EXACT_WHOLE_BYTE_INVERSE'))
for row in handoff['Root_ready_BUILD_outputs']:
 target=row['canonical_target'];assert not(G/target[6:]).exists(),('NEW_TARGET_NOT_ABSENT',target);raw=read(row['source'],row['sha256']);targets.append(dict(target=target,old_sha256='ABSENT',candidate=dict(path=row['source'],sha256=row['sha256'],bytes=len(raw)),kind='NEW_ROOT_TRIAL_APPROVED_ORDINARY_LEAF'))
assert len(targets)==4 and len({r['target']for r in targets})==4
manifest_pin=next(r['candidate']for r in targets if r['target']==handoff['canonical_approval']);manifest=load(manifest_pin);assert manifest['approved']is True and manifest['approved_by']=='root'and manifest['root_activation_pending']is True
module_pin=next(r['candidate']for r in targets if r['target']==handoff['canonical_module']);module=read(module_pin['path'],module_pin['sha256']).decode();assert module.count('const READY: bool=true')==1 and manifest_pin['sha256']in module
for key in ['CAPTURE','BRIDGE_REPORT','WATER_REPORT','SOURCE','STREAM']:
 path=re.search(r'const '+('CAPTURE_PATH'if key=='CAPTURE'else key)+r': String="([^"]+)"',module).group(1);h=re.search(r'const '+key+r'_SHA: String="([^"]+)"',module).group(1);add(path,h)
for row in handoff['54_actual_media']:add(row['path'],row['sha256']);assert len(read(row['path'],row['sha256']))==row['bytes']
for row in handoff['fixed_actual_artifact_sources']:
 # Historical false candidates are provenance, not current runtime authority.
 if row['path'].endswith(('actual_joint_export_compact_receipt.json','actual_joint18_import_compact_proof.json','world18_media54_promotion_ROOT_EXECUTED.json')):add(row['path'],row['sha256'])
for p,h in unchanged.items():add(p,h)
for row in manifest['entries']:add(row['old_path'],row['old_sha256'])
add(manifest['chunk']['old_path'],manifest['chunk']['old_sha256'])
for row in handoff['unchanged64walks']:unchanged[row['path']]=row['sha256']
for p,h in unchanged.items():read(p,h)
# Strong source map is fixed by handoff/export/import/Root trial, not actual World render observations.
expected=dict(sources)
for row in targets:expected[row['target']]=row['candidate']['sha256']
for p,h in [(hp['path'],hp['sha256']),(backup_pin['path'],backup_pin['sha256'])]:add(p,h)
plan=dict(status='SEPARATE_WORLD_EXACT4_PREPARED_NOT_STAGE_NOT_CITY_OWNED',handoff=hp,Root_two_backup=backup_pin,targets=targets,target_partition=dict(GD=3,JSON=1,total=4),ordinary_source_sha256=sources,expected_world_visual_source_sha256=expected,protected_unchanged=unchanged,media54_count=54,no_city_OWNED_or_execution_change=True,no_geometry_NAV_source_layout_stream_field_route_changes=True,trial_permission_not_result=True,actual_World_Field_pass=False,engine_calls=0,Stage_calls=0,canonical_writes=0)
assert not OUT.exists();OUT.mkdir();raw=enc(plan)
with(OUT/'world4_candidates_and_sources_ROOT_REVIEW.json').open('xb')as f:f.write(raw)
print(json.dumps(dict(path=P+'world4_candidates_and_sources_ROOT_REVIEW.json',sha256=sha(raw),targets=4,ordinary=len(sources),expected=len(expected),protected=len(unchanged))))
