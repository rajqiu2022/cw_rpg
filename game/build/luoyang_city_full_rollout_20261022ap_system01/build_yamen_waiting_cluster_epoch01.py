"""NEW finite Yamen proposal: fixed-source declarations and conservative static planning.

No PNG decode/edit, engine, native write, admission metadata or canonical mutation.
"""
from pathlib import Path
import copy, hashlib, json, re, struct

ROOT = Path(__file__).resolve().parent
GAME = ROOT.parent.parent
REPO = GAME.parent
OUT = ROOT / 'yamen_waiting_cluster_epoch01'
SCENE = 'ch4_s1_luoyang_yamen'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p): return 'res://' + p.relative_to(GAME).as_posix()
def source(p):
    return {'path': res(p) if p.is_relative_to(GAME) else p.relative_to(REPO).as_posix(), 'sha256': sha(p), 'bytes': p.stat().st_size}
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def save(name, value):
    p = OUT / name
    assert not p.exists(), p
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return source(p)
def box(points): return [min(p[0] for p in points), min(p[1] for p in points), max(p[0] for p in points), max(p[1] for p in points)]
def overlaps(a,b): return not (a[2] < b[0] or b[2] < a[0] or a[3] < b[1] or b[3] < a[1])
def grow(b,x,y): return [b[0]-x,b[1]-y,b[2]+x,b[3]+y]
def strict_same(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return a.keys()==b.keys() and all(strict_same(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(strict_same(x,y) for x,y in zip(a,b))
    return a==b

fixture_path = ROOT.parent/'luoyang_city_full_rollout_20261022ap_qa01/bounded_groups_v5_author_anchors_READY.json'
assert sha(fixture_path)=='56af9d883a163e6cd0646f6ef4b394e46fc2c29e10baf254fc5d0bc548ee618d'
scene = next(s for s in load(fixture_path)['scenes'] if s['id']==SCENE)
geometry = scene['geometry']
assert geometry['source_size_px']==[3072,2048] and geometry['foot_forbidden_regions_px']==[]
old_solids = geometry['solids']
assert len(old_solids)==39
author_path = GAME/'data/maps/luoyang_district_life_20261016f/author.json'
assert sha(author_path)=='d98c65879681b58fee a64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c'.replace(' ','')
author = load(author_path)
district = author['districts'][SCENE]
assert len(district['crowd'])==6 and len(district['placements'])==10
clerk = next(r for r in district['crowd'] if r['id']=='yamen_clerk')
assert clerk=={'id':'yamen_clerk','name':'书办','family':'merchant','foot_px':[1260,1500],'distance_px':0}

def asset(identifier, room, expected_sha):
    room_path = GAME/f'data/maps/luoyang_assembled_interiors_20261016g/{room}_author.json'
    furniture = next(r for r in load(room_path)['furniture'] if r['asset_id']==identifier)
    p = GAME/furniture['texture'].removeprefix('res://')
    assert sha(p)==expected_sha==furniture['source_sha256']
    header=p.read_bytes()[:24]
    assert header[:8]==b'\x89PNG\r\n\x1a\n' and list(struct.unpack('>II',header[16:24]))==[1536,1024]
    meta_path=REPO/f'assets/raw/luoyang_interiors_assembly_20261016g/{identifier}.meta.json'
    meta=load(meta_path)
    assert meta['sha256']==expected_sha and meta['actual_size_px']==[1536,1024]
    assert meta['source_geometry']['source_ground_anchor_px']==furniture['source_ground_anchor_px']
    assert meta['source_geometry']['ground_solid_polygons_px']==furniture['source_ground_solid_polygons_px']
    side=p.with_name(p.name+'.import')
    text=side.read_text(encoding='utf-8')
    ctex=GAME/re.search(r'^path="(res://[^\"]+)"',text,re.M)[1].removeprefix('res://')
    assert f'source_file="{res(p)}"' in text and ctex.exists()
    return {'asset_id':identifier,'texture':res(p),'source_size_px':[1536,1024],
        'source_ground_anchor_px':furniture['source_ground_anchor_px'],
        'source_ground_solid_polygons_px':furniture['source_ground_solid_polygons_px'],
        'existing_interior_author':source(room_path),'existing_row_id':furniture['id'],
        'source_geometry_metadata':source(meta_path),'media_three_leaves':[source(p),source(side),source(ctex)],
        'alpha_bbox_nonzero_xyxy':meta['bbox_nonzero'],'alpha_bbox_ge8_xyxy':meta['bbox_alpha_ge8'],
        'strict_zero_alpha_10pct_margin_pass':False,
        'admission':'Already referenced interior media, NOT newly approved outdoor art. Full source unchanged, no crop/threshold/background processing.',
        'visual_observation':'Viewed complete existing PNG; weak-alpha brown contact surround remains, requires true alpha compositing outdoors before art acceptance.'}

bench=asset('long_bench_v1','herbal_shop','41759460141f9a6ba742d5df9d2de3fce10ba040af5a86fa8f31bd540877108e')
desk=asset('writing_desk_v1','general_stall','8c1011e8c1695c68bba232730bc64d2296aed6b739cbc59ce413aed4df3c4837')
placements=[]
for identifier,a,foot,scale,purpose in [
    ('ap_yamen_waiting_bench_north',bench,[1140,1170],.12,'候见长凳；不是站立/坐姿动画点'),
    ('ap_yamen_waiting_bench_south',bench,[1140,1290],.12,'第二条候见长凳，留出120px排距'),
    ('ap_yamen_petition_writing_desk',desk,[1130,1450],.12,'代书案：笔砚书册一体，西侧候见簇，主轴不设摊桌')]:
    anchor=a['source_ground_anchor_px']
    polys=[[[round(foot[0]+(x-anchor[0])*scale,6),round(foot[1]+(y-anchor[1])*scale,6)] for x,y in poly] for poly in a['source_ground_solid_polygons_px']]
    canvas=[round(foot[0]-anchor[0]*scale,6),round(foot[1]-anchor[1]*scale,6),round(foot[0]+(1536-anchor[0])*scale,6),round(foot[1]+(1024-anchor[1])*scale,6)]
    strong=a['alpha_bbox_ge8_xyxy']
    strong_world=[round(foot[i%2]+(strong[i]-anchor[i%2])*scale,6) for i in range(4)]
    placements.append({'id':identifier,'asset_id':a['asset_id'],'foot_px':foot,'uniform_scale':scale,'rotation':0,
        'ground_solid_polygons_px':polys,'canvas_aabb_xyxy':canvas,'visible_ge8_aabb_xyxy':strong_world,
        'height_behavior':'LOW_OPAQUE_ACTOR_LOCAL_GHOST','actor_body_collision':'solid full source authored under-table/bench footprint; no table-top standing',
        'purpose':purpose})
new_solids=[{'id':r['id']+'_poly_'+str(i),'points_px':poly} for r in placements for i,poly in enumerate(r['ground_solid_polygons_px'])]
for i,s in enumerate(new_solids):
    assert not any(overlaps(box(s['points_px']),box(old['points_px'])) for old in old_solids),s['id']
    assert not any(overlaps(box(s['points_px']),box(other['points_px'])) for other in new_solids[:i]),s['id']

# Swept AABB tests are intentionally conservative and only static raw author planning.
routes=[
    {'id':'preserved_south_gate_to_hall_axis','points_px':[[1536,1860],[1536,1740],[1536,1640],[1536,1240],[1536,740],[1536,660]]},
    {'id':'west_lateral_gate_to_axis','points_px':[[800,1020],[1040,1020],[1360,1020],[1536,1020]]},
    {'id':'axis_to_waiting_face','points_px':[[1536,1320],[1300,1320],[1260,1320],[1260,1170]]},
    {'id':'axis_to_desk_front','points_px':[[1536,1530],[1300,1530],[1130,1530],[1130,1498]]},
    {'id':'clerk_relocation_static_swept_path','points_px':[[1260,1500],[1300,1500],[1300,1360],[1130,1360]]},
    {'id':'future_normal_approach_existing_petitioner','points_px':[[1536,1368],[1750,1368]]}]
checks=[]
for route in routes:
    for index,(p,q) in enumerate(zip(route['points_px'],route['points_px'][1:])):
        swept=grow(box([p,q]),17,15)
        hits=[s['id'] for s in old_solids+new_solids if overlaps(swept,box(s['points_px']))]
        assert hits==[],(route['id'],index,hits)
        checks.append({'route':route['id'],'segment':index,'swept_aabb_xyxy':swept,'intersections':hits})
for npc in district['crowd']:
    foot=[1130,1360] if npc['id']=='yamen_clerk' else npc['foot_px']
    assert not any(overlaps(grow(box([foot]),17,15),box(s['points_px'])) for s in new_solids),npc['id']

child=copy.deepcopy(author)
next(r for r in child['districts'][SCENE]['crowd'] if r['id']=='yamen_clerk')['foot_px']=[1130,1360]
inverse=copy.deepcopy(child)
next(r for r in inverse['districts'][SCENE]['crowd'] if r['id']=='yamen_clerk')['foot_px']=copy.deepcopy(clerk['foot_px'])
assert strict_same(inverse,author)
assert all(not overlaps(placements[i]['canvas_aabb_xyxy'],placements[j]['canvas_aabb_xyxy']) for i in range(3) for j in range(i))
helper=OUT/'pure_yamen_author_delta_candidate.gd'
proposal=save('author_delta_READY.json',{
    'status':'BUILD_ONLY_FINITE_STATIC_PROPOSAL_NOT_NATIVE_OR_RUNTIME_ADMISSION',
    'scene_id':SCENE,'independent_epoch':'Not part of old 29 deployment or pending Router06 23-target source successor.',
    'parent_sources':[source(author_path),source(fixture_path)],'assets':[bench,desk],'placements':placements,
    'existing_npc_change_only':{'json_pointer':'/districts/'+SCENE+'/crowd/3/foot_px','id':'yamen_clerk','before':[1260,1500],'after':[1130,1360],
        'preserve':'Other five actor rows exact, all six IDs/names/families/distances/dialogue/culture/rewards unchanged. No new NPC or seated animation claim.'},
    'preserved':{'hall_door':[1536,660],'hall_approach':[[1536,740],[1536,700],[1536,660]],
        'south_gate_author_feet':[1536,1700],'south_gate_body_clear_width_px':130,
        'central_axis_keep_clear_rect':[1408,660,256,1200],'native_solids':39,'district_placements':10,
        'no_changes':['native39solid geometry','existing notice_pavilion at5501180','two service annexes','all trees/lamps','all doors/portals','RAW ground','ENVrects/shaders','player/body/speed','NPC artwork/dialogue/voice','task/reward logic','source DAG']},
    'new_solids':new_solids,'static_routes':routes,'static_swept_body_half_extent_px':[17,15],
    'static_swept_checks':checks,'npc_new_prop_body_intersections':[],
    'clearances':{'bench_ground_left_to_west_wall_inner_face_px':round(min(p[0] for p in placements[0]['ground_solid_polygons_px'][0])-978,6),
        'bench_strong_visible_height_px':round((786-333)*.12,6),'desk_strong_visible_height_px':round((883-195)*.12,6),
        'main_axis_nearest_new_prop_ground_gap_px':round(1408-max(p[0] for s in new_solids for p in s['points_px']),6),
        'clerk_to_desk_ground_north_gap_px':round(min(p[1] for p in placements[2]['ground_solid_polygons_px'][0])-1360,6)},
    'pure_clerk_overlay':source(helper),'whole_typed_author_inverse_static':True,
    'future_finite_acceptance':['Root approves this separate epoch first; freeze final current source DAG separately, do not rewrite old29/pending23.',
        'One new author compilation must only add3 prop visual/3solid plus move clerkfoot; preserve39oldsolid/10DG placements and all doors. Local mask blackening derived from original RAW/native rules, no blind mask editing.',
        'Only new small footprints/approaches/routes need fresh 34x24+875+17 and affected routes. Outside geometry inherits fixed prior evidence, no all-scene/room rerun.',
        'True alpha outdoor composite and one same-camera finite picture must assess weak-alpha surrounds, tabletop size/depth and wall/actor visibility. Assets strict-margin FAIL remains recorded; no fresh art approval claimed.',
        'Normal INPUT+Space on relocated existing clerk and unchanged cultural petitioner; no reward or task implementation in this proposal.'],
    'engine_runs':0,'image_decodes':0,'canonical_writes':0,'new_media':0})
handoff=save('handoff_READY.json',{'status':'NEW_BUILD_ONLY_PROPOSAL_COMPLETE','proposal':proposal,'pure_helper':source(helper),
    'static_scope':'3 low props + 1 existing non-culture clerk foot; 6 actors total unchanged. Source content/history fixed, no engine.',
    'runtime_or_art_pass':False,'outputs_not_admission':True})
print(json.dumps(handoff))
