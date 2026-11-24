"""Finite source-only final preflight. Never accesses registered userdata paths.
Root executes via final_guard_ROOT_ONLY.ps1; all output is exclusive new evidence.
"""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
GAME=ROOT/'game'
sha=lambda b:hashlib.sha256(b).hexdigest()

def workspace(p):
    p=Path(p).resolve()
    assert ROOT==p or ROOT in p.parents,('WORKSPACE_ONLY',str(p))
    return p

def res(p):
    assert p.startswith('res://') and '..' not in p
    path=(GAME/p[6:]).resolve()
    assert GAME in path.parents
    return path

def fact(p):
    p=workspace(p);first=p.stat();b=p.read_bytes();last=p.stat()
    assert (first.st_size,first.st_mtime_ns)==(last.st_size,last.st_mtime_ns),'UNSTABLE_SOURCE'
    return {'exists':True,'bytes':len(b),'utc_ticks':str(first.st_mtime_ns//100+621355968000000000),'sha256':sha(b),'stable':True}

def load(p,expected=None):
    p=workspace(p);b=p.read_bytes()
    if expected:assert sha(b)==expected,('EXACT_JSON_HASH',str(p),sha(b),expected)
    return json.loads(b)

def exact(p,expected):
    actual=fact(p)
    for key in ('bytes','utc_ticks','sha256','stable'):
        assert actual[key]==expected[key],('BACKUP_OR_CAPTURE_CHANGED',str(p),key,actual[key],expected[key])
    return actual

def splice(source,hunks,inverse=False):
    offset_key='new_offset' if inverse else 'old_offset'
    old_key,new_key=('new','old') if inverse else ('old','new')
    result=[];cursor=0
    for h in sorted(hunks,key=lambda x:x[offset_key]):
        at=int(h[offset_key]);old=h[old_key].encode('utf-8');new=h[new_key].encode('utf-8')
        assert cursor<=at<=len(source) and source[at:at+len(old)]==old,('EXACT_HUNK_BYTES',at)
        result.extend((source[cursor:at],new));cursor=at+len(old)
    result.append(source[cursor:]);return b''.join(result)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--authorization',required=True)
    parser.add_argument('--authorization-sha256',required=True)
    parser.add_argument('--capture',default=str(HERE/'capture_targets_ACTUAL.json'))
    parser.add_argument('--output',default=str(HERE/'source_preflight_ACTUAL.json'))
    args=parser.parse_args()
    output=workspace(args.output)
    assert output.parent==HERE and not output.exists()
    auth=load(args.authorization,args.authorization_sha256.lower())
    assert auth['schema']=='CITY_NAVIGATION_20261101D_STAGE2_AUTHORIZATION_V1' and auth['root_approved'] is True
    cap=load(args.capture,auth['supplement02_capture_sha256'])
    assert cap['schema']=='CITY_NAVIGATION_20261101D_FRESH21_SUPPLEMENT02_V1' and cap['captured_successfully'] and cap['target_count']==21
    assert cap['intersects_original113']==cap['intersects_frozen96']==0 and cap['intersects_quarter01']==2
    before=load(cap['original_capture_path'],auth['original_capture_sha256'])
    quarter=load(cap['quarter01_capture_path'],auth['quarter01_capture_sha256'])
    assert before['source_count']==113 and before['save_count']==171
    closure=load(cap['closure_path'],auth['closure_sha256'])
    proof=load(cap['hunks_path'],auth['hunks_sha256'])
    applied=load(GAME/'build/luoyang_navigation_docks_20261101d_successor02/apply_ACTUAL.json',auth['apply_receipt_sha256'])
    assert len(closure['actual_targets'])==len(proof)==len(auth['old_target_deltas'])==21
    actual_set={r['res_path'] for r in closure['actual_targets']}
    approved={r['path']:r for r in auth['old_target_deltas']}
    assert set(approved)==actual_set==set(cap['before_facts'])==set(cap['full_backups'])
    proofs={r['target']:r for r in proof};facts={};backups={};inverse_proofs={}
    for row in closure['actual_targets']:
        key=row['res_path'];allow=approved[key]
        for name in ('before_sha256','before_bytes','after_sha256','after_bytes'):
            assert allow[name]==row[name]
        assert key not in before['before_facts']
        backup=cap['full_backups'][key];backups[key]=exact(backup['path'],backup['fact'])
        assert backup['fact']==cap['before_facts'][key]
        assert backups[key]['sha256']==row['before_sha256'] and backups[key]['bytes']==row['before_bytes']
        after=fact(res(key));facts[key]=after
        assert after['sha256']==row['after_sha256'] and after['bytes']==row['after_bytes']
        a=workspace(backup['path']).read_bytes();b=res(key).read_bytes()
        h=proofs['game/'+key[6:]]['hunks']
        assert splice(a,h)==b and splice(b,h,True)==a,('WHOLE_BYTE_DUAL_INVERSE',key)
        inverse_proofs[key]={'wholebyte_forward_inverse':True,'hunk_count':len(h),'before_sha256':sha(a),'after_sha256':sha(b)}
    # Quarter stage1 has a separate originalbefore; stage2before is its after.
    q_receipt=load(GAME/'build/city_navigation_20261101d_quarter_pins01/exact_successors_READY.json',auth['quarter01_receipt_sha256'])
    chains={};quarter_backup_facts={}
    for row in q_receipt['targets']:
        key=row['res_path'];assert key in approved
        backup=quarter['full_backups'][key];quarter_backup_facts[key]=exact(backup['path'],backup['fact'])
        a=workspace(backup['path']).read_bytes();b=workspace(cap['full_backups'][key]['path']).read_bytes()
        assert sha(a)==row['before_sha256'] and sha(b)==row['after_sha256']==approved[key]['before_sha256']
        h=[{'old_offset':v['byte_offset'],'new_offset':v['byte_offset'],'old':v['old'],'new':v['new']} for v in row['hunks']]
        assert splice(a,h)==b and splice(b,h,True)==a
        chains[key]={'stage1_before_sha256':sha(a),'stage1_after_stage2_before_sha256':sha(b),'stage2_after_sha256':approved[key]['after_sha256'],'both_stage_wholebyte_dual_inverse':True}
    assert len(chains)==2
    # The96baseline is archived, not reset. Exactly the same Art01key changes.
    old_manifest_path=workspace(ROOT/auth['candidate_manifest_before_backup'])
    old_manifest=load(old_manifest_path,auth['candidate_manifest_before_sha256'])
    manifest_path=workspace(cap['candidate_manifest_path'])
    new_manifest=load(manifest_path,auth['candidate_manifest_after_sha256'])
    old_pins=old_manifest['source_pins'];new_pins=new_manifest['source_pins']
    assert old_manifest['ready'] is True and new_manifest['ready'] is True
    assert len(old_pins)==len(new_pins)==auth['candidate_leaf_count']==96 and set(old_pins)==set(new_pins)
    changed={k:(old_pins[k],new_pins[k]) for k in old_pins if old_pins[k]!=new_pins[k]}
    art=auth['art_samepath_change'];assert changed=={art['path']:(art['before_sha256'],art['after_sha256'])}
    assert auth['candidate_manifest_before_sha256']==cap['candidate_manifest_fact']['sha256']=='64b80a6d4c930aec98fb214084ba6dd838cebfa5ff13d498c88c6999262c21e4'
    art_proof=load(ROOT/art['proof'])
    assert art_proof['canonical_path']==art['path'] and art_proof['before_sha256']==art['before_sha256'] and art_proof['after_sha256']==art['after_sha256']
    a=workspace(ROOT/art_proof['before_backup']).read_bytes();b=res(art['path']).read_bytes()
    assert sha(a)==art['before_sha256'] and sha(b)==art['after_sha256']
    h=[{k:art_proof[k] for k in ('old_offset','new_offset','old','new')}]
    assert h[0]['old']=='_quad.z_as_relative=false;_quad.z_index=int(floor(FRONT/8.0));' and h[0]['new']=='_quad.z_as_relative=true;_quad.z_index=int(floor(FRONT/8.0));'
    assert splice(a,h)==b and splice(b,h,True)==a
    # Root's original final will hash the96afterleaves; keep this explicit3pool.
    new_facts={}
    assert closure['new_runtime_sources']==auth['new_runtime_sources'] and len(auth['new_runtime_sources'])==3
    for key,expected in auth['new_runtime_sources'].items():
        value=exact(res(key),cap['new_runtime_source_facts'][key]);assert value['sha256']==expected;new_facts[key]=value
    for key,value in cap['original_guard_file_facts'].items():
        exact(res(key),value)
    exact(HERE/'capture_targets_ROOT_ONLY.ps1',cap['capture_script_fact'])
    # QA files are only explicitly named Root evidence, never an inventory scan.
    qa={}
    for row in auth.get('qa_evidence',[]):
        value=fact(res(row['path']));assert value['sha256']==row['sha256'];qa[row['path']]=value
    report={'schema':'CITY_NAVIGATION_20261101D_SOURCE_PREFLIGHT_STAGE2_V1','passed':True,'authorization_sha256':args.authorization_sha256.lower(),'original_capture_path':cap['original_capture_path'],'original_capture_sha256':auth['original_capture_sha256'],'source_after_facts':facts,'source_backup_facts':backups,'source_count':21,'wholebyte_inverse_proofs':inverse_proofs,'quarter_two_stage_chains':chains,'quarter_original_backup_facts':quarter_backup_facts,'new_runtime_source_facts':new_facts,'new_runtime_source_count':3,'candidate_manifest_before_backup_fact':fact(old_manifest_path),'candidate_manifest_after_fact':fact(manifest_path),'candidate_leaf_count':96,'candidate_exact_one_samekey_leaf_delta':changed,'art_singleline_dual_inverse':True,'art_before_backup_fact':fact(ROOT/art_proof['before_backup']),'qa_evidence_facts':qa,'original113_immutable_scope_preserved':True,'quarter01_final_invocations':0,'save_metadata_passes':0,'save_content_reads':0,'save_hashes':0,'save_writes':0,'engine_runs':0,'old_source_writes':0,'source_preflight_script_fact':fact(__file__),'verified_backup_count_excluding_original_project':25}
    with output.open('x',encoding='utf-8',newline='\n') as stream:stream.write(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'passed':True,'path':str(output),'sha256':fact(output)['sha256'],'canonical_targets':21,'two_stage_quarter':2,'new_runtime_leaves':3,'samekey_art_leaf_delta':1,'save_metadata_passes':0}))

if __name__=='__main__':main()
