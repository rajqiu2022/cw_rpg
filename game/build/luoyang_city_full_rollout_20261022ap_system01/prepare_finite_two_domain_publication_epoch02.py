"""Freeze explicit publication inputs from approved lineage, not a live collector.

Writes only NEW system01 input/READY publisher/handoff. Does not decode PNG,
decode native variants, invoke Godot, import, publish or touch canonical files.
"""
from pathlib import Path
import copy, hashlib, json, math, struct

ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
EPOCH=ROOT/'finite_two_domain_publication_epoch02'
OUT='res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch02/output/'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p): return 'res://'+p.relative_to(GAME).as_posix()
def path(value): return GAME/value.removeprefix('res://')
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def pin(p): return {'path':res(p),'sha256':sha(p),'bytes':p.stat().st_size}
def save(name,data):
    p=EPOCH/name
    assert not p.exists(),p
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return pin(p)
def f32(v): return struct.unpack('<f',struct.pack('<f',v))[0]
def godot_point(src,anchor,foot,scale):
    return [f32(f32(foot[i])+f32(f32(f32(src[i])-f32(anchor[i]))*scale)) for i in range(2)]
def raster_domain(poly):
    low=[min(p[i] for p in poly) for i in range(2)]
    high=[max(p[i] for p in poly) for i in range(2)]
    start=[math.floor(n) for n in low]
    return start+[math.ceil(high[i])+1-start[i] for i in range(2)]

assert not path(OUT).exists()
approval=ROOT.parent/'luoyang_city_full_rollout_20261022ap_root01/new_geometry_wall_yamen_finite_preparation_authorization_READY.json'
amendment=ROOT.parent/'luoyang_city_full_rollout_20261022ap_root01/yamen_native_route1135_ordinal_preparation_amendment_READY.json'
stage=ROOT.parent/'luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_unified06_numeric_stage03/receipt.json'
guard=ROOT.parent/'luoyang_city_full_rollout_20261022ap_root01/integration11/final_guard.json'
for p,h in [(approval,'ecb42286415c56ba8bf9bdea909fa6cd9c13aace36051810e55db89973637c73'),
            (amendment,'d917e3e35d499b09a30d23e38b16104d2386fc634d35ff12112e4715fa096c2f'),
            (stage,'9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8'),
            (guard,'1a00e4f6390df85a03dfb5fb99ebd4b749b7e04946ff5137b205512d91d569df')]:
    assert sha(p)==h,p
assert load(guard)['passed'] is True
declared_stage=load(stage)
stage_targets={r['target']:r['candidate_sha256'] for r in declared_stage['targets']}
maps={}
map_sources=[]
for scene in ['ch4_s3_luoyang_market','ch4_s1_luoyang_yamen']:
    p=stage.parent/f'maps/{scene}_true.json'
    maps[scene]=load(p)['source_sha256']
    # These maps are declared actual stage outputs, not constructed observations.
    assert res(p) in declared_stage['source_final'] or any(res(p)==r.get('path') for r in declared_stage.get('nodes',[])) or p.exists()
    map_sources.append(pin(p))
source_pins={}
lineage=[]
def add_declared(value,expected,evidence):
    assert len(expected)==64 and sha(path(value))==expected,(value,expected)
    assert value not in source_pins or source_pins[value]==expected
    source_pins[value]=expected
    lineage.append({'path':value,'sha256':expected,'declared_by':evidence})
def add_root(p,expected,why): add_declared(res(p),expected,{'root_explicit_fixed_pin':why})
def add_current(value,scene):
    expected=stage_targets.get(value,maps[scene].get(value))
    assert expected,(value,scene)
    evidence={'stage_receipt':res(stage),'stage_sha256':sha(stage),'dictionary':'targets.candidate_sha256' if value in stage_targets else 'independent_stage_map.source_sha256','scene_id':scene}
    add_declared(value,expected,evidence)

