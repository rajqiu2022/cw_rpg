shader_type spatial;render_mode cull_disabled;
uniform sampler2D biome_weights:filter_linear,repeat_disable;
uniform sampler2D road_weights:filter_linear,repeat_disable;
uniform vec4 source_rect;uniform vec2 world_size=vec2(12288.,8192.);
uniform int field_ecology_mode=3;
uniform sampler2D grass_ground_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_ground_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_ground_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D leafy_grass_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_ground_04_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_01_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brown_mud_03_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_diff:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_nor_gl:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D aerial_grass_rock_arm:filter_linear_mipmap_anisotropic,repeat_enable;
uniform float v9c_material_identity=1.;
varying vec3 xyz;varying vec3 geo;
void vertex(){xyz=VERTEX;geo=NORMAL;}
float h2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h2(i),h2(i+vec2(1.,0.)),f.x),mix(h2(i+vec2(0.,1.)),h2(i+vec2(1.)),f.x),f.y);}
vec3 scan(sampler2D s,float metres,vec3 w,float bias){return texture(s,xyz.zy/metres,bias).rgb*w.x+texture(s,xyz.xz/metres,bias).rgb*w.y+texture(s,xyz.xy/metres,bias).rgb*w.z;}
uniform float v9d_material_identity=1.;
uniform float v9e_material_identity=1.;

float coast31h_segment(vec2 p,vec2 a,vec2 b){vec2 v=b-a;return length(p-a-v*clamp(dot(p-a,v)/max(dot(v,v),.001),0.,1.));}
vec3 coast31h_bianzhou_road(vec3 original,vec2 p){
 float d=min(min(coast31h_segment(p,vec2(7830.06396484375,2294.90063476563),vec2(8050.,2150.)),coast31h_segment(p,vec2(8050.,2150.),vec2(8050.,1850.))),min(coast31h_segment(p,vec2(8050.,1850.),vec2(7600.,1800.)),coast31h_segment(p,vec2(7600.,1800.),vec2(7600.,1556.8779296875))));
 float ellipse=(length((p-vec2(7600.,1800.))/vec2(250.,160.))-1.)*160.;
 float owner=1.-smoothstep(38.,64.,d);owner=max(owner,1.-smoothstep(-12.,18.,ellipse));
 float retired=min(coast31h_segment(p,vec2(7840.,2295.),vec2(7840.,2230.)),min(coast31h_segment(p,vec2(7840.,2230.),vec2(7600.,2230.)),coast31h_segment(p,vec2(7600.,2230.),vec2(7600.,2196.8779296875))));
 float remove=1.-smoothstep(42.,70.,retired);
 original.rg*=1.-remove;original.rg=max(original.rg,vec2(owner));return original;
}

