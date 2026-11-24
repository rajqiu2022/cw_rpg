"""Finite JSON/source-only follow-up. No native/image decoding or execution."""
from pathlib import Path
import json,hashlib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h;return json.loads(b)
p='res://build/luoyang_city_revision_20261024b_root01/ratio_readback_READY/output/result.json';h='a789e73761b3ef903759d36ca5a30b341104fe224da75830a568eef4833c680c';actual=load(p,h)
ids=['assembled_west_service_annex','assembled_east_service_annex','harbour_rope_shop','harbour_quay_supply_shop'];scale=145/312
rows=[]
for r in actual['regions']:
    for o in r.get('record_objects',[]):
        if o.get('id') not in ids:continue
        x,y=o['world_foot_px'];sx,sy=o['source_size_px'];rs=o['render_size_px'];uv=o['foot_uv'];sem=o['source_semantics'];alpha=o['alpha_measurement']['bounds_strict_alpha_greater_than']['0']
        assert sem['door_top_source_px']==[1000,630] and sem['door_foot_source_px']==[1000,942]
        assert abs(uv[0]*sx-1000)<1e-9 and abs(uv[1]*sy-942)<1e-9
        bbox=lambda a:[x+(a[0]-1000)*scale,y+(a[1]-942)*scale,x+(a[0]+a[2]-1000)*scale,y+(a[1]+a[3]-942)*scale]
        rows.append(dict(scene_id=r['scene_id'],id=o['id'],fixed_native_packet=dict(path=r['packet_path'],sha256=r['packet_sha256']),world_ground_and_visual_threshold=[x,y],source_ground_anchor=[1000,942],source_door_top=[1000,630],source_door_bottom=[1000,942],source_door_height=312,current_canvas_render=rs,current_uniform_scale=rs[1]/sy,current_clear_door=312*rs[1]/sy,source_texture=o['texture'],source_sha256=o['source_sha256'],target145_uniform_scale=scale,target_canvas_render=[sx*scale,sy*scale],target_A1_envelope_xyxy=bbox(alpha),new_interior_or_return_required=False,physical_footprint_status='Not present in the fixed bounded readback: no solid_polygons/collision_size. A1 bounds are a visual envelope, never a ground blocker or a certified free plot.',G_room_mapping='No current G room.building_id equals this ID. Visual doorway only, not an enabled enterable interior.'))
assert len(rows)==4
registry=load('res://data/maps/luoyang_estate_rooms_20261021am/registry.json');roommap=[]
for k,v in registry['rooms'].items():
    a=load(v['author_path']);room=a.get('room',{});assert room.get('building_id') not in ids
    if room.get('city_id') in ['ch4_s1_luoyang_yamen','ch4_s2_canal_docks']:roommap.append(dict(room=k,building_id=room.get('building_id'),city=room.get('city_id')))
constraints={
 'assembled_west_service_annex':dict(neighbor='v11_yamen_west_north_940',neighbor_visual_left_x=906,target_visual_right_x=590+520*scale,visual_gap_x=906-(590+520*scale),decision='No certified96px eave-side lane; existing notice pavilion550,1180 is also immediately at the front. Keep the threshold, inspect/replan only this annex court locally before any publication.'),
 'assembled_east_service_annex':dict(neighbor='v11_yamen_east_north_940',neighbor_visual_right_x=2165,target_visual_left_x=2640-1000*scale,visual_gap_x=2640-1000*scale-2165,decision='Near-touching visual eaves after scale-up. Do not enlarge in place or claim a96px side lane. A local lot/threshold reposition is required if a clear side lane is intended.'),
 'harbour_rope_shop':dict(neighbor='workyard_ac_grain_sack_stack at760,960',target_visual_top_y=1420-942*scale,decision='The enlarged top envelope nearly meets existing workyard sack visual bottom around976; original handcart820,1590 and crate1030,1530 remain south/east. Small-lot candidate only, no proof of a free ground footprint.'),
 'harbour_quay_supply_shop':dict(neighbor='quay_rail_400/720',neighbor_visual_left_x=2199,target_visual_right_x=1930+520*scale,visual_gap_x=2199-(1930+520*scale),decision='Cannot claim96px passage between the enlarged eave and canal rail. Preserve canal boundary and main warehouse; shift/replan this one supply plot locally rather than extend toward water.')}
