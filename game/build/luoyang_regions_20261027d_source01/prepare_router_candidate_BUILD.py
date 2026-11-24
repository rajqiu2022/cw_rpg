"""One BUILD-only Router candidate. Preserve all legacy bytes including 13 CRLF.
No canonical write, Stage, import, engine, or automatic source pin filling.
"""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent
G=N.parents[1]
P=G/'build/luoyang_garden_estate_exit_20261027c_system01/Router_garden_estate_CANDIDATE.gd'
OLD='2687a0d72d6bf34654894905b9caf2082c3fdf97e7db4633e518996569d2650c'
sha=lambda raw:hashlib.sha256(raw).hexdigest()
old=P.read_bytes();assert sha(old)==OLD
text=old.decode('utf8');changes=[]
def replace(before,after):
 global text
 assert text.count(before)==1,(before[:140],text.count(before))
 text=text.replace(before,after,1);changes.append(dict(before=before,after=after))
replace('const LUOYANG_V3 = preload("res://scripts/city/luoyang_layered_v3_contract.gd")',
 'const REGION27D_ENABLED := true\nconst REGION27D_AUTHOR_SHA := "PENDING_FINAL_AUTHOR_SHA_NOT_ADOPTABLE"\nconst REGION27D = preload("res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd")\nconst LUOYANG_V3 = preload("res://scripts/city/luoyang_layered_v3_contract.gd")')
replace('\tif scene_id==&"": return false\n\tif LUOYANG_V3.owns_id(scene_id)',
 '\tif scene_id==&"": return false\n\tif REGION27D.enabled(self,scene_id): return REGION27D.start(self,scene_id,player_spawn,pending_action,local_spawn_version)\n\tif LUOYANG_V3.owns_id(scene_id)')
replace('func _go_field_smart_prepared(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:\n',
 'func _go_field_smart_prepared(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:\n\tif REGION27D.enabled(self,scene_id): return REGION27D.start(self,scene_id,player_spawn,pending_action,local_spawn_version)\n')
replace(') -> void:\n\tif not _public_city_request.is_empty() or not _resident_return.is_empty(): return\n\tif _try_resident_return',
 ') -> void:\n\tif not _public_city_request.is_empty() or not _resident_return.is_empty(): return\n\tif REGION27D.enabled(self,scene_id):\n\t\tREGION27D.enter_from_legacy(self,scene_id,authored_target_spawn,source_player_spawn,pending_action)\n\t\treturn\n\tif _try_resident_return')
replace('func field_scene_resource_path(scene_id: StringName) -> String:\n',
 'func field_scene_resource_path(scene_id: StringName) -> String:\n\tif REGION27D_ENABLED and REGION27D.Entry.SCENE_RESOURCES.has(String(scene_id)): return REGION27D.Entry.SCENE_RESOURCES[String(scene_id)]\n')
replace('\treturn state\n\n\nfunc restore_navigation_state(',
 '\tif REGION27D_ENABLED: state.merge(REGION27D.state(),true)\n\treturn state\n\n\nfunc restore_navigation_state(')
replace('\tdata = _city_preflight_result.duplicate(true)\n',
 '\tdata = _city_preflight_result.duplicate(true)\n\tif REGION27D_ENABLED: REGION27D.restore(data)\n')
replace('var city_prepared: Dictionary = LUOYANG_V3.prepare_navigation(data, StringName(data.get("current_field", "")), _city_target_versions())',
 'var city_prepared: Dictionary = _prepare_region27d_navigation(data, StringName(data.get("current_field", "")))')
replace('else LUOYANG_V3.prepare_navigation(data, fallback, _city_target_versions())',
 'else _prepare_region27d_navigation(data, fallback)')
replace('"local_migration_trace": local_prepared.local_migration_trace}',
 '"local_migration_trace": local_prepared.get("local_migration_trace",[]), "region27d": local_prepared.get("region27d",{}), "region27d_returns": local_prepared.get("region27d_returns",{})}')
replace('\t_local_layout_versions = prepared.get("local_layout_versions", {}).duplicate(true)\n',
 '\t_local_layout_versions = prepared.get("local_layout_versions", {}).duplicate(true)\n\tif REGION27D_ENABLED: REGION27D.restore(prepared)\n')
# Reset is an explicit navigation boundary, not a per-transition state wipe.
replace('func reset_for_new_game() -> void:\n',
 'func reset_for_new_game() -> void:\n\tREGION27D.reset()\n')
replace('\tgo_field_smart(scene_id, _current_field_spawn, pending_action)\n',
 '\tif REGION27D.enabled(self,scene_id) and not REGION27D.state().region27d.is_empty():\n\t\tREGION27D.resume_modal(self,pending_action)\n\t\treturn\n\tgo_field_smart(scene_id, _current_field_spawn, pending_action)\n')
replace('func return_from_battle_payload(payload: Dictionary, pending_action: String = "") -> void:\n',
 'func return_from_battle_payload(payload: Dictionary, pending_action: String = "") -> void:\n\tif REGION27D_ENABLED and payload.has("return_region27d") or REGION27D_ENABLED and _battle_payload.has("return_region27d"):\n\t\tREGION27D.resume_battle(self,payload,pending_action)\n\t\treturn\n')
replace('func _transition_to(scene_path: String, kind: StringName, context: Dictionary = {}) -> void:\n',
 'func _transition_to(scene_path: String, kind: StringName, context: Dictionary = {}) -> void:\n\tif REGION27D_ENABLED and not REGION27D.capture_modal(self,kind): return\n')
extra='''
func commit_region27d_navigation(navigation: Dictionary) -> bool:
	return REGION27D_ENABLED and REGION27D.commit(self,navigation)

func go_from_region27d_portal(logical: String,door_id: String,target: String,uv: Vector2,legacy_uv: Vector2) -> bool:
	return REGION27D_ENABLED and REGION27D.exit_region(self,logical,door_id,target,uv,legacy_uv)

func _prepare_region27d_navigation(data: Dictionary,fallback: StringName) -> Dictionary:
	if REGION27D_ENABLED:
		return REGION27D.preflight(self,data,fallback,_city_target_versions(),LUOYANG_V3)
	return LUOYANG_V3.prepare_navigation(data,fallback,_city_target_versions())
'''
text=text+extra.lstrip('\n')
changes.append(dict(before='',after=extra.lstrip('\n'),append=True))
new=text.encode('utf8')
assert new.count(b'\r\n')==old.count(b'\r\n')==13
inverse=text
for h in reversed(changes):
 if h.get('append'):
  assert inverse.endswith(h['after']);inverse=inverse[:-len(h['after'])]
  # The parent ended with one LF. Appending kept that LF exactly.
 else:
  assert inverse.count(h['after'])==1;inverse=inverse.replace(h['after'],h['before'],1)
assert inverse.encode('utf8')==old,(len(old),len(inverse.encode('utf8')))
dest=N/'Router_region_CANDIDATE02.gd';proof=N/'Router_region_whole_inverse_BUILD02.json'
for p in (dest,proof):assert not p.exists(),str(p)
dest.write_bytes(new)
proof.write_text(json.dumps(dict(status='BUILD_NOT_ADOPTED_AUTHOR_PENDING',parent_path='res://'+P.relative_to(G).as_posix(),parent_sha256=sha(old),candidate_path='res://'+dest.relative_to(G).as_posix(),candidate_sha256=sha(new),internal_CRLF=13,hunks=changes,whole_inverse_exact=True),ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
print(json.dumps(dict(candidate=str(dest),sha256=sha(new),hunks=len(changes),whole_inverse=True)))
