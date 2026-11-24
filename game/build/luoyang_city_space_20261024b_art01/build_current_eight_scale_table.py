"""Read Root's already-decoded current native projection; zero packet/image/engine access."""
from pathlib import Path
import hashlib
import json

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/"game/build/luoyang_city_revision_20261024b_root01/ratio_readback_READY/output/result.json"
EXPECTED="a789e73761b3ef903759d36ca5a30b341104fe224da75830a568eef4833c680c"
raw=SOURCE.read_bytes()
assert hashlib.sha256(raw).hexdigest()==EXPECTED
actual=json.loads(raw)
assert actual["complete"] and actual["failures"]==0 and actual["native_decode_count"]==6 and len(actual["regions"])==8
IDS={
    "ch4_s3_luoyang_market":["inn","shop","north_market_front","market_west_ward_frontage","market_northeast_rear_frontage","market_east_ward_frontage"],
    "ch4_s0_luoyang_gate":["north_court_boundary","west_street_front","east_street_front","gate_tower_140","gate_tower_2932"],
    "ch4_s1_luoyang_yamen":["magistrate_hall","south_court_gate","assembled_west_service_annex","assembled_east_service_annex"],
    "ch4_s2_canal_docks":["north_canal_warehouse","harbour_rope_shop","harbour_cargo_trade_front","harbour_quay_supply_shop"],
    "luoyang_artisan_residential_20261022ap":["ap_courtyard_home_west","ap_courtyard_home_east","ap_woodwork_court_west_chinese_v3","ap_cloth_dye_workshop_east","ap_carpentry_general_shop_south"],
    "luoyang_riverside_garden_20261022ap":["ap_river_pavilion"],
    "luoyang_estate_riverside_20261021ai":["estate_mansion_courtyard_gate","estate_ak_main_hall","estate_ak_west_wing","estate_ak_east_wing","estate_ak_west_corridor","estate_ak_east_corridor"]
}
def vec(value):
    if isinstance(value,dict): value=value.get("xy")
    return value if isinstance(value,list) and len(value)==2 else None
def numbers(values): return [round(float(x),9) for x in values]
regions=[]
for region in actual["regions"]:
    scene=region["scene_id"]
    if scene not in IDS:
        regions.append({"scene_id":scene,"status":"UNKNOWN_DYNAMIC_ASSEMBLY_NOT_ZERO_BUILDINGS","building_rows":[],"reason":"No current native packet; historical temple author is not substituted."})
        continue
    objects=region.get("record_objects") or region.get("layout_visuals") or []
    rows=[]
    for object_id in IDS[scene]:
        matches=[x for x in objects if x.get("id")==object_id]
        assert len(matches)==1,(scene,object_id)
        item=matches[0]
        render=vec(item.get("render_size_px")) or vec(item.get("render_size"))
        size=vec(item.get("source_size_px")) or vec(item.get("source_size"))
        sem=item.get("source_semantics") or {}
        row={"id":object_id,"texture":item.get("texture"),"current_render_full_canvas_world_size":render,"current_source_size":size,"current_source_sha256_if_recorded":item.get("source_sha256"),"world_foot":item.get("world_foot_px"),"A1_body_size_world":"UNKNOWN","door_clear_height_world":"UNKNOWN","door_to_adult120":"UNKNOWN","render_canvas_height_to_adult120_not_body_height":round(render[1]/120,9) if render else "UNKNOWN"}
        if render and size:
            sx,sy=render[0]/size[0],render[1]/size[1]
            row["current_pixel_scale_xy"]=numbers([sx,sy])
            bounds=(item.get("alpha_measurement") or {}).get("bounds_strict_alpha_greater_than",{}).get("0")
            if isinstance(bounds,list) and len(bounds)==4:
                row["native_A1_rect_xywh_source"]=bounds
                row["A1_body_size_world"]=numbers([bounds[2]*sx,bounds[3]*sy])
                row["A1_height_to_adult120"]=round(bounds[3]*sy/120,9)
                row["A1_extent_not_wall_height_warning"]="Complete A>0 may include weak detached pixels/contact tail. It is not a measured clear wall or floor height."
            strong=sem.get("strong_alpha_bbox_xyxy")
            if isinstance(strong,list) and len(strong)==4:
                row["native_strong_visual_size_world_diagnostic_only"]=numbers([(strong[2]-strong[0])*sx,(strong[3]-strong[1])*sy])
            top=vec(sem.get("door_top_source_px"))
            foot=vec(sem.get("door_foot_source_px"))
            door_source=None
            if top and foot:
                door_source=abs(foot[1]-top[1])
                row["door_source_basis"]="Native source_semantics door_foot minus door_top, multiplied by CURRENT render scale; not inherited measured world number."
            else:
                for name in ["visible_ground_door_height_px","visible_center_door_height_px"]:
                    if isinstance(sem.get(name),(int,float)):
                        door_source=sem[name]
                        row["door_source_basis"]="Native source_semantics."+name+" times CURRENT render/source scale."
                        break
            if door_source is not None:
                door=door_source*sy
                row.update({"door_clear_source_height":door_source,"door_clear_height_world":round(door,9),"door_to_adult120":round(door/120,9),"minimum_uniform_scale_for_new145_target":round(145/door_source,12),"increase_multiplier_if145_is_explicitly_required":round(max(1,145/door),9),"legacy120_numeric_test":door>=120})
                inherited=sem.get("measured_door_height_px")
                if isinstance(inherited,(int,float)):
                    row["native_inherited_measured_world_number"]=inherited
                    row["inherited_number_matches_current_scale"]=abs(inherited-door)<.001
        if row["door_clear_height_world"]=="UNKNOWN":
            row["limit"]="Current packet has no independently usable clear-door measurement; no historical author was silently used to fill this field."
        rows.append(row)
    regions.append({"scene_id":scene,"native_scope":region["status"],"packet_sha256":region.get("packet_sha256"),"all_record_or_layout_visual_count":region.get("record_object_count") or region.get("layout_visual_count"),"listed_buildings_or_gate_towers":len(rows),"building_rows":rows,"post_native_runtime_overlay_buildings":"NOT_PROJECTED_NOT_ZERO"})
