"""Bounded mechanical reuse of the existing exact31 source domain; no engine/formal writes."""
from pathlib import Path
import hashlib,json,re,copy,difflib,argparse
parser=argparse.ArgumentParser()
parser.add_argument("--publication",required=True,help="res:// path of Root actual publisher result")
args=parser.parse_args()
GAME=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent/'closure_READY01'
PREFIX='res://build/luoyang_gate_front_walls_20261101c_system01/closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):
 path=GAME/p.removeprefix('res://')
 if not path.exists():
  path=GAME/'build/luoyang_gate_front_walls_20261101c_system01/mask_import_ROOT'/p[6:]
 return path.read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def need(v,s):
 if not v:raise ValueError(s)
def put(name,b):
 p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return PREFIX+name
def once(b,o,n):
 o=o.encode()if isinstance(o,str)else o;n=n.encode()if isinstance(n,str)else n
 need(b.count(o)==1,('NONUNIQUE',o[:120],b.count(o)));return b.replace(o,n,1)
def replace_literals(raw,replacements):
 result=raw
 for old,new in replacements:result=once(result,old,new)
 inverse=result
 for old,new in reversed(replacements):inverse=once(inverse,new,old)
 need(inverse==raw,'WHOLE_LITERAL_INVERSE');return result
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
paths=[r['target']for r in scope['targets']]
oldroot='res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/'
old_runtime=oldroot+'finish8_runtime_READY.gd';old_material=oldroot+'material_runtime_finish139_READY.gd'
paths += [old_runtime,old_material]
need(len(paths)==33,'BOUNDED_33_POTENTIAL_DOMAIN')
region='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
region_value=json.loads(read(region))
pins=json.loads(read('res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'))['source_pins']
need(len(pins)==60,'11B60_EXACT_PINS')
protected={p:h for p,h in pins.items() if p!='res://project.godot'}
protected[region]='af1bb975b0603e2d735890ff89fa60c8e2100ccb0a7565fc1211ca1794d866be'
protected['res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json']=sha(read('res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'))
for row in region_value['compiled_bindings'].values():protected[row['path']]=row['sha256']
need(not set(paths)&set(protected),'NO_REGION_OR_11B_TARGET_OVERLAP')
need(not set(paths)&set(region_value['runtime_modules']),'NO_REGION_RUNTIME_MODULE_OVERLAP')
for p,h in protected.items():need(sha(read(p))==h,('PROTECTED_FIRST',p))
for row in region_value['compiled_bindings'].values():
 data=read(row['path'])
 for p in paths:need(p.encode()not in data,('NO_COMPILED_SOURCE_KEY',row['path'],p))
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()};after={};outputs={};hunks={}
def new(name,b):outputs[name]=b;return PREFIX+name,sha(b)
oldroot='res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/'
old_runtime=oldroot+'finish8_runtime_READY.gd';old_binding=oldroot+'finish8_binding_READY.json';old_material=oldroot+'material_runtime_finish139_READY.gd'
publication_path=args.publication
need(publication_path.startswith('res://build/luoyang_gate_front_walls_20261101c_system01/output/'),'CURRENT_PUBLICATION_DOMAIN')
pub=json.loads(read(publication_path))
need(pub['passed'] and pub['whole_payload_inverse'] and pub['whole_RGBA_inverse'],'ROOT_ACTUAL_PUBLICATION_REQUIRED')
need(pub['removed_ids']==['seven26c_gate_west_waiting_front','seven26c_gate_east_transfer_front'],'EXACT_TWO_APPROVED_IDS')
need(pub['source_first']==pub['source_final'],'PUBLICATION_FIRST_FINAL')
mask=pub['mask'];sidecar=mask['path']+'.import'
compiled=re.search(r'^path="([^"]+)"',read(sidecar).decode(),re.M).group(1)
need(sha(read(mask['path']))==mask['sha256'],'ACTUAL_NAV_PNG')
need(read(sidecar)and read(compiled),'ROOT_TARGETED_IMPORT_REQUIRED')
binding=json.loads(read(old_binding));original_binding=copy.deepcopy(binding);gate=binding['scenes']['ch4_s0_luoyang_gate']
gate['payload']=pub['payload'];gate['mask']={**mask,'kind':'IMPORTED_RGBA8','import_path':sidecar,'compiled_path':compiled}
gate['publication_completion']={'path':publication_path,'sha256':sha(read(publication_path))};gate['fingerprints']=pub['fingerprints']
for p in [pub['payload']['path'],mask['path'],publication_path,sidecar,compiled]:gate['required_source_sha256'][p]=sha(read(p))
for id in binding['scenes']:
 if id!='ch4_s0_luoyang_gate':need(binding['scenes'][id]==original_binding['scenes'][id],'OTHER_SEVEN_BINDING_ROWS_IDENTICAL')
