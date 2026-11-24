"""Source-only immutable fixture; no Godot/Stage/import/canonical write."""
from pathlib import Path
import hashlib,json,re,struct,math
import numpy as np

N=Path(__file__).resolve().parent
G=N.parents[1]
OUT=N/'street_edges04_local01_NOTREADY'
P='res://build/luoyang_city_finish_20261025i_source01/'
GATE='ch4_s0_luoyang_gate';YAMEN='ch4_s1_luoyang_yamen'
SIDS=[GATE,YAMEN]
pins={}
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+str(p.relative_to(G)).replace('\\','/')
def read(path,wanted):
    path=G/path[6:] if isinstance(path,str) and path.startswith('res://') else Path(path)
    b=path.read_bytes();assert sha(b)==wanted.lower(),(str(path),sha(b),wanted)
    pins[res(path)]=wanted.lower();return b
def j(path,wanted):return json.loads(read(path,wanted))
def put(name,value):
    b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode('utf8')
    with (OUT/name).open('xb') as f:f.write(b)
    return {'path':res(OUT/name),'sha256':sha(b),'bytes':len(b)}

descriptor_path=P+'temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json'
descriptor=j(descriptor_path,'c7896af45a53d8eb45f6bc0f5f6fd794fa40c8999af1757906fa8ec7812a8aa7')
authority={}
for scene_id in SIDS:
    pin=descriptor['maps']['expected_'+scene_id+'_true']['candidate']
    value=j(pin['path'],pin['sha256'])['source_sha256']
    for key,wanted in value.items():
        assert key not in authority or authority[key]==wanted
        authority[key]=wanted
binding_path=P+'family_visual_material_loading_repair01/closure_READY01/finish8_binding_READY.json'
binding=j(binding_path,'26b8b652aaa73a93c3123ff4287be63d6952124a6ce9b424c27aa2a30d316ff5')
author_pin={'path':P+'street_edges04_BUILD01/author_five_street_edges01_NOTREADY.json','sha256':'e44e15872d1f5a4305cd5d21086e6ed54a6e1bca7e2f961806d7ec99570d54e5'}
author=j(**{'path':author_pin['path'],'wanted':author_pin['sha256']})
axis=j(P+'author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json','2b17aa92d9b034fc914fa2c643a41b6301da7218c1422492e5f1128b80083731')

# Execute definitions only, never the earlier five-lot generator's emission path.
prefix=(N/'prepare_street_edges05_BUILD_ONLY.py').read_text(encoding='utf8').split('lots=[];audit=[]')[0]
prefix=prefix.replace("OUT=N/'street_edges05_BUILD02'","OUT=N/'_READONLY_PREFIX_NO_DIRECTORY_CREATED'")
prefix=prefix.replace("for sid in {lot['scene_id'] for lot in design['lots']}|{'luoyang_artisan_residential_20261022ap','luoyang_estate_riverside_20261021ai'}:","for sid in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen']:")
scope={'__file__':str(N/'prepare_street_edges05_BUILD_ONLY.py')}
exec(compile(prefix,'IMMUTABLE_DEFINITIONS_ONLY','exec'),scope)
payloads=scope['payloads'];parent_A1={};excluded={}
for sid in SIDS:
    parent_A1[sid]=[];excluded[sid]=[]
    for row in payloads[sid]['effective_navigation']:
        if not row.get('texture'):continue
        if not any(row.get(k) for k in ['sort_by_feet','blocking','gate_module_object']):
            excluded[sid].append({'id':row['id'],'reason':'original nonblocking ground row, not building A1'});continue
        bounds=scope['row_a1'](row)
        if bounds is None:excluded[sid].append({'id':row['id'],'reason':'exact original Atlas region fully transparent; original solid retained'});continue
        parent_A1[sid].append({'id':row['id'],'xyxy':bounds,'source_texture':row['texture']})
    for name in ['payload','mask']:
        pin=binding['scenes'][sid][name];read(pin['path'],pin['sha256'])
for path,actual in scope['texture_sources'].items():
    assert path in authority,('TEXTURE_NOT_DECLARED_BY_FROZEN_SIGNED_SOURCE_MAP',path)
    assert authority[path]==actual['sha256'],('TEXTURE_PHYSICAL_DIFFERS_FROM_INDEPENDENT_SOURCE_VALUE',path)
    read(path,authority[path])
for lot in author['lots']:
    asset=lot['source_asset'];read(asset['texture'],asset['source_sha256'])
    assert asset['source_sha256'].lower()==authority[asset['texture']]

routes={};npcs={};portals={};provenance={}
def npc(row,where,foot_key='point_px',distance_key=None,prefix=''):
    point=row[foot_key];distance=float(row.get(distance_key,0)) if distance_key else 0
    return {'id':prefix+row['id'],'from_px':[point[0]-distance,point[1]],'to_px':[point[0]+distance,point[1]],'full_body_px':[34,30],'source_selector':where}
