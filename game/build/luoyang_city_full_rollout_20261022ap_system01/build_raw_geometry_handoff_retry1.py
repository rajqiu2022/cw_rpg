"""Read-only source-author translation for independent QA, not a compiler run.

No Godot calls, rasterization, navigation, path sampling, binary decoding,
current Field/Scene reads, collision/clearance queries or publisher execution.
"""
from pathlib import Path
import copy
import hashlib
import json
import struct

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
OUT = HERE / "independent_raw_geometry_handoff_READY.json"
ROOT = "res://build/luoyang_city_full_rollout_20261022ap_system01/"
ARTISAN = "luoyang_artisan_residential_20261022ap"
GARDEN = "luoyang_riverside_garden_20261022ap"
MARKET = "ch4_s3_luoyang_market"
ESTATE = "luoyang_estate_riverside_20261021ai"
PINS = {
 "res://tests/fixtures/luoyang_t_ordinary_world_gate_final_20261019u.json":"b6aea50592ba2046f07846d666dfd3a7a8309764cf0b7047ae02faf08fdfc114",
 "res://tests/fixtures/luoyang_t_yamen_hall_return_retry1_20261019u.json":"c3b0c0273d86e8db3b0387f84dc37846d307e8953d97f815b1564c2a819a9007",
 "res://tests/fixtures/luoyang_t_temple_two_monks_actual_route1_20261019u.json":"f2b7aa51b64bdac6d02485c7101b680ebe138f5d88b51471419d545b599c7ebb",
 "res://tests/fixtures/luoyang_t_market_herbal_actual_retry2_20261019u.json":"55a315e0d2c10e9c3d8b4caea7266c1be2b4c1ee813ee50afa1f6eccf92cdeb3",
 "res://build/luoyang_estate_courtyard_20261021an_qa01/travel_remaining_fixture_READY.json":"780c84440d82aaf5b39d4823ca8ee210811d908798b5557eee03138cccb1305a",
 "res://build/luoyang_estate_courtyard_20261021an_qa01/travel_domain_inputs_READY.json":"72b14306f595cef4513042c9dfa047ece35bd273e315b1934419559aab5dd856",
 "res://build/luoyang_market_two_shops_20261021ao_system01/author_READY.json":"227735f42114e843e62109b127a3c57d4a7b9ffdb4e545799ba9d50dc77cc849",
 ROOT+"market_alpha_pin_retry6/market_author.json":"b11f48b8249ab27784aef1dc5b960e9ede7430e381a923c389c6461d95ca7a2e",
 ROOT+"artisan_revision4/author_READY.json":"c2aa48ec6fe654f85e17be9081ca86c748fffe2506581405c4df4ec0b15add69",
 ROOT+"garden_revision4/shore_landing_retry2/author_READY.json":"937320f2e24d159e0dc5b023d72222be4118fb4e6d90e9558fa3cfba4ae55dfe",
 ROOT+"publication_assets/registry_candidate.json":"c7b8db7a5d3bea314d956c4bb5dced734a9e093757cfc41373fe5bd77c6f3670",
 "res://data/maps/luoyang_district_life_20261016f/author.json":"d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c",
}


def sha(data): return hashlib.sha256(data).hexdigest()
def path(key): return GAME / key.removeprefix("res://")
def read(key):
    data = path(key).read_bytes()
    assert key in PINS and sha(data) == PINS[key], key
    return json.loads(data)
def f(v): return struct.unpack("<f", struct.pack("<f", float(v)))[0]
def add(a,b): return [f(f(x)+f(y)) for x,y in zip(a,b)]
def sub(a,b): return [f(f(x)-f(y)) for x,y in zip(a,b)]
def mul(a,s): return [f(f(x)*f(s)) for x in a]
def box(raw):
    low = [f(raw[0]), f(raw[1])]; high = add(low,raw[2:])
    return [low,[high[0],low[1]],high,[low[0],high[1]]]
def transformed(point, foot, anchor, uniform): return add(foot,mul(sub(point,anchor),uniform))
def solid(id, poly, kind="fixed_source_author"): return {"id":id,"points_px":poly,"kind":kind}
def from_rect(id, source, foot, anchor, uniform):
    low=transformed(source[:2],foot,anchor,uniform);size=mul(source[2:],uniform)
    return solid(id,box(low+size))
def clean(g):
    return {"source_size_px":g.get("source_size_px",[3072,2048]),"floor_regions_px":copy.deepcopy(g["floor_regions_px"]),"solids":copy.deepcopy(g["solids"]),"foot_forbidden_regions_px":copy.deepcopy(g.get("foot_forbidden_regions_px",[])),"mask_path":g.get("mask_path","")}