bind_path,bind_sha=new('finish8_binding_READY.json',enc(binding))
runtime=replace_literals(read(old_runtime),[(old_binding,bind_path),(sha(read(old_binding)),bind_sha)])
runtime_snapshot,runtime_sha=new('finish8_runtime_READY.gd',runtime)
after[old_runtime]=runtime
runtime_path=old_runtime
material=replace_literals(read(old_material),[(sha(read(old_runtime)),runtime_sha),(old_binding,bind_path),(sha(read(old_binding)),bind_sha)])
material_snapshot,material_sha=new('material_runtime_finish139_READY.gd',material)
after[old_material]=material
six=['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_estate_family_20261021am.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd']
for p in six:
 changes=[(sha(read(old_runtime)),runtime_sha)]
 if 'environment_layer' in p:changes.append((sha(read(old_material)),material_sha))
 after[p]=replace_literals(before[p],changes)
ct='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
coord='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';c=six[1]
field=six[0]
ct_changes=[]
ct_parent=json.loads(before[ct])
for p in [field,c]:ct_changes.append(('"'+p+'": "'+ct_parent['source_sha256'][p]+'"','"'+p+'": "'+sha(after[p])+'"'))
after[ct]=replace_literals(before[ct],ct_changes)
after[coord]=replace_literals(before[coord],[(oldsha[ct],sha(after[ct]))])
need(b'(path != "res://scripts/autoload/scene_router.gd" and path != FIELD) or not AP_NPC._source_matches' in after[coord],'PRESERVE_CURRENT_ROUTER_AND_FIELD_ADMISSION')
def gd_hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);matches=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op=='equal':continue
  start=max(0,i-1);end=min(len(aa),j+1);left=''.join(aa[start:end]);right=''.join(aa[start:i])+''.join(bb[k:l])+''.join(aa[j:end]);matches.append({'old':left,'new':right})
 test=a
 for h in matches:test=once(test,h['old'],h['new'])
 need(test==b,'GD_HUNKS_WHOLE_FORWARD')
 return matches

def positional_hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);rows=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op=='equal':continue
  rows.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 forward=a
 for row in reversed(rows):
  at=row['old_offset'];old=row['old'].encode();new=row['new'].encode()
  need(forward[at:at+len(old)]==old,'POSITIONAL_FORWARD_EXACT_SLICE')
  forward=forward[:at]+new+forward[at+len(old):]
 need(forward==b,'POSITIONAL_WHOLE_FORWARD')
 inverse=b
 for row in reversed(rows):
  at=row['new_offset'];old=row['old'].encode();new=row['new'].encode()
  need(inverse[at:at+len(new)]==new,'POSITIONAL_INVERSE_EXACT_SLICE')
  inverse=inverse[:at]+old+inverse[at+len(new):]
 need(inverse==a,'POSITIONAL_WHOLE_INVERSE')
 return rows
