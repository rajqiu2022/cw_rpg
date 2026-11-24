"""Freeze sole finite Yamen key from fixed independent sources; zero engine."""
import copy,hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
S=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):
    assert p.startswith('res://');return ROOT/p[6:]
def key(p):return 'res://'+p.relative_to(ROOT).as_posix()
def load(p):return json.loads(p.read_bytes())
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def norm_roundtrip(p):return [f(f(x/d)*d) for x,d in zip(p,[3072,2048])]
ownerp=S/'finite09_stage02_independent_review/owner_source_maps_READY.json'
assert sha(ownerp)=='1002af3bf3cd46ef0e1f4864d8313bfca0d82eea04349437b916e5df6f932188'
owner=next(x for x in load(ownerp)['scenes'] if x['id']=='ch4_s1_luoyang_yamen')
assert len(owner['source_sha256'])==1211 and owner['owner']=='C'
rp=S/'outputs/root_finite09_two_domain_stage02/receipt.json'
assert sha(rp)=='885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'
binding=S/'finite_adapter_production08/adapter_binding_READY.json'
assert sha(binding)=='dc21bb2a5e8d4e1af6944d6a6fe6c864caf29702e4b17b44063ed2369f53ecff'
bd=load(binding)['domains']['yamen']['manifest_immutable']
prior=QA/'wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json'
assert sha(prior)=='448c148ed5a15aaf4b1acbf6472afd6f94fe1ea2bdb654717dd59a5a56b4f947'
y=load(prior)['Yamen']
pending=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_SOURCE_SCALE_PENDING_20261023.gd'
assert sha(pending)=='ca222df6bccfacd5924c1177fd5a4fa745b9d84d7729f131e34f7c3794afa04e'
planp=QA/'yamen_three_low_props_final_fixture_READY.json'
scriptp=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_READY_20261023.gd'
handoff=QA/'yamen_three_low_props_final_handoff_READY.json'
assert not any(p.exists() for p in [planp,scriptp,handoff])
props=[]
for row in y['independent_new_visuals']:
    size=row['full_source_size_px'];anchor=row['source_ground_anchor_px'];foot=row['foot_px']
    assert size==[1536,1024] and row['uniform_scale']==.12
    render=[f(x*.12) for x in size]
    center=[f(foot[i]+f(f(.5-f(anchor[i]/size[i]))*render[i])) for i in range(2)]
    origin=norm_roundtrip(center)
    props.append({'id':row['id'],'texture_path':row['texture'],'native_scale':[f(render[i]/size[i]) for i in range(2)],'sprite_origin_px':origin,'source_polygon_px':copy.deepcopy(row['native_f32_polygons_px'][0]),'source_uniform_author_scale':.12,'independent_expression':'full source Vector2 sizes and UV, each native Vector2 operation f32; normalized pos roundtrip then Field source-size multiplication'})
npcs=[]
for row in y['expected_district']['crowd']:
    npcs.append({'id':'district_life_'+row['id'],'movement_mode':'patrol' if row['distance_px'] else 'idle','axis':[1,0],'distance':row['distance_px'],'speed':24 if row['family']=='guard' else 22,'origin_px':norm_roundtrip(row['foot_px'])})
assert len(npcs)==6
source=copy.deepcopy(owner['source_sha256'])
extras=[ownerp,rp,binding,prior,
 QA/'yamen_local_connectors_source_only_EXPECTATIONS_NOT_RUNTIME_READY.json',
 QA/'yamen_source_native_scale_successor_NOTREADY.json',
 QA/'finite09_stage02_actual_independent_review_READY.json',
 ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/yamen_finite_input_attempt_scope_READY.json',
 ROOT/'tests/test_luoyang_ap_yamen_three_low_props_DRAFT_NOTREADY_20261023.gd',
 ROOT/'tests/test_luoyang_city_life_cpu_draft_20261016f.gd',ROOT/'tests/helpers/v15_input_driver.gd']
for p in extras:
    k=key(p);h=sha(p)
    assert k not in source or source[k]==h;source[k]=h
fixture={'status':'FROZEN_SOURCE_EXPECTATIONS_ROOT_ONLY_FINITE_YAMEN_ATTEMPT','ready':True,'whole_ms':60000,'arrival_ms':60000,'max_pictures':2,'input_endpoint_tolerance_px':.3,'source_connectors_sha256':'6f5cf1fa7ef0cf3f2efa509a46fa6bc50f4d429d49e3f3c131609580c8f682d8','mask_whiteness_preclaimed':False,'expected_city_source_sha256':copy.deepcopy(owner['source_sha256']),'source_sha256':source,'scene_path':bd['artifacts'] and next(p for p in bd['artifacts'] if p.endswith('/scene.res')),'layout_path':next(p for p in bd['artifacts'] if p.endswith('/layout.res')),'mask_RGBA_sha256':'3b9cf5b43231a2ac4f8c3f6f53e4307a2c2adf7aeca77f3d9d17d4f12dcc7874','default_spawn_px':[f(f(.5)*3072),f(f(.9082031)*2048)],'props':props,'npc_rows':npcs,'raw_default_spawn_source':'res://data/scenes/ch4_s1_luoyang_yamen.tres','independent_owner_sha256':sha(ownerp),'native_prop_source_expectation_sha256':sha(prior),'first_actual_input_fact_meaning':'Completion clock of first verified normal INPUT drive, not first movement tick','key_source_integrity':'Root externally pins complete final key SHA before launch; no circular key hash in this fixture. Source fact observation may record key first/final only, never fill production expectations.'}
planp.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
raw=pending.read_text(encoding='utf-8')
changes=[('const FINAL_OWNER_READY: bool = false','const FINAL_OWNER_READY: bool = true'),('PENDING_INDEPENDENT_YAMEN_OWNER_AND_ROOT_DEPLOYMENT_CONTRACT',key(planp)),('PENDING_NOT_CURRENT_DISK_SHA',sha(planp)),('yamen_three_low_props_source_pending/%d_%d','yamen_three_low_props_final/%d_%d')]
for old,new in changes:assert raw.count(old)==1;raw=raw.replace(old,new)
scriptp.write_text(raw,encoding='utf-8',newline='\n')
back=raw
for old,new in reversed(changes):assert back.count(new)==1;back=back.replace(new,old)
assert back.encode()==pending.read_bytes()
result={'status':'ROOT_ONLY_FINITE_YAMEN_KEY_SOURCE_FROZEN_NOT_EXECUTED','script':{'path':key(scriptp),'sha256':sha(scriptp),'lines':len(raw.splitlines())},'fixture':{'path':key(planp),'sha256':sha(planp)},'actual_stage_receipt':{'path':key(rp),'sha256':sha(rp)},'independent_owner':{'path':key(ownerp),'sha256':sha(ownerp)},'production_sources':1211,'fixture_protected_sources':len(source),'native_expected_source':{'path':key(prior),'sha256':sha(prior)},'only_pending_to_final_four_literal_changes_whole_byte_inverse':True,'root_only_launch_after_exact29_deployment_guard':True,'budget':{'whole_ms':60000,'arrival_cap_in_whole_ms':60000,'max_pictures':2},'no_teleport_nearsetup_or_fallback_stations':True,'source_connector_mask_white_not_preclaimed':True,'source_parent_CA22_numeric_scale_fix_no_epsilon':True,'no_engine_parse_field_or_actual_credit':True,'engine_runs':0,'canonical_writes':0}
handoff.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script':result['script'],'fixture':result['fixture'],'handoff_sha256':sha(handoff)}))
