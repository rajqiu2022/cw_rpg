extends "res://tests/helpers/luoyang_inn_y830_natural_alpha_diagnostic_20261009.gd"
## NEW limited consumer: original PNG alpha oracle, independent packed Float32
## key expectation. Never calls production key codec to construct expected.
static func independent_native(value: float) -> Variant:
	if not is_finite(value): return null
	var encoded: PackedByteArray=PackedFloat32Array([value]).to_byte_array()
	var native: float=encoded.decode_float(0)
	if not is_finite(native): return null
	return 0.0 if native==0.0 else native

func _union_png(debug: Dictionary,_registered: bool) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D
	var image: Image=png_alpha.call("image_for",actor)
	if image==null: return {"valid":false}
	var frame: Rect2i=png_alpha.call("frame",actor,image)
	if frame.size.x<=0: return {"valid":false}
	var expected:=Image.create(frame.size.x,frame.size.y,false,Image.FORMAT_RGBA8)
	expected.fill(Color(0,0,0,0))
	var helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	var actor_key: Variant=independent_native(float(player.call("get_depth_sort_y")))
	if actor_key==null: return {"valid":false}
	var candidates: Array[Sprite2D]=[]
	var selected: Array=[]
	for object: Dictionary in manifest.objects:
		if object.get("role","")=="ground_overlay" or object.get("ghost_occlusion",true)==false: continue
		var sprite: Sprite2D=prop(String(object.id))
		var matches: Array=[]
		for row: Dictionary in helper.get("_props"):
			if row.get("sprite")==sprite and String(row.get("id",""))==String(object.id): matches.append(row)
		if matches.size()!=1: return {"valid":false,"reason":"registered_prop_identity","id":object.id}
		var measured: float=sprite.to_global(matches[0].foot_local).y
		var prop_key: Variant=independent_native(measured)
		if prop_key==null: return {"valid":false}
		# Exact native tie puts every prop (including nonoccluding props) before
		# actors. Strictly greater feet alone can occlude, plus real live order.
		if prop_key<=actor_key or not png_alpha.call("actual_in_front",sprite,player): continue
		candidates.append(sprite)
		selected.append({"id":object.id,"raw_foot":_native(measured),"independent_native_key":prop_key,"band":sprite.z_index,"index":sprite.get_index()})
	var pixels:=0
	for y in frame.size.y:
		for x in frame.size.x:
			if image.get_pixelv(frame.position+Vector2i(x,y)).a<=0: continue
			var uv:=Vector2((x+.5)/frame.size.x,(y+.5)/frame.size.y)
			if actor.flip_h: uv.x=1-uv.x
			if actor.flip_v: uv.y=1-uv.y
			var world: Vector2=actor.to_global(actor.get_rect().position+uv*actor.get_rect().size)
			var remainder:=1.0
			for sprite: Sprite2D in candidates: remainder*=1-float(png_alpha.call("alpha_at",sprite,world))
			var value: float=1-remainder
			if value>0: expected.set_pixel(x,y,Color(1,1,1,value)); pixels+=1
	var actual: Image=debug.get("mask_image") as Image
	var exact: bool=not bool(debug.get("active",false)) and int(debug.get("pixels",-1))==0 if pixels==0 else debug.get("space")=="actor_frame" and debug.get("active")==true and actual!=null and actual.get_size()==frame.size and actual.get_data()==expected.get_data()
	return {"valid":true,"domain":"INDEPENDENT_PACKED_FLOAT32_REGISTERED_FOOT_PROP_BEFORE_ACTOR_TIES","independent_actor_key":actor_key,"expected_pixels":pixels,"expected_RGBA_sha256":_digest(expected.get_data()),"actual_mask":_scalar_evidence(actual),"byte_exact":exact,"candidates":selected,"uses_production_mask_or_key_as_expected":false}

