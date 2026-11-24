"""NEW narrow hall34 source text: diagnostics + proven doorway shape contract."""
from pathlib import Path
import copy,difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
OUT=QA/'hall_roundtrip_ROOT34_READY'
assert not OUT.exists()
def rp(p):return 'res://'+p.relative_to(GAME).as_posix()
def res(s):return GAME/s.removeprefix('res://')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def pin(p,s):
    assert sha(p)==s.lower(),str(p)
    return {'path':rp(p),'sha256':s.lower()}
oldkey=QA/'hall_roundtrip_ROOT33_READY/test_hall_roundtrip_ROOT33_READY.gd'
oldfp=QA/'hall_roundtrip_ROOT33_READY/hall_roundtrip_fixture_ROOT33_READY.json'
parent=pin(oldkey,'D16F5DBBAC971BFDD25F95790D8EBEFE449914B95161840EC76126CC6A54B609')
parentfixture=pin(oldfp,'92A78E2530269D8798F5F52E0FFD9EB46D5D6B2C9361A4267E8B9879BC375BC2')
fresh=pin(ROOT/'integration34/guard_before.json','15449672A4FA00F77EAB5825C4A00D6BAEC1C9E4A0E82590D74320F9ABC6304B')
failed=pin(ROOT/'integration33/final_guard.json','9944E3BE37D89A949915B3F7A622A3C960C1036F8A11839B87AE44DC295EAF86')
fact=pin(GAME/'build/luoyang_city_full_rollout_20261022ap_system01/hall_portal_failure_readonly_epoch01/declared_chain_and_unresolved_live_match_READONLY.json','DF291A513BD0C794020281D7A49BE2F27EC0EF9C2361D6A329E96C435DE45254')
g34=rd(res(fresh['path']));g33=rd(res(failed['path']))
assert g34['mode']=='before'and g34['checked']==2118 and g34['save_count']==15
assert g33['passed']is False and g33['unexpected_change_count']==1 and g33['save_change_count']==0 and g33['unexpected_changes'][0]['after']['sha256']=='9c27ffc9f97a9ba2c238f6da8a7bdab193027e1622445d086be8b727d7b56544'
taskfact=next(r for r in g34['facts']if Path(r['path']).resolve()==(GAME.parent/'prompts/tasks.yaml').resolve())
assert taskfact['sha256']=='9c27ffc9f97a9ba2c238f6da8a7bdab193027e1622445d086be8b727d7b56544'and taskfact['bytes']==769954
shape_pins=[pin(GAME/'scripts/field/luoyang_v3_exit_zone.gd','A18B3FD92CC0A186912D7FBFA2D6F73BC212B62CC24CC023E0B2F27845F65061'),pin(GAME/'scripts/field/world_v15_exit_zone.gd','19665F50731EB90286372CBD0EBF55B43BF6EDF1694E85885D50BB59CBE9E8EF'),pin(GAME/'scripts/field/exit_zone.gd','BF0EE27EACDB592DC977E378E9E4B7FBE1C6E695F9101CD9415A303747E22BC5')]
old=rd(oldfp);f=copy.deepcopy(old)
f['status']='ROOT34_HALL_NARROW_POLYGON_CONTRACT_AND_PREFILTER_OBSERVER_READY_NOT_RUN'
for desc in [parent,parentfixture,fresh,failed,fact]+shape_pins:
    assert desc['path']not in f['source_sha256']or f['source_sha256'][desc['path']]==desc['sha256']
    f['source_sha256'][desc['path']]=desc['sha256']
