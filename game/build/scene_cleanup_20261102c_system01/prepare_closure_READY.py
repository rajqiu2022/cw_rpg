"""Finite immutable six-bundle successor candidates. Never writes canonical sources."""
from pathlib import Path
import hashlib,json,re,copy,difflib
GAME=Path(__file__).resolve().parents[2]
TASK=Path(__file__).resolve().parent
OUT=TASK/'closure_READY01'
PREFIX='res://build/scene_cleanup_20261102c_system01/closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):
 q=GAME/p[6:]
 if not q.exists():q=TASK/'mask_import_ROOT'/p[6:]
 return q.read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def need(v,s):
 if not v:raise ValueError(s)
def once(b,o,n):
 o=o.encode()if isinstance(o,str)else o;n=n.encode()if isinstance(n,str)else n
 need(b.count(o)==1,('NONUNIQUE',o[:100],b.count(o)))
 return b.replace(o,n,1)
def replace(raw,rows):
 b=raw
 for o,n in rows:b=once(b,o,n)
 inv=b
 for o,n in reversed(rows):inv=once(inv,n,o)
 need(inv==raw,'LITERAL_WHOLE_INVERSE');return b
outputs={}
def new(name,b):
 need(name not in outputs or outputs[name]==b,('OUTPUT_NAME_CONFLICT',name))
 outputs[name]=b;return PREFIX+name,sha(b)
def positional(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);rows=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':rows.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 forward=a
 for h in reversed(rows):
  at=h['old_offset'];o=h['old'].encode();n=h['new'].encode();need(forward[at:at+len(o)]==o,'EXACT_FORWARD_SLICE');forward=forward[:at]+n+forward[at+len(o):]
 need(forward==b,'WHOLE_POSITIONAL_FORWARD')
 need(reverse_proof(b,rows)==a,'WHOLE_POSITIONAL_INVERSE');return rows
def reverse_proof(b,rows):
 for h in reversed(rows):
  at=int(h['new_offset']);o=h['old'].encode();n=h['new'].encode();need(b[at:at+len(n)]==n,'EXACT_INVERSE_SLICE');b=b[:at]+o+b[at+len(n):]
 return b
def gd_hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);rows=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op=='equal':continue
  start=max(0,i-1);end=min(len(aa),j+1)
  rows.append({'old':''.join(aa[start:end]),'new':''.join(aa[start:i])+''.join(bb[k:l])+''.join(aa[j:end])})
 need(replace(a,[(h['old'],h['new'])for h in rows])==b,'CONTEXT_WHOLE_FORWARD');return rows
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
paths=[r['target']for r in scope['targets']]
oldroot='res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/'
runtime=oldroot+'finish8_runtime_READY.gd';material=oldroot+'material_runtime_finish139_READY.gd'
binding_path='res://build/luoyang_gate_front_walls_20261101c_system01/closure_READY01/finish8_binding_READY.json'
region='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
router='res://scripts/autoload/scene_router.gd'
native='res://build/three_towns_world_20261029j_system01/native_sources.json'
registry='res://build/three_towns_world_20261029j_system01/town_registry.gd'
geo='res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd'
pair='res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd'
paths += [runtime,material,region,router,native,registry,geo,pair]
need(len(paths)==39 and len(set(paths))==39,'FINITE37_PLUS_TWO_CITYNAV_LEAVES')
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()};after={}
pubpath='res://build/scene_cleanup_20261102c_system01/output/140404/result.json'
pub=json.loads(read(pubpath));need(pub['passed']and pub['retired_actual_owners']==28 and len(pub['records'])==6,'ACTUAL_ROOT_SIX_BUNDLE_RESULT')
spec=json.loads(read('res://build/scene_cleanup_20261102c_system01/publication_spec_READY.json'))
extra={pubpath:sha(read(pubpath))}
original_binding=json.loads(read(binding_path));binding=copy.deepcopy(original_binding)
for sid,r in pub['records'].items():
 need(r['whole_typed_inverse'],'EXACT_TYPED_PUBLICATION')
 need(sha(read(r['payload']['path']))==r['payload']['sha256'],'NEW_BUNDLE_BYTES')
 extra[r['payload']['path']]=r['payload']['sha256']
 if r['kind']!='LEGACY':continue
 need(r['whole_RGBA_inverse'],'EXACT_RGBA_PUBLICATION')
 mask=r['mask'];side=mask['path']+'.import';gpu=re.search(r'^path="([^"]+)"',read(side).decode(),re.M).group(1)
 for p in [mask['path'],side,gpu]:extra[p]=sha(read(p))
 row=binding['scenes'][sid];row['payload']=r['payload'];row['mask']={**mask,'import_path':side,'compiled_path':gpu};row['fingerprints']=r['fingerprints'];row['publication_completion']={'path':pubpath,'sha256':extra[pubpath]}
 for p in [pubpath,r['payload']['path'],mask['path'],side,gpu]:row['required_source_sha256'][p]=extra[p]
