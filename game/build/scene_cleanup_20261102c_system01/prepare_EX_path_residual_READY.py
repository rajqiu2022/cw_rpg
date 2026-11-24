"""Correct only five new snapshot locations to existing EX luoyang_ domain.
Retain the rejected full EX snapshot and every pre-cleanup edge. No canonical write.
"""
from pathlib import Path
import hashlib,json,difflib
TASK=Path(__file__).resolve().parent;GAME=TASK.parents[1]
OUT=GAME/'build/luoyang_scene_cleanup_20261102c_source01';PREFIX='res://build/luoyang_scene_cleanup_20261102c_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p[6:]).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def need(v,s):
 if not v:raise ValueError(s)
def once(b,o,n):
 o=o.encode();n=n.encode();need(b.count(o)==1,('EXACT_ONE',o));return b.replace(o,n,1)
def positional(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);hs=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':hs.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 inverse=b
 for h in reversed(hs):
  at=h['new_offset'];n=h['new'].encode();need(inverse[at:at+len(n)]==n,'EXACT_INV_SLICE');inverse=inverse[:at]+h['old'].encode()+inverse[at+len(n):]
 need(inverse==a,'WHOLE_BYTE_INVERSE');return hs
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
paths=[r['target']for r in scope['targets']];need(len(paths)==31,'ORIGINAL_FINITE31_DOMAIN')
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()};after={};outputs={}
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
receipt=json.loads(read('res://build/scene_cleanup_20261102c_system01/closure_READY01/receipt_READY.json'))
authority=json.loads(before[ex]);expected=json.loads(before[ex]);text=before[ex];extra={};corrections=[];relocations={}
for p in receipt['owned_edges_added']:
 row=authority['owned'][p];edge=row['edges'][-1];old=edge['new_snapshot'];need(old.startswith('res://build/scene_cleanup_20261102c_system01/closure_READY01/'),'ONLY_CURRENT_FIVE_NEW_EDGES')
 raw=read(old);need(sha(raw)==edge['new_sha256']==sha(read(p)),'SAME_CURRENT_SNAPSHOT_WHOLE_BYTES')
 name='snapshots/'+Path(p).name;new=PREFIX+name;outputs[name]=raw;extra[new]=sha(raw)
 relocations[old]=new
 # This snapshot path occurs in edge and source map; preserve old source-map key.
 needle='"new_snapshot": '+json.dumps(old);replacement='"new_snapshot": '+json.dumps(new);text=once(text,needle,replacement)
 expected['owned'][p]['edges'][-1]['new_snapshot']=new;corrections.append({'owner':p,'old':old,'new':new,'sha256':sha(raw),'only_last_edge_snapshot_location_changed':True})
for old,new in relocations.items():expected['source_sha256'][new]=expected['source_sha256'].pop(old)
def rename_source_keys(raw):
 b=raw
 for old,new in relocations.items():
  o=(json.dumps(old)+':').encode();n=(json.dumps(new)+':').encode()
  if o in b:
   need(b.count(o)==1,('ONE_FIVE_NEW_KEY',old));b=b.replace(o,n,1)
 return b
def source_update(raw,known,adds=None):
 value=json.loads(raw);rows=[]
 def walk(node):
  if isinstance(node,dict):
   for k,m in node.items():
    if k in ('source_sha256','legacy_source_sha256','runtime_authority_sha256')and isinstance(m,dict):
     for p,h in m.items():
      if p in known and h==oldsha.get(p)and known[p]!=h:rows.append((json.dumps(p)+': '+json.dumps(h),json.dumps(p)+': '+json.dumps(known[p])))
    else:walk(m)
  elif isinstance(node,list):
   for v in node:walk(v)
 walk(value);b=raw
 for o,n in dict(rows).items():need(o.encode()in b,'SOURCE_PRESENT');b=b.replace(o.encode(),n.encode())
 if adds:
  t=b.decode();k='legacy_source_sha256'if 'legacy_source_sha256'in value else 'source_sha256';need(k in value,'TOP_SOURCE_MAP');start=t.index('  '+json.dumps(k)+': {');end=t.index('\n  }',start);ins=''
  for p,h in adds.items():
   if p in value[k]:need(value[k][p]==h,'EXTRA_ALREADY_EXACT');continue
   ins+=',\n    '+json.dumps(p)+': '+json.dumps(h)
  b=(t[:end]+ins+t[end:]).encode()
 return b
after[ex]=rename_source_keys(text);need(json.loads(after[ex])==expected,'ONLY_FIVE_SNAPSHOT_PATHS_AND_FIVE_PIN_KEY_RELOCATIONS')
after[ei]=once(before[ei],oldsha[ex],sha(after[ex]))
known={p:sha(b)for p,b in after.items()};pending=[p for p in paths if p not in after]
for _ in range(31):
 progress=False
 for p in list(pending):
  deps={q for q,h in oldsha.items()if q!=p and h.encode()in before[p]}
  if any(q in pending for q in deps):continue
  if p.endswith('.json'):b=source_update(rename_source_keys(before[p]),known)
  else:
   b=before[p]
   for q,h in known.items():
    if oldsha[q]!=h and oldsha[q].encode()in b:b=once(b,oldsha[q],h)
  if b!=before[p]:after[p]=b;known[p]=sha(b)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('SOURCE_CYCLE',pending))
need(not pending,'FINITE_CLOSURE_DONE')
# There must be no new canonical executable change apart from metadata SHA indices.
for p in receipt['owned_edges_added']:need(p not in after,('FIVE_CANONICAL_EXECUTABLES_IDENTICAL',p))
need('res://scripts/autoload/scene_router.gd'not in after,'ROUTER_IDENTICAL')
need(not OUT.exists(),'IMMUTABLE_RESIDUAL_OUTPUT')
targets=[]
for p,b in after.items():
 name='candidates/'+p[6:].replace('/','__');outputs[name]=b;outputs['before/'+p[6:].replace('/','__')]=before[p]
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'old_bytes':len(before[p]),'new_sha256':sha(b),'bytes':len(b),'whole_inverse_exact':True,'hunks':positional(before[p],b)})
for p,b in before.items():need(read(p)==b,('CANONICAL_UNCHANGED',p))
outputs['receipt_READY.json']=enc({'status':'FIX_FIVE_NEW_EX_SNAPSHOT_LOCATION_CONTRACT_NOT_DEPLOYED','targets':targets,'changed_count':len(targets),'corrections':corrections,'exact_owned_keys_preserved':True,'all_precleanup_edges_identical':True,'all_five_current_executable_bytes_identical':True,'CT_Coordinator_Router_MainField_unchanged':True,'rejected141076_parent_EX_full_archived':True,'five_source_pin_key_relocations':relocations,'no_collector_key_count_growth':True,'canonical_writes':0,'engine_runs':0,'save_reads':0})
OUT.mkdir()
for n,b in outputs.items():
 f=OUT/n;f.parent.mkdir(parents=True,exist_ok=True)
 with f.open('xb')as h:h.write(b)
print(json.dumps({'targets':len(targets),'new_legal_snapshots':len(extra),'receipt':PREFIX+'receipt_READY.json','receipt_sha256':sha(outputs['receipt_READY.json'])}))
