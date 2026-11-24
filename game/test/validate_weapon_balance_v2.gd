extends SceneTree

const MIN_ATTACK_BY_QUALITY := [10, 14, 22, 34, 50]
const WEAPON_SCALING_BY_QUALITY := [4, 6, 10, 15, 22]
const SPECIAL_EFFECT_CHANCE_MAX := [0.0, 0.0, 0.20, 0.30, 0.40]
const SPECIAL_EFFECT_VALUE_MAX := [0, 0, 12, 20, 30]
const SPECIAL_EFFECT_DURATION_MAX := [0, 0, 2, 2, 3]
const WEAPON_FAMILIES := [&"sword", &"blade", &"staff", &"palm", &"hidden"]
const ALLOWED_SPECIAL_EFFECTS := [&"poison", &"bleed", &"weaken", &"internal_injury", &"armor_break", &"damage_boost", &"guard", &"heal"]
const EXPECTED_FAMOUS_QUALITY := {
	"heavy_iron_sword": Item.Quality.EPIC,
	"qingming_sword": Item.Quality.EPIC,
	"golden_hoop_staff": Item.Quality.LEGENDARY,
	"seven_star_sword": Item.Quality.LEGENDARY,
	"zhouju_bronze_sword": Item.Quality.LEGENDARY,
}

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	var count := 0
	var identity_signatures: Dictionary = {}
	var rare_effect_families: Dictionary = {}
	var epic_effect_counts: Dictionary = {}
	var legendary_effect_families: Dictionary = {}
	for filename in DirAccess.get_files_at("res://data/equipment"):
		if not filename.ends_with(".tres"):
			continue
		var eq: Equipment = load("res://data/equipment/%s" % filename)
		if eq == null or eq.slot != Equipment.Slot.WEAPON:
			continue
		count += 1
		_check(not String(eq.weapon_type).is_empty(), "%s has explicit weapon_type" % eq.item_id)
		# Palm weapons trade raw attack for defensive/attribute value, so the
		# traditional weapon attack floor does not apply to them.
		if eq.weapon_type != &"palm":
			_check(eq.atk_bonus >= MIN_ATTACK_BY_QUALITY[eq.quality], "%s meets quality attack floor" % eq.item_id)
		_check(eq.crit_chance_bonus >= 0.0 and eq.crit_chance_bonus <= 0.5, "%s crit chance is bounded" % eq.item_id)
		_check(eq.hit_chance_bonus >= 0.0 and eq.hit_chance_bonus <= 0.2, "%s hit chance is bounded" % eq.item_id)
		_check(eq.weapon_type != &"dagger" and eq.weapon_type != &"short_blade" and eq.weapon_type != &"axe",
			"%s uses normalized weapon taxonomy" % eq.item_id)
		var identity_signature := "%d/%s/%d/%d/%d/%d/%d/%d/%d/%.3f/%.3f/%d/%s" % [
			eq.quality, eq.weapon_type, eq.atk_bonus, eq.def_bonus, eq.speed_bonus,
			eq.str_bonus, eq.agi_bonus, eq.inner_bonus, eq.guard_bonus,
			eq.crit_chance_bonus, eq.hit_chance_bonus, eq.weapon_skill_bonus_scaling,
			eq.special_effect_type,
		]
		_check(not identity_signatures.has(identity_signature),
			"%s does not duplicate another same-tier weapon build" % eq.item_id)
		identity_signatures[identity_signature] = eq.item_id
		var family := Equipment.normalize_weapon_type(eq.weapon_type)
		if not eq.special_effect_type.is_empty():
			_check(eq.quality >= Item.Quality.RARE, "%s special effect starts at blue quality" % eq.item_id)
			_check(eq.special_effect_type in ALLOWED_SPECIAL_EFFECTS, "%s uses a supported special effect" % eq.item_id)
			_check(eq.special_effect_chance > 0.0 and eq.special_effect_chance <= SPECIAL_EFFECT_CHANCE_MAX[eq.quality],
				"%s special effect chance follows its quality cap" % eq.item_id)
			_check(eq.special_effect_value >= 0 and eq.special_effect_value <= SPECIAL_EFFECT_VALUE_MAX[eq.quality],
				"%s special effect value follows its quality cap" % eq.item_id)
			_check(eq.special_effect_duration >= 0 and eq.special_effect_duration <= SPECIAL_EFFECT_DURATION_MAX[eq.quality],
				"%s special effect duration follows its quality cap" % eq.item_id)
			_check(not eq.special_effect_description.strip_edges().is_empty(), "%s exposes its special effect in UI" % eq.item_id)
			if eq.quality == Item.Quality.RARE:
				rare_effect_families[family] = true
			elif eq.quality == Item.Quality.EPIC:
				epic_effect_counts[family] = int(epic_effect_counts.get(family, 0)) + 1
			elif eq.quality == Item.Quality.LEGENDARY:
				legendary_effect_families[family] = true
		if eq.quality == Item.Quality.LEGENDARY:
			_check(not eq.special_effect_type.is_empty(), "%s legendary weapon has a special effect" % eq.item_id)
			_check(not eq.special_effect_description.strip_edges().is_empty(), "%s legendary effect has UI copy" % eq.item_id)
		if eq.weapon_type != &"palm":
			_check(eq.get_weapon_skill_scaling_bonus() == WEAPON_SCALING_BY_QUALITY[eq.quality],
				"%s has its quality-tier technique bonus" % eq.item_id)

		if eq.weapon_type == &"sword" and eq.item_id != &"heavy_iron_sword":
			_check(eq.speed_bonus > 0 and eq.agi_bonus > 0 and eq.crit_chance_bonus > 0.0,
				"%s follows fast crit sword identity" % eq.item_id)
		if eq.weapon_type == &"blade":
			_check(eq.def_bonus > 0 and eq.guard_bonus > 0,
				"%s follows high-attack defensive blade identity" % eq.item_id)

	for item_id in EXPECTED_FAMOUS_QUALITY:
		var eq: Equipment = load("res://data/equipment/%s.tres" % item_id)
		_check(eq != null and eq.quality >= EXPECTED_FAMOUS_QUALITY[item_id], "%s has famous-weapon quality" % item_id)

	var seven_star: Equipment = load("res://data/equipment/seven_star_sword.tres")
	_check(seven_star.atk_bonus >= 60 and seven_star.crit_chance_bonus >= 0.25,
		"seven-star sword delivers legendary power spike")
	var tiger: Equipment = load("res://data/equipment/tiger_roar_blade.tres")
	_check(not tiger.icon_path.is_empty() and ResourceLoader.exists(tiger.icon_path), "tiger roar blade has a real icon")
	var legendary_blade: Equipment = load("res://data/equipment/jinhe_duanyue_blade.tres")
	_check(legendary_blade != null and legendary_blade.quality == Item.Quality.LEGENDARY and legendary_blade.weapon_type == &"blade",
		"legendary blade tier is represented")
	_check(not legendary_blade.special_effect_description.is_empty(), "legendary blade has a visible special effect")
	var staff_signatures: Dictionary = {}
	for staff_path in ["buddha_subduing_staff", "golden_hoop_staff", "heaven_piercing_staff"]:
		var staff: Equipment = load("res://data/equipment/%s.tres" % staff_path)
		staff_signatures["%d/%d/%d/%.2f/%.2f/%s" % [staff.atk_bonus, staff.str_bonus, staff.inner_bonus, staff.crit_chance_bonus, staff.hit_chance_bonus, staff.special_effect_type]] = true
	_check(staff_signatures.size() == 3, "legendary staves have distinct combat identities")
	for family in WEAPON_FAMILIES:
		_check(rare_effect_families.has(family), "%s has a blue weapon with a restrained special effect" % family)
		_check(int(epic_effect_counts.get(family, 0)) >= 1 and int(epic_effect_counts.get(family, 0)) <= 2,
			"%s has one or two purple weapons with special effects" % family)
		_check(legendary_effect_families.has(family), "%s has an orange weapon with a special effect" % family)
	_check(count == 52, "all 52 weapons were validated")

	print("[WeaponBalanceV2] checks=%d weapons=%d failed=%d" % [checks, count, failures.size()])
	for failure in failures:
		push_error("[WeaponBalanceV2] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
