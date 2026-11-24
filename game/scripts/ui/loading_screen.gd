extends CanvasLayer
class_name LoadingScreen

## 正式 Loading 视觉层。只负责展示，资源状态由 LoadingManager 驱动。

@onready var root: Control = $Root
@onready var background: TextureRect = $Root/Background
@onready var category_label: Label = $Root/Content/Category
@onready var title_label: Label = $Root/Content/Title
@onready var body_label: Label = $Root/Content/Body
@onready var stage_label: Label = $Root/Content/Footer/Status/Stage
@onready var percent_label: Label = $Root/Content/Footer/Status/Percent
@onready var progress_bar: ProgressBar = $Root/Content/Footer/Progress
@onready var retry_button: Button = $Root/Content/Footer/Retry

var _retry_action: Callable = Callable()
var _motion_tween: Tween = null
var _visibility_tween: Tween = null
var _visibility_generation := 0
var _opaque_backdrop: ColorRect
var _backhill_destination: Dictionary = {}
var _suspended_dialog_input: Control
const BACKHILL_FOREST := &"ch1_s3_zhuwei_forest"
const BACKHILL_VILLAGE := &"ch1_s2_qingfeng"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opaque_backdrop = ColorRect.new()
	_opaque_backdrop.name = "TransitionBackdrop"
	_opaque_backdrop.color = Color("#070e14")
	_opaque_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opaque_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_opaque_backdrop)
	root.move_child(_opaque_backdrop, 0)
	retry_button.pressed.connect(_on_retry_pressed)
	root.visible = false
	root.visibility_changed.connect(_sync_dialog_input)


func _sync_dialog_input() -> void:
	if root.visible:
		# Arrival choices can request a second trip. The global dialogue layer
		# receives keyboard input independently of this screen's mouse filter.
		var box := DialogPlayer.get_node_or_null("DialogLayer/DialogBox") as Control
		if is_instance_valid(box) and box.is_processing_input():
			_suspended_dialog_input = box
			box.set_process_input(false)
	else:
		_restore_dialog_input()


func _restore_dialog_input() -> void:
	if is_instance_valid(_suspended_dialog_input):
		_suspended_dialog_input.set_process_input(true)
	_suspended_dialog_input = null


func configure(card: Dictionary, transition_title: String = "") -> void:
	var image_path := String(card.get("image", ""))
	background.texture = load(image_path) as Texture2D if not image_path.is_empty() else null
	category_label.text = String(card.get("category", "江湖见闻"))
	title_label.text = transition_title if not transition_title.is_empty() else String(card.get("title", "行至江湖深处"))
	body_label.text = String(card.get("body", "风声会掩去脚步，却掩不住留下的因果。"))
	retry_button.visible = false
	_retry_action = Callable()
	_start_background_motion()


func show_screen(_immediate: bool = false) -> void:
	_cancel_visibility_tween()
	_backhill_destination.clear()
	if LoadingManager.get("_transition_active") and LoadingManager.get("_transition_kind") == &"field":
		var payload := SceneRouter.get_field_payload()
		var destination := StringName(payload.get("scene_id", ""))
		var source := get_tree().current_scene
		var source_id := &""
		if is_instance_valid(source) and source.has_method("get_field_loading_state"):
			source_id = StringName(source.get_field_loading_state().get("scene_id", ""))
		if _is_backhill(destination) or (destination == BACKHILL_VILLAGE and _is_backhill(source_id)):
			_backhill_destination = payload.duplicate(true)
	root.visible = true
	# Never show an outgoing field during scene-host swapping.
	root.modulate.a = 1.0


func _is_backhill(id: StringName) -> bool:
	return id == BACKHILL_FOREST or String(id).begins_with("ch1_s4_")


func _input(event: InputEvent) -> void:
	# The router sets the next field payload before the loader can reject a
	# second transition. Do not let a second Space/click reach either field.
	if _backhill_destination.is_empty() or not root.visible or not LoadingManager.get("_transition_active"):
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event is InputEventMouseButton or event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()


