"""B-only execution exact inverse and Root22 old-byte scope review, no Stage."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;D=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance12_B_only_dependencies'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def load(p,h):
    b=p.read_bytes();assert sha(b)==h;return json.loads(b),b
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
h,_=load(D/'handoff_PRODUCTION_PROPOSAL.json','0b475ef75769431cb02b46a2a6e3daab6312ab3a7289b837d361ad2bdedfb79c')
old,oldraw=load(res(h['execution_parent']['snapshot']),h['execution_parent']['sha256']);new,newraw=load(res(h['execution_proposal']['path']),h['execution_proposal']['sha256'])
assert h['execution_parent']['sha256']=='428a3484e0a995803d95677dbd36f545313c622142605fce292ffd493b6bea03'
assert h['execution_proposal']['sha256']=='a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283'
assert len(old['owned'])==len(new['owned'])==10 and old['owned'].keys()==new['owned'].keys()
assert len(h['owned_changed_exactly1'])==1;edge=h['owned_changed_exactly1'][0];bp=edge['path']
assert bp=='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
assert len(new['owned'][bp]['edges'])==len(old['owned'][bp]['edges'])+1 and same(new['owned'][bp]['edges'][:-1],old['owned'][bp]['edges'])and same(new['owned'][bp]['edges'][-1],edge)
assert new['owned'][bp]['current_sha256']==edge['new_sha256']and old['owned'][bp]['current_sha256']==edge['old_sha256']
for p in old['owned']:
    if p!=bp:assert same(old['owned'][p],new['owned'][p])
assert len(old['source_sha256'])==67 and len(new['source_sha256'])==69 and all(new['source_sha256'][p]==s for p,s in old['source_sha256'].items())
extra={p:s for p,s in new['source_sha256'].items()if p not in old['source_sha256']};assert same(extra,h['new_proof_pins'])and len(extra)==2
back=copy.deepcopy(new);back['owned'][bp]=copy.deepcopy(old['owned'][bp]);back['source_sha256']=copy.deepcopy(old['source_sha256'])
assert same(back,old)and (json.dumps(back,indent=2)+'\n').encode()==oldraw
before=res(edge['old_snapshot']).read_bytes();after=res(edge['new_snapshot']).read_bytes();assert sha(before)==edge['old_sha256']and sha(after)==edge['new_sha256']
text=after.decode()
for row in reversed(edge['replacements']):assert text.count(row['new'])==1;text=text.replace(row['new'],row['old'],1)
assert text.encode()==before
scope,_=load(D/'exact22_existing_scope_PROPOSAL_NOT_APPROVED.json','0df58c434b6bf549c2fd7fcf37b4587a91067d7664a90ba588d95196dcb33b47')
root,_=load(ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration21/scope22_full_old_backups_READY.json','f028426e4d70e80a822d3f41dc23cccd371e19807d94730b672f6d1d7a1dffc5')
assert root['approved_by_root']and root['target_count']==scope['target_count']==22 and root['GD_count']==9 and root['JSON_count']==13
assert not root['stage_execution_authorized']and not root['formal_deployment_authorized']
targets={r['target']:r['old_sha256']for r in scope['targets']};assert len(targets)==22 and targets=={r['target']:r['old_sha256']for r in root['targets']}
assert sum(p.endswith('.gd')for p in targets)==9 and sum(p.endswith('.json')for p in targets)==13
for row in root['targets']:
    b=res(row['target']).read_bytes();backup=Path(row['backup_path']).read_bytes();assert b==backup and sha(b)==row['old_sha256']==row['backup_sha256']
assert all(not p.endswith('/'+name)for p in targets for name in ['luoyang_district_life_20261016f.gd','luoyang_parallel_source_hash_20261017k.gd','luoyang_temple_assembly_20261016.gd'])
assert 'res://data/maps/luoyang_estate_rooms_20261021am/registry.json'not in targets
out=QA/'performance12_Bonly_executionA816_scope22_independent_static_review_READY.json'
r={'status':'INDEPENDENT_BONLY_EXECUTION_AND_ROOT22_SCOPE_NO_BLOCKER_NOT_STAGE_OR_DEPLOYMENT','execution_parent_sha256':h['execution_parent']['sha256'],'execution_proposal_sha256':h['execution_proposal']['sha256'],'ten_owned_members_same_only_B_one_edge':True,'other9_owned_rows_wholetyped_same':True,'old67_proof_pins_unchanged_plus_exact2':True,'whole_execution_typed_and_serialized_inverse':True,'B_candidate_whole_byte_inverse77DFC':True,'Root22_current_old_and_full_backup_bytes_exact':True,'partition':{'GD':9,'JSON':13},'DT_hash_Temple_registry_excluded':True,'Stage_engine_collector_native_decode_calls':0,'canonical_writes':0,'blocking_findings':[],'pending':'Final driver/input DAG separately required; this receipt is not stage authorization.'}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
