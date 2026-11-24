shader_type canvas_item;
render_mode unshaded;
uniform vec2 path_points[64];
uniform int path_count = 0;
uniform float half_width = 42.0;
varying vec2 ground_point;
varying vec4 source_tint;
void vertex(){ground_point=VERTEX;source_tint=COLOR;}
void fragment(){
    float nearest=100000.0;
    for(int i=0;i<63;i++){
        if(i>=path_count-1){break;}
        vec2 a=path_points[i];vec2 b=path_points[i+1];vec2 edge=b-a;
        float t=clamp(dot(ground_point-a,edge)/max(dot(edge,edge),0.001),0.0,1.0);
        nearest=min(nearest,length(ground_point-(a+edge*t)));
    }
    vec4 soil=texture(TEXTURE,UV);
    float alpha=1.0-smoothstep(max(half_width-16.0,0.0),half_width,nearest);
    COLOR=vec4(soil.rgb,soil.a*alpha)*source_tint;
}