func _backhill_ready(field: Node, destination: StringName) -> bool:
	if not is_instance_valid(field) or not field.has_method("get_field_loading_state"):
		return false
	var state: Dictionary = field.get_field_loading_state()
	return state.get("complete") == true and state.get("failed") != true and StringName(state.get("scene_id", "")) == destination and SceneRouter.get_current_field_id() == destination


func _backhill_reveal_failed() -> void:
	var retry := _backhill_destination.duplicate(true)
	_backhill_destination.clear()
	show_failure("地图未就绪，请重试。", func() -> void:
		SceneRouter.go_field_smart(StringName(retry.scene_id), retry.get("player_spawn"), String(retry.get("pending_action", "")))
	)


func hide_screen() -> void:
	_cancel_visibility_tween()
	if not root.visible:
		return
	var generation := _visibility_generation
	var field := get_tree().current_scene
	var backhill_id := StringName(_backhill_destination.get("scene_id", ""))
	if not backhill_id.is_empty():
		var deadline := Time.get_ticks_msec() + 5000
		while not _backhill_ready(field, backhill_id):
			if Time.get_ticks_msec() >= deadline:
				_backhill_reveal_failed()
				return
			await get_tree().process_frame
			if generation != _visibility_generation or not is_inside_tree(): return
			field = get_tree().current_scene
	if is_instance_valid(field) and field.has_method("get_field_loading_state"):
		var adventure := get_node_or_null("/root/AdventureRuntime")
		if adventure != null:
			adventure.call("prepare_loaded_field", field)
			var links := adventure.get_node_or_null("AdventureWorldLinks31f")
			if links != null and links.has_method("prepare_world_view"):
				links.call("prepare_world_view", field)
	if not backhill_id.is_empty():
		var camera := get_viewport().get_camera_2d()
		if is_instance_valid(camera) and not field.is_ancestor_of(camera):
			_backhill_reveal_failed()
			return
		if is_instance_valid(camera):
			camera.reset_smoothing()
			camera.force_update_scroll()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	if generation != _visibility_generation or not is_inside_tree():
		return
	if not backhill_id.is_empty() and (field != get_tree().current_scene or not _backhill_ready(field, backhill_id)):
		_backhill_reveal_failed()
		return
	var tween := root.create_tween()
	_visibility_tween = tween
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate:a", 0.0, 0.22)
	# Killing a superseded Tween does not emit finished. Observe its lifecycle
	# on existing idle frames so cancellation also releases this pending call.
	while generation == _visibility_generation and tween.is_valid() and tween.is_running():
		await get_tree().process_frame
	if generation != _visibility_generation or not is_inside_tree(): return
	_visibility_tween = null
	root.visible = false
	root.modulate.a = 1.0
	_backhill_destination.clear()


func _cancel_visibility_tween() -> void:
	_visibility_generation += 1
	if _visibility_tween != null and _visibility_tween.is_valid():
		_visibility_tween.kill()
	_visibility_tween = null


func _exit_tree() -> void:
	_restore_dialog_input()
	_cancel_visibility_tween()


func is_showing() -> bool:
	return root.visible


func set_progress(ratio: float, stage_text: String) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	progress_bar.show()
	percent_label.show()
	progress_bar.value = clamped * 100.0
	percent_label.text = "%d%%" % int(round(clamped * 100.0))
	stage_label.text = stage_text
	retry_button.visible = false


func show_failure(message: String, retry_action: Callable) -> void:
	stage_label.text = message
	percent_label.hide()
	progress_bar.hide()
	_retry_action = retry_action
	retry_button.visible = not retry_action.is_null()


func _start_background_motion() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	background.scale = Vector2.ONE
	background.pivot_offset = Vector2(960.0, 540.0)
	_motion_tween = background.create_tween().set_loops()
	_motion_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_motion_tween.tween_property(background, "scale", Vector2(1.035, 1.035), 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(background, "scale", Vector2.ONE, 9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_retry_pressed() -> void:
	if not _retry_action.is_null():
		_retry_action.call()

