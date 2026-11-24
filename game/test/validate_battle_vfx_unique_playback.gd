extends SceneTree

const SAMPLE_EFFECTS: Array[StringName] = [
	&"gufeng_jingang_buhuai",
	&"qinghe_returning_breath",
	&"wudang_xuanwu_ge",
	&"mingwu_wuyin_sanshi",
]

var _checks := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Control.new()
	stage.size = Vector2(1280, 720)
	root.add_child(stage)
	var source := Control.new()
	source.position = Vector2(150, 170)
	source.size = Vector2(220, 320)
	stage.add_child(source)
	var target := Control.new()
	target.position = Vector2(760, 170)
	target.size = Vector2(220, 320)
	stage.add_child(target)
	var vfx := BattleVfxPlayer.new()
	vfx.size = stage.size
	stage.add_child(vfx)
	await process_frame
	for animation_id in SAMPLE_EFFECTS:
		_check(BattleVfxPlayer.has_effect(animation_id), "%s is registered" % animation_id)
		await vfx.play_for_skill(animation_id, target, source)
		await process_frame
		_check(vfx.get_child_count() == 0, "%s cleans up playback layers" % animation_id)
	print("[BattleVfxUniquePlayback] checks=%d failed=%d" % [_checks, _failed])
	quit(1 if _failed else 0)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		push_error("[BattleVfxUniquePlayback] FAIL: %s" % label)
