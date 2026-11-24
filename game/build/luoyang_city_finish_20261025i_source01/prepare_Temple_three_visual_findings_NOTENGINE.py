"""Only static diagnosis/proposal. No new Temple geometry/payload or runtime code."""
from pathlib import Path
from fractions import Fraction as F
import hashlib,json,struct,copy
import numpy as np
N=Path(__file__).resolve().parent;G=N.parents[1];OUT=N/'Temple_visible_arrival_art01_READONLY'
assert not OUT.exists(),'NEW output only'
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(p,w):
    p=G/p[6:] if isinstance(p,str) and p.startswith('res://') else Path(p)
    b=p.read_bytes();assert sha(b)==w.lower(),(p,sha(b),w);return b
P='res://build/luoyang_city_finish_20261025i_source01/'
author_path=P+'author_temple_source_compiled03_NOTREADY.json'
author_raw=fixed(author_path,'0a8ab1db61b0f8109b26c2b82921be17869278a4f02934b96c47230775e102a3');author=json.loads(author_raw)
natural_path=P+'temple_signed_iid_repair01/expected_Temple_natural_sources_READONLY.json'
natural=json.loads(fixed(natural_path,'a0c525ed72fbb2d30617c8074087bc9f20c8d5a27210afba2f879ad2730bbf8b'))
sources=natural['source_sha256']
temple_path='res://scripts/city/luoyang_temple_assembly_20261016.gd';temple=fixed(temple_path,sources[temple_path]).decode('utf8')
field_path='res://scripts/field/field_walkable_controller.gd';field=fixed(field_path,sources[field_path]).decode('utf8')
payload_path=P+'publication11/output_ROOT_READY/109200/ch4_s4_ancient_temple/payload.bin'
payload_raw=fixed(payload_path,'2ce49190aa32825251153de17277766f05f5bfc72890b01e6d7aec9c636b8d65')
text=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8');scope={'struct':struct};exec(text[text.index('class FrozenVariant:'):text.index('binding_pin=')],scope)
decoder=scope['FrozenVariant'](payload_raw);payload=decoder.value();assert decoder.p==len(payload_raw) and len(payload['effective_solids'])==25
assert 'Vector2(936.0,900.0)' in temple and 'Vector2(600.0,900.0)' in temple
assert temple.count('"sprite_path":SPRITE')==2 and temple.count('"portrait_path":SPRITE')==2
for expected in ['(_viewport_size.y - scaled_world_size.y) * 0.5','return design_size.x > _viewport_size.x * 1.05 or design_size.y > _viewport_size.y * 1.05']:
    assert expected in field
def f32(v):return np.asarray(v,dtype=np.float32)
def arr(v):return [float(x) for x in v]
def world(point):return arr(f32(f32(point)/f32([1536,1024]))*f32([1920,1280]))
def box(poly):return [min(p[0]for p in poly),min(p[1]for p in poly),max(p[0]for p in poly),max(p[1]for p in poly)]
def exact_sweep_hit(a,b,obstacle,half):
    # Fraction operations on exact binary32 values; outer-AABB proof is conservative for 2 nonrect old props.
    a=list(map(F,a));b=list(map(F,b));lo=[F(obstacle[i])-F(half[i])for i in range(2)];hi=[F(obstacle[i+2])+F(half[i])for i in range(2)];enter=F(0);leave=F(1)
    for i in range(2):
        delta=b[i]-a[i]
        if not delta:
            if a[i]<lo[i]or a[i]>hi[i]:return False
        else:
            start=(lo[i]-a[i])/delta;end=(hi[i]-a[i])/delta
            if start>end:start,end=end,start
            enter=max(enter,start);leave=min(leave,end)
            if enter>leave:return False
    return True
