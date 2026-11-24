extends Node2D
## New independent runtime presentation/physics overlay. Root must source-pin
## this candidate and import its sole new PNG before calling attach(). No hook.
const HOME := "res://build/luoyang_temple_adult_20261101d_art01/"
const SELF := HOME + "live_art_view.gd"
const BINDING := HOME + "art_binding_CANDIDATE.json"
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const NPC_SCRIPT := "res://scripts/field/npc_node.gd"
const OVERLAP_MATH_PATH := "res://scripts/world/v14_modular_overlap.gd"
const OverlapMath = preload("res://scripts/world/v14_modular_overlap.gd")
const TEMPLE := "luoyang_temple_region_27d"
const CIVIC := "luoyang_civic_market_region_27d"
const LOGICAL := "ch4_s3_luoyang_market"
const KEY := "ch4_s4_ancient_temple/finish_i_temple_east_sutra_house"
const OLD := "res://art/modules/luoyang_estate_components_20261021am/wing.png"
const PNG := "res://art/modules/city_navigation_20261101d/east_scripture_hall_v1.png"
const PNG_SHA := "8bda9590a12e3fb7cbab787a7095adc007c0ebca366ba1fcea87505467c15d90"
const GPU := "res://.godot/imported/east_scripture_hall_v1.png-57ce4b0788e554a3042d2bc600222dd7.ctex"
const NODE_NAME := "Quality20261101dArtView"
const QUAD_NAME := "Quality20261101dEastScriptureHall"
const META := "quality_20261101d_art"
const RATIO := 950.0 / 1499.0
const QUAD_POSITION := Vector2(2220,2850) - Vector2(832,818) * RATIO
const LEFT := 2220.0 + (104.0 - 768.0) * RATIO
const RIGHT := 2220.0 + (1433.0 - 768.0) * RATIO
const FRONT := 2850.0 + (866.0 - 754.0) * RATIO
const TARGET_HEIGHT := 132.0
const SOURCES := {
    "spar_luoyang_blademaster": "res://art/characters/npc_linxi_martial_hall_master_idle_down_25d_4f_v2_runtime.png",
    "luoyang_paper_scholar": "res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png",
    "spar_luoyang_examiner": "res://art/characters/street_expansion_v1/npc_wulin_examiner_idle_down_4f.png",
    "feng_yanqiu_ch4": "res://art/characters/street_expansion_v1/npc_wulin_examiner_idle_down_4f.png",
    "luoyang_poetry_host": "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png",
    "luoyang_armorer": "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
}
var _field_ref: WeakRef
var _prior_motion: Callable
var _region_bytes := PackedByteArray()
var _quad: Polygon2D
var _body_host: Node2D
var _old_sprite_ref: WeakRef
var _old_visible := true
var _committed := false
var _pixel_math: RefCounted = OverlapMath.new()
var _quad_image: Image
var _ghost_mask: Image
var _ghost_texture: ImageTexture
var _ghost_signature: Array = []
var _ghost_pixels := 0
var _owns_overlap := false
var _receipt: Dictionary = {}
var _error := ""
var _actor_before: Dictionary = {}
var _texture_heights: Dictionary = {}

static func source_paths() -> Array[String]:
    var paths: Array[String] = [SELF,BINDING,PNG,PNG + ".import",GPU,NPC_SCRIPT,OVERLAP_MATH_PATH,"res://scripts/field/player.gd"]
    for id: String in SOURCES:
        var path: String = SOURCES[id]
        if path in paths: continue
        paths.append(path); paths.append(path + ".import")
        var cfg := ConfigFile.new()
        if cfg.load(path + ".import") == OK:
            var gpu: String = String(cfg.get_value("remap","path",""))
            if not gpu.is_empty(): paths.append(gpu)
    return paths

static func overlay_rects() -> Array[Rect2]:
    return [Rect2(LEFT,2790,RIGHT-LEFT,30),Rect2(LEFT,2820,2170.087646484375-LEFT,FRONT-2820),Rect2(2269.91259765625,2820,RIGHT-2269.91259765625,FRONT-2820)]

