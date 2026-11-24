shader_type canvas_item;
render_mode unshaded;
uniform sampler2D baseline : filter_nearest, repeat_disable;
uniform sampler2D native_image : filter_nearest, repeat_disable;
uniform vec2 canvas_origin;
uniform vec2 canvas_size;
uniform int mode=0;
uniform vec2 bay[64];
uniform vec2 island[72];
float bay_distance(vec2 p){bool inside=false;float dist=1e20;for(int i=0;i<64;i++){vec2 a=bay[i],b=bay[(i+1)%64];vec2 v=b-a;dist=min(dist,length(p-a-v*clamp(dot(p-a,v)/max(dot(v,v),.0001),0.,1.)));if((a.y>p.y)!=(b.y>p.y)&&p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x)inside=!inside;}return inside?dist:-dist;}
float island_distance(vec2 p){bool inside=false;float dist=1e20;for(int i=0;i<72;i++){vec2 a=island[i],b=island[(i+1)%72];vec2 v=b-a;dist=min(dist,length(p-a-v*clamp(dot(p-a,v)/max(dot(v,v),.0001),0.,1.)));if((a.y>p.y)!=(b.y>p.y)&&p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x)inside=!inside;}return inside?dist:-dist;}
float bianzhou_influence(vec2 p){vec2 q=abs(p-vec2(7700.,1780.))-vec2(450.,650.);return 1.-smoothstep(0.,96.,max(q.x,q.y));}
void fragment(){vec2 p=canvas_origin+UV*canvas_size;float sea=-1e20;if(p.x>=10400.&&p.y>=2100.&&p.y<=4260.)sea=min(bay_distance(p),-island_distance(p));vec4 old=texture(baseline,UV),fresh=texture(native_image,UV);float influence=smoothstep(-96.,-32.,sea);if(mode==1){bool old_allowed=old.a>=.5&&max(old.r,max(old.g,old.b))>=.5;float allowed=old_allowed&&(influence<=0.||(fresh.r>.999&&fresh.a>=.5))?1.:0.;COLOR=vec4(vec3(allowed),1.);}else COLOR=vec4(mix(old.rgb,fresh.rgb,max(influence,bianzhou_influence(p))),1.);}
