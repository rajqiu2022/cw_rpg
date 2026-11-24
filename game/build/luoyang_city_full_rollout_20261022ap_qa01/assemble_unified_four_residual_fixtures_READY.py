"""NEW residual QA expectations from externally SHA-fixed actual owner manifest.
No engine/collector/current-runtime hash is used to invent source expectations.
Root calls only after its exact canonical deployment. Old fixtures are preserved.
"""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys,copy
ROOT=Path(__file__).resolve().parents[3]
QA=Path(__file__).resolve().parent
SYSTEM=ROOT/"game/build/luoyang_city_full_rollout_20261022ap_system01"
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def fixed(p,h):
    assert sha(p)==h.lower(),str(p)
    return json.loads(p.read_bytes())
def save(name,obj):
    p=QA/name
    assert not p.exists(),str(p)
    p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    return {"path":"res://"+p.relative_to(ROOT/"game").as_posix(),"sha256":sha(p)}
p=argparse.ArgumentParser()
p.add_argument("--owners",required=True)
p.add_argument("--owners-sha",required=True)
p.add_argument("--prefix",required=True)
args=p.parse_args()
assert args.prefix.isidentifier() and len(args.prefix)<80
owners_path=Path(args.owners).resolve()
owners=fixed(owners_path,args.owners_sha)
assert owners["status"]=="ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS"
original_D=fixed(QA/"bounded_remaining_garden_docks_READY.json","90a8f9193410789d6e338689c00953aa479be0905784530f6613575b4c7c5df7")
poses_path=SYSTEM/"examiner_and_artisan_visual_coordinates_READY.json"
poses=fixed(poses_path,"8c0c9d3dab99463210a921e85bc1b5388f8bb757f74887cd3c79f9ae006545c1")
base_path=QA/(args.prefix+"_source_base_READY.json")
assert not base_path.exists()
command=[sys.executable,str(QA/"assemble_bounded_fixture_remaining_READY.py"),"--base-sha","a9e0930c90c1f369b91518c89b7180715c50ceed6b10afc36532d2d2e2fb1ac4","--owners",str(owners_path),"--owners-sha",args.owners_sha,"--geometry",str(SYSTEM/"independent_raw_geometry_handoff_READY.json"),"--geometry-sha","3ed674aa85b9cd8ac459a3f32baf3c90df872822bcd8cc7a26ee1a623f930f43","--output",str(base_path)]
subprocess.run(command,check=True)
base=json.loads(base_path.read_bytes())
# Contract's behavior remains the original bound author spawn semantics. Only
# current executable source identities move to the independent actual owner.
for key in ("Field","Router"):
    base["return_memory_authority"][key+"_sha256"]=base["core_source_sha256"][base["return_memory_authority"][key]]
base["return_memory_authority"]["source"]="Original Field bound-author callback policy preserved; new exact Market/Artisan retained path preserves both author paired-memory entries. Actual offcenter Artisan feet are separately finite/native-safe/live-overlap, never the stored author argument."
scenes={r["id"]:r for r in base["scenes"]}
d=copy.deepcopy(original_D)
for k in ("scenes","rooms","core_source_sha256","source_authority","return_memory_authority"):
    d[k]=copy.deepcopy(base[k])
d["prior_D_completed_components_not_replayed"]=["trueMarketEstate","EstateGarden_both_ways","Estate_picture","Garden_picture","four_Garden_negative_stations"]
d_out=save(args.prefix+"_garden_docks_ONLY_READY.json",d)
e=copy.deepcopy(base)
e["schema"]="AP_QA_E_PERFORMANCE_ONLY_ORIGINAL10S_OFFCENTER_AUTHOR_ARG"
e["permitted_remaining_groups"]=["E"]
e["groups"]={"E":{"whole_ms":90000,"captures":[],"doors":[],"links":["market_craft"],"dialogues":[]}}
next(r for r in e["links"] if r["id"]=="market_craft")["target_approach"]=[[2816,1740],[2816,1764],[2816,1744]]
e["performance_residual"]={"prior_functional_report":"51956_2945","prior_performance_FAIL_usec":11203165,"original_target_usec":10000000,"reverse_expected_INPUT_foot":[2816,1744],"author_bound_source_arg_foot":[2816,1740],"return_Market_author_foot":[1100,1860],"paired_reverse_memory_is_author_not_actual":True,"same_original_Field_Scene_layout_and_fresh_complete_source_SHA_required":True,"source_only_point_selection":"Original south24px segment swept34x24 AABB[2799,1728]..[2833,1776] intersects no33source-solids; floor contains/forbidden empty; fixed A186905D walk conservative35x49 RGBA255. Not a new engine geometry publication or observed-value selection."}
e_out=save(args.prefix+"_E_performance_ONLY_READY.json",e)
v=copy.deepcopy(base)
v["schema"]="AP_FINITE_MARKET_UI_OR_ARTISAN_SAME_VIEW_VISUAL_ONLY"
v["arrival_ms"]=60000;v["whole_ms"]=90000
v["visual_poses"]=poses
v["visual_source_sha256"]={"res://"+poses_path.relative_to(ROOT/"game").as_posix():sha(poses_path),"res://tests/test_luoyang_city_full_rollout_remaining_BDE_fade_history_READY_20261022ap.gd":"6c0488d71287f4fe504c38e350bdf2b722696523a983691b81aa9df0210ec3d8",poses["artisan_same_camera"]["original_image"]["path"]:poses["artisan_same_camera"]["original_image"]["sha256"],poses["artisan_same_camera"]["union_oracle"]["path"]:poses["artisan_same_camera"]["union_oracle"]["sha256"]}
v["examiner_portrait_path"]="res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png"
v["artisan_union_shader_path"]="res://build/luoyang_city_full_rollout_20261022ap_system01/visual_transition_successor02_retry2/artisan_ground_union_exterior_READY.gdshader"
assert scenes["ch4_s3_luoyang_market"]["source_sha256"][v["examiner_portrait_path"]]=="4fba998b313e66b60f62804ea8968b25742dc5825a76921743265e6a26031dcc"
assert scenes["luoyang_artisan_residential_20261022ap"]["source_sha256"][v["artisan_union_shader_path"]]=="411bceeec31d10025ff17e21e36b416054425e916e04ee39e91038b709acda83"
v["no_old_C_rooms_Physics_or_NPC_menu_replay"]=True
v_out=save(args.prefix+"_Market_Artisan_visual_ONLY_READY.json",v)
print(json.dumps({"source_base":str(base_path),"source_base_sha256":sha(base_path),"D":d_out,"E":e_out,"visual":v_out,"engine_executed":False}))