def portal_guard(row,where):
    foot=row.get('foot_px',row.get('arrival_foot_px'))
    if foot is None and 'pos' in row:foot=[float(row['pos'][0])*3072,float(row['pos'][1])*2048]
    poly=row.get('polygon_px',row.get('city_v3_interaction_polygon_px',row.get('interaction_polygon_px')))
    assert foot is not None,(row,where)
    pts=[foot]+(poly or [])
    box=[min(v[0] for v in pts)-17,min(v[1] for v in pts)-12,max(v[0] for v in pts)+17,max(v[1] for v in pts)+12]
    return {'id':str(row.get('id',row.get('source_id'))),'player_body_and_portal_foot_guard_xyxy':box,'source_selector':where}

for scene in axis['scenes']:
    sid=scene['scene_id'];source=scene['original_routes_source'];manifest=source['manifest']
    original=j(manifest['path'],manifest['sha256'])['record']
    routes[sid]=[dict(v,source_selector=manifest['path']+'#/record/routes/'+str(i)) for i,v in enumerate(original['routes'])]
    replacements={v['id']:v for v in scene['affected_old_route_replacements']}
    for row in routes[sid]:
        if row['id'] in replacements:row['points_px']=replacements[row['id']]['new_points_px'];row['source_selector']=res(N/'author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json')+'#/affected_old_route_replacements/'+row['id']
    routes[sid]+=[dict(v,source_selector=res(N/'author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json')+'#/new_source_routes/'+v['id']) for v in scene['new_source_routes']]
    npcs[sid]=[npc(v,manifest['path']+'#/record/npc_stations/'+str(i)) for i,v in enumerate(original['npc_stations'])]
    portals[sid]=[portal_guard(v,manifest['path']+'#/record/gameplay_slots/portals/'+str(i)) for i,v in enumerate(original['gameplay_slots']['portals'])]
    for i,row in enumerate(payloads[sid]['portal_after']):portals[sid].append(portal_guard(row,binding['scenes'][sid]['payload']['path']+'#/portal_after/'+str(i)))
    provenance[sid]={'original_manifest':manifest,'original_rows_retained':True,'only_current_axis_replacements_applied':True}
    if sid==YAMEN:
        for key in ['current24c_short_routes','T_additional_source']:
            source_pin=source[key];value=j(source_pin['path'],source_pin['sha256'])
            for part in source_pin['pointer']:value=value[part]
            routes[sid]+=[dict(v,source_selector=source_pin['path']+'#/'+('/'.join(source_pin['pointer']))+'/'+str(i)) for i,v in enumerate(value)]
        for which,foot in [('west_annex_threshold',[590,1000]),('west_annex_return',[590,1048]),('east_annex_threshold',[2664,1050]),('east_annex_return',[2664,1098])]:
            portals[sid].append({'id':which,'player_body_and_portal_foot_guard_xyxy':[foot[0]-17,foot[1]-12,foot[0]+17,foot[1]+12],'source_selector':source['current24c_short_routes']['path']+'# adopted annex threshold/return contract'})

crowd_script='res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd'
text=read(crowd_script,'1aaea6ca19ab8abb1f164b155f24ac8a11ca43e7e4d73b1fa4fd899937b5e83b').decode('utf8')
section=text.split('if id==A.IDS[0]:',1)[1].split('if id==A.IDS[1]:',1)[0]
literal=section[section.index('return ')+7:].strip()
crowd=json.loads(literal);assert len(crowd)==10
for row in crowd:
    # Original authored literal [id,name,[x,y],distance,walk,invert].
    assert isinstance(row,list) and len(row)==6,row
    distance=float(row[3]);npcs[GATE].append({'id':'harbour_life_'+str(row[0]),'from_px':[row[2][0]-distance,row[2][1]],'to_px':[row[2][0]+distance,row[2][1]],'full_body_px':[34,30],'source_selector':crowd_script+'#spec(A.IDS[0]):'+str(row[0])})
override='res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/yamen_clerk_overlay_PENDING.json'
current_crowd=j(override,'6d820cd5df670e3c5dd67976b9030d638554d6f9aefc50ecec9c8f4bc8aacaf3')['new_spec']['crowd']
assert len(current_crowd)==6
npcs[YAMEN]+=[npc(v,override+'#/new_spec/crowd/'+str(i),'foot_px','distance_px') for i,v in enumerate(current_crowd)]
assert len(npcs[GATE])==11 and len(npcs[YAMEN])==9

