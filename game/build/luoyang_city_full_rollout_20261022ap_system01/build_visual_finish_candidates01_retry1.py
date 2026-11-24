"""Retry1 preserves mixed EOL per hunk; first preparation FAIL retained."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
OUT=HERE/"visual_finish_candidates01_retry1"
assert not OUT.exists()
def sha_bytes(b):return hashlib.sha256(b).hexdigest()
def sha(p):return sha_bytes(p.read_bytes())
def ref(p):return "res://"+p.relative_to(GAME).as_posix()

hud=GAME/"scripts/ui/field_primary_hud.gd"
field=GAME/"scripts/field/field_walkable_controller.gd"
env=HERE/"environment_rect_transition_candidate_READY.gd"
assert sha(hud)=="9232f5a427461b127178e16eef1851e7d3960592e0dccd852f79bd714000a8ab"
assert sha(field)=="24b5159b01470b571955f68a2762b9e979fc45703168e86cb8da157defea1179"
assert sha(env)=="4245e7d5268c8a5509e46cf46f4ff737c1178843c5f3c2f4f8d650d662b2fbfc"

hud_vars='''var _quest_backplate: StyleBoxFlat = null
var _quest_backplate_hovered: bool = false
var _quest_backplate_pinned: bool = false'''
hud_setup='''func _setup_quest_tracker_style() -> void:
	if not is_instance_valid(_quest_panel) or not is_instance_valid(_quest_summary):
		return
	# User-requested plain readability backing, not a replacement art frame.
	_quest_backplate = StyleBoxFlat.new()
	_quest_backplate.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	_quest_backplate.content_margin_left = 18.0
	_quest_backplate.content_margin_right = 18.0
	_quest_backplate.content_margin_top = 15.0
	_quest_backplate.content_margin_bottom = 15.0
	_quest_panel.add_theme_stylebox_override("panel", _quest_backplate)
	_quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_summary.fit_content = true
	_quest_summary.resized.connect(_sync_quest_backplate_bounds)
	_sync_quest_backplate_bounds.call_deferred()


func _sync_quest_backplate_bounds() -> void:
	if not is_instance_valid(_quest_panel) or not is_instance_valid(_quest_summary):
		return
	# The real wrapped text determines height; the original width/layout stay.
	var height: float = maxf(1.0, float(_quest_summary.get_content_height())) + 30.0
	if not is_equal_approx(_quest_panel.size.y, height):
		_quest_panel.size.y = height
	_quest_backplate_hovered = _quest_panel.is_visible_in_tree() and _quest_panel.get_global_rect().has_point(get_global_mouse_position())
	_update_quest_backplate()


func _update_quest_backplate() -> void:
	if _quest_backplate != null:
		_quest_backplate.bg_color = Color(0.0, 0.0, 0.0, 0.62 if _quest_backplate_hovered or _quest_backplate_pinned else 0.0)


func _input(event: InputEvent) -> void:
	# Observe pointer movement without changing GUI mouse filters. Only the
	# explicit local left press is handled, so it cannot also click the map.
	if not is_instance_valid(_quest_panel) or not _quest_panel.is_visible_in_tree() or DialogPlayer.is_playing():
		return
	if event is InputEventMouseMotion:
		_quest_backplate_hovered = _quest_panel.get_global_rect().has_point(event.position)
		_update_quest_backplate()
	elif event is InputEventMouseButton and event.device >= 0 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _quest_panel.get_global_rect().has_point(event.position):
			return
		_quest_backplate_pinned = not _quest_backplate_pinned
		_quest_backplate_hovered = true
		_update_quest_backplate()
		get_viewport().set_input_as_handled()'''
old_setup='''func _setup_quest_tracker_style() -> void:
	if not is_instance_valid(_quest_panel):
		return
	var panel_style := StyleBoxEmpty.new()
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_top = 15.0
	panel_style.content_margin_bottom = 15.0
	_quest_panel.add_theme_stylebox_override("panel", panel_style)'''
hud_changes=[
 ('@onready var _quest_panel: PanelContainer = $QuestSummaryPanel', '@onready var _quest_panel: PanelContainer = $QuestSummaryPanel\n'+hud_vars),
 ('_quest_summary.text = "%s\\n\\n%s" % [main_block, side_block]', '_quest_summary.text = "%s\\n\\n%s" % [main_block, side_block]\n\t_sync_quest_backplate_bounds.call_deferred()'),
 (old_setup,hud_setup),
 ('_quest_panel.visible = false\n\thide_right_menu_now()', '_quest_panel.visible = false\n\t_quest_backplate_hovered = false\n\t_update_quest_backplate()\n\thide_right_menu_now()'),
 ('_quest_panel.visible = true\n\trestore_right_menu()', '_quest_panel.visible = true\n\t_sync_quest_backplate_bounds.call_deferred()\n\trestore_right_menu()'),
]
hero_ids=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s4_ancient_temple","luoyang_estate_riverside_20261021ai","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
field_before='_player.set_visual_scale_multiplier(_current_scene.player_visual_scale)'
field_after='''var visual_multiplier: float = _current_scene.player_visual_scale
		# Exact eight-city visual scope. Body/speed/scene data and foot anchor stay.
		if _current_scene.scene_id in ['''+','.join('&"'+x+'"' for x in hero_ids)+''']:
			visual_multiplier *= 1.12
		_player.set_visual_scale_multiplier(visual_multiplier)'''
env_changes=[
 ('transition.set_shader_parameter("ap_core_opacity",0.66)', 'var core_opacity: float=1.0 if scene.scene_id==&"ch4_s3_luoyang_market" and row.id=="market_pawn_clean_paved_forecourt" else 0.66\n\t\t\ttransition.set_shader_parameter("ap_core_opacity",core_opacity)'),
 ('"feather_world":32.0,"core_opacity":0.66,"no_tile_edge_feather":true', '"feather_world":32.0,"core_opacity":core_opacity,"no_tile_edge_feather":true'),
]
jobs=[("HUD_readability",hud,hud_changes,"field_primary_hud_readability_READY.gd"),("Hero_visual_only",field,[(field_before,field_after)],"Field_hero_visual_only_READY.gd"),("ENV_pawn_core",env,env_changes,"environment_pawn_core_transition_READY.gd")]
prepared=[]
for name,parent,changes,filename in jobs:
    original=parent.read_bytes();eol="\r\n" if b"\r\n" in original else "\n"
    child=original
    applied=[]
    for before,after in changes:
        choices=[eol] if "\n" not in before else [eol, "\n" if eol=="\r\n" else "\r\n"]
        found=[]
        for local_eol in choices:
            b=before.replace("\n",local_eol).encode()
            if child.count(b)==1:found.append((b,after.replace("\n",local_eol).encode()))
        assert len(found)==1,(name,before,len(found))
        b,a=found[0]
        child=child.replace(b,a);applied.append((b,a))
    inverse=child
    for b,a in reversed(applied):
        assert inverse.count(a)==1
        inverse=inverse.replace(a,b)
    assert inverse==original
    prepared.append((name,parent,changes,filename,original,child))
OUT.mkdir()
receipts=[]
for name,parent,changes,filename,original,child in prepared:
    snapshot=OUT/(name+"_parent.gd");snapshot.write_bytes(original)
    out=OUT/filename;out.write_bytes(child)
    receipts.append({"id":name,"candidate_path":ref(out),"candidate_sha256":sha(out),"parent_snapshot":ref(snapshot),"parent_sha256":sha(snapshot),"original_source":ref(parent),"wholebyte_inverse":True,"exact_hunks":[{"before":b,"after":a} for b,a in changes]})
receipt={"status":"ROOT_APPROVED_BUILD_ONLY_THREE_VISUAL_CANDIDATES_NOT_ENGINE_CHECKED_NOT_SOURCE_CLOSED_NOT_DEPLOYED",
 "candidates":receipts,
 "HUD":{"canonical_files_if_later_adopted":1,"tscn_unchanged":True,"black_alpha":0.62,"plain_StyleBoxFlat_user_explicit_exception":True,"hover_or_local_left_click_pin_toggle":True,"only_local_original_left_press_handled":True,"Esc_J_rightclick_wheel_and_map_outside_rect_untouched":True,"hidden_or_dialog_playing_ignores_pointer":True,"actual_wrapped_content_height_plus_padding":30,"existing_width_and_text_logic_unchanged":True,"no_narrow_title_atlas":True},
 "Hero":{"exact_eight_ids":hero_ids,"visual_multiplier_factor":1.12,"no_Player_gd_delta":True,"body_34x24_speed_and_physical_feet_unchanged":True,"original_anchor_formula_unchanged":True,"all_other_scenes_and_rooms_unchanged":True},
 "ENV":{"only_pawn_forecourt_core_opacity":1.0,"other_ten_rects_core_opacity":0.66,"all_rect_feather_world":32.0,"shader_DA5141_unchanged":True,"all_four_wholealpha_stamps_unchanged":True,"author19_and_native_unchanged":True},
 "portrait":"Separate art-owned production remains pending; no portrait placeholder or runtime binding included",
 "forbidden_actions_not_taken":["canonical write","source closure or deployment","Godot/check-only/run","new media/image editing/import","NAV/body/door/NPC/task changes","old candidate/proof overwrites"],
 "next":"Root first finishes B/D/E remaining actual. These candidates require a later single tightly scoped source successor and bounded HUD/hero/ENV visual verification; no claim of runtime or visual acceptance."}
out=OUT/"handoff_READY.json"
out.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"handoff_path":ref(out),"handoff_sha256":sha(out),"candidates":[{"id":r["id"],"sha256":r["candidate_sha256"]} for r in receipts]}))


