"""Read retained two results/small code/logs only. Never invoke Godot or decode media."""
from pathlib import Path
import hashlib,json
GAME=Path('F:/Code/RPG_GAME/game')
BASE=GAME/'build/luoyang_city_full_rollout_20261022ap_qa01/hall_column_portal_tint_execution_READY'
OUT=BASE/'two_actual_independent_review_READY.json'
assert not OUT.exists()
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path): return json.loads(path.read_bytes())
summaries={}
for mode,rel in [('geometry','geometry_output_READY/79080_1761/result.json'),('shader','portal_isolate/output_READY/78028_983/result.json')]:
    path=BASE/rel;result=read(path);receipt_path=BASE/(mode+'_once_process_receipt.json');receipt=read(receipt_path)
    assert result['complete'] is True and result['failures']==0
    assert receipt['actual_natural_console_exit_code']==0 and receipt['exit_code_from_retained_process_WaitForExit'] is True and not receipt['process_stopped_by_tool']
    assert receipt['script_sha256']==receipt['script_after_sha256']
    stderr=Path(receipt['stderr_path']);stdout=Path(receipt['stdout_path'])
    assert sha(stderr)==receipt['stderr_sha256'] and stderr.stat().st_size==0
    assert sha(stdout)==receipt['stdout_sha256']
    text=stdout.read_text(encoding='utf-8',errors='replace')
    assert 'SCRIPT ERROR' not in text
    assert result['source_before']==result['source_after']
    assert result.get('players_before',result.get('saves_before'))==result.get('players_after',result.get('saves_after'))
    saves=result.get('players_before',result.get('saves_before'));assert len(saves)==15
    # Only small code/fixture is independently current-hashed; asset current facts
    # are producer first/final declarations, not an additional QA decode/hash.
    checked=[];declared_only=[]
    for source,facts in result['source_before'].items():
        local=GAME/source[6:] if source.startswith('res://') else Path(source)
        if local.suffix in ['.gd','.gdshader','.json','.godot','.tscn']:
            assert local.stat().st_size==facts['bytes'] and sha(local)==facts['sha256']
            checked.append(source)
        else: declared_only.append(source)
    common={'result':{'path':str(path),'sha256':sha(path)},'process_receipt':{'path':str(receipt_path),'sha256':sha(receipt_path)},'complete':True,'checks':result['checks'],'failures':0,'script_elapsed_ms':result['elapsed_ms'],'retained_process_wall_ms':receipt['elapsed_wall_ms'],'actual_exit_code':0,'stderr_bytes':0,'editor51856_retained':receipt['editor51856_still_running'],'source_first_final_equal_count':len(result['source_before']),'small_current_source_verified_count':len(checked),'media_source_fact_only':declared_only,'save15_equal':True,'save_mtime_precision':'Godot seconds only; Root external exactUTCticks guard separate','no_QA_engine':True}
    if mode=='geometry':
        legs=[r for r in result['records'] if r.get('kind')=='behind_column_short_leg'];assert len(legs)==2
        for r in legs: assert r['reached'] and r['all_foot_clear'] and r['all_shapes_clear'] and not r['contacts']
        negatives=[r for r in result['records'] if r.get('kind')=='base_center_negative'];assert len(negatives)==2
        for i,r in enumerate(negatives): assert r['column']==i and not r['foot_clear'] and len(r['hits'])==1 and r['hits'][0]['name']==f'fixed_column_{i}'
        contact=[r for r in result['records'] if r.get('kind')=='true_base_contact_negative'];assert len(contact)==1
        assert not contact[0]['reached'] and contact[0]['contacts'][0]['name']=='fixed_column_0' and contact[0]['all_shapes_clear']
        common.update(behind_legs=[{'start_target_end':r['target'],'end':r['actual'],'actual_physics_steps':len(r['physics_steps'])} for r in legs],base_center_negative_count=2,base_contact_end=contact[0]['actual'],base_contact_name='fixed_column_0',credit='canonical OLD compile + candidate pure helper actual34x24 Physics; no candidate G dispatch/Field/Player/INPUT/ghost/ART')
    else:
        assert len(result['records'])==6 and result['Field']==0 and result['autoload']==0 and result['import']==0 and result['PNG_output']==0
        rows=[]
        for r in result['records']:
            assert r['eligible_pixels']>0 and r['candidate_mismatch_pixels']==0
            rows.append({k:r[k] for k in ['state','scale','eligible_pixels','candidate_mismatch_pixels','old_mismatch_pixels','edge_or_outline_changed_pixels_not_body']})
        common.update(rows=rows,credit='one raw asset decode,18 isolated framebuffer captures; normal/locked allregion and ready opaque-body exact reference equality; outline edge differences recorded not independent fulloutline proof; locked tint intentional; no real portal state/Field hookup credit')
    summaries[mode]=common
review={'status':'INDEPENDENT_RETAINED_TWO_COMPONENT_ACTUAL_REVIEW_NOT_FIELD_OR_ALLCITY','tests':summaries,'scope':'No Godot rerun, media decode/hash, oldgeometry replay, collector, production or player write. Prior scholar/bench failures remain untouched. Result numeric object identities are not recopied; named contacts suffice.'}
OUT.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'path':str(OUT),'sha256':sha(OUT),'geometry_checks':summaries['geometry']['checks'],'shader_checks':summaries['shader']['checks'],'natural_exit_codes':[0,0]},ensure_ascii=False))
