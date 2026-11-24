"""Five Root-approved anchors, immutable-source offline preparation; never Godot/Stage."""
from pathlib import Path
import hashlib,json,math,struct,re
import numpy as np
from PIL import Image

N=Path(__file__).resolve().parent
G=N.parents[1]
OUT=N/'street_edges05_BUILD02'
DESIGN=G/'build/luoyang_city_finish_20261025i_art01/continuous_street_edge_five_lots_DESIGN04_SOURCE_CANDIDATE.json'
DESIGN_SHA='3d4a4c0cf0e4d164b3723efdda6371ec008a95cffe2c32557f9ad81d955cae32'
BIND=N/'family_visual_material_loading_repair01/closure_READY01/finish8_binding_READY.json'
BIND_SHA='26b8b652aaa73a93c3123ff4287be63d6952124a6ce9b424c27aa2a30d316ff5'
AXIS=N/'author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json'
AXIS_SHA='2b17aa92d9b034fc914fa2c643a41b6301da7218c1422492e5f1128b80083731'

def sha(b):return hashlib.sha256(b).hexdigest()
def pin(path,wanted):
    b=path.read_bytes();assert sha(b)==wanted,(str(path),sha(b),wanted);return b
def jsonfile(path,wanted):return json.loads(pin(path,wanted))
def f(x):return float(np.float32(x))
def vec(a):return np.asarray(a,dtype=np.float32)
def arr(a):return [float(x) for x in a]
def project(p,anchor,ratio,foot):return arr(vec(foot)+(vec(p)-vec(anchor))*float(ratio))
def box(points):return [min(p[0] for p in points),min(p[1] for p in points),max(p[0] for p in points),max(p[1] for p in points)]
def intersection(a,b):
    c=[max(a[0],b[0]),max(a[1],b[1]),min(a[2],b[2]),min(a[3],b[3])]
    return c if c[0]<c[2] and c[1]<c[3] else None
def closed(a):return [math.ceil(a[0]),math.ceil(a[1]),math.floor(a[2]),math.floor(a[3])]
def expand(a,x,y):return [a[0]-x,a[1]-y,a[2]+x,a[3]+y]
def respath(p):return 'res://'+str(p.relative_to(G)).replace('\\','/')
def write(name,v):
    b=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
    with (OUT/name).open('xb') as stream:stream.write(b)
    return {'path':respath(OUT/name),'sha256':sha(b),'bytes':len(b)}

assert not OUT.exists(),'NEW output only'
design=jsonfile(DESIGN,DESIGN_SHA);binding=jsonfile(BIND,BIND_SHA);axis=jsonfile(AXIS,AXIS_SHA)
text=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope={'struct':struct};exec(text[text.index('class FrozenVariant:'):text.index('binding_pin=')],scope)
payloads={};parentpins={}
for sid in {lot['scene_id'] for lot in design['lots']}|{'luoyang_artisan_residential_20261022ap','luoyang_estate_riverside_20261021ai'}:
    p=binding['scenes'][sid]['payload'];raw=pin(G/p['path'][6:],p['sha256']);decoder=scope['FrozenVariant'](raw)
    payloads[sid]=decoder.value();assert decoder.p==len(raw);parentpins[sid]=p

texture_cache={};texture_sources={}
def texture(path):
    if path in texture_cache:return texture_cache[path]
    file=G/path[6:];raw=file.read_bytes();texture_sources[path]={'sha256':sha(raw),'bytes':len(raw)}
    if file.suffix.lower()=='.png':
        with Image.open(file) as im:
            alpha=im.convert('RGBA').getchannel('A');size=im.size;bbox=alpha.getbbox()
    elif file.suffix.lower()=='.tres':
        t=raw.decode('utf8');m=re.search(r'path="(res://[^\"]+\.png)"',t);r=re.search(r'region = Rect2\(([^)]+)\)',t)
        if not m or not r:raise ValueError(('UNSUPPORTED_TEXTURE_RESOURCE',path))
        region=[int(float(x.strip())) for x in r.group(1).split(',')];texture(m[1])
        with Image.open(G/m[1][6:]) as im:
            alpha=im.convert('RGBA').getchannel('A').crop((region[0],region[1],region[0]+region[2],region[1]+region[3]))
            size=tuple(region[2:]);bbox=alpha.getbbox()
    else:raise ValueError(('UNSUPPORTED_TEXTURE',path))
    texture_cache[path]=(size,bbox);return size,bbox

