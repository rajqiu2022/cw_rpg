class_name NPCProfile
extends Resource

@export var npc_id: StringName = &""
@export var display_name: String = ""
@export var scene_ids: Array[StringName] = []
@export var default_dialog_id: StringName = &""
@export var sprite_path: String = ""
@export var portrait_path: String = ""
@export var walk_sprite_path: String = ""
@export var sprite_scale: float = 0.95
@export_enum("idle", "patrol", "seated") var movement_mode: String = "idle"
@export var quest_ids: Array[StringName] = []
@export var role: String = "resident"
