"""NEW build-only visual successor; no Godot, images or canonical writes."""
from pathlib import Path
import hashlib, json, math

ROOT = Path(__file__).resolve().parent
GAME = ROOT.parent.parent
OUT = ROOT / "visual_transition_successor02"
OUT.mkdir(exist_ok=True)
def sha(b): return hashlib.sha256(b).hexdigest()
def rp(p): return "res://" + str(p.relative_to(GAME)).replace("\\", "/")
def emit(name, data):
    path = OUT / name
    assert not path.exists(), path
    path.write_bytes(data)
    return {"path":rp(path), "sha256":sha(data), "bytes":len(data)}
def patch(data, old, new, edits):
    old, new = old.encode(), new.encode()
    assert data.count(old)==1, old[:120]
    edits.append({"old":old.decode(),"new":new.decode()})
    return data.replace(old,new,1)

old_shader = ROOT / "environment_rect_transition_candidate.gdshader"
shader = old_shader.read_bytes()
assert sha(shader)=="da5141e484f7401669bbf9a0c3b36c402a2a88778551a8a4d008bb47afb4aacd"
needle=b"\tCOLOR = texture(TEXTURE, UV) * COLOR;\n"
assert shader.count(needle)==1
new_shader=shader.replace(needle,b"\t// Godot 4 fragment COLOR already includes the default texture once.\n",1)
shader_row=emit("environment_rect_color_once_READY.gdshader",new_shader)

proposal_path=ROOT / "artisan_ground_union_boundary_visual_proposal_READY.json"
proposal=json.loads(proposal_path.read_text(encoding="utf-8"))
assert sha(proposal_path.read_bytes())=="17468578d164f42a713aaae7eb0688eb779f40661b94b03b7774c939b19c5b15"
segments=proposal["exterior_union_segments_only"]
assert len(segments)==32
union_shader=b'''shader_type canvas_item;
// Fixed exterior union, never a repeated tile or individual section boundary.
uniform vec4 ap_union_segments[32];
uniform vec2 ap_sprite_design_origin = vec2(0.0);
uniform vec2 ap_sprite_source_to_design = vec2(1.0);
varying vec2 ap_design_position;
void vertex() {
    ap_design_position = ap_sprite_design_origin + VERTEX * ap_sprite_source_to_design;
}
float ap_segment_squared(vec2 point, vec4 segment) {
    vec2 line = segment.zw - segment.xy;
    float along = clamp(dot(point - segment.xy, line) / max(dot(line, line), 0.0001), 0.0, 1.0);
    vec2 offset = point - (segment.xy + along * line);
    return dot(offset, offset);
}
void fragment() {
    float nearest_squared = 100000000.0;
    for (int index = 0; index < 32; index++) {
        nearest_squared = min(nearest_squared, ap_segment_squared(ap_design_position, ap_union_segments[index]));
    }
    // Preserve the original texture/modulate/core; no second texture sample.
    COLOR.a *= smoothstep(0.0, 32.0, sqrt(nearest_squared));
}
'''
union_row=emit("artisan_ground_union_exterior_READY.gdshader",union_shader)

