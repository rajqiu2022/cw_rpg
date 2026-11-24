extends RefCounted
## The resource at the original item_id remains the immutable base template.
const MAX_RANK := 3
const ORE := [2, 3, 4]
const GOLD := [10, 20, 35]
const AFFIX_NAMES := {
	"bleed": "锋痕：命中后 18% 概率流血两回合",
	"poison": "淬毒：命中后 16% 概率中毒两回合",
	"crit_damage": "破势：暴击倍率 +0.20",
}

static func roll_affixes(base: Equipment, rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = ["bleed", "poison", "crit_damage"]
	pool.erase(String(base.special_effect_type))
	var result: Array[String] = []
	for i in rng.randi_range(1, 2):
		result.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return result

static func make_weapon(base: Equipment, rank: int, raw_affixes: Variant) -> Equipment:
	if base == null or base.slot != Equipment.Slot.WEAPON or rank < 1 or rank > MAX_RANK:
		return base
	var item := base.duplicate() as Equipment
	item.forge_rank = rank
	item.atk_bonus += rank * 2
	item.display_name += " +%d" % rank
	item.description += "\n锻打：攻击 +%d。" % (rank * 2)
	if rank == MAX_RANK:
		item.quality = mini(int(base.quality) + 1, int(Item.Quality.LEGENDARY)) as Item.Quality
		if raw_affixes is Array:
			for raw: Variant in raw_affixes:
				if not raw is String or not AFFIX_NAMES.has(raw) or raw == String(base.special_effect_type) or item.forge_affixes.has(raw):
					continue
				item.forge_affixes.append(raw)
				item.description += "\n" + String(AFFIX_NAMES[raw])
				if item.forge_affixes.size() >= 2:
					break
	return item
