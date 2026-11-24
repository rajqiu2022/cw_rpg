extends "res://scripts/drafts/redrock_desert_complete_20261028d/town_controller.gd"

func update_view() -> void:
	super.update_view()
	$UI/Status.text = "折返阶街通关镇　｜　取水、驮运与石作分院"

func examine() -> void:
	if not in_hall:
		for item in $Town.get_children():
			if item.has_meta("life_portrait") and actor.global_position.distance_to(item.global_position)<155.0:
				$UI/Detail/Portrait.texture=load(ART_ROOT+str(item.get_meta("life_portrait"))+".png")
				$UI/Detail/Portrait.visible=true
				$UI/Detail/Text.text=str(item.get_meta("label"))+"\n\nEsc关闭后继续行走。"
				show_details=true
				return
	super.examine()