def source_update(raw,known,additions=None):
 value=json.loads(raw);changed=[]
 def walk(node):
  if isinstance(node,dict):
   for key,m in node.items():
    if key in ('source_sha256','legacy_source_sha256','runtime_authority_sha256')and isinstance(m,dict):
     for p,h in list(m.items()):
      if p in known and p in oldsha and h==oldsha[p]:
       m[p]=known[p];changed.append(('"'+p+'": "'+h+'"','"'+p+'": "'+known[p]+'"'))
    else:walk(m)
  elif isinstance(node,list):
   for item in node:walk(item)
 walk(value)
 result=raw
 for old,new_value in dict(changed).items():
  need(result.count(old.encode())>=1,'SOURCE_LITERAL_EXISTS');result=result.replace(old.encode(),new_value.encode())
 if additions:
  text=result.decode();key='legacy_source_sha256'if 'legacy_source_sha256'in value else 'source_sha256'
  need(key in value,'TOP_SOURCE_MAP_REQUIRED')
  marker='  "'+key+'": {';start=text.index(marker);end=text.index('\n  }',start)
  insert=''
  for p,h in additions.items():
   if p in value[key]:need(value[key][p]==h,'NEW_PIN_CONFLICT');continue
   insert+=',\n    '+json.dumps(p)+': '+json.dumps(h)
  text=text[:end]+insert+text[end:];result=text.encode()
 return result
# AA/AC historical ordinary layers and Temple native binding stay unchanged.

ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
authority=json.loads(before[ex]);ex_text=before[ex].decode();owned_changed=[]
for p in list(after):
 if p not in authority['owned']:continue
 owned_changed.append(p);row=authority['owned'][p];need(row['current_sha256']==oldsha[p],'CURRENT_OWNED_PARENT')
 candidate=PREFIX+Path(p).name;new(candidate.removeprefix(PREFIX),after[p]);h=gd_hunks(before[p],after[p]);hunks[p]=h
 old_snapshot=next(e['new_snapshot']for e in reversed(row['edges'])if e['new_sha256']==oldsha[p])
 need(sha(read(old_snapshot))==oldsha[p],'IMMUTABLE_OWNED_PREDECESSOR')
 row['current_sha256']=sha(after[p]);row['edges'].append({'path':p,'old_sha256':oldsha[p],'new_sha256':sha(after[p]),'old_snapshot':old_snapshot,'new_snapshot':candidate,'whole_inverse':True,'replacements':h})
 authority['source_sha256'][candidate]=sha(after[p])
 # Preserve all old serialization outside this one owned-row envelope.
 marker='    "'+p+'": {';start=ex_text.index(marker);value_start=start+len('    "'+p+'": ');_,used=json.JSONDecoder().raw_decode(ex_text[value_start:]);end=value_start+used
 replacement=json.dumps(row,ensure_ascii=False,indent=2).splitlines();formatted='    '+json.dumps(p)+': '+replacement[0]+'\n'+'\n'.join('    '+s for s in replacement[1:])
 ex_text=ex_text[:start]+formatted+ex_text[end:]
extra={p:sha(v)for name,v in outputs.items()for p in [PREFIX+name]}
for p in [publication_path,pub['payload']['path'],mask['path'],sidecar,compiled]:extra[p]=sha(read(p))
ex_text=source_update(ex_text.encode(),{p:sha(v)for p,v in after.items()}).decode()
old_ex=json.loads(before[ex]);new_keys={p:h for p,h in extra.items()if p not in old_ex['source_sha256']}
start=ex_text.index('  "source_sha256": {');end=ex_text.index('\n  }',start)
ex_text=ex_text[:end]+''.join(',\n    '+json.dumps(p)+': '+json.dumps(h)for p,h in new_keys.items())+ex_text[end:]
after[ex]=ex_text.encode();after[ei]=replace_literals(before[ei],[(oldsha[ex],sha(after[ex]))])
known={p:sha(b)for p,b in after.items()}
pending=[p for p in paths if p not in after]
# Reuse the old31 explicit dependency order: metadata pins then their existing indices.
def dependencies(p):
 raw=before[p]
 return {q for q,h in oldsha.items()if q!=p and h.encode()in raw}
for _ in range(33):
 progress=False
 for p in list(pending):
  if any(q in pending for q in dependencies(p)):continue
  if p.endswith('.json'):v=source_update(before[p],known,extra)
  else:
   changes=[(oldsha[q],known[q])for q in known if oldsha[q].encode()in before[p]and oldsha[q]!=known[q]]
   v=replace_literals(before[p],changes)if changes else before[p]
  if v!=before[p]:after[p]=v;known[p]=sha(v)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('SOURCE_DEPENDENCY_CYCLE',pending))
