extends RefCounted

const SHEETS := {
	"system": preload("res://art/ui/menu_buttons_20261109/system.png"),
	"hud": preload("res://art/ui/menu_buttons_20261109/hud.png"),
	"compact": preload("res://art/ui/menu_buttons_20261109/compact.png"),
	"action": preload("res://art/ui/menu_buttons_20261109/action.png"),
}

# The four original cells are normal, hover, pressed, and disabled.
const REGIONS := {
	"system": [Rect2(73, 264, 877, 204), Rect2(73, 550, 877, 204), Rect2(73, 837, 877, 204), Rect2(73, 1124, 877, 204)],
	"hud": [Rect2(200, 53, 1136, 204), Rect2(200, 295, 1136, 204), Rect2(200, 535, 1136, 204), Rect2(200, 774, 1136, 204)],
	"compact": [Rect2(420, 47, 695, 208), Rect2(420, 280, 695, 208), Rect2(420, 516, 695, 208), Rect2(420, 754, 695, 208)],
	"action": [Rect2(37, 394, 450, 314), Rect2(538, 394, 450, 314), Rect2(37, 830, 450, 314), Rect2(538, 830, 450, 314)],
}
