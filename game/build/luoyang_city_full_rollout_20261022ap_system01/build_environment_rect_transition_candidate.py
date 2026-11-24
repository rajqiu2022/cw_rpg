"""Root-approved NEW finite visual candidate; never deploy or invoke Godot."""
from pathlib import Path
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def ref(p):return "res://"+p.relative_to(GAME).as_posix()
parent=GAME/"scripts/city/luoyang_environment_layer_20261022ap.gd"
author=GAME/"data/maps/luoyang_full_city_20261022ap/environment.json"
assert sha(parent)=="9038c896e742d53b0ff4042c0977c8a5cd0713376b52bf29ed3543001154de59"
assert sha(author)=="5a9994d84b4a2adf6d8e02048fce236bd433d6b163b1aaec5cdb8ea992cbc98f"
shader=HERE/"environment_rect_transition_candidate.gdshader"
data=parent.read_bytes(); eol=b"\r\n" if b"\r\n" in data else b"\n"
def lines(s):return s.replace("\n",eol.decode()).encode()
changes=[
 ('const Z=-4', 'const Z=-4\nconst RECT_TRANSITION_SHADER="'+ref(shader)+'"\nconst RECT_TRANSITION_SHADER_SHA="'+sha(shader)+'"'),
 ('var out: Dictionary={SELF:true,INDEX:true,AUTHOR:true}', 'var out: Dictionary={SELF:true,INDEX:true,AUTHOR:true,RECT_TRANSITION_SHADER:true}'),
 ('var source_first: Dictionary={};var textures: Dictionary={};var source_pins: Dictionary=data.source_sha256.duplicate()',
  'var source_first: Dictionary={};var textures: Dictionary={};var source_pins: Dictionary=data.source_sha256.duplicate()\n\tsource_pins[RECT_TRANSITION_SHADER]=RECT_TRANSITION_SHADER_SHA'),
 ('var layer:=Node2D.new();layer.name=NAME;layer.z_index=Z',
  'var rect_transition: Shader=ResourceLoader.load(RECT_TRANSITION_SHADER) as Shader\n\tif rect_transition==null or rect_transition.resource_path!=RECT_TRANSITION_SHADER: return fail("AP_ENVIRONMENT_EXACT_RECT_SHADER")\n\tvar layer:=Node2D.new();layer.name=NAME;layer.z_index=Z'),
 ('sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2.ZERO,area.size/float(row.uniform_scale));sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED',
  'sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2.ZERO,area.size/float(row.uniform_scale));sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED\n\t\t\t# Whole rect coordinates remain independent of repeating UV tiles.\n\t\t\tvar transition:=ShaderMaterial.new();transition.shader=rect_transition\n\t\t\ttransition.set_shader_parameter("ap_rect_size_world",area.size*design_scale)\n\t\t\ttransition.set_shader_parameter("ap_source_to_world",float(row.uniform_scale)*design_scale)\n\t\t\ttransition.set_shader_parameter("ap_feather_world",32.0)\n\t\t\ttransition.set_shader_parameter("ap_core_opacity",0.66)\n\t\t\tsprite.material=transition\n\t\t\tsprite.set_meta("ap_rect_transition",{"whole_author_rect":true,"feather_world":32.0,"core_opacity":0.66,"no_tile_edge_feather":true})'),
]
new=data
for before,after in changes:
    b,a=lines(before),lines(after)
    assert new.count(b)==1,b
    new=new.replace(b,a)
reverse=new
for before,after in reversed(changes):
    assert reverse.count(lines(after))==1
    reverse=reverse.replace(lines(after),lines(before))
assert reverse==data
out=HERE/"environment_rect_transition_candidate_READY.gd"
snapshot=HERE/"environment_rect_transition_parent_9038.gd"
receipt=HERE/"environment_rect_transition_candidate_receipt_READY.json"
for target in (out,snapshot,receipt):assert not target.exists()
snapshot.write_bytes(data);out.write_bytes(new)
j=json.loads(author.read_text(encoding="utf-8"))
rects=[{"scene_id":scene,"row_id":row["id"],"asset":row["asset"],"rect":row["rect"],"uniform_scale":row["uniform_scale"]} for scene,value in j["scenes"].items() for row in value["ground"] if "rect" in row]
stamps=[{"scene_id":scene,"row_id":row["id"],"row":row} for scene,value in j["scenes"].items() for row in value["ground"] if "center" in row]
result={"status":"ROOT_APPROVED_NEW_VISUAL_CANDIDATE_NOT_DEPLOYED_NOT_SOURCE_CLOSED_NOT_ENGINE_TESTED",
 "parent":{"path":ref(snapshot),"sha256":sha(snapshot),"canonical_target":ref(parent)},
 "candidate":{"path":ref(out),"sha256":sha(out)},"shader":{"path":ref(shader),"sha256":sha(shader)},
 "unchanged_author":{"path":ref(author),"sha256":sha(author)},
 "wholebyte_inverse_to_parent":True,"exact_changes":[{"before":b,"after":a} for b,a in changes],
 "rect_count":len(rects),"whole_rect_rows":rects,"unchanged_whole_alpha_stamps":stamps,
 "render_only":{"feather_world":32,"core_opacity":0.66,"RGB_original_texture_unchanged":True,"UV_and_repeating_scale_unchanged":True,"per_setup_resource_load_only":True,"no_TIME_noise_CPU_frame_work_or_new_media":True},
 "unchanged":["PNG/import/ctex","all author bytes and source19","native scene/layout/packet/walkmask","NAV/support/collision/portals/NPC/task","facade sign attachment","all existing alpha stamp material and transform","C Artisan native ground visuals"],
 "next":"Root first finishes exact two-target Market source closure and remaining B/D/E actual; only then consider this separate source successor and bounded visual inspection. No A/C technical replay authorized by this candidate."}
receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"candidate_sha256":sha(out),"shader_sha256":sha(shader),"receipt_path":ref(receipt),"receipt_sha256":sha(receipt),"rect_count":len(rects),"stamps_unchanged":len(stamps)}))
