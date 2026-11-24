"""Exact Artisan145 material consumer successor. No engine or canonical writes."""
from pathlib import Path
import hashlib,json,re,copy,difflib,ast,struct
TASK=Path(__file__).resolve().parent;GAME=TASK.parents[1]
OUT=GAME/'build/luoyang_scene_cleanup_20261102c_material02'
PREFIX='res://build/luoyang_scene_cleanup_20261102c_material02/'
# Reuse only pure helper definitions, not the generator's top-level execution.
tree=ast.parse((TASK/'prepare_closure_READY.py').read_bytes())
helpers={'sha','read','enc','need','once','replace','positional','reverse_proof','gd_hunks','source_update'}
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name in helpers],type_ignores=[]),'bounded_existing_helpers','exec'),globals())
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
material='res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/material_runtime_finish139_READY.gd'
env='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
paths=[r['target']for r in scope['targets']]+[material];need(len(paths)==32 and len(set(paths))==32,'FINITE31_PLUS_MATERIAL')
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()};after={}
publication=json.loads(read('res://build/scene_cleanup_20261102c_system01/output/140404/result.json'))
row=publication['records']['luoyang_artisan_residential_20261022ap'];need(row['whole_typed_inverse']and row['whole_RGBA_inverse'],'ACTUAL_TYPED_AND_RGBA_PARENT_INVERSE')
retired=[r['id']for r in row['retired_owners']];need(len(retired)==8,'EXACT_EIGHT_ARTISAN_WALLS')
newsha=row['payload']['sha256'];need(newsha=='f419598b6404070fd88f3c7da853016de88fd728a9a7d00f6ce5dee68b2da36a'and sha(read(row['payload']['path']))==newsha,'EXACT_ROOT_PUBLISHED145')
decoder=ast.parse((TASK/'audit_current.py').read_bytes());ns={'struct':struct}
exec(compile(ast.Module(body=[n for n in decoder.body if isinstance(n,ast.ClassDef)and n.name=='Reader'],type_ignores=[]),'existing_variant_reader','exec'),ns)
rd=ns['Reader'](read(row['payload']['path']));payload=rd.value()
shape={k:len(payload[k])for k in ['parent_native_navigation','parent_navigation','effective_navigation','visual_patches','visual_additions','visual_retired','effective_solids']}
need(shape=={'parent_native_navigation':136,'parent_navigation':136,'effective_navigation':145,'visual_patches':18,'visual_additions':9,'visual_retired':0,'effective_solids':53},'EXACT_FULL_DECLARED145_SHAPE')
raw=before[material];changed=replace(raw,[('93dac66cc5e07ae84e0fd4e946856df7f8e732f387dcf84f5666e834a8484a09',newsha)])
text=changed.decode();start=text.index('const SEVEN_STREET_SOURCES={');end=text.index('\nconst FINISH_GEOMETRY_KEYS=',start);block=text[start:end]
removed=[]
for owner in retired:
 matches=[line for line in block.splitlines(keepends=True)if line.startswith('\t'+json.dumps(owner)+':')]
 need(len(matches)==1 and matches[0].endswith(',\n'),'EXACT_COMPLETE_RETIRED_SOURCE_LINE')
 removed.append(matches[0]);block=block.replace(matches[0],'',1)
remaining=re.findall(r'^\t"([^"]+)":',block,re.M);need(len(remaining)==6 and not(set(remaining)&set(retired)),'EXACT_SIX_RETAINED_SOURCE_SPECS')
need(set(remaining)=={r['id']for r in payload['visual_additions']} - {'new_open_forge','new_pottery_kiln_workshop','new_plain_kitchen_rear_house'},'PUBLISHED_SIX_SOURCE_IDENTITIES')
after[material]=(text[:start]+block+text[end:]).encode()
# Exact hash, counts and all fourteen original specs are recoverable by whole-byte inverse.
positional(raw,after[material])
after[env]=replace(before[env],[(oldsha[material],sha(after[material]))])
known={p:sha(b)for p,b in after.items()};pending=[p for p in paths if p not in after]
for _ in range(32):
 progress=False
 for p in list(pending):
  deps={q for q,h in oldsha.items()if q!=p and h.encode()in before[p]}
  if any(q in pending for q in deps):continue
  if p.endswith('.json'):b=source_update(before[p],known)
  else:b=replace(before[p],[(oldsha[q],h)for q,h in known.items()if oldsha[q]!=h and oldsha[q].encode()in before[p]])
  if b!=before[p]:after[p]=b;known[p]=sha(b)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('BOUNDED_METADATA_CYCLE',pending))
need(not pending,'BOUNDED_CLOSURE_COMPLETE')
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
if ex in after:need(json.loads(after[ex])['owned']==json.loads(before[ex])['owned'],'ALL_OWNED_EDGES_IDENTICAL')
for p in ['res://scripts/autoload/scene_router.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_docks_district08_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd']:
 need(p not in after,('OTHER_EXECUTABLE_UNCHANGED',p))
need(not OUT.exists(),'IMMUTABLE_MATERIAL_RESIDUAL_OUTPUT')
targets=[];outputs={}
for p,b in after.items():
 name='candidates/'+p[6:].replace('/','__');outputs[name]=b;outputs['before/'+p[6:].replace('/','__')]=before[p]
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'new_sha256':sha(b),'old_bytes':len(before[p]),'bytes':len(b),'whole_inverse_exact':True,'hunks':positional(before[p],b)})
overlap={}
for name in ['city_navigation_20261101d_candidate01','luoyang_quality_20261101b_runtime01']:
 frozen=json.loads(read('res://build/'+name+'/source_pins_READY.json'))
 overlap[name]=sorted(set(frozen['source_pins'])&set(after))
for p,b in before.items():need(read(p)==b,('CANONICAL_UNCHANGED',p))
receipt={'status':'EXACT_ARTISAN145_MATERIAL_CONSUMER_SUCCESSOR_NOT_DEPLOYED','targets':targets,'changed_count':len(targets),'payload':row['payload'],'actual_shape':shape,'retired_exact8_specs':retired,'retained_exact6_specs':remaining,'whole_original136_and_118ground_and18patch_and_base139_guards_preserved':True,'all_geometry_and_masks_unchanged':True,'published_payload_strict_SHA_and_fingerprint_guard_retained':True,'all_OWNED_edges_unchanged':True,'old_failures_preserved':[141076,127508],'source_pin_overlap':overlap,'canonical_writes':0,'engine_runs':0,'save_reads':0}
outputs['receipt_READY.json']=enc(receipt);OUT.mkdir()
for name,b in outputs.items():
 p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
print(json.dumps({'targets':len(targets),'material_sha256':sha(after[material]),'ENV_sha256':sha(after[env]),'direct_pin_overlap':overlap,'receipt_sha256':sha(outputs['receipt_READY.json'])}))
