extends RefCounted
## Independent six-roof proof, not a search-miss waiver or Field approval.
## Behind/input/875+17/Physics/Y/union checks remain the caller's obligations.
const PATCH := "res://art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/art_patch.json"
const PATCH_SHA := "2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4"
const PLAYER := "res://scripts/field/player.gd"
const PLAYER_SHA := "9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419"
const ROOT := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/"
const IDS: Array[String] = ["v11_yamen_west_south_1520","v11_yamen_west_south_1360","v11_yamen_west_north_780","v11_yamen_east_south_1520","v11_yamen_east_south_1360","v11_yamen_east_north_780"]
var sources: Dictionary = {}
var inventory: Array[Dictionary] = []
var records: Dictionary = {}

func _file(path: String) -> Dictionary:
	var f := FileAccess.open(path,FileAccess.READ)
	return {"exists":f!=null,"bytes":f.get_length() if f!=null else 0,"sha256":FileAccess.get_sha256(path) if f!=null else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if f!=null else 0}
func _track(path: String) -> bool:
	var value: Dictionary=_file(path)
	if not value.exists or (sources.has(path) and sources[path]!=value): return false
	sources[path]=value
	return true
func unchanged() -> bool:
	for path: String in sources:
		if sources[path]!=_file(path): return false
	return true
func _rgba(image: Image) -> Image:
	if image==null: return null
	var owned: Image=image.duplicate() as Image
	if owned.is_compressed() and owned.decompress()!=OK: return null
	owned.convert(Image.FORMAT_RGBA8)
	return owned
func _import(path: String) -> Texture2D:
	if not _track(path) or not _track(path+".import"): return null
	var config:=ConfigFile.new()
	if config.load(path+".import")!=OK: return null
	var compiled: Variant=config.get_value("remap","path",null)
	if typeof(compiled)!=TYPE_STRING or not _track(compiled): return null
	return ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
func _point(value: Variant) -> Vector2:
	if not value is Array or value.size()!=2: return Vector2(INF,INF)
	for n: Variant in value:
		if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(n)): return Vector2(INF,INF)
	return Vector2(value[0],value[1])

func rgba_pair_exact(original: Image,actual: Image) -> bool:
	return original!=null and actual!=null and not original.is_compressed() and not actual.is_compressed() and original.get_format()==Image.FORMAT_RGBA8 and actual.get_format()==Image.FORMAT_RGBA8 and original.get_size()==actual.get_size() and original.get_data()==actual.get_data()

func prepare() -> bool:
	release()
	if not _track(PATCH) or not _track(PLAYER) or sources[PATCH].sha256!=PATCH_SHA or sources[PLAYER].sha256!=PLAYER_SHA: return false
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATCH))!=OK or not parser.data is Dictionary: return false
	var patch: Dictionary=parser.data
	if not patch.get("objects") is Array or not patch.get("asset_sha256") is Dictionary: return false
	for row: Variant in patch.objects:
		if not row is Dictionary or typeof(row.get("id"))!=TYPE_STRING: return false
		if row.id not in IDS: continue
		if records.has(row.id) or typeof(row.get("texture"))!=TYPE_STRING: return false
		var path: String=PATCH.get_base_dir()+"/entities/"+row.id+".png"
		var digest: Variant=patch.asset_sha256.get(path)
		if row.texture!=path or typeof(digest)!=TYPE_STRING or not _track(path) or sources[path].sha256!=digest: return false
		if _import(path)==null: return false
		if not _point(row.get("render_size_px")).is_finite() or not _point(row.get("world_foot_px")).is_finite() or not _point(row.get("foot_uv")).is_finite(): return false
		records[row.id]=row.duplicate(true)
	if records.size()!=6: return false
	for family: String in ["sword","dao","staff","palm","hidden"]:
		for state: String in ["idle","walk"]:
			var frames: int=4 if state=="idle" else 8
			for direction: String in ["up","down","left","right"]:
				var path: String=ROOT+family+"/lengguyun_"+family+"_"+state+"_"+direction+"_25d_"+str(frames)+"f.png"
				var texture: Texture2D=_import(path)
				var original: Image=_rgba(Image.load_from_file(path))
				var actual: Image=_rgba(texture.get_image()) if texture!=null else null
				if original==null or actual==null or original.get_size()!=Vector2i(frames*160,160) or actual.get_size()!=original.get_size(): return false
				# Actor imports may fix RGB edges. FULLdrawrect includes every pixel;
				# record the difference, never substitute source alpha for its rectangle.
				inventory.append({"path":path,"family":family,"state":state,"direction":direction,"hframes":frames,"size":original.get_size(),"source_import_RGBA_exact":original.get_data()==actual.get_data(),"full_drawrect":Rect2(-80,-80,160,160),"frame_count":frames})
	return inventory_valid(inventory) and unchanged()

