extends RefCounted

const ART = "res://art/characters/legendary_weapons_20261108/"
const SOURCES = {
	"yuanming_sword": "3c1cf451dd14cda62539020e28704f915a7294860b4b0b42ecc029473c7915a8",
	"tiger_roar_blade": "1b22a35325bf8a9bd10b8eaee99cbcf4ff439933022116e88efe700cad329bab",
	"buddha_subduing_staff": "d19c157a3f64bebb692d39f2f31d1de7f8f2efc5f3cec122a6afeff16fffe050",
	"heaven_piercing_staff": "55b34e7e9d887a538514787c274cc6c028548272c9576815403730787a4dac95",
	"golden_hoop_staff": "0b725a823f35f3fb35cddf142a4d91335843ef9c621809aad895349db5353df9",
	"immortal_gauntlets": "6d245935460e67cd0099764fd4047c38c71829f787faafa2c7ce56272d2e165f",
	"zhouju_bronze_sword": "428b97fbe22639e505a987236775f19e5626e62c40adb6831d9cf79b871bca94",
	"suwusheng_teapot": "f0e8dd7f8f256b60e71cb66c6b39ddba661bffa999ed843c87f36d53d48aeb32",
}

# Art coordinates are local to the indicated cell, including the weapon
# contact, the luminous span and the attachment of its closed scabbard.
const PROPS = {
	"yuanming_sword": {
		"atlas": "yuanming_sword", "region": Rect2(0,0,768,1024),
		"grip": Vector2(491,816), "scale": 0.39, "tip": Vector2(491,32), "heel": Vector2(491,726),
	},
	"yuanming_sheath": {
		"atlas": "yuanming_sword", "region": Rect2(768,0,768,1024),
		"grip": Vector2(275,784), "scale": 0.44, "tip": Vector2(274,30), "heel": Vector2(275,730),
	},
	"tiger_roar_blade": {
		"atlas": "tiger_roar_blade", "region": Rect2(0,0,768,1024),
		"grip": Vector2(400,738), "scale": 0.43, "tip": Vector2(478,20), "heel": Vector2(399,575),
	},
	"tiger_sheath": {
		"atlas": "tiger_roar_blade", "region": Rect2(768,0,768,1024),
		"grip": Vector2(318,662), "scale": 0.43, "tip": Vector2(420,19), "heel": Vector2(317,591),
	},
	"buddha_subduing_staff": {
		"atlas": "buddha_subduing_staff", "region": Rect2(0,0,1024,1536),
		"grip": Vector2(511,934), "scale": 0.235, "tip": Vector2(511,120), "heel": Vector2(511,567),
		"back_center": Vector2(511,768),
	},
	"heaven_piercing_staff": {
		"atlas": "heaven_piercing_staff", "region": Rect2(0,0,1024,1536),
		"grip": Vector2(512,682), "scale": 0.39, "tip": Vector2(512,65), "heel": Vector2(512,1465),
		"back_center": Vector2(512,765),
	},
	"golden_hoop_staff": {
		"atlas": "golden_hoop_staff", "region": Rect2(0,0,1024,1536),
		"grip": Vector2(512,811), "scale": 0.40, "tip": Vector2(512,65), "heel": Vector2(512,1470),
		"back_center": Vector2(512,768),
	},
	"zhouju_bronze_sword": {
		"atlas": "zhouju_bronze_sword", "region": Rect2(0,0,768,1024),
		"grip": Vector2(456,767), "scale": 0.34, "tip": Vector2(456,19), "heel": Vector2(456,696),
	},
	"zhouju_sheath": {
		"atlas": "zhouju_bronze_sword", "region": Rect2(768,0,768,1024),
		"grip": Vector2(311,767), "scale": 0.35, "tip": Vector2(311,18), "heel": Vector2(311,698),
	},
	"suwusheng_teapot": {
		"atlas": "suwusheng_teapot", "region": Rect2(0,0,1254,1254),
		"grip": Vector2(138,510), "scale": 0.105, "tip": Vector2(1170,365), "heel": Vector2(1085,405),
	},
}

const WEAPONS = {
	"jinhe_duanyue_blade": {
		"sheath": "jinhe_sheath", "ready_angle": 22.0, "heavy": true,
		"tint": Color(1.0,0.35,0.12), "glow_end": 0.59, "intensity": 1.7,
		"speed": 1.47, "spread": 1.48, "size": 1.10, "aspect": Vector2(0.60,1.26),
		"drawn_tip": Vector2(571,8), "drawn_heel": Vector2(490,875),
	},
	"yuanming_sword": {
		"sheath": "yuanming_sheath", "ready_angle": 25.0, "heavy": false,
		"tint": Color(0.70,0.43,1.0), "glow_end": 0.72,
		"speed": 0.72, "spread": 0.93, "size": 0.85, "aspect": Vector2(0.9,1.1),
	},
	"tiger_roar_blade": {
		"sheath": "tiger_sheath", "ready_angle": 23.0, "heavy": true,
		"tint": Color(1.0,0.56,0.20), "glow_end": 0.58,
		"speed": 1.38, "spread": 1.28, "size": 0.72, "aspect": Vector2(0.44,1.55),
	},
	"buddha_subduing_staff": {
		"sheath": "", "ready_angle": 19.0, "heavy": true, "back": true,
		"tint": Color(1.0,0.83,0.35), "glow_end": 0.47,
		"speed": 0.65, "spread": 2.15, "size": 1.19, "aspect": Vector2(1.0,1.0),
	},
	"heaven_piercing_staff": {
		"sheath": "", "ready_angle": 16.0, "heavy": true, "paired_tips": true, "back": true,
		"tint": Color(1.0,0.28,0.27), "speed": 1.23, "spread": 0.80, "size": 0.86,
		"aspect": Vector2(0.65,1.42),
	},
	"golden_hoop_staff": {
		"sheath": "", "ready_angle": 23.0, "heavy": true, "paired_tips": true, "back": true,
		"tint": Color(0.47,0.90,0.88), "speed": 0.82, "spread": 1.53, "size": 0.93,
		"aspect": Vector2(1.23,0.84),
	},
	"zhouju_bronze_sword": {
		"sheath": "zhouju_sheath", "ready_angle": 23.0, "heavy": false,
		"tint": Color(0.87,0.90,0.48), "glow_end": 0.69,
		"speed": 0.66, "spread": 1.32, "size": 0.80, "aspect": Vector2(0.9,1.0),
	},
	"suwusheng_teapot": {
		"sheath": "", "concealed": true, "heavy": false,
		"tint": Color(0.78,0.46,0.93), "glow_end": 0.46,
		"speed": 1.65, "spread": 2.0, "size": 2.2, "aspect": Vector2(1.0,0.82),
	},
}

static func sheath_for(weapon_id: String) -> String:
	if weapon_id=="seven_star_sword":
		return "seven_star_sheath"
	return WEAPONS.get(weapon_id,{}).get("sheath","")