static func mini_compiled_copy(original: Dictionary) -> Dictionary:
    var result: Dictionary = original.duplicate(true)
    if original.get("id") == TEMPLE:
        var filtered: Array = []
        for row: Dictionary in original.get("render",[]):
            if row.get("key") != KEY: filtered.append(row.duplicate(true))
        result["render"] = filtered
    return result

static func _failure(reason: String) -> Dictionary:
    return {"ok":false,"applied":false,"error":reason}

static func _field_ok(field: Node) -> bool:
    return is_instance_valid(field) and field.is_inside_tree() and field.get_script() != null and field.get_script().resource_path == FIELD and field.get("_field_loading_complete") == true and field.get("_field_loading_failed") != true and field.get("_scene_rebuilding") != true

static func _clear_at(foot: Vector2, half: Vector2 = Vector2(17,12)) -> bool:
    var body := Rect2(foot-half,half*2.0)
    for rectangle: Rect2 in overlay_rects():
        if body.intersects(rectangle): return false
    return true

static func attach(field: Node) -> Dictionary:
    if not _field_ok(field): return _failure("ART11D_EXACT_READY_FIELD")
    var region: Variant = field.get("_region")
    var scene: SceneScript = field.get("_current_scene") as SceneScript
    if not region is Dictionary or region.get("id") not in [TEMPLE,CIVIC] or scene == null or String(scene.scene_id) != region.id:
        return _failure("ART11D_EXACT_REGION_SCENE")
    var existing: Node = field.get_node_or_null(NodePath(NODE_NAME))
    if existing != null:
        if existing.get_script() == null or existing.get_script().resource_path != SELF: return _failure("ART11D_FOREIGN_HOST")
        return {"ok":true,"applied":false,"already_attached":true,"host":existing,"receipt":existing.call("receipt")}
    var binding: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDING))
    if not binding is Dictionary or binding.get("schema") != "LUOYANG_20261101D_ART_BINDING_V1" or binding.get("runtime_png_sha256") != PNG_SHA:
        return _failure("ART11D_BINDING_SCHEMA_OR_MEDIA")
    var host: Variant = load(SELF).new()
    host.name = NODE_NAME
    host.process_priority = 1000
    host._field_ref = weakref(field)
    host._region_bytes = var_to_bytes(region)
    host._receipt = {"region_id":region.id,"runtime_nav_overlay_only":region.id==TEMPLE,"compiled_unchanged":true,"migrated":false,"adult_ids":[],"source_binding_sha256":FileAccess.get_sha256(BINDING)}
    if region.id == TEMPLE:
        var prepared: Dictionary = host._prepare_temple(field,region)
        if prepared.get("ok") != true:
            host._rollback(field);host.free();return prepared
    field.add_child(host)
    if region.id == TEMPLE:
        var installed: Dictionary = host._commit_temple(field)
        if installed.get("ok") != true:
            host._rollback(field);host.free();return installed
    if region.id == CIVIC: host._apply_adults(field)
    if not host._error.is_empty():
        host.queue_free(); return _failure(host._error)
    field.set_meta(META,host.receipt())
    return {"ok":true,"applied":true,"host":host,"receipt":host.receipt()}