monks=[{'id':'temple_cave_keeper_20261018t','source_foot':[936,900]},{'id':'temple_bell_keeper_20261018t','source_foot':[600,900]}]
for npc in monks:npc['world_foot_final_f32']=world(npc['source_foot']);npc['body_px']=[34,30]
candidate_routes=[{'id':'proposed_default_to_visible_market_portal','source_points':[[768,737.28],[730,926],[170,926]],'source_portal_id':'legacy_portal_6','target_scene':'ch4_s3_luoyang_market'},
 {'id':'proposed_default_to_visible_docks_portal','source_points':[[768,737.28],[768,926],[1380,926]],'source_portal_id':'legacy_portal_7','target_scene':'ch4_s2_canal_docks'}]
route_findings=[];proposal_portals=[]
for route in candidate_routes:
    points=[world(v)for v in route['source_points']];conflicts=[]
    for leg,(a,b) in enumerate(zip(points,points[1:])):
        for index,solid in enumerate(payload['effective_solids']):
            if exact_sweep_hit(a,b,box(solid),[17,12]):conflicts.append({'kind':'old_solid_outer_AABB','index':index,'leg':leg})
        for npc in monks:
            p=npc['world_foot_final_f32'];bounds=[p[0]-17,p[1]-15,p[0]+17,p[1]+15]
            if exact_sweep_hit(a,b,bounds,[17,12]):conflicts.append({'kind':'unchanged_monk34x30','id':npc['id'],'leg':leg})
    for p in points:assert 20+17<p[0]<1900-17 and 20+12<p[1]<1260-12
    assert not conflicts,conflicts
    current=next(r for r in payload['portal_after']if r['id']==route['source_portal_id'])
    candidate=copy.deepcopy(current);candidate['pos']=arr(f32(route['source_points'][-1])/f32([1536,1024]))
    assert {k:v for k,v in current.items()if k!='pos'}=={k:v for k,v in candidate.items()if k!='pos'}
    foot=points[-1];proposal_portals.append({'source_portal_id':route['source_portal_id'],'before_complete_payload_row':current,'proposal_complete_row_only_pos_changed':candidate,'source_foot_before':[route['source_points'][-1][0],980],'source_foot_proposed':route['source_points'][-1],'world_foot_final_f32':foot,'world_body34x24_xyxy':[foot[0]-17,foot[1]-12,foot[0]+17,foot[1]+12],'screen_foot_with_original_origin_0_minus100':[foot[0],foot[1]-100],'body_bottom_margin_to_visible_world1180':1180-foot[1]-12,'Root_authorization_required':True})
    route_findings.append({'id':route['id'],'source_points':route['source_points'],'world_points_final_UV_consumer_f32':points,'exact_rational_continuous_Player34x24_vs_original25_outer_AABBs_and_two_NPC34x30':{'conflicts':conflicts,'passed_Source_static_component_only':True},'new_route_not_independent_or_engine_pass':True})

door_rows=[]
for placement in author['placements']:
    if placement['id']not in ['finish_i_temple_west_monks_house','finish_i_temple_east_sutra_house']:continue
    row=next(v for v in payload['effective_navigation']if v['id']==placement['id']);assert row['centered']is False
    ratio=f32(row['render_size_px'])/f32([2202,1289]);pos=f32(row['pos'])*f32([1920,1280]);local=f32([893,812.5]);center=pos+local*ratio;size=f32([248,369])*ratio
    door_rows.append({'id':row['id'],'fixed_parent_complete_row':row,'parent_centered':False,'child_local_position_px':[893,812.5],'child_scale':[1,1],'child_relative_z':-1,'child_world_center_final_f32':arr(center),'child_world_size_f32':arr(size),'world_region_actual_parent_transform_xyxy':arr(center-size*.5)+arr(center+size*.5),'do_not_use_Estate_centered_local_minus208_168':True})
