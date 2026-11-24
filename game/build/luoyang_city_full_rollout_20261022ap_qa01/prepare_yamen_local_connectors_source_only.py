"""NEW finite axis-aligned connector source analysis only, no engine or mask decode."""
from pathlib import Path
import hashlib
import json
import math

QA = Path(__file__).resolve().parent
OUT = QA / "yamen_local_connectors_source_only_EXPECTATIONS_NOT_RUNTIME_READY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cross(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def on(a, b, p):
    return cross(a,b,p) == 0 and min(a[0],b[0]) <= p[0] <= max(a[0],b[0]) and min(a[1],b[1]) <= p[1] <= max(a[1],b[1])


def lines_hit(a,b,c,d):
    x,y,z,w = cross(a,b,c),cross(a,b,d),cross(c,d,a),cross(c,d,b)
    return (x*y < 0 and z*w < 0) or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)


def inside(p, poly):
    result = False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if on(a,b,p): return True
        if (a[1] > p[1]) != (b[1] > p[1]):
            x = a[0] + (p[1]-a[1])*(b[0]-a[0])/(b[1]-a[1])
            if p[0] < x: result = not result
    return result


def rect_poly(rect):
    x0,y0,x1,y1 = rect
    return [[x0,y0],[x1,y0],[x1,y1],[x0,y1]]


def polygons_hit(a,b):
    if max(p[0] for p in a) < min(p[0] for p in b) or max(p[0] for p in b) < min(p[0] for p in a) or max(p[1] for p in a) < min(p[1] for p in b) or max(p[1] for p in b) < min(p[1] for p in a): return False
    if any(inside(p,b) for p in a) or any(inside(p,a) for p in b): return True
    return any(lines_hit(x,y,z,w) for x,y in zip(a,a[1:]+a[:1]) for z,w in zip(b,b[1:]+b[:1]))


def sweep(a,b):
    assert a[0] == b[0] or a[1] == b[1], "Only exact axis-aligned connectors; no diagonal AABB overclaim"
    return [min(a[0],b[0])-17,min(a[1],b[1])-12,max(a[0],b[0])+17,max(a[1],b[1])+12]


assert not OUT.exists()
recipe_path = QA / "wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json"
assert sha(recipe_path) == "448c148ed5a15aaf4b1acbf6472afd6f94fe1ea2bdb654717dd59a5a56b4f947"
recipe = json.loads(recipe_path.read_bytes())
yamen = recipe["Yamen"]
geometry = yamen["expected_child_geometry"]
assert len(geometry["solids"]) == 42 and geometry["foot_forbidden_regions_px"] == []
assert geometry["floor_regions_px"] == [[[0,0],[3072,0],[3072,2048],[0,2048]]]
polys = {row["id"]: row["points_px"] for row in geometry["solids"]}
npcs = {row["id"]: rect_poly(row["continuous_NPC34x30_sweep_bounds_xyxy"]) for row in yamen["six_real_NPC_lane_expectations"]}
for key, foot in (("native_spar_patrol",[1170,1000]),("native_captain_conditional",[1790,870]),("native_final_clerk_conditional",[1980,1180])):
    npcs[key] = rect_poly([foot[0]-17,foot[1]-15,foot[0]+17,foot[1]+15])

