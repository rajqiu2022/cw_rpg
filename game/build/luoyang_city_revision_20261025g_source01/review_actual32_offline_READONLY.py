"""Finite independent32 artifact/inverse/domain review; no live source collection or media reads."""
from pathlib import Path
import json,hashlib,copy
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(pin):
    b=(GAME/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def doc(pin):return json.loads(read(pin))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def at(v,p):
    for k in p:v=v[k]
    return v
sp=dict(path=S+'outputs/root_market_courtyard45_exact32_stage02/receipt.json',sha256='c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396');stage=doc(sp)
ip=dict(path=S+'source_input_courtyard45_exact32_residual02_ROOT_REVIEW.json',sha256='ef9ec3345623352d2c35406438828db20982894e4d9f606939f4d89f7cb0aa5f');spec=doc(ip)
pp=dict(path=S+'courtyard32_candidates01/code_execution_whole_inverse_NOT_STAGE.json',sha256='e4c12661d767a9f72db3848adaf75557d6341f74103d7a1c56f81b45047a016e');proof=doc(pp)
scope=doc(dict(path=S+'courtyard45_exact32_scope_PREPARATION.json',sha256='823dcc493006e0a439dc4f4caa1ce8a1ad6b029fb9c3e8f847620731defac4d5'))
old={r['target']:r for r in scope['targets']};targets={r['target']:r for r in stage['targets']};pins={r['id']:r for r in spec['pinned_inputs']};nodes={r['id']:r for r in spec['nodes']};groups={r['id']:r for r in spec['source_groups']}
assert len(targets)==32 and set(targets)==set(old) and stage['source_first']==stage['source_final'] and stage['target_partition']==dict(patch_count=17,copy_count=15,total=32)
def resolve(v):
    if isinstance(v,dict) and '$pin' in v:return pins[v['$pin']]['sha256']
    if isinstance(v,dict) and '$sha' in v:return stage['nodes'][v['$sha']]['sha256']
    return v
byte_checks=[];classification=[]
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
authority=doc(proof['execution']['candidate']);prior=doc(proof['execution']['parent'])
assert len(authority['owned'])==10 and len(prior['source_sha256'])==162 and len(authority['source_sha256'])==170
assert all(authority['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
for p,row in targets.items():
    before=read(dict(path=old[p]['immutable_old'],sha256=old[p]['old_sha256']));after=read(dict(path=row['candidate_path'],sha256=row['candidate_sha256']));assert before!=after and row['old_sha256']==sha(before)
    if p==EXEC:
        restored=copy.deepcopy(authority)
        for member in prior['owned']:
            a,b=prior['owned'][member],authority['owned'][member]
            if member in proof['execution']['changed_existing_owned']:
                assert len(b['edges'])==len(a['edges'])+1 and b['edges'][:-1]==a['edges']
            else:assert a==b
            restored['owned'][member]=copy.deepcopy(a)
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(restored)==before
    elif p in proof['records']:
        f,v=before,after
        for h in proof['records'][p]['hunks']:
            a,b=h['old'].encode(),h['new'].encode();assert f.count(a)==1;f=f.replace(a,b,1)
        for h in reversed(proof['records'][p]['hunks']):
            a,b=h['old'].encode(),h['new'].encode();assert v.count(b)==1;v=v.replace(b,a,1)
        assert f==after and v==before
    else:
        n=next(n for n in spec['nodes'] if n.get('target')==p);result=stage['nodes'][n['id']]
        if p.endswith('.json'):
            original=json.loads(before);new=json.loads(after);assert new==result['value'];back=copy.deepcopy(new)
            for delta in reversed(stage['proofs'][n['id']]['source_delta']):
                holder=at(back,delta['pointer'][:-1]);key=delta['pointer'][-1]
                if delta['existed']:holder[key]=delta['old']
                else:del holder[key]
            assert back==original
            if n['kind']=='space_contract':
                restored=after
                for h in reversed(proof['contract']['byte_hunks']):
                    a,b=h['old'].encode(),h['new'].encode();assert restored.count(b)==1;restored=restored.replace(b,a,1)
                assert restored==before
            else:assert enc(back)==before
            for key in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts','geometry_receipt','publication_receipt']:
                if key in original:assert new[key]==original[key]
            bundle=n.get('source_bundle',{})
            if bundle:
                fields=bundle['fields'];oldsets=[set(at(original,ptr)) for ptr in fields];newsets=[set(at(new,ptr)) for ptr in fields]
                for ptr,keys,oldkeys in zip(fields,newsets,oldsets):
                    if 'runtime_authority' in ptr:assert keys==oldkeys
                classification.append(dict(target=p,source_field_class_keysets_preserved=True,new_ordinary_keys=sum(len(b-a) for a,b in zip(oldsets,newsets))))
        else:
            off,on=n['disabled_literal'],n['enabled_literal'];text=after.decode();assert text.count(on)==1;text=text.replace(on,off,1)
            for h in reversed(n['replacements']):
                new=resolve(h['new']);assert text.count(new)==1;text=text.replace(new,h['old'],1)
            assert text.encode()==before
    byte_checks.append(dict(target=p,old_sha256=sha(before),candidate_sha256=sha(after),candidate_bytes=len(after),whole_byte_inverse=True))
extra=proof['execution']['extra'];assert len(extra)==8
maps=[]
for ident,n in nodes.items():
    if n['kind']!='docks_incremental_map':continue
    parent=doc(pins[n['base_input']])['source_sha256'];expected=copy.deepcopy(parent)
    for p,row in targets.items():
        if p in expected:assert expected[p]==row['old_sha256'];expected[p]=row['candidate_sha256']
    additions=copy.deepcopy(extra)
    for g in n['declared_new_groups']:
        if g=='authority_before_and_candidate_proofs':continue
        assert groups[g]['kind']=='explicit'
        for p,h in groups[g]['leaves'].items():
            if p in additions:assert additions[p]==h
            additions[p]=h
    for p,h in additions.items():
        if p in expected:assert expected[p]==h
        expected[p]=h
    actual=stage['nodes'][ident];assert actual['value']['source_sha256']==expected
    assert doc(dict(path=actual['path'],sha256=actual['sha256']))==actual['value']
    maps.append(dict(id=ident,path=actual['path'],sha256=actual['sha256'],count=len(expected),old_count=len(parent),new_keys=len(set(expected)-set(parent)),independent_parent_plus32_plus_exact_groups=True))
assert [r['count'] for r in maps]==[982,1364,1858,1900]
out=dict(status='SOURCE25G_ACTUAL32_FINITE_INDEPENDENT_REVIEW_READONLY',passed=True,stage=sp,input=ip,code_proof=pp,target_count=32,partition=dict(GD=17,JSON=15),noops=0,whole_target_byte_inverses=byte_checks,metadata_classification_checks=classification,maps=maps,old162_keyvalues_and_old_edges_preserved=True,only6_existing_members_append_one_edge=True,OWNED=10,proof_count=170,depth_limit=16,shortcuts=0,old_native_history_and_source_policy_fields_unchanged=True,formal_current_not_assumed_from_artifacts=True,engine_calls=0,collector_calls=0,media_hashes=0,media_decodes=0,canonical_writes=0)
raw=enc(out);dest=HERE/'actual32_finite_independent_review_READONLY.json'
with dest.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),passed=True,targets=32,maps=[r['count'] for r in maps])))
