extends RefCounted
const Legendary = preload("res://scripts/appearance/legendary_weapon_data.gd")

const ATLAS_PATH = "res://art/characters/layered_actor_adoption_20261106/weapon_carry_atlas.png"
const ATLAS_SHA = "5d821c8cf9f87524118c68a5fe07af9a0e90c69f113b0a6555fe4f8b8a8f2c79"
const SHEATHS_PATH = "res://art/characters/layered_actor_adoption_20261106/field_sheaths.png"
const SHEATHS_SHA = "8100799af9e702823e310413e0cc559caf9af19e1373467c5b570cf9526292e4"
const PROPS = {
	"plain_sword": {"region": Rect2(0, 0, 444, 887), "grip": Vector2(224, 700), "scale": 0.44},
	"plain_blade": {"region": Rect2(444, 0, 443, 887), "grip": Vector2(220, 700), "scale": 0.44},
	"plain_staff": {"region": Rect2(887, 0, 444, 887), "grip": Vector2(222, 438), "scale": 0.69},
	"seven_star_sheath": {
		"region": Rect2(1331, 0, 443, 887), "grip": Vector2(222, 674), "scale": 0.49,
		"tip": Vector2(221, 10), "heel": Vector2(222, 645),
	},
	"plain_sword_sheath": {
		"atlas": "field_sheaths", "region": Rect2(0,0,512,1024), "grip": Vector2(322,729), "scale": 0.36,
	},
	"plain_blade_sheath": {
		"atlas": "field_sheaths", "region": Rect2(512,0,512,1024), "grip": Vector2(246,722), "scale": 0.36,
	},
	"jinhe_sheath": {
		"atlas": "field_sheaths", "region": Rect2(1024,0,512,1024), "grip": Vector2(164,550), "scale": 0.39,
		"tip": Vector2(200,16), "heel": Vector2(166,552),
	},
}
# Image coordinates at the belt, projected scabbard angle, then draw depth.
const WAIST = {
	"side": [Vector2(246, 333), -133.0, 2],
	"down": [Vector2(304, 344), 131.0, 2],
	"up": [Vector2(198, 319), -168.0, 0],
}

# Source pixel where the front-facing view begins showing the handle.
const FRONT_HILT_CUT = {
	"plain_sword_sheath": 744.0,
	"plain_blade_sheath": 735.0,
	"seven_star_sheath": 665.0,
	"jinhe_sheath": 642.0,
	"yuanming_sheath": 747.0,
	"tiger_sheath": 617.0,
	"zhouju_sheath": 721.0,
}

# The diagonal across the back projects edge-on in profile. Keep the side
# mount close to the spine and let the body cover it.
const BACK = {
	"side": [Vector2(229, 336), 0.0, 0],
	"down": [Vector2(251, 305), 33.0, 0],
	"up": [Vector2(258, 307), -33.0, 2],
}

static func sheath_for(id: String) -> String:
	match id:
		"plain_sword": return "plain_sword_sheath"
		"plain_blade": return "plain_blade_sheath"
		_: return Legendary.sheath_for(id)

static func carries_on_back(id: String) -> bool:
	return id=="plain_staff" or Legendary.WEAPONS.get(id,{}).get("back",false)

# Right-hand skin outlines and upper-wrap contacts for the four combat-ready
# cells. The left pose mirrors the same contact and original fingers.
const READY_SWORD_GRIPS = [
	{"web": Vector2(308, 356), "fingers": [290,352, 304,353, 314,357, 319,362, 321,371, 319,381, 312,390, 301,392, 291,390, 284,383, 279,373, 279,362, 283,356]},
	{"web": Vector2(308, 348), "fingers": [290,344, 302,345, 313,349, 318,354, 321,362, 319,373, 313,380, 302,385, 291,384, 284,378, 279,370, 278,357, 282,351]},
	{"web": Vector2(308, 344), "fingers": [290,340, 302,341, 312,345, 318,350, 321,358, 320,368, 314,376, 305,381, 294,381, 285,375, 280,367, 279,354, 282,348]},
	{"web": Vector2(309, 356), "fingers": [290,352, 305,353, 315,357, 320,363, 322,371, 319,381, 313,390, 302,392, 291,390, 284,384, 280,374, 279,363, 284,356]},
]

# The near sleeve and bracer, traced on the original side-facing cells. Keep
# their pixels in front of the sheath without lifting the torso above it.
const ARM_COVER = {
	"idle": [
		[210,225, 299,225, 307,268, 303,286, 309,310, 323,343, 326,371, 317,395, 287,397, 272,365, 257,339, 238,319, 233,311, 215,298, 207,274],
		[210,222, 298,222, 307,266, 303,281, 308,305, 324,341, 327,368, 317,390, 287,392, 272,361, 254,332, 236,311, 230,305, 214,292, 206,270],
		[211,221, 300,221, 308,264, 302,278, 309,300, 325,335, 328,365, 320,389, 291,391, 274,357, 255,329, 237,308, 230,301, 215,288, 207,266],
		[211,225, 301,225, 309,269, 305,286, 312,311, 326,344, 328,374, 319,396, 288,398, 273,366, 258,339, 239,320, 233,311, 215,297, 207,275],
	],
	"walk": [
		[237,228, 294,228, 304,276, 319,302, 348,333, 382,349, 385,380, 354,390, 331,369, 297,340, 272,322, 255,311, 240,293, 235,266],
		[208,225, 264,225, 271,270, 271,285, 282,322, 311,353, 315,381, 309,400, 280,405, 264,375, 244,346, 229,316, 218,298, 207,278],
		[233,224, 290,224, 307,273, 322,293, 359,322, 392,341, 398,366, 366,384, 341,362, 308,337, 285,322, 261,310, 242,293, 232,265],
		[220,224, 275,224, 282,269, 294,291, 310,320, 344,347, 361,367, 351,391, 324,395, 306,369, 278,343, 262,320, 240,308, 225,288],
	],
	"walk_mid_clean": [
		[237,226, 292,226, 313,265, 324,288, 347,313, 385,331, 406,346, 400,368, 370,380, 350,359, 314,335, 286,320, 263,308, 246,287, 237,259],
		[236,224, 290,224, 312,264, 322,286, 345,310, 384,326, 405,344, 398,367, 368,377, 347,356, 311,331, 285,316, 261,305, 245,284, 235,256],
		[222,225, 278,225, 299,266, 310,293, 333,317, 374,340, 392,352, 389,374, 357,389, 339,369, 305,346, 278,331, 251,316, 232,297, 223,264],
		[232,224, 287,224, 310,265, 320,286, 343,310, 381,328, 402,345, 396,368, 367,376, 347,357, 311,332, 284,317, 260,306, 242,286, 231,259],
	],
}

static func equipment_appearance(equipment: Equipment, fallback_style: StringName) -> String:
	if equipment == null:
		return "unarmed"
	var id := String(equipment.item_id)
	if id in ["seven_star_sword", "jinhe_duanyue_blade"] or Legendary.WEAPONS.has(id):
		return id
	var style := Equipment.normalize_weapon_type(equipment.weapon_type)
	if style == &"":
		style = Equipment.normalize_weapon_type(fallback_style)
	if style==&"palm" and equipment.quality==Item.Quality.LEGENDARY:
		return "immortal_gauntlets"
	match style:
		&"sword": return "plain_sword"
		&"blade": return "plain_blade"
		&"staff": return "plain_staff"
		_: return "unarmed"