atlas_path='res://build/luoyang_estate_courtyard_20261021al_system01/textures/wing_door_depth.tres'
fixed(atlas_path,'61c70b6f98c4c399ae4356ccba9151d2621b6833a8c71ed1b2cf8a79e1ee4efd')
report={'status':'SOURCE_STATIC_THREE_TEMPLE_VISUAL_FINDINGS_WITH_UNAUTHORIZED_PORTAL_PROPOSAL_NOT_RUNTIME_REPAIR','frozen_sources':{'author':{'path':author_path,'sha256':sha(author_raw)},'payload':{'path':payload_path,'sha256':sha(payload_raw)},'temple_script':{'path':temple_path,'sha256':sources[temple_path]},'Field_script':{'path':field_path,'sha256':sources[field_path]},'natural_expectation':{'path':natural_path,'sha256':'a0c525ed72fbb2d30617c8074087bc9f20c8d5a27210afba2f879ad2730bbf8b'}},'single_screen_source_model':{'source_design_size':[1536,1024],'world_size':[1920,1280],'viewport':[1920,1080],'camera_zoom':1,'Camera2D':None,'original_world_container_origin':[0,-100],'visible_world_xyxy':[0,100,1920,1180],'old_portal_source_y':980,'old_world_foot_y':1225,'old_foot_beyond_visible_bottom_px':45,'not_a_new_render_or_physics_failure':True},'portal_and_incoming_arrival_proposal':proposal_portals,'only_candidate_new_routes_Source_checks':route_findings,'crossed_monk_horizontal_clearance_world_px':5.5,'NPCs_unchanged':monks,'portal_followthrough_required_if_Root_approves':['Temple two target portal pos and original hotspot source pos projection only; target/action/flags/size remain identical','Market to_ancient_temple and Docks canal_world_ferry target_pos; original actual local sourcefeet remain1170/1600 and2140/1840','Those two payload new_route_contracts target_source_foot/world_foot/expected_normalized plus runtime hardlimited arrival contract must follow exact same UV expression','Author incoming target migrations and Temple required return routes explicit successor; no old25body or floor or sourceboundary changes','Source strict maps/FIRSTFINAL/CT26/Temple196 prospective pins only after actual permitted narrow component'], 'side_wing_door_backdrop_reuse':{'atlas':{'path':atlas_path,'sha256':'61c70b6f98c4c399ae4356ccba9151d2621b6833a8c71ed1b2cf8a79e1ee4efd'},'same_wing_source_png':'res://art/modules/luoyang_estate_components_20261021am/wing.png','same_wing_sha256':'7e1783a9ea26ad9aa4a09c0cf5e0bf966645ee81cbe3ab6ef5d7e9a4880fee75','source_door_rect_grow3_xywh':[769,628,248,369],'two_exact_parents':door_rows,'no_body_portal_or_PNG_change':True,'System_renderer_ownership':True,'requires_Root_explicit_Temple_renderer_scope_approval':True},'two_monks_same_identity_asset_source_fact':{'function':'TEMPLE.successor_npcs()','IDs':[v['id']for v in monks],'sprite_and_portrait_both_same':'res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png','script_literal_evidence':'One const SPRITE; both rows sprite_path and portrait_path=SPRITE, idle, same scale.9459459459; no current finish NPC patch for these two IDs.','not_introduced_by_current_signed_repair':True,'narrow_asset_gap':'No second monk-named mature sprite found in existing game/art/characters filename inventory. This does not claim all unknown filenames are unsuitable. Root/ART must select or authorize one distinct same-person sprite+portrait before identity replacement; no random hero portrait reuse.','not_a_request_to_remove_or_move_existing_task_NPCs':True},'engine_calls':0,'old_geometry_recompile_PIP_or_routes_replay':False,'canonical_or_runtime_writes':0,'new_actual_Field_claim':False,'whole_city_ART_pass':False}
OUT.mkdir();raw=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf8');target=OUT/'three_findings_and_visible_portal_pair_READONLY.json'
with target.open('xb')as f:f.write(raw)
print(json.dumps({'path':'res://'+str(target.relative_to(G)).replace('\\','/'),'sha256':sha(raw),'bytes':len(raw),'proposed_pair_source_y':926,'old_source_bodies_unchanged':True}))
