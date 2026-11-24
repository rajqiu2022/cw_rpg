"""One finite source/deployment audit; no Stage import, collector or native decode."""
from pathlib import Path
import json,hashlib,copy,re,datetime
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025f_source01/';S24='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261025f_root01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def resolve(p):return GAME/p[6:]
def read(pin):
    raw=resolve(pin['path']).read_bytes();assert sha(raw)==pin['sha256'].lower(),pin['path'];return raw
def load(pin):return json.loads(read(pin))
def at(v,ptr):
    for k in ptr:v=v[k]
    return v
stagepin=dict(path=S+'outputs/root_street_materials_exact18_stage01/receipt.json',sha256='9876e1cc4bab5e292d9d15052b7758c7d4f1ce5e98fecfb49fda4b6f45feff67')
deppin=dict(path=R+'street_materials18_deployed_actual.json',sha256='9154c72b8240aff417c3af7c910f3b78659b83814ee06cf681aed644d8caf734')
scopepin=dict(path=S+'street_materials18_scope_PREPARATION.json',sha256='c6920eb563c899186b3091cf2acb69cc70d592ec394e7603c49585671ef4428b')
stage=load(stagepin);dep=load(deppin);scope=load(scopepin)
assert stage['status']=='STREET_MATERIALS_EXACT18_STAGED_NOT_DEPLOYED' and stage['target_partition']==dict(patch_count=7,copy_count=11,total=18) and stage['source_first']==stage['source_final']
assert dep['stage_sha256']==stagepin['sha256'] and dep['GD_apply_patch']==7 and dep['JSON_exact_copy']==11
rows={r['target']:r for r in stage['targets']};old={r['target']:r for r in scope['targets']};deployed={r['target']:r for r in dep['targets']};assert set(rows)==set(old)==set(deployed) and len(rows)==18
spec=load(dict(path=S+'source_input_street_materials18_ROOT_REVIEW.json',sha256='a0d03ff0c7011a926d25b216c9a928ef29e619464ff35b31dcad93b74f25b797'));pins={r['id']:r for r in spec['pinned_inputs']};node_rows={n['id']:n for n in spec['nodes']};nodes=stage['nodes'];code=load(dict(path=S+'ENV_materials18_whole_inverse_NOT_STAGE.json',sha256='16e841bb2af32c5747281125c18e8bfe295dbc35c864d5fdbf95f08f2940fb42'))
target_checks=[];json_checks=[];index_checks=[]
new3=code['new_Market_only_ordinary3'];market_nodes={'legacy_manifest_5','legacy_manifest_8','market_final','finite08_market'}
def value(v):
    if isinstance(v,dict) and '$sha' in v:return nodes[v['$sha']]['sha256']
    if isinstance(v,dict) and '$pin' in v:return pins[v['$pin']]['sha256']
    return v
for p,r in rows.items():
    assert r['old_sha256']==old[p]['old_sha256'];after=read(dict(path=r['candidate_path'],sha256=r['candidate_sha256']));before=read(dict(path=old[p]['immutable_old'],sha256=old[p]['old_sha256']))
    assert len(before)==old[p]['old_bytes'] and deployed[p]['sha256']==r['candidate_sha256'] and deployed[p]['bytes']==len(after)
    current=resolve(p).read_bytes();assert current==after;target_checks.append(dict(target=p,candidate_sha256=r['candidate_sha256'],bytes=len(after),current_exact=True))
    if p.endswith('.json'):
        ident=next(k for k,n in nodes.items() if n['path']==r['candidate_path']);n=node_rows[ident];a,b=json.loads(before),json.loads(after);back=copy.deepcopy(b)
        assert stage['proofs'][ident]['whole_typed_inverse'] is True
        for d in reversed(stage['proofs'][ident]['source_delta']):
            holder=at(back,d['pointer'][:-1]);key=d['pointer'][-1]
            if d['existed']:holder[key]=d['old']
            else:del holder[key]
        assert enc(back)==before
        added={}
        fields=n.get('source_bundle',{}).get('fields',[])+[f['pointer'] for f in n.get('source_fields',[])]
        for ptr in fields:
            av,bv=at(a,ptr),at(b,ptr);assert set(av)<=set(bv)
            for key,h in av.items():
                expected=rows[key]['candidate_sha256'] if key in rows else h
                assert bv[key]==expected,(ident,ptr,key)
            added.update({key:h for key,h in bv.items() if key not in av})
        assert added==(new3 if ident in market_nodes else {})
        if ident in market_nodes:assert all(b['legacy_source_sha256'].get(k)==h for k,h in new3.items())
        for ptr in n.get('protected_pointers',[]):assert enc(at(a,ptr))==enc(at(b,ptr))
        for key in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts']:
            if key in a:assert enc(a[key])==enc(b[key])
        json_checks.append(dict(id=ident,target=p,whole_typed_and_serialized_UTF8_inverse=True,all_existing_class_keys_and_non_target_values_same=True,new_ordinary_keys=added,protected_native_geometry_fields_same=True))
    elif p in code['records']:
        ops=code['records'][p]['hunks'];f,v=before,after
        for h in ops:
            x,y=h['old'].encode(),h['new'].encode();assert f.count(x)==1;f=f.replace(x,y,1)
        for h in reversed(ops):
            x,y=h['old'].encode(),h['new'].encode();assert v.count(y)==1;v=v.replace(y,x,1)
        assert f==after and v==before
    else:
        ident=next(k for k,n in nodes.items() if n['path']==r['candidate_path']);n=node_rows[ident];text=before.decode();replacements=[]
        for h in n['replacements']:
            new=value(h['new']);assert text.count(h['old'])==1;text=text.replace(h['old'],new,1);replacements.append((h['old'],new))
        disabled=read(dict(path=nodes[ident]['disabled_path'],sha256=nodes[ident]['disabled_sha256']));assert text.encode()==disabled
        off,on=n['disabled_literal'],n['enabled_literal'];assert text.count(off)==1 and text.replace(off,on).encode()==after
        inverse=after.decode().replace(on,off)
        for oldval,newval in reversed(replacements):assert inverse.count(newval)==1;inverse=inverse.replace(newval,oldval,1)
        assert inverse.encode()==before;index_checks.append(dict(id=ident,target=p,full_byte_forward_inverse=True,sole_disabled_enabled_bool=True))
