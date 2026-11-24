"""Prepare only the observed finite Market source succession; no canonical writes."""
from pathlib import Path
import json, hashlib, base64, difflib
TASK=Path(__file__).resolve().parent
GAME=TASK.parents[1]
OUT=TASK/'market_closure_READY01'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p): return (GAME/p.removeprefix('res://')).read_bytes()
def obj(p): return json.loads(read(p))
def need(v,s):
 if not v: raise ValueError(s)
def once(b,o,n):
 o=o.encode(); n=n.encode(); need(b.count(o)==1,('unique',o,b.count(o))); return b.replace(o,n,1)
def save(p,o): p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
d=json.loads((TASK/'actual/144228/market_source_diagnostic.json').read_bytes())
mp=d['entry']['manifest_path']; ip='res://scripts/city/luoyang_full_city_index_20261022ap.gd'
dp='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
ep='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
qp='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
before={mp:read(mp),ip:read(ip)}; raw=before[mp]; m=json.loads(raw)
need(sha(raw)==d['entry']['manifest_sha256'],'exact manifest parent')
need(sha(before[ip])=='bce29a1bf8ff249d718cd399035411a10b1a88fbcb5826c2418393385e1094b1','exact index parent')
docks=obj(dp)['legacy_source_sha256']; ex=obj(ep)['source_sha256']; proofs=[]
need(len(d['extra'])==22 and len(d['different'])==8 and not d['missing'],'observed scope')
for p,h in d['extra'].items():
 need(p not in m['legacy_source_sha256'],'extra truly new')
 need(docks.get(p)==h and ex.get(p)==h and sha(read(p))==h,('extra historical authority',p))
 proofs.append({'path':p,'sha256':h,'authority':[dp+'#/legacy_source_sha256',ep+'#/source_sha256']})
for p,v in d['different'].items():
 need(m['legacy_source_sha256'].get(p)==v['expected'] and sha(read(p))==v['actual'],('exact changed parent',p))
 authority=[dp+'#/legacy_source_sha256']
 if p==qp:
  receipt=json.loads((TASK/'hash_closure_READY01/receipt.json').read_bytes())
  need(any(r['target']=='game/'+p[6:] and r['new_sha256']==v['actual'] for r in receipt['targets']),'Root approved exact8')
  authority=['res://build/loading_20261106_system01/hash_closure_READY01/receipt.json']
 else: need(docks.get(p)==v['actual'],('Docks current authority',p))
 text=raw.decode(); start=text.index('  "legacy_source_sha256": {'); end=text.index('\n  }',start)
 segment=once(text[start:end].encode(),json.dumps(p)+': '+json.dumps(v['expected']),json.dumps(p)+': '+json.dumps(v['actual'])).decode()
 raw=(text[:start]+segment+text[end:]).encode()
 proofs.append({'path':p,'old_sha256':v['expected'],'sha256':v['actual'],'authority':authority})
text=raw.decode(); start=text.index('  "legacy_source_sha256": {'); end=text.index('\n  }',start)
raw=(text[:end]+''.join(',\n    '+json.dumps(p)+': '+json.dumps(h) for p,h in d['extra'].items())+text[end:]).encode()
after={mp:raw,ip:once(before[ip],sha(before[mp]),sha(raw))}
new=json.loads(raw); rest=dict(new); rest['legacy_source_sha256']=m['legacy_source_sha256']
need(rest==m,'all non-source fields unchanged')
expected=dict(d['expected_sources']); actual=dict(d['actual_sources'])
for p,v in d['different'].items():expected[p]=v['actual']
expected.update(d['extra'])
for p,b in after.items():expected[p]=sha(b);actual[p]=sha(b)
need(expected==actual and len(actual)==2696,'exact full 2696 source set')
need(not OUT.exists(),'immutable output')
targets=[];hunks=[];originals={}
for p,b in after.items():
 name=p[6:].replace('/','__'); a=before[p]; aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);hh=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':hh.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 inv=b
 for h in reversed(hh):
  at=h['new_offset'];nb=h['new'].encode();need(inv[at:at+len(nb)]==nb,'inverse hunk');inv=inv[:at]+h['old'].encode()+inv[at+len(nb):]
 need(inv==a,'whole inverse')
 targets.append({'target':'game/'+p[6:],'candidate':'game/build/loading_20261106_system01/market_closure_READY01/'+name,'old_sha256':sha(a),'new_sha256':sha(b),'old_bytes':len(a),'bytes':len(b)})
 hunks.append({'target':'game/'+p[6:],'hunks':hh,'whole_inverse':True});originals[p]={'sha256':sha(a),'base64':base64.b64encode(a).decode()}
for p,b in before.items():need(read(p)==b,'unchanged during preparation')
OUT.mkdir()
for p,b in after.items():(OUT/p[6:].replace('/','__')).write_bytes(b)
save(OUT/'receipt.json',{'status':'ROOT_REVIEW_REQUIRED_NOT_INSTALLED','targets':targets,'extra22_different8_provenance':proofs,'full_source_set_count':2696,'canonical_writes':0,'OWNED_changes':0,'real_save_content_access':0})
save(OUT/'all_hunks.json',hunks);save(OUT/'original_bytes.json',originals)
print(json.dumps(targets))
