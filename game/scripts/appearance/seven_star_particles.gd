extends Node2D
## Reuse the painted star texture in a fixed pool. Sampling by time lets the
## combat afterimage freeze exactly the same particles as the current pose.

const STREAM_COUNT := 10
const DRIFT_COUNT := 12
const BLADE_MOTES := 6
const DRAWN_BLADE_MOTES := 12
var motes: Array[Sprite2D] = []
var stream_count := STREAM_COUNT

func setup(star_strip: Texture2D, streams := STREAM_COUNT, drifts := DRIFT_COUNT) -> void:
	var star := AtlasTexture.new()
	star.atlas = star_strip
	star.region = Rect2(1202, 207, 310, 310)
	star.filter_clip = true
	stream_count=streams
	for i in range(streams + drifts):
		var mote := Sprite2D.new()
		mote.texture = star
		add_child(mote)
		motes.append(mote)

func draw_at(seconds: float, tip: Vector2, heel: Vector2, sheathed: bool, profile: Dictionary={}, soft_blade := false, compact := false) -> void:
	var speed := float(profile.get("speed",1.0))
	var spread := float(profile.get("spread",1.0))
	var size_factor := float(profile.get("size",1.0))
	var aspect: Vector2 = profile.get("aspect",Vector2.ONE)
	var tint: Color = profile.get("tint",Color(0.69,0.91,1.0))
	var paired_tips: bool = profile.get("paired_tips",false)
	var blade_mote_count := BLADE_MOTES if sheathed else DRAWN_BLADE_MOTES
	for i in range(motes.size()):
		var mote := motes[i]
		mote.visible = i < 4 if compact else (not soft_blade or i < blade_mote_count)
		if not mote.visible:
			continue
		var drifting := i >= stream_count
		var seed := fmod(float(i) * 0.61803398875, 1.0)
		var life := lerpf(0.56, 1.19, seed) if drifting else lerpf(0.86, 1.42, seed)
		var age := fposmod(seconds * speed / life + seed, 1.0)
		var fade := smoothstep(0.0, 0.16, age) * (1.0 - smoothstep(0.46, 1.0, age))
		if compact:
			var position_on_weapon := lerpf(0.13, 0.95, age) if sheathed else lerpf(0.87, 1.0, age)
			if not sheathed and paired_tips and i % 2 == 0:
				position_on_weapon=1.0-position_on_weapon
			mote.position=heel.lerp(tip,position_on_weapon)+Vector2(sin(age*TAU+i*2.4)*27.0,0.0)
			mote.scale=aspect*lerpf(0.17,0.24,seed)*size_factor
			mote.rotation=(seed-age)*0.75
			mote.modulate=Color(tint.lerp(Color.WHITE,0.25),fade*0.94)
			continue
		if soft_blade:
			var along := (float(i) + age) / float(blade_mote_count)
			var offset := sin(age * TAU + i * 2.4) * (42.0 if sheathed else 24.0)
			mote.position = heel.lerp(tip, along) + Vector2(offset, 0.0)
			mote.scale = aspect * lerpf(0.035, 0.065, seed) * size_factor * (4.3 if sheathed else 2.15)
			mote.rotation = (seed - age) * 0.75
			mote.modulate = Color(tint.lerp(Color.WHITE,0.25), fade * (0.95 if sheathed else 0.90))
			continue
		var start := lerpf(0.12, 0.90, seed) if drifting else lerpf(0.03, 0.29, seed)
		var travel := minf(0.99, start + age * (0.17 if drifting else 0.70))
		if paired_tips:
			travel=lerpf(0.64,0.98,travel) if i%2==0 else lerpf(0.36,0.02,travel)
		var radius := 11.0 if sheathed else 21.0
		var lateral := sin(age * TAU * 1.2 + i * 2.4) * radius
		if drifting:
			var side := -1.0 if i % 2 == 0 else 1.0
			lateral += side * age * lerpf(110.0, 215.0, seed)
		mote.position = heel.lerp(tip, travel) + Vector2(lateral * spread, 0.0)
		var size := lerpf(0.17, 0.29, seed) if drifting else lerpf(0.30, 0.53, seed)
		mote.scale = aspect * size * size_factor * (0.90 if sheathed else 1.14)
		mote.rotation = (seed - age) * 0.75
		mote.modulate = Color(tint.r,tint.g,tint.b,fade * (0.87 if sheathed else 1.0))
