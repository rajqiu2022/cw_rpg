class_name BattleEncounter
extends Resource

## Data contract for a full encounter. IDs are resolved by BattleController.
## A legacy enemy_id payload is normalized to one enemy ID at runtime.

@export var encounter_id: StringName = &""
@export var player_unit_ids: Array[StringName] = []
@export var enemy_unit_ids: Array[StringName] = []
@export var background_path: String = ""
@export var allow_flee: bool = true
@export var victory_action: String = ""
@export var defeat_action: String = ""
