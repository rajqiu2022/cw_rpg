extends Node2D

const Particles = preload("res://scripts/appearance/seven_star_particles.gd")
const GOLD := Color(1.0, 0.70, 0.30)
const MOTES_PER_HAND := 7
const FAR_HANDS = {
	"idle": [Vector2(338,391),Vector2(336,387),Vector2(336,385),Vector2(339,392)],
	"walk": [Vector2(194,375),Vector2(376,364),Vector2(186,379),Vector2(215,339)],
	"walk_mid_clean": [Vector2(182,383),Vector2(184,374),Vector2(191,377),Vector2(182,374)],
	"idle_down": [Vector2(353,392),Vector2(354,391),Vector2(354,387),Vector2(353,395)],
	"walk_down": [Vector2(380,381),Vector2(366,358),Vector2(355,350),Vector2(380,387)],
	"walk_down_mid": [Vector2(378,382),Vector2(362,358),Vector2(358,351),Vector2(380,387)],
	"idle_up": [Vector2(169,382),Vector2(168,382),Vector2(170,380),Vector2(169,383)],
	"walk_up": [Vector2(149,339),Vector2(149,378),Vector2(140,379),Vector2(141,380)],
	"walk_up_mid": [Vector2(150,353),Vector2(132,380),Vector2(137,385),Vector2(134,386)],
	"attack": [Vector2(337,393),Vector2(348,388),Vector2(183,381),Vector2(344,392)],
	"hit": [Vector2(-1,-1),Vector2(-1,-1),Vector2(-1,-1),Vector2(-1,-1)],
	"defeat_v3": [Vector2(380,396),Vector2(376,436),Vector2(408,670),Vector2(-1,-1)],
}

var hand_sprites: Array[Sprite2D] = []
var emitters: Array[Node2D] = []

func setup(textures: Dictionary) -> void:
	# Keep diffuse glow behind the silhouette, but keep the small sparks visible
	# over the hands. Otherwise a wrist over the torso hides the entire effect.
	z_index = 0
	var ring := _make_ring()
	for i in range(2):
		var halo := Sprite2D.new()
		halo.texture = ring
		add_child(halo)
		hand_sprites.append(halo)

		var sparks := Particles.new()
		sparks.z_index = 6
		add_child(sparks)
		sparks.setup(textures.starfx, MOTES_PER_HAND, 0)
		emitters.append(sparks)

func _make_ring() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.39, 0.54, 0.69, 1.0])
	gradient.colors = PackedColorArray([
		Color(GOLD, 0.16), Color(GOLD, 0.07), Color(GOLD, 0.80),
		Color(GOLD, 0.35), Color(GOLD, 0.0),
	])
	var ring := GradientTexture2D.new()
	ring.gradient = gradient
	ring.width = 126
	ring.height = 132
	ring.fill = GradientTexture2D.FILL_RADIAL
	ring.fill_from = Vector2(0.5, 0.5)
	ring.fill_to = Vector2(1.0, 0.5)
	return ring

func show_hands(pose: Dictionary, foot: Vector2, seconds: float) -> void:
	var cell := int(pose.cell_index)
	var sheet: String = pose.texture
	var near := Vector2(pose.hand_center[0], pose.hand_center[1])
	var far: Vector2 = pose.get("far_hand", Vector2(-1,-1))
	if not pose.has("far_hand"):
		far = Vector2(350,383) if sheet=="victory" else FAR_HANDS.get(sheet,[Vector2(-1,-1),Vector2(-1,-1),Vector2(-1,-1),Vector2(-1,-1)])[cell]
	for i in range(2):
		var center := near if i == 0 else far
		var halo := hand_sprites[i]
		var sparks := emitters[i]
		var present := center.x >= 0
		halo.visible = present
		sparks.visible = present
		if not present:
			continue
		var clock := seconds + i * 0.31
		halo.position = center - foot
		halo.modulate.a = 0.78 + sin(clock * 3.4) * 0.16
		sparks.position = halo.position
		_draw_orbit(sparks, clock)

func _draw_orbit(sparks: Node2D, clock: float) -> void:
	for i in MOTES_PER_HAND:
		var mote: Sprite2D = sparks.motes[i]
		var seed := float(i) / MOTES_PER_HAND
		var age := fposmod(clock * (0.55 + 0.31 * seed) + seed, 1.0)
		var angle := seed * TAU + clock * (1.1 + 0.52 * seed)
		var radius := lerpf(20.0, 53.0, age)
		var opacity := smoothstep(0.02, 0.16, age) * (1.0 - smoothstep(0.42, 1.0, age))
		mote.position = Vector2.from_angle(angle) * radius * Vector2(1.0, 1.12)
		mote.scale = Vector2.ONE * lerpf(0.125, 0.067, age)
		mote.rotation = angle * 0.28
		mote.modulate = Color(GOLD.lerp(Color.WHITE, 0.32), opacity * 0.96)
