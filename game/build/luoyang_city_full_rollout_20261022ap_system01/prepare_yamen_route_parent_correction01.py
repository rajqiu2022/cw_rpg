"""Expose actual immutable assembled parent route ordinals; no native decode/run."""
from pathlib import Path
import copy, hashlib, json
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OUT=ROOT/'yamen_route_parent_correction01'
OUT.mkdir(exist_ok=False)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def pin(p): return {'path':'res://'+p.relative_to(GAME).as_posix(),'sha256':sha(p)}
def equal(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return a==b
p=GAME/'build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s1_luoyang_yamen/manifest.json'
assert sha(p)=='517a0e68c01dd2ff27a648f72736a100c8523780d5f49423b682c3452b94a32f'
parent=json.loads(p.read_text(encoding='utf-8'))
routes=parent['record']['routes']
assert routes[1]['id']=='court_loop' and len(routes[1]['points_px'])==15
assert routes[2]['id']=='case_board' and len(routes[2]['points_px'])==5
child=copy.deepcopy(parent)
changes=[]
for route_index,point_index,expected in [(1,1,[1100.,1360.]),(1,2,[1100.,1135.]),(2,0,[1100.,1360.]),(2,1,[1100.,1135.])]:
    before=routes[route_index]['points_px'][point_index]
    assert equal(before,expected)
    after=[1280.,before[1]]
    child['record']['routes'][route_index]['points_px'][point_index]=after
    changes.append({'route_id':routes[route_index]['id'],'route_index_in_immutable_manifest':route_index,
        'point_ordinal':point_index,'pointer':f'/record/routes/{route_index}/points_px/{point_index}',
        'before':before,'after':after})
inverse=copy.deepcopy(child)
for row in changes:
    inverse['record']['routes'][row['route_index_in_immutable_manifest']]['points_px'][row['point_ordinal']]=copy.deepcopy(row['before'])
assert equal(inverse,parent)
assert equal(child['record']['routes'][1]['points_px'][6:8],[[1100.,1135.],[1100.,1080.]])
assert equal(child['record']['routes'][2]['points_px'][-1],[550.,1240.])
tpath=GAME/'build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json'
t=json.loads(tpath.read_text(encoding='utf-8'))
assert t['districts']['ch4_s1_luoyang_yamen']['route_replacements']==[]
result={'status':'STATIC_IMMUTABLE_PARENT_CORRECTION_NOT_NATIVE_RUNTIME_FACT_OR_APPROVAL',
    'immutable_parent_manifest':pin(p),'route_dictionary_pointers':['/record/routes/1','/record/routes/2'],
    'original_route_dictionaries':[routes[1],routes[2]],'exact_four_ordinal_changes':changes,
    'candidate_route_dictionaries':[child['record']['routes'][1],child['record']['routes'][2]],
    'whole_manifest_typed_inverse':True,'numeric_types_preserved':'Original JSON float pairs -> float pairs, strict recursive type check, not generic Python ==',
    'court_loop_ordinals_6_7_unchanged':routes[1]['points_px'][6:8],'case_board_real_stand_unchanged':routes[2]['points_px'][-1],
    'later_pure_transform_lineage':[
        {'source':pin(GAME/'scripts/city/luoyang_yamen_annex_revision_20261016.gd'),'function':'compose','scope':'Only assembled_east_service_front changed; appends4annex routes. court_loop/case_board untouched.'},
        {'source':pin(GAME/'build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd'),'function':'compose','author':pin(tpath),'scope':'Yamen route_replacements empty; appends t_official_hall_approach only.'}],
    'required_actual_gate':'Publisher must decode fixed current native04F2 packet and compare its complete court_loop/case_board dictionaries against this immutable source before changing any point. This script does not decode the native packet or assert actual comparison passed.',
    'supersedes_claim_only':'EA340 amendment mistakenly named y1080 from older art_contract. Original file and incorrect approval retained; no execution.'}
out=OUT/'evidence_READY.json'
out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(pin(out)))
