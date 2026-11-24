extends SceneTree

const TARGETS := {
	"bianzhou": {"scene": &"openworld_bianzhou_city", "spawn": Vector2(0.505, 0.500)},
	"xiangzhou": {"scene": &"openworld_xiangzhou_city", "spawn": Vector2(0.505, 0.610)},
	"jinling": {"scene": &"openworld_jinling_city", "spawn": Vector2(0.500, 0.500)},
	"bailu_ferry": {"scene": &"openworld_bailu_ferry", "spawn": Vector2(0.470, 0.560)},
	"luoyang_gate": {"scene": &"ch4_s0_luoyang_gate", "spawn": Vector2(0.500, 0.330)},
	"wudang_gate": {"scene": &"openworld_wudang_gate", "spawn": Vector2(0.500, 0.430)},
	"huashan_gate": {"scene": &"openworld_huashan_forecourt", "spawn": Vector2(0.500, 0.585)},
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var target_name := "xiangzhou"
	for arg: String in OS.get_cmdline_user_args():
		if TARGETS.has(arg):
			target_name = arg
	var target: Dictionary = TARGETS[target_name]
	root.get_node("SceneRouter").go_field_smart(target.scene, target.spawn)
	for tick in range(160):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
			break
	await create_timer(1.0).timeout
	for frame in range(10):
		await process_frame
	var output := "res://screenshots/city_gate_v2_%s.png" % target_name
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Could not read viewport image")
		quit(1)
		return
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not save capture: %s" % output)
		quit(1)
		return
	print("[CityGateV2Capture] " + output)
	quit(0)
