from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;GAME=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
QA='res://build/luoyang_city_finish_20261025i_system01/qa_role_new/'
def physical(path):
    return GAME/path.removeprefix('res://') if path.startswith('res://') else Path(path)
def sha(b): return hashlib.sha256(b).hexdigest()
def read(path): return json.loads(physical(path).read_text(encoding='utf8'))
def descriptor(path,digest=None):
    b=physical(path).read_bytes();s=sha(b)
    if digest: assert s==digest,(path,s,digest)
    return dict(path=path,sha256=s,bytes=len(b))
def emit(name,value):
    b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
    with (N/name).open('xb') as f:f.write(b)
    return descriptor(NS+name)
stage_path='res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json'
descriptor(stage_path,'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5')
stage=read(stage_path);authority={}
for key,node in stage['nodes'].items():
    if key.startswith('expected_'):
        v=node.get('value',{})
        for p,s in v.get('source_sha256',{}).items():
            assert p not in authority or authority[p]==s
            authority[p]=s
for target in stage['targets']: authority[target['target']]=target['candidate_sha256']
overview=read(NS+'overview_eight_fields12_material04_two_ROOT_READY_input.json')
sources=dict(overview['sources'])
def fixed(path):
    s=authority.get(path,sources.get(path))
    assert s is not None,('NO_INDEPENDENT_FORMAL_AUTHORITY',path)
    descriptor(path,s);sources[path]=s
    return path
def candidate(path,digest=None):
    d=descriptor(path,digest);sources[path]=d['sha256'];return path
json_inputs={k:overview[k] for k in ['axis_author','axis_library','artisan_old_author','artisan_life_author','artisan_author','processed_buildings','temple_old_author','temple_author','adjacent_author','adjacent_library','district_author']}
json_inputs['axis_low_author']=candidate(NS+'author_gate_yamen_axis08_low_courts_NOTREADY.json','5baa93dc833b5f33c2bcdba96fff64365c7aca7454bb90f5f6e790e9603bdbba')
json_inputs['adjacent_old_author']=candidate(NS+'author_adjacent_four_fields05_routes_NOTREADY.json','8b1825f064a2b7287e70329c30000db6daaf2ce5afccb688676b563c84817377')
json_inputs['estate_geometry']=fixed('res://build/luoyang_estate_courtyard_20261021an_system01/revision4_route_domain_retry2/geometry/16580/result.json')
binary_inputs={
 'parent_seed':overview['parent_seed'],
 'market_projection':fixed('res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/projection.bin'),
 'market_geometry':fixed('res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/geometry.bin'),
 'docks_projection':fixed('res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/publication01/output/78128/projection.bin'),
 'docks_geometry':fixed('res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/publication01/output/78128/geometry.bin')}
prior_paths={
 'low':(QA+'four_low_objects03_ROOT_READY/four_low_output_ROOT_READY/118052/prior.json',None),
 'artisan':(QA+'artisan_prior05_ROOT_READY/artisan_output05_ROOT_READY/108000/prior.json','1e8d3272d328d5a2eb30c100f1c1f61a19c9338d5a01c68e7fa21bef332c9f5c'),
 'adjacent':(QA+'adjacent_prior04_ROOT_READY/adjacent_output04_ROOT_READY/111376/prior.json','2a07fb2d82ab3c3c301bbf7b898071dd14cc8970a483ac3f0dda110e5d4bd3ab'),
 'temple':(QA+'temple_prior02_ROOT_READY/output_ROOT_READY/108880/prior.json','97ca9a5e77334432695e9f27795a2d274487ac2055d6ea48597ba9532cbf3770'),
 'residual':(QA+'remaining_six_domains04_ROOT_READY/output_ROOT_READY/61996/prior.json','bac2cb27a49fe18e2dae43cfbb65e429286c61ab84bdbccb1d14e4f4c070528e')}
priors={};raw_priors={}
for key,(path,s) in prior_paths.items():
    candidate(path,s);priors[key]=descriptor(path,s);raw_priors[key]=read(path)
for key,field,dirname in [('low','expected_primitives_binary','four_low_objects03_ROOT_READY'),('artisan','expected_source_geometry_binary','artisan_prior05_ROOT_READY'),('residual','expected_binary','remaining_six_domains04_ROOT_READY')]:
    p=raw_priors[key][field]
    path=('res://'+Path(p['path']).resolve().relative_to(GAME).as_posix()) if Path(p['path']).is_absolute() else QA+dirname+'/'+p['path'].removeprefix('res://')
    candidate(path,p['sha256']);priors[key]['geometry_path']=path
    priors[key]['geometry_sha256']=p['sha256']
