"""Exact minimal target manifest and static facts, never launches an engine."""
from pathlib import Path
import hashlib
import json
import re
import importlib.util

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent


def fact(path):
    raw = path.read_bytes()
    return {"sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}


def dump(name, data):
    (HERE / name).write_text(json.dumps(data, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")


before = json.loads((HERE / "source_before.json").read_text(encoding="utf-8"))
assert all(fact(ROOT / path)["sha256"] == old["sha256"] for path,old in before.items())
audit = json.loads((HERE / "geometry_attempt04.json").read_text(encoding="utf-8"))
facts = json.loads((HERE / "candidate_facts_BUILD.json").read_text(encoding="utf-8"))
for key, layout in audit["layouts"].items():
    assert not layout["building_solid_overlaps"]
    assert not any(p["hits"] for p in list(layout["doors"].values())+list(layout["npcs"].values()))
    assert not any(r["newly_blocked_samples"] for r in layout["routes"].values())
    for building in facts["facts"][key]["buildings"].values():
        assert building["scale"] <= 1 and building["door_height_px"] >= 128.52*1.1
        if building["key"] != "inn":
            assert 2.5 <= building["height"]/128.52 <= 3.5
    new_scene = (HERE / (key+".tscn")).read_text(encoding="utf-8")
    for resource in re.findall(r'path="(res://[^"\n]+)"',new_scene):
        assert (ROOT / "game" / resource[6:]).exists(), resource
    assert 'uid="' not in new_scene.splitlines()[0]
    assert (HERE/(key+"_ground.gdshader")).read_text(encoding="utf-8") == (ROOT/"game/art/modules/four_settlements_20261030e"/(key+"_ground.gdshader")).read_text(encoding="utf-8")

# Use only definitions before the CLI audit body (no report overwrite/import run).
namespace = {"__file__":str(HERE/"audit_geometry.py")}
source = (HERE/"audit_geometry.py").read_text(encoding="utf-8")
exec(source.split('report = {"engine_calls":')[0],namespace)
cases = {"linxi_center":{"School":[1600,600],"FarmerHome":[2600,1020],"HerbHome":[2580,2000]},
         "linxi_south":{"VillagerHome":[700,780],"SouthSchool":[1800,700],"Apothecary":[3000,780]}}
migrations = {}
for key, tests in cases.items():
    new = json.loads((HERE/(key+".json")).read_text(encoding="utf-8"))
    old = json.loads((HERE/"before/game/art/modules/four_settlements_20261030e"/(key+".json")).read_text(encoding="utf-8"))
    new_solids, old_solids = namespace["solids"](new), namespace["solids"](old)
    function_targets = {"School":"linxi_scholar_house","FarmerHome":"linxi_farmer_cottage","HerbHome":"linxi_herbal_home",
                        "VillagerHome":"linxi_south_villager_home","SouthSchool":"linxi_south_scholar_house","Apothecary":"linxi_south_apothecary_home"}
    migrations[key] = {}
    for owner, foot in tests.items():
        assert not namespace["blocked"](foot,old_solids), (owner,"not old legal")
        assert "Town/"+owner+"/Body" in namespace["blocked"](foot,new_solids)
        target = new["business"]["portal_targets"][function_targets[owner]]
        assert not namespace["blocked"](target,new_solids)
        migrations[key][owner] = {"old_legal_new_body_foot":foot,"explicit_original_return_target":target}

targets = []
for target, candidate in [("game/build/four_settlements_20261030e_system01/locations.gd","locations_READY.gd"),
                          ("game/build/four_settlements_20261030e_system01/locations.json","locations_READY.json")]:
    new = fact(HERE/candidate)
    targets.append({"target":target,"candidate":(HERE/candidate).relative_to(ROOT).as_posix(),"old_sha256":before[target]["sha256"],"new_sha256":new["sha256"],"bytes":new["bytes"]})
names = [key+suffix for key in ["linxi_center","linxi_south"] for suffix in [".tscn",".json","_ground.gdshader"]]
names += ["restore.gd"]+["before/game/art/modules/four_settlements_20261030e/"+key+".json" for key in ["linxi_center","linxi_south"]]
modules = {(HERE/name).relative_to(ROOT).as_posix():fact(HERE/name) for name in names}
manifest = {"status":"CANDIDATE_ONLY_ROOT_FORMAL_AND_ENGINE_AUTHORITY", "layout_version":3004,
            "targets":targets,"new_modules":modules,"runtime_inputs":{},"source_closure_owner":"xiangzhou30e",
            "current_native_before":before["game/build/three_towns_world_20261029j_system01/native_sources.json"],
            "old_source_keys_must_remain":True,"no_new_media":True,"engine_calls":0,"formal_writes":0}
dump("h_manifest_READY.json",manifest)
facts.update(status="STATIC_NEW_SCALE_DOMAIN_CHECKED_NOT_ENGINE_OR_ART", source_before=before,
             minimal_targets=targets, runtime_new_module_count=len(modules), static_proof="geometry_attempt04.json",
             inherited_old_route_blocked_samples={key:{i:r["inherited_old_blocked_samples"] for i,r in value["routes"].items() if r["blocked"]} for key,value in audit["layouts"].items()},
             new_route_blocked_samples=0, original_six_functional_doors_clear=True, original_nineteen_NPC_feet_clear=True,
             enlarged_buildings_vs_all_static_bodies_overlap_count=0, restoration_cases=migrations,
             two_storey_exception={"scene":"linxi_center","building":"Tavern","height":772.68,"native_scale":.94,"door_height":145.7,"height_per_storey_per_adult":772.68/2/128.52},
             corrected_small_home_footprint={"world_width":943*.64*.84,"world_depth":120,"source_basis_rect":[623.44,786.5,792.12,187.5],"basis":"Manual conservative ground foundation rectangle, not alpha/roof bounds. Same source/pivot for all this batch's small_home; accepted30f master body remains untouched."},
             npc_max_adult_reference=132, minimum_door_required=145.2,
             retained_failed_audits=["geometry_attempt01.json","geometry_attempt02.json","geometry_attempt03.json"],
             not_claimed=["Godot parse","runtime physics","room trips","new ART acceptance","formal integration"])
dump("candidate_facts_READY.json",facts)
dump("HANDOFF_READY.json",{"manifest":"game/build/linxi_building_scale_20261030h_system01/h_manifest_READY.json",
                           "manifest_fact":fact(HERE/"h_manifest_READY.json"),"facts":"candidate_facts_READY.json",
                           "integration":"Only two LOC rows version3004/new Scene; one LOC preload+same-ID restore branch. Existing master3002 and5other rows unchanged. Shared NPC/source owner merges canonical targets once.",
                           "normal_camera_feet":{"linxi_center":[[1769.3851102941176,850],[2808.4667571234736,1210]],"linxi_south":[[669.5929443690637,1020],[1969.3851102941176,970],[3100,1020]]},
                           "scope":"21 complete buildings recalibrated; no roads/terrain/NPC/business modifications. Neighbour nonfunctional footprints locally repositioned only to keep corrected shell clear.","engine_calls":0})
print(json.dumps({"manifest":fact(HERE/"h_manifest_READY.json"),"new_modules":len(modules),"targets":targets,"facts":fact(HERE/"candidate_facts_READY.json")},ensure_ascii=False))