def row_a1(row):
    size,bbox=texture(row['texture'])
    if row.get('gate_atlas_region') is not None:
        region=[int(x) for x in row['gate_atlas_region']]
        with Image.open(G/row['texture'][6:]) as im:
            bbox=im.convert('RGBA').getchannel('A').crop((region[0],region[1],region[0]+region[2],region[1]+region[3])).getbbox()
        size=tuple(region[2:])
    if bbox is None:return None # Exact transparent atlas blockers still retain their physical-domain guards.
    render=vec(row.get('render_size_px',size));scale=vec([float(render[0])/size[0],float(render[1])/size[1]])
    pos=vec(row['pos'])*vec([3072,2048]);origin=pos-render*.5 if row.get('centered',True) else pos
    return box([arr(origin+vec([x,y])*scale) for x,y in [(bbox[0],bbox[1]),(bbox[2],bbox[1]),(bbox[2],bbox[3]),(bbox[0],bbox[3])]])

lots=[];audit=[]
for lot in design['lots']:
    piece=lot['new_piece'];asset=design['reuse_assets'][piece['asset_id']];p=payloads[lot['scene_id']]
    size,bbox=texture(asset['texture']);assert list(size)==asset['source_size_px'] and list(bbox)==asset['complete_A1_xyxy']
    assert texture_sources[asset['texture']]['sha256']==asset['source_sha256']
    ground=[project(point,asset['source_ground_anchor_px'],piece['scale'],piece['foot_px']) for point in asset['true_ground_polygon_px']]
    a1=box([project([x,y],asset['source_ground_anchor_px'],piece['scale'],piece['foot_px']) for x,y in [(bbox[0],bbox[1]),(bbox[2],bbox[1]),(bbox[2],bbox[3]),(bbox[0],bbox[3])]])
    domain=closed(box(ground));assert domain[0]<=domain[2] and domain[1]<=domain[3]
    top=vec(piece['foot_px'])-vec(asset['source_ground_anchor_px'])*float(piece['scale'])
    render=vec(size)*float(piece['scale']);pos=(top+render*.5)/vec([3072,2048])
    row={'id':piece['id'],'texture':asset['texture'],'source_sha256':asset['source_sha256'],'pos':arr(pos),'render_size_px':arr(render),'centered':True,'sort_by_feet':True,'depth_sort_foot_y':float(piece['foot_px'][1])/2048.0,'world_foot_px':piece['foot_px'],'physical_center_px':piece['foot_px'],'collision_size_px':[0,0],'blocking':True,'city_v3_solid_polygons_px':[ground]}
    full_a1_intersections=[];skipped_ground=[]
    for old in p['effective_navigation']:
        if not old.get('texture'):continue
        if not old.get('sort_by_feet') and not old.get('blocking') and not old.get('gate_module_object'):
            skipped_ground.append(old['id']);continue
        bounds=row_a1(old)
        if bounds is None:
            skipped_ground.append({'id':old['id'],'reason':'exact atlas region has zero alpha; physical blocker still retained'})
            continue
        cross=intersection(a1,bounds)
        if cross:full_a1_intersections.append({'id':old['id'],'texture':old['texture'],'old_complete_A1_f32':bounds,'envelope_intersection_xyxy':cross,'status':'CONSERVATIVE_A1_ENVELOPE_CONFLICT_REQUIRES_EXPLICIT_REJECTION_OR_SOURCE_ROLE_REVIEW_NOT_PIXEL_ALPHA_PROOF'})
    route_candidates=[];old_route_sources=[];npc_sources=[]
    if lot['scene_id'] in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen']:
        source=next(s for s in axis['scenes'] if s['scene_id']==lot['scene_id'])
        old_route_sources.append(source['original_routes_source']);npc_sources=source['original_NPC_source_guards']
        for category in ['new_source_routes','affected_old_route_replacements']:
            for route in source[category]:
                points=route.get('points_px',route.get('new_points_px',[]))
                if points and intersection(expand(box(points),17,12),box(ground)):
                    route_candidates.append({'category':category,'row':route,'reason':'whole_Player34x24_swept_AABB_intersects_new_ground_bbox_only; exact_finite_leg_check_required'})
    else:
        old_route_sources.append({'path':respath(N/'author_adjacent_four_fields08_loading_clear_portal_NOTREADY.json'),'sha256':'faf779e271859b267d5ee05f8cf364320e8b2bf6acbc3866355ba4caca4ccfde','selector':'scenes[scene_id=ch4_s3_luoyang_market].new_source_routes + retained route inheritance','no_old_all_routes_replay':True})
        npc_sources=[{'source':'current Market fixed original sources + unchanged task/NPC source expressions; only actors whose full body/patrol envelope meets this one domain','status':'FINITE_QA_INPUT_REQUIRES_COMPLETE_FIXED_TABLE_NOT_CURRENT_OBSERVATION'}]
    lots.append({'lot_id':lot['lot_id'],'scene_id':lot['scene_id'],'role':lot['role'],'source_asset':asset,'foot_px':piece['foot_px'],'uniform_scale':piece['scale'],'full_complete_A1_world_f32_xyxy':a1,'new_ground_polygon_world_f32':ground,'closed_domain_xyxy':domain,'domain_pixels':(domain[2]-domain[0]+1)*(domain[3]-domain[1]+1),'candidate_render_row':row,'parent_payload':parentpins[lot['scene_id']],'all_original_rows_and_portals_NPCs_unchanged':True,'exact_anchors_only_no_snap_or_resize':True,'source_A1_envelope_admission':'REJECT_FIXED_ANCHOR_ENVELOPE_CONFLICT_NO_AUTO_REPAIR' if full_a1_intersections else 'A1_ENVELOPE_COMPONENT_CLEAR_ONLY_FINITE_QA_PENDING'})
    audit.append({'lot_id':lot['lot_id'],'full_A1_envelope_conflicts':full_a1_intersections,'ground_layer_rows_excluded_from_roof_comparison':skipped_ground,'near_new_axis_route_rows':route_candidates,'original_route_sources':old_route_sources,'original_NPC_sources':npc_sources,'strict_finite_required':['new domain source-mask support + parent complete solids','all current affected portal polygons/return feet with Player34x24','complete fixed original NPC/patrol body envelopes','only old route legs whose full body sweep meets domain','complete A1 envelopes vs fixed architecture/trees/lamps, no opacity/depth hiding'],'decision':'REJECT_FIXED_ANCHOR_ON_ANY_CONFIRMED_CONFLICT; PENDING_INDEPENDENT_FINITE_QA_NOT_ADMITTED'})

