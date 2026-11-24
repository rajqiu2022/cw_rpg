"""Prepare only NEW false QA artifacts from fixed owner72 + actual Stage94/owner95.
No engine, source Stage, collector, packet/image read or canonical mutation.
"""
import copy
import difflib
import hashlib
import json
from pathlib import Path

Q=Path(__file__).resolve().parent;G=Q.parents[1]
R=G/'build/luoyang_city_full_rollout_20261022ap_root01'
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT=Q/'docks_ordinary21_default_entry_NOTREADY'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=p.read_bytes();assert sha(b)==h.lower(),str(p);return b
def load(p,h): return json.loads(read(p,h))
def res(p): return 'res://'+p.relative_to(G).as_posix()
def write_json(p,d):
    assert not p.exists()
    with p.open('x',encoding='utf-8',newline='\n') as f: f.write(json.dumps(d,ensure_ascii=False,indent=2)+'\n')

oldkey_path=R/'integration53/docks_diagnostic_READY/test_docks_diagnostic_READY.gd'
oldkey=read(oldkey_path,'d81dcf30c62bfb69809206757065e44890613b6359c5d8b9c9a78b430a6b3636')
oldfix=load(oldkey_path.parent/'fixture_READY.json','6b4bfac3f245c6436c1ad3512c5b81bb6cba08ff960b9c386f0ab70e29de3e58')
ownerpath=S/'performance95_Docks_ordinary21_actual_independent_review/owner_source_maps_READY.json'
owner=load(ownerpath,'c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb')
parent=load(S/'performance72_A1_ENV18_actual_independent_review/owner_source_maps_READY.json','3715a958d0f9ee71d1ffdbe823ddcbd066d7613e2f5748d0e96e4bd25ed7e666')
stagepath=S/'outputs/root_Docks_ordinary21_stage02/receipt.json'
stage=load(stagepath,'a75b11116797d5e4488e519aa2b1c3d1342fa6b71abec157b8cdb6d310745a85')
ID='ch4_s2_canal_docks'
def docks(o): return next(x for x in o['scenes'] if x['id']==ID)['source_sha256']
before=docks(parent);after=docks(owner)
assert before==oldfix['source_sha256']==oldfix['legs'][0]['expected_sources'] and len(before)==1726
assert stage['source_first']==stage['source_final'] and len(stage['targets'])==21
derived=copy.deepcopy(before);changes={}
for t in stage['targets']:
    if t['target'] in derived:
        assert derived[t['target']]==t['old_sha256']
        derived[t['target']]=t['candidate_sha256']
        if t['old_sha256']!=t['candidate_sha256']: changes[t['target']]={'old':t['old_sha256'],'new':t['candidate_sha256']}
prefix='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance89_Docks_ordinary_C_successor_BUILD/'
newkeys={prefix+'AC_ordinary_C_AA_sources_CANDIDATE.gd':'71353ab8379cc86e1af4de3343969a5b33e88e4d4640f2bbbe74b9cf8ce846b8',
         prefix+'AA_ordinary_source_wholebyte_proof_READY.json':'04ed80f86ca854e010ca9809c78374261436fd8d2c93840442c9a62fb1476145',
         prefix+'C_ordinary_source_wholebyte_proof_READY.json':'ffc135f4161d532496b0247a71b841b8ba4e2fe84fea3a1a81bb0969e9f128f2'}
assert not set(newkeys)&set(derived)
derived.update(newkeys)
assert derived==after and len(after)==1729 and len(changes)==11 and not set(before)-set(after)

qa_pins={
 'res://tests/helpers/v15_input_driver.gd':'a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7',
 'res://tests/fixtures/luoyang_shore_visual_field_ready_20261020ae.json':'3d9f0554a4f409857111ef4ba10a14951df73b3ca96a9e71c20c880bad684e98',
 'res://tests/fixtures/luoyang_docks08_formal_field_retry1_20261019ab.json':'62b4015f9c147275e35089c72b01fb527a094c4cb5aac764c60aae6454e6e5c7',
 'res://build/luoyang_spacing_publication_20261017p/67340_1837/manifest.json':'f3ff3ff892d72ac0350c50f7e2f00cfcd7038c3d9dae608768beca4da34a1e41',
 'res://art/maps/luoyang_city_revision_retry2_20261015/author.json':'cf904eae70c2f789e123c9249b4b47aea6fdb0c63cec7d99a61a4cffe66d935d'}