# Authored before any actual Field run. Default trunk/desk front are inherited
# from fixed six-route publication. Only NEW connectors below are swept here.
connections = [
    {"id":"desk_front_to_east_bypass","points":[[1130,1498],[1130,1530],[1300,1530],[1300,1394]]},
    {"id":"desk_east_to_behind","points":[[1300,1394],[1130,1394]]},
    {"id":"desk_behind_to_south_bench_front","points":[[1130,1394],[1232,1394],[1232,1330],[1140,1330]]},
    {"id":"south_bench_front_around_east_to_behind","points":[[1140,1330],[1232,1330],[1232,1246],[1140,1246]]},
    {"id":"south_behind_to_north_bench_front","points":[[1140,1246],[1232,1246],[1232,1200],[1140,1200]]},
    {"id":"north_bench_front_around_east_to_behind","points":[[1140,1200],[1232,1200],[1232,1135],[1100,1135]]},
    {"id":"north_bench_back_to_front_restore","points":[[1100,1135],[1232,1135],[1232,1200],[1140,1200]]}
]
conflicts = []
for route in connections:
    route["segments"] = []
    route["length_px"] = sum(math.dist(a,b) for a,b in zip(route["points"],route["points"][1:]))
    for index,(a,b) in enumerate(zip(route["points"],route["points"][1:])):
        rect = sweep(a,b)
        box = rect_poly(rect)
        hit_solids = [key for key,poly in polys.items() if polygons_hit(box,poly)]
        hit_npcs = [key for key,poly in npcs.items() if polygons_hit(box,poly)]
        floor = rect[0] > 0 and rect[1] > 0 and rect[2] < 3072 and rect[3] < 2048
        row = {"segment":index,"swept_original34x24_AABB":rect,"source_solid_conflicts":hit_solids,"entire_NPC_lane_conflicts":hit_npcs,"full_source_floor":floor}
        route["segments"].append(row)
        if hit_solids or hit_npcs or not floor: conflicts.append({"route":route["id"],**row})

negative_controls = []
for prop, foot in (("ap_yamen_petition_writing_desk",[1130,1436]),("ap_yamen_waiting_bench_south",[1140,1284]),("ap_yamen_waiting_bench_north",[1140,1154])):
    box = rect_poly(sweep(foot,foot))
    hits = [key for key,poly in polys.items() if polygons_hit(box,poly)]
    assert hits == [prop+"_poly_0"], (prop,hits)
    negative_controls.append({"prop":prop,"fixed_inside_foot":foot,"source_original_body_hits_exactly":[prop+"_poly_0"]})

result = {
    "status":"NEW_LOCAL_CONNECTOR_SOURCE_ANALYSIS_NOT_MASK_OR_RUNTIME_ADMISSION",
    "independent_recipe_sha256":sha(recipe_path),
    "author_basis":"Exact independent frozen source39+new3 native/DG polygons; source float32 values preserved. No publisher/actual output used as expected.",
    "connections":connections,
    "source_floor_solid_and_all_NPC_lane_conflicts":conflicts,
    "continuous_axis_sweep_source_clear":not conflicts,
    "negative_controls":negative_controls,
    "clerk_avoided":"1130,1394 behind-desk station is34px south of real clerk1130,1360; exact body gap7px. Do not use the occupied clerk's original route endpoint.",
    "patrol_avoided":"New east bypassx1232 leaves Player right1249 west of complete west patrol left1253,4px nominal source gap. Never wait for a phase, freeze or move the NPC.",
    "mask_boundary":{
        "existing_local_inverse":"Prior independent full25MiB inverse outside three localized masks and exact child RGBA3B9C is inherited, not recomputed.",
        "old_known_stations":"Default source trunk/desk front and north1100,1135 witness already have89216 full875+17 evidence.",
        "new_connector_mask_clearance_independently_proven_here":False,
        "not_a_full875_or_raw_pixel_claim":True,
        "Root_choice_required":"No new mask decode/sampling performed. Root may approve this source-floor/continuous-solid delta plus finite actual original-body/mask/input observations, or reduce ghost assertions; do not fill expected cells from actual outcomes."
    },
    "itinerary_length_source_px_excluding_default_trunk_and_attempts":sum(row["length_px"] for row in connections),
    "sample_counts_not_preclaimed":True,
    "operations":{"engine":0,"PNG_decode":0,"native_decode":0,"full875_or1085_samples":0,"collector":0,"canonical_write":0},
    "actual_key_READY":False
}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"output":OUT.name,"sha256":sha(OUT),"source_conflicts":conflicts,"engine":0,"mask_clearance_proven":False}))
