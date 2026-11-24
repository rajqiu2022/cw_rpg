"""One road JSON visual successor only; body deletion is paired with removed bamboo."""
from pathlib import Path
import copy
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent
TARGET = "game/build/linxi_mountain_road_20261030g_system01/road_layout.json"
AUTHOR = "game/build/linxi_mountain_road_20261030g_system01/road_author.gd"
NEW_PNG = "game/art/modules/linxi_scale_polish_20261030h/green_bamboo.png"
GREEN = "res://art/modules/linxi_scale_polish_20261030h/green_bamboo.png"
QUIET = "res://art/modules/sect_maps_20261029k/quiet_ground.png"
SOIL = "res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
OLD_WOOD = "res://art/modules/miao_recompose_20261029g/woodland_floor.png"
PNG_SHA = "3975d5bc2f8f0ea2593253fc3d8562030ec896182313aaf145c2025f5a8b51bd"


def fact(path):
    raw = path.read_bytes()
    return {"sha256":hashlib.sha256(raw).hexdigest(),"bytes":len(raw)}


def dump(name,value):
    (HERE/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")


assert fact(ROOT/NEW_PNG)["sha256"] == PNG_SHA
original = (ROOT/TARGET).read_bytes()
old = json.loads(original)
new = copy.deepcopy(old)
if (HERE/"road_layout_original_30g.json").exists():
    assert (HERE/"road_layout_original_30g.json").read_bytes() == original
else:
    (HERE/"road_layout_original_30g.json").write_bytes(original)
old_bamboo = [r for r in old["specs"] if r["id"].startswith("bamboo_grove_")]
retired = []
retained = []
specs = []
for row in new["specs"]:
    if not row["id"].startswith("bamboo_grove_"):
        specs.append(row)
        continue
    number = int(row["id"].split("_")[-1])
    x,y = row["foot"]
    cave_front = 1450 < y < 1850 and abs(x-2420) < 650
    if number%2 or cave_front:
        retired.append({"id":row["id"],"foot":row["foot"],"removed_body":row["body"],
                        "reason":"odd_numeric_id" if number%2 else "cave_front_clearance"})
        continue
    row.update(texture=GREEN,native_scale=.45,source_foot_px=[928,1090])
    specs.append(row)
    retained.append(row)
new["specs"] = specs
for row in new["ground"]:
    if row["id"] == "wooded_mineral_floor":
        assert row["texture"] == OLD_WOOD
        row["texture"] = QUIET
    elif row["id"] == "shoulder_02":
        row["texture"] = SOIL
for row in retained:
    x,y = row["foot"]
    new["ground"].append({"id":"leaf_litter_"+row["id"],
                          "polygon":[[x+math.cos(math.tau*i/12)*330,y+math.sin(math.tau*i/12)*220] for i in range(12)],
                          "texture":OLD_WOOD,"period":[512,512],"z":-1190,"feather_px":120})
# Every nonvisual source field and every surviving body's exact bytes stay put.
assert {k:v for k,v in new.items() if k not in ["ground","specs"]} == {k:v for k,v in old.items() if k not in ["ground","specs"]}
old_by_id = {row["id"]:row for row in old["specs"]}
for row in new["specs"]:
    previous = old_by_id[row["id"]]
    if row["id"].startswith("bamboo_grove_"):
        assert {k:v for k,v in row.items() if k not in ["texture","native_scale","source_foot_px"]} == {k:v for k,v in previous.items() if k not in ["texture","native_scale","source_foot_px"]}
    else:
        assert row == previous
assert all(row["id"] not in {r["id"] for r in new["specs"]} for row in retired)
dump("road_layout_READY.json",new)
native = json.loads((ROOT/"game/build/three_towns_world_20261029j_system01/native_sources.json").read_text(encoding="utf-8"))
native = native.get("sources",native)
quiet_keys = [k for k in native if k in [QUIET,"game/"+QUIET[6:]]]
# Actual existing native source ownership, not a directory/name assumption.
quiet_pinned = bool(quiet_keys)
if quiet_pinned:
    assert all(native[k] == fact(ROOT/"game"/QUIET[6:])["sha256"] for k in quiet_keys)
inputs = {NEW_PNG:fact(ROOT/NEW_PNG)}
if not quiet_pinned:
    inputs["game/"+QUIET[6:]] = fact(ROOT/"game"/QUIET[6:])
manifest = {"status":"VISUAL_SUCCESSOR_CANDIDATE_ROOT_ENGINE_AND_ART_PENDING",
            "targets":[{"target":TARGET,"candidate":(HERE/"road_layout_READY.json").relative_to(ROOT).as_posix(),
                        "old_sha256":fact(ROOT/TARGET)["sha256"],"new_sha256":fact(HERE/"road_layout_READY.json")["sha256"],
                        "bytes":(HERE/"road_layout_READY.json").stat().st_size}],
            "new_modules":{},"runtime_inputs":inputs,
            "existing_quiet_ground_native_keys":quiet_keys,"quiet_ground_already_native":quiet_pinned,
            "source_closure_owner":"xiangzhou30e","layout_version_unchanged":3003,
            "engine_calls":0,"PNG_pixel_writes":0,"formal_writes":0}
dump("visual_manifest_READY.json",manifest)
facts = {"status":"STATIC_VISUAL_DIFF_PROOF_NOT_ENGINE_OR_ART", "old_layout":fact(ROOT/TARGET),
         "candidate_layout":fact(HERE/"road_layout_READY.json"),"author":AUTHOR,"author_fact":fact(ROOT/AUTHOR),
         "bamboo_before":len(old_bamboo),"numeric_even_before_cave_filter":sum(int(r["id"].split("_")[-1])%2==0 for r in old_bamboo),
         "bamboo_retained":len(retained),"retained_ids":[r["id"] for r in retained],"retired":retired,
         "numeric_id_gap_note":"Original33 rows use sparse numeric IDs00..41, so literal even-ID filter gives15, cave condition removes30/36, final13; no renumbering.",
         "retained_feet_and_bodies_exact":True,"all_other_specs_exact":True,"body_set_is_original_subset_no_new_collision":True,
         "original_NPC_visual_portal_roads_land_solids_business_exact":True,
         "ground_base":{"texture":QUIET,"original_polygon_period_z_exact":True},
         "cave_shoulder":{"id":"shoulder_02","texture":SOIL,"original_polygon_period_z_feather_exact":True},
         "leaf_litter":{"count":len(retained),"points":12,"ellipse_radii":[330,220],"period":[512,512],"z":-1190,"feather_px":120},
         "green_bamboo":{"path":NEW_PNG,**fact(ROOT/NEW_PNG),"size":[1792,1280],"scale":.45,"source_foot_px":[928,1090],"resampled":False},
         "previous_ART_rejection":"Root98012 two images: old blue-cyan blocky bamboo and repeating broad ground rejected, not relabelled PASS.",
         "retained_prior_business_credit":"Original170 checks belong to prior business; this step does not rerun or claim new gameplay success.",
         "engine_calls":0,"PNG_pixel_writes":0,"new_generations_by_author":0,"formal_writes":0}
dump("visual_facts_READY.json",facts)
dump("HANDOFF_READY.json",{"manifest":"visual_manifest_READY.json","manifest_fact":fact(HERE/"visual_manifest_READY.json"),
                           "facts":"visual_facts_READY.json","existing_target":TARGET,"new_runtime_resources":list(inputs),
                           "scope":"New candidate JSON only. Keep all30h building sources frozen; Root alone imports PNG and reviews actual road frames.","engine_calls":0})
assert (ROOT/TARGET).read_bytes() == original
assert fact(ROOT/NEW_PNG)["sha256"] == PNG_SHA
print(json.dumps({"manifest":fact(HERE/"visual_manifest_READY.json"),"old":fact(ROOT/TARGET),"new":fact(HERE/"road_layout_READY.json"),"old_bamboo":len(old_bamboo),"retained":len(retained),"quiet_native":quiet_keys},ensure_ascii=False))
