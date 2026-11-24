class_name NPCCatalog
extends Resource

@export var profiles: Array[NPCProfile] = []

func find(npc_id: StringName, scene_id: StringName) -> NPCProfile:
	for profile in profiles:
		if profile.npc_id == npc_id and (profile.scene_ids.is_empty() or scene_id in profile.scene_ids):
			return profile
	return null
