"""Finite exact successor proposal, no canonical writes or engine launch."""
from pathlib import Path
import json, hashlib, copy, difflib, base64
GAME=Path(__file__).resolve().parents[2]
TASK=Path(__file__).resolve().parent
OUT=TASK/'keepalive_closure_READY01'
PREFIX='res://build/loading_20261106_system03/keepalive_closure_READY01/'
def read(p): return (GAME/p[6:]).read_bytes()
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(o): return (json.dumps(o,ensure_ascii=False,indent=2)+'\n').encode()
def need(v,m):
 if not v: raise ValueError(m)
def once(b,o,n):
 o=o.encode() if isinstance(o,str) else o;n=n.encode() if isinstance(n,str) else n
 need(b.count(o)==1,('UNIQUE',o[:80],b.count(o)))
 return b.replace(o,n,1)
def positional(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);hs=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal': hs.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 inv=b
 for h in reversed(hs):
  at=h['new_offset'];n=h['new'].encode();o=h['old'].encode();need(inv[at:at+len(n)]==n,'INVERSE_SLICE');inv=inv[:at]+o+inv[at+len(n):]
 need(inv==a,'WHOLE_INVERSE');return hs
def json_changes(a,b,path=''):
 if a==b:return []
 if isinstance(a,dict) and isinstance(b,dict):
  return sum((json_changes(a.get(k),b.get(k),path+'/'+k) for k in sorted(a.keys()|b.keys())),[])
 if isinstance(a,list) and isinstance(b,list):
  return sum((json_changes(a[i] if i<len(a) else None,b[i] if i<len(b) else None,path+'/'+str(i)) for i in range(max(len(a),len(b)))),[])
 return [{'path':path,'before':a,'after':b}]
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
router='res://scripts/autoload/scene_router.gd'
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
nav='res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'
paths=[r['target'] for r in scope['targets']]+[router,nav]
before={p:read(p) for p in paths};oldsha={p:sha(b) for p,b in before.items()}
spec=json.loads((TASK/'keepalive01/optimization_exact_hunk.json').read_text(encoding='utf-8'))
need(oldsha[router]==spec['old_sha256'],'EXACT_ROUTER_PARENT')
rb=once(before[router],spec['before'],spec['after'])
need(sha(rb)==spec['candidate_sha256'],'EXACT_MEASURED_CANDIDATE')
need(once(rb,spec['after'],spec['before'])==before[router],'ROUTER_WHOLE_INVERSE')
after={router:rb};known={router:sha(rb)}
snap=PREFIX+'scene_router.gd.snapshot.txt';outputs={'scene_router.gd.snapshot.txt':rb}
authority=json.loads(before[ex]);oldauthority=copy.deepcopy(authority)
row=copy.deepcopy(authority['owned'][router]);need(row['current_sha256']==oldsha[router],'EX_OWNED_PARENT')
prior=next(e['new_snapshot'] for e in reversed(row['edges']) if e['new_sha256']==oldsha[router])
need(sha(read(prior))==oldsha[router],'IMMUTABLE_PARENT_SNAPSHOT')
row['current_sha256']=sha(rb)
row['edges'].append({'path':router,'old_sha256':oldsha[router],'new_sha256':sha(rb),'old_snapshot':prior,'new_snapshot':snap,'whole_inverse':True,'replacements':[{'old':spec['before'],'new':spec['after']}]})
et=before[ex].decode();marker='    '+json.dumps(router)+': {';start=et.index(marker);vstart=start+len('    '+json.dumps(router)+': ');_,used=json.JSONDecoder().raw_decode(et[vstart:]);end=vstart+used
parts=json.dumps(row,ensure_ascii=False,indent=2).splitlines();piece='    '+json.dumps(router)+': '+parts[0]+'\n'+'\n'.join('    '+s for s in parts[1:]);et=et[:start]+piece+et[end:]
def source_update(raw,add_snapshot=False,keys=('source_sha256','legacy_source_sha256','runtime_authority_sha256')):
 obj=json.loads(raw)
 def walk(node):
  nonlocal raw
  if isinstance(node,dict):
   for k,v in node.items():
    if k in keys and isinstance(v,dict):
     for p,h in v.items():
      if p in known and h==oldsha[p] and h!=known[p]:
       o=(json.dumps(p)+': '+json.dumps(h)).encode();n=(json.dumps(p)+': '+json.dumps(known[p])).encode();need(o in raw,'SOURCE_LITERAL');raw=raw.replace(o,n)
    else:walk(v)
  elif isinstance(node,list):
   for v in node:walk(v)
 walk(obj)
 if add_snapshot:
  key='legacy_source_sha256' if 'legacy_source_sha256' in obj else 'source_sha256'
  need(prior in obj[key] and snap not in obj[key],'SAME_EXISTING_EX_SNAPSHOT_COLLECTOR')
  t=raw.decode();start=t.index('  '+json.dumps(key)+': {');end=t.index('\n  }',start)
  raw=(t[:end]+',\n    '+json.dumps(snap)+': '+json.dumps(sha(rb))+t[end:]).encode()
 return raw