assert len(json_checks)==11 and len(index_checks)==6
parent=load(dict(path=S24+'outputs/root_docks_frontages_exact31_stage03/receipt.json',sha256='8ea2ed3e987510ace0ef772e4f683468b714e77c6648f7c086e234520f9bd826'))
fresh=load(dict(path=S+'fresh_current25f02_READONLY.json',sha256='e92b03c9ca2e5e5a95bfc8f8bf1451e8550a5d841a366bc2c1c2c0d738775a22'));all33={r['target']:dict(r['expected_from_fixed_deployment_or_immutable']) for r in fresh['all_33_declared_target_checks']}
for p,r in rows.items():all33[p]=dict(sha256=r['candidate_sha256'],bytes=deployed[p]['bytes'])
assert len(all33)==33
for p,pin in all33.items():
    b=resolve(p).read_bytes();assert sha(b)==pin['sha256'] and len(b)==pin['bytes'],p
map_checks=[]
for ident,n in nodes.items():
    if not ident.startswith('expected_'):continue
    prior=parent['nodes'][ident];before=load(dict(path=prior['path'],sha256=prior['sha256']))['source_sha256'];expected=copy.deepcopy(before)
    for p,r in rows.items():
        if p in expected:assert expected[p]==r['old_sha256'];expected[p]=r['candidate_sha256']
    if ident.endswith('market_true'):expected.update(new3)
    actual=load(dict(path=n['path'],sha256=n['sha256']));assert enc(expected)==enc(actual['source_sha256']) and expected==n['value']['source_sha256']
    map_checks.append(dict(id=ident,path=n['path'],sha256=n['sha256'],count=len(expected),independent_fixed8EA2_plus_exact18_and_only_Market3=True))
authoritypin=code['execution_frozen'];authoritybytes=read(authoritypin);assert resolve('res://data/maps/luoyang_full_city_20261022ap/execution_successor.json').read_bytes()==authoritybytes
authority=json.loads(authoritybytes);assert len(authority['owned'])==10 and len(authority['source_sha256'])==162
backup=load(dict(path=R+'predeploy18_backup_receipt.json',sha256='8d205d0cd8b4cb73e2bee5d444ccb39755458b22e2f12db78e728b2d95414444'));assert backup['count']==len(backup['targets'])==18
for r in backup['targets']:
    raw=Path(r['backup']).read_bytes();assert sha(raw)==old[r['target']]['old_sha256']==r['backup_sha256'] and len(raw)==old[r['target']]['old_bytes']==r['bytes']
patch=read(dict(path=stage['patch_path'],sha256=stage['patch_sha256'])).decode();patch_paths=re.findall(r'^\*\*\* Update File: (.+)$',patch,re.M);assert len(patch_paths)==7
assert {Path(p).resolve() for p in patch_paths}=={resolve(p).resolve() for p in rows if p.endswith('.gd')}
copyplan=load(stage['byte_copy_plan']);assert len(copyplan['rows'])==11 and {r['target'] for r in copyplan['rows']}=={p for p in rows if p.endswith('.json')}
doc=dict(status='SOURCE25F_ACTUAL18_LIMITED_INDEPENDENT_REVIEW_PASSED_NOT_FIELD',passed=True,stage=stagepin,deployment=deppin,scope=scopepin,target_count=18,partition=dict(GD=7,JSON=11),target_checks=target_checks,current33_fixed_deployment_candidates_exact=True,json_inverse11=json_checks,index_inverse6=index_checks,ENV_one_whole_byte_hunk_verified=True,map_checks=map_checks,old_execution=dict(**authoritypin,whole_bytes_unchanged=True,OWNED=10,proofs=162,depth_limit16_not_modified=True),new18_full_backups_SHA_bytes_same=True,old98_current_backup_rehash_not_repeated=True,source_first_final_same=True,source_classification_existing_keys_unchanged=True,new3_Market_legacy_only=True,native_protection=dict(no_native_or_media_targets=True,protected_artifact_geometry_mask_history_fields_full_same=True,no_PNG_packet_or_geometry_decode=True,current_full_native_hash_not_repeated=True),Field_runtime_and_whole_street_ART_not_claimed=True,Stage_imports=0,Stage_calls=0,collector_calls=0,engine_calls=0,canonical_writes=0,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
raw=enc(doc);dest=HERE/'actual18_limited_independent_review_READONLY.json';assert not dest.exists();dest.write_bytes(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),passed=True,targets=18,current=33,json_inverse=11,index_inverse=6,map_counts=[r['count'] for r in map_checks])))
