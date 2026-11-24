"""Text-only task-only scope and source-derived Coordinator node expectation."""
from pathlib import Path
import copy,hashlib,json
Q=Path(__file__).resolve().parent;GAME=Q.parent.parent
OLD=Q/'market_dialogue_only_remaining_READY';OUT=Q/'market_task_decline_only_remaining_READY'
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(v): return (json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode('ascii')
def res(p): return 'res://'+p.resolve().relative_to(GAME.resolve()).as_posix()
def source(p,h):
    raw=(GAME/p[6:]).read_bytes();assert sha(raw)==h,p
    return raw.decode('utf-8-sig')
def main():
    ph='39f3308051d37a248d538120a70f99fde5a084c20bc5456f0c4b4f240e24cf8a';fh='579fd19cdd7c45f063c6666d3725fbd7f96bd390ce4cca49c80e26c8ef5d3f1b'
    parent=OLD/'test_READY.gd';assert sha(parent.read_bytes())==ph
    raw=(OLD/'fixture_READY.json').read_bytes();assert sha(raw)==fh
    old=json.loads(raw);fixture=copy.deepcopy(old)
    assert len(old['expected_city_sources'])==old['expected_city_count']==1813
    assert old['proposed_source_points_not_route_admission']['vendor_approach_and_task_approach']['task']['stand']==[520,1400]
    cp='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';ch='66b3ecb9a2381b70be547ced15fb50f4cfb62438eb8b3e7bf5d3adff0cdca423'
    coordinator=source(cp,ch);assert old['expected_city_sources'][cp]==ch
    ds='res://scripts/domain/dialog_script.gd';dh='de9c75302f92d84fa6a483656f55e967237a28f1ab3f8440373ae7fe5cffd4c5'
    domain=source(ds,dh)
    helper='res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd';hh='535fb1d33e32cfddcf1d09535ca2f88aa475264ec149217b3c1dd2af1e79b468'
    conversation=source(helper,hh)
    assert '@export var nodes: Array[DialogNode] = []' in domain
    assert 'node.node_id = StringName("x_%d_%s" % [script.nodes.size(), suffix])' in coordinator
    start=coordinator.index('func open(npc_id: String) -> Dictionary:');end=coordinator.index('\nfunc observe_node()',start)
    opened=coordinator[start:end]
    first=opened.index('var script := DialogScript.new()');menu=opened.index('var menu := _node(script, ready.text.common.greeting, npc.npc_name, "menu")')
    assert first<menu and '_node(' not in opened[first:menu]
    assert 'script.entry_node_id = menu.node_id' in opened
    assert 'var target: StringName = original.entry_node_id' in conversation
    assert 'opening.on_end = "next:" + String(target)' in conversation
    assert 'script.nodes.push_front(opening)' in conversation
    assert 'script.entry_node_id = opening.node_id' in conversation
    menu_id='x_%d_%s'%(0,'menu');assert menu_id=='x_0_menu'
    proof={'status':'SOURCE_ONLY_EXACT_COORDINATOR_MENU_NODE_ID_NOT_ACTUAL_BACKFILL',
      'coordinator':{'path':cp,'sha256':ch,'lines':[227,229,324,327,331,345]},
      'DialogScript_empty_nodes':{'path':ds,'sha256':dh,'line':9},
      'conversation_hero_wrapper':{'path':helper,'sha256':hh},
      'derivation':['DialogScript.new has empty nodes Array','open first _node call suffix menu',
        '_node formats x_%d_%s from script.nodes.size() before append','therefore exact first node x_0_menu',
        'hero wrapper retains original entry node target; push_front does not rename existing IDs'],
      'expected_node_id':menu_id,'actual_result_read_by_this_builder':False,'production_change':False,
      'dedicated_scholar_portrait_credit':False}
    proof_path=OUT/'Coordinator_menu_id_source_READONLY.json';proof_raw=enc(proof)
    fixture.update(status='ROOT_APPROVED_NEW_TASK_ONLY_SCHOLAR_NEAR_DECLINE',near_return_world=[520,1400],max_pictures=0)
    fixture['task']['culture_menu_node_id']=menu_id
    fixture['task_menu_id_source']={'path':res(proof_path),'sha256':sha(proof_raw)}
    fixture['task_only_remaining']={'source_stand':[520,1400],'no_vendor_path_room_replay':True,'no_movement_or_PNG':True,
      'prior112496_wholeFAIL_preserved':True,'no_street_travel_or_benchmark_credit':True,'dedicated_scholar_portrait_credit':False}
    fixture['task_only_parent']={'key_path':res(parent),'key_sha256':ph,'fixture_path':res(OLD/'fixture_READY.json'),'fixture_sha256':fh}
    additions={res(parent):ph,res(OLD/'fixture_READY.json'):fh,cp:ch,ds:dh,res(proof_path):sha(proof_raw)}
    previous={p:fixture['source_sha256'].get(p) for p in additions}
    for p,h in additions.items():
        assert previous[p] is None or previous[p]==h;fixture['source_sha256'][p]=h
    inverse=copy.deepcopy(fixture)
    for k in ['status','near_return_world','max_pictures']: inverse[k]=old[k]
    del inverse['task']['culture_menu_node_id']
    for k in ['task_menu_id_source','task_only_remaining','task_only_parent']: del inverse[k]
    for p,h in previous.items():
        if h is None: del inverse['source_sha256'][p]
        else: inverse['source_sha256'][p]=h
    assert enc(inverse)==enc(old),'Complete fixture inverse;1813 and all task choice text unchanged'
    kp=OUT/'test_READY.gd';key=kp.read_bytes();oldkey=(Q/'root_market_journey18_ground_READY/test_READY.gd').read_bytes()
    def task_method(data):
        a=data.index(b'func _unchanged_task_choices_decline() -> bool:')
        b=data.find(b'\nfunc ',a+1)
        return data[a:b if b!=-1 else None].rstrip()
    method=task_method(key)
    assert method.count(b'await _dialog(fixture.task.culture_menu_node_id,true)')==1
    assert method.replace(b'await _dialog(fixture.task.culture_menu_node_id,true)',b'await _dialog("menu",true)',1)==task_method(oldkey),'Original task method wholebytes except one source-derived node expression'
    fx=enc(fixture);fp=OUT/'fixture_READY.json';assert not fp.exists() and not proof_path.exists()
    for before,after in [(b'PENDING_TASK_FIXTURE_PATH',res(fp).encode()),(b'PENDING_TASK_FIXTURE_SHA',sha(fx).encode())]:
        assert key.count(before)==1;key=key.replace(before,after,1)
    proof_path.write_bytes(proof_raw);fp.write_bytes(fx);kp.write_bytes(key)
    summary={'status':'NEW_TASK_ONLY_REMAINING_NO_ENGINE','key_sha256':sha(key),'fixture_sha256':sha(fx),
      'menu_source_proof_sha256':sha(proof_raw),'expected_menu_id':menu_id,'fixed_sources':1813,
      'source_guard_count':len(fixture['source_sha256']),'fixture_full_delta_inverse':True,'task_method_single_node_expression_inverse':True,
      'near':[520,1400],'whole60_entry20_max0PNG':True,'dedicated_scholar_portrait_credit':False,'engine_calls':0}
    (OUT/'scope_fixture_inverse_READY_NOTRUN.json').write_bytes(enc(summary));print(json.dumps(summary))
if __name__=='__main__': main()