need(sum(binding['scenes'][k]!=v for k,v in original_binding['scenes'].items())==3,'ONLY_THREE_FINISH_BINDINGS')
bind,bindsha=new('finish8_binding_READY.json',enc(binding))
after[geo]=replace(before[geo],[(binding_path,bind)])
pair_plan=json.loads(read('res://build/scene_cleanup_20261102c_system01/pair_successor_READY.json'))
need(pair_plan['before_sha256']==oldsha[pair],'CURRENT_PAIR_PARENT')
after[pair]=replace(before[pair],[(pair_plan['old'],pair_plan['new'])])
need(sha(after[pair])==pair_plan['after_sha256'],'EXACT_PAIR_SUCCESSOR')
after[runtime]=replace(before[runtime],[(binding_path,bind),(sha(read(binding_path)),bindsha)])
run_snapshot,runsha=new('finish8_runtime_READY.gd',after[runtime])
after[material]=replace(before[material],[(oldsha[runtime],runsha),(binding_path,bind),(sha(read(binding_path)),bindsha)])
mat_snapshot,matsha=new('material_runtime_finish139_READY.gd',after[material])
six=['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_estate_family_20261021am.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd']
for p in six:after[p]=replace(before[p],[(oldsha[runtime],runsha)]+([(oldsha[material],matsha)]if 'environment_layer'in p else []))
# Preserve the manifest's old serialization and every field outside three binding values.
reg=json.loads(before[region]);rt=before[region]
for sid,r in pub['records'].items():
 if r['kind']!='REGION':continue
 old=reg['compiled_bindings'][sid];need(old==r['before'],'EXACT_CURRENT_REGION_BINDING')
 for key in ['path','sha256']:rt=once(rt,json.dumps(old[key]),json.dumps(r['payload'][key]))
 # byte count is replaced only within this scene row envelope, not globally.
 text=rt.decode();marker='    '+json.dumps(sid)+': {';start=text.index(marker);vstart=start+len('    '+json.dumps(sid)+': ');_,used=json.JSONDecoder().raw_decode(text[vstart:]);end=vstart+used
 piece=text[start:end];piece2=re.sub(r'("bytes": )'+str(old['bytes'])+r'(\.0)?(?=,)',lambda m:m.group(1)+str(r['payload']['bytes']),piece,count=1)
 need(piece!=piece2,'REGION_BYTES_REPLACED');rt=(text[:start]+piece2+text[end:]).encode()
newreg=json.loads(rt);expected=copy.deepcopy(reg)
for sid,r in pub['records'].items():
 if r['kind']=='REGION':expected['compiled_bindings'][sid]=r['payload']
