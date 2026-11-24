"""NEW data only. Fixed owner/deployment inputs, no source expectation crawl."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def load(p,s):
    b=p.read_bytes();assert sha(b)==s;return json.loads(b)
ownerpath=SF/'a2_source_recipe08/actual_independent_review/owner_source_maps_READY.json';oh='12924be9ea2c6a081b4865354d40075caa10e3804ad6c942e972f0270bd5219a'
owner=load(ownerpath,oh);row=next(r for r in owner['scenes'] if r['id']=='ch4_s1_luoyang_yamen')
assert len(row['source_sha256'])==1217 and row['source_sha256']==row['receipt_source_sha256']
gp=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration16/final_guard.json';gh='0dbf473bb55c75612b9f903dc37da2a8203f2080285e335cedade906cf8245f9'
guard=load(gp,gh);assert guard['passed'] is True and guard['unexpected_change_count']==0 and guard['save_change_count']==0
sources=copy.deepcopy(row['source_sha256'])
qa={'res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd':'a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895',res(ownerpath):oh,res(gp):gh}
for values in [owner['core_source_sha256'],qa]:
    for p,s in values.items():assert p not in sources or sources[p]==s;sources[p]=s
fixture={'status':'ROOT16_FIXED_YAMEN_PERFORMANCE03_ONE_DEFAULT_ENTRY_ONLY','ready':True,'whole_ms':60000,'max_pictures':0,'public_requests':1,'source_sha256':sources,'expected_city_source_sha256':row['source_sha256'],'scene_path':row['scene_path'],'layout_path':row['layout_path'],'owner_path':row['owner_path'],'firstdraw_target_usec':10000000,'performance_target_report_only_not_invented_pass':True,'authority':{'independent_owner':{'path':res(ownerpath),'sha256':oh},'actual_Root_deployment_guard':{'path':res(gp),'sha256':gh}},'measurement':'Public null/default request starts after QA precheck; ready and Loadinghidden/canmove frame_post_draw are timestamped before copied receipts, hashes or report. Not process startup, SSDcold or repeated entry.','natural_receipt_rule':'Read only existing C._resident_ready identity/token/finalized/sources after draw. Do not call resident_receipt/resident_matches/transition_sources/resolve/validation or generate source credit. Same-token transition_validation_state snapshots only joined scalar timings. Missing/reset stays missing, not zero.','scope':'One Yamen default public entry; zero input/teleport/doors/pictures/native or image decode/Physics/geometry/routes/NPC/art regression/collector. 15 saves preserved; no automatic replay to wash a slow result.'}
fp=QA/'yamen_performance03_fixture_ROOT16_READY.json';assert not fp.exists();b=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode()
with fp.open('xb') as f:f.write(b)
print(json.dumps({'path':res(fp),'sha256':sha(b),'source_guard_count':len(sources),'scene_path':row['scene_path'],'layout_path':row['layout_path']}))
