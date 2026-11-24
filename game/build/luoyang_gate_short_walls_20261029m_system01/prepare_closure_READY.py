"""Bounded mechanical reuse of the existing exact31 source domain; no engine/formal writes."""
from pathlib import Path
import hashlib,json,re,copy,difflib
GAME=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent/'closure_READY01'
PREFIX='res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):
 path=GAME/p.removeprefix('res://')
 if not path.exists() and p in ('res://build/luoyang_gate_short_walls_20261029m_system01/output/132376/walk_overlay.png.import','res://.godot/imported/walk_overlay.png-fd004cc6e0d2034953575f93d1fb0864.ctex'):
  path=GAME/'build/luoyang_gate_short_walls_20261029m_system01/mask_import_ROOT'/p[6:]
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
paths=[r['target']for r in scope['targets']];need(len(paths)==31,'EXACT_EXISTING_31_DOMAIN')
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()};after={};outputs={};hunks={}
def new(name,b):outputs[name]=b;return PREFIX+name,sha(b)
oldroot='res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/closure_READY01/'
old_runtime=oldroot+'finish8_runtime_READY.gd';old_binding=oldroot+'finish8_binding_READY.json';old_material=oldroot+'material_runtime_finish139_READY.gd'
publication_path='res://build/luoyang_gate_short_walls_20261029m_system01/output/132376/result.json'
pub=json.loads(read(publication_path));need(pub['passed']and pub['checks']==16 and pub['changed_mask_pixels']==2530,'FIXED_ACTUAL_132376')
mask=pub['mask'];sidecar=mask['path']+'.import';compiled='res://.godot/imported/walk_overlay.png-fd004cc6e0d2034953575f93d1fb0864.ctex'
need(sha(read(mask['path']))==mask['sha256'],'ACTUAL_NAV_PNG')
need(read(sidecar)and read(compiled),'ROOT_TARGETED_IMPORT_REQUIRED')
binding=json.loads(read(old_binding));original_binding=copy.deepcopy(binding);gate=binding['scenes']['ch4_s0_luoyang_gate']
gate['payload']=pub['payload'];gate['mask']={**mask,'kind':'IMPORTED_RGBA8','import_path':sidecar,'compiled_path':compiled}
gate['publication_completion']={'path':publication_path,'sha256':sha(read(publication_path))};gate['fingerprints']=pub['fingerprints']
for p in [pub['payload']['path'],mask['path'],publication_path,sidecar,compiled]:gate['required_source_sha256'][p]=sha(read(p))
for id in binding['scenes']:
 if id!='ch4_s0_luoyang_gate':need(binding['scenes'][id]==original_binding['scenes'][id],'OTHER_SEVEN_BINDING_ROWS_IDENTICAL')
bind_path,bind_sha=new('finish8_binding_READY.json',enc(binding))
runtime=replace_literals(read(old_runtime),[(old_runtime,PREFIX+'finish8_runtime_READY.gd'),(old_binding,bind_path),(sha(read(old_binding)),bind_sha)])
runtime_path,runtime_sha=new('finish8_runtime_READY.gd',runtime)
material=replace_literals(read(old_material),[(old_runtime,runtime_path),(sha(read(old_runtime)),runtime_sha),(old_binding,bind_path),(sha(read(old_binding)),bind_sha)])
material_path,material_sha=new('material_runtime_finish139_READY.gd',material)
six=['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_estate_family_20261021am.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd']
for p in six:
 changes=[(old_runtime,runtime_path),(sha(read(old_runtime)),runtime_sha)]
 if 'environment_layer' in p:changes.extend([(old_material,material_path),(sha(read(old_material)),material_sha)])
 after[p]=replace_literals(before[p],changes)
ct='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
coord='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';c=six[1]
field=six[0]
ct_changes=[]
for p in [field,c]:ct_changes.append(('"'+p+'": "'+oldsha[p]+'"','"'+p+'": "'+sha(after[p])+'"'))
after[ct]=replace_literals(before[ct],ct_changes)
after[coord]=replace_literals(before[coord],[(oldsha[ct],sha(after[ct]))])
need(b'path != "res://scripts/autoload/scene_router.gd" or not AP_NPC._source_matches' in after[coord],'PRESERVE_29L_ROUTER_ADMISSION')
def gd_hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);matches=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op=='equal':continue
  start=max(0,i-1);end=min(len(aa),j+1);left=''.join(aa[start:end]);right=''.join(aa[start:i])+''.join(bb[k:l])+''.join(aa[j:end]);matches.append({'old':left,'new':right})
 test=a
 for h in matches:test=once(test,h['old'],h['new'])
 need(test==b,'GD_HUNKS_WHOLE_FORWARD')
 return matches
