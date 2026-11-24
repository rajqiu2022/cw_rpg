"""Source-only finalpreflight for one capture. No userdata path is accessed.
Root-only; requires approved complete authorization and exact final stages.
"""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parents[3]
GAME=ROOT/'game'
HERE=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()
HELPERS={
 'res://build/city_navigation_20261101d_candidate01/mouth_visual.gd',
 'res://build/city_navigation_20261101d_candidate01/mouth_shoulder.gdshader'
}

def inside(p):
    p=Path(p).resolve();assert ROOT in p.parents,('WORKSPACE_LEAF_ONLY',str(p));return p

def res(p):
    assert isinstance(p,str) and p.startswith('res://') and '..' not in p
    q=(GAME/p[6:]).resolve();assert GAME in q.parents;return q

def fact(p):
    p=inside(p);a=p.stat();raw=p.read_bytes();b=p.stat()
    assert (a.st_size,a.st_mtime_ns)==(b.st_size,b.st_mtime_ns),'UNSTABLE_SOURCE'
    return {'exists':True,'bytes':len(raw),'utc_ticks':str(a.st_mtime_ns//100+621355968000000000),'sha256':sha(raw),'stable':True}

def load(p,h=None):
    raw=inside(p).read_bytes()
    if h:assert sha(raw)==h,('EXACT_JSON_HASH_REQUIRED',str(p))
    return json.loads(raw)

def same(actual,before):
    return all(actual[k]==before[k] for k in ('exists','bytes','utc_ticks','sha256','stable'))

def splice(source,hunks,inverse=False):
    atkey='new_offset' if inverse else 'old_offset'
    oldkey,newkey=('new','old') if inverse else ('old','new')
    cursor=0;out=[]
    for row in sorted(hunks,key=lambda r:r[atkey]):
        at=int(row[atkey]);old=row[oldkey].encode();new=row[newkey].encode()
        assert cursor<=at<=len(source) and source[at:at+len(old)]==old,('EXACT_HUNK_BYTES',at)
        out.extend((source[cursor:at],new));cursor=at+len(old)
    out.append(source[cursor:]);return b''.join(out)

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--authorization',required=True);p.add_argument('--authorization-sha256',required=True)
    p.add_argument('--capture',default=str(HERE/'capture_before_ACTUAL.json'))
    p.add_argument('--output',default=str(HERE/'source_preflight_ACTUAL.json'))
    a=p.parse_args();output=inside(a.output)
    assert output.parent==HERE and not output.exists()
    auth=load(a.authorization,a.authorization_sha256.lower())
    assert auth['schema']=='CITY_NAVIGATION_ROADMOUTHS_20261102A_FINAL_AUTHORIZATION_V1' and auth['root_approved'] is True
    cap=load(a.capture,auth['capture_sha256'])
    assert cap['schema']=='CITY_NAVIGATION_ROADMOUTHS_20261102A_FINITE_CAPTURE_V1' and cap['captured_successfully']
    assert cap['immutable134_count']==134 and cap['manifest_before_leaf_count']==96 and cap['full_backup_count']==3 and cap['save_count']==171
    assert len(cap['before_source_facts'])==cap['finite_deduplicated_source_count']==208
    prior=fact(cap['prior_guard_path']);assert same(prior,cap['prior_guard_fact']) and prior['sha256']==auth['prior_guard_sha256']
    assert same(fact(HERE/'capture_before_ROOT_ONLY.ps1'),cap['capture_script_fact'])
    assert same(fact(cap['established_guard_helper_path']),cap['established_guard_helper_fact'])
    mutable=set(cap['allowed_prospective_mutable_paths']);manifest_key=cap['current_manifest_path']
    assert mutable==HELPERS|{manifest_key} and not (set(cap['immutable134_paths'])&mutable)
    facts={k:fact(res(k)) for k in cap['before_source_facts']}
    for key,before in cap['before_source_facts'].items():
        if key not in mutable:assert same(facts[key],before),('IMMUTABLE_FINITE_SOURCE_CHANGED',key)
    backups={}
    for key,row in cap['full_backups'].items():
        value=fact(row['path']);assert same(value,row['fact']) and same(value,cap['before_source_facts'][key]);backups[key]=value
    assert set(backups)==mutable
    assert cap['approved_existing_ground_source_sha256']==auth['existing_ground_media_pins'] and len(auth['existing_ground_media_pins'])==3
    for key,h in auth['existing_ground_media_pins'].items():
        assert facts[key]['sha256']==h and same(facts[key],cap['existing_ground_source_facts'][key])
    # First exacthelperstage: currentold original985A/0B46 -> selectedsample.
    sample=auth['sample_stage']
    plan=load(res(sample['plan_path']),sample['plan_sha256'])
    hunks=load(res(sample['hunks_path']),sample['hunks_sha256'])
    load(res(sample['apply_path']),sample['apply_sha256'])
    sample_rows={r['path']:r for r in plan['targets']};sample_hunks={r['target']:r['hunks'] for r in hunks}
    assert set(sample_rows)==set(sample_hunks)==HELPERS
    original_bytes={};sample_bytes={};stage1_proofs={}
    for key in HELPERS:
        row=sample_rows[key];before=inside(cap['full_backups'][key]['path']).read_bytes();after=res(row['candidate']).read_bytes()
        assert sha(before)==row['before_sha256']==cap['before_source_facts'][key]['sha256'] and len(before)==row['before_bytes']
        assert sha(after)==row['after_sha256'] and len(after)==row['after_bytes']
        assert splice(before,sample_hunks[key])==after and splice(after,sample_hunks[key],True)==before
        original_bytes[key]=before;sample_bytes[key]=after
        stage1_proofs[key]={'before_sha256':sha(before),'sample_sha256':sha(after),'wholebyte_forward_inverse':True}
    # The promotedstage may omit an unchangedshader; omittedhelpers must equal
    # the archivedsample exactly. Root's approved aftermap always namesboth.
    final=auth['final_stage']
    final_plan=load(res(final['plan_path']),final['plan_sha256'])
    final_hunks=load(res(final['hunks_path']),final['hunks_sha256'])
    load(res(final['apply_path']),final['apply_sha256'])
    promotions={r['path']:r for r in final['targets']};promotion_hunks={r['target']:r['hunks'] for r in final_hunks}
    assert final_plan['targets']==final['targets']
    assert set(promotions)==set(promotion_hunks)==HELPERS
    assert set(auth['final_helper_afters'])==HELPERS
    stage2_proofs={}
    for key in HELPERS:
        before=sample_bytes[key];after=res(key).read_bytes()
        assert sha(after)==auth['final_helper_afters'][key]==facts[key]['sha256']
        if key in promotions:
            row=promotions[key];h=promotion_hunks.get(key,[])
            assert sha(before)==row['before_sha256'] and len(before)==row['before_bytes']
            assert sha(after)==row['after_sha256'] and len(after)==row['after_bytes']
            assert splice(before,h)==after and splice(after,h,True)==before
        else:assert after==before
        inverse_sample=splice(after,promotion_hunks[key],True)
        inverse_fresh=splice(inverse_sample,sample_hunks[key],True)
        assert inverse_sample==sample_bytes[key] and inverse_fresh==original_bytes[key]
        stage2_proofs[key]={'sample_before_sha256':sha(before),'final_after_sha256':sha(after),'fresh_before_sha256':sha(inverse_fresh),'wholebyte_forward_inverse':True,'combined_final_to_sample_to_fresh_exact':True,'no_op':after==before}
    old_manifest=load(cap['full_backups'][manifest_key]['path'],auth['manifest_before_sha256'])
    assert old_manifest['source_pins']==cap['manifest_before_source_pins'] and len(old_manifest['source_pins'])==96
    sample_manifest=load(res(sample['manifest_archive']),sample['manifest_sha256'])
    current_manifest=load(res(manifest_key),auth['manifest_after_sha256'])
    sample_expected={**old_manifest['source_pins'],**{k:sha(sample_bytes[k]) for k in HELPERS},**auth['existing_ground_media_pins']}
    final_expected={**old_manifest['source_pins'],**auth['final_helper_afters'],**auth['existing_ground_media_pins']}
    assert len(sample_expected)==len(final_expected)==auth['expected_final_leaf_count']==99
    assert sample_manifest['ready'] is True and sample_manifest['source_pins']==sample_expected
    assert current_manifest['ready'] is True and current_manifest['source_pins']==final_expected
    unchanged=[k for k,h in old_manifest['source_pins'].items() if current_manifest['source_pins'][k]==h]
    assert len(unchanged)==auth['expected_unchanged_old_leaf_count']==94
    unchanged_sample=[k for k,h in sample_manifest['source_pins'].items() if current_manifest['source_pins'].get(k)==h]
    assert len(unchanged_sample)==auth['expected_unchanged_sample_leaf_count']==97
    for key,h in final_expected.items():assert facts[key]['sha256']==h
    qa={};roles=set()
    for row in auth['qa_evidence']:
        value=fact(res(row['path']));assert value['sha256']==row['sha256'];qa[row['role']]=value;roles.add(row['role'])
        if row.get('require_passed'):assert load(res(row['path']))['passed'] is True
    assert set(auth['required_final_qa_roles'])<=roles
    baseline=next(r for r in auth['qa_evidence'] if r['role']=='baseline_remaining14')
    b=load(res(baseline['path']));assert b['actual_true_legs']==14 and b['input_events']==56
    report={'schema':'CITY_NAVIGATION_ROADMOUTHS_20261102A_SOURCE_PREFLIGHT_V1','passed':True,'capture_sha256':auth['capture_sha256'],'source_facts':facts,'finite_source_count':208,'immutable134_count':134,'unchanged_finite_source_count':205,'full_backup_facts':backups,'full_backup_count':3,'sample_manifest_archive_fact':fact(res(sample['manifest_archive'])),'stage1_helper_proofs':stage1_proofs,'stage2_helper_proofs':stage2_proofs,'old_manifest_leaf_count':96,'sample_and_final_manifest_leaf_count':99,'unchanged_old_leaf_count':94,'existing_added_media_leaf_count':3,'qa_evidence_facts':qa,'new_true_legs':14,'inherited_true_legs':8,'total_pair_true_directions':22,'old_guards_invoked':0,'save_metadata_passes':0,'save_content_reads':0,'save_hashes':0,'save_writes':0,'engine_runs':0,'old_source_writes':0,'source_preflight_script_fact':fact(__file__)}
    report['unchanged_sample_leaf_count']=len(unchanged_sample)
    report['combined_final_to_sample_to_fresh_inverse_exact']=True
    with output.open('x',encoding='utf-8',newline='\n') as stream:stream.write(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'passed':True,'path':str(output),'sha256':fact(output)['sha256'],'sources':208,'old134':134,'leaf_count':99,'unchanged_old_leaves':94,'save_metadata_passes':0}))

if __name__=='__main__':main()
