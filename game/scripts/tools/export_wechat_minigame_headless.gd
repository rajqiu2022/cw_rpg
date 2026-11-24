extends SceneTree

const Exporter = preload("res://addons/godot_mini_game/exporter.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: --script ... -- <appid> <output_dir> [preset]")
		quit(2)
		return
	var appid := str(args[0])
	var output_dir := str(args[1])
	var preset := str(args[2]) if args.size() >= 3 else "Web-WeChat-Base"
	var exporter := Exporter.new()
	var err := await exporter.export_mini_game(
		"wechat",
		appid,
		"landscape",
		preset,
		output_dir,
	)
	if err != OK:
		push_error("WeChat mini-game native export failed: %s" % error_string(err))
		quit(1)
		return
	print("[WeChatNativeExport] output=%s" % output_dir)
	quit(0)
