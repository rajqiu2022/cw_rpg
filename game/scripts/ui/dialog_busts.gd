extends RefCounted

const INDEX := "res://data/config/dialog_busts.json"
# Authored conversations belonging to bystanders. Keep identities local to their
# dialogue: an inn guest and a quest witness can have the same displayed name.
const AMBIENT_CONVERSATIONS: Array[StringName] = [
	&"linxi_center_farmer", &"linxi_center_granny", &"linxi_center_herb_gatherer",
	&"linxi_center_apothecary_apprentice", &"linxi_center_peddler",
	&"linxi_scrollmap_porter", &"linxi_scrollmap_guard", &"linxi_scrollmap_veteran",
	&"interior_inn_guest_chatter", &"interior_inn_traveler_chatter",
	&"ch1_s2_inn_waiter", &"east_tea_ridge_farmer",
	&"ch4_docks_roles_20261019ad_carrier_daily", &"ch4_docks_roles_20261019ad_west_porter_daily",
	&"ch4_docks_roles_20261019ad_store_attendant_daily", &"ch4_docks_roles_20261019ad_rope_seller_daily",
]
static var _index: Dictionary
static var _role_patterns: Array[RegEx] = []

static func is_party_speaker(speaker: String) -> bool:
	if speaker == "冷孤云" or (GameState.player != null and speaker == GameState.player.display_name):
		return true
	for member in GameState.party:
		if member != null and member.display_name == speaker:
			return true
	return false

static func for_speaker(speaker: String, portrait: String, scene: Node, conversation: DialogScript = null) -> Texture2D:
	if speaker.strip_edges().is_empty() or speaker in ["旁白", "旧船单"]:
		return null
	if conversation != null and not is_party_speaker(speaker) and _ambient_speaker(conversation, scene, speaker):
		return null
	if _index.is_empty():
		_index = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
		for rule in _index.rules:
			_role_patterns.append(RegEx.create_from_string(rule[0]))
	var id := _portrait_id(speaker.strip_edges(), portrait, scene)
	var row: Array = _index.regions[id]
	if row.size() == 1:
		return load(row[0]) as Texture2D
	var bust := AtlasTexture.new()
	bust.atlas = load(row[0]) as Texture2D
	bust.region = Rect2(row[1], row[2], row[3], row[4])
	bust.filter_clip = true
	return bust

static func _ambient_speaker(conversation: DialogScript, scene: Node, speaker: String) -> bool:
	if conversation.dialog_id in AMBIENT_CONVERSATIONS:
		return true
	if scene == null or not "_active_dialog_npc" in scene:
		return false
	var npc := scene.get("_active_dialog_npc") as NPCNode
	if not is_instance_valid(npc) or npc.npc_name != speaker:
		return false
	# These markers are assigned by the city's dedicated ambient NPC providers.
	return npc.get_meta("ambient25i_exact_identity", false) or npc.get_meta("ap_daily_exact_identity", false) or npc.get_meta("ap_quarter_daily_exact_identity", false)

static func _portrait_id(speaker: String, portrait: String, scene: Node) -> int:
	if GameState.player != null and speaker == GameState.player.display_name:
		return _index.names["冷孤云"]
	if _index.names.has(speaker):
		return _index.names[speaker]
	for part in speaker.split("·", false):
		if _index.names.has(part.strip_edges()):
			return _index.names[part.strip_edges()]
	for i in _role_patterns.size():
		if _role_patterns[i].search(speaker):
			return _index.rules[i][1]
	if _index.paths.has(portrait):
		return _index.paths[portrait]
	if scene != null and scene.has_method("_on_player_interacted"):
		for npc in scene.get("_npc_nodes"):
			if is_instance_valid(npc) and npc.npc_name == speaker:
				return _index.paths.get(npc.sprite_path, _index.fallback)
	return _index.fallback
