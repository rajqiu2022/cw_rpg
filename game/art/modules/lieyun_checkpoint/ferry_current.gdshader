shader_type canvas_item;
render_mode unshaded;

uniform sampler2D water_tex : source_color, repeat_enable, filter_linear;
uniform sampler2D bed_tex : source_color, repeat_enable, filter_linear;
uniform bool bridge_current = false;
uniform vec2 bridge_y = vec2(0.);
uniform float texture_span = 750.;
varying vec2 world;
varying float channel_width;

void vertex() {
	world = VERTEX;
	channel_width = COLOR.r * 1600.0;
}

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.,0.)), f.x),
	           mix(hash(cell + vec2(0.,1.)), hash(cell + vec2(1.)), f.x), f.y);
}

// Elliptical shingle lies in small bars. Light catches the upstream face of each stone.
vec3 pebbles(vec2 p, vec3 base, float coverage) {
	vec2 cell = floor(p);
	float seed = hash(cell);
	vec2 center = .5 + .24 * (vec2(hash(cell + 3.1),hash(cell - 6.2)) - .5);
	vec2 d = (fract(p) - center) / (.16 + .24 * seed);
	d.x += .33 * d.y * (seed - .35);
	float r = length(d);
	float shape = (1. - smoothstep(.76,1.,r)) * smoothstep(.25,.82,coverage + .35 * seed);
	float bevel = .55 - .29 * dot(d,vec2(.48,.88)) + .16 * (1. - r*r);
	return mix(base, mix(vec3(.33,.32,.25),vec3(.66,.65,.54),seed) * bevel,shape);
}

// Short, discontinuous foam ribbons below a constriction. Each patch is advected
// at the local speed and crossfaded before a velocity gradient can stretch it.
float whitewater(vec2 p) {
	float streak = noise(p / vec2(14.,61.)) + .17 * noise(p / vec2(7.,18.));
	float breaks = noise(p / vec2(41.,35.));
	return smoothstep(.60,.85,streak) * smoothstep(.38,.72,breaks);
}

void fragment() {
	float across = UV.x, along = UV.y * 512.0;
	float rim = min(across, 1.0 - across) * channel_width;
	float shore = rim + 7.0 * (noise(world / 15.0) - 0.5);
	float shallow = 1.0 - smoothstep(0.0, 87.0 + 30.0 * noise(world / 90.0), shore);
	vec3 gravel = texture(bed_tex, world / 280.0).rgb;
	float grain = dot(gravel, vec3(.29,.52,.19));
	float bars = noise(world / vec2(42., 85.));
	vec3 shingle = mix(vec3(.20,.18,.14), vec3(.59,.57,.48), grain);
	shingle *= .76 + .44 * bars;
	shingle = pebbles(world / vec2(8.,5.5), shingle, bars);
	shingle = pebbles((world + 13.*noise(world/76.)) / vec2(20.,12.), shingle, smoothstep(.45,.84,bars));
	// Surface detail travels in channel coordinates, while the submerged bed stays still.
	float speed = mix(19., 68., smoothstep(0., 150., rim));
	vec2 stream = vec2(across * texture_span, along);
	float throat = 0.;
	float midstream = smoothstep(0.,.33,min(across,1.-across));
	if (bridge_current) {
		vec2 distances = abs(vec2(world.y - 35.) - bridge_y);
		throat = 1. - smoothstep(25.,205.,min(distances.x,distances.y));
		speed = mix(12., 48. + 64. * throat, midstream);
	}
	vec2 warp = vec2(noise(stream / 103.), noise(stream / 84. + 12.)) * 18.;
	// Two alternating patches allow local velocities without indefinitely shearing the texture.
	float cycle = fract(TIME * .24), other = fract(cycle + .5);
	vec2 surface = (stream + warp - vec2(0., TIME * 43.)) / vec2(290.,380.);
	vec2 excursion = vec2(0., (speed - 43.) / (.24 * 380.));
	vec3 ripples = mix(texture(water_tex,surface - cycle * excursion).rgb,
	                   texture(water_tex,surface - other * excursion).rgb, abs(2. * cycle - 1.));
	float light = dot(ripples, vec3(.25,.55,.20));
	vec3 water = mix(vec3(.135,.237,.234), vec3(.36,.49,.45), light);
	water += (light - .46) * .29;
	water = mix(water, shingle * vec3(.79,.96,.87), shallow * .80);
	// Broken crests drift around the bend; an independent train breaks up the reflections.
	vec2 drift = vec2(stream.x, along - TIME * 57.);
	float lanes = noise(drift / vec2(24.,105.));
	float phase = drift.y * .083 + 8. * noise(drift / vec2(62.,110.)) + 1.9 * sin(drift.x * .043);
	float crests = smoothstep(.72,.98,cos(phase)) * smoothstep(.46,.79,lanes);
	float glint = smoothstep(.74,.94, noise((stream - vec2(0., TIME * 36.)) / vec2(17.,6.)));
	if (bridge_current) {
		vec2 a = stream + warp - vec2(0., (TIME * 43.) + cycle * (speed - 43.) / .24);
		vec2 b = stream + warp - vec2(0., (TIME * 43.) + other * (speed - 43.) / .24);
		float foam = mix(whitewater(a),whitewater(b),abs(2. * cycle - 1.));
		crests = foam * midstream * (.5 + 1.75 * throat);
		glint *= midstream * .35;
	}
	water += vec3(.23,.25,.21) * (crests * (.30 + .70 * light) + glint * .33) * smoothstep(1.,24.,shore);
	float wash = 1.0 - smoothstep(1., 6., abs(shore - 4. - 2. * sin(TIME * 1.6 + along * .039)));
	water += vec3(.14,.15,.12) * wash * bars;
	vec3 land = shingle * mix(.71,1.12,smoothstep(1.,34.,-shore));
	float apron = 19. + 32. * bars + 10. * noise(world / 12.);
	COLOR = vec4(mix(land, water, smoothstep(-1.,1.5,shore)), smoothstep(-apron,-apron * .46,shore));
}