need(newreg==expected,'REGION_ONLY_THREE_COMPILED_ROWS');after[region]=rt
after[router]=replace(before[router],[(oldsha[region],sha(rt))])
# Existing fixed ordinary guard proofs, strictly to the same immutable historical parents.
c=six[1];aa='res://scripts/city/luoyang_docks_district08_20261019aa.gd';ac='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
for consumer,upstream,tag,name in [(aa,c,'C','C_cleanup_to_fixed_FINISH_C_inverse_READY.json'),(ac,aa,'AA','AA_cleanup_to_fixed_FINISH_AA_inverse_READY.json')]:
 raw=before[consumer];text=raw.decode()
 vals={k:re.search(r'const CITYNAV_'+tag+'_'+k+r' := "([^"]+)"',text).group(1)for k in ['CURRENT_SHA','PARENT_SHA','PROOF','PROOF_SHA']}
 proofraw=read(vals['PROOF']);need(sha(proofraw)==vals['PROOF_SHA'],'CURRENT_FIXED_PROOF_SHA');proof=json.loads(proofraw)
 need(vals['CURRENT_SHA']==oldsha[upstream],'EXACT_ORDINARY_CURRENT');parent=reverse_proof(before[upstream],proof['hunks']);need(sha(parent)==vals['PARENT_SHA'],'EXACT_UNCHANGED_FIXED_PARENT')
 np={'schema':proof['schema'],'path':upstream,'parent_sha256':vals['PARENT_SHA'],'current_sha256':sha(after[upstream]),'whole_inverse_exact':True,'hunks':positional(parent,after[upstream])}
 pp,ph=new(name,enc(np));after[consumer]=replace(raw,[(vals['CURRENT_SHA'],np['current_sha256']),(vals['PROOF'],pp),(vals['PROOF_SHA'],ph)])
ct='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';coord='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';field=six[0]
ctold=json.loads(before[ct]);after[ct]=replace(before[ct],[(json.dumps(p)+': '+json.dumps(ctold['source_sha256'][p]),json.dumps(p)+': '+json.dumps(sha(after[p])))for p in [field,c]])
after[coord]=replace(before[coord],[(oldsha[ct],sha(after[ct]))])
need(b'(path != "res://scripts/autoload/scene_router.gd" and path != FIELD) or not AP_NPC._source_matches'in after[coord],'KEEP_ORIGINAL_ADMISSION_BRANCH')
def source_update(raw,known,additions=None):
 value=json.loads(raw);rows=[]
 def walk(node):
  if isinstance(node,dict):
   for k,m in node.items():
    if k in ('source_sha256','legacy_source_sha256','runtime_authority_sha256')and isinstance(m,dict):
     for p,h in m.items():
      if p in known and h==oldsha.get(p) and known[p]!=h:rows.append((json.dumps(p)+': '+json.dumps(h),json.dumps(p)+': '+json.dumps(known[p])))
    else:walk(m)
  elif isinstance(node,list):
   for v in node:walk(v)
 walk(value);b=raw
 for o,n in dict(rows).items():need(b.count(o.encode())>0,'SOURCE_LITERAL_EXISTS');b=b.replace(o.encode(),n.encode())
 if additions:
  text=b.decode();key='legacy_source_sha256'if 'legacy_source_sha256'in value else 'source_sha256';need(key in value,'TOP_SOURCE_MAP_REQUIRED');start=text.index('  '+json.dumps(key)+': {');end=text.index('\n  }',start)
  ins=''
  for p,h in additions.items():
   if p in value[key]:need(value[key][p]==h,'NEW_SOURCE_CONFLICT');continue
   ins+=',\n    '+json.dumps(p)+': '+json.dumps(h)
  b=(text[:end]+ins+text[end:]).encode()
 return b
# Exact existing OWNED key set; append full inverse edges for only five previously owned consumers.
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
authority=json.loads(before[ex]);original_authority=copy.deepcopy(authority);et=before[ex].decode();owned=[]
for p,b in list(after.items()):
 if p not in authority['owned']:continue
 row=copy.deepcopy(authority['owned'][p]);need(row['current_sha256']==oldsha[p],'EX_CURRENT_PARENT');snap,hh=new(Path(p).name,b)
 prior=next(e['new_snapshot']for e in reversed(row['edges'])if e['new_sha256']==oldsha[p]);need(sha(read(prior))==oldsha[p],'EX_IMMUTABLE_PARENT')
 row['current_sha256']=hh;row['edges'].append({'path':p,'old_sha256':oldsha[p],'new_sha256':hh,'old_snapshot':prior,'new_snapshot':snap,'whole_inverse':True,'replacements':gd_hunks(before[p],b)})
 authority['owned'][p]=row;owned.append(p)
 marker='    '+json.dumps(p)+': {';start=et.index(marker);vstart=start+len('    '+json.dumps(p)+': ');_,used=json.JSONDecoder().raw_decode(et[vstart:]);end=vstart+used
 parts=json.dumps(row,ensure_ascii=False,indent=2).splitlines();piece='    '+json.dumps(p)+': '+parts[0]+'\n'+'\n'.join('    '+s for s in parts[1:]);et=et[:start]+piece+et[end:]
