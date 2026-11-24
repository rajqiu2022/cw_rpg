"""24e fresh protection observation only. No engine, collectors or canonical writes."""
from pathlib import Path
import hashlib,json,datetime,subprocess
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/'
C='res://build/luoyang_city_revision_20261024c_root01/'
STAGE='res://build/luoyang_city_revision_20261024c_source01/outputs/root_courts_scholar_exact30_stage03/receipt.json'
UI='res://scripts/ui/dialog_box.gd';UI_SHA='fe8165682670f7bcc5689d963b456f5d9503ba7f6abece575ad4f04e82c9c337'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://') and '..' not in p
    x=(GAME/p[6:]).resolve();assert x.is_relative_to(GAME.resolve());return x
def load(p,h):
    b=res(p).read_bytes();assert sha(b)==h,(p,'FROZEN_PARENT_METADATA_REQUIRED');return json.loads(b)
def clock():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def stat(p):
    if not p.exists():return dict(exists=False)
    x=p.stat();return dict(exists=True,bytes=x.st_size,ticks=str(x.st_mtime_ns//100+621355968000000000))
def fact(p):
    a=stat(p)
    if a['exists']:
        with p.open('rb') as f:a['sha256']=hashlib.file_digest(f,'sha256').hexdigest()
    return a
def inventory():
    # Read-only process listing. Never launches, interrupts or terminates Godot.
    command="[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false); @(Get-CimInstance Win32_Process -Filter \"Name LIKE '%Godot%'\" | Select-Object ProcessId,Name,ExecutablePath,CommandLine) | ConvertTo-Json -Compress"
    p=subprocess.run(['powershell','-NoProfile','-Command',command],capture_output=True,text=True,encoding='utf-8',check=False)
    assert p.returncode==0,'READ_ONLY_PROCESS_INVENTORY_FAILED'
    v=json.loads(p.stdout.strip()) if p.stdout.strip() else []
    return v if isinstance(v,list) else [v]
def main():
    out=HERE/'fresh_24e_current_observation_READONLY.json';assert not out.exists(),'PRESERVE_FRESH_EPOCH'
    parent=load(C+'post_Field30_guard_actual.json','55e0984464daf622a277192bc2dd5091dadd06ccc66db228d739f6ae3ff7a4b1')
    dep=load(C+'deployment30_actual.json','bcac9111f4abd016b8eed497aa11ce03e221760870abfeb956839401afe2e291')
    stage=load(STAGE,'99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce')
    assert parent['passed'] is True and parent['protected_count']==len(parent['current_facts'])==2120
    assert dep['passed'] is True and dep['target_count']==len(stage['targets'])==30
    paths=[Path(r['path']).resolve() for r in parent['current_facts']];ui=res(UI)
    assert len(set(map(str,paths)))==2120 and ui not in paths
    allpaths=paths+[ui];started=clock();process_first=inventory()
    observed={str(p):fact(p) for p in allpaths}
    unstable=[str(p) for p in allpaths if any(stat(p).get(k)!=observed[str(p)].get(k) for k in ['exists','bytes','ticks'])]
    changes=[];saves={str(Path(r['path']).resolve()):r for r in parent['saves']}
    for old in parent['current_facts']:
        p=str(Path(old['path']).resolve());now=observed[p]
        if any(now.get(k)!=old.get(k) for k in ['exists','sha256','bytes','ticks']):
            changes.append(dict(path=p,kind='save_external_change' if p in saves else 'other_external_change',old={k:old.get(k) for k in ['exists','sha256','bytes','ticks']},current=now))
    targets=[]
    for r in stage['targets']:
        p=str(res(r['target']));a=observed[p]
        targets.append(dict(target=r['target'],expected_sha256=r['candidate_sha256'],immutable_snapshot=r['candidate_path'],current=a,exact_expected_sha256=a.get('sha256')==r['candidate_sha256']))
    field=next(r for r in targets if r['target']=='res://scripts/field/field_walkable_controller.gd')
    literal='npc.portrait_path = "res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"'
    ftext=res(field['immutable_snapshot']).read_text(encoding='utf8')
    assert literal in ftext and 'scene_id == &"ch4_s3_luoyang_market"' in ftext and 'luoyang_paper_scholar' in ftext
    portraits=load(C+'scholar_portrait_three_actual.json','6d520a7f4779895f5a87e12b24bf37fd7ca9e8d50baa0ab50d2c0efa998664c8')
    # Existing local acceptance, not a new pixel/image or Field test.
    scholar=dict(formal_Field_sha256=field['expected_sha256'],current_Field_exact=field['exact_expected_sha256'],exact_Market_ID_hook_present_in_fixed_Field=True,
      portrait_png='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png',png_sha256='ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74',
      prior_media_admission=dict(path=C+'scholar_portrait_three_actual.json',sha256='6d520a7f4779895f5a87e12b24bf37fd7ca9e8d50baa0ab50d2c0efa998664c8'),
      real_visible_Field_acceptance='24c Root51180: 35 checks/0, hero opening -> dedicated TextureRect -> original leave; inherited, NOT rerun',new_generation_authorized=False,PNG_decode=0,new_Field_test=0)
    current_saves=[dict(path=p,**observed[p]) for p in saves]
    process_final=inventory();finished=clock()
    v=dict(status='24E_READONLY_CURRENT_PROTECTION_OBSERVATION_NOT_FUNCTIONAL_EXPECTATION_FILL',started_utc=started,finished_utc=finished,
      parent_guard=dict(path=C+'post_Field30_guard_actual.json',sha256='55e0984464daf622a277192bc2dd5091dadd06ccc66db228d739f6ae3ff7a4b1'),
      parent_deployment=dict(path=C+'deployment30_actual.json',sha256='bcac9111f4abd016b8eed497aa11ce03e221760870abfeb956839401afe2e291'),
      stage=dict(path=STAGE,sha256='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce'),
      protected_count=2120,extra_UI_count=1,observed_count=2121,stable_capture=not unstable,changed_during_capture=unstable,
      facts=[dict(path=str(p),**observed[str(p)]) for p in paths],UI_extra=dict(path=UI,expected_sha256=UI_SHA,current=observed[str(ui)],exact_sha256=observed[str(ui)].get('sha256')==UI_SHA),
      changes_since_24c=changes,save_count=15,current_save_protection_start=current_saves,
      save_changes_since_24c=sum(r['kind']=='save_external_change' for r in changes),
      non_save_changes_since_24c=sum(r['kind']=='other_external_change' for r in changes),
      preservation='All observed current bytes/ticks become this new protection starting point only. Historical external saves/other changes are retained, never restored, and are not represented as zero change from24c.',
      formal30_targets=targets,formal30_all_exact=all(r['exact_expected_sha256'] for r in targets),scholar_confirmation=scholar,
      process_first=process_first,process_final=process_final,processes_stopped=0,
      future_source_expectations='Only derive from frozen24c declarations plus newly approved finite author/code deltas; never use these observed current hashes to admit new source behavior.',
      engine_calls=0,import_calls=0,collector_calls=0,packet_decode=0,PNG_decode=0,canonical_writes=0,save_writes=0)
    with out.open('xb') as f:f.write((json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode())
    print(json.dumps(dict(path=S+out.name,sha256=sha(out.read_bytes()),stable=not unstable,formal30_exact=v['formal30_all_exact'],protected=2120,extraUI=1,changes=len(changes),save_changes=v['save_changes_since_24c'],other_changes=v['non_save_changes_since_24c'],processes=process_final)))
if __name__=='__main__':main()
