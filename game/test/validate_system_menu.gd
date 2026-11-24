extends SceneTree

const MENU_SCENE := "res://scenes/ui/system_menu.tscn"
const HUD_SCENE := "res://scenes/ui/field_primary_hud.tscn"


func _initialize() -> void:
	var menu_scene: PackedScene = load(MENU_SCENE) as PackedScene
	if menu_scene == null:
		push_error("[SystemMenuCheck] system menu scene cannot load")
		quit(1)
		return
	var menu: Node = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	var hidden_panel: bool = not bool(menu.get("visible"))
	var bgm: HSlider = menu.get_node_or_null("Panel/Content/BgmRow/BgmSlider") as HSlider
	var sfx: HSlider = menu.get_node_or_null("Panel/Content/SfxRow/SfxSlider") as HSlider
	var save: Button = menu.get_node_or_null("Panel/Content/SaveBtn") as Button
	var close: BaseButton = menu.get_node_or_null("Panel/Content/CloseBtn") as BaseButton
	var slider_nodes_ok: bool = bgm != null and sfx != null
	var button_nodes_ok: bool = save != null and close != null
	var confirmation_ok: bool = menu.find_child("SystemMenuConfirmation", true, false) is FormalConfirmDialog
	var ok: bool = hidden_panel and slider_nodes_ok and button_nodes_ok and confirmation_ok
	menu.queue_free()
	var hud_scene: PackedScene = load(HUD_SCENE) as PackedScene
	var hud: Control = hud_scene.instantiate() if hud_scene != null else null
	if hud != null:
		root.add_child(hud)
		await process_frame
		var system_button: TextureButton = hud.get_node_or_null("BtnSystem") as TextureButton
		var hidden_menu: bool = system_button != null and system_button.position.x == 1950.0
		ok = ok and hidden_menu
		print("[SystemMenuCheck] hidden_panel=%s sliders=%s buttons=%s confirmation=%s hidden_menu=%s" % [hidden_panel, slider_nodes_ok, button_nodes_ok, confirmation_ok, hidden_menu])
		hud.queue_free()
	else:
		print("[SystemMenuCheck] HUD scene cannot load")
	quit(0 if ok else 1)
