"""Root-only text freezer. Exact Stage35/deploy35; no current source filling."""
from pathlib import Path
import copy, hashlib, json, difflib

Q=Path(__file__).resolve().parent
GAME=Q.parent.parent
OUT=Q/'root_market_journey35_worker_facts_READY'
OLD_KEY=Q/'root_market_journey36_coordinate_version_READY/test_READY.gd'
OLD_FIXTURE=Q/'root_market_journey36_READY/fixture_READY.json'
S='res://build/luoyang_city_space_20261024b_source01/'
STAGE=S+'outputs/root_market_worker_facts_exact35_stage01/receipt.json'
STAGE_SHA='af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c'
DEPLOY='res://build/luoyang_city_revision_20261024b_root01/deployment35_worker_facts_actual.json'
DEPLOY_SHA='a93d0241fcb35cbaa5e4c4e31384495fd2b4f4d7c55ef3838b384ca075280d62'
MAP_SHA='6321e69db1a42ce7b8f06bd0e930a95bf5f89286ac95f50bb44e9de395ef3964'
OLD_FIXTURE_SHA='98aed550ea2313ed17c7c800845828e13bc9dfd85a06abcfe098ad9c1c398d88'
OLD_KEY_SHA='f22305ce466b074b26efd101b968b09ac1aeff126ca62f3dc7ce437f911cb521'

def sha(raw): return hashlib.sha256(raw).hexdigest()
def res(path): return 'res://'+path.resolve().relative_to(GAME.resolve()).as_posix()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME/p[6:]
def read(p,h):
    raw=path(p).read_bytes();assert sha(raw)==h,p
    return json.loads(raw)
def encoded(value): return (json.dumps(value,ensure_ascii=True,indent=2)+'\n').encode('ascii')

