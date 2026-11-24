class_name TestimonyDef
extends Resource

## NPC 证词定义。证词可以先被听到，再由物证或其他证人验证。

@export var testimony_id: StringName = &""
@export var display_name: String = ""
@export var speaker_npc_id: StringName = &""
@export_multiline var statement: String = ""
@export var chapter: int = 1
@export_range(0, 100, 1) var initial_credibility: int = 50
@export var related_evidence_ids: Array[StringName] = []
@export var contradicts_testimony_ids: Array[StringName] = []

