"""Single Router constant successor plus the existing exact nine closure targets.
Run only after Root's one-room publisher. Candidate output only, CreateNew.
"""
from pathlib import Path
import hashlib,json,re,sys,copy,difflib
GAME=Path(__file__).resolve().parents[2]
ROOTBASE=Path(__file__).resolve().parent
RESIDUAL='--residual03'in sys.argv
THRESHOLD='--threshold29o'in sys.argv
HALL='--hall29p'in sys.argv
GARDEN='--garden29q'in sys.argv
BASE=GAME/'build/luoyang_estate_garden_20261029q_system01' if GARDEN else (GAME/'build/luoyang_hall_boundary_20261029p_system01' if HALL else (GAME/'build/luoyang_threshold_20261029o_system01' if THRESHOLD else (ROOTBASE/'visual03' if RESIDUAL else ROOTBASE)))
OUT=BASE/'closure_READY01'
PREFIX='res://'+BASE.relative_to(GAME).as_posix()+'/closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p.removeprefix('res://')).read_bytes()
def once(b,o,n):
 o=o.encode()if isinstance(o,str)else o;n=n.encode()if isinstance(n,str)else n
 assert b.count(o)==1,(o[:90],b.count(o))
 return b.replace(o,n,1)
def put(name,b):
 p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return PREFIX+name
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def addpin(b,name,path,digest):
 marker=('  "'+name+'": {').encode();s=b.index(marker);e=b.index(b'\n  }',s)
 fragment=(',\n    "'+path+'": "'+digest+'"').encode()
 assert path not in json.loads(b)[name]
 return b[:e]+fragment+b[e:],fragment
def literals(raw,replacements):
 result=raw
 for old,new in replacements:result=once(result,old,new)
 inverse=result
 for old,new in reversed(replacements):inverse=once(inverse,new,old)
 assert inverse==raw
 return result
result_path=Path(sys.argv[1]).resolve()
pub=json.loads(result_path.read_bytes());assert pub['passed'] and pub['production_writes']==0
manifest_path=pub['manifest']['path'];manifest=read(manifest_path)
assert sha(manifest)==pub['manifest']['sha256']
if GARDEN:
 baseline={r['target']:{'sha256':r['new_sha256']}for r in json.loads((GAME/'build/luoyang_hall_boundary_20261029p_system01/closure_READY01/receipt_READY.json').read_bytes())['targets']}
 # Root-approved concurrent Linxi successor is the actual public Router head.
 # Preserve all its code/edges/source keys; only this batch's Region SHA changes.
 baseline.update({'game/'+r['path'][6:]:{'sha256':r['after']}for r in json.loads((GAME.parent/'assets/staging/linxi_entry_repair_20261029q/closure.json').read_bytes())['targets']})
 baseline.update({r['target']:{'sha256':r['old_sha256']}for r in json.loads((BASE/'runtime_hunks_READY.json').read_bytes())['targets']})
elif HALL:
 baseline={r['target']:{'sha256':r['new_sha256']}for r in json.loads((GAME/'build/luoyang_threshold_20261029o_system01/closure_READY01/receipt_READY.json').read_bytes())['targets']}
 baseline.update({r['target']:{'sha256':r['old_sha256']}for r in json.loads((BASE/'runtime_hunks_READY.json').read_bytes())['targets']})
elif THRESHOLD:
 baseline={r['target']:{'sha256':r['new_sha256']}for r in json.loads((ROOTBASE/'visual03/closure_READY01/receipt_READY.json').read_bytes())['targets']}
 baseline.update({r['target']:{'sha256':r['new_sha256']}for r in json.loads((ROOTBASE/'closure_READY01/receipt_READY.json').read_bytes())['targets']if r['target'].endswith('/region_entry.gd')})
elif RESIDUAL:
 baseline={r['target']:{'sha256':r['new_sha256']}for r in json.loads((ROOTBASE/'closure_READY01/receipt_READY.json').read_bytes())['targets']}
else:
 baseline=json.loads((GAME/'build/luoyang_yihongyuan_20261029n_qa01/baseline_before_ACTUAL.json').read_bytes())['sources']