artisan=payloads['luoyang_artisan_residential_20261022ap'];cart=next(r for r in artisan['effective_navigation'] if r['id']=='ap_carpentry_cart_v2');forge=next(r for r in artisan['effective_navigation'] if r['id']=='new_open_forge')
stamp='res://art/modules/luoyang_shore_market_20261020ae/decal_docks_cart_ruts_horizontal_v1.png';ss,sb=texture(stamp)
# ENV center branch inherits Sprite2D.centered=true: subtract HALF the canvas.
# BUILD01's cart-only full-canvas subtraction was a Source model error, retained.
stamp_origin=vec([1180,1810])-vec(ss)*.16*.5
stamp_a1=box([arr(stamp_origin+vec([x,y])*.16) for x,y in [(sb[0],sb[1]),(sb[2],sb[1]),(sb[2],sb[3]),(sb[0],sb[3])]])
stamp_cross=[]
for row in artisan['effective_navigation'][118:]:
    if row.get('texture'):
        a=row_a1(row);c=intersection(stamp_a1,a)
        if c:stamp_cross.append({'id':row['id'],'complete_A1':a,'intersection_xyxy':c,'relationship':'under_cart_intended_only_if_this_is_cart; other_roof_or_supply_relation_requires_review'})
cart_report={'status':'READONLY_EXACT_PROPOSAL_NOT_APPLIED','BUILD01_cart_model_rejected':'Full-canvas subtraction was incorrect; this successor faithfully uses original ENV Sprite2D centered=true. No prior Source/engine artifact overwritten.','current_ENV_author':{'path':'res://data/maps/luoyang_full_city_20261022ap/environment.json','sha256':'64a7efc81a2d37c588c4d63b302324ff9b2eb90cea932de543e85177e8a4afd2'},'selector':['scenes','luoyang_artisan_residential_20261022ap','ground',0],'exact_before_center':[610,1535],'proposed_center':[1180,1810],'uniform_scale':.16,'actual_texture_size':list(ss),'strict_A1_source_bbox':list(sb),'whole_A1_world_f32':stamp_a1,'cart_row':cart,'forge_A1_world_f32':row_a1(forge),'complete_A1_intersections':stamp_cross,'body_NAV_change':False,'no_PNG_edit':True,'decision':'RENDER_ONLY_SOURCE_PROPOSAL_REQUIRES_ROOT_ROLE_REVIEW; KEEP_SCALE_AND_NO_AUTO_MOVE'}

