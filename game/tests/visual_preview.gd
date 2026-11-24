extends Node


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var preview_id: StringName = &"linxi_apothecary"
	var preview_kind := "shop"
	for arg: String in args:
		if arg.begins_with("--preview-kind="):
			preview_kind = arg.trim_prefix("--preview-kind=")
		elif arg.begins_with("--preview-id="):
			preview_id = StringName(arg.trim_prefix("--preview-id="))

	if preview_kind == "field":
		SceneRouter.go_field_smart.call_deferred(preview_id)
	else:
		SceneRouter.go_shop.call_deferred(preview_id)
