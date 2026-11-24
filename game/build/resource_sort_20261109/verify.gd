extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var loaded := 0
	for resource_path in [
		"res://art/ui/menu_buttons_20261109/system.png",
		"res://art/battle_vfx/vfx_linxi_sword_one_4frame_v1.png",
		"res://art/maps/world_coast_20261031h/candidate02/overview.png",
		"res://art/background_chunks/world_map_jianghu_v8/mobile/tile_00_00.png",
		"res://art/audio/bgm/bgm_jianghu_journey_v4.wav",
		"res://art/audio/free/sfx_blade_light_wuxia_v2.wav",
	]:
		if ResourceLoader.exists(resource_path) and load(resource_path) != null:
			loaded += 1
		else:
			printerr("Missing: ",resource_path)
	print("RESOURCE_SORT verified ",loaded,"/6")
	quit(0 if loaded==6 else 1)

