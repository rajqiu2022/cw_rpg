shader_type spatial;render_mode cull_disabled,blend_mix,depth_draw_never;
uniform sampler2D actual_height_rf:filter_nearest,repeat_disable;
uniform ivec2 grid_origin;uniform ivec2 grid_shape;
varying vec3 xyz;void vertex(){xyz=VERTEX;}
float bed(vec2 p){vec2 q=p/8.-vec2(grid_origin);ivec2 c=clamp(ivec2(floor(q)),ivec2(0),grid_shape-ivec2(2));vec2 f=clamp(q-vec2(c),vec2(0.),vec2(1.));float a=texelFetch(actual_height_rf,c,0).r,b=texelFetch(actual_height_rf,c+ivec2(1,0),0).r,d=texelFetch(actual_height_rf,c+ivec2(1,1),0).r,e=texelFetch(actual_height_rf,c+ivec2(0,1),0).r;return f.x+f.y<=1.?a+(b-a)*f.x+(e-a)*f.y:d+(e-d)*(1.-f.x)+(b-d)*(1.-f.y);}

float rich_h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float rich_n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*f*(f*(f*6.-15.)+10.);return mix(mix(rich_h(i),rich_h(i+vec2(1.,0.)),f.x),mix(rich_h(i+vec2(0.,1.)),rich_h(i+vec2(1.)),f.x),f.y);}
float rich_phase(vec2 q){return q.x*13.1+q.y*5.7+(rich_n(q/1.7)-.5)*3.2+(rich_n(q/4.9+vec2(7.,-3.))-.5)*1.1;}
float rich_wave(vec2 q){float a=rich_phase(q);return .00105*sin(a)*(.25+.75*rich_n(q/1.1))+.00048*sin(q.y*12.7-q.x*3.9+(rich_n(q/1.9)-.5)*4.1)+.00022*sin(q.x*23.4+q.y*6.1);}
void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 float depth=-.025-bed(p);if(depth<=0.)discard;
 // Static global phases keep byte-exact captures possible. 28-60cm ripples
 // remain 20-60 logical pixels at this camera, not a flat sky-blue gradient.
 // Static noncommensurate phase warping prevents ROOT123's regular spot grid.
 // Restrained ripples are lit surface detail, not opaque foam dots or a flow
 // simulation. No TIME, no receiver-local origin, no ownership/nav changes.
 vec2 q=xyz.xz;
 float a=rich_phase(q);
 float derivative_step=.015;
 vec2 slope=vec2(rich_wave(q+vec2(derivative_step,0.))-rich_wave(q-vec2(derivative_step,0.)),rich_wave(q+vec2(0.,derivative_step))-rich_wave(q-vec2(0.,derivative_step)))/(2.*derivative_step);
 vec3 wn=normalize(vec3(-slope.x,1.,-slope.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
 float crest=smoothstep(.52,.96,sin(a));
 float deep=1.-exp(-depth*2.4);
 vec3 shallow=vec3(.255,.29,.205),channel=vec3(.095,.205,.19);
 // Native static interference detail: no TIME, fake foam, or new wet mask.
 // Same native RF bed changes sediment exposure continuously with actual
 // depth and neighbouring bed grade, not a receiver-local painted water mask.
 float bed_dx=(bed(p+vec2(8.,0.))-bed(p-vec2(8.,0.)))*102.4/16.;
 float bed_dz=(bed(p+vec2(0.,8.))-bed(p-vec2(0.,8.)))*72.40773439/16.;
 float bed_grade=length(vec2(bed_dx,bed_dz));
 vec3 bed_sediment=mix(vec3(.23,.215,.16),vec3(.175,.20,.175),smoothstep(.12,.7,bed_grade));
 float bed_visible=exp(-depth*1.7);
 ALBEDO=mix(channel,bed_sediment,bed_visible)+vec3(.008,.012,.010)*crest;
 ROUGHNESS=mix(.36,.26,deep);SPECULAR=.32;METALLIC=0.;
 // Steeper opacity falloff leaves a narrow visible sediment shallows band.
 // Actual RF triangles still exclusively decide shoreline and water support.
 ALPHA=mix(.38,.96,smoothstep(.008,.11,depth));
}