func inventory_valid(rows: Variant) -> bool:
	if not rows is Array or rows.size()!=40: return false
	var seen: Dictionary={}; var total:=0
	for row: Variant in rows:
		if not row is Dictionary: return false
		for key: String in ["family","state","direction","path"]:
			if typeof(row.get(key))!=TYPE_STRING: return false
		if row.family not in ["sword","dao","staff","palm","hidden"] or row.state not in ["idle","walk"] or row.direction not in ["up","down","left","right"]: return false
		var n: int=4 if row.state=="idle" else 8
		var path: String=ROOT+row.family+"/lengguyun_"+row.family+"_"+row.state+"_"+row.direction+"_25d_"+str(n)+"f.png"
		if row.path!=path or seen.has(path) or typeof(row.get("hframes"))!=TYPE_INT or row.hframes!=n or typeof(row.get("frame_count"))!=TYPE_INT or row.frame_count!=n or typeof(row.get("size"))!=TYPE_VECTOR2I or row.size!=Vector2i(n*160,160) or typeof(row.get("full_drawrect"))!=TYPE_RECT2 or row.full_drawrect!=Rect2(-80,-80,160,160): return false
		seen[path]=true; total+=n
	return total==240

func actor_bound(actor: Sprite2D,depth_foot: float,visual_scale: float,ground_anchored: bool) -> Dictionary:
	if actor==null or actor.texture==null or not inventory_valid(inventory) or not is_finite(depth_foot) or not is_finite(visual_scale) or visual_scale<=0. or not ground_anchored: return {}
	var member: Dictionary={}
	for row: Dictionary in inventory:
		if row.path==actor.texture.resource_path: member=row
	if member.is_empty() or actor.hframes!=member.hframes or actor.vframes!=1 or actor.frame<0 or actor.frame>=member.hframes: return {}
	var scale_value: float=.945*visual_scale
	if not is_finite(scale_value) or actor.scale!=Vector2.ONE*scale_value or not actor.centered or actor.region_enabled or actor.rotation!=0. or actor.offset!=Vector2.ZERO or actor.position!=Vector2(0.,-160.*actor.scale.y*.45) or actor.get_rect()!=Rect2(-80,-80,160,160): return {}
	var parent: Node2D=actor.get_parent() as Node2D
	if parent==null or parent.rotation!=0. or parent.scale!=Vector2.ONE: return {}
	var expected_foot: float=parent.global_position.y+actor.position.y+actor.texture.get_height()*actor.scale.y*.45
	if expected_foot!=depth_foot: return {}
	var t: Transform2D=actor.global_transform
	if not t.x.is_finite() or not t.y.is_finite() or not t.origin.is_finite() or t.x.y!=0. or t.y.x!=0.: return {}
	var minimum:=INF
	for p: Vector2 in [Vector2(-80,-80),Vector2(80,-80),Vector2(80,80),Vector2(-80,80)]:
		var q: Vector2=t*p
		if not q.is_finite(): return {}
		minimum=minf(minimum,float(q.y)-depth_foot)
	if not is_finite(minimum): return {}
	return {"minimum_relative_y":minimum,"strip_count":40,"frame_count":240,"actual_texture":actor.texture.resource_path,"domain":"ALL_240_FULL_DRAWRECTS_ALL_XY_TRANSLATIONS"}

