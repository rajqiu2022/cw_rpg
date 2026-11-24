extends "res://scripts/dev/world_map_v15_v9_visual_quality_proposal_surface.gd"

## NEW shader candidate. Literal finite parcels replace the unproven GPU Array
## upload dependency. Actual source scans/metres/mips remain inherited intact.
const V9B_MATERIAL_ID := "V9B_LITERAL_FINITE_CULTIVATION_MULTISCALE_SILT_MINERAL_SNOW_PROPOSAL"

func _v9b_parcel_branch(index: int,parcel: Vector4) -> String:
	return """ {
 vec4 parcel=vec4(%.9f,%.9f,%.9f,%.9f);vec2 delta=p-parcel.xy;
 float angle=sin(%.9f*2.17)*.61;
 vec2 axis=vec2(cos(angle),sin(angle)),across=vec2(-axis.y,axis.x);
 vec2 local=vec2(dot(delta,axis),dot(delta,across))/parcel.zw;
 float owner=1.-smoothstep(.82,1.05,max(abs(local.x),abs(local.y)));
 float phase=dot(vec2(delta.x/102.4,delta.y/72.40773439),axis)*6.8+%.9f*1.73+(n2(xyz.xz/2.3)-.5)*.32;
 if(owner>field_owner){field_owner=owner;crop=.16+.58*smoothstep(.20,.80,.5+.5*sin(phase));furrow_n=sin(phase);}
 }
"""%[parcel.x,parcel.y,parcel.z,parcel.w,float(index),float(index)]

func _v9b_literal_parcels() -> String:
	var code: String="float field_owner=0.,crop=0.,furrow_n=0.;\n"
	for index in V9_PARCELS.size(): code+=_v9b_parcel_branch(index,V9_PARCELS[index])
	return code

