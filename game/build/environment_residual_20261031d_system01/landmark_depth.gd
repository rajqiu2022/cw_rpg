extends RefCounted
## Match the actual ActorLayer's inherited world depth, not a root-canvas z.
const REFINEMENT=preload("res://build/world_landmarks_20261031c/refinement.gd")

static func align(sprite: Sprite2D,actor_layer: Node2D) -> void:
	# This repair is only the newly adopted Lanxi compound. Other two landmarks,
	# world geometry, portals, visual feet, actor material and texture stay intact.
	if sprite.texture!=REFINEMENT.texture(REFINEMENT.LANDMARK):return
	if not is_instance_valid(actor_layer):return
	# Both parents are direct descendants of WorldContainer. The original actor
	# branch additionally inherits ActorLayer.z (20); the compound must inherit
	# the same branch offset as well as WorldContainer.z (-100 in the live field).
	sprite.z_as_relative=true
	sprite.z_index+=actor_layer.z_index
	sprite.set_meta("world31d_depth_alignment",{"actor_layer_z":actor_layer.z_index,"sort_foot_preserved":5920,"inherits_world_canvas":true})
