extends RefCounted

const ROOT := "res://art/modules/gathering_herbs_20261114/"
const SPECIES := {
	"licorice": [195, 357, 0.145],
	"mint": [199, 355, 0.125],
	"peony": [198, 353, 0.15],
	"mugwort": [199, 356, 0.133],
	"honeysuckle": [207, 343, 0.131],
	"dandelion": [197, 352, 0.119],
	"astragalus": [191, 358, 0.147],
	"perilla": [196, 357, 0.146],
	"danshen": [191, 354, 0.145],
	"plantain": [203, 343, 0.116],
}
const BY_SITE := {
	"life_road_herb_01": "peony",
	"life_road_herb_02": "licorice",
	"life_forest_herb_01": "mugwort",
	"life_forest_herb_02": "mint",
	"life_mine_herb_01": "astragalus",
	"life_marsh_herb_01": "plantain",
	"life_marsh_herb_02": "honeysuckle",
	"life_marsh_herb_03": "dandelion",
	"adventure_forest_herb_01": "perilla",
	"adventure_forest_herb_02": "danshen",
	"adventure_forest_herb_03": "mint",
	"adventure_forest_herb_04": "mugwort",
}

static func apply_species(site: Dictionary) -> void:
	var species: String = BY_SITE.get(site.get("id"), "")
	if site.get("type") != "herb" or not SPECIES.has(species):
		return
	var art: Array = SPECIES[species]
	site["item_id"] = "field_herb_" + species
	site["texture"] = ROOT + species + ".tres"
	site["source_foot"] = [art[0], art[1]]
	site["scale"] = art[2]

static func is_material(id: String) -> bool:
	return id.begins_with("field_herb_") and SPECIES.has(id.trim_prefix("field_herb_"))
