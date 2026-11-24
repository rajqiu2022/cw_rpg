"""Finite byte-exact parallel source hash candidate. Never edits canonical sources."""
from pathlib import Path
import hashlib, json, difflib, base64
GAME=Path(__file__).resolve().parents[2]
TASK=Path(__file__).resolve().parent
OUT=TASK/'hash_closure_READY01'
PREFIX='res://build/loading_20261106_system01/hash_closure_READY01/'
def read(p): return (GAME/p[6:]).read_bytes()
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(v): return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def need(v,s):
 if not v: raise ValueError(s)
def once(b,o,n):
 o=o.encode() if isinstance(o,str) else o; n=n.encode() if isinstance(n,str) else n
 need(b.count(o)==1,('EXACT_UNIQUE',o[:100],b.count(o)))
 return b.replace(o,n,1)
def positional(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);rows=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':rows.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 inv=b
 for h in reversed(rows):
  at=h['new_offset'];n=h['new'].encode();o=h['old'].encode();need(inv[at:at+len(n)]==n,'EXACT_INVERSE');inv=inv[:at]+o+inv[at+len(n):]
 need(inv==a,'WHOLE_INVERSE')
 return rows
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
paths=[r['target'] for r in scope['targets']]
quarter='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
helper='res://build/loading_20261106_system01/hash_batch.gd'
helper_sha=sha(read(helper))
before={p:read(p) for p in paths};oldsha={p:sha(b) for p,b in before.items()}
need(oldsha[quarter]=='d238bc25c955c54c84175a7cddca5ca8f27f95515e3324155e66082cd7a13042','EXACT_QUARTER_PARENT')
raw=before[quarter]
addition='''const SOURCE_HASH_BATCH="%s"
const SOURCE_HASH_BATCH_SHA="%s"
static func _fresh_source_hashes(source: Dictionary) -> Dictionary:
	# Pin before loading executable helper; each invocation reopens all original paths.
	if FileAccess.get_sha256(SOURCE_HASH_BATCH)!=SOURCE_HASH_BATCH_SHA: return {}
	var batch: Variant=load(SOURCE_HASH_BATCH)
	if not batch is GDScript or batch.resource_path!=SOURCE_HASH_BATCH: return {}
	var paths: Array[String]=[]
	for path: String in source: paths.append(path)
	return batch.fresh(paths,4)
'''%(helper,helper_sha)
raw=once(raw,'static func manifest() -> Dictionary:\n',addition+'static func manifest() -> Dictionary:\n')
raw=once(raw,'\tfor p: String in header.source_sha256:\n\t\tif FileAccess.get_sha256(p)!=header.source_sha256[p]: return {}', '\tvar first: Dictionary=_fresh_source_hashes(header.source_sha256)\n\tfor p: String in header.source_sha256:\n\t\tif first.get(p,"")!=header.source_sha256[p]: return {}')
raw=once(raw,'\tvar began: int=Time.get_ticks_usec();var final: Dictionary={}\n\tfor p: String in _receipt.source_first:\n\t\tfinal[p]=FileAccess.get_sha256(p)\n\t\tif final[p]!=_receipt.source_first[p]: _data={};_packets={};_images={};_sessions={};return false','\tvar began: int=Time.get_ticks_usec();var final: Dictionary=_fresh_source_hashes(_receipt.source_first)\n\tfor p: String in _receipt.source_first:\n\t\tif final.get(p,"")!=_receipt.source_first[p]: _data={};_packets={};_images={};_sessions={};return false')
after={quarter:raw};known={quarter:sha(raw)}
def source_update(raw):
 obj=json.loads(raw);changed=False
 def walk(node):
  nonlocal raw,changed
  if isinstance(node,dict):
   for key,value in node.items():
    if key in ('source_sha256','legacy_source_sha256','runtime_authority_sha256') and isinstance(value,dict):
     for p,h in value.items():
      if p in known and h==oldsha[p] and h!=known[p]:
       old=(json.dumps(p)+': '+json.dumps(h)).encode();new=(json.dumps(p)+': '+json.dumps(known[p])).encode()
       need(old in raw,'SOURCE_LITERAL');raw=raw.replace(old,new);changed=True
    else:walk(value)
  elif isinstance(node,list):
   for value in node:walk(value)
 walk(obj)
 # Only source maps that actually refer to Quarter gain its new executable helper.
 key='legacy_source_sha256' if 'legacy_source_sha256' in obj else 'source_sha256'
 if key in obj and quarter in obj[key]:
  need(helper not in obj[key],'NEW_HELPER_ABSENT')
  text=raw.decode();start=text.index('  '+json.dumps(key)+': {');end=text.index('\n  }',start)
  raw=(text[:end]+',\n    '+json.dumps(helper)+': '+json.dumps(helper_sha)+text[end:]).encode()
 return raw
pending=[p for p in paths if p!=quarter]
def dependencies(p):return {q for q,h in oldsha.items() if q!=p and h.encode() in before[p]}
for _ in range(len(paths)):
 progress=False
 for p in list(pending):
  if any(q in pending for q in dependencies(p)):continue
  raw=before[p]
  if p.endswith('.json'):raw=source_update(raw)
  else:
   for q,h in known.items():
    if oldsha[q].encode() in raw and oldsha[q]!=h:raw=once(raw,oldsha[q],h)
  if raw!=before[p]:after[p]=raw;known[p]=sha(raw)
  pending.remove(p);progress=True
 if not pending:break
 need(progress,('DEPENDENCY_CYCLE',pending))
need(not pending,'CLOSURE_FINISHED')
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
authority=json.loads(before[ex]);owned_changes=[p for p in after if p in authority['owned']]
need(not owned_changes,('UNEXPECTED_OWNED_CHANGE_REQUIRES_EXPLICIT_INVERSE',owned_changes))
targets=[];hunks=[];originals={}
for p,b in after.items():
 name=p[6:].replace('/','__');targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'old_bytes':len(before[p]),'new_sha256':sha(b),'bytes':len(b)})
 hunks.append({'target':'game/'+p[6:],'whole_inverse':True,'hunks':positional(before[p],b)})
 originals[p]={'sha256':oldsha[p],'base64':base64.b64encode(before[p]).decode()}
for p,b in before.items():need(read(p)==b,('SOURCE_CHANGED_DURING_PREPARATION',p))
need(not OUT.exists(),'IMMUTABLE_OUTPUT')
OUT.mkdir()
for p,b in after.items(): (OUT/p[6:].replace('/','__')).write_bytes(b)
(OUT/'original_bytes.json').write_bytes(enc(originals));(OUT/'all_hunks.json').write_bytes(enc(hunks))
(OUT/'receipt.json').write_bytes(enc({'status':'ROOT_REVIEW_REQUIRED_NOT_ADOPTED','targets':targets,'changed_count':len(targets),'helper':{'path':helper,'sha256':helper_sha},'exact_old_OWNED_keys_preserved':True,'owned_changes':owned_changes,'canonical_writes':0,'real_save_content_access':0}))
print(json.dumps({'changed_count':len(targets),'targets':[r['target'] for r in targets],'receipt_sha256':sha((OUT/'receipt.json').read_bytes())}))
