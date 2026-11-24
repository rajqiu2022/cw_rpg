"""Explicit Pair-only successor; source I/O only, never userdata or old mains."""
from pathlib import Path
import argparse, importlib.util, json, hashlib, sys
sys.dont_write_bytecode=True
HERE=Path(__file__).resolve().parent
OLD=HERE.parent/'city_navigation_20261102a_guard01'
H='e6f37ad5c6059a0e12629556a5329e84f7aca566ed464c6728bfcb4952c7c2eb'
assert hashlib.sha256((OLD/'verify_sources_ROOT_ONLY.py').read_bytes()).hexdigest()==H
spec=importlib.util.spec_from_file_location('road02a_definitions',OLD/'verify_sources_ROOT_ONLY.py')
v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
PAIR='res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd'

def main():
    p=argparse.ArgumentParser();p.add_argument('--authorization',required=True);p.add_argument('--authorization-sha256',required=True)
    p.add_argument('--capture',default=str(OLD/'capture_before_ACTUAL.json'));p.add_argument('--output',default=str(HERE/'source_preflight_ACTUAL.json'))
    a=p.parse_args();out=v.inside(a.output);assert out.parent==HERE and not out.exists()
    au=v.load(a.authorization,a.authorization_sha256.lower())
    assert au['schema']=='CITY_NAVIGATION_ROADMOUTHS_20261102A_PAIR_FINAL_AUTHORIZATION_V1' and au['root_approved'] is True
    base=v.load(v.res(au['inherited_stage_authorization_path']),au['inherited_stage_authorization_sha256'])
    assert base['root_approved'] is False and base['capture_sha256']==au['capture_sha256']
    assert au['inherited_verifier_sha256']==H and v.res(au['inherited_verifier_path'])==OLD/'verify_sources_ROOT_ONLY.py'
    cap=v.load(a.capture,au['capture_sha256']);assert cap['captured_successfully'] and cap['finite_deduplicated_source_count']==208
    assert cap['immutable134_count']==134 and cap['save_count']==171 and cap['save_metadata_passes']==1
    assert v.same(v.fact(cap['prior_guard_path']),cap['prior_guard_fact']) and cap['prior_guard_sha256']==base['prior_guard_sha256']
    assert v.same(v.fact(OLD/'capture_before_ROOT_ONLY.ps1'),cap['capture_script_fact'])
    assert v.same(v.fact(cap['established_guard_helper_path']),cap['established_guard_helper_fact'])
    manifest=cap['current_manifest_path'];mutable=v.HELPERS|{PAIR,manifest}
    assert set(cap['allowed_prospective_mutable_paths'])==v.HELPERS|{manifest}
    assert not (mutable&set(cap['immutable134_paths']))
    facts={k:v.fact(v.res(k)) for k in cap['before_source_facts']};assert len(facts)==208
    for k,b in cap['before_source_facts'].items():
        if k not in mutable:assert v.same(facts[k],b),('IMMUTABLE204_CHANGED',k)
    backups={}
    for k,row in cap['full_backups'].items():
        assert v.same(v.fact(row['path']),row['fact']) and v.same(row['fact'],cap['before_source_facts'][k]);backups[k]=row
    pc=v.load(v.res(au['pair_capture_path']),au['pair_capture_sha256'])
    assert pc['schema']=='CITY_NAVIGATION_ROADMOUTHS_20261102A_PAIR_SUPPLEMENT_CAPTURE_V1' and pc['captured_successfully']
    assert pc['original_capture_sha256']==au['capture_sha256'] and pc['target']==PAIR and pc['save_metadata_passes']==0
    assert v.same(pc['before_fact'],cap['before_source_facts'][PAIR]) and v.same(pc['full_backup']['fact'],pc['before_fact'])
    assert v.same(v.fact(pc['full_backup']['path']),pc['full_backup']['fact'])
    assert v.same(v.fact(HERE/'capture_pair_before_ROOT_ONLY.ps1'),pc['capture_script_fact']);backups[PAIR]=pc['full_backup']
    ground=base['existing_ground_media_pins'];assert ground==cap['approved_existing_ground_source_sha256'] and len(ground)==3
    for k,h in ground.items():assert facts[k]['sha256']==h and v.same(facts[k],cap['existing_ground_source_facts'][k])
    stages=[];data={k:v.inside(backups[k]['path']).read_bytes() for k in v.HELPERS};fresh=dict(data);sample_data=None
    for name in ('sample_stage','final_stage'):
        s=base[name];plan=v.load(v.res(s['plan_path']),s['plan_sha256']);hs=v.load(v.res(s['hunks_path']),s['hunks_sha256']);v.load(v.res(s['apply_path']),s['apply_sha256'])
        rows={r['path']:r for r in plan['targets']};hunks={r['target']:r['hunks'] for r in hs}
        assert set(rows)==set(hunks)==v.HELPERS
        if name=='final_stage':assert plan['targets']==s['targets']
        proof={}
        for k in v.HELPERS:
            r=rows[k];before=data[k];after=v.res(r['candidate']).read_bytes()
            assert v.sha(before)==r['before_sha256'] and len(before)==r['before_bytes']
            assert v.sha(after)==r['after_sha256'] and len(after)==r['after_bytes']
            assert v.splice(before,hunks[k])==after and v.splice(after,hunks[k],True)==before
            proof[k]={'before':v.sha(before),'after':v.sha(after),'wholebyte_forward_inverse':True};data[k]=after
        stages.append({'stage':name,'proofs':proof,'hunks':hunks})
        if name=='sample_stage':sample_data=dict(data)
    for k in v.HELPERS:
        assert v.res(k).read_bytes()==data[k] and facts[k]['sha256']==base['final_helper_afters'][k]
        assert v.splice(v.splice(data[k],stages[1]['hunks'][k],True),stages[0]['hunks'][k],True)==fresh[k]
    ps=au['pair_stage'];pp=v.load(v.res(ps['plan_path']),ps['plan_sha256']);ph=v.load(v.res(ps['hunks_path']),ps['hunks_sha256']);v.load(v.res(ps['apply_path']),ps['apply_sha256'])
    row=ps['target'];assert row['path']==PAIR
    # Exact candidate plan/hunks format is finite: one Pair target only.
    assert len(pp['targets'])==1
    for key in ('path','candidate','before_sha256','before_bytes','after_sha256','after_bytes'):assert pp['targets'][0][key]==row[key]
    assert len(ph)==1 and ph[0]['target']==PAIR
    before=v.inside(backups[PAIR]['path']).read_bytes();after=v.res(PAIR).read_bytes()
    assert v.sha(before)==row['before_sha256'] and len(before)==row['before_bytes']
    assert v.sha(after)==row['after_sha256'] and len(after)==row['after_bytes'] and after==v.res(row['candidate']).read_bytes()
    assert v.splice(before,ph[0]['hunks'])==after and v.splice(after,ph[0]['hunks'],True)==before
    old=v.load(backups[manifest]['path'],base['manifest_before_sha256']);assert old['source_pins']==cap['manifest_before_source_pins'] and len(old['source_pins'])==96
    sample=v.load(v.res(base['sample_stage']['manifest_archive']),base['sample_stage']['manifest_sha256'])
    prepair=v.load(v.res(au['pre_pair_manifest_archive']),au['pre_pair_manifest_sha256']);assert au['pre_pair_manifest_sha256']==base['manifest_after_sha256']
    current=v.load(v.res(manifest),au['manifest_after_sha256'])
    expected_sample={**old['source_pins'],**{k:v.sha(sample_data[k]) for k in v.HELPERS},**ground}
    expected_pre={**old['source_pins'],**base['final_helper_afters'],**ground};expected={**expected_pre,PAIR:row['after_sha256']}
    assert sample['ready'] and sample['source_pins']==expected_sample and prepair['ready'] and prepair['source_pins']==expected_pre
    assert current['ready'] and current['source_pins']==expected and len(expected)==au['expected_final_leaf_count']==99
    assert sum(expected[k]==h for k,h in old['source_pins'].items())==au['expected_unchanged_original96_leaf_count']==93
    assert sum(expected[k]==h for k,h in expected_pre.items())==au['expected_unchanged_pre_pair99_leaf_count']==98
    for k,h in expected.items():assert facts[k]['sha256']==h
    qa={}
    for r in base['qa_evidence']+au['qa_evidence']:
        f=v.fact(v.res(r['path']));assert f['sha256']==r['sha256'];qa[r['role']]=f
        if r.get('require_passed'):assert v.load(v.res(r['path']))['passed'] is True
    assert set(au['required_final_qa_roles'])<=set(qa)
    baseline=v.load(v.res(next(r['path'] for r in base['qa_evidence'] if r['role']=='baseline_remaining14')))
    assert baseline['actual_true_legs']==14 and baseline['input_events']==56
    local=v.load(v.res(next(r['path'] for r in au['qa_evidence'] if r['role']=='pair_two_directions_report')))
    assert local['passed'] is True and local['checks']==109 and local['errors']==[] and local['actual_true_legs']==2 and local['input_events']==8
    assert {r['key'] for r in local['passed_legs']}=={'yamen_artisan:a','yamen_artisan:b'}
    assert au['functional_credit']['unique_directions']==22 and au['functional_credit']['unchanged20_not_reexecuted'] is True
    report={'schema':'CITY_NAVIGATION_ROADMOUTHS_20261102A_PAIR_SOURCE_PREFLIGHT_V1','passed':True,'source_facts':facts,'finite_source_count':208,'immutable134_count':134,'unchanged_finite_source_count':204,'mutable_paths':sorted(mutable),'full_before_backup_count':4,'helper_stages':stages,'combined_helper_inverse_exact':True,'pair_inverse_exact':True,'manifest_stages':[base['manifest_before_sha256'],base['sample_stage']['manifest_sha256'],au['pre_pair_manifest_sha256'],au['manifest_after_sha256']],'runtime_leaves':99,'unchanged_original96_leaves':93,'unchanged_pre_pair99_leaves':98,'ground3_unchanged':True,'qa_evidence_facts':qa,'inherited_actual_directions':22,'local_retested_pair_directions':2,'save_metadata_passes':0,'save_content_reads':0,'save_hashes':0,'save_writes':0,'engine_runs':0,'prior_guard_invocations':0,'script_fact':v.fact(__file__)}
    report.update({'inherited_unchanged_actual_directions':20,'superseded_old_pair_directions':2,'replacement_actual_pair_directions':2,'unique_functional_direction_count':22,'functional_credit_formula':'8+14-2+2=22','Root_visual_scope':au['Root_visual_scope']})
    with out.open('x',encoding='utf-8',newline='\n') as stream:stream.write(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'passed':True,'path':str(out),'sha256':v.fact(out)['sha256'],'sources':208,'unchanged':204,'runtime':99,'old93':93,'save_metadata_passes':0}))

if __name__=='__main__':main()