strips={GATE:[{'id':'original_x300_public_lane144','xyxy':[228,0,372,2048]},{'id':'main_axis312','xyxy':[1380,0,1692,2048]}],YAMEN:[{'id':'existing_east_service_x2790_width144','xyxy':[2718,1080,2862,1350]},{'id':'main_court_axis312','xyxy':[1380,0,1692,2048]}]}
backup_path=P+'temple_signed_iid_repair01/current_377B_backup31_ROOT_ACTUAL.json'
backup=j(backup_path,'8e8f484f0f9b0531969b4e227b5f71abd818dc4935fd568890ad79501bb76026')
save_paths=list(backup['save15']);assert len(save_paths)==15
fixture={'schema':1,'ready':False,'root_run_authorized':False,'status':'SOURCE_FIXED_FOUR_WALLS_ONLY_ROOT_CPU_REVIEW_NOT_INDEPENDENT_QA','author':author_pin,'sources':pins,'save_absolute_paths':save_paths,'parent_complete_A1':parent_A1,'protected_strips':strips,'NPC_guards':npcs,'portal_guards':portals,'route_guards':routes,'scenes':{sid:{key:binding['scenes'][sid][key] for key in ['payload','mask']} for sid in SIDS},'output_root':P+'street_edges04_local01_NOTREADY/output_NOTREADY/','source_provenance':provenance,'excluded_original_ground_A1_rows':excluded,'parent_A1_derivation':'Frozen original effective_navigation, full alpha>0 texture bounds, exact Field position and Sprite scale expressions; no observed Field sampling. Atlas regions preserve original regions.','author_new_domain_pixels':sum(lot['domain_pixels'] for lot in author['lots']),'Inn_abandoned':True,'no_engine_Stage_import_collector_canonical':True}

# Independent execution is NOT claimed: this is the implementation's read-only preflight.
def intersect(a,b,closed=False):
    return max(a[0],b[0])<=min(a[2],b[2]) and max(a[1],b[1])<=min(a[3],b[3]) if closed else max(a[0],b[0])<min(a[2],b[2]) and max(a[1],b[1])<min(a[3],b[3])
def segment_hits(a,b,bounds,half):
    low=np.asarray(bounds[:2],dtype=np.float32)-np.asarray(half,dtype=np.float32);high=np.asarray(bounds[2:],dtype=np.float32)+np.asarray(half,dtype=np.float32)
    a=np.asarray(a,dtype=np.float32);delta=np.asarray(b,dtype=np.float32)-a;t0=0.;t1=1.
    for axis in range(2):
        if delta[axis]==0:
            if a[axis]<low[axis] or a[axis]>high[axis]:return False
        else:
            enter=float(np.float32(low[axis]-a[axis]))/float(delta[axis]);leave=float(np.float32(high[axis]-a[axis]))/float(delta[axis])
            if enter>leave:enter,leave=leave,enter
            t0=max(t0,enter);t1=min(t1,leave)
            if t0>t1:return False
    return True
checks=[];failures=[]
for lot in author['lots']:
    sid=lot['scene_id'];lid=lot['lot_id'];ground=lot['new_ground_polygon_world_f32'];bounds=scope['box'](ground);a1=scope['row_a1'](lot['candidate_render_row']);local=[]
    for old in parent_A1[sid]:
        if intersect(a1,old['xyxy']):local.append({'kind':'full_A1','id':old['id']})
    for strip in strips[sid]:
        if intersect(a1,strip['xyxy']):local.append({'kind':'full144design_strip','id':strip['id']})
    for actor in npcs[sid]:
        if segment_hits(actor['from_px'],actor['to_px'],bounds,[17,15]):local.append({'kind':'NPC34x30','id':actor['id']})
    for portal in portals[sid]:
        if intersect(bounds,portal['player_body_and_portal_foot_guard_xyxy'],True):local.append({'kind':'portal_or_return','id':portal['id']})
    for route in routes[sid]:
        for i,(a,b) in enumerate(zip(route['points_px'],route['points_px'][1:])):
            if segment_hits(a,b,bounds,[17,12]):local.append({'kind':'continuousPlayer34x24','id':route['id'],'leg':i})
    checks.append({'id':lid,'actual_render_A1_f32':a1,'closed_domain':lot['closed_domain_xyxy'],'domain_pixels':lot['domain_pixels'],'failures':local});failures+=local
assert not failures,failures
assert len(author['lots'])==4 and fixture['author_new_domain_pixels']==22012
fixture_pin=put('input_NOTREADY.json',fixture)
audit_pin=put('static_preflight_READONLY.json',{'status':'SOURCE_SELF_PREFLIGHT_NOT_INDEPENDENT_QA_OR_GODOT_PASS','passed':not failures,'per_lot':checks,'route_row_counts':{sid:len(routes[sid]) for sid in SIDS},'NPC_counts':{sid:len(npcs[sid]) for sid in SIDS},'parent_A1_counts':{sid:len(parent_A1[sid]) for sid in SIDS},'sources_count':len(pins),'new_domains_pixels':22012,'all_original_portals_and_NPCs_and_route_values_unchanged':True,'only_current_axis_route_replacements_inherited':True,'Inn_known_conflict_retained_not_retried':True,'fixed_input':fixture_pin,'no_engine_Stage_collector_or_canonical_writes':True})
print(json.dumps({'input':fixture_pin,'source_self_preflight':audit_pin},ensure_ascii=False))
