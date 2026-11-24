extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var list := FileAccess.open(args[0], FileAccess.READ)
	var pack := PCKPacker.new()
	if not list or pack.pck_start(args[1]) != OK:
		quit(1)
		return
	while not list.eof_reached():
		var line := list.get_line()
		if line.is_empty():
			continue
		var pair := line.split("\t", false, 1)
		if pair.size() != 2 or pack.add_file("res://" + pair[0], pair[1]) != OK:
			printerr("Failed to pack ", line)
			quit(2)
			return
	if pack.flush() != OK:
		quit(3)
		return
	var notices := FileAccess.open(args[0].get_base_dir().path_join("ENGINE-NOTICES.txt"), FileAccess.WRITE)
	if not notices:
		quit(4)
		return
	notices.store_line(Engine.get_license_text())
	for component in Engine.get_copyright_info():
		notices.store_line(JSON.stringify(component, "  "))
	var licenses := Engine.get_license_info()
	for license_name in licenses:
		notices.store_line(str(license_name) + "\n" + str(licenses[license_name]))
	quit()
