"""Frozen System v2 three-script parse fixture; no engine/canonical mutation."""
from pathlib import Path
import hashlib,json
GAME=Path(__file__).resolve().parents[2]
QA=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def path(p):
    assert p.startswith("res://") and ".." not in p
    return GAME/p[6:]
authority="res://build/luoyang_city_full_rollout_20261022ap_system01/unified_runtime_visual_finish_candidates_v2_READY.json"
authority_sha="84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee"
assert sha(path(authority))==authority_sha
fixed=json.loads(path(authority).read_bytes())
selected={
 "res://scripts/autoload/scene_router.gd":["_ap_live_pair_portal","_ap_return_complete_source_sha","get_resident_city_state"],
 "res://scripts/city/luoyang_resident_field_20261016.gd":["stage","detach","attach","state"],
 "res://scripts/city/luoyang_environment_layer_20261022ap.gd":["source_paths_for","install","attach_artisan_union_transition"],
}
sources={authority:authority_sha,"res://project.godot":"4e49287b58d3d3c5fddbeee8db761a6ac8572a73f21d09a34d94c15d338a1cb2",
"res://build/luoyang_city_full_rollout_20261022ap_qa01/visual_two_autoload_parse/36912_1762/result.json":"f22f4c5e50e10af1034a8b54922fa7c133d2c15e770f73294517d633f54ef745"}
rows=[]
for row in fixed["targets"]:
    if row["canonical"] not in selected:continue
    c=row["candidate"]
    assert sha(path(c["path"]))==c["sha256"] and path(c["path"]).stat().st_size==c["bytes"]
    assert sha(path(row["canonical"]))==row["parent_sha256"]
    sources[c["path"]]=c["sha256"]
    sources[row["canonical"]]=row["parent_sha256"]
    rows.append({"path":c["path"],"sha256":c["sha256"],"methods":selected[row["canonical"]]})
assert len(rows)==3,{t["canonical"] for t in fixed["targets"]}
for shader in fixed["new_consumed_shader_leaves"]:sources[shader["path"]]=shader["sha256"]
for p,h in sources.items():assert sha(path(p))==h,p
out=QA/"remaining_three_autoload_parse_READY.json"
assert not out.exists()
result={"status":"AP_REMAINING_THREE_SCRIPTS_AUTOLOAD_PARSE_ONLY","limit_ms":15000,"source_sha256":sources,"rows":rows,"shaders_declared_bytes_only_not_loaded_or_compiled":fixed["new_consumed_shader_leaves"],"original_two_script_actual_inherited_only":"f22f4c5e50e10af1034a8b54922fa7c133d2c15e770f73294517d633f54ef745","no_instances_or_candidate_methods_or_Field":True}
out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"path":str(out),"sha256":sha(out),"rows":len(rows),"engine_executed":False}))
