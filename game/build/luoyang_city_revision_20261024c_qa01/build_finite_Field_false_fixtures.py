"""Only NEW false fixtures; no current-source expected map / engine / media access."""
import hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
OUT=BASE/'finite_Field_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,value):
    p=OUT/name;assert not p.exists(),p
    p.write_bytes((json.dumps(value,ensure_ascii=True,indent=2)+'\n').encode())
    return dict(path=str(p),sha256=sha(p),bytes=p.stat().st_size)
author=GAME/'build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json'
assert sha(author)=='51582b8d281876b08989acef6d16e9216022bad34640cb7bf1c872f0cc2cf429'
a=json.loads(author.read_text(encoding='utf-8'))
old_fixture=GAME/'build/luoyang_city_revision_20261024b_qa01/market_task_decline_only_remaining_READY/fixture_READY.json'
assert sha(old_fixture)=='2f7bf89461c366f8dd610db225a61fadf92347d5306baa67a35c93d9b9676e7d'
old=json.loads(old_fixture.read_text(encoding='utf-8'))
pins={}
for file in [OUT/'common.gd',GAME/'build/luoyang_city_revision_20261024b_qa01/root_market_journey18_ground_READY/test_READY.gd',GAME/'tests/test_luoyang_city_life_cpu_draft_20261016f.gd',GAME/'tests/helpers/v15_input_driver.gd']:
    pins['res://'+file.relative_to(GAME).as_posix()]=sha(file)
common=dict(ready=False,formal_deployed=False,status='HARDFALSE_PENDING_FINAL_FIXED_SOURCE_MAP_AND_DEPLOYMENT',
    blockers=['Source final expected map path/SHA/count and fixed runtime/binding/Field pins','Root exact deployment/fresh guard; candidate read and mechanical readiness freeze only'],
    whole_ms=60000,entry_ms=20000,camera_zoom=1.05,viewport=[1920,1080],
    expected_city_count=None,expected_city_sources={},source_sha256=pins,
    stage=None,deployment=None,fresh_guard=None,hero_fallback_portrait=old['hero_fallback_portrait'],
    no_default_performance_credit=True,old_full_geometry_replay=False)
y=dict(common,scene_id='ch4_s1_luoyang_yamen',public_near=[590,1048],max_pictures=2,
    courts_runtime_path='PENDING_FINAL_SOURCE_RUNTIME',effective_mask_path='PENDING_FINAL_SOURCE_MASK',
    official_texture=a['asset']['texture'],east_setup_QA_only_approved=True,east_inspection_setup=[2664,1098],
    west_path=[[590,1048],[590,1135]],east_path=[[2664,1098],[2664,1260]],
    preserved_npcs=a['preserved']['all_original_npcs'],hall_room_id=a['preserved']['hall_room_id'],annexes=[],
    Root_scope='East pose one explicit QA-only setup approved; not continuous court travel; two Yamen images only. NPCs/production unchanged.')
for index,c in enumerate(a['annex_changes']):
    y['annexes'].append(dict(id=c['id'],foot_px=c['new_foot_px'],base_polygon=c['new_primitive']['points_px'],negative=a['negative_body_centres'][index]))
s=dict(common,scene_id='ch4_s3_luoyang_market',public_near=[520,1400],max_pictures=0,
    scholar_portrait='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png',
    task_primary=old['task']['primary_path_id'],culture_menu_labels=old['task']['culture_menu_labels'],
    Root_scope='Real hero->x_0_menu dedicated portrait->KEY3leave; no Task primary topic/offer/rewards, no vendor/route replay, no third image.')
print(json.dumps(dict(yamen=write('yamen_fixture_NOTREADY.json',y),scholar=write('scholar_fixture_NOTREADY.json',s))))
