extends SceneTree
## Load-only; never instantiates/calls the draft generator or writes reviews.
const GENERATOR_PATH := "res://tests/helpers/prepare_joint_v9e_joint_release_review_drafts_20261007.gd"
const GENERATOR_SHA := "0f031f54ed69a64f7136678f776af44cad10181f4232cd82adcd20307eaadc2e"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var script: GDScript = ResourceLoader.load(GENERATOR_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
	var ok: bool = FileAccess.get_sha256(GENERATOR_PATH).to_lower() == GENERATOR_SHA and script != null and script.can_instantiate()
	print("V9E_JOINT_RELEASE_REVIEW_DRAFTS_SOURCE_COMPILE ", GENERATOR_PATH, " valid=", ok, " generator_executed=false")
	script = null
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if ok else 1)