func support_gap(image: Image,rect: Rect2,transform: Transform2D,flip_h: bool,flip_v: bool,actor_minimum_relative_y: float,prop_depth_foot: float) -> Dictionary:
	# This is the actual production-facing proof core. Tests call it with owned
	# mutations; no bbox metadata, alpha threshold or coarse-search result exists.
	if image==null or image.is_compressed() or image.get_format()!=Image.FORMAT_RGBA8 or image.get_width()<=0 or image.get_height()<=0 or not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x<=0. or rect.size.y<=0. or not transform.x.is_finite() or not transform.y.is_finite() or not transform.origin.is_finite() or transform.determinant()==0. or not is_finite(transform.determinant()) or not is_finite(actor_minimum_relative_y) or actor_minimum_relative_y>=0. or not is_finite(prop_depth_foot): return {}
	var ymax: float=-INF; var count:=0; var minrow:=image.get_height(); var maxrow:=-1
	var support_min:=Vector2(INF,INF); var support_max:=Vector2(-INF,-INF)
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x,y).a<=0.: continue
			count+=1
			minrow=mini(minrow,y); maxrow=maxi(maxrow,y)
			# Bilinear samples use uv*size-.5, and can read a positive texel when
			# that coordinate is within one texel. A closed conservative envelope
			# is [x-.5,x+1.5] in uv*size, including even alpha=1/255.
			for p: Vector2 in [Vector2(x-.5,y-.5),Vector2(x+1.5,y-.5),Vector2(x+1.5,y+1.5),Vector2(x-.5,y+1.5)]:
				var uv: Vector2=p/Vector2(image.get_size())
				if flip_h: uv.x=1.-uv.x
				if flip_v: uv.y=1.-uv.y
				var world: Vector2=transform*(rect.position+uv*rect.size)
				if not world.is_finite(): return {}
				support_min=support_min.min(world); support_max=support_max.max(world)
				ymax=maxf(ymax,world.y)
	if count==0 or not is_finite(ymax): return {}
	# ALL F>=propFoot is a superset of original front F>propFoot+.01.
	# Every possible actor strong sample is inside its FULLdrawrect, so a
	# strictly positive vertical gap proves absence regardless of X or frame.
	var lower: float=prop_depth_foot+actor_minimum_relative_y
	var gap: float=lower-ymax
	if not is_finite(lower) or not is_finite(gap): return {}
	var hash:=HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(image.get_data())
	return {"proved":gap>0.,"gap_world_px":gap,"prop_positive_pixels":count,"source_positive_min_row":minrow,"source_positive_max_row":maxrow,"full_RGBA_sha256":hash.finish().hex_encode(),"transformed_support_min":support_min,"transformed_support_max":support_max,"prop_bilinear_support_max_y":ymax,"all_front_actor_min_y":lower,"zero_gap_is_NOT_PROVEN":true,"metadata_used":false,"search_miss_used":false,"front_domain":"F>=propFoot; all X; all240 complete frames","collision_or_input_approval":false}

func prove_actual(id: String,prop: Sprite2D,actor: Sprite2D,actor_depth_foot: float,prop_depth_foot: float,visual_scale: float,ground_anchored: bool) -> Dictionary:
	if id not in IDS or not records.has(id) or prop==null or prop.texture==null or not unchanged(): return {}
	var row: Dictionary=records[id]
	if prop.texture.resource_path!=row.texture or not prop.centered or prop.offset!=Vector2.ZERO or prop.region_enabled or prop.hframes!=1 or prop.vframes!=1 or prop.frame!=0 or prop.rotation!=0. or prop.scale!=Vector2.ONE or prop.texture_filter!=CanvasItem.TEXTURE_FILTER_LINEAR or prop.modulate.a!=1. or prop.self_modulate.a!=1.: return {}
	var render: Vector2=_point(row.render_size_px); var foot: Vector2=_point(row.world_foot_px); var uv: Vector2=_point(row.foot_uv)
	var center: Vector2=(foot+(Vector2(.5,.5)-uv)*render)/Vector2(3072,2048)
	if not center.is_finite() or prop.position!=center*Vector2(3072,2048): return {}
	var container: Node2D=prop.get_parent() as Node2D
	if container==null or actor==null or actor.get_parent()==null or actor.get_parent().get_parent()!=container or container.global_transform.x!=Vector2.RIGHT or container.global_transform.y!=Vector2.DOWN or not container.global_transform.origin.is_finite() or prop_depth_foot!=container.to_global(foot).y: return {}
	var texture: Texture2D=_import(row.texture)
	var original: Image=_rgba(Image.load_from_file(row.texture))
	var imported: Image=_rgba(prop.texture.get_image())
	var independent_import: Image=_rgba(texture.get_image()) if texture!=null else null
	if original==null or original.get_size()!=Vector2i(render) or not rgba_pair_exact(original,imported) or not rgba_pair_exact(original,independent_import): return {}
	var bound: Dictionary=actor_bound(actor,actor_depth_foot,visual_scale,ground_anchored)
	if bound.is_empty(): return {}
	var result: Dictionary=support_gap(imported,prop.get_rect(),prop.global_transform,prop.flip_h,prop.flip_v,bound.minimum_relative_y,prop_depth_foot)
	if result.is_empty(): return {}
	result.merge({"id":id,"source_png":row.texture,"source_sha256":sources[row.texture].sha256,"source_import_all_RGBA_exact":true,"actor":bound,"strict_six_roof_identity":true,"source_unchanged":unchanged(),"actual_Field_credit":false})
	return result if result.source_unchanged else {}

func release() -> void:
	sources.clear(); inventory.clear(); records.clear()