# Native resources were already formally admitted. This publisher reads them,
# never re-decodes their large packets, runs compilers or claims a new old proof.
parent_scenes={
 'ch4_s0_luoyang_gate':'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/scene.res',
 'ch4_s1_luoyang_yamen':'res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/yamen/scene.res',
 'ch4_s2_canal_docks':'res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/scene.res',
 'ch4_s3_luoyang_market':'res://build/luoyang_city_revision_20261024b_root01/market_detours06_READY/output/scene.res',
 'luoyang_artisan_residential_20261022ap':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration59/artisan_life_READY/output/native/scene.res',
 'ch4_s4_ancient_temple':'res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres',
 'luoyang_estate_riverside_20261021ai':'res://data/maps/luoyang_estate_courtyard_20261021am/scene.res',
 'luoyang_riverside_garden_20261022ap':'res://build/luoyang_garden_river_20261025h_source01/publication01/output/native/luoyang_riverside_garden_20261022ap/scene.res'}
old_scope=read(NS+'adjacent_old_geometry_and_new_route_scope05_NOTREADY.json')
low=raw_priors['low'];scenes=[]
axis=read(json_inputs['axis_author'])
for id,path in parent_scenes.items():
    spec={'id':id,'parent_scene':fixed(path)}
    if id in low['scenes']:
        transport=low['scenes'][id]['transported_parent_mask']
        path=QA+'four_low_objects03_ROOT_READY/'+transport['path'].removeprefix('res://')
        candidate(path,transport['sha256'])
        spec['mask_parent']={'path':path,'sha256':transport['sha256'],'RGBA_sha256':low['scenes'][id]['parent_RGBA_sha256']}
        source=next(s for s in axis['scenes'] if s['scene_id']==id)['raw_support_source']
        candidate(source['path'],source['sha256']);spec['raw_support']=source
    elif id=='luoyang_artisan_residential_20261022ap':
        p='res://build/luoyang_city_full_rollout_20261022ap_root01/integration59/artisan_life_READY/output/native/walk.png'
        spec['mask_parent']={'path':fixed(p),'sha256':authority[p],'RGBA_sha256':raw_priors['artisan']['prior']['parent_RGBA_sha256']}
    elif id!='ch4_s4_ancient_temple':
        m=old_scope['sources'][id]['mask'];fixed(m['path'])
        spec['mask_parent']={'path':m['path'],'sha256':m['sha256'],'RGBA_sha256':raw_priors['adjacent']['scenes'][id]['parent_RGBA_sha256']}
    scenes.append(spec)
for path in list(json_inputs.values())+list(binary_inputs.values()):
    if path not in sources: fixed(path)
code={
 'source_views':candidate(NS+'finish8_source_views01_NOTREADY.gd'),
 'payload_builder':candidate(NS+'finish8_payload_builder01_NOTREADY.gd','a88b447d975779a2ad0fd4a2a21085d59e6e4abd1b8699a61d2e4636a0d1bc70'),
 'axis_helper':overview['axis_helper'],'artisan_helper':overview['artisan_helper'],'temple_builder':overview['temple_builder'],'adjacent_helper':overview['adjacent_helper']}
for path in code.values(): descriptor(path,sources[path])
value=dict(status='ROOT_ONLY_FINISH8_SOURCE_COMPONENT_PUBLICATION_NOT_RUNTIME',ready=False,root_run_authorized=False,whole_budget_ms=45000,
 output_root=NS+'publication01/output_NOTREADY',sources=sources,json_inputs=json_inputs,binary_inputs=binary_inputs,priors=priors,scenes=scenes,save_absolute_paths=overview['save_absolute_paths'],**code,
 inherited_original_components='No native4 recompilation, old route or pixel acceptance replay. Source creates own7 masks from approved parent PNGs and exact declared changed domains; Temple SOURCE_POLYGON_ONLY.',
 original_FAILs_preserved=True,formal_parent_stage={'path':stage_path,'sha256':'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'})
pin=emit('finish8_publication_input01_NOTREADY.json',value)
entry=descriptor(NS+'publish_finish8_components01_NOTREADY.gd')
handoff=emit('finish8_publication01_handoff_NOTREADY.json',dict(status='SOURCE_UNIFIED_EIGHT_PUBLICATION_ROOT_REVIEW_REQUIRED',entry=entry,input=pin,helpers={k:descriptor(v) for k,v in code.items()},source_count=len(sources),expected_scene_count=8,new_mask_count=7,Temple_no_PNG=True,engine_calls=0,canonical_writes=0,remaining_authority='All geometry/prior component pins fixed; exact published output values may be admitted only after Root actual execution. Not an actual execution or deployment.'))
print(json.dumps(dict(entry=entry,input=pin,handoff=handoff,source_count=len(sources))))