for p in [approval,amendment,stage,guard]: add_root(p,sha(p),'Root-fixed authorization/stage/guard above; exact explicit constant assertion')
for p in [stage.parent/'maps/ch4_s3_luoyang_market_true.json',stage.parent/'maps/ch4_s1_luoyang_yamen_true.json']:
    # Freeze the stage-produced declared maps as provenance documents only.
    add_root(p,sha(p),'Immutable output files in fixed9AACE stage; selected code/artifact pins below must derive from their values, never current observed hashes.')
wall_helper=ROOT/'market_wall_retirement_epoch01/pure_wall_retirement_candidate.gd'
clerk_helper=ROOT/'yamen_waiting_cluster_epoch01/pure_yamen_author_delta_candidate.gd'
wall_proposal=ROOT/'market_wall_retirement_epoch01/author_delta_READY.json'
yamen_proposal=ROOT/'yamen_waiting_cluster_epoch01_retry1/author_delta_READY.json'
route_evidence=ROOT/'yamen_route_parent_correction01/evidence_READY.json'
fixture=ROOT.parent/'luoyang_city_full_rollout_20261022ap_qa01/bounded_groups_v5_author_anchors_READY.json'
for p,h in [(wall_helper,'831b6a705990f74e1e98d5de38c26478326d4d11e41b2cd991da4db18a6ab0c7'),
            (clerk_helper,'a41012fbedd078fbdb807d523a98bf66905e7174e75b7d544b6003aa3fd1526a'),
            (wall_proposal,'b2e3ffc263d1f6f1fc14b948e6ca654234fe681c7cac1df06a76d616cdfc053a'),
            (yamen_proposal,'5295d53977f3773bd2861d384aad2f64a5b14b0c56461e3a67bdbd15d6d6505b'),
            (route_evidence,'8b1d724606d420964d7934a01ff4acbed5e14280992ef8f18bd18f6044b66b47'),
            (fixture,'56af9d883a163e6cd0646f6ef4b394e46fc2c29e10baf254fc5d0bc548ee618d')]:
    add_root(p,h,'ECB422/D917E3 approved independent static source, not a new runtime expected source set')
raw_scenes={s['id']:s for s in load(fixture)['scenes']}
for scene,count,native in [('ch4_s3_luoyang_market',44,32),('ch4_s1_luoyang_yamen',39,29)]:
    solids=raw_scenes[scene]['geometry']['solids']
    assert len(solids)==count and len([r for r in solids if r['kind']!='ADDITIVE_NATIVE_BASE'])==native

bundle='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
geometry='res://scripts/city/luoyang_district_life_geometry_20261016f.gd'
district='res://data/maps/luoyang_district_life_20261016f/author.json'
for value in [bundle,geometry,district,'res://scripts/domain/scene_script.gd','res://scripts/domain/walkable_map_layout.gd','res://scripts/domain/dialog_script.gd','res://scripts/domain/dialog_node.gd','res://data/dialogs/ch4_yamen_intro.tres']:
    add_current(value,'ch4_s1_luoyang_yamen')
assert source_pins[district]=='d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c'
native_parent=load(route_evidence)['immutable_parent_manifest']
add_declared(native_parent['path'],native_parent['sha256'],{'approved_by':res(amendment),'pointer':'/immutable_native_parent'})
for row in load(route_evidence)['later_pure_transform_lineage']:
    add_declared(row['source']['path'],row['source']['sha256'],{'declared_by':res(route_evidence),'purpose':'Read-only lineage; not invoked by publisher'})
    if row.get('author'): add_declared(row['author']['path'],row['author']['sha256'],{'declared_by':res(route_evidence),'purpose':'Empty Yamen route_replacements lineage'})

