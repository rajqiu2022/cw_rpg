"""Text-only remaining-scope fixture projection from exact current Stage18.
No engine, collector, current-value fill, packet/image decode or production write.
"""
from pathlib import Path
import copy,hashlib,json
Q=Path(__file__).resolve().parent
GAME=Q.parent.parent
OLD=Q/'root_market_journey18_ground_READY'
OUT=Q/'market_remaining_vendor_task_READY'
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(v): return (json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode('ascii')
def res(p): return 'res://'+p.resolve().relative_to(GAME.resolve()).as_posix()
def fixed(p,h):
    assert p.startswith('res://') and '..' not in p
    raw=(GAME/p[6:]).read_bytes();assert sha(raw)==h,p
    return json.loads(raw)

def main():
    parent=OLD/'test_READY.gd';parent_sha='82075c5af1c641f35405c1c48919479d8fffe3cccf9df4642c2352356d368cd1'
    assert sha(parent.read_bytes())==parent_sha
    original=fixed(res(OLD/'fixture_READY.json'),'58e3a8eb6896d4aa4222128bda4837e32c59f3d631378aded690ddd386f129c4')
    stage=fixed(original['stage_receipt']['path'],'a7f8ce3a8b54cf78e3fe836c39ebab8ddb8e8f3ec58a53b6f6a2e6edf946ead6')
    assert stage['source_first']==stage['source_final']
    node=stage['nodes']['expected_ch4_s3_luoyang_market_true']
    table=fixed(node['path'],'7de7550e1fc67c40526cf1573831a11cbdd1f60e2f4a86a719d2b7448cf7c726')
    assert table==node['value'] and table['source_sha256']==original['expected_city_sources'] and len(table['source_sha256'])==1813
    assert original['paths']['entry_to_threshold']==[[1690,1663.7652439024391],[1690,1596]]
    approval_path='res://build/luoyang_city_space_20261024b_source01/market_warm_return_remaining_approach_SOURCE_APPROVED.json'
    approval_sha='3b327f01ccf3558835fa4b0f8d85470646b850ef06bc75dbfce5b432e7291494'
    approval=fixed(approval_path,approval_sha)
    assert approval['source_approved'] is True and approval['approved_suffix_entry']['from_world_px']==[1690,1596] and approval['approved_suffix_entry']['to_world_px']==[1690,1663.7652439024391]
    fixture=copy.deepcopy(original)
    fixture['status']='ROOT_APPROVED_NEW_REMAINING_ONLY_THRESHOLD_NEAR_VENDOR_TASK_60S'
    fixture['near_return_world']=copy.deepcopy(original['city_threshold_world'])
    fixture['paths']['threshold_to_approach']=list(reversed(copy.deepcopy(original['paths']['entry_to_threshold'])))
    fixture['remaining_scope']={'no_room_requests':True,'initial_near_is_authored_threshold_not_default':True,
      'prior_room_component_only_no_replay':True,'original_cold_authored_return_not_warm_remembered_return':True,
      'prior67928_wholeFAIL_preserved':True,'three_images':['street','vendor_daily','vendor_rumor'],
      'no_default_or_warm_loading_benchmark_credit':True,'task':'original menu/primary/offer KEY2 decline, no acceptance'}
    fixture['remaining_parent']={'key_path':res(parent),'key_sha256':parent_sha,'fixture_path':res(OLD/'fixture_READY.json'),
      'fixture_sha256':'58e3a8eb6896d4aa4222128bda4837e32c59f3d631378aded690ddd386f129c4'}
    fixture['remaining_source_approval']={'path':approval_path,'sha256':approval_sha}
    fixture['source_sha256'][res(parent)]=parent_sha
    fixture['source_sha256'][res(OLD/'fixture_READY.json')]='58e3a8eb6896d4aa4222128bda4837e32c59f3d631378aded690ddd386f129c4'
    assert approval_path not in original['source_sha256'];fixture['source_sha256'][approval_path]=approval_sha
    restored=copy.deepcopy(fixture)
    restored['status']=original['status'];restored['near_return_world']=original['near_return_world']
    del restored['paths']['threshold_to_approach'];del restored['remaining_scope'];del restored['remaining_parent'];del restored['remaining_source_approval']
    del restored['source_sha256'][res(parent)];del restored['source_sha256'][res(OLD/'fixture_READY.json')]
    del restored['source_sha256'][approval_path]
    assert enc(restored)==enc(original),'Only listed remaining-scope deltas; complete1813 map and vendor/task unchanged'
    fpath=OUT/'fixture_READY.json';assert not fpath.exists()
    fx=enc(fixture);keypath=OUT/'test_READY.gd';key=keypath.read_bytes()
    for before,after in [(b'PENDING_REMAINING_FIXTURE_PATH',res(fpath).encode()),(b'PENDING_REMAINING_FIXTURE_SHA',sha(fx).encode())]:
        assert key.count(before)==1;key=key.replace(before,after,1)
    fpath.write_bytes(fx);keypath.write_bytes(key)
    proof={'status':'NEW_REMAINING_SCOPE_NO_ENGINE','key_sha256':sha(key),'fixture_sha256':sha(fx),
      'parent_key_exact_sha256':parent_sha,'parent_fixture_exact_sha256':'58e3a8eb6896d4aa4222128bda4837e32c59f3d631378aded690ddd386f129c4',
      'expected_count':1813,'source_guard_count':len(fixture['source_sha256']),'fixture_delta_fully_inverted':True,
      'initial_near':[1690,1596],'threshold_to_approach':fixture['paths']['threshold_to_approach'],
      'all_vendor_task_UI_walk_camera_helpers_inherited_unchanged':True,'overrides':['precheck','exercise_cpu','_run'],
      'old_room_requests_not_called':True,'source_table_not_live_filled':True,'engine_calls':0}
    (OUT/'scope_and_fixture_inverse_READY_NOTRUN.json').write_bytes(enc(proof))
    print(json.dumps(proof))

if __name__=='__main__': main()
