extends Sprite2D

const ATLAS_PATH := "res://art/modules/linxi_du_smithy_20261109/du_hammer_atlas.png"
const METAL := preload("res://art/audio/free/sfx_hit_metal_wuxia_v2.wav")
const CELL := 627
const FOOT_X := [268, 225, 248, 236]
const FOOT_Y := [582, 582, 583, 583]
const HOLD_SECONDS := [0.49, 0.12, 0.14, 0.72]
var _npc: NPCNode
var _sound: AudioStreamPlayer2D
var _frame := 0
var _elapsed := 0.0
var _frames: Array[AtlasTexture] = []

func install(npc: NPCNode) -> bool:
	var atlas := load(ATLAS_PATH) as Texture2D
	if atlas == null or atlas.get_size() != Vector2(CELL * 2, CELL * 2):
		return false
	_npc = npc
	name = "SmithingAnimation"
	centered = false
	scale = Vector2.ONE * 0.282
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for i in range(4):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = atlas
		frame_texture.region = Rect2((i % 2) * CELL, floori(i / 2.0) * CELL, CELL, CELL)
		frame_texture.filter_clip = true
		_frames.append(frame_texture)
	_sound = AudioStreamPlayer2D.new()
	_sound.stream = METAL
	_sound.position = Vector2(61, -58) / scale
	_sound.volume_db = -21
	_sound.max_distance = 285
	_sound.attenuation = 1.8
	add_child(_sound)
	_show_frame()
	return true

func _process(delta: float) -> void:
	var working := not _npc._conversation_active
	visible = working
	# Keep the original visible to the NPC mouse hit-test. Its transparent
	# placeholder must not run the outline shader, which samples raw alpha.
	_npc.sprite.self_modulate.a = 0.0 if working else 1.0
	var outline := _npc._interaction_outline_material if _npc._in_range else null
	_npc.sprite.material = null if working else outline
	material = outline if working else null
	if not working:
		_sound.stop()
		return
	_elapsed += delta
	if _elapsed < HOLD_SECONDS[_frame]:
		return
	_elapsed -= HOLD_SECONDS[_frame]
	_frame = (_frame + 1) % _frames.size()
	_show_frame()
	if _frame == 2 and not DialogPlayer.is_playing():
		var field := get_tree().current_scene
		var hero := field.get("_player") as Node2D if field != null else null
		if hero != null and hero.global_position.distance_to(_npc.global_position) < _sound.max_distance:
			_sound.play()

func _show_frame() -> void:
	texture = _frames[_frame]
	offset = -Vector2(FOOT_X[_frame], FOOT_Y[_frame])