market_report=ROOT/'market_alpha_pin_retry6/publication/17536/result.json'
report=load(market_report)
assert report['passed'] is True and report['geometry']['passed'] is True and report['geometry']['full87517'] is True
wall_parent=load(wall_proposal)['geometry_parent']
assert any(r.get('path')==res(market_report) and r.get('sha256')==sha(market_report) for r in wall_parent.values() if isinstance(r,dict))
add_root(market_report,sha(market_report),'Exact17536 report pinned by approvedB2E3 wall proposal.geometry_parent')
for value,h in report['artifacts'].items(): add_declared(value,h,{'report':res(market_report),'pointer':'/artifacts'})
market_manifest='res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json'
yamen_manifest='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/manifest.json'
add_current(market_manifest,'ch4_s3_luoyang_market');add_current(yamen_manifest,'ch4_s1_luoyang_yamen')
mm=load(path(market_manifest));ym=load(path(yamen_manifest))
assert mm['mask_sha256']==report['walk_candidate']['rgba_sha256']=='d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e'
assert ym['mask_sha256']=='24ed57059813082ced5cd2222f8fbb6c1498dd50961e139fc2949670fdb999a8'
for value,h in ym['artifacts'].items(): add_declared(value,h,{'manifest':yamen_manifest,'pointer':'/artifacts'})
yamen_geometry=ym['geometry_publication_path']
add_declared(yamen_geometry,ym['geometry_publication_sha256'],{'manifest':yamen_manifest,'pointer':'/geometry_publication_sha256'})
gy=load(path(yamen_geometry))
assert gy['passed'] is True and gy['rows']['ch4_s1_luoyang_yamen']['geometry']['passed'] is True and gy['rows']['ch4_s1_luoyang_yamen']['geometry']['full87517'] is True

def domain(scene,identifier,manifest,mask_rgba):
    root=manifest.rsplit('/',1)[0]+'/'
    raw=f'res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/{scene}/raw_walk.png'
    for value in [root+'layout.res',root+'scene.res',root+'packet.bin',root+'walk.png',raw]: add_current(value,scene)
    assert source_pins[raw]=='0dc78a4affde8a13d1d2f58385b4ac5da102b1718f8e5b48d12dd066b0dedcfa'
    return {'scene_id':scene,'domain_id':identifier,'parent_manifest_path':manifest,'parent_manifest_sha256':source_pins[manifest],
        'scene_path':root+'scene.res','layout_path':root+'layout.res','packet_path':root+'packet.bin','packet_sha256':source_pins[root+'packet.bin'],
        'walk_path':root+'walk.png','raw_walk_path':raw,'mask_rgba_sha256':mask_rgba,'raw_geometry':copy.deepcopy(raw_scenes[scene]['geometry']),
        'oracle_basis':{'path':res(fixture),'sha256':sha(fixture),'scene_id':scene,'purpose':'Independent raw native+DG geometry only, not runtime sources/collector output'}}
market=domain('ch4_s3_luoyang_market','market',market_manifest,mm['mask_sha256'])
yamen=domain('ch4_s1_luoyang_yamen','yamen',yamen_manifest,ym['mask_sha256'])
assert market['packet_sha256']=='edcb58007aff16bb5175ce3424b4e4bddfcb619aaab5ff07d0102f50c6962f80'
assert yamen['packet_sha256']=='04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df'
yp=load(yamen_proposal)
for asset in yp['assets']:
    for row in asset['media_three_leaves']: add_declared(row['path'],row['sha256'],{'approved_yamen_proposal':res(yamen_proposal),'asset_id':asset['asset_id'],'closure':'Exact sourcePNG/sidecar/ctex reused unchanged, not a new import'})
    for field in ['existing_interior_author','source_geometry_metadata']:
        row=asset[field]
        if row['path'].startswith('res://'): add_declared(row['path'],row['sha256'],{'approved_proposal':res(yamen_proposal),'field':field})
    assert asset['source_size_px']==[1536,1024]