need(not pending,'SOURCE_CLOSURE_COMPLETE')
need(not any('scene_router.gd'in p for p in after),'ROUTER_UNCHANGED')
need(OUT.exists()==False,'EXCLUSIVE_CLOSURE_OUTPUT')
need(not any(p in after for p in ['res://scripts/city/luoyang_docks_district08_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd']),'HISTORICAL_ORDINARY_LAYERS_UNCHANGED')
for p,h in protected.items():need(sha(read(p))==h,('PROTECTED_FINAL',p))
need(json.loads(after[ex])['owned']['res://scripts/autoload/scene_router.gd']==old_ex['owned']['res://scripts/autoload/scene_router.gd'],'ENTIRE_ROUTER_APPROVED_EDGE_CHAIN_IDENTICAL')
targets=[];patches=[];all_source_hunks=[];proposed_deltas=[]
for p,b in after.items():
 name=Path(p).name
 if name in outputs and outputs[name]!=b:name=p.removeprefix('res://').replace('/','__')
 new(name,b)
 reason=('Exact binding path/SHA successor at same runtime entry' if p==old_runtime else ('Exact runtime/binding SHA successor at same material entry' if p==old_material else ('Shared runtime SHA constant only; ENV also material SHA' if p in six else ('CT exact Field/C pins only' if p==ct else ('CT SHA constant only; existing admission branch preserved' if p==coord else ('Append exact inverse edges to existing owners; old Router row and OWNED key set preserved' if p==ex else ('Existing index SHA constants only' if p.endswith('.gd') else 'Finite source-map mechanical successor; geometry/business fields preserved')))))))
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'old_bytes':len(before[p]),'new_sha256':sha(b),'bytes':len(b),'reason':reason})
 proposed_deltas.append({'path':'game/'+p[6:],'before_sha256':oldsha[p],'before_bytes':len(before[p]),'after_sha256':sha(b),'after_bytes':len(b),'reason':reason})
 complete_hunks=positional_hunks(before[p],b)
 all_source_hunks.append({'target':'game/'+p[6:],'byte_offset_hunks':complete_hunks,'whole_bytes_inverse':True})
 if p.endswith('.gd'):
  hunks[p]=gd_hunks(before[p],b)
  patches.append({'target':'game/'+p[6:],'hunks':hunks[p]})
for name,b in outputs.items():put(name,b)
receipt={'status':'BOUNDED_GATE_TWO_FRONT_WALLS_MECHANICAL_SUCCESSORS_NOT_DEPLOYED','targets':targets,'potential_33_domain':paths,'protected_region_and_11b_pins':protected,'runtime_entry_path_unchanged':True,'six_callers_only_SHA_constants':True,'AA_AC_unchanged':True,'changed_count':len(targets),'owned_edges_added':owned_changed,'extra_source_pins':extra,'old_EX_keys_preserved':True,'Router_unchanged':True,'canonical_writes':0,'engine_runs':0,'other_seven_binding_rows_typed_equal':True,'CT_changes_only_Field_and_C_sources':True,'coordinator_29l_Router_branch_preserved':True}
put('receipt_READY.json',enc(receipt));put('GD_hunks_READY.json',enc(patches))
put('all_source_hunks_READY.json',enc(all_source_hunks))
put('proposed_old_target_deltas_READY.json',enc({'status':'ROOT_REVIEW_REQUIRED_NOT_AUTHORIZATION','old_target_deltas':proposed_deltas}))
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']}for r in targets},'new_modules':{'game/'+PREFIX[6:]+name:{'sha256':sha(b),'bytes':len(b)}for name,b in outputs.items()}}
put('auth_READY.json',enc(auth));print(json.dumps({'targets':len(targets),'owned_added':len(owned_changed),'new_modules':len(outputs),'auth_sha256':sha(enc(auth))}))