func _prepare_temple(field: Node, region: Dictionary) -> Dictionary:
    if region.get("size") != Vector2(3072,4608): return _failure("ART11D_TEMPLE_SIZE")
    var rows: Array = region.get("render",[]).filter(func(row: Dictionary) -> bool:return row.get("key")==KEY)
    if rows.size()!=1 or rows[0].get("texture")!=OLD or rows[0].get("position_px")!=Vector2(1851.6375732421875,2409.449951171875) or rows[0].get("scale")!=Vector2(0.4125000238418579,0.4125000238418579):
        return _failure("ART11D_ORIGINAL_WING_ROW")
    if region.get("solids",[]).size()<25: return _failure("ART11D_ORIGINAL_SOLIDS")
    var first := PackedVector2Array([Vector2(2033.96240234375,2804.625),Vector2(2170.087646484375,2804.625),Vector2(2170.087646484375,2850),Vector2(2033.96240234375,2850)])
    var second := PackedVector2Array([Vector2(2269.91259765625,2804.625),Vector2(2575.574951171875,2804.625),Vector2(2575.574951171875,2850),Vector2(2269.91259765625,2850)])
    if region.solids[23]!=first or region.solids[24]!=second: return _failure("ART11D_OLD_TWO_SOLIDS_EXACT")
    if FileAccess.get_sha256(PNG)!=PNG_SHA: return _failure("ART11D_PNG_SHA")
    var cfg := ConfigFile.new()
    if cfg.load(PNG+".import")!=OK or cfg.get_value("remap","path","")!=GPU or cfg.get_value("params","compress/mode",-1)!=0 or cfg.get_value("params","mipmaps/generate",true)!=false or cfg.get_value("params","process/fix_alpha_border",true)!=false or cfg.get_value("params","process/size_limit",-1)!=0:
        return _failure("ART11D_ROOT_EXACT_IMPORT_SPEC")
    var texture: Texture2D = load(PNG) as Texture2D
    if texture==null or texture.get_size()!=Vector2(1664,1152): return _failure("ART11D_NATIVE_TEXTURE_SIZE")
    var image: Image = texture.get_image()
    if image==null or image.get_used_rect()!=Rect2i(79,169,1506,799): return _failure("ART11D_GPU_ALPHA_BBOX")
    _quad_image=image
    # Validate external parents and any currently resident old chunk BEFORE
    # allocating/installing bodies, hiding art or changing the motion callable.
    var visual: Node2D=field.get("_visual_layer") as Node2D
    var collisions: Node2D=field.get("_collision_layer") as Node2D
    if visual==null or collisions==null or visual.global_transform!=Transform2D.IDENTITY or collisions.global_transform!=Transform2D.IDENTITY:
        return _failure("ART11D_NATIVE_WORLD_TRANSFORMS")
    if visual.get_node_or_null(NodePath(QUAD_NAME))!=null or collisions.get_node_or_null("Quality20261101dTempleOverlayBodies")!=null:
        return _failure("ART11D_FOREIGN_OWNED_NODE_NAMES")
    if not _validate_old(field): return _failure("ART11D_ORIGINAL_LIVE_WING")
    var player: Node2D = field.get("_player") as Node2D
    if player==null or not player.has_method("set_building_overlap") or player.get("sprite")==null or player.get("_overlap_ghost")==null:
        return _failure("ART11D_PLAYER_GHOST_API")
    _prior_motion=player.get("movement_constraint")
    if not _prior_motion.is_valid(): return _failure("ART11D_ORIGINAL_CALLABLE")
    var origin: Vector2=player.global_position
    var migration := false
    if not _clear_at(origin):
        if not bool(_prior_motion.call(origin)): return _failure("ART11D_NO_REPAIR_ORIGINAL_ILLEGAL_FOOT")
        if not bool(_prior_motion.call(Vector2(2220,2990))) or not _clear_at(Vector2(2220,2990)):
            return _failure("ART11D_EXACT_MIGRATION_TARGET_UNSAFE")
        migration=true
    var size: Vector2=texture.get_size()
    _quad=Polygon2D.new();_quad.name=QUAD_NAME;_quad.texture=texture
    _quad.polygon=PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)])
    _quad.uv=_quad.polygon.duplicate();_quad.scale=Vector2.ONE*RATIO;_quad.position=QUAD_POSITION
    _quad.z_as_relative=true;_quad.z_index=int(floor(FRONT/8.0));_quad.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    _quad.set_meta("quality11d_native_complete_building",true)
    _quad.set_meta("replaces_compiled_render_key",KEY)
    _body_host=Node2D.new();_body_host.name="Quality20261101dTempleOverlayBodies"
    for rectangle: Rect2 in overlay_rects():
        var body := StaticBody2D.new();body.collision_layer=1;body.collision_mask=0
        var shape := CollisionShape2D.new();var resource := RectangleShape2D.new()
        resource.size=rectangle.size;shape.shape=resource;shape.position=rectangle.get_center()
        body.add_child(shape);_body_host.add_child(body)
    _receipt["migrated"]=migration;_receipt["old_foot"]=origin
    _receipt["overlay_rects"]=overlay_rects();_receipt["quad_instance"]=_quad.get_instance_id()
    _receipt["body_host_instance"]=_body_host.get_instance_id();_receipt["old_solids_preserved"]=[23,24]
    if var_to_bytes(region)!=_region_bytes: return _failure("ART11D_COMPILED_CHANGED")
    return {"ok":true}