parent_path=ROOT / "environment_compatible_stone_candidate01/environment_compatible_stone_READY.gd"
parent=parent_path.read_bytes()
assert sha(parent)=="dea0c73dcf34b565195c492227a90d8c2fd10e49e657f86ffa862ccdf2483948"
data=parent; edits=[]
data=patch(data,'const RECT_TRANSITION_SHADER="'+rp(old_shader)+'"','const RECT_TRANSITION_SHADER="'+shader_row['path']+'"',edits)
data=patch(data,'const RECT_TRANSITION_SHADER_SHA="'+sha(shader)+'"','const RECT_TRANSITION_SHADER_SHA="'+shader_row['sha256']+'"\nconst ARTISAN_UNION_SHADER="'+union_row['path']+'"\nconst ARTISAN_UNION_SHADER_SHA="'+union_row['sha256']+'"',edits)
data=patch(data,'\t# The small per-release author owns all four shared materials.','\tif id==&"luoyang_artisan_residential_20261022ap": out[ARTISAN_UNION_SHADER]=true\n\t# The small per-release author owns all four shared materials.',edits)
data=patch(data,'\tsource_pins[RECT_TRANSITION_SHADER]=RECT_TRANSITION_SHADER_SHA','\tsource_pins[RECT_TRANSITION_SHADER]=RECT_TRANSITION_SHADER_SHA\n\tif scene.scene_id==&"luoyang_artisan_residential_20261022ap": source_pins[ARTISAN_UNION_SHADER]=ARTISAN_UNION_SHADER_SHA',edits)
data=patch(data,'\tvar source_final: Dictionary={}\n','\tvar artisan_union: Dictionary={}\n\tif scene.scene_id==&"luoyang_artisan_residential_20261022ap":\n\t\tartisan_union=attach_artisan_union_transition(field,scene,world_size,owner)\n\t\tif artisan_union.get("ok")!=true: layer.free();return artisan_union\n\tvar source_final: Dictionary={}\n',edits)
data=patch(data,'\tif scene.scene_id==&"ch4_s3_luoyang_market":\n\t\tvar attached: Dictionary=attach_pawn_sign','\tif not artisan_union.is_empty(): receipt["artisan_union_visual_only"]=artisan_union\n\tif scene.scene_id==&"ch4_s3_luoyang_market":\n\t\tvar attached: Dictionary=attach_pawn_sign',edits)

# Reproduce only the immutable publisher's tile names/positions/sizes/source paths.
author_path=ROOT / "artisan_revision4/author_READY.json"
author=json.loads(author_path.read_text(encoding="utf-8"))
scene=author["scenes"]["luoyang_artisan_residential_20261022ap"]
tile_specs=[]
for section in proposal["preserved_nine_sections"]:
    original=next(s for s in scene["ground_sections"] if s["id"]==section["id"])
    assert all(original[k]==section[k] for k in ["id","rect","tile_size","z"])
    asset=author["assets"][original["asset"]]
    x,y,w,h=section["rect"]; tw,th=section["tile_size"]
    scale=tw/asset["source_size"][0]
    assert scale==th/asset["source_size"][1]
    for iy in range(math.ceil(h/th)):
        for ix in range(math.ceil(w/tw)):
            sw,sh=min(w-ix*tw,tw),min(h-iy*th,th)
            texture=asset["texture"] if (sw,sh)==(tw,th) else original["clip_textures"][f"{int(sw/scale)}x{int(sh/scale)}"]
            tile_specs.append([f"SceneObject_{section['id']}_{ix}_{iy}",texture,[x+ix*tw+sw/2,y+iy*th+sh/2],[sw,sh],section["z"]])

