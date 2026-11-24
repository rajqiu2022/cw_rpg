extends RefCounted

const PURPLE_CHANCE := 0.10
const BLUE_CHANCE := 0.35
const LOOT := {
	&"wild_elite_road": [&"hero_hat", &"battle_helmet"],
	&"wild_elite_wolf": [&"iron_mail", &"dark_iron_boots"],
	&"wild_elite_zhuwei": [&"steel_helmet", &"assassin_blade"],
	&"wild_elite_temple": [&"bronze_ring_staff", &"battle_helmet"],
	&"wild_elite_snow": [&"gufeng_iron_bracer", &"dark_iron_boots"],
	&"wild_elite_hunter": [&"mountain_armor", &"dark_iron_armor"],
	&"wild_elite_convoy": [&"cloud_boots", &"assassin_blade"],
	&"wild_elite_lieyun": [&"dragon_scale_bracers", &"battle_helmet"],
	&"wild_elite_post": [&"wind_walker_boots", &"battle_helmet"],
	&"wild_elite_marsh": [&"cloud_boots", &"assassin_blade"],
	&"wild_elite_mine": [&"mountain_armor", &"dark_iron_armor"],
	&"wild_elite_yanmen": [&"frost_dart", &"dark_iron_boots"],
	&"wild_elite_mistwood": [&"dragon_scale_bracers", &"dark_iron_armor"],
	&"wild_elite_gallery": [&"wind_walker_boots", &"assassin_blade"],
	&"wild_elite_western_lion": [&"mountain_armor", &"dark_iron_armor"],
}

static func is_elite(id: StringName) -> bool:
	return LOOT.has(id)

# A single roll selects a purple item, a blue item, or no equipment.
static func equipment_for_roll(id: StringName, roll: float) -> StringName:
	var pool: Array = LOOT.get(id, [])
	if pool.is_empty() or roll >= PURPLE_CHANCE + BLUE_CHANCE:
		return &""
	return pool[1 if roll < PURPLE_CHANCE else 0]
