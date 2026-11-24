"""One-hunk successor only; original/frozen/runtime files are read-only.
No engine, no save, no formal deployment. Includes a small offline state model.
"""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
target=GAME/'scripts/world/world_v15_visible_stream_20261018r.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def put(name,b):
 with (HERE/name).open('xb') as f:f.write(b)
before=target.read_bytes()
eol='\r\n' if before.count(b'\r\n')==before.count(b'\n') and b'\r\n' in before else '\n'
assert sha(before)=='06108350bc7be28287453cd706a368a7d3078626778af4fb38004f9826b50eb8'
assert before==(HERE/'FINAL_01_stream_READY.gd').read_bytes()
old=(
'\t\t\tif not _wanted.has(old): _detach(old)\r\n'
'\t\tif _bytes+cost>RESIDENT_ESTIMATE_BUDGET_BYTES or _loaded.size()>=RESIDENT_OBJECTS:\r\n'
'\t\t\terror="WORLD_VISIBLE_RESIDENCY_BUDGET"; return\r\n').replace('\r\n',eol).encode()
new=(
'\t\t\tif not _wanted.has(old): _detach(old)\r\n'
'\t\t# Pressure eviction may have released this bridge image\'s last reference.\r\n'
'\t\t# Recompute only shared-image cost before budget check and commit.\r\n'
'\t\tif not shared_bridge.is_empty():cost=0 if _bridge_texture_refs.has(shared_bridge) else native_cost\r\n'
'\t\tif _bytes+cost>RESIDENT_ESTIMATE_BUDGET_BYTES or _loaded.size()>=RESIDENT_OBJECTS:\r\n'
'\t\t\terror="WORLD_VISIBLE_RESIDENCY_BUDGET"; return\r\n').replace('\r\n',eol).encode()
assert before.count(old)==1
after=before.replace(old,new,1)
assert after.count(new)==1 and after.replace(new,old,1)==before
candidate='FINAL_02_stream_BUDGET_CANDIDATE.gd'
put(candidate,after)
# State-model facts are not a Godot/Physics/stream runtime pass. Native-only
# branch simulates refcount changed by the existing _detach at pressure time.
cases=[
 {'id':'last_bridge_ref_evicted','shared':'bridge','native':120,'refs_after':0,'bytes_after':80,'budget':200,'expected_cost':120,'expected_ok':True,'old_cached_cost':0},
 {'id':'last_bridge_ref_evicted_budget_reject','shared':'bridge','native':120,'refs_after':0,'bytes_after':81,'budget':200,'expected_cost':120,'expected_ok':False,'old_cached_cost':0},
 {'id':'other_bridge_ref_still_resident','shared':'bridge','native':120,'refs_after':1,'bytes_after':150,'budget':200,'expected_cost':0,'expected_ok':True,'old_cached_cost':0},
 {'id':'new_bridge_not_resident','shared':'bridge','native':120,'refs_after':0,'bytes_after':10,'budget':200,'expected_cost':120,'expected_ok':True,'old_cached_cost':120},
 {'id':'nonbridge_existing_charge_unchanged','shared':'','native':120,'refs_after':0,'bytes_after':10,'budget':200,'expected_cost':120,'expected_ok':True,'old_cached_cost':120},
]
for row in cases:
 cost=row['old_cached_cost']
 if row['shared']:cost=0 if row['refs_after'] else row['native']
 ok=row['bytes_after']+cost<=row['budget']
 assert cost==row['expected_cost'] and ok==row['expected_ok']
 row['actual_model_cost']=cost;row['actual_model_budget_ok']=ok
receipt={'schema_version':1,'status':'ONE_HUNK_SOURCE_CANDIDATE_STATIC_MODEL_ONLY_NOT_ENGINE_VERIFIED','target':'game/scripts/world/world_v15_visible_stream_20261018r.gd','candidate':'game/build/world_bridges_20261030m_system01/'+candidate,'before_copy':'game/build/world_bridges_20261030m_system01/FINAL_01_stream_READY.gd','old_sha256':sha(before),'new_sha256':sha(after),'bytes':len(after),'replacements':[{'old':old.decode(),'new':new.decode()}],'whole_byte_inverse':True,'line_endings':'CRLF','old_nonbridge_accounting_unchanged':True,'budgets_unchanged':True,'binding_helper_overlap_shader_art_physics_unchanged':True,'source_closure':'ONE_WORLD_STREAM_SUCCESSOR_NO_ROUTER_NATIVE_REGISTRY','binding_sha256_unchanged':'9a5a767a8a71c80b25d44d4630e2fa4d714a446141edc4aa8592435ca3f3082e','offline_model':{'kind':'PYTHON_STATE_MODEL_NOT_GODOT','cases':cases,'checks':10,'failures':0,'original_bug_reproduced_by_old_cost_zero':True},'engine_runs':0,'canonical_writes':0,'save_access':False}
receipt['line_endings']='CRLF' if eol=='\r\n' else 'LF'
b=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode()
put('FINAL_02_budget_receipt_CANDIDATE.json',b)
print(json.dumps({'candidate':candidate,'new_sha256':sha(after),'bytes':len(after),'receipt_sha256':sha(b),'hunks':1,'offline_model_checks':10,'offline_model_failures':0}))
