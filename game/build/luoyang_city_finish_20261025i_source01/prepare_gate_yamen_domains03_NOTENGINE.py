"""Current ROOT parent seed + declared new source shapes; no native re-decode."""
from pathlib import Path
import copy,hashlib,json,math,re,struct
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def f(v):return struct.unpack('<f',struct.pack('<f',float(v)))[0]
def fixed(p,h):
    raw=p.read_bytes();assert sha(raw)==h,str(p)
    return json.loads(raw)
def out(n,v):
    raw=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    with (HERE/n).open('xb') as stream:stream.write(raw)
    return {'path':NS+n,'sha256':sha(raw),'bytes':len(raw)}
def decode(v):
    if not isinstance(v,dict):return v
    if v.get('type')=='Dictionary':return {r['key']:decode(r['value']) for r in v['entries']}
    if v.get('type')=='Array':return [decode(x) for x in v['values']]
    if v.get('type')=='StringName':return v['value']
    if v.get('type') in ['Vector2','PackedVector2Array']:
        b=bytes.fromhex(v['f32_le_hex']);flat=struct.unpack('<'+'f'*(len(b)//4),b)
        return list(flat) if v['type']=='Vector2' else [list(flat[i:i+2]) for i in range(0,len(flat),2)]
    return v
seed_report_path=HERE/'parent_projection01_ROOT_READY/output_ROOT_READY/result.json'
report=fixed(seed_report_path,'5e529bb83888eb65e6e5976ed86d15b6a82f299a8b3e0a63131636cb3623bc30')
assert report['complete'] and report['failures']==0 and report['native_decode_count']==2
seed=decode(report['primitive_source_seed'])
author=fixed(HERE/'author_gate_yamen_axis02_NOTREADY.json','24bc2a809487bb17747661827486d1479538491732cf4aed79fba2a1091380e6')
library=fixed(HERE/'reuse_asset_library01_SOURCE_ONLY.json','17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d')
stage=fixed(GAME/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json','ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5')
authority={}
for k,r in stage['nodes'].items():
    if k.startswith('expected_'):authority.update(r['value']['source_sha256'])
for r in stage['targets']:authority[r['target']]=r['candidate_sha256']
dg_path='res://data/maps/luoyang_district_life_20261016f/author.json'
dg=fixed(GAME/dg_path[6:],authority[dg_path])
def source(p):return fixed(GAME/p[6:],authority[p])
parentseed={'path':NS+'parent_projection01_ROOT_READY/output_ROOT_READY/parent_source_seeds.bin','sha256':'dfd5162f2668f599a1e3362298eb1953778d9339c59069a738c732d0ef849486','actual_parent_only_not_new_expected':True}
roots=[]
def closed(poly):
    lo=[min(q[i] for q in poly) for i in range(2)];hi=[max(q[i] for q in poly) for i in range(2)]
    return [max(0,math.floor(lo[0])-1),max(0,math.floor(lo[1])-1),min(3071,math.ceil(hi[0])+1),min(2047,math.ceil(hi[1])+1)]
def domains(polys):
    result=[]
    for poly in polys:
        current=closed(poly);again=True
        while again:
            again=False
            for i,r in enumerate(result):
                if current[0]<=r[2]+1 and current[2]+1>=r[0] and current[1]<=r[3]+1 and current[3]+1>=r[1]:
                    current=[min(current[0],r[0]),min(current[1],r[1]),max(current[2],r[2]),max(current[3],r[3])]
                    result.pop(i);again=True;break
        result.append(current)
    return sorted(result,key=lambda r:(r[1],r[0],r[3],r[2]))
def binarypoly(poly):return b''.join(struct.pack('<ff',*p) for p in poly).hex()
for scene in author['scenes']:
    sid=scene['scene_id'];parent=seed[sid]
    old_geometry=parent['render_primitive_rows']
    parent_render=parent['effective_parent_render'];old_ids=[r['id'] for r in parent_render]
    assert len(set(old_ids))==len(old_ids)
    if sid=='ch4_s0_luoyang_gate':
        assert len(parent_render)==39 and len(old_geometry)==39
        scene['object_migrations'][0]['new_foot_px']=[1160,1490]
    else:assert len(parent_render)==35 and len(old_geometry)==40 and len(parent['courts_source_40'])==40
    scene['parent_source_seed']=parentseed
    scene['parent_seed_report']={'path':NS+'parent_projection01_ROOT_READY/output_ROOT_READY/result.json','sha256':'5e529bb83888eb65e6e5976ed86d15b6a82f299a8b3e0a63131636cb3623bc30'}
    scene['parent_record_and_render_body_bytes_sha256']=parent['record_and_render_body_bytes']
    scene['parent_render_count']=len(parent_render);scene['parent_primitive_count']=len(old_geometry)
    scene['parent_ordered_render_ids']=old_ids
    retires=set(scene.get('retire_exact_visual_ids',[]))
    moves={r['id']:r for r in scene.get('object_migrations',[])}
    assert retires.issubset(set(old_ids)) and set(moves).issubset(set(old_ids))
    changed_old=[];changed_new=[];new_geometry=[]
    for primitive in old_geometry:
        row=copy.deepcopy(primitive);owner=row['owner_id']
        if owner in retires:changed_old.append(row);continue
        if owner in moves:
            move=moves[owner]
            native=next(r for r in parent_render if r['id']==owner)
            assert native['world_foot_px']==move['old_foot_px']
            delta=[f(f(move['new_foot_px'][i])-f(move['old_foot_px'][i])) for i in range(2)]
            changed_old.append(copy.deepcopy(row))
            row['points_px']=[[f(f(p[i])+delta[i]) for i in range(2)] for p in row['points_px']]
            changed_new.append(copy.deepcopy(row))
        new_geometry.append(row)
    additions=[]
    for placement in scene['placements']:
        assert placement['id'] not in old_ids
        for i,points in enumerate(placement['source_derived_new_ground_polygons_f32']):
            row={'id':placement['id']+'_poly_'+str(i),'owner_id':placement['id'],'kind':'NEW_SOURCE_AUTHORED_GROUND_POLYGON','points_px':points}
            additions.append(row);new_geometry.append(row)
    new_ids=[id for id in old_ids if id not in retires]+[r['id'] for r in scene['placements']]
    scene['exact_retired_or_relocated_parent_primitive_rows']=changed_old
    scene['exact_relocated_new_primitive_rows']=changed_new
    scene['new_asset_primitive_rows']=additions
    scene['new_ordered_render_ids']=new_ids
    scene['new_render_count']=len(new_ids);scene['new_primitive_count']=len(new_geometry)
    scene['old_retained_primitive_order_and_values_preserved']=True
    scene['new_all_primitive_rows_source_model']=new_geometry
    local=domains([r['points_px'] for r in changed_old+changed_new+additions])
    scene['local_closed_integer_domains_xyxy']=local
    scene['local_domain_max_visited_pixels']=sum((r[2]-r[0]+1)*(r[3]-r[1]+1) for r in local)
    scene['domain_formula']='For exact f32 old/new primitive bbox: floor(min)-1..ceil(max)+1 inclusive, clamp0..3071/2047; iteratively bbox-merge closed integer overlap/adjacency, sort(y0,x0,y1,x1). No epsilon or visual bbox.'
    scene['mask_recipe']='Copy exact current parent effective mask; only in these domains use fixed original raw support AND complement of every retained+new primitive. Never white-brush retired holes; old outside RGBA inverse exact.'
    parent_manifest=dg['districts'][sid]['parent_manifest'];old_manifest=fixed(GAME/parent_manifest['path'][6:],parent_manifest['sha256'])
    roots.append(parent_manifest)
    raw_support=old_manifest['record']['raw_walk_path']
    scene['raw_support_source']={'path':raw_support,'sha256':authority[raw_support],'not_decoded_by_Source':True}
    if sid=='ch4_s0_luoyang_gate':
        native_manifest_path=parent['fixed_packet']['path'].replace('packet.bin','manifest.json')
        native_manifest=source(native_manifest_path)
        mask_path=old_manifest['record']['walk_path']
        assert old_manifest['walk_sha256']==authority[mask_path]
        scene['parent_mask_source']={'path':mask_path,'sha256':authority[mask_path],
          'RGBA_sha256':native_manifest['mask_sha256'],
          'source_declaration':{'path':native_manifest_path,'sha256':authority[native_manifest_path],'pointer':['mask_sha256']},
          'parent_native_primitive_count':28,'effective_render_primitive_count':39,
          'not_claiming_old_mask_already_rasterized_all_DG_primitives':True,'not_decoded_by_Source':True}
        scene['same_interaction_migrations']=[]
        for row in old_manifest['record']['gameplay_slots']['interactions']:
            assert row['source_id'] in ['luoyang_wanted_board','luoyang_repeatable_bounty_board'] and row['stand_px']==[700,1460]
            scene['same_interaction_migrations'].append({'id':row['source_id'],'visual_object_id':'notice_pavilion','old_stand_world_px':row['stand_px'],'new_stand_world_px':[1160,1550],
             'old_interaction_polygon_world_px':row['interaction_polygon_px'],'new_interaction_polygon_world_f32':[[f(f(p[0])+460),f(f(p[1])+90)] for p in row['interaction_polygon_px']],
             'action_flags_rewards_stage_and_identity_unchanged':True})
        scene['affected_old_route_replacements']=[
         {'id':'public_loop','old_points_px':next(r['points_px'] for r in old_manifest['record']['routes'] if r['id']=='public_loop'),
          'new_points_px':[[1536,1390],[900,1390],[470,1390],[470,1510],[1050,1510],[1536,1510],[2130,1510],[2130,1390],[2660,1390],[2660,1510],[2130,1510],[1536,1510],[1536,1390]],'reason':'Only old y1280 lateral legs cross new two annex bases'},
         {'id':'notice_approach','old_points_px':next(r['points_px'] for r in old_manifest['record']['routes'] if r['id']=='notice_approach'),'new_points_px':[[1536,1550],[1160,1550]],'reason':'Both same original board IDs follow the same moved visible Notice'}]
        scene['new_source_routes']=[
         {'id':'west_inspection_front','points_px':[[1536,1390],[1120,1390],[650,1390]]},
         {'id':'west_gallery_clear_side_to_front','points_px':[[650,1390],[470,1390],[470,1772],[650,1772]]},
         {'id':'west_goods_front_inside_open_gallery','points_px':[[650,1772],[650,1718]]},
         {'id':'east_inspection_front','points_px':[[1536,1390],[2130,1390],[2490,1390]]},
         {'id':'east_gallery_front','points_px':[[1536,1790],[2160,1790],[2490,1790]]},
         {'id':'notice_two_original_tasks','points_px':[[1536,1550],[1160,1550]]}]
        scene['original_routes_source']={'manifest':parent_manifest,'pointer':['record','routes'],'unchanged_rows':['south_avenue'],'no_original_route_replay':True}
        scene['original_NPC_source_guards']=[{'manifest':parent_manifest,'pointer':['record','npc_stations']},{'script_path':'res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd','sha256':authority['res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd'],'selector':'spec(A.IDS[0]) ten exact rows; guard each authored patrol distance and34x30, no coordinate migrations'}]
        assert len(new_ids)==41 and len(new_geometry)==47
    else:
        courtsp='res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/binding_READY.json';cb=source(courtsp)
        scene['parent_mask_source']={'path':cb['mask']['path'],'sha256':cb['required_source_sha256'][cb['mask']['path']],'RGBA_sha256':cb['mask']['RGBA_sha256'],'not_decoded_by_Source':True}
        scene['affected_old_route_replacements']=[]
        scene['new_source_routes']=[
         {'id':'west_archive_front','points_px':[[1040,750],[846,750],[846,680],[590,680]]},
         {'id':'east_runner_house_front','points_px':[[2040,800],[2224,800],[2224,680],[2664,680]]},
         {'id':'new_artisan_west_branch','points_px':[[300,1260],[120,1260],[120,1240]]}]
        scene['original_routes_source']={'manifest':parent_manifest,'pointer':['record','routes'],'Temple_Room_replay':False,
           'T_additional_source':{'path':'res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json','sha256':authority['res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json'],'pointer':['districts',sid,'additional_routes']},
           'current24c_short_routes':{'path':'res://build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json','sha256':authority['res://build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json'],'pointer':['proposed_short_routes']},
           'only_segments_whose_body_bbox_intersects_new_domains_need_new_checks':True}
        scene['original_NPC_source_guards']=[{'manifest':parent_manifest,'pointer':['record','npc_stations']},
           {'path':dg_path,'sha256':authority[dg_path],'pointer':['districts',sid,'crowd'],'terminal_clerk_override':{'path':'res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/yamen_clerk_overlay_PENDING.json','sha256':authority['res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/yamen_clerk_overlay_PENDING.json'],'selector':'new_spec.crowd; yamen_clerk actual11301360, not historical12601500'}}]
        assert len(new_ids)==37 and len(new_geometry)==42
    scene['independent_new_domain_prior_and_route_credit']=False
    scene.pop('affected_domains_provisional_xywh',None)
    scene['domain_status']='EXACT_SOURCE_F32_PRIMITIVES_CLOSED_DOMAIN_MODEL_WAITING_INDEPENDENT_QA'
author['Root_approved_normal_layout_notice_adaptation']='Notice11601490 and two original task stands11601550; no NPC/task logic changes'
author['source_parent_JSON_declaration_pins']=roots
author['all_old_parent_decode_and_parse_actuals_inherited']=True
pin=out('author_gate_yamen_axis03_exact_domains_NOTREADY.json',author)
summary={'status':'GATE_YAMEN_EXACT_OLD_PARENT_AND_NEW_SOURCE_DOMAIN_MODEL_NOT_QA_OR_RUNTIME_PASS','ready':False,'author':pin,'parent_seed':parentseed,'scenes':[{'scene_id':s['scene_id'],'old_render':s['parent_render_count'],'new_render':s['new_render_count'],'old_primitives':s['parent_primitive_count'],'new_primitives':s['new_primitive_count'],'closed_domains':s['local_closed_integer_domains_xyxy'],'domain_visited_budget':s['local_domain_max_visited_pixels'],'route_ids':[r['id'] for r in s['new_source_routes']]} for s in author['scenes']],'engine_calls':0,'packet_decodes_this_preparation':0,'collector_calls':0,'new_geometry_PIP_mask_or_Physics_pass':False}
print(json.dumps({'author':pin,'summary':out('gate_yamen_new_domain_summary03_NOTREADY.json',summary)},ensure_ascii=False))