void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 eco=texture(biome_weights,uv);vec3 road=texture(road_weights,uv).rgb;road=coast31h_bianzhou_road(road,vec2(p.x,p.y-xyz.y*72.4077343935025));
 vec3 gn=normalize(geo);vec3 w=pow(abs(gn),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 float forest=clamp(eco.r,0.,1.),rock=clamp(eco.g,0.,1.),wet=clamp(eco.b,0.,1.),snow=clamp(eco.a,0.,1.);
 float route=clamp(road.r,0.,1.),sand=road.b*(1.-snow)*(1.-forest);
 float patch=n2(xyz.xz/1.9)*.38+n2(xyz.xz/5.8+vec2(7.,-3.))*.62;
 float growth=smoothstep(.34,.67,patch);
 // Registered diffuse stays in RGB. Native pigment correction is a small
 // multiplier, not replacement by two flat colours or a luma-only field.
 vec3 gd=scan(grass_ground_diff,2.51,w,.25),ld=scan(leafy_grass_diff,2.,w,.25);
 vec3 fd=scan(forest_ground_04_diff,3.2,w,0.),rd=scan(rock_01_diff,1.5,w,0.);
 vec3 bd=scan(brown_mud_03_diff,1.3,w,.25),ad=scan(aerial_grass_rock_diff,15.,w,0.);
 vec3 ga=scan(grass_ground_arm,2.51,w,.25),la=scan(leafy_grass_arm,2.,w,.25);
 vec3 fa=scan(forest_ground_04_arm,3.2,w,0.),ra=scan(rock_01_arm,1.5,w,0.);
 vec3 ba=scan(brown_mud_03_arm,1.3,w,.25),aa=scan(aerial_grass_rock_arm,15.,w,0.);
 vec3 gnscan=scan(grass_ground_nor_gl,2.51,w,.25),ln=scan(leafy_grass_nor_gl,2.,w,.25);
 vec3 fn=scan(forest_ground_04_nor_gl,3.2,w,0.),rn=scan(rock_01_nor_gl,1.5,w,0.);
 vec3 bn=scan(brown_mud_03_nor_gl,1.3,w,.25),an=scan(aerial_grass_rock_nor_gl,15.,w,0.);
 vec3 turf=(gd*.80+ld*.20)*vec3(.86,1.10,.80);
 vec3 turf_a=ga*.80+la*.20,turf_n=gnscan*.80+ln*.20;
 vec3 loam=fd*.75+rd*.20+bd*.05;
 vec3 loam_a=fa*.75+ra*.20+ba*.05,loam_n=fn*.75+rn*.20+bn*.05;
 float dry_island=.015+.085*(1.-growth);
 vec3 col=mix(turf,loam,dry_island),arm=mix(turf_a,loam_a,dry_island),detail=mix(turf_n,loam_n,dry_island);
 // Real litter/soil detail at roots, not a flat black forest disk.
 vec3 litter=ld*.74+fd*.26;
 col=mix(col,litter*vec3(.74,.94,.69),forest*.80);
 arm=mix(arm,la*.74+fa*.26,forest*.80);detail=mix(detail,ln*.74+fn*.26,forest*.80);
 float field_owner=0.,crop=0.,furrow_n=0.;
 {
 vec4 parcel=vec4(3150.000000000,3000.000000000,220.000000000,170.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(0.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+0.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(3690.000000000,3080.000000000,240.000000000,150.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(1.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+1.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(4250.000000000,3250.000000000,195.000000000,210.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(2.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+2.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(4810.000000000,3150.000000000,215.000000000,145.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(3.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+3.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(5310.000000000,3480.000000000,230.000000000,190.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(4.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+4.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(3260.000000000,3540.000000000,245.000000000,190.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(5.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+5.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(3860.000000000,3750.000000000,210.000000000,145.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(6.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+6.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(4490.000000000,3760.000000000,225.000000000,195.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(7.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+7.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(4950.000000000,3970.000000000,210.000000000,175.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(8.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+8.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(5570.000000000,4000.000000000,185.000000000,135.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(9.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+9.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(6680.000000000,5670.000000000,205.000000000,160.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(10.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+10.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(7230.000000000,5740.000000000,240.000000000,180.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(11.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+11.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(7800.000000000,5790.000000000,185.000000000,210.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(12.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+12.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(8380.000000000,5880.000000000,230.000000000,175.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(13.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+13.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(6880.000000000,6240.000000000,235.000000000,165.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(14.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+14.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(7480.000000000,6310.000000000,190.000000000,160.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(15.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+15.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(8050.000000000,6410.000000000,235.000000000,180.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(16.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+16.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
 {
 vec4 parcel=vec4(8660.000000000,6470.000000000,210.000000000,150.000000000);vec2 delta=p-parcel.xy;
 float angle=sin(17.000000000*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+17.000000000*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }

 field_owner*=.88*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);
 // Narrow ridges between actual granular earth and actual low grass scans.
 // No full-region high-contrast green/brown ALBEDO sine bands.
 col=mix(col,mix(loam,turf,crop)*(.97+.035*furrow_n),field_owner);
 arm=mix(arm,mix(loam_a,turf_a,crop),field_owner);
 detail=mix(detail,mix(loam_n,turf_n,crop),field_owner);
 // Mineral patches retain RGB scan grains at the real1.5/3.2/15m periods.
 float plate=smoothstep(.29,.67,n2(xyz.xz/1.3)*.40+n2(xyz.xz/4.4)*.60);
 vec3 mineral=rd*.93+ad*.07;
 mineral*=vec3(1.07,1.08,1.06);
 float exposed=rock*.95*(1.-snow);
 col=mix(col,mix(mineral,loam,plate*.08),exposed);
 arm=mix(arm,ra*.93+aa*.07,exposed);detail=mix(detail,rn*.93+an*.07,exposed);
 // Existing native sand owner, explicitly not a licensed sand photograph.
 float sand_owner=sand*.90;
 col=mix(col,mix(fd*.43+rd*.57,vec3(.38,.34,.25),.20),sand_owner);
 arm=mix(arm,fa*.43+ra*.57,sand_owner);detail=mix(detail,fn*.43+rn*.57,sand_owner);
 // Irregular opaque wet-soil films/pools on already legal RF soil. They
 // never alter ALPHA/discard/waterY/land/navigation or become walk support.
 float pool=smoothstep(.42,.59,n2(xyz.xz/2.8)*.38+n2(xyz.xz/6.7+vec2(4.,9.))*.62);
 float wet_owner=wet*.97*(1.-route)*(1.-snow);
 float bank_film=1.-smoothstep(.04,.25,xyz.y);

 vec3 silt=fd*.60+ld*.05+bd*.35;
 vec3 wet_col=mix(silt*vec3(.62,.57,.48),mix(silt*vec3(.28,.34,.32),vec3(.065,.10,.11),.54),pool*.83+bank_film*.12);
 col=mix(col,wet_col,wet_owner);
 vec3 wet_a=fa*.60+la*.05+ba*.35;wet_a.g=mix(.74,.11,clamp(pool*.90+bank_film*.12,0.,1.));
 arm=mix(arm,wet_a,wet_owner);detail=mix(detail,mix(fn*.60+ln*.05+bn*.35,vec3(.5,.5,1.),pool*.94),wet_owner);
 // Material snow coverage is irregular; it cannot certify that a cached
 // shelf mesh has been repaired. A derived-RF executor must say so honestly.
 float grade=length(gn.xz)/max(abs(gn.y),.05);
 float deposit=snow*(.22+.60*smoothstep(.24,.68,n2(xyz.xz/1.8)*.38+n2(xyz.xz/4.7+vec2(-3.,5.))*.62))*(1.-smoothstep(.22,.54,grade));
 float snow_bed=snow*(1.-deposit);
 col=mix(col,mineral*vec3(.74,.81,.87),snow_bed);arm=mix(arm,ra*.93+aa*.07,snow_bed);detail=mix(detail,rn*.93+an*.07,snow_bed);
 float crust=n2(xyz.xz/.18)*.24+n2(xyz.xz/.73)*.31+patch*.45;
 vec3 snow_col=mix(vec3(.48,.52,.51),vec3(.70,.73,.72),clamp(crust,0.,1.));
 snow_col*=.93+.07*rd;
 col=mix(col,snow_col,deposit);arm=mix(arm,vec3(1.,.78,0.),deposit);
 detail=mix(detail,mix(vec3(.5,.5,1.),rn,.28),deposit);
 // Coherent compact earth with real mineral ALBEDO/ARM/normal, not a blurred
 // whole brown colour replacement and not the cracked mud scan as a road.
 float compact=n2(xyz.xz/.56)*.34+n2(xyz.xz/2.1)*.66;
 vec3 earth=mix(vec3(.25,.23,.18),vec3(.34,.30,.24),compact);
 vec3 aggregate=fd*.70+rd*.30;
 vec3 lane=mix(earth,aggregate,.62);
 float shoulder=clamp(road.g-route,0.,1.);
 col=mix(col,mix(loam,lane,.65),shoulder*.64);col=mix(col,lane,route);
 arm=mix(arm,mix(vec3(1.,.90,0.),fa*.70+ra*.30,.62),route);
 detail=mix(detail,mix(vec3(.5,.5,1.),fn*.70+rn*.30,.62),route);
 ALBEDO=col;AO=mix(1.,arm.r,.24);ROUGHNESS=clamp(arm.g,.14,.98);SPECULAR=mix(.18,.52,clamp((pool*.90+bank_film*.10)*wet_owner,0.,1.));METALLIC=0.;
 float strength=mix(.26,.20,route);vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));
 wn=normalize(wn+vec3(furrow_n*.07*field_owner,0.,0.));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