assert all(f['source_sha256'][p]==v for p,v in old['source_sha256'].items())
f['city_doorway_local_points']=[[-20,-16],[20,-16],[20,16],[-20,16]]
f['authority']['Root34_before']=fresh;f['authority']['Root33_failed_after_preserved']=failed;f['authority']['portal_readonly_diagnosis']=fact
f['predicate_successor']={'first_target_text_and_exact_node_position_filter_unchanged':True,'no_actual_list_expected_fill':True,'city':'Disabled original CollisionShape2D plus enabled DoorwayPolygon, exactly frozen four local author points. Original rectangle disabled is intentional.','ordinary_room':'Enabled RectangleShape2D remains required; no city polygon condition borrowed.','prefilter_diagnostics':'All_exit_nodes valid scalar snapshots and PortalLayer childcount before original filter; foundcount recorded before original exact1 assertion. No added yield, worker, helper call or source hash in arrival timing.','guard_scope':'Old1290-report/root33FAIL retained; all old1289 fixture guard entries kept, new small shape facts/code/Root34 fresh and immutable parent appended.','external_tasks':'Root33after remainsFAIL. Root34fresh explicitly preserves external9C27 current value; no restore or retroactive approval.'}
insert='''func _snapshot_exit_scalars_before_filter(target: StringName,foot: Vector2) -> void:
\tvar rows: Array[Dictionary]=[]
\tfor node: Node in field.get("_exit_nodes"):
\t\tif not is_instance_valid(node):
\t\t\trows.append({"valid":false});continue
\t\tvar script: Script=node.get_script() as Script
\t\tvar actual_target: Variant=node.get("target_scene_id")
\t\tvar target_text: String=String(actual_target) if actual_target is String or actual_target is StringName else "UNSUPPORTED_VARIANT_TYPE_"+str(typeof(actual_target))
\t\tvar pos: Vector2=(node as Node2D).position if node is Node2D else Vector2(INF,INF)
\t\tvar shape: CollisionShape2D=node.get_node_or_null("CollisionShape2D") as CollisionShape2D
\t\tvar polygon: CollisionPolygon2D=node.get_node_or_null("DoorwayPolygon") as CollisionPolygon2D
\t\tvar points: Array=[]
\t\tif polygon!=null and polygon.polygon.size()==4:
\t\t\tfor point: Vector2 in polygon.polygon: points.append([point.x,point.y])
\t\tvar spawn: Variant=node.get("target_spawn_pos")
\t\trows.append({"valid":true,"instance":node.get_instance_id(),"scriptpath":script.resource_path if script!=null else "","target_text":target_text,"target_type":typeof(actual_target),"position":[pos.x,pos.y],"locked":node.get("is_locked"),"auto_trigger":node.get("auto_trigger"),"monitoring":(node as Area2D).monitoring if node is Area2D else null,"in_range":node.get("_in_range"),"shape_present":shape!=null,"shape_disabled":shape.disabled if shape!=null else null,"shape_type":shape.shape.get_class() if shape!=null and shape.shape!=null else "","polygon_present":polygon!=null,"polygon_disabled":polygon.disabled if polygon!=null else null,"polygon_point_count":polygon.polygon.size() if polygon!=null else 0,"polygon_four_local_points":points,"target_spawn":[spawn.x,spawn.y] if spawn is Vector2 else [],"target_spawn_type":typeof(spawn)})
\tvar portal_layer: Node=field.get("_portal_layer") as Node
\trecords.append({"kind":"HALL_EXIT_SCALARS_BEFORE_UNCHANGED_FILTER","requested_target":String(target),"expected_author_position":[foot.x,foot.y],"nodes":rows,"portal_layer_child_count":portal_layer.get_child_count() if portal_layer!=null else -1,"no_expected_values_taken_from_observed_nodes":true})

'''
oldzone='''func _zone(target: StringName,foot: Vector2,spawn: Vector2) -> bool:
\tawait driver.completed_actor_stage()
\tvar found: Array[Area2D]=[]
\tfor node: Node in field.get("_exit_nodes"):
\t\tif node is Area2D and node.get("target_scene_id")==String(target) and node.position==foot: found.append(node)
\tif not check(found.size()==1,"One exact authored native target and door foot"): return false
\tvar zone: Area2D=found[0]
\tvar collider: CollisionShape2D=zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
\tvar good: bool=zone.is_inside_tree() and zone.monitoring and zone.get("is_locked")==false and zone.get("auto_trigger")==false and zone.get("target_spawn_pos")==spawn and collider!=null and not collider.disabled and zone.overlaps_body(field.get("_player")) and zone.get("_in_range")==true
\trecords.append({"kind":"HALL_ACTUAL_NATIVE_ZONE","target":String(target),"zone_id":zone.get_instance_id(),"position":zone.position,"target_spawn":zone.get("target_spawn_pos"),"enabled_overlap_inrange":good,"actual_player_foot":field.get("_player").position})
\treturn check(good and _clear(field.get("_player").position),"Enabled exact-target native Area and actual full-body overlap before Space")

'''
newzone='''func _zone(target: StringName,foot: Vector2,spawn: Vector2) -> bool:
\tawait driver.completed_actor_stage()
\t_snapshot_exit_scalars_before_filter(target,foot)
\tvar found: Array[Area2D]=[]
\tfor node: Node in field.get("_exit_nodes"):
\t\tif node is Area2D and node.get("target_scene_id")==String(target) and node.position==foot: found.append(node)
\trecords.append({"kind":"HALL_UNCHANGED_EXACT_FILTER_COUNT","requested_target":String(target),"expected_author_position":[foot.x,foot.y],"found_count":found.size()})
\tif not check(found.size()==1,"One exact authored native target and door foot"): return false
\tvar zone: Area2D=found[0]
\tvar collider: CollisionShape2D=zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
\tvar polygon: CollisionPolygon2D=zone.get_node_or_null("DoorwayPolygon") as CollisionPolygon2D
\tvar shape_contract: bool=false
\tif scene.scene_id==CITY:
\t\tvar expected: PackedVector2Array=PackedVector2Array()
\t\tfor point: Variant in fixture.city_doorway_local_points: expected.append(_v(point))
\t\tshape_contract=collider!=null and collider.disabled and collider.shape is RectangleShape2D and polygon!=null and not polygon.disabled and polygon.polygon==expected
\telif scene.scene_id==ROOM:
\t\tshape_contract=collider!=null and not collider.disabled and collider.shape is RectangleShape2D
\tvar good: bool=zone.is_inside_tree() and zone.monitoring and zone.get("is_locked")==false and zone.get("auto_trigger")==false and zone.get("target_spawn_pos")==spawn and shape_contract and zone.overlaps_body(field.get("_player")) and zone.get("_in_range")==true
\trecords.append({"kind":"HALL_ACTUAL_NATIVE_ZONE","target":String(target),"zone_id":zone.get_instance_id(),"position":zone.position,"target_spawn":zone.get("target_spawn_pos"),"shape_contract":shape_contract,"city_original_shape_intentionally_disabled":scene.scene_id==CITY,"enabled_overlap_inrange":good,"actual_player_foot":field.get("_player").position})
\treturn check(good and _clear(field.get("_player").position),"Enabled exact-target native Area and actual full-body overlap before Space")

'''
fp=OUT/'hall_roundtrip_fixture_ROOT34_READY.json';kp=OUT/'test_hall_roundtrip_ROOT34_READY.gd'
fb=(json.dumps(f,ensure_ascii=False,indent=2)+'\n').encode();fs=hashlib.sha256(fb).hexdigest()
t=oldkey.read_bytes().decode();hunks=[]
def change(a,b):
    global t
    assert t.count(a)==1,a[:100]
    t=t.replace(a,b,1);hunks.append({'old':a,'new':b})
