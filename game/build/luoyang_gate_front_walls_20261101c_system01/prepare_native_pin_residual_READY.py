"""Two explicit source-pin successors only. No engine or canonical writes."""
from pathlib import Path
import hashlib,json
TASK=Path(__file__).resolve().parent
GAME=TASK.parents[1]
OUT=TASK/'native_pin_residual01'
FIELD='res://scripts/field/field_walkable_controller.gd'
APPROVED_FIELD='1fc80d5ee11603e08aa562e516613444a8ae644d880c098fab6035f88628e614'
OLD_FIELD='15517292104b7e4d8695fd0eb5e6ff36b7a897d8119ce22997537fc62eae6eeb'
NATIVE='res://build/three_towns_world_20261029j_system01/native_sources.json'
OLD_NATIVE='0275ebab7f5c5df000d0e3182295813aad4572f3ca7a2882f05cb7cad2c7c47e'
REGISTRY='res://build/three_towns_world_20261029j_system01/town_registry.gd'
OLD_REGISTRY='9258a2975f5216151ebff2ad04dd6c9268226753fc328289af3f5b211a513964'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p.removeprefix('res://')).read_bytes()
def need(v,s):
 if not v:raise ValueError(s)
def replace_one(raw,old,new):
 old=old.encode();new=new.encode()
 need(raw.count(old)==1,'EXACT_ONE_OLD_LITERAL')
 child=raw.replace(old,new,1)
 need(child.count(new)==1 and child.replace(new,old,1)==raw,'WHOLE_BYTES_INVERSE')
 return child
need(sha(read(FIELD))==APPROVED_FIELD,'ROOT_APPROVED_FIXED_POST_WALL_FIELD_SHA')
native=read(NATIVE);registry=read(REGISTRY)
need(sha(native)==OLD_NATIVE and sha(registry)==OLD_REGISTRY,'EXACT_TWO_CURRENT_HEADS')
sources=json.loads(native)['sources'];need(len(sources)==228,'FIXED_228_SOURCE_SET')
diffs=[{'path':p,'expected':h,'actual':sha(read(p))}for p,h in sources.items()if sha(read(p))!=h]
need(diffs==[{'path':FIELD,'expected':OLD_FIELD,'actual':APPROVED_FIELD}],'ONLY_DECLARED_MAINFIELD_PIN_DIFF')
new_native=replace_one(native,'"'+FIELD+'": "'+OLD_FIELD+'"','"'+FIELD+'": "'+APPROVED_FIELD+'"')
next_sources=json.loads(new_native)['sources']
need(set(next_sources)==set(sources),'ALL_228_KEYS_IDENTICAL')
need(all(next_sources[p]==h for p,h in sources.items()if p!=FIELD),'OTHER_227_VALUES_IDENTICAL')
need(all(sha(read(p))==h for p,h in next_sources.items()),'ALL_228_CANDIDATE_PINS_MATCH_FIXED_ACTUAL_SOURCES')
new_registry=replace_one(registry,OLD_NATIVE,sha(new_native))
guard='static func source_valid() -> bool:'
need(new_registry.decode().split(guard,1)[1]==registry.decode().split(guard,1)[1],'WHOLE_GUARD_AND_REMAINING_ALGORITHMS_BYTE_IDENTICAL')
need(not OUT.exists(),'EXCLUSIVE_NEW_CANDIDATE_OUTPUT')
OUT.mkdir()
rows=[]
for path,name,before,after,reason in [(NATIVE,'native_sources_READY.json',native,new_native,'Advance only MainField source pin to explicitly approved 1FC80D5E; other 227 values and all 228 keys identical'),(REGISTRY,'town_registry_READY.gd',registry,new_registry,'Advance only NATIVE_SOURCE_SHA; complete source_valid guard and every subsequent function byte-identical')]:
 with (OUT/name).open('xb')as f:f.write(after)
 rows.append({'path':'game/'+path[6:],'candidate':'game/'+str((OUT/name).relative_to(GAME)).replace('\\','/'),'before_sha256':sha(before),'before_bytes':len(before),'after_sha256':sha(after),'after_bytes':len(after),'reason':reason})
report={'status':'ROOT_REVIEW_REQUIRED_NOT_AUTHORIZATION','old_target_deltas':rows,'native_source_diffs_before':diffs,'all_228_candidate_sources_match':True,'other_227_sources_and_all_keys_identical':True,'source_valid_guard_byte_identical':True,'complete_two_source_inverse':True,'no_other_owner_contract_updates_required':True,'C_B_EX_Router_World16_Region_updates':0,'canonical_writes':0,'engine_runs':0,'preserved_failed_run':'npc_gait_20261101c_joint02/actual/102424','residual_QA':'Call exact town_registry.source_valid once; no repeated World-to-Gate or town travel matrix'}
with (OUT/'proposed_old_target_deltas_READY.json').open('xb')as f:f.write((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'targets':2,'native_after':sha(new_native),'registry_after':sha(new_registry),'proposal_sha256':sha((OUT/'proposed_old_target_deltas_READY.json').read_bytes()),'canonical_writes':0}))
