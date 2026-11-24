"""31d guard scope framework, stdout only. Pending city heads are NOT accepted."""
from pathlib import Path
import hashlib,json
ROOT=Path('F:/Code/RPG_GAME');QA=ROOT/'game/build/world_cities_20261031d_qa01'
baseline_path=QA/'baseline_NOW_ACTUAL.json'
assert hashlib.sha256(baseline_path.read_bytes()).hexdigest()=='4df3ece41c552cb279866283a39bf8c020e035d749b8f6018e9991533570b4ed'
b=json.loads(baseline_path.read_text(encoding='utf-8-sig'))
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
system=read('game/build/environment_residual_20261031d_system01/replacement_receipt_READY.json')
jx=read('game/build/city_neighborhoods_20261031d/jx_manifest_READY02.json')
ly=read('game/build/city_neighborhoods_20261031d/closure_READY/receipt_READY.json')
paths={row['target'] for row in jx['targets']+ly['targets']}
paths.update([
system['world_watcher']['path'],system['huashan_scene']['path'],
'game/build/three_towns_world_20261029j_system01/native_sources.json',
'game/build/three_towns_world_20261029j_system01/town_registry.gd','prompts/tasks.yaml'])
assert len(paths)==18
out={
 'schema_version':1,'status':'DRAFT_ONLY_PENDING_CITY_SUCCESSORS_DO_NOT_RUN',
 'baseline_sha256':'4df3ece41c552cb279866283a39bf8c020e035d749b8f6018e9991533570b4ed',
 'baseline_source_count':2317,'save_count':171,'expected_absent_count':9,
 'allowed_old_targets':{},'new_runtime_pins':{},'evidence_pins':{},
 'native_manifest':'game/build/three_towns_world_20261029j_system01/native_sources.json',
 'native_count':226,
 'pending':['JX west_service geometry successor','LY xuantong business-object clearance successor and source closure','final Root-reviewed after pins and evidence facts'],
 'previous_functional_successes_not_repeated':['World portals','Wudang enclosure','Taiji/Purple return','Huashan stairs','NPC facing','animated water'],
 'visual_actual_inherited':{'pid':136304,'checks':29,'errors':0,'inputs':0,'hero_RGB_matching':[2432,2458],'old_huashan_clear_ROI_filled':27000},
 'old_body_placement_failures_retained':True,'engine_runs':0,'save_content_reads':0}
for relative in sorted(paths):
    p=(ROOT/relative).as_posix();fact=b['facts'][p]
    assert fact['exists']
    out['allowed_old_targets'][relative]={'before_sha256':fact['sha256'],'before_bytes':fact['bytes'],'after_sha256':None,'after_bytes':None,'status':'PENDING_EXPLICIT_FINAL_PIN_NOT_CURRENT_AUTO_ACCEPT'}
print(json.dumps(out,ensure_ascii=False,indent=2))
