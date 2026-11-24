"""Small actual review + source-fixed remaining fixture. No engine/media decoding."""
import copy,hashlib,json,re
from pathlib import Path
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1]
ROOT=GAME/'build/luoyang_city_revision_20261024c_root01'
OLD=BASE/'finite_Field_READY01/yamen_courts'
OUT=BASE/'finite_Field_remaining_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p,h):
    assert sha(p)==h,(p,sha(p));return json.loads(p.read_text(encoding='utf-8'))
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def write(name,v):
    p=OUT/name;assert not p.exists(),p
    p.write_bytes((json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode())
    return dict(path=res(p),sha256=sha(p),bytes=p.stat().st_size)
def main():
    actualp=OLD/'output_READY/43628_2926/result.json'
    r=read(actualp,'48761b930f69c867ffd020f3c7f08773531d089ca6b69e7dcb2149f0653e5f10')
    pp=ROOT/'yamen_finite_Field_once_process_receipt.json';p=json.loads(pp.read_text(encoding='utf-8'))
    assert r['complete'] is False and r['checks']==40 and r['failures']==2 and r['elapsed_ms']==14621
    assert p['actual_natural_console_exit_code']==1 and p['exit_code_from_retained_process_WaitForExit'] is True and p['process_stopped_by_tool'] is False
    assert p['script_sha256']==p['script_after_sha256']=='c1fe886387e90930b2267d8f0871caf023ed0f5a38d218f85a693e013be25f1d'
    stderr=Path(p['stderr_path']);stdout=Path(p['stdout_path'])
    assert sha(stderr)==p['stderr_sha256'] and sha(stdout)==p['stdout_sha256']
    lines=stderr.read_text(encoding='utf-8').splitlines()
    log_counts={k:sum(line.startswith(k+':') for line in lines) for k in ['ERROR','WARNING','SCRIPT ERROR']}
    assert log_counts=={'ERROR':7,'WARNING':0,'SCRIPT ERROR':0},log_counts
    assert r['source_before']==r['source_after'] and r['players_before']==r['players_after'] and len(r['players_before'])==15
    rec=r['records'];sprite=[x for x in rec if x['kind']=='ANNEX_ACTUAL_SPRITE_SOURCE_PROJECTION']
    bases=[x for x in rec if x['kind']=='NEW_BASE_ACTUAL_PHYSICS_NEGATIVE']
    natural=[x for x in rec if x['kind']=='NATURAL_LOCAL_CITY_FINAL'][0]
    state=[x for x in rec if x['kind']=='NATURAL_COURTS_STATE_ONLY'][0]['state']
    scope=[x for x in rec if x['kind']=='FINITE_24C_ONLY'][0]
    assert natural['count']==1319 and state['finalized'] is True and state['solid_count']==40 and state['district_solid_count']==10
    assert len(sprite)==len(bases)==2 and all(x['visible'] is True and x['position']==x['expected_position'] and x['scale']=='(0.5, 0.5)' for x in sprite)
    assert all(any(h['expected_polygon_exact'] is True and h['authoring_id']==sprite[i]['id'] for h in x['hits']) for i,x in enumerate(bases))
    assert scope['real_INPUT_ticks']==0 and scope['pictures']==1 and scope['Physics_queries']==2
    image=[x for x in rec if x['kind']=='LOCAL_PNG_NOT_WHOLE_CITY_ART'][0]
    assert image['sha256']=='a49bc245a3f10a8c76d14b8b8ba9e0ef1eb05d77a52103fd77cf61f8b0c0b767'
    crowd=GAME/'scripts/city/luoyang_district_life_crowd_20261016f.gd'
    assert sha(crowd)=='58cebe7fea4304006245bc32822993d6ae2cddd583b2a3c6e9e2c16096706641'
    text=crowd.read_text(encoding='utf-8')
    assert 'var id: String="district_life_"+String(row.get("id",""))' in text
    field=GAME/'scripts/field/field_walkable_controller.gd'
    assert sha(field)=='ad2a3569f8fc0b570dc288dff6da7a7b3222c103ede041c7de54d781900bb575'
    assert 'npc.npc_id = String(d.get("npc_id", ""))' in field.read_text(encoding='utf-8')
    oldp=OLD/'fixture_READY.json';old=json.loads(oldp.read_text(encoding='utf-8'))
    fixture=copy.deepcopy(old)
    fixture.update(ready=False,status='ROOT_APPROVED_YAMEN_REMAINING_ONLY_NOTREADY',max_pictures=1,fresh_guard=None,
        blockers=['New successful Root current guard and mechanical readiness freeze only; no production/source changes'],
        west_setup_QA_only_approved=True,west_inspection_setup=[590,1048],
        passed_prefix_not_repeated=dict(result=dict(path=res(actualp),sha256=sha(actualp)),west_image=image,
            natural1319=True,lease40_10=True,two_source_sprites=True,two_new_base_Physics=True,hall1536660=True),
        public_spawn_contract='One public near is not assumed to place exact source foot; both subsequent inspection setups are explicit, approved and body/Physics checked. No continuous two-court travel claim.')
    mapping=[]
    for spec in old['preserved_npcs']:
        source=spec.get('id',spec.get('source_id'))
        district='family' in spec
        mapping.append(dict(source_id=source,runtime_id=('district_life_'+source if district else source),
            foot_px=spec['foot_px'],distance_px=spec.get('distance_px',0),must_exist=district,
            missing_meaning='LOOKUP_ABSENT_NOT_VALIDATED_QUESTGATE'))
    assert len(mapping)==9 and sum(x['must_exist'] for x in mapping)==6
    fixture['original_npc_runtime_mapping']=mapping
    fixture['source_sha256'][res(crowd)]=sha(crowd)
    fixture['source_sha256'][res(OLD/'test_READY.gd')]=p['script_sha256']
    fixture['source_sha256'][res(actualp)]=sha(actualp)
    npc_proof=dict(status='SOURCE_FIXED_NPC_ID_MAPPING_CORRECTION_NOT_ACTUAL_CROWD_PASS',
        source=dict(path=res(crowd),sha256=sha(crowd)),mapping=mapping,
        exact_rule='CROWD.project: district_life_ + row.id; Field npc.npc_id=d.npc_id; AP visual projection does not change ID; clerk helper only moves pos, not ID.',
        first_report_correction='Original first six unprefixed lookups were wrong. active:false is lookup absent, not proof of quest gating or real actor absence. Keep original report unchanged.',
        last_three='No prefix for original native IDs. A missing lookup remains UNKNOWN/NOT_VALIDATED_QUESTGATE; no forced visibility or inferred reason.')
    n=write('NPC_id_mapping_source_READONLY.json',npc_proof)
    fixture['source_sha256'][n['path']]=n['sha256']
    fi=write('fixture_NOTREADY.json',fixture)
    review=dict(status='FIRST_YAMEN_ACTUAL_COMPONENTS_WITH_WHOLEFAIL_PRESERVED',passed_for_components_only=True,
        actual=dict(path=res(actualp),sha256=sha(actualp)),process=dict(path=res(pp),sha256=sha(pp)),
        checks=40,failures=2,complete=False,elapsed_ms=14621,true_console_exit=1,stderr_counts=log_counts,not_clean=True,
        natural_map_count=1319,lease_solids=[40,10],two_exact_source_sprites=sprite,new_base_actual_Physics=bases,
        west_image=image,QA_viewed_original_west_image=True,
        image_observation='West official annex full silhouette/door/steps readable; recess from wall and side gap visible. Large stone paving and hard field divisions remain; not wholecourtyard ART.',
        failure='Public near accepted but actual safe fallback (582.9767,1012.692), not requested590,1048; strict path start rejected before any INPUT. No failed movement/navigation/base-blocking evidence.',
        retained_scope=dict(INPUT=0,body_Physics_queries=2,pictures=1,no_old_geometry_replay=True),
        source_first_final_same_count=len(r['source_before']),save15_first_final_same=True,
        NPC_mapping_correction=n,remaining_fixture=fi,
        no_new_engine_decode_or_production_write=True)
    print(json.dumps(dict(fixture=fi,npc_proof=n,review=write('first_actual43628_review_READONLY.json',review))))

if __name__=='__main__':main()