def quarter(author):
    scene=author["scenes"][0];solids=[]
    for row in scene["placements"]:
        asset=author["assets"][row["asset"]]; scale=row["width"]/asset["used_rect"][2]
        for index, rect in enumerate(asset.get("solid_rects",[])):
            solids.append(from_rect(row["id"]+"_base_"+str(index),rect,row["foot"],asset["ground_anchor"],scale))
        for index, poly in enumerate(asset.get("solid_polygons",[])):
            solids.append(solid(row["id"]+"_hull_"+str(index),[transformed(p,row["foot"],asset["ground_anchor"],scale) for p in poly]))
    for index, poly in enumerate(scene.get("water_polygons",[])):
        solids.append(solid("ap_garden_deepwater_"+str(index+1),poly,"actual_closed_water_no_bridge_support"))
    return {"source_size_px":[3072,2048],"floor_regions_px":[box(scene["walk_rect"])],"solids":solids,"foot_forbidden_regions_px":[],"mask_path":"res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/"+scene["scene_id"]+"/walk.png"}


def main():
    assert not OUT.exists(), "NEW-only output"
    docs={p:read(p) for p in PINS}
    gate=docs["res://tests/fixtures/luoyang_t_ordinary_world_gate_final_20261019u.json"]
    yamen=docs["res://tests/fixtures/luoyang_t_yamen_hall_return_retry1_20261019u.json"]
    temple=docs["res://tests/fixtures/luoyang_t_temple_two_monks_actual_route1_20261019u.json"]
    old_market=docs["res://tests/fixtures/luoyang_t_market_herbal_actual_retry2_20261019u.json"]
    estate=docs["res://build/luoyang_estate_courtyard_20261021an_qa01/travel_remaining_fixture_READY.json"]
    domain=docs["res://build/luoyang_estate_courtyard_20261021an_qa01/travel_domain_inputs_READY.json"]
    geo={"ch4_s0_luoyang_gate":clean(gate["gate_geometry"]),"ch4_s1_luoyang_yamen":clean(yamen["geometry"]["ch4_s1_luoyang_yamen"]),"ch4_s4_ancient_temple":clean(temple["geometry"]["ch4_s4_ancient_temple"])}
    geo[ESTATE]=clean(estate["geometry"][ESTATE]); es=[]
    for row in domain["inherited_solids"]: es.append(solid(row["id"],box(row["rect_px"])))
    for row in domain["wall_components"]:
        asset=domain["wall_assets"][row["asset_id"]]
        if "solid_relative_to_foot" in asset:
            rect=asset["solid_relative_to_foot"];es.append(solid(row["id"]+"_solid_0",box(add(row["foot_px"],rect[:2])+rect[2:])))
        else: es.append(from_rect(row["id"]+"_solid_0",asset["source_solid_rect_px"],row["foot_px"],asset["source_anchor_px"],asset["uniform_scale"]))
    assert len(es)==48;geo[ESTATE]["solids"]=es
    # Market: exact independent U geometry -> already admitted AO two shops ->
    # AP two frontages, same five finite prop moves and west wall replacement.
    market=clean(old_market["geometry"][MARKET]); ao=docs["res://build/luoyang_market_two_shops_20261021ao_system01/author_READY.json"]
    retired={"market_east_ward_frontage_poly_0","v13_market_east_plot_wall_poly_0"}
    kept=[r for r in market["solids"] if r["id"] not in retired];assert len(market["solids"])-len(kept)==2
    for index,key in enumerate(["apothecary","study"]):
        a=ao["assets"][key];p=ao["new_objects"][index]
        for i,poly in enumerate(a["ground_solid_polygons_px"]): kept.append(solid(p["id"]+"_poly_"+str(i),[transformed(v,p["world_foot_px"],a["source_ground_anchor_px"],a["scale"]) for v in poly]))
    ap=docs[ROOT+"market_alpha_pin_retry6/market_author.json"]
    retired={id+"_poly_0" for id in ap["retire_ids"]}; before=len(kept)
    kept=[r for r in kept if r["id"] not in retired];assert before-len(kept)==2
    for index,key in enumerate(["pawn","tailor"]):
        a=ap["assets"][key];p=ap["new_objects"][index]
        for i,rect in enumerate(a["solid_rects"]): kept.append(from_rect(p["id"]+"_solid_"+str(i),rect,p["world_foot_px"],a["source_ground_anchor_px"],a["scale"]))
    moves=ap["layout_successor"]
    for move in moves["native_moves"]+moves["district_moves"]:
        prefix=("district_" if move in moves["district_moves"] else "")+move["id"]+"_"
        affected=[r for r in kept if r["id"].startswith(prefix)];assert len(affected)==1,(prefix,len(affected))
        delta=sub(move["new_foot"],move["old_foot"])
        affected[0]["points_px"]=[add(p,delta) for p in affected[0]["points_px"]]
    wall=moves["wall"]; affected=[r for r in kept if r["id"]==wall["id"]+"_poly_0"];assert len(affected)==1
    affected[0]["points_px"]=box(wall["solid"])
    market["solids"]=kept;market["mask_path"]="res://data/maps/luoyang_full_city_20261022ap/market/"+MARKET+"/walk.png";geo[MARKET]=market
    geo[ARTISAN]=quarter(docs[ROOT+"artisan_revision4/author_READY.json"]);assert len(geo[ARTISAN]["solids"])==33
    geo[GARDEN]=quarter(docs[ROOT+"garden_revision4/shore_landing_retry2/author_READY.json"]);assert len(geo[GARDEN]["solids"])==11
    registry=docs[ROOT+"publication_assets/registry_candidate.json"]
    for id in registry["ap_return_successor"]["room_ids"]:
        row=registry["rooms"][id]; data=path(row["author_path"]).read_bytes();assert sha(data)==row["author_sha256"]
        PINS[row["author_path"]]=row["author_sha256"]; g=json.loads(data)["geometry"]
        geo[id]={"source_size_px":g["source_size_px"],"floor_regions_px":g["floor_regions_px"],"foot_forbidden_regions_px":g.get("foot_forbidden_regions_px",[]),"solids":[solid(r["id"],r["ground_polygon_px"]) for r in g["furniture_bases"] if r.get("blocking")==True],"mask_path":""}
    for id,g in geo.items(): assert len({r["id"] for r in g["solids"]})==len(g["solids"]),id
    result={"schema_version":1,"status":"INDEPENDENT_RAW_SOURCE_DATA_AND_ONE_FROZEN_DOCKS_RECIPE_NO_ENGINE","source_sha256":PINS,"geometry":geo,"counts":{id:len(g["solids"]) for id,g in geo.items()},"Docks_recipe":{"id":"ch4_s2_canal_docks","packet_path":"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/packet.bin","packet_sha256":"1cb6bbf9825d538c982fcdf1171c5f3e268854be54796c3684c91502da14f221","record":"bytes_to_var(exact fixed packet).record.objects; exactly29 objects, never C._records/Field/current collector","source_size_px":[3072,2048],"floor_regions_px":[[[0,0],[3072,0],[3072,2048],[0,2048]]],"foot_forbidden_regions_px":[],"object_geometry":"for each source object, append each solid_polygons_px as world polygon. If collision_size_px.x>0 and.y>0, low=Vector2(physical_center_px)-Vector2(collision_size_px)*.5; high=low+extent; append rectangle[low,(high.x,low.y),high,(low.x,high.y)]. Give stable unique IDs object.id+'_poly_'+i and object.id+'_box'. All source record fields already world3072x2048, never re-scale/normalize.","District_author":"res://data/maps/luoyang_district_life_20261016f/author.json","District_author_sha256":PINS["res://data/maps/luoyang_district_life_20261016f/author.json"],"District_geometry":"For each author.districts[ch4_s2_canal_docks].placements row get author.assets[row.asset_id]; for each asset.ground_solid_polygons_px, map point=Vector2(row.foot_px)+(Vector2(sourcepoint)-Vector2(asset.source_ground_anchor_px))*float(row.scale). ID='district_'+row.id+'_'+polyindex. No production geometry functions. AP District projection affects Market only, Docks these declarations unchanged.","water":"Original closed dark water is independently enforced by exact raw packet walk mask; no false wholefloor water-walk credit. mask path from immutable packet.record.walk_path, complete-source manifest must pin that exact file.","historical_independent_algorithm":"res://tests/test_luoyang_docks_workyard_field_ready_20261019ac.gd::_geometry, lines58..72; recipe changes only stable IDs to comply RAW oracle, not geometry."},"boundaries":["No production safe_body/compiler or live runtime reads used to form oracle.","Twelve JSON geometry domains plus one Docks typed published-source recipe = eight outdoors and five rooms.","Only source author coordinates are translated with explicit Godot Vector2 float32 operation encoding. No walk samples or source mask pixels recomputed.","Native mask path/SHA must be bound from final immutable owner source maps, never fill from an observed collector/current disk. Old fixture mask paths are historical same geometry; QA may replace with final native packet walk_path only under fixed packet identity and compare full original RGBA.","Gate source_size fixed3072x2048; Temple source1536x1024 and actual1920x1280 remain distinct; do not force all eight to one size.","Actual Physics/input/firstdraw/menu/travel remains Root/QA duty, not this source-data handoff."]}
    OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"output_sha256":sha(OUT.read_bytes()),"raw_json_domains":len(geo),"Docks_recipe":1,"solid_counts":result["counts"]}))


if __name__=="__main__": main()
