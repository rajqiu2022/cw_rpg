extends "res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd"
## Read-only natural inn boundary observations. No refresh, ordering or mask setter.
const PNG_ALPHA=preload("res://tests/helpers/v15_geometry_oracle.gd")
var png_alpha: RefCounted=PNG_ALPHA.new()
var png_bindings: Dictionary={}

func _digest(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
	return hash.finish().hex_encode()

func _native(value: Variant) -> Dictionary:
	return {"type":typeof(value),"value":_scalar_evidence(value),"variant_hex":var_to_bytes(value).hex_encode()}

func bind_original_pngs() -> bool:
	var player: Node2D=field.get("_player") as Node2D
	var sprites: Array[Sprite2D]=[player.get("sprite") as Sprite2D]
	for object: Dictionary in manifest.objects:
		var actual: Sprite2D=prop(String(object.id))
		if actual==null or actual.texture==null or actual.texture.resource_path!=String(object.texture): return false
		sprites.append(actual)
	for sprite: Sprite2D in sprites:
		var path: String=sprite.texture.resource_path
		if png_bindings.has(path) and png_alpha.images.has(sprite.texture.get_instance_id()): continue
		var image: Image=Image.load_from_file(path)
		var imported: Image=alpha.image_for(sprite)
		if image==null or imported==null or image.get_size()!=imported.get_size(): return false
		image.convert(Image.FORMAT_RGBA8)
		var own: Image=imported.duplicate()
		own.convert(Image.FORMAT_RGBA8)
		var src: PackedByteArray=image.get_data()
		var imp: PackedByteArray=own.get_data()
		var src_alpha:=PackedByteArray(); var imp_alpha:=PackedByteArray()
		for i in range(3,src.size(),4):
			src_alpha.append(src[i]); imp_alpha.append(imp[i])
		if src_alpha!=imp_alpha: return false
		png_alpha.images[sprite.texture.get_instance_id()]=image
		png_bindings[path]={"file_sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()],"original_RGBA_sha256":_digest(src),"imported_RGBA_sha256":_digest(imp),"all_original_imported_alpha_bytes_exact":true,"alpha_sha256":_digest(src_alpha),"RGBA_equal_not_required_for_alpha_domain":src==imp}
	return true

func _union_png(debug: Dictionary,registered: bool) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D
	var image: Image=png_alpha.call("image_for",actor)
	var frame: Rect2i=png_alpha.call("frame",actor,image)
	if image==null or frame.size.x<=0: return {"valid":false}
	var expected:=Image.create(frame.size.x,frame.size.y,false,Image.FORMAT_RGBA8)
	expected.fill(Color(0,0,0,0))
	var helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	var container: Node2D=field.get("world_container") as Node2D
	var candidates: Array[Sprite2D]=[]
	var selected: Array=[]
	for object: Dictionary in manifest.objects:
		if object.get("role","")=="ground_overlay" or object.get("ghost_occlusion",true)==false: continue
		var sprite: Sprite2D=prop(String(object.id))
		var foot: float=container.to_global(point(object.world_foot_px)).y
		if registered:
			var matches: Array=[]
			for row: Dictionary in helper.get("_props"):
				if row.get("sprite")==sprite and String(row.get("id",""))==String(object.id): matches.append(row)
			if matches.size()!=1: return {"valid":false,"reason":"registered_prop_identity","id":object.id}
			foot=sprite.to_global(matches[0].foot_local).y
		if foot<=float(player.call("get_depth_sort_y")) or not png_alpha.call("actual_in_front",sprite,player): continue
		candidates.append(sprite); selected.append({"id":object.id,"actual_foot":_native(foot),"band":sprite.z_index,"index":sprite.get_index()})
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
	return {"valid":true,"domain":"MEASURED_REGISTERED_NATIVE_FOOT" if registered else "ORIGINAL_AUTHOR_MANIFEST_FOOT","expected_pixels":pixels,"expected_RGBA_sha256":_digest(expected.get_data()),"actual_mask":_scalar_evidence(actual),"byte_exact":exact,"candidates":selected,"uses_production_mask_as_expected":false}

func observe(label: String) -> Dictionary:
	if not bind_original_pngs(): return {"valid":false,"reason":"original_imported_actual_alpha_bytes_binding"}
	var target: Sprite2D=prop("inn")
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D
	var helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	var container: Node2D=field.get("world_container") as Node2D
	var object: Dictionary={}
	for row: Dictionary in manifest.objects:
		if row.get("id")=="inn": object=row
	if target==null or helper==null or object.is_empty(): return {"valid":false}
	var depth: float=float(player.call("get_depth_sort_y"))
	var registered: Array=[]
	for row: Dictionary in helper.get("_props"):
		if String(row.get("id",""))=="inn":
			registered.append({"id":row.id,"same_actual_sprite":row.sprite==target,"foot_local":_native(row.foot_local),"global_foot":_native(target.to_global(row.foot_local)),"strict_behind":target.to_global(row.foot_local).y>depth})
	var order: Array=[]
	for row: Dictionary in helper.get("_depth_entries"):
		var node: Node2D=row.node as Node2D
		if node==player or node==target:
			order.append({"id":row.id,"same_actor":node==player,"same_prop":node==target,"ordinal":row.ordinal,"stored_band":row.band,"stored_foot_y":_native(row.foot_y),"z_index":node.z_index,"sibling_index":node.get_index()})
	var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
	var ghost: Sprite2D=player.get("_overlap_ghost") as Sprite2D
	var uniforms: Dictionary={}
	if ghost!=null and ghost.material is ShaderMaterial:
		var material: ShaderMaterial=ghost.material as ShaderMaterial
		for name: String in ["ghost_alpha","actor_local_rect","mask_flip","frame_mask"]: uniforms[name]=_scalar_evidence(material.get_shader_parameter(name))
	return {"valid":true,"label":label,"snapshot":_alpha_observation(target),"actual_root":_native(player.position),"actual_global_root":_native(player.global_position),"actor_depth":_native(depth),"visual_foot_offset":_native(depth-player.global_position.y),"actor_sprite_position":_native(actor.position),"actor_sprite_scale":_native(actor.scale),"actor_transform":_native(actor.global_transform),"prop_transform":_native(target.global_transform),"author_world_foot":_native(container.to_global(point(object.world_foot_px))),"registered_inn":registered,"depth_entries":order,"actual_actor_in_front":alpha.actual_in_front(player,target),"current_strong_alpha":png_alpha.call("strong_intersection",actor,target),"original_manifest_union_png":_union_png(debug,false),"registered_actual_foot_union_png":_union_png(debug,true),"original_probe_union":exact_union(debug),"ghost_sprite":_sprite_observation(ghost),"ghost_shader_uniforms":uniforms,"main_alpha":_native(actor.modulate.a*actor.self_modulate.a),"signature_native_hex":var_to_bytes(helper.get("_signature")).hex_encode(),"raw_full875_and17":raw_evidence(player.position),"actual_Physics_clear":physical_clear(player.position),"png_bindings":png_bindings.duplicate(true),"manual_refresh_or_sort_used":false}

func release() -> void:
	png_alpha.call("release"); png_alpha=null
	png_bindings.clear()
	super.release()