for p,h in qa_pins.items(): read(G/p[6:],h)
ae=json.loads((G/'tests/fixtures/luoyang_shore_visual_field_ready_20261020ae.json').read_bytes())
ab=json.loads((G/'tests/fixtures/luoyang_docks08_formal_field_retry1_20261019ab.json').read_bytes())
pub=json.loads((G/'build/luoyang_spacing_publication_20261017p/67340_1837/manifest.json').read_bytes())
assert ae['short_route_px']==ab['default_spawn_authority']['normal32px_segment']==[[2140,1840],[2172,1840]]
assert pub['record']['entry_foot_px']==ab['default_spawn_authority']['published_foot_px']==[2140,1840]

assert not OUT.exists();OUT.mkdir()
fix=copy.deepcopy(oldfix)
fix.update({'status':'DOCKS_ONLY_DEFAULT_ORDINARY21_REPAIR_PENDING_ROOT_FORMAL_GUARDS_NOTREADY','ready':False,
            'owner':{'path':res(ownerpath),'sha256':sha(ownerpath.read_bytes())},
            'actual_stage_receipt':{'path':res(stagepath),'sha256':sha(stagepath.read_bytes())},
            'expected_guard_count':1729,'source_sha256':after,'qa_source_sha256':qa_pins,
            'Root_fresh_before':{'path':None,'sha256':None,'external_only':True},
            'Root_deployment_final':{'path':None,'sha256':None,'external_only':True},
            'short_route_px':ae['short_route_px'],'default_foot_px':[2140,1840],
            'actual_mask_sample_contract':'17 points of existing Field-loaded mask plus actual enabled34x24 Physics at start/each recorded INPUT foot; no PNG decode or source875/geometry replay.',
            'blockers':['Root exact21 formal final deployment guard unknown','Root fresh post-deployment pre-actual guard unknown','Root final key/fixture complete read and authorization required'],
            'source_derivation':'Fixed owner72 Docks1726 + exact21 target values present in Docks(11 changes) + independently declared ACsnapshot1/ordinaryproof2 =1729. Fullmap matches independent actual owner95; no current collector/table/hash crawl supplied expectations.',
            'scope':'One ordinary public Docks default21401840, one original-source32px INPUT to21721840, live34x24 Physics and17 loaded-mask observations, original1.05 camera/1920x1080/onePNG;20s entry/60s whole. No Gate/near/Space/rooms/teleport/collector/native decode/geometry replay.'})
del fix['Root53_before']
leg=fix['legs'][0];leg['expected_count']=1729;leg['expected_sources']=after
mp=leg['manifest_provenance']['path'];mt=next(t for t in stage['targets'] if t['target']==mp)
leg['manifest_provenance']={'path':mp,'sha256':after[mp],'immutable_snapshot':mt['candidate_path']}
leg['default_spawn_policy']='Only one-argument public default/null. Fixed published formal record.entry_foot_px21401840, not raw input3401840. Actual default must be within original .03px; no setup/teleport or observed target construction.'
leg['default_spawn_authority']=ab['default_spawn_authority']
fixpath=OUT/'fixture_NOTREADY.json';write_json(fixpath,fix)
fixhash=sha(fixpath.read_bytes())

hunks=[]
def replace(a,b):
    global candidate
    assert candidate.count(a.encode())==1,a[:80]
    candidate=candidate.replace(a.encode(),b.encode(),1);hunks.append({'before':a,'after':b})