need(set(authority['owned'])==set(original_authority['owned'])and len(owned)==5,'UNCHANGED_OWNED_KEYS_FIVE_EDGES')
extra.update({PREFIX+n:sha(b)for n,b in outputs.items()})
after[ex]=source_update(et.encode(),{p:sha(b)for p,b in after.items()},extra);after[ei]=replace(before[ei],[(oldsha[ex],sha(after[ex]))])
# Native manifest has exactly 228 original keys and only Field's value changes.
nv=json.loads(before[native]);need(len(nv['sources'])==228 and nv['sources'][field]==oldsha[field],'NATIVE228_CURRENT_FIELD')
after[native]=replace(before[native],[(json.dumps(field)+': '+json.dumps(oldsha[field]),json.dumps(field)+': '+json.dumps(sha(after[field])))])
nv2=json.loads(after[native]);nv2['sources'][field]=oldsha[field];need(nv2==nv,'OTHER227_AND_KEYS_PRESERVED')
after[registry]=replace(before[registry],[(oldsha[native],sha(after[native]))])
known={p:sha(b)for p,b in after.items()};pending=[p for p in paths if p not in after]
def dependencies(p):return {q for q,h in oldsha.items()if q!=p and h.encode()in before[p]}
for _ in range(39):
 progress=False
 for p in list(pending):
  if any(q in pending for q in dependencies(p)):continue
  if p.endswith('.json'):b=source_update(before[p],known,extra)
  else:b=replace(before[p],[(oldsha[q],known[q])for q in known if oldsha[q].encode()in before[p]and oldsha[q]!=known[q]])
  if b!=before[p]:after[p]=b;known[p]=sha(b)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('FINITE_DEPENDENCY_CYCLE',pending))
need(not pending,'FINITE_CLOSURE_COMPLETE');need(not OUT.exists(),'IMMUTABLE_NEW_OUTPUT_REQUIRED')
targets=[];hunks=[]
for p,b in after.items():
 name=Path(p).name
 if name in outputs and outputs[name]!=b:name=p[6:].replace('/','__')
 cp,hh=new(name,b)
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+cp[6:],'old_sha256':oldsha[p],'old_bytes':len(before[p]),'new_sha256':hh,'bytes':len(b)})
 hunks.append({'target':'game/'+p[6:],'byte_offset_hunks':positional(before[p],b),'whole_bytes_inverse':True})
for p,b in before.items():need(read(p)==b,('CANONICAL_SOURCE_STILL_UNCHANGED',p))
receipt={'status':'ROOT_REVIEW_REQUIRED_NOT_DEPLOYED','targets':targets,'changed_count':len(targets),'potential37_plus_CityNav2':paths,'owned_edges_added':owned,'exact_old_OWNED_keys_preserved':True,'other_seven_region_bindings_equal':True,'other_five_finish_bindings_equal':True,'native_other227_equal':True,'fixed_C_AA_historical_parents_unchanged':True,'extra_source_pins':extra,'canonical_writes':0,'engine_runs':0,'save_content_reads':0,'CityNav99_and_SceneArt60_final_pins_sealed_by_Root_later':True}
new('receipt_READY.json',enc(receipt));new('all_source_hunks_READY.json',enc(hunks));new('proposed_old_target_deltas_READY.json',enc({'status':'ROOT_REVIEW_REQUIRED_NOT_AUTHORIZATION','old_target_deltas':[{'path':r['target'],'before_sha256':r['old_sha256'],'before_bytes':r['old_bytes'],'after_sha256':r['new_sha256'],'after_bytes':r['bytes']}for r in targets]}))
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']}for r in targets},'new_modules':{'game/'+PREFIX[6:]+n:{'sha256':sha(b),'bytes':len(b)}for n,b in outputs.items()}}
new('auth_READY.json',enc(auth))
OUT.mkdir()
for n,b in outputs.items():
 with (OUT/n).open('xb')as f:f.write(b)
print(json.dumps({'targets':len(targets),'owned_edges':len(owned),'new_modules':len(outputs),'auth_sha256':sha(enc(auth))}))
