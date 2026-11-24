class_name EnemyDef
extends Resource

## 敌人模板。BattleController 启动时根据 enemy_id 加载对应 .tres，
## 再 spawn 出运行时的 CharacterStats 实例。

@export var enemy_id: StringName = ""
@export var display_name: String = ""
@export var portrait_path: String = ""
@export var battle_actor_path: String = ""
@export var battle_actor_scale: float = 1.0
## Opt out of the formation's default minimum for deliberately smaller sprites.
@export var battle_actor_use_exact_scale: bool = false
## Additional logical pixels above the usual battle status position.
@export var battle_actor_status_lift: float = 0.0
## True when the authored battle art faces right and must be mirrored for the
## enemy formation on the right side of the battlefield.
@export var battle_actor_flip_h: bool = false
@export var defeat_mode: StringName = &"defeat"
@export_category("Battle Animation")
## Every production combatant owns all five sequences. Frames from a different
## character must never be reused as a fallback.
@export var ready_frame_paths: PackedStringArray = PackedStringArray()
@export var move_frame_paths: PackedStringArray = PackedStringArray()
@export var attack_frame_paths: PackedStringArray = PackedStringArray()
@export var hit_frame_paths: PackedStringArray = PackedStringArray()
@export var defeat_frame_paths: PackedStringArray = PackedStringArray()
@export_category("Battle Audio")
@export var ready_sfx_path: String = ""
@export var attack_sfx_path: String = ""
@export var hit_sfx_path: String = ""
@export var defeat_sfx_path: String = ""

@export var level: int = 1
@export var max_hp: int = 80
@export var max_mp: int = 0
@export var attack: int = 14
@export var defense: int = 6
@export var speed: int = 8

@export_category("Battle Traits")
@export var trait_caption: String = ""
@export var poison_weapons: bool = false
## Additional effect on a successful hit from this boss's telegraphed finisher.
@export_enum("none", "venom", "seal") var finisher_affliction: String = "none"
@export_range(0.0, 0.8, 0.01) var evasion_penalty: float = 0.0
## Flat extra defence removed while an armor-break status is active.
@export var breakable_armor: int = 0

@export_category("Party Balance")
## Extra companions add actions much faster than they add tactical risk.  Scale
## durability more than damage so a three-person party gets a real fight without
## making enemies capable of deleting one hero in a single turn.
@export_range(0.0, 0.6, 0.01) var party_hp_scale_per_extra_ally: float = 0.22
@export_range(0.0, 0.25, 0.01) var party_attack_scale_per_extra_ally: float = 0.06
## Authored supports used when this enemy starts through the single-enemy battle
## entry point.  SceneRouter fills only up to the player's current party size,
## capped at three, so the same boss remains fair for a solo player.
@export var party_reinforcement_ids: Array[StringName] = []

@export var skill_ids: Array[StringName] = []   ## 引用 res://data/skills/<id>.tres

@export_category("AI Behavior")
## 0～1：可用时选择非普通攻击招式的概率。Boss通常配置在0.7以上，
## 普通敌人保持0.45～0.6，避免每次行动都重复同一个强力招式。
@export var aggression: float = 0.6

@export_category("Drops")
@export var drop_gold_min: int = 20
@export var drop_gold_max: int = 50
@export var drop_exp: int = 25
@export var drop_items: Array[StringName] = []          ## 必掉物品 id
@export var drop_random: Array[Dictionary] = []
## 例：[{"item_id": "healing_pill_minor", "chance": 0.3, "count": 1}]

@export_category("Chapter")
## 章节 Boss：胜利后进入章节结算而非普通胜利
@export var is_chapter_boss: bool = false


func get_battle_actor_scale(minimum: float) -> float:
	if battle_actor_use_exact_scale and battle_actor_scale > 0.0:
		return battle_actor_scale
	return maxf(minimum, battle_actor_scale)


func to_runtime_stats(extra_allies: int = 0) -> CharacterStats:
	## 把模板"实例化"成战斗用的 CharacterStats。
	var capped_extra_allies := clampi(extra_allies, 0, 2)
	var s: CharacterStats = CharacterStats.new()
	s.character_id = String(enemy_id)
	s.display_name = display_name
	s.portrait_path = portrait_path
	s.level = level
	s.max_hp = maxi(1, roundi(float(max_hp) * (1.0 + party_hp_scale_per_extra_ally * capped_extra_allies)))
	s.hp = s.max_hp
	s.max_mp = max_mp
	s.mp = max_mp
	s.attack = maxi(1, roundi(float(attack) * (1.0 + party_attack_scale_per_extra_ally * capped_extra_allies)))
	s.defense = defense
	s.speed = speed
	s.skills = skill_ids.duplicate()
	return s