candidate=oldkey
replace('const FIXTURE_READY=true','const FIXTURE_READY=false')
replace(oldfix_path:= 'res://build/luoyang_city_full_rollout_20261022ap_root01/integration53/docks_diagnostic_READY/fixture_READY.json',res(fixpath))
replace('6b4bfac3f245c6436c1ad3512c5b81bb6cba08ff960b9c386f0ab70e29de3e58',fixhash)
replace('const IDS=[&"ch4_s2_canal_docks"]\n','const IDS=[&"ch4_s2_canal_docks"]\nconst INPUT_DRIVER=preload("res://tests/helpers/v15_input_driver.gd")\n')
replace('var terminal_snapshot_taken: bool=false\n','var terminal_snapshot_taken: bool=false\nvar movement_driver: RefCounted\nvar actual_mask: Image\nvar actual_queries: int=0\nvar mask_observations: int=0\nvar input_physics_samples: int=0\nvar first_bad_foot: Dictionary={}\n')
replace('fixture.Root53_before.sha256.length()==64 and fixture.Root53_before.path.begins_with("res://"),"Root53 fresh external guard must be frozen, not PENDING"',
        'fixture.Root_fresh_before.sha256 is String and fixture.Root_fresh_before.sha256.length()==64 and fixture.Root_fresh_before.path is String and fixture.Root_fresh_before.path.begins_with("res://") and fixture.Root_deployment_final.sha256 is String and fixture.Root_deployment_final.sha256.length()==64,"Actual formal deployment and fresh external guards must be frozen, not PENDING"')
for a,b in [('fixture.source_sha256.size()==1726 and fixture.expected_guard_count==1726','fixture.source_sha256.size()==1729 and fixture.expected_guard_count==1729'),
            ('"Fixed independent Docks1726 complete table"','"Fixed independent Docks1729 complete table"'),
            ('row.expected_count==[1726][i]','row.expected_count==[1729][i]'),
            ('"Docks1726 only; no Gate replay"','"Docks1729 only; no Gate replay"'),
            ('"Full independent Docks1726 complete source identity, no collector fill"','"Full independent Docks1729 complete source identity, no collector fill"')]: replace(a,b)
