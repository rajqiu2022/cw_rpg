extends RefCounted
## Data only. Existing Item/Equipment resources keep all their original stats.
## A real station is resolved by the caller; a medicine shop is never a smith.
const DATA := [
	{"id":"clear_sight_powder","station":"medicine","output":"clear_sight_powder","count":1,"ingredients":{"field_herb_mint":1,"field_herb_plantain":1},"gold":0,"min_level":1,"require_stock":false},
	{"id":"field_edge_pill","station":"medicine","output":"field_edge_pill","count":1,"ingredients":{"field_herb_licorice":1,"field_herb_danshen":1},"gold":0,"min_level":1,"require_stock":false},
	{"id":"field_focus_pill","station":"medicine","output":"field_focus_pill","count":1,"ingredients":{"field_herb_mint":1,"field_herb_danshen":1},"gold":0,"min_level":1,"require_stock":false},
	{"id":"field_guard_powder","station":"medicine","output":"field_guard_powder","count":1,"ingredients":{"field_herb_perilla":1,"field_herb_mugwort":1},"gold":0,"min_level":1,"require_stock":false},
	{"id":"field_breath_pill","station":"medicine","output":"field_breath_pill","count":1,"ingredients":{"field_herb_mint":1,"field_herb_astragalus":1},"gold":0,"min_level":1,"require_stock":false},
	{"id":"healing_pill_minor","station":"medicine","output":"healing_pill_minor","count":1,"ingredients":{"herb_bundle":2},"gold":0,"min_level":1,"require_stock":false},
	{"id":"inner_breath_pill","station":"medicine","output":"inner_breath_pill","count":1,"ingredients":{"herb_bundle":3},"gold":0,"min_level":1,"require_stock":false},
	{"id":"antidote_pill","station":"medicine","output":"antidote_pill","count":1,"ingredients":{"herb_bundle":4},"gold":0,"min_level":1,"require_stock":false},
	{"id":"field_healing_blend","station":"medicine","output":"healing_pill_minor","count":1,"ingredients":{"field_herb_peony":1,"field_herb_mugwort":1},"gold":0,"min_level":1,"require_stock":false},
	{"id":"field_antidote_blend","station":"medicine","output":"antidote_pill","count":1,"ingredients":{"field_herb_honeysuckle":1,"field_herb_plantain":1},"gold":0,"min_level":1,"require_stock":false},
	# These three basic crafts are common smith services, including iron knuckles
	# (existing uncommon quality), not an expansion of any shop's sale stock.
	{"id":"iron_sword","station":"blacksmith","output":"iron_sword","count":1,"ingredients":{"iron_ore":6},"gold":20,"min_level":1,"require_stock":false},
	{"id":"iron_helmet","station":"blacksmith","output":"iron_helmet","count":1,"ingredients":{"iron_ore":3},"gold":12,"min_level":1,"require_stock":false},
	{"id":"iron_knuckles","station":"blacksmith","output":"iron_knuckles","count":1,"ingredients":{"iron_ore":4},"gold":18,"min_level":1,"require_stock":false},
	# Existing rare equipment: chapter/level and the actual smith stock both gate it.
	{"id":"iron_staff","station":"blacksmith","output":"iron_staff","count":1,"ingredients":{"iron_ore":10},"gold":50,"min_level":5,"require_stock":true},
	{"id":"iron_great_blade","station":"blacksmith","output":"iron_great_blade","count":1,"ingredients":{"iron_ore":12},"gold":55,"min_level":5,"require_stock":true},
	{"id":"iron_mail","station":"blacksmith","output":"iron_mail","count":1,"ingredients":{"iron_ore":8},"gold":32,"min_level":5,"require_stock":true},
]

static func for_station(station: String, stock: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in DATA:
		if String(row.station) != station:
			continue
		if bool(row.require_stock) and not stock_has(stock, String(row.output)):
			continue
		result.append(row.duplicate(true))
	return result

static func find(id: String) -> Dictionary:
	for row: Dictionary in DATA:
		if String(row.id) == id:
			return row.duplicate(true)
	return {}

static func stock_has(stock: Array, output: String) -> bool:
	# ShopDef.stock is Array[StringName]; String is accepted for value-only UI/QA.
	# No dictionary aliases, broad shop categories, or guessed vendor identities.
	for entry: Variant in stock:
		if (entry is String or entry is StringName) and String(entry) == output:
			return true
	return false
