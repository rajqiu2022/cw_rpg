"""Independent exact dependency inverse; no engine/compiler/source-set crawl."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;BASE=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance05_dependencies'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):assert p.startswith('res://');return ROOT/p[6:]
def read(p,s):
    b=p.read_bytes();assert sha(b)==s;return json.loads(b)
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
h=read(BASE/'handoff_PRODUCTION_PROPOSAL.json','2140f39a3c61f87f089256b670f941b11a925c9b30f300e63d56c55a8acec3c7')
d=read(BASE/'dependency_inverse_READY.json','17f36f1cd4692e9434b991c5c0674b05aac383c2cfc57d0d720d2a688e957a04')
old=read(res(h['execution_parent']['snapshot']),h['execution_parent']['sha256'])
new=read(res(h['execution_proposal']['path']),'428a3484e0a995803d95677dbd36f545313c622142605fce292ffd493b6bea03')
assert len(old['owned'])==len(new['owned'])==10 and old['owned'].keys()==new['owned'].keys()
assert len(old['source_sha256'])==63 and len(new['source_sha256'])==67
assert all(new['source_sha256'].get(p)==s for p,s in old['source_sha256'].items())
added={p:s for p,s in new['source_sha256'].items() if p not in old['source_sha256']};assert same(added,h['new_proof_pins']) and len(added)==4
for p,s in added.items():assert sha(res(p).read_bytes())==s
changed={r['path']:r for r in h['owned_changed_exactly3']}
assert set(changed)=={'res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd'}
restored=copy.deepcopy(new)
for p,prior in old['owned'].items():
    current=new['owned'][p]
    if p not in changed:assert same(prior,current);continue
    assert len(current['edges'])==len(prior['edges'])+1 and same(current['edges'][:-1],prior['edges'])
    edge=current['edges'][-1];decl=changed[p]
    assert edge['old_sha256']==prior['current_sha256']==decl['old_sha256'] and edge['new_sha256']==current['current_sha256']==decl['new_sha256']
    restored['owned'][p]=copy.deepcopy(prior)
restored['source_sha256']=copy.deepcopy(old['source_sha256']);assert same(restored,old)
hashpath='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd';assert hashpath not in old['owned'] and hashpath not in new['owned']
inverse_rows=[]
for row in h['consumers']:
    parent=res(row['parent_snapshot']['path']).read_bytes();candidate=res(row['candidate']['path']).read_bytes()
    assert sha(parent)==row['old_sha256'] and sha(candidate)==row['candidate']['sha256'] and res(row['target']).read_bytes()==parent
    forward=parent.decode()
    for edit in row['forward_hunks']:assert forward.count(edit['old'])==1;forward=forward.replace(edit['old'],edit['new'],1)
    assert forward.encode()==candidate
    back=candidate.decode()
    for edit in row['inverse_replacements']:assert back.count(edit['new'])==1;back=back.replace(edit['new'],edit['old'],1)
    assert back.encode()==parent
    inverse_rows.append({'target':row['target'],'hunks':len(row['forward_hunks']),'whole_bytes_forward_inverse':True})
oldbindingpath=res(d['binding_parent']['path']);newbindingpath=res(d['binding']['path'])
ob=oldbindingpath.read_bytes();nb=newbindingpath.read_bytes();assert sha(ob)==d['binding_parent']['sha256'] and sha(nb)==d['binding']['sha256']
edit=d['binding_byte_hunks'];assert isinstance(edit,dict) and ob.count(edit['old'].encode())==1
assert ob.replace(edit['old'].encode(),edit['new'].encode(),1)==nb
assert nb.replace(edit['new'].encode(),edit['old'].encode(),1)==ob
ov=json.loads(ob);nv=json.loads(nb);expected=copy.deepcopy(ov)
assert hashpath not in expected['source_delta'];expected['source_delta'][hashpath]='85a7b0b86ca201679b227b1f39c7315bb7196b4d0943befa5397ce569fe650e1'
assert same(expected,nv)
base=read(res(ov['parent_binding_path']),ov['parent_binding_sha256'])
prior=copy.deepcopy(base['source_sha256']);prior.update(ov['source_delta'])
following=copy.deepcopy(base['source_sha256']);following.update(nv['source_delta'])
assert len(prior)==len(following)==189 and prior.keys()==following.keys()
assert [p for p in prior if prior[p]!=following[p]]==[hashpath]
assert prior[hashpath]=='80261e1bf9b34400c6aa99959d98502b648589fccf2138231f3907d9826d8b0b'
assert ob.count(b'\r\n')==163 and nb.count(b'\r\n')==164
assert ob.count(b'\n')-ob.count(b'\r\n')==nb.count(b'\n')-nb.count(b'\r\n')==1
out=QA/'performance05_dependency2140_independent_whole_inverse_review_READY.json'
r={'status':'INDEPENDENT_BUILD_DEPENDENCY_WHOLE_INVERSE_NO_STATIC_BLOCKER_PENDING_ROOT_AUTHORITY','handoff_sha256':'2140f39a3c61f87f089256b670f941b11a925c9b30f300e63d56c55a8acec3c7','execution_parent_sha256':h['execution_parent']['sha256'],'execution_proposal_sha256':h['execution_proposal']['sha256'],'whole_execution_typed_inverse':True,'owned_membership_count_unchanged':10,'only_three_appended_owned_edges':sorted(changed),'other_seven_owned_rows_exact':True,'old63_proof_pins_exact_plus4_to67':True,'hash_helper_remains_nonowned':True,'consumer_whole_byte_inverses':inverse_rows,'Temple_binding':{'only_new_source_delta_key':hashpath,'old_merged_count':189,'new_merged_count':189,'other188_merged_values_exact':True,'whole_typed_and_bytes_inverse':True,'old_CRLF':163,'new_CRLF':164,'explanation':'Original163CRLF+one bareLF preserved byte-for-byte, plus exactly one authorized inserted CRLF source row.','old_and_new_bareLF':1,'Temple_script_only_two_literal_replacements':True},'not_credit':['Root execution approval','source DAG stage/deployment','new parse of Temple literal successor','runtimeFIRSTFINAL or city speedup'],'engine_collector_source_crawl_calls':0,'canonical_writes':0,'blocking_findings':[]}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