after[ex]=source_update(et.encode(),True);known[ex]=sha(after[ex])
after[ei]=once(before[ei],oldsha[ex],known[ex]);known[ei]=sha(after[ei])
pending=[p for p in paths if p not in after and p!=nav]
def dependencies(p):return {q for q,h in oldsha.items() if q!=p and h.encode() in before[p]}
for _ in range(len(paths)):
 progress=False
 for p in list(pending):
  if any(q in pending for q in dependencies(p)):continue
  b=before[p]
  if p.endswith('.json'):
   obj=json.loads(b);has_prior=any(prior in obj.get(k,{}) for k in ['source_sha256','legacy_source_sha256'])
   b=source_update(b,has_prior)
  else:
   for q,h in known.items():
    if oldsha[q].encode() in b and h!=oldsha[q]:b=once(b,oldsha[q],h)
  if b!=before[p]:after[p]=b;known[p]=sha(b)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('DEPENDENCY_CYCLE',pending))
need(not pending,'CLOSURE_COMPLETE')
# Navigation is an independent precise frozen set: only existing values, no new keys.
b=source_update(before[nav],False,('source_pins',))
if b!=before[nav]:after[nav]=b;known[nav]=sha(b)
newauthority=json.loads(after[ex]);tmp=copy.deepcopy(newauthority);tmp['owned'][router]=oldauthority['owned'][router]
need(tmp['owned']==oldauthority['owned'],'EX_ONLY_ONE_OLD_OWNED_ROW')
need([p for p in after if p in oldauthority['owned']]==[router],'NO_OTHER_OWNED_CHANGE')
targets=[];hunks=[];jc=[];originals={}
for p,b in after.items():
 name=p[6:].replace('/','__');outputs[name]=b
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'new_sha256':sha(b),'old_bytes':len(before[p]),'bytes':len(b)})
 hunks.append({'target':'game/'+p[6:],'whole_inverse':True,'hunks':positional(before[p],b)})
 if p.endswith('.json'):jc.append({'target':'game/'+p[6:],'changes':json_changes(json.loads(before[p]),json.loads(b))})
 originals[p]={'sha256':oldsha[p],'base64':base64.b64encode(before[p]).decode()}
for p,b in before.items():need(read(p)==b,('SOURCE_MOVED',p))
need(not OUT.exists(),'IMMUTABLE_NEW_OUTPUT')
OUT.mkdir();(OUT/'.gdignore').write_bytes(b'')
for n,b in outputs.items():(OUT/n).write_bytes(b)
(OUT/'all_hunks.json').write_bytes(enc(hunks));(OUT/'json_changes.json').write_bytes(enc(jc));(OUT/'original_bytes.json').write_bytes(enc(originals))
receipt={'status':'ROOT_REVIEW_REQUIRED_NOT_ADOPTED','targets':targets,'changed_count':len(targets),'new_runtime_leaf':{'path':snap,'sha256':sha(rb)},'owned_edges_added':[router],'old_OWNED_keys_and_other_rows_unchanged':True,'canonical_writes':0,'engine_runs':0,'real_save_content_access':0,'scope':'Only measured function-local reference lifetime; remaining changes are exact source successor pins and one full inverse edge. No hash/guard/lease algorithm changes. Navigation existing keys unchanged.'}
(OUT/'receipt.json').write_bytes(enc(receipt))
print(json.dumps({'changed_count':len(targets),'targets':[r['target'] for r in targets],'receipt_sha256':sha(enc(receipt))}))
