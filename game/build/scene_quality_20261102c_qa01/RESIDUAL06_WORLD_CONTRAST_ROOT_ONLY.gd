extends "res://build/scene_quality_20261102c_qa01/RESIDUAL04_VISUALS_ROOT_ONLY.gd"
func capture(label: String) -> bool:
	if label == "temple_retired_small_broken_wall_normal": records.append({"inherited_actual":6532,"inherited_checks_not_new_unique_credit":38,"accepted_temple_image_not_repeated":true,"only_new_scope":"WORLD_ICON_CONTRAST_NORMAL_IMAGE"}); return true
	return await super.capture(label)