func observe(label: String) -> Dictionary:
	var result: Dictionary=super.observe(label)
	if result.get("valid")!=true: return result
	var helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	var player: Node2D=field.get("_player") as Node2D
	var target: Sprite2D=prop("inn")
	var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
	var states: Array=helper.call("get_depth_order_state")
	var actor_rows: Array=[]; var prop_rows: Array=[]
	var all_keys_exact: bool=not states.is_empty()
	for row: Dictionary in states:
		var expected: Variant=independent_native(float(row.raw_foot_y))
		all_keys_exact=all_keys_exact and expected!=null and typeof(row.foot_y)==TYPE_FLOAT and row.foot_y==expected and row.kind_rank==(1 if row.actor else 0) and row.stable_ordinal>=0 and row.band==clampi(int(floor(float(expected)/8.0)),0,255)
		if row.id=="inn": prop_rows.append(row)
		# Bind by the same real actor identity already stored by original helper,
		# not by guessed actor string.
		for entry: Dictionary in helper.get("_depth_entries"):
			if entry.node==player and entry.id==row.id: actor_rows.append(row)
	var exact_pair: bool=actor_rows.size()==1 and prop_rows.size()==1
	var actor_key: Variant=independent_native(float(player.call("get_depth_sort_y")))
	var inn_props: Array=[]
	for actual_prop: Dictionary in helper.get("_props"):
		if actual_prop.sprite==target: inn_props.append(actual_prop)
	if inn_props.size()!=1: return {"valid":false,"reason":"exact_actual_registered_inn"}
	var raw_inn: float=target.to_global(inn_props[0].foot_local).y
	var prop_key: Variant=independent_native(raw_inn)
	var actual_front: bool=png_alpha.call("actual_in_front",player,target)
	var expected_front: bool=actor_key>=prop_key
	var pair_exact: bool=false
	if exact_pair:
		var a: Dictionary=actor_rows[0]; var p: Dictionary=prop_rows[0]
		pair_exact=a.foot_y==actor_key and p.foot_y==prop_key and a.sibling_index==player.get_index() and p.sibling_index==target.get_index() and a.band==player.z_index and p.band==target.z_index and a.kind_rank==1 and p.kind_rank==0
	var main: Sprite2D=player.get("sprite") as Sprite2D
	result["canonical_order"]={"states":states,"states_native_hex":var_to_bytes(states).hex_encode(),"all_keys_exact":all_keys_exact,"actor_rows":actor_rows,"inn_rows":prop_rows,"pair_exact":pair_exact,"independent_actor_key":actor_key,"independent_inn_key":prop_key,"expected_actor_front":expected_front,"actual_actor_front":actual_front,"front_order_exact":actual_front==expected_front,"debug_snapshot_valid":not debug.get("invalid_depth_snapshot",false),"debug_key":debug.get("native_depth_key"),"debug_key_exact":debug.get("native_depth_key",{}).get("foot_y")==actor_key,"main_alpha":main.modulate.a*main.self_modulate.a,"ghost_pixels":debug.get("pixels"),"ghost_active":debug.get("active"),"production_raw_actor":debug.get("raw_actor_foot_y")}
	result["native_union_png"]=result.registered_actual_foot_union_png
	result["old_probe_union_is_diagnostic_not_new_native_expected"]=true
	var style: String=String(player.get("_weapon_style"))
	var direction: String=String(player.get("_direction"))
	var moving: bool=player.get("_is_moving")==true
	var frames: int=8 if moving else 4
	var state: String="walk" if moving else "idle"
	var expected_path: String="res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png"%[style,style,state,direction,frames]
	var actor_identity: bool=style in ["sword","dao","staff","palm","hidden"] and direction in ["left","right","up","down"] and main.texture!=null and main.texture.resource_path==expected_path and main.hframes==frames and main.vframes==1 and main.frame>=0 and main.frame<frames and not main.flip_h and not main.flip_v and not main.region_enabled and main.material==null and png_bindings.has(expected_path)
	result["current_actor_identity"]={"exact":actor_identity,"weapon_style":style,"direction":direction,"state":state,"expected_source_path":expected_path,"actual_sprite":_sprite_observation(main)}
	return result