estate=payloads['luoyang_estate_riverside_20261021ai'];shrine=next(r for r in estate['effective_navigation'] if r['id']=='finish_i_estate_family_ancestral_wing')
oldwing=next(r for r in estate['effective_navigation'] if r['id']=='estate_al_door_west_wing')
shrine_report={'status':'READONLY_REUSE_PROPOSAL_NOT_APPLIED','actual_E_image':'res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_families12_ROOT_READY/FAMILY_E_ESTATE_TWO_REAL_HERO_RESIDENTS_output_ROOT_READY/119312_2691/1_01_actual_NPC_hero_first_portrait.png','observed_limitation':'Original open wing doorway visibly reveals grass behind it; no claim of physical or portal fault.','existing_adopted_mechanism':{'publisher':'res://build/luoyang_estate_courtyard_20261021al_system01/revision2/publish_and_preview_visual_candidate.gd','selector':'door_rows: real Atlas material, source metadata door_clear_rect_px grow3, facade original uniform scale, warm modulation, facade foot-depth minus1','atlas':'res://build/luoyang_estate_courtyard_20261021al_system01/textures/wing_door_depth.tres','atlas_sha256':'61c70b6f98c4c399ae4356ccba9151d2621b6833a8c71ed1b2cf8a79e1ee4efd','source_texture':'res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png','source_region_xywh':[432,208,248,369],'modulate':[.46,.42,.38,1]},'existing_same_asset_door_row':oldwing,'new_shrine_parent_row':shrine,'proposal':'One backdrop child bound to this exact facade/parent row and original SAME wing source door rectangle. Reuse wing Atlas, not hall crop (different door aspect). Place behind unchanged facade at same original depth minus1; no pixel editing/body/NAV/new portal. Do not globally reuse the old count3 publisher or fake a new interior.','required_next':['fixed C210 wing metadata door_clear_rect_px and shrine scale/anchor source expression','same parent node/foot/depth identity and inherited exact source texture tuple','render-only row provenance/source-FIRST and finite depth-ID admission, no generic unknown-ID bypass','one limited actual view after Root approval'],'no_functional_candidate_written':True}

OUT.mkdir()
author={'schema':1,'status':'ROOT_APPROVED_ANCHORS_SOURCE_AUTHOR_BUILD_ONLY_NOT_QA_PASS','ready':False,'parent_binding':{'path':respath(BIND),'sha256':BIND_SHA},'design_authority':{'path':respath(DESIGN),'sha256':DESIGN_SHA},'parent_actual_root_label':'377B31; Root actual source deployment, not a new observed expectation','counts':{'new_rows':5,'new_ground_polygons':5,'new_roofs':0,'new_NPCs':0,'new_portals':0},'source_coordinate_expression':'Vector2f32(foot)+(Vector2f32(source_point)-Vector2f32(anchor))*float64_ratio; source schema values exact, no epsilon','lots':lots,'unrelated_components_inherited':True,'engine_calls':0,'Stage_calls':0,'collector_calls':0,'canonical_writes':0}
results={}
results['author']=write('author_five_street_edges01_NOTREADY.json',author)
results['finite_plan']=write('finite_five_domains_A1_route_NPC_plan_READONLY.json',{'status':'SOURCE_SELF_AUDIT_NOT_INDEPENDENT_PRIOR_NOT_RUNTIME_PASS','new_domain_pixels_total':sum(x['domain_pixels'] for x in lots),'lots':audit,'texture_physical_read_facts':texture_sources,'original_source_classification_and_registered_edges_untouched':True,'old_global_geometry_replay':False})
results['cart']=write('cart_ruts11801810_source_relationship_READONLY.json',cart_report)
results['shrine']=write('estate_shrine_door_depth_reuse_READONLY.json',shrine_report)
results['handoff']=write('handoff_BUILD_ONLY.json',{'status':'NEW_BUILD_ONLY_NO_CLOSURE_NO_ENGINE','artifacts':results.copy(),'all_5_fixed_anchors_no_auto_repair':True,'Root_approval_before_any_publication_or_stage':True})
print(json.dumps(results,ensure_ascii=False))