func _commit_temple(field: Node) -> Dictionary:
    # No awaits: all fallible external validation precedes this short commit.
    if not _field_ok(field) or not _validate_old(field) or var_to_bytes(field.get("_region"))!=_region_bytes:
        return _failure("ART11D_PRECOMMIT_DRIFT")
    var player: Node2D=field.get("_player") as Node2D
    if player==null or player.get("movement_constraint")!=_prior_motion or player.global_position!=_receipt.old_foot:
        return _failure("ART11D_PRECOMMIT_PLAYER_DRIFT")
    (field.get("_visual_layer") as Node2D).add_child(_quad)
    (field.get("_collision_layer") as Node2D).add_child(_body_host)
    player.call("set_movement_constraint",Callable(self,"_motion"))
    _committed=true
    if _receipt.migrated:
        player.global_position=Vector2(2220,2990)
        field.call("_snap_camera_to_player")
    if not _hide_old(field): return _failure("ART11D_COMMIT_OLD_OWNER_DRIFT")
    _receipt["new_foot"]=player.global_position
    _refresh_quad_overlap(field)
    return {"ok":true}

func _rollback(field: Node) -> void:
    _release_quad_overlap(field)
    if is_instance_valid(field):
        var player: Node2D=field.get("_player") as Node2D
        if player!=null and player.get("movement_constraint")==Callable(self,"_motion"):
            player.call("set_movement_constraint",_prior_motion)
            if _committed and _receipt.get("migrated",false):
                player.global_position=_receipt.old_foot
                field.call("_snap_camera_to_player")
    var old: Sprite2D=_old_sprite_ref.get_ref() as Sprite2D if _old_sprite_ref!=null else null
    if is_instance_valid(old): old.visible=_old_visible
    if is_instance_valid(_quad): _quad.free()
    if is_instance_valid(_body_host): _body_host.free()
    _quad=null;_body_host=null;_committed=false

func _validate_old(field: Node) -> bool:
    var visuals: Variant=field.get("_region_visuals")
    if not visuals is Dictionary: return false
    if not visuals.has(KEY): return true # The declared old chunk may be unloaded.
    var old: Sprite2D=visuals.get(KEY) as Sprite2D
    return is_instance_valid(old) and old.texture!=null and old.texture.resource_path==OLD and old.texture.get_size()==Vector2(2202,1289) and not old.centered and old.position==Vector2(1851.6375732421875,2409.449951171875) and old.scale==Vector2(0.4125000238418579,0.4125000238418579)

func _motion(next_global: Vector2) -> bool:
    if not _prior_motion.is_valid() or not bool(_prior_motion.call(next_global)): return false
    var field: Node=_field_ref.get_ref() as Node
    if not _field_ok(field): return false
    var player: Node2D=field.get("_player") as Node2D
    if player==null: return false
    var from: Vector2=player.global_position
    var swept := Rect2(Vector2(minf(from.x,next_global.x)-17,minf(from.y,next_global.y)-12),Vector2(absf(from.x-next_global.x)+34,absf(from.y-next_global.y)+24))
    for rectangle: Rect2 in overlay_rects():
        if swept.intersects(rectangle): return false
    return true

func _hide_old(field: Node) -> bool:
    if not _validate_old(field): return false
    var visuals: Variant=field.get("_region_visuals")
    var old: Sprite2D=visuals.get(KEY) as Sprite2D
    if old!=null:
        if _old_sprite_ref==null or _old_sprite_ref.get_ref()!=old:
            _old_sprite_ref=weakref(old);_old_visible=old.visible
        old.visible=false
    return true