replace('\tif not track(fixture.owner.path,fixture.owner.sha256): return false\n',
'''\tif not track(fixture.owner.path,fixture.owner.sha256): return false
\tfor path: String in fixture.qa_source_sha256:
\t\tif not track(path,fixture.qa_source_sha256[path]): return false
\tif not check(fixture.short_route_px.size()==2 and Vector2(fixture.short_route_px[0][0],fixture.short_route_px[0][1])==Vector2(2140,1840) and Vector2(fixture.short_route_px[1][0],fixture.short_route_px[1][1])==Vector2(2172,1840) and Vector2(fixture.default_foot_px[0],fixture.default_foot_px[1])==Vector2(2140,1840),"Fixed publication default and original admitted32px+x route, no raw340 or observed target"): return false
''')
movement='''func _body_query(at: Vector2) -> Array[Dictionary]:
\tvar player: CharacterBody2D=field.get("_player") as CharacterBody2D
\tvar shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D if player!=null else null
\tvar world: Node2D=field.get("world_container") as Node2D
\tif shape==null or world==null or not shape.shape is RectangleShape2D or shape.disabled or shape.position!=Vector2.ZERO or shape.shape.size!=Vector2(34,24): return [{"invalid_original34x24":true}]
\tvar query:=PhysicsShapeQueryParameters2D.new()
\tquery.shape=shape.shape;query.transform=shape.global_transform
\tquery.transform.origin+=world.to_global(at)-player.global_position
\tquery.collision_mask=player.collision_mask;query.exclude=[player.get_rid()];query.collide_with_areas=false
\tactual_queries+=1
\treturn player.get_world_2d().direct_space_state.intersect_shape(query,16)

func _live_clear(foot: Vector2) -> bool:
\tif Time.get_ticks_msec()>=deadline or not foot.is_finite() or current_scene!=field or actual_mask==null: return false
\t# Both live observations are recorded independently; mask failure never hides Physics.
\tvar hits: Array[Dictionary]=_body_query(foot);var bad_mask: Array=[]
\tfor offset: Vector2 in [Vector2.ZERO,Vector2(-17,-12),Vector2(17,-12),Vector2(17,12),Vector2(-17,12),Vector2(-17,0),Vector2(17,0),Vector2(0,-12),Vector2(0,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6),Vector2(-8,-12),Vector2(8,-12),Vector2(-8,12),Vector2(8,12)]:
\t\tvar pixel:=Vector2i(foot.round()+offset);mask_observations+=1
\t\tif pixel.x<0 or pixel.y<0 or pixel.x>=actual_mask.get_width() or pixel.y>=actual_mask.get_height(): bad_mask.append({"point":pixel,"out_of_bounds":true})
\t\telif actual_mask.get_pixelv(pixel)!=Color.WHITE: bad_mask.append({"point":pixel,"color":actual_mask.get_pixelv(pixel)})
\tif (not hits.is_empty() or not bad_mask.is_empty()) and first_bad_foot.is_empty(): first_bad_foot={"foot":foot,"Physics_hit_count":hits.size(),"mask_bad_points":bad_mask,"clock":_clock()}
\treturn hits.is_empty() and bad_mask.is_empty()

func _short_true_input() -> bool:
\tvar player: CharacterBody2D=field.get("_player") as CharacterBody2D
\tvar start:=Vector2(2140,1840);var target:=Vector2(2172,1840)
\tactual_mask=field.get("_walkable_mask_image") as Image
\trecords.append({"kind":"SOURCE_FIXED_DEFAULT32PX_INPUT_PRECONDITION","actual_foot":player.position if player!=null else null,"source_start":start,"source_target":target,"original_body_size":Vector2(34,24),"no_position_write":true,"loaded_mask_exists":actual_mask!=null,"clock":_clock()})
\tif not check(player!=null and player.position.distance_to(start)<=.03 and field.get("_world_size")==Vector2(3072,2048) and actual_mask!=null and actual_mask.get_size()==Vector2i(3072,2048),"Fixed published default21401840, original fullworld loaded mask, no near/teleport"): return false
\tif not check(_live_clear(player.position),"Initial actual enabled34x24 Physics and17 loaded-mask observations",first_bad_foot): return false
\tmovement_driver=INPUT_DRIVER.new();movement_driver.call("configure",self)
\tvar moved: Dictionary=await movement_driver.call("drive",field,target,Callable(self,"_live_clear"))
\tinput_physics_samples=int(moved.get("physics_samples",0))
\trecords.append({"kind":"FIXED_ONLY32PX_REAL_INPUT_WITH_LIVE_BODY","result":moved,"endpoint_tolerance_px":.3,"Physics_queries":actual_queries,"mask17_observations":mask_observations,"first_bad":first_bad_foot,"source_path":"AE3D9F.short_route_px/F3FF.record.entry_foot_px/CF904.entry_return_move","source875_or_geometry_replay":false})
\tif not check(moved.get("ok")==true and input_physics_samples>0 and player.position.distance_to(target)<=.3,"One fixed32px real INPUT, every recorded original body clear",moved):
\t\t_record_terminal_snapshot("FIXED_SHORT_INPUT_FAILED")
\t\treturn false
\treturn check(current_scene==field and field.get("_current_scene")==scene and _loading_hidden(),"Same natural Field/Scene after real32px, no extra request")

'''
replace('func _capture_one() -> bool:\n',movement+'func _capture_one() -> bool:\n')
replace('\t\tif not _natural_owner(): return false\n','\t\tif not _natural_owner(): return false\n\t\tif not await _short_true_input(): return false\n')
replace('res://build/luoyang_city_full_rollout_20261022ap_root01/integration53/docks_diagnostic_READY/output/',res(OUT)+'/output_NOTREADY/')
replace('\tactive_id=&""\n\tif RenderingServer.frame_post_draw.is_connected(_draw):', '\tactive_id=&""\n\tif movement_driver!=null: movement_driver.call("release_movement")\n\tif RenderingServer.frame_post_draw.is_connected(_draw):')
replace('"INPUT":0,"Space":0,"Physics":0,"mask":0,','"INPUT":input_physics_samples,"Space":0,"Physics":actual_queries,"mask":mask_observations,')
replace('DOCKS_ONLY_DEFAULT_TERMINAL_DIAGNOSTIC_60s20s_NO_GATE_REPLAY_INPUT_ROOM_PHYSICS_COLLECTOR','DOCKS_ONLY_DEFAULT_ORDINARY21_REPAIR_REAL32PX_60s20s_ONE_PNG_NO_GATE_ROOM_GEOMETRY_COLLECTOR')
inverse=candidate
for h in reversed(hunks):
    a=h['before'].encode();b=h['after'].encode();assert inverse.count(b)==1
    inverse=inverse.replace(b,a,1)