for p,fact in baseline.items():assert sha((GAME.parent/p).read_bytes())==fact['sha256'],p
rp='res://scripts/autoload/scene_router.gd';ep='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
gp='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
bi='res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
qp='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
qi='res://scripts/city/luoyang_quarters_index_20261022ap.gd'
dp='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
di='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
paths=[rp,ep,ei,gp,bi,qp,qi,dp,di]
before={p:read(p)for p in paths};after={}
router=before[rp]
old_header=re.search(rb'const REGION27D_AUTHOR_SHA := "([a-f0-9]{64})"',router).group(0)
new_header=b'const REGION27D_AUTHOR_SHA := "'+sha(manifest).encode()+b'"'
after[rp]=literals(router,[(old_header,new_header)])
oldex=json.loads(before[ep]);oldrow=oldex['owned'][rp]
assert oldrow['current_sha256']==sha(router)
old_snapshot=oldrow['edges'][-1]['new_snapshot']
assert old_snapshot.startswith('res://build/luoyang_') and read(old_snapshot)==router
snapshot=PREFIX+'Router_READY.gd'
edge={'path':rp,'old_sha256':sha(router),'new_sha256':sha(after[rp]),'old_snapshot':old_snapshot,'new_snapshot':snapshot,'whole_inverse':True,'replacements':[{'old':old_header.decode(),'new':new_header.decode()}]}
newrow=copy.deepcopy(oldrow);newrow['current_sha256']=sha(after[rp]);newrow['edges'].append(edge)
text=before[ep].decode();start=text.index('    "'+rp+'": {')+len('    "'+rp+'": ')
_,used=json.JSONDecoder().raw_decode(text[start:]);row_before=text[start:start+used].encode()
row_after=json.dumps(newrow,ensure_ascii=False,indent=2).replace('\n','\n    ').encode()
changed=once(before[ep],row_before,row_after)
after[ep],pin=addpin(changed,'source_sha256',snapshot,sha(after[rp]))
assert once(once(after[ep],pin,b''),row_after,row_before)==before[ep]
newex=json.loads(after[ep]);assert newex['owned'][rp]['edges'][:-1]==oldrow['edges']
assert all(newex['source_sha256'][p]==h for p,h in oldex['source_sha256'].items())
assert len(newex['source_sha256'])==len(oldex['source_sha256'])+1
after[ei]=literals(before[ei],[(sha(before[ep]),sha(after[ep]))])
for p in [gp,dp]:
 edits=[('"'+rp+'": "'+sha(router)+'"','"'+rp+'": "'+sha(after[rp])+'"'),('"'+ep+'": "'+sha(before[ep])+'"','"'+ep+'": "'+sha(after[ep])+'"')]
 b=literals(before[p],edits);after[p],insert=addpin(b,'legacy_source_sha256',snapshot,sha(after[rp]))
 inverse=once(after[p],insert,b'')
 for old,new in reversed(edits):inverse=once(inverse,new,old)
 assert inverse==before[p]
edits=[('"'+ep+'": "'+sha(before[ep])+'"','"'+ep+'": "'+sha(after[ep])+'"'),('"'+ei+'": "'+sha(before[ei])+'"','"'+ei+'": "'+sha(after[ei])+'"')]
b=literals(before[qp],edits);after[qp],insert=addpin(b,'source_sha256',snapshot,sha(after[rp]))
inverse=once(after[qp],insert,b'')
for old,new in reversed(edits):inverse=once(inverse,new,old)
assert inverse==before[qp]
for p,source in [(bi,gp),(qi,qp),(di,dp)]:after[p]=literals(before[p],[(sha(before[source]),sha(after[source]))])
names=['Router_READY.gd','execution_successor_READY.json','execution_index_READY.gd','gate_bundle_manifest_READY.json','bundle_index_READY.gd','quarters_manifest_READY.json','quarters_index_READY.gd','docks_ac_manifest_READY.json','docks_ac_index_READY.gd']
rows=[];hunks=[]
def delta(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);parts=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op=='equal':continue
  s=max(0,i-1);e=min(len(aa),j+1)
  parts.append({'old':''.join(aa[s:e]),'new':''.join(aa[s:i])+''.join(bb[k:l])+''.join(aa[j:e])})
 test=a
 for h in parts:test=once(test,h['old'],h['new'])
 assert test==b
 return parts