func occlusion_sources() -> Array[CanvasItem]:
    var result: Array[CanvasItem]=[]
    if is_instance_valid(_quad): result.append(_quad)
    return result

func _release_quad_overlap(field: Node) -> void:
    if not _owns_overlap or not is_instance_valid(field): return
    var player: Player=field.get("_player") as Player
    if player!=null:
        var material: ShaderMaterial=player.get("_frame_overlap_material") as ShaderMaterial
        # Do not clear a fresher overlap mask supplied by another owner.
        if material!=null and material.get_shader_parameter("frame_mask")==_ghost_texture:
            player.set_building_overlap(false,.42,true)
    _owns_overlap=false;_ghost_pixels=0;_ghost_signature.clear()

func _refresh_quad_overlap(field: Node) -> void:
    var player: Player=field.get("_player") as Player
    if player==null or player.sprite==null or player.sprite.texture==null or not is_instance_valid(_quad): return
    var actor: Sprite2D=player.sprite
    var actor_z: int=_pixel_math.call("effective_z",actor)
    var quad_z: int=_pixel_math.call("effective_z",_quad)
    var quad_bounds:=Rect2(_quad.to_global(Vector2.ZERO),_quad.texture.get_size()*_quad.scale)
    var actor_bounds: Rect2=_pixel_math.call("_world_bounds",actor)
    if not _quad.is_visible_in_tree() or quad_z<=actor_z or player.get_depth_sort_y()>=FRONT or not quad_bounds.intersects(actor_bounds):
        _release_quad_overlap(field);return
    var signature: Array=[actor.texture.get_instance_id(),actor.frame,actor.hframes,actor.vframes,actor.region_rect,actor.region_enabled,actor.global_transform,actor.flip_h,actor.flip_v,actor_z,_quad.global_transform,quad_z]
    var current_material: ShaderMaterial=player.get("_frame_overlap_material") as ShaderMaterial
    var current_ghost: Sprite2D=player.get("_overlap_ghost") as Sprite2D
    if signature==_ghost_signature and _owns_overlap and current_material!=null and current_material.get_shader_parameter("frame_mask")==_ghost_texture and current_ghost!=null and current_ghost.visible: return
    _ghost_signature=signature
    var image: Image=_pixel_math.call("_image",actor.texture)
    if image==null: _release_quad_overlap(field);return
    var frame: Rect2i=_pixel_math.call("_frame_rect",actor,image)
    var rect: Rect2=actor.get_rect()
    if frame.size.x<=0 or frame.size.y<=0: _release_quad_overlap(field);return
    if _ghost_mask==null or _ghost_mask.get_size()!=frame.size:
        _ghost_mask=Image.create(frame.size.x,frame.size.y,false,Image.FORMAT_RGBA8)
        _ghost_texture=ImageTexture.create_from_image(_ghost_mask)
    _ghost_mask.fill(Color(0,0,0,0));_ghost_pixels=0
    for y: int in frame.size.y:
        for x: int in frame.size.x:
            if image.get_pixel(frame.position.x+x,frame.position.y+y).a<=0: continue
            var uv: Vector2=(Vector2(x,y)+Vector2(.5,.5))/Vector2(frame.size)
            if actor.flip_h: uv.x=1.0-uv.x
            if actor.flip_v: uv.y=1.0-uv.y
            var world: Vector2=actor.to_global(rect.position+uv*rect.size)
            var local: Vector2=_quad.to_local(world)
            if local.x<0 or local.y<0 or local.x>=_quad_image.get_width() or local.y>=_quad_image.get_height(): continue
            var alpha: float=_pixel_math.call("_linear_alpha",_quad_image,local-Vector2(.5,.5))
            if alpha<=0: continue
            _ghost_mask.set_pixel(x,y,Color(1,1,1,alpha));_ghost_pixels+=1
    if _ghost_pixels==0: _release_quad_overlap(field);return
    _ghost_texture.update(_ghost_mask)
    # Reuse the current Player same-frame ghost/mask API; architecture alpha and
    # the original actor z never change. Only overlapping live actor pixels42%.
    player.set_building_overlap(true,.42,true,{"space":"actor_frame","texture":_ghost_texture,"actor_rect":rect,"flip":Vector2(1 if actor.flip_h else 0,1 if actor.flip_v else 0),"ghost_z":maxi(450,quad_z+1)})
    _owns_overlap=true

