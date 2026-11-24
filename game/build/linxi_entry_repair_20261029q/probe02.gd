extends "res://build/linxi_entry_repair_20261029q/probe01.gd"
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	sr.call("go_field_smart",&"linxi_village_center",Vector2(.875,.468))
	var field:=await wait_field("linxi_village_center")
	if field==null:finish(false);return
	var e:=InputEventKey.new();e.keycode=KEY_D;e.physical_keycode=KEY_D;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	await key(KEY_SPACE)
	e=InputEventKey.new();e.keycode=KEY_D;e.physical_keycode=KEY_D;e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events()
	field=await wait_field("linxi_farmer_cottage")
	if field==null:finish(false);return
	await capture("moving_entry_before",field)
	sr.call("go_field_smart",&"linxi_farmer_cottage",Vector2(.835,.60))
	field=await wait_field("linxi_farmer_cottage")
	if field==null:finish(false);return
	await capture("legacy_before02",field);finish(true)
func finish(ok:bool)->void:
	var f:=FileAccess.open(OUT+"probe02.json",FileAccess.WRITE);f.store_string(JSON.stringify({"finished":ok,"rows":rows},"\t"));f.close();quit(0 if ok else 1)