domains=[]
for placement in yp['placements']:
    asset=next(a for a in yp['assets'] if a['asset_id']==placement['asset_id'])
    for poly in asset['source_ground_solid_polygons_px']:
        points=[godot_point(p,asset['source_ground_anchor_px'],placement['foot_px'],.12) for p in poly]
        domains.append(raster_domain(points))
assert domains==[[1069,1148,143,14],[1069,1278,143,14],[1063,1425,134,27]],domains
assert sum(w*h for x,y,w,h in domains)==7622
yamen['local_mask_domains_px']=domains
yamen['route_whole_parent_expectation']={'path':native_parent['path'],'sha256':native_parent['sha256'],'route_ids':['court_loop','case_board'],'actual_native_decode_compare_required':True}

data={'status':'FROZEN_FINITE_TWO_DOMAIN_ROOT_ONLY_INPUT','output_prefix':OUT,
    'scope':'Only new local geometry/native candidates. No runtime admission/consumer, imports, Field, collector or canonical writes.',
    'preparation_approval':pin(approval),'route_amendment':pin(amendment),'parent_runtime_stage':pin(stage),'parent_runtime_final_guard':pin(guard),
    'declared_stage_maps':map_sources,'bundle_api_path':bundle,'geometry_api_path':geometry,
    'wall_helper_path':res(wall_helper),'clerk_helper_path':res(clerk_helper),'district_author_path':district,
    'yamen_proposal_path':res(yamen_proposal),'route_correction_path':res(route_evidence),
    'source_pins':source_pins,'source_pin_lineage':lineage,'market':market,'yamen':yamen,
    'source_scope_not_complete_runtime':'Fixed actual9AACE maps provide selected code/artifact declarations. No actual collector called or expected source rebuilt. Original17536 and T geometry inherited only outside finite delta.',
    'required_future_admission':['Root actual finite CPU report','Independent QA local mask/body/route/native inverse','Original-alpha outdoor limited picture','Exact source-only B/DT/Fade/native-parent mappings and source-bound pre-spawn clerk row projection separately approved','Minimal metadata closure and formal deployment separately approved']}
input_pin=save('input_READY.json',data)
template=EPOCH/'publisher_template_NOTEXEC.gd'
text=template.read_text(encoding='utf-8')
assert text.count('const READY=false')==1 and text.count('@INPUT_SHA@')==1
text=text.replace('const READY=false','const READY=true').replace('@INPUT_SHA@',input_pin['sha256'])
ready=EPOCH/'publisher_READY.gd'
assert not ready.exists()
ready.write_text(text,encoding='utf-8')
handoff=save('handoff_READY.json',{'status':'ROOT_REVIEW_UNIQUE_EXECUTABLE_FINITE_CPU_PUBLISHER_INPUT_READY_NOT_RUN',
    'publisher':pin(ready),'input':input_pin,'template':pin(template),'preparation_builder':pin(Path(__file__)),
    'mechanical_template_changes':['READY false->true','One INPUT_SHA token to fixed input SHA'],
    'source_pin_count':len(source_pins),'domains':{'Market':{'local_mask':[35,1408,111,13],'visited_pixels':1443,'native_visuals':[24,23],'raw_combined_solids':[44,43],'new_witnesses':2},'Yamen':{'local_mask':domains,'visited_pixels':7622,'native_visuals':[24,27],'native_solids':[29,32],'DG_solids':10,'combined_solids':[39,42],'real_NPC_lanes':6,'changed_route_points':4,'changed_connecting_segments':5,'near_tangent_inherited_segments':[5,6]}},
    'source_first_final_scope':'Only pinned inputs read by this finite publisher; not a new full-city/current collector admission.',
    'root_only_execution':'One headless SceneTree may execute both independent domain functions. No subagent engine. No output exists yet. Do not run twice or reuse output folder.',
    'engine_runs':0,'image_decodes':0,'native_variant_decodes':0,'canonical_writes':0,'new_media_imports':0,
    'runtime_consumer_missing_is_explicit':True,'whole_city_art_pass':False})
print(json.dumps(handoff))