func _actor_state(npc: NPCNode) -> Dictionary:
    var body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
    var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D if body!=null and body.get_child_count()==1 else null
    if shape==null or not shape.shape is RectangleShape2D: return {}
    return {"node":npc.get_instance_id(),"position":npc.position,"transform":npc.transform,"body":body.get_instance_id(),"body_transform":body.transform,"shape":shape.get_instance_id(),"shape_transform":shape.transform,"shape_size":(shape.shape as RectangleShape2D).size,"layer":body.collision_layer,"mask":body.collision_mask,"dialog_id":npc.dialog_id,"action":npc.interaction_action,"variants":npc.dialog_variants.duplicate(true),"portrait":npc.portrait_path,"source":npc.sprite_path,"movement_mode":npc.movement_mode,"processing":npc.is_processing()}

func _apply_adults(field: Node) -> void:
    var actors: Variant=field.get("_region_actors")
    if not actors is Dictionary: _error="ART11D_ACTOR_TABLE";return
    for id: String in SOURCES:
        var key: String=LOGICAL+"/"+id
        if not actors.has(key): continue # Original flags may hide scholar/plot adult.
        var npc: NPCNode=actors[key].get("node") as NPCNode
        if not is_instance_valid(npc) or npc.get_script().resource_path!=NPC_SCRIPT or npc.npc_id!=id or npc.get_meta("region27d_slot_key","")!=key or npc.get_meta("region27d_logical_id","")!=LOGICAL or npc.sprite_path!=SOURCES[id] or npc.movement_mode!="idle" or npc.get("_ground_anchored")!=true or npc.sprite==null or npc.sprite.texture==null:
            _error="ART11D_EXACT_STANDING_ADULT:"+id;return
        var before: Dictionary=_actor_state(npc)
        if before.is_empty(): _error="ART11D_ADULT_ORIGINAL_BODY:"+id;return
        var token: int=npc.get_instance_id()
        if not _actor_before.has(token): _actor_before[token]=before.duplicate(true)
        # Display-only calibration properties; body was already created and is
        # never recreated. Existing NPCNode then preserves scale on begin/end
        # conversation and original directional swaps. No process suppression.
        npc.set("_calibrate_adult_body",true)
        npc.sprite_scale=TARGET_HEIGHT/140.0
        npc.call("_apply_sprite_scale")
        npc.call("_sync_ground_anchor")
        if _actor_state(npc)!=before: _error="ART11D_ADULT_BODY_OR_BUSINESS_CHANGED:"+id;return
        if id not in _receipt.adult_ids: _receipt.adult_ids.append(id)

func _process(_delta: float) -> void:
    var field: Node=_field_ref.get_ref() as Node if _field_ref!=null else null
    if not _field_ok(field) or not _error.is_empty(): return
    if _receipt.get("region_id")==TEMPLE:
        if not _hide_old(field):
            _error="ART11D_FOREIGN_RECREATED_OWNER";_rollback(field);return
        _refresh_quad_overlap(field)
    else: _apply_adults(field)

func receipt() -> Dictionary:
    var result: Dictionary=_receipt.duplicate(true)
    result["error"]=_error
    result["new_quad_ghost_pixels"]=_ghost_pixels
    result["new_quad_ghost_alpha"]=.42
    result["new_quad_ghost_uses_original_player_api"]=true
    var field: Node=_field_ref.get_ref() as Node if _field_ref!=null else null
    result["compiled_unchanged"]=is_instance_valid(field) and var_to_bytes(field.get("_region"))==_region_bytes
    return result
