shader_type canvas_item;
// Original grass pixels/UV/alpha/size remain; only chroma is restrained.
uniform float ap_grass_saturation = 0.58;
void fragment() {
    float luminance = dot(COLOR.rgb,vec3(0.2126,0.7152,0.0722));
    COLOR.rgb = mix(vec3(luminance),COLOR.rgb,clamp(ap_grass_saturation,0.0,1.0));
}
