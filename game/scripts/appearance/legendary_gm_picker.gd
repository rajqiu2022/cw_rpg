extends Node

const GROUP := "神兵外显"
const FEATURED: Array[StringName] = [
	&"seven_star_sword", &"jinhe_duanyue_blade", &"yuanming_sword",
	&"tiger_roar_blade", &"buddha_subduing_staff", &"heaven_piercing_staff",
	&"golden_hoop_staff", &"immortal_gauntlets",
	&"zhouju_bronze_sword", &"suwusheng_teapot",
]

var console: CanvasLayer
var search: LineEdit
var choices: OptionButton
var inventory: Node

func _ready() -> void:
	console=get_node_or_null("/root/GMConsole")
	inventory=get_node_or_null("/root/Inventory")
	if console==null or inventory==null:
		return
	search=console.get("_item_search")
	choices=console.get("_item_select")
	var panel: Control=console.get("_panel")
	if search==null or choices==null or panel==null:
		return
	var shortcut:=Button.new()
	shortcut.name="LegendaryAppearanceFilter"
	shortcut.text=GROUP
	shortcut.tooltip_text="只显示已接入专属外显的神兵"
	shortcut.pressed.connect(_show_featured)
	var container:=search.get_parent()
	container.add_child(shortcut)
	container.move_child(shortcut,search.get_index()+1)
	search.clear_button_enabled=true
	search.text_changed.connect(_apply_search)
	panel.visibility_changed.connect(_panel_visibility_changed)
	for button: Button in panel.find_children("*","Button",true,false):
		if button.text=="刷新数据":
			button.pressed.connect(_panel_visibility_changed)
			break
	_apply_search(search.text)

func _show_featured() -> void:
	search.text=GROUP
	_apply_search(GROUP)

func _panel_visibility_changed() -> void:
	# GM rebuilds its ordinary list immediately after showing the panel.
	_apply_search.call_deferred(search.text)

func _apply_search(query: String) -> void:
	var entries: Array=console.get("_all_items")
	var featured_rows: Array[Dictionary]=[]
	for id in FEATURED:
		var item: Equipment=inventory.load_item_by_id(id) as Equipment
		if item==null:
			continue
		var label: String="%s [%s]" % [item.display_name,id]
		var known:=false
		for entry: Dictionary in entries:
			if entry.get("id")==id:
				label=entry.label
				known=true
				break
		if not known:
			entries.append({"id":id,"label":label})
		featured_rows.append({"id":id,"label":label})
	var needle:=query.strip_edges()
	if needle in [GROUP,"神兵","金箍棒"]:
		choices.clear()
		for row: Dictionary in featured_rows:
			if needle=="金箍棒" and row.id!=&"golden_hoop_staff":
				continue
			choices.add_item(row.label)
			choices.set_item_metadata(choices.item_count-1,row.id)
		choices.disabled=choices.item_count==0
		if choices.item_count>0:
			choices.select(0)
	else:
		console.call("_refresh_item_options",query)
