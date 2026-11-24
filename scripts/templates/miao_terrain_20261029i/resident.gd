extends "res://scripts/drafts/miao_town_20261029f/resident.gd"
var floor_level := 0
var elevation := 0.0

func show_frame() -> void:
	super.show_frame()
	art.position.y-=elevation
