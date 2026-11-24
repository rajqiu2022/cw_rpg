"""Text-only fixed vendor-near projection; no engine/collector/current fill."""
from pathlib import Path
import copy,hashlib,json
Q=Path(__file__).resolve().parent;GAME=Q.parent.parent
OLD=Q/'market_remaining_vendor_task_READY';OUT=Q/'market_dialogue_only_remaining_READY'
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(v): return (json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode('ascii')
def res(p): return 'res://'+p.resolve().relative_to(GAME.resolve()).as_posix()
def main():
    parent=OLD/'test_READY.gd';ph='77adabb960e785997b3cf8a7828992a85f8fdcae781a55fbb42f4cce79be5f34'
    assert sha(parent.read_bytes())==ph
    fr=(OLD/'fixture_READY.json').read_bytes();fh='e928ce8b8a96d3f22cc324735970cf7e02c0f725e1804b9189311bb30d52604f'
    assert sha(fr)==fh
    old=json.loads(fr);fixture=copy.deepcopy(old)
    assert old['expected_city_count']==1813 and len(old['expected_city_sources'])==1813
    assert old['paths']['vendor_to_task']==[[710,1260],[780,1260],[780,1400],[520,1400]]
    assert old['proposed_source_points_not_route_admission']['vendor_approach_and_task_approach']['vendor']['stand']==[710,1260]
    fixture.update(status='ROOT_APPROVED_NEW_DIALOGUE_ONLY_VENDOR_NEAR_REMAINING',near_return_world=[710,1260],max_pictures=2)
    fixture['dialogue_only_remaining']={'explicit_near_from_source':[710,1260],'not_street_travel':True,
      'prior27636_wholeFAIL_preserved':True,'prior_street_threshold_reverse_and_image_not_replayed':True,
      'failed_return_to_vendor_connection_not_passed':True,'vendor_to_task_original_path_requires_actual_INPUT':True,
      'no_room_or_street_route_requests':True,'images':['vendor_daily','vendor_attributed_rumor'],'no_performance_credit':True}
    fixture['dialogue_only_parent']={'key_path':res(parent),'key_sha256':ph,'fixture_path':res(OLD/'fixture_READY.json'),'fixture_sha256':fh}
    assert res(parent) not in fixture['source_sha256'] and res(OLD/'fixture_READY.json') not in fixture['source_sha256']
    fixture['source_sha256'][res(parent)]=ph;fixture['source_sha256'][res(OLD/'fixture_READY.json')]=fh
    inverse=copy.deepcopy(fixture)
    for k in ['status','near_return_world','max_pictures']: inverse[k]=old[k]
    del inverse['dialogue_only_remaining'];del inverse['dialogue_only_parent']
    del inverse['source_sha256'][res(parent)];del inverse['source_sha256'][res(OLD/'fixture_READY.json')]
    assert enc(inverse)==enc(old),'Only listed dialogue-only scope deltas; expected1813/vendor/task unchanged'
    fx=enc(fixture);fp=OUT/'fixture_READY.json';assert not fp.exists()
    kp=OUT/'test_READY.gd';key=kp.read_bytes()
    for before,after in [(b'PENDING_DIALOGUE_FIXTURE_PATH',res(fp).encode()),(b'PENDING_DIALOGUE_FIXTURE_SHA',sha(fx).encode())]:
        assert key.count(before)==1;key=key.replace(before,after,1)
    fp.write_bytes(fx);kp.write_bytes(key)
    proof={'status':'NEW_DIALOGUE_ONLY_REMAINING_NO_ENGINE','key_sha256':sha(key),'fixture_sha256':sha(fx),
      'parent_key_sha256':ph,'parent_fixture_sha256':fh,'fixture_full_delta_inverse':True,
      'source_count':1813,'source_guard_count':len(fixture['source_sha256']),'explicit_near':[710,1260],
      'inherited_vendor_UI_Task_walk_camera_core_unchanged':True,'overrides':['precheck','exercise_cpu','_run','_picture_max2_only'],
      'failed_street_connection_pass_credit':False,'whole60_entry20_max2PNG':True,'engine_calls':0,'source_live_fill':False}
    (OUT/'scope_fixture_inverse_READY_NOTRUN.json').write_bytes(enc(proof));print(json.dumps(proof))
if __name__=='__main__': main()
