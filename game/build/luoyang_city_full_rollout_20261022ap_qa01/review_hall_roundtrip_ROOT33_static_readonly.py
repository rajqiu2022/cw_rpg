"""Static finite-scope audit only; no Godot/collector/geometry execution."""
from pathlib import Path
import hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'hall_roundtrip_ROOT33_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return GAME/p.removeprefix('res://')
h=rd(D/'handoff_ROOT33_READY_NOT_RUN.json');key=res(h['key']['path']);fp=res(h['fixture']['path']);f=rd(fp)
assert sha(key)==h['key']['sha256']=='d16f5dbbac971bfdd25f95790d8ebefe449914b95161840ec76126cc6a54b609'
assert sha(fp)==h['fixture']['sha256']=='92a78e2530269d8798f5f52e0ffd9eb46d5d6b2c9361a4267e8b9879bc375bc2'
text=key.read_text(encoding='utf-8');inverse=text
for q in reversed(h['literal_hunks']):
    assert inverse.count(q['new'])==1;inverse=inverse.replace(q['new'],q['old'],1)
assert inverse.encode()==res(h['template']['path']).read_bytes()and sha(res(h['template']['path']))==h['template']['sha256']
owner=rd(res(f['authority']['owner']['path']));city=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen');globalG=owner['rooms'][0]['source_sha256']
assert f['expected_city_sources']==city['source_sha256']and len(f['expected_city_sources'])==1239
assert f['expected_G_global_sources']==globalG and len(globalG)==557 and all(r['source_sha256']==globalG for r in owner['rooms'])
assert len(set(globalG)-set(city['source_sha256']))==22 and len(set(globalG)|set(city['source_sha256']))==1261
for table in (city['source_sha256'],globalG):assert all(f['source_sha256'][k]==v for k,v in table.items())
assert len(f['source_sha256'])==1289
reg=rd(res(f['authority']['registry']['path']));row=reg['rooms']['luoyang_yamen_official_hall_20261018t']
assert f['hall_row']==row and len(row['source_sha256'])==247
assert f['hall_author']==rd(res(f['authority']['hall_author']['path']))
assert [k for k,v in row['source_sha256'].items()if globalG[k]!=v]==['res://scripts/city/luoyang_district_life_20261016f.gd']
assert (f['whole_ms'],f['entry_ms'],f['room_ms'],f['return_ms'],f['max_pictures'])==(60000,20000,20000,10000,0)
assert f['setup_uv']==[.5,716/2048]and f['street_input']==[[1536,716],[1536,660]]and f['room_input']==[[960,1050],[960,1142.5]]and f['author_return_world']==[1536,660]
assert text.count('.call("go_field_smart"')==1 and text.count('await driver.key(KEY_SPACE)')==2
for forbidden in ('.source_paths(','.catalogue(','.finalize_setup(','.resident_receipt(','.resident_matches(','.safe_body(','.compile_geometry(','save_png(','reset_for_new_game','set_position('):assert forbidden not in text,forbidden
assert 'query.shape=shape.shape' in text and 'shape.shape.size!=Vector2(34,24)'in text and 'intersect_shape(query,16)'in text
assert 'estimated_bytes)<=536870912' in text and 'ret.get("final_live_identity")==true'in text and 'source_basis")=="SAME_LIVE_OBJECTS_AND_EDITOR_METADATA"'in text
assert 'field.get("_player").position==_v(fixture.author_return_world)'in text
out=D/'independent_static_scope_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT33_SINGLE_REAL_HALL_ROUNDTRIP_STATIC_NO_BLOCKER_NOT_RUNTIME_OR_PARSE_PASS','key':h['key'],'fixture':h['fixture'],'whole_byte_reverse_to_template':True,'scope':{'whole60s':True,'near_setup_not_default_travel':True,'initial_and_room_caps20s':True,'warm_hidden_draw_under10s':True,'true_INPUT_short_routes2_and_Space2':True,'pictures0_collector0_geometry_publication0':True,'full_original34x24_actualPhysics_plus_loaded17mask_when_present':True,'same_live_WeakRefs_and_PARKED_memory512MiB_RESUMED_ready_hit_required':True,'author_return1536_660_not_departurefoot':True},'source_domains':{'C_natural_final1239':True,'globalG557_independent_firstfinal_guard_not_session_sources':True,'G_extra22_guarded_no_Csubset_fiction':True,'hall247_historical_registry_whole_unchanged':True,'sole_DT_approved_history_not_rewritten':True,'guard1289_recipe':True},'timing_limits':['All hidden rendered clocks frozen before source/session/lease deep checks','Ready scalar is first observed ready; no fabricated stage ordering if draw occurs during real key await','Room lease total_ms excludes loading hide; only armed Space-to-hidden operable draw decides warm<10s','Perleg20/20/10 caps not permission to exceed60s; finishing source hashes stay inside whole failure rule'],'preexecution':['No test has run or been Godot-parsed here','No fallback, QAfinalize, manualcollector, roomprop or oldgeometry replay','Root must read frozen complete key and fixture then uniquely execute']},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'lines':len(text.splitlines())}))