change('const FIXTURE="'+rp(oldfp)+'"','const FIXTURE="'+rp(fp)+'"')
change('const FIXTURE_SHA="'+sha(oldfp)+'"','const FIXTURE_SHA="'+fs+'"')
change(oldzone,insert+newzone)
change(rp(QA/'hall_roundtrip_ROOT33_READY/output'),rp(OUT/'output'))
back=t
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==oldkey.read_bytes()
for k in old:
    if k not in ('status','source_sha256','authority'):assert f[k]==old[k],k
assert 'not collider.disabled' in newzone and oldzone.splitlines()[4]in newzone
assert not OUT.exists();OUT.mkdir();fp.write_bytes(fb);kp.write_bytes(t.encode())
kd=OUT/'complete_key_vs_D16F.diff';fd=OUT/'complete_fixture_vs_ROOT33.diff'
kd.write_text(''.join(difflib.unified_diff(oldkey.read_text(encoding='utf-8').splitlines(keepends=True),t.splitlines(keepends=True),fromfile=rp(oldkey),tofile=rp(kp))),encoding='utf-8',newline='')
fd.write_text(''.join(difflib.unified_diff(oldfp.read_text(encoding='utf-8').splitlines(keepends=True),fb.decode().splitlines(keepends=True),fromfile=rp(oldfp),tofile=rp(fp))),encoding='utf-8',newline='')
hand={'status':'ROOT34_NARROW_HALL_SUCCESSOR_READY_NOT_EXECUTED_NOT_PARSE_PASS','key':{'path':rp(kp),'sha256':sha(kp)},'fixture':{'path':rp(fp),'sha256':sha(fp)},'parent_D16F':parent,'parent_fixture':parentfixture,'whole_byte_inverse_to_D16F':True,'hunks':hunks,'sourceguard_count':len(f['source_sha256']),'all_old1289_guard_values_unchanged':True,'runtime1239_G557_historical247_maps_whole_same':True,'original60_20_20_under10_paths_and_targets_unchanged':True,'exact_selector_line_unchanged':oldzone.splitlines()[4],'extra_only':'prefilter safe scalar rows+PortalLayer count/foundcount; city intentional disabled rectangle and enabled exact4point polygon vs ordinaryroom enabledrectangle','Root34fresh':fresh,'Root33FAILguard_preserved':failed,'no_external_tasks_restore_or_retroactive_authority':True,'diffs':{'key':{'path':rp(kd),'sha256':sha(kd)},'fixture':{'path':rp(fd),'sha256':sha(fd)}},'engine_Stage_parse_collector_formal_calls':0}
hp=OUT/'handoff_ROOT34_READY_NOT_RUN.json';hp.write_text(json.dumps(hand,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'key':hand['key'],'fixture':hand['fixture'],'handoff':{'path':rp(hp),'sha256':sha(hp)},'sourceguard':len(f['source_sha256'])}))