def main():
    assert not OUT.exists(),'NEW output only; no overwrite'
    stage=read(STAGE,STAGE_SHA);deploy=read(DEPLOY,DEPLOY_SHA)
    assert stage['status']=='MARKET_DIALOGUE_EXACT35_STAGED_NOT_DEPLOYED'
    assert stage['target_partition']=={'patch_count':20,'copy_count':15,'total':35}
    assert len(stage['targets'])==35 and stage['source_first']==stage['source_final'] and len(stage['source_first'])==3168
    assert deploy['status']=='ROOT_EXACT35_DEPLOYED_FIRST_FINAL_VERIFIED' and deploy['passed'] is True
    assert deploy['stage']=={'path':STAGE,'sha256':STAGE_SHA}
    assert deploy['target_count']==35 and deploy['partition']=={'apply_patch_GD':20,'exact_copy_JSON':15}
    approved={r['target']:r for r in stage['targets']}
    assert len(approved)==35 and len(deploy['targets'])==35
    seen=set()
    for row in deploy['targets']:
        assert set(row)=={'target','old_sha256','candidate_path','candidate_sha256','actual_sha256','bytes'}
        target=row['target'];assert target in approved and target not in seen;seen.add(target)
        original=approved[target]
        assert row['old_sha256']==original['old_sha256']
        assert path(row['candidate_path']).resolve()==path(original['candidate_path']).resolve()
        assert row['candidate_sha256']==row['actual_sha256']==original['candidate_sha256']
        assert type(row['bytes']) is int and row['bytes']>0
    assert seen==set(approved)
    node=stage['nodes']['expected_ch4_s3_luoyang_market_true']
    assert node['sha256']==MAP_SHA
    declared=read(node['path'],MAP_SHA)
    assert declared==node['value'] and declared['scene_id']=='ch4_s3_luoyang_market'
    sources=declared['source_sha256'];assert len(sources)==1808
    assert all(type(k) is str and k.startswith('res://') and '..' not in k and type(v) is str and len(v)==64 for k,v in sources.items())
    oldraw=OLD_FIXTURE.read_bytes();assert sha(oldraw)==OLD_FIXTURE_SHA
    old=json.loads(oldraw);fixture=copy.deepcopy(old)
    assert old['expected_city_count']==1797 and old['whole_ms']==60000 and old['entry_ms']==20000 and old['max_pictures']==3
    fixture.update(expected_city_sources=copy.deepcopy(sources),expected_city_count=1808,
        independent_owner={'path':node['path'],'sha256':MAP_SHA,'kind':'ACTUAL_SOURCE_STAGE_INDEPENDENT_MAP_NOT_COLLECTOR'},
        stage_receipt={'path':STAGE,'sha256':STAGE_SHA},deployment_actual={'path':DEPLOY,'sha256':DEPLOY_SHA},
        previous_fixture_provenance={'path':res(OLD_FIXTURE),'sha256':OLD_FIXTURE_SHA,'expected_city_count':1797,
                                     'key_path':res(OLD_KEY),'key_sha256':OLD_KEY_SHA,'prior_failures_preserved':True})
    delta={}
    for p,h in list(fixture['source_sha256'].items()):
        if p in sources and sources[p]!=h:
            delta[p]={'old':h,'new':sources[p]};fixture['source_sha256'][p]=sources[p]
    extras={STAGE:STAGE_SHA,DEPLOY:DEPLOY_SHA,node['path']:MAP_SHA}
    for p,h in extras.items():
        assert p not in fixture['source_sha256'];fixture['source_sha256'][p]=h
    restored=copy.deepcopy(fixture)
    for p in extras: del restored['source_sha256'][p]
    for p,row in delta.items(): restored['source_sha256'][p]=row['old']
    for field in ['expected_city_sources','expected_city_count','independent_owner','stage_receipt','deployment_actual']: restored[field]=old[field]
    del restored['previous_fixture_provenance']
    assert restored==old and encoded(restored)==encoded(old),'Complete fixture inverse; routes/dialogues/UI/budgets unchanged'
    oldkey=OLD_KEY.read_bytes();assert sha(oldkey)==OLD_KEY_SHA
    assert b'"",-1,C.VERSION)' in oldkey and b'INITIAL_PUBLIC_REQUEST_REJECTED_BEFORE_FIELD' in oldkey
    fx=encoded(fixture)
    operations=[(res(OLD_FIXTURE).encode(),res(OUT/'fixture_READY.json').encode()),
                (OLD_FIXTURE_SHA.encode(),sha(fx).encode()),
                (res(OLD_KEY.parent/'output_READY').encode(),res(OUT/'output_READY').encode())]
    key=oldkey
    for before,after in operations:
        assert key.count(before)==1;key=key.replace(before,after,1)
    inverse=key
    for before,after in reversed(operations):
        assert inverse.count(after)==1;inverse=inverse.replace(after,before,1)
    assert inverse==oldkey,'Three literals only, including exact original EOF'
    proof={'status':'THREE_LITERAL_F223_AND_FIXED_STAGE35_SOURCE_SUCCESSOR_NOT_RUN',
        'key_sha256':sha(key),'fixture_sha256':sha(fx),'source_count':1808,'source_guard_count':len(fixture['source_sha256']),
        'key_wholebyte_inverse_including_EOF':True,'fixture_fulltyped_and_serialized_inverse':True,
        'existing_guard_value_delta_from_fixed_stage_map':delta,'new_receipt_guards':extras,
        'C_VERSION_initial_request_retained':True,'routes_and_UI_and_60s_20s_3PNG_unchanged':True,
        'old_98AED_1797_F223_failures_provenance_retained':True,'current_fill_or_collector_or_engine':False}
    outputs={'test_READY.gd':key,'fixture_READY.json':fx,'freeze_inverse_READY_NOTRUN.json':encoded(proof),
      'complete_vs_F223.diff':''.join(difflib.unified_diff(oldkey.decode().splitlines(True),key.decode().splitlines(True),fromfile=res(OLD_KEY),tofile=res(OUT/'test_READY.gd'))).encode()}
    OUT.mkdir()
    for name,raw in outputs.items():
        with (OUT/name).open('xb') as stream: stream.write(raw)
    print(json.dumps({'output':res(OUT),'key_sha256':sha(key),'fixture_sha256':sha(fx),'proof_sha256':sha(outputs['freeze_inverse_READY_NOTRUN.json']),'expected_city_count':1808,'key_changed_literals':3}))

if __name__=='__main__': main()