for row in rows:row['local_plot_constraint']=constraints[row['id']]
v=dict(status='NEXT_FOUR_ANNEX_AND_SCHOLAR_READONLY_NOT_CANDIDATE',production_frozen=True,basis=dict(current_native_readback=dict(path=p,sha256=h),audit='res://build/luoyang_city_space_20261024b_art01/current_eight_region_building_scale_audit.json',limited_to_four_existing_IDs=True),four_annexes=rows,G_current_city_room_mapping=roommap,
    fit_limit='Arithmetic source-image envelopes only. Weak-alpha/A1 or full PNG canvas is not building ground volume. None of the four enlarged lots has a certified current solid/route fit; no hidden whole-city replay was used to assert otherwise.',
    smallest_building_atom='Do not auto-scale all four. First a bounded Yamen annex-pair lot proposal preserving IDs/source pixels/threshold semantics, with actual source-ground polygons and just affected approach/court segments. Docks rope/supply are a separate two-plot atom; main warehouse door154.38 already meets145 and stays unchanged. No new G room, interior native publication or return mapping unless independently designed later.',
    scholar_portrait=dict(current_id='luoyang_paper_scholar',root_cause='Original native Scene uses waiter sprite and no authored portrait. Field fallback chooses matched waiter portrait at1897-1898 from that sprite. Exact scholar world sprite replacement at1904-1906 occurs afterward and leaves portrait_path untouched. It is deterministic selection order, not DialogBox retaining a stale previous texture.',sources=['res://data/scenes/luoyang_enclosure_v11_candidates/ch4_s3_luoyang_market.tres:60','res://scripts/field/field_walkable_controller.gd:1897','res://scripts/field/field_walkable_controller.gd:1904','res://build/luoyang_city_revision_20261024b_dialog01/npc_conversation_CANDIDATE.gd:17'],existing_resources=[dict(path='res://art/characters/portraits/generic/portrait_generic_young_man_v1.png',recommendation='Only available identity-neutral young male fallback located; visually inspected, rough working clothes rather than the newly authored book scholar. Conditional temporary reuse only, not a matched scholar portrait.'),dict(path='res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png',recommendation='Existing mature examiner identity; do not assign it to the young book scholar.'),dict(path='res://art/characters/portraits/portrait_qi_yunsheng_ch7_v1.png',recommendation='Existing named story character, not a generic scholar; do not borrow identity.'),dict(path='res://art/characters/portraits/portrait_su_wusheng_ch8_v1.png',recommendation='Existing named story character, not a generic scholar; do not borrow identity.')],dedicated_matching_scholar_portrait_found=False,minimal_future_atom='An exact Market+paper_scholar portrait-only override after the world-sprite override (selected existing resource or explicitly blank until matching art is authorized). No global family rule, task/dialogue text, rewards, scale/feet, DP or DialogBox changes. Field-owned source successor and its actual hard-pin dependents only if Root later authorizes implementation.'),
    execution=dict(engine=0,packet_decode=0,Godot_Image_decode=0,existing_portrait_images_viewed=2,geometry_PIP_or_NAV_checks=0,collector=0,canonical_writes=0),latest_four_Stages_unchanged=True)
b=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();dest=HERE/'next_four_annex_and_scholar_READONLY.json'
with dest.open('xb') as f:f.write(b)
assert json.loads(dest.read_bytes())==v
print(json.dumps(dict(path=S+dest.name,sha256=sha(b),bytes=len(b),four_buildings=4,no_current_G_mapping=True)))
