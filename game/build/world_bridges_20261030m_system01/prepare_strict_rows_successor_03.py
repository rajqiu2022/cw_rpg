"""Exactly three necessary source successors + one new canonical row proof.
No engine/formal writes. Preserve _matches_original and all geometry verbatim.
"""
from pathlib import Path
import difflib,hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def put(name,b):
 with (HERE/name).open('xb') as f:f.write(b)
def encoded(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [4,8,16,32,10000]:
  result=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in result):
   proof=a
   for r in result:proof=proof.replace(r['old'].encode(),r['new'].encode(),1)
   assert proof==b
   for r in reversed(result):proof=proof.replace(r['new'].encode(),r['old'].encode(),1)
   assert proof==a
   return result
 raise AssertionError('NO_UNIQUE_BYTE_HUNKS')
helper=HERE/'bridge_visual_patch.gd';stream=GAME/'scripts/world/world_v15_visible_stream_20261018r.gd';binding=GAME/'art/modules/world_bridges_20261030m/bridge_bindings.json'
old_helper=helper.read_bytes();old_stream=stream.read_bytes();old_binding=binding.read_bytes()
assert sha(old_helper)=='ef10cc93e67373f963fd459299a27adc89638491e607a6bdb100a687a9f21256'
assert sha(old_stream)=='bf465430c1bc74c93b39c917e05ed802751221ee32939fa16d6ac814873c2a65'
assert sha(old_binding)=='9a5a767a8a71c80b25d44d4630e2fa4d714a446141edc4aa8592435ca3f3082e'
rows=HERE/'bridge_source_rows_LAYOUT_TYPED_03_READY.json';row_sha=sha(rows.read_bytes())
assert row_sha=='dd1e58a5955803d6c351eb87833731174483688c135de6a4fc14309fe39bcfed'
proof=read(rows)['canonical_expectation_basis']
assert proof['checked_guard_fields']==1302 and len(proof['changes'])==8
assert all(r['field']=='depth_sort_foot_y' and r['difference_kind']=='EXACT_AUTHORED_FLOAT64_SERIALIZATION' for r in proof['changes'])
assert proof['layout_sha256']=='aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072'
new_helper=old_helper
old_sha=b'03fd46ccba6f268079810d9d94a0904cd1ad336e965069102e5c48ddf04a9df0'
assert new_helper.count(old_sha)==1;new_helper=new_helper.replace(old_sha,row_sha.encode(),1)
assert new_helper.count(b'bridge_source_rows_READY.json')==2
new_helper=new_helper.replace(b'bridge_source_rows_READY.json',rows.name.encode())
begin=b'static func _matches_original(';end=b'\nstatic func _import_valid('
assert old_helper[old_helper.index(begin):old_helper.index(end)]==new_helper[new_helper.index(begin):new_helper.index(end)]
binding_data=read(binding);binding_data['helper_sha256']=sha(new_helper)
new_binding=encoded(binding_data)
# Only one JSON key changes; every transform/import/source mask remains typed exact.
check=read(binding);check['helper_sha256']=sha(new_helper);assert check==binding_data
assert set(k for k in binding_data if binding_data[k]!=read(binding).get(k))=={'helper_sha256'}
assert old_stream.count(sha(old_binding).encode())==1
new_stream=old_stream.replace(sha(old_binding).encode(),sha(new_binding).encode(),1)
outputs=[(helper,old_helper,new_helper,'FINAL_03_helper_STRICT_ROWS_CANDIDATE.gd'),(binding,old_binding,new_binding,'FINAL_03_binding_STRICT_ROWS_CANDIDATE.json'),(stream,old_stream,new_stream,'FINAL_03_stream_STRICT_ROWS_CANDIDATE.gd')]
put('bridge_visual_patch_EF10.BEFORE_03.gd',old_helper)
targets=[]
for target,before,after,name in outputs:
 put(name,after)
 targets.append({'target':target.relative_to(GAME.parent).as_posix(),'candidate':'game/build/world_bridges_20261030m_system01/'+name,'old_sha256':sha(before),'new_sha256':sha(after),'bytes':len(after),'replacements':hunks(before,after),'whole_byte_inverse':True})
receipt={'schema_version':1,'status':'EXACT_CANONICAL_SOURCE_EVIDENCE_SUCCESSOR_CANDIDATE_NOT_ENGINE_RUN','targets':targets,'new_modules':{'game/build/world_bridges_20261030m_system01/'+rows.name:{'sha256':row_sha,'bytes':rows.stat().st_size}},'source_evidence_fields_checked':1302,'only_expected_value_changes':proof['changes'],'matches_original_logic_identical':True,'epsilon_added':False,'original_layout_original_JSON_inventory_unchanged':True,'budget_successor_BF465_preserved':True,'all_five_transforms_source_polygons_imports_typed_exact':True,'binding_changed_keys':['helper_sha256'],'stream_changed_only_binding_sha':True,'overlap_shader_unchanged':True,'scope':'THREE_NECESSARY_LEAVES_NO_ROUTER_NATIVE_REGISTRY_MANIFEST','Root_authorized_exact_TRES_expectations':True,'engine_runs':0,'canonical_writes':0,'save_access':False,'retained_failures':['world5_128880_75s_41checks1','startup02_134624_6checks1_INPUT_BRIDGE_ROW_post3']}
b=encoded(receipt);put('FINAL_03_strict_rows_receipt_CANDIDATE.json',b)
print(json.dumps({'receipt_sha256':sha(b),'bytes':len(b),'targets':[{k:r[k] for k in ['target','candidate','new_sha256','bytes']} for r in targets],'new_modules':receipt['new_modules'],'hunks':sum(len(r['replacements']) for r in targets)},ensure_ascii=False))
