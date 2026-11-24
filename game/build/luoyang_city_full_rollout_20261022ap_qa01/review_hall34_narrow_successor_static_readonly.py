"""Static narrow34 exact inverse/shape proof; no engine or collector."""
from pathlib import Path
import hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'hall_roundtrip_ROOT34_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(s):return GAME/s.removeprefix('res://')
h=rd(D/'handoff_ROOT34_READY_NOT_RUN.json');key=res(h['key']['path']);fp=res(h['fixture']['path'])
assert sha(key)==h['key']['sha256']=='b91a2b332c08fdc9e38360cd158a9277e569836f7c6fe5df5129217f0100ef68'
assert sha(fp)==h['fixture']['sha256']=='6e0bb85fd73f71cdc22271174831c413023a09e482f756d3cbd52f6b2aa91a93'
parent=res(h['parent_D16F']['path']);oldfp=res(h['parent_fixture']['path'])
assert sha(parent)=='d16f5dbbac971bfdd25f95790d8ebefe449914b95161840ec76126cc6a54b609'and sha(oldfp)=='92a78e2530269d8798f5f52e0ffd9eb46d5d6b2c9361a4267e8b9879bc375bc2'
text=key.read_text(encoding='utf-8');inverse=text
for q in reversed(h['hunks']):
    assert inverse.count(q['new'])==1;inverse=inverse.replace(q['new'],q['old'],1)
assert inverse.encode()==parent.read_bytes()
f,old=rd(fp),rd(oldfp)
for k in old:
    if k not in ('status','source_sha256','authority'):assert f[k]==old[k],k
assert all(f['source_sha256'][p]==s for p,s in old['source_sha256'].items())and len(old['source_sha256'])==1289 and len(f['source_sha256'])==1297
for k,v in old['authority'].items():assert f['authority'][k]==v
assert f['city_doorway_local_points']==[[-20,-16],[20,-16],[20,16],[-20,16]]
assert (f['whole_ms'],f['entry_ms'],f['room_ms'],f['return_ms'])==(60000,20000,20000,10000)
selector='if node is Area2D and node.get("target_scene_id")==String(target) and node.position==foot: found.append(node)'
assert text.count(selector)==parent.read_text(encoding='utf-8').count(selector)==1
zone=text[text.index('func _zone('):text.index('func _city_owner(')]
assert zone.index('_snapshot_exit_scalars_before_filter')<zone.index(selector)<zone.index('"HALL_UNCHANGED_EXACT_FILTER_COUNT"')<zone.index('if not check(found.size()==1')
assert 'collider.disabled and collider.shape is RectangleShape2D and polygon!=null and not polygon.disabled and polygon.polygon==expected'in zone
assert 'shape_contract=collider!=null and not collider.disabled and collider.shape is RectangleShape2D'in zone
assert zone.count('await ')==1 and 'await driver.completed_actor_stage()'in zone
snapshot=text[text.index('func _snapshot_exit_scalars_before_filter'):text.index('func _zone(')]
assert 'await 'not in snapshot and 'FileAccess.'not in snapshot
for field in ('instance','scriptpath','target_text','target_type','position','locked','auto_trigger','monitoring','shape_disabled','polygon_point_count','polygon_four_local_points','target_spawn','portal_layer_child_count'):assert '"'+field+'"'in snapshot,field
assert '.source_paths('not in text and '.catalogue('not in text and '.finalize_setup('not in text and '.resident_receipt('not in text and text.count('.call("go_field_smart"')==1 and text.count('await driver.key(KEY_SPACE)')==2
fresh=f['authority']['Root34_before'];failed=f['authority']['Root33_failed_after_preserved']
assert sha(res(fresh['path']))==fresh['sha256']=='15449672a4fa00f77eab5825c4a00d6baec1c9e4a0e82590d74320f9abc6304b'
assert sha(res(failed['path']))==failed['sha256']=='9944e3be37d89a949915b3f7a622a3c960c1036f8a11839b87ae44dc295eaf86'
assert rd(res(failed['path']))['passed']is False
out=D/'independent_narrow_static_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT34_NARROW_HALL_STATIC_NO_BLOCKER_FOR_ROOT_UNIQUE_RUN_NOT_EXECUTED','key':h['key'],'fixture':h['fixture'],'handoff_sha256':sha(D/'handoff_ROOT34_READY_NOT_RUN.json'),'whole_byte_inverse_to_D16F':True,'original_exact_target_position_selector_unchanged':True,'diagnostics_before_filter_all_safe_scalars_no_extra_yield_worker_or_hash':True,'foundcount_record_before_original_exact1assert':True,'city_intentional_disabledRectangle_enabled_exact4polygon_and_room_enabledRectangle':True,'all_old_source1289_values_and_runtime_maps_paths_targets_budgets_unchanged':True,'guard1297_fixed_additions_only':True,'expected4points_source_G_door_polygon_not_observed_backfill':True,'Root33_failed_guard_and_original_report_retained':True,'Root34fresh_keeps_external9C27_not_retroactive_authority':True,'limits':['If original exact filter still count!=1, retainFAIL with node evidence; do not adjust coordinates/target from observations','No source schema or production code/mask/portal/geometry edits','60s whole20s entry20s room and hidden warm<10s unchanged','This is static scope approval, not a Godot parse or runtime result'],'engine_Stage_parse_collector_formal_calls':0},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'lines':len(text.splitlines())}))