for p,name in zip(paths,names):
 candidate=put(name,after[p])
 rows.append({'target':'game/'+p[6:],'candidate':'game/'+candidate[6:],'old_sha256':sha(before[p]),'new_sha256':sha(after[p]),'bytes':len(after[p]),'whole_inverse':True})
 if p.endswith('.gd'):hunks.append({'target':'game/'+p[6:],'replacements':delta(before[p],after[p])})
runtime={'targets':[]}if RESIDUAL else json.loads((BASE/'runtime_hunks_READY.json').read_bytes())
for row in runtime['targets']:
 data=(GAME.parent/row['candidate']).read_bytes();assert sha(data)==row['new_sha256']
 rows.append(row);hunks.append({'target':row['target'],'replacements':row['replacements']})
mp='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
rows.append({'target':'game/'+mp[6:],'candidate':'game/'+manifest_path[6:],'old_sha256':sha(read(mp)),'new_sha256':sha(manifest),'bytes':len(manifest)})
assert len(rows)==(12 if GARDEN else (11 if (THRESHOLD or HALL) else (10 if RESIDUAL else 12)))
put('hunks_READY.json',enc({'targets':hunks}))
put('receipt_READY.json',enc({'status':('EXACT12_GARDEN_READY_NOT_DEPLOYED'if GARDEN else ('EXACT11_HALL_BOUNDARY_READY_NOT_DEPLOYED'if HALL else ('EXACT11_THRESHOLD_READY_NOT_DEPLOYED'if THRESHOLD else ('EXACT10_VISUAL_RESIDUAL_READY_NOT_DEPLOYED'if RESIDUAL else 'EXACT12_READY_NOT_DEPLOYED')))),'targets':rows,'router_edges_before':len(oldrow['edges']),'router_edges_after':len(newrow['edges']),'old_EX_keys_preserved':True,('all_ten_bins_preserved'if HALL else ('old_nine_bins_preserved'if (THRESHOLD or GARDEN) else 'old_eight_bins_preserved')):True,'canonical_writes':0,'engine_runs':0,'publication':pub}))
sources={r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes'] if 'bytes'in r else len((GAME.parent/r['candidate']).read_bytes())}for r in rows}
new_modules={}
for p in BASE.glob('*.gd'):
 if p.name.endswith('_READY.gd'):continue
 data=p.read_bytes();new_modules[str(p.relative_to(GAME.parent)).replace('\\','/')]={'sha256':sha(data),'bytes':len(data)}
dependencies=[BASE/'garden_definition_READY.json']if GARDEN else ([BASE/'room_patch.gdshader']if HALL else ([BASE/'repair_definition_READY.json']if (RESIDUAL or THRESHOLD) else [BASE/'interior_definition_CANDIDATE.json',BASE/'yihongyuan27n_interior.tres',GAME/json.loads(manifest)['author']['path'][6:],GAME.parent/'game/build/luoyang_yihongyuan_20261029n_art01/asset_and_layout_spec.json']))
dependencies += []if HALL else ([GAME/pub['estate']['path'][6:]]if (THRESHOLD or GARDEN) else [GAME/pub['civic']['path'][6:],GAME/pub['room']['path'][6:]])
for p in dependencies:
 data=p.read_bytes();new_modules[str(p.relative_to(GAME.parent)).replace('\\','/')]={'sha256':sha(data),'bytes':len(data)}
new_modules['game/'+snapshot[6:]]={'sha256':sha(after[rp]),'bytes':len(after[rp])}
canonical=[]if (RESIDUAL or THRESHOLD or HALL or GARDEN) else [{'target':'game/data/scenes/yihongyuan27n_interior.tres','candidate':'game/build/luoyang_yihongyuan_20261029n_system01/yihongyuan27n_interior.tres','sha256':sha((BASE/'yihongyuan27n_interior.tres').read_bytes())}]
put('auth_READY.json',enc({'sources':sources,'new_modules':new_modules,'new_targets':canonical,'canonical_writes':0}))
print(json.dumps({'target_count':len(rows),'edges':len(newrow['edges']),'auth_sha256':sha((OUT/'auth_READY.json').read_bytes()),'receipt_sha256':sha((OUT/'receipt_READY.json').read_bytes()),'canonical_writes':0}))