literal=json.dumps(tile_specs,separators=(",",":"))
seg_literal=",".join("Vector4(%s)" % ",".join(str(v) for v in s["from"]+s["to"]) for s in segments)
function='''

static func attach_artisan_union_transition(field: Node,scene: SceneScript,world_size: Vector2,owner: Callable) -> Dictionary:
\tif scene.scene_id!=&"luoyang_artisan_residential_20261022ap" or world_size!=SIZE or not owner.call(): return fail("AP_UNION_EXACT_ARTISAN_WORLD")
\tvar visual: Node2D=field.get("_visual_layer") as Node2D
\tif not is_instance_valid(visual): return fail("AP_UNION_VISUAL_LAYER")
\tvar shader: Shader=ResourceLoader.load(ARTISAN_UNION_SHADER) as Shader
\tif shader==null or shader.resource_path!=ARTISAN_UNION_SHADER: return fail("AP_UNION_EXACT_SHADER")
\tvar specifications: Array=SPECIFICATIONS
\tvar prepared: Array[Dictionary]=[]
\tvar segments:=PackedVector4Array([SEGMENTS])
\tfor row: Array in specifications:
\t\tvar found: Array[Sprite2D]=[]
\t\tfor child: Node in visual.get_children():
\t\t\tif child is Sprite2D and String(child.name)==row[0]: found.append(child as Sprite2D)
\t\tif found.size()!=1: return fail("AP_UNION_EXACT_NATIVE_TILE",row[0])
\t\tvar sprite: Sprite2D=found[0]
\t\tvar source_size: Vector2=sprite.texture.get_size() if sprite.texture!=null else Vector2.ZERO
\t\tvar native_pos: Vector2=(Vector2(row[2][0],row[2][1])/SIZE)*SIZE
\t\tvar native_size:=Vector2(row[3][0],row[3][1])
\t\tif sprite.texture==null or sprite.texture.resource_path!=row[1] or not sprite.centered or sprite.position!=native_pos or sprite.scale!=native_size/source_size or sprite.rotation!=0.0 or sprite.z_index!=row[4] or sprite.material!=null: return fail("AP_UNION_NATIVE_SOURCE_TRANSFORM",row[0])
\t\tvar material:=ShaderMaterial.new();material.shader=shader
\t\tmaterial.set_shader_parameter("ap_union_segments",segments)
\t\tmaterial.set_shader_parameter("ap_sprite_design_origin",sprite.position)
\t\tmaterial.set_shader_parameter("ap_sprite_source_to_design",sprite.scale)
\t\tprepared.append({"sprite":sprite,"material":material})
\tif not owner.call(): return fail("AP_UNION_CANCELLED_BEFORE_ATTACH")
\tfor row: Dictionary in prepared:
\t\tvar sprite: Sprite2D=row.sprite
\t\tsprite.material=row.material
\t\tsprite.set_meta("ap_union_exterior_transition",{"segment_count":32,"feather_world":32.0,"core_opacity":1.0,"native_transform_and_texture_unchanged":true,"no_tile_or_interior_section_seams":true})
\treturn {"ok":true,"native_tile_count":prepared.size(),"source_sections":9,"exterior_segments":32,"feather_world":32.0,"core_opacity":1.0,"visual_only":true,"no_native_geometry_delta":true}
'''.replace("SPECIFICATIONS",literal).replace("SEGMENTS",seg_literal)
data=patch(data,'\n\nstatic func attach_pawn_sign(',function+'\n\nstatic func attach_pawn_sign(',edits)
inverse=data
for e in reversed(edits):
    assert inverse.count(e["new"].encode())==1
    inverse=inverse.replace(e["new"].encode(),e["old"].encode(),1)
assert inverse==parent
helper_row=emit("environment_visual_transition_READY.gd",data)
receipt={"status":"NEW_BUILD_ONLY_NO_ENGINE_NO_DEPLOY_NO_ART_PASS","parent":{"path":rp(parent_path),"sha256":sha(parent)},"helper":helper_row,"rect_shader":shader_row,"union_shader":union_row,"author":{"path":rp(author_path),"sha256":sha(author_path.read_bytes())},"proposal":{"path":rp(proposal_path),"sha256":sha(proposal_path.read_bytes())},"native_tile_count":len(tile_specs),"sections":9,"segments":32,"feather_world":32,"whole_byte_inverse":inverse==parent,"edits":edits,"shader_parent_inverse":{"old_sha256":sha(shader),"new_sha256":sha(new_shader),"old":needle.decode(),"new":"\t// Godot 4 fragment COLOR already includes the default texture once.\n"},"official_contract":{"url":"https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html#color-and-texture","fact":"fragment input COLOR already equals vertex COLOR multiplied by default TEXTURE; only COLOR.a changed by both successor shaders","checked":"2026-10-22"},"preserved":["all native scenes/layout/packet/mask/solid/portal/route/NPC/34x24 bodies","original nine ground sections, all Atlas sources and transforms","rect core opacity .66 except pawn forecourt1; whole-alpha stamps","no image generation/processing/import; no per-frame CPU or animated shader"],"not_admitted":["Godot shader compilation","same-camera visual comparison","full city ART","source closure or deployment"]}
receipt_row=emit("handoff_READY.json",(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n").encode())
print(json.dumps({"helper":helper_row,"rect_shader":shader_row,"union_shader":union_row,"receipt":receipt_row,"native_tiles":len(tile_specs)},indent=2))