func _v9b_replace(code: String,before: String,after: String) -> String:
	if code.count(before)!=1:
		error="V9B exact frozen shader anchor absent/ambiguous."
		return ""
	return code.replace(before,after)

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var material: ShaderMaterial=super.terrain_material(weights,roads,local_rect)
	if material==null: return null
	var before: String=material.shader.code
	var code: String=before
	var start: int=code.find(" float field_owner=0.,crop=0.,furrow_n=0.;")
	var finish: int=code.find(" field_owner*=.58*")
	if start<0 or finish<=start or code.count("for(int i=0;i<18;i++)")!=1:
		error="V9B finite parcel source block absent."
		return null
	code=code.substr(0,start)+_v9b_literal_parcels()+code.substr(finish)
	code=_v9b_replace(code,"uniform vec4 finite_parcels[18];","uniform float v9b_material_identity=1.;")
	if code.is_empty(): return null
	code=_v9b_replace(code,"field_owner*=.58*","field_owner*=.84*")
	if code.is_empty(): return null
	code=_v9b_replace(code,"col=mix(col,mix(loam,scan(leafy_grass_diff,2.,w,1.),crop),field_owner);","""// Finite local planted/turned-soil bands, same channels and period.
 vec3 crop_scan=scan(leafy_grass_diff,2.,w,1.);float crop_luma=dot(crop_scan,vec3(.2126,.7152,.0722));
 vec3 crop_turf=mix(vec3(.100,.205,.090),vec3(.205,.315,.125),clamp(crop_luma*1.8,0.,1.));
 vec3 tilled=mix(vec3(.195,.155,.095),vec3(.305,.235,.145),patch);
 col=mix(col,mix(tilled,crop_turf,crop),field_owner);""")
	if code.is_empty(): return null
	code=_v9b_replace(code,"wn=normalize(wn+vec3(furrow_n*.008*field_owner,0.,0.));","wn=normalize(wn+vec3(furrow_n*.032*field_owner,0.,0.));")
	if code.is_empty(): return null
	code=_v9b_replace(code,"vec3 turf=mix(vec3(.160,.230,.120),vec3(.235,.310,.175),patch);","""// Honest native vegetation pigment treatment, NOT a new green scan.
 float grass_luma=dot(scan(grass_ground_diff,2.51,w,1.),vec3(.2126,.7152,.0722));
 vec3 turf=mix(vec3(.105,.190,.075),vec3(.230,.330,.145),growth);
 turf*=.80+.45*clamp(grass_luma*1.8,0.,1.);""")
	if code.is_empty(): return null
	code=_v9b_replace(code,"col=mix(col,floor_col,floor_owner);arm=mix(arm,vec3(1.,.89,0.),floor_owner);","col=mix(col,floor_col,min(1.,floor_owner*1.28));arm=mix(arm,vec3(1.,.89,0.),floor_owner);")
	if code.is_empty(): return null
	code=_v9b_replace(code,"float moist=smoothstep(.35,.72,silt)*wet;","""// Several connected moisture/deposition scales; opaque legal dry soil,
 // not new water geometry or NAV. No cracked scan ALBEDO dominance.
 float silt_shelf=smoothstep(.27,.73,n2(xyz.xz/1.15)*.35+n2(xyz.xz/5.8)*.65);
 float moist=smoothstep(.30,.68,silt)*wet;
 silt_col=mix(mix(vec3(.065,.075,.063),vec3(.110,.132,.095),silt),mix(vec3(.235,.213,.163),vec3(.330,.290,.210),silt),silt_shelf*.72);""")
	if code.is_empty(): return null
	code=_v9b_replace(code,"mix(.76,.34,moist)","mix(.77,.20,moist)")
	if code.is_empty(): return null
	code=_v9b_replace(code,"col=mix(col,mix(rock_col,loam,.17*(1.-mineral_patch)),rock*.86*(1.-snow));","""// Existing rock_01 is granular grey-brown ground, not cliff imagery.
 // Native irregular mineral plates/litter islands are explicitly procedural.
 float rock_luma=dot(rock_col,vec3(.2126,.7152,.0722));
 float plate=smoothstep(.24,.64,n2(xyz.xz/1.35)*.65+n2(xyz.xz/4.1)*.35);
 vec3 grey_mineral=mix(vec3(.185,.205,.205),vec3(.400,.410,.395),clamp(rock_luma*1.7,0.,1.));
 col=mix(col,mix(grey_mineral,mix(loam,grey_mineral,.55),plate),rock*.94*(1.-snow));""")
	if code.is_empty(): return null
	code=_v9b_replace(code,"float deposit=snow*(.28+.66*smoothstep(.29,.70,n2(xyz.xz/1.4)*.55+n2(xyz.xz/4.6)*.45))*(1.-smoothstep(.30,1.1,grade)*.7);","float deposit=snow*(.72+.24*smoothstep(.29,.70,n2(xyz.xz/1.4)*.55+n2(xyz.xz/4.6)*.45))*(1.-smoothstep(.42,1.2,grade)*.54);")
	if code.is_empty(): return null
	code=_v9b_replace(code,"vec3 snow_col=mix(vec3(.51,.55,.56),vec3(.71,.75,.76),smoothstep(.27,.71,patch));","vec3 snow_col=mix(vec3(.72,.74,.73),vec3(.90,.91,.89),smoothstep(.27,.71,patch));")
	if code.is_empty(): return null
	code=_v9b_replace(code,"col=mix(col,rock_col,snow_ground);","col=mix(col,mix(rock_col,vec3(dot(rock_col,vec3(.2126,.7152,.0722))),.72),snow_ground);")
	if code.is_empty(): return null
	code=_v9b_replace(code,"ROUGHNESS=clamp(arm.g,.30,.98);SPECULAR=.18;","ROUGHNESS=clamp(arm.g,.18,.98);SPECULAR=mix(.18,.32,moist*wet_owner);")
	if code.is_empty(): return null
	# Keep every actual inherited sampler/owner binding, but do not carry the
	# removed finite_parcels uniform into the new literal-branch shader.
	var retained: Dictionary={}
	for row: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(row["name"])
		if name!="finite_parcels": retained[name]=material.get_shader_parameter(name)
	var replacement:=Shader.new()
	replacement.code=code
	material.shader=replacement
	for name: String in retained: material.set_shader_parameter(name,retained[name])
	material.set_shader_parameter("v9b_material_identity",1.)
	v7_material_records.back()["identity"]=V9B_MATERIAL_ID
	v7_material_records.back()["shader_code_sha256"]=_v7_code_sha(code)
	v8_material_records.back()["identity"]=V9B_MATERIAL_ID
	v8_material_records.back()["actual_code_sha256"]=_v7_code_sha(code)
	v9_material_records.back()["kind"]="inherited_terrain_provenance_replaced"
	v9_material_records.back()["no_longer_attached_to_receiver"]=true
	v9_material_records.back()["actual_attached_code_sha256"]=_v7_code_sha(code)
	v9_material_records.append({"identity":V9B_MATERIAL_ID,"kind":"terrain","actual_script_path":get_script().resource_path,"actual_script_sha256":FileAccess.get_sha256(get_script().resource_path),"actual_code_sha256":_v7_code_sha(code),"parent_actual_code_sha256":_v7_code_sha(before),"registered_binding":_v7_binding_evidence(material),"literal_parcels":V9_PARCELS,"finite_parcel_array_dependency":false,"geometry_navigation_change":false,"visual_approved":false,"production_approved":false,"limitations":"existing river/snow shelf geometry and native sites unchanged; opaque wet-soil treatment is not a new wetland/waterbody","provenance":"unchanged18 CC0 physical scans plus explicitly native pigment/deposition/mineral formulas, NOT new CC0 scans"})
	return material

func parcel_diagnostic_material() -> ShaderMaterial:
	# Independent GPU test: R=literal finite-owner, G=old untyped Array upload.
	# Metadata get_shader_parameter alone never counted as GPU consumption proof.
	var code: String="""shader_type spatial;render_mode cull_disabled,unshaded;
 uniform vec4 debug_uniform_parcels[18];varying vec3 xyz;
 void vertex(){xyz=VERTEX;}
 float h2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
 float n2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h2(i),h2(i+vec2(1.,0.)),f.x),mix(h2(i+vec2(0.,1.)),h2(i+vec2(1.)),f.x),f.y);}
 void fragment(){vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 """+_v9b_literal_parcels()+"""
 float uploaded=0.;for(int i=0;i<18;i++){vec4 parcel=debug_uniform_parcels[i];float angle=sin(float(i)*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));vec2 d=p-parcel.xy;vec2 local=vec2(dot(d,axis),dot(d,vec2(-axis.y,axis.x)))/parcel.zw;uploaded=max(uploaded,1.-smoothstep(.82,1.05,max(abs(local.x),abs(local.y))));}
 ALBEDO=vec3(field_owner,uploaded,0.);}
 """
	var material:=ShaderMaterial.new()
	material.shader=Shader.new()
	material.shader.code=code
	var untyped: Array=[]
	for parcel: Vector4 in V9_PARCELS: untyped.append(parcel)
	material.set_shader_parameter("debug_uniform_parcels",untyped)
	return material