report={
    "status":"CURRENT_EIGHT_REGION_BUILDING_RATIO_TABLE_WITH_EXPLICIT_UNKNOWNS_NOT_ART_OR_RUNTIME_PASS",
    "source_actual":str(SOURCE),"source_sha256":EXPECTED,"source_root_checks":78,"source_root_failures":0,"source_root_elapsed_ms":actual["elapsed_ms"],
    "basis":"Only Root's one six-packet actual projection plus inherited Market23. No new packet or PNG decode, engine, Field, Physics, NAV or collector.",
    "adult_reference":120,
    "policy":"Legacy adult-clear author limit120 is not retroactively145. New two dedicated shops keep145. Total one-storey height is not universally3x adult height.",
    "regions":regions,
    "definite_findings":[
        "Docks warehouse current .62 scale gives 249*.62=154.38 clear door, so no increase is necessary to meet145. Its width1085/A1height549.94 includes complete alpha extent, not a net measured wall height.",
        "Yamen service annexes and Docks rope/supply shops inherit measured_door_height_px156 from a differently scaled parent. The native source door top/foot with each CURRENT render scale gives131.04/124.8/132.6/124.8 respectively, not156.",
        "The pharmacy and study are visibly wrong door-only FORM even though legacy doorway clearance may allow an adult. Replace with the two new complete shops; this report does not count those candidates as already formal.",
        "Gate current fronts are700x467 and do not carry native door/A1 metrics. Do not substitute historical1029x686 values. A separate same-source228px-door hypothesis would imply about104px, but that is a flagged follow-up hypothesis, NOT a current measurement or permission to change scale.",
        "Artisan5, Garden pavilion and Estate6 current native visuals provide full-canvas render dimensions but lack native source/A1/door fields. Mark those metrics UNKNOWN rather than importing old author numbers as current.",
        "Temple has no current packet in this resolver and is explicitly UNKNOWN; this does not mean no buildings or that its existing main hall is too small."
    ],
    "inventory_limits":"Listed are complete building/gate/tower exteriors, not ground tiles, trees, signs, bridges, freestanding notice boards or market awnings. Dynamic runtime additions after the packet are not inventoried by this key.",
    "next_smallest_actions":["Finish new two-shop isolated import and bounded Source geometry/door pairing before formal adoption.","Do not enlarge Docks main warehouse merely to satisfy a door minimum it already meets; give its distinct office/cargo/service plot planning priority.","For Gate front houses, obtain a bounded same-source door semantic link before deciding on any uniform scale change; do not repeat whole-city Field tests.","Only fill missing Quarter/Temple metrics through an explicitly bounded current-source readback or proven same-source component contract; do not reclassify historical author data as actual."]
}
output=Path(__file__).with_name("current_eight_region_building_scale_audit.json")
assert not output.exists()
with output.open("x",encoding="utf-8") as file: file.write(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
summary=[]
for region in regions:
    for row in region["building_rows"]:
        summary.append({"scene":region["scene_id"],"id":row["id"],"render":row["current_render_full_canvas_world_size"],"A1":row["A1_body_size_world"],"door":row["door_clear_height_world"],"door_H":row["door_to_adult120"]})
print(json.dumps({"audit":str(output),"sha256":hashlib.sha256(output.read_bytes()).hexdigest(),"regions":len(regions),"rows":len(summary),"table":summary},indent=2))