assert inverse==oldkey and b'const FIXTURE_READY=false' in candidate
diff=''.join(difflib.unified_diff(oldkey.decode().splitlines(True),candidate.decode().splitlines(True),fromfile='Root53_D81D_executed_failure',tofile='NEW_Docks_ordinary21_NOTREADY'))
proof={'status':'FALSE_DOCKS1729_SOURCE_AND_REAL32PX_SCOPE_FIXED_NOT_EXECUTED','ready':False,
       'old_key_sha256':sha(oldkey),'new_key_sha256':sha(candidate),'full_inverse_sha256':sha(inverse),
       'fixture_sha256':fixhash,'fixed_owner95_sha256':sha(ownerpath.read_bytes()),'fixed_stage94_sha256':sha(stagepath.read_bytes()),
       'source_derivation':{'parent_count':1726,'target_value_changes':changes,'added_exact3':newkeys,'no_removed_key':True,'complete_derived_map_equals_owner95':True,'new_count':1729},
       'INPUT_path':ae['short_route_px'],'default_authority':ab['default_spawn_authority'],'qa_source_pins':qa_pins,
       'hunks':hunks,'budget_60s_20s_original_clock_cadence_retained':True,'C_natural_map_read_only_after_draw':True,
       'new_scope_explicitly_not_inherited_from53':'Only fixed32px INPUT with live original34x24 Physics and17 existing-mask observations; no source geometry, whole875, packet or image decode. No route change/teleport/fallback direction on failure.',
       'formal_guard_unknown':True,'fresh_before_unknown':True,'QA_engine_Stage_collector_native_decode_calls':0}
write_json(OUT/'whole_byte_inverse_and_source_scope_NOTREADY.json',proof)
with (OUT/'complete_vs_Root53.diff').open('x',encoding='utf-8',newline='\n') as f:f.write(diff)
handoff={'status':'DOCKS_ONLY_DEFAULT_ORDINARY21_FALSE_KEY_WAIT_FORMAL_GUARDS','ready':False,
         'key':{'path':res(OUT/'test_docks_default_ordinary21_NOTREADY.gd'),'sha256':sha(candidate),'bytes':len(candidate),'lines':len(candidate.splitlines())},
         'fixture':{'path':res(fixpath),'sha256':fixhash,'bytes':fixpath.stat().st_size},
         'proof':{'path':res(OUT/'whole_byte_inverse_and_source_scope_NOTREADY.json'),'sha256':sha((OUT/'whole_byte_inverse_and_source_scope_NOTREADY.json').read_bytes())},
         'diff_sha256':sha((OUT/'complete_vs_Root53.diff').read_bytes()),'source_count':1729,
         'blockers':fix['blockers'],'not_RUN_or_parse':True,
         'source_and_scope_boundary':'Owner95 derived only from fixed72 plus approved Stage94 values/3independent ordinary leaves. AA/AC fixes are not runtime-admitted by this key preparation. Root must read complete key+fixture+physical SHA and supply formal/fresh guards before NEW READY freeze.'}
write_json(OUT/'handoff_NOTREADY.json',handoff)
patch='*** Begin Patch\n*** Add File: '+str(OUT/'test_docks_default_ordinary21_NOTREADY.gd').replace('\\','/')+'\n'+''.join('+'+line+'\n' for line in candidate.decode().splitlines())+'*** End Patch'
print(json.dumps({'patch':patch,'summary':{'key_sha256':sha(candidate),'fixture_sha256':fixhash,'proof_sha256':handoff['proof']['sha256'],'handoff_sha256':sha((OUT/'handoff_NOTREADY.json').read_bytes()),'source_count':1729,'changed_existing_values':len(changes),'newkeys':3,'full_key_inverse':True,'INPUT_path':ae['short_route_px'],'ready':False,'engine':0}}))