def source_update(raw,known,additions=None):
 value=json.loads(raw);changed=[]
 def walk(node):
  if isinstance(node,dict):
   for key,m in node.items():
    if key in ('source_sha256','legacy_source_sha256')and isinstance(m,dict):
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
temple='res://scripts/city/luoyang_temple_assembly_20261016.gd'
temple_text=before[temple].decode();old_tbind=re.search(r'const BIND_PATH="([^"]+)"',temple_text).group(1)
tbind=source_update(read(old_tbind),{p:sha(v)for p,v in after.items()})
tbind_path,tbind_sha=new('Temple_binding_READY.json',tbind)
after[temple]=replace_literals(before[temple],[(old_runtime,runtime_path),(sha(read(old_runtime)),runtime_sha),(old_tbind,tbind_path),(sha(read(old_tbind)),tbind_sha)])
aa='res://scripts/city/luoyang_docks_district08_20261019aa.gd';ac='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
def ordinary_successor(consumer,source,key,proof_key,name):
 text=before[consumer].decode();old_proof=re.search(r'const '+proof_key+r'="([^"]+)"',text).group(1)
 proof=json.loads(read(old_proof));need(proof['new_sha256']==oldsha[source],'FIXED_ORDINARY_HEAD')
 # Existing finite inverse list remains the same length. Only exact new const literals advance.
 proof['new_sha256']=sha(after[source])
 old_source=before[source].decode();new_source=after[source].decode()
 for r in proof['replacements']:
  for old,new_value in [(old_runtime,runtime_path),(sha(read(old_runtime)),runtime_sha)]:r['new']=r['new'].replace(old,new_value)
  if source==aa:
   for old,new_value in aa_literal_changes:r['new']=r['new'].replace(old,new_value)
 inv=new_source
 for r in reversed(proof['replacements']):
  need(inv.count(r['new'])==1,'ORDINARY_FINITE_INVERSE_UNIQUE');inv=inv.replace(r['new'],r['old'])
 need(sha(inv.encode())==proof['old_sha256'],'ORDINARY_COMPLETE_INVERSE')
 proof_path,proof_sha=new(name,enc(proof))
 changes=[(oldsha[source],sha(after[source])),(old_proof,proof_path),(sha(read(old_proof)),proof_sha)]
 after[consumer]=replace_literals(before[consumer],changes)
 return changes
aa_literal_changes=ordinary_successor(aa,c,'FINISH_C_SHA','FINISH_C_PROOF','C_ordinary_to_fixed25h_READY.json')
ordinary_successor(ac,aa,'FINISH_AA_SHA','FINISH_AA_PROOF','AA_ordinary_to_fixed25h_READY.json')
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
for _ in range(31):
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
targets=[];patches=[]
for p,b in after.items():
 name=Path(p).name
 if name in outputs and outputs[name]!=b:name=p.removeprefix('res://').replace('/','__')
 new(name,b)
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'new_sha256':sha(b),'bytes':len(b)})
 if p.endswith('.gd'):
  hunks[p]=gd_hunks(before[p],b)
  patches.append({'target':'game/'+p[6:],'hunks':hunks[p]})
for name,b in outputs.items():put(name,b)
receipt={'status':'EXACT31_DOMAIN_MECHANICAL_SUCCESSORS_READY_NOT_DEPLOYED','targets':targets,'original_31_domain':paths,'changed_count':len(targets),'owned_edges_added':owned_changed,'extra_source_pins':extra,'old_EX_keys_preserved':True,'Router_unchanged':True,'canonical_writes':0,'engine_runs':0,'other_seven_binding_rows_typed_equal':True,'CT_changes_only_Field_and_C_sources':True,'coordinator_29l_Router_branch_preserved':True}
put('receipt_READY.json',enc(receipt));put('GD_hunks_READY.json',enc(patches))
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']}for r in targets},'new_modules':{'game/'+PREFIX[6:]+name:{'sha256':sha(b),'bytes':len(b)}for name,b in outputs.items()}}
put('auth_READY.json',enc(auth));print(json.dumps({'targets':len(targets),'owned_added':len(owned_changed),'new_modules':len(outputs),'auth_sha256':sha(enc(auth))}))
