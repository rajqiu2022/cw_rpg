"""Source-only observation of a fixed whitelist. No collector or functional fill."""
from pathlib import Path
import json,hashlib,datetime,subprocess
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S24='res://build/luoyang_city_revision_20261024e_source01/'
S25='res://build/luoyang_city_revision_20261025f_source01/'
E='res://scripts/city/luoyang_environment_layer_20261022ap.gd';ROUTER='res://scripts/autoload/scene_router.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def resolve(p):
    if p.startswith('res://'):
        value=(GAME/p[6:]).resolve();assert value.is_relative_to(GAME.resolve()) and '..' not in p;return value
    return Path(p).resolve()
def load(pin):
    b=resolve(pin['path']).read_bytes();assert sha(b)==pin['sha256'];return json.loads(b)
def stat(p):
    if not p.exists():return dict(exists=False)
    s=p.stat();return dict(exists=True,bytes=s.st_size,ticks=str(s.st_mtime_ns//100+621355968000000000))
def fact(p):
    row=stat(p)
    if row['exists']:
        with p.open('rb') as f:row['sha256']=hashlib.file_digest(f,'sha256').hexdigest()
    return row
def sig(row):return {k:row.get(k) for k in ['exists','sha256','bytes','ticks']}
priorpin=dict(path=S24+'guard_docks31_after_Docks_READONLY.json',sha256='d1d20983cd281e0117284c6c0ea3800b407fa4abed3c80621b576be910e13ecf')
prior=load(priorpin);assert prior['passed'] is True and prior['observed_count']==2121 and len(prior['saves'])==15 and len(prior['backups_current'])==98 and len(prior['new_media_current'])==6
stagepin=prior['docks_stage'];deppin=prior['docks_deployment'];stage=load(stagepin);deployment=load(deppin)
assert stagepin['sha256']=='8ea2ed3e987510ace0ef772e4f683468b714e77c6648f7c086e234520f9bd826' and deppin['sha256']=='ee47ad85fadce157fb805a039f734b8fcd1d4eb05d54a6d197ab539a93c20f89'
declared={r['target']:dict(sha256=r['candidate_sha256'],bytes=resolve(r['candidate_path']).stat().st_size,immutable_candidate=r['candidate_path']) for r in stage['targets']}
assert len(declared)==31
complements={E:dict(sha256='0f223acc26a91a74a5523b87032d1487c0996730d3e8b93ac3c29aba81e5f07b',path=S24+'prewarm_profile29_candidates01/ENV_profile04_CANDIDATE.gd'),ROUTER:dict(sha256='908f2254539010557b7ebfdc1cb77f86f6a05b068d1386741268b39a9cadeb51',path=S24+'runtime_ready03/Router_READY.gd')}
for p,pin in complements.items():
    b=resolve(pin['path']).read_bytes();assert sha(b)==pin['sha256'];declared[p]=dict(sha256=pin['sha256'],bytes=len(b),immutable_candidate=pin['path'])
assert len(declared)==33 and {r['target']:r['sha256'] for r in deployment['targets']}=={r['target']:r['candidate_sha256'] for r in stage['targets']}
old={r['path']:r for r in prior['current_facts']};assert len(old)==2121
started=datetime.datetime.now(datetime.timezone.utc).isoformat();now={p:fact(Path(p)) for p in old};saves={r['path'] for r in prior['saves']};assert len(saves)==15
changed=[];save_changes=[];target_changes=[];other_changes=[];declared_checks=[]
for p,before in old.items():
    if sig(before)!=sig(now[p]):
        row=dict(path=p,before=sig(before),current=sig(now[p]),classification='PREEXISTING_SAVE_CHANGE_KEEP_LATEST' if p in saves else 'PREEXISTING_OTHER_CHANGE_NOT_AUTHORIZED_FOR_OVERWRITE')
        changed.append(row)
        if p in saves:save_changes.append(row)
        elif any(str(resolve(k))==p for k in declared):target_changes.append(row)
        else:other_changes.append(row)
for p,pin in declared.items():
    current=now[str(resolve(p))];declared_checks.append(dict(target=p,expected_from_fixed_deployment_or_immutable=pin,current=current,exact_SHA_bytes=current.get('sha256')==pin['sha256'] and current.get('bytes')==pin['bytes']))
backupfacts=[];backupchanges=[];mediafacts=[];mediachanges=[]
for rows,out,delta in [(prior['backups_current'],backupfacts,backupchanges),(prior['new_media_current'],mediafacts,mediachanges)]:
    for before in rows:
        row=dict(path=before['path'],**fact(Path(before['path'])));out.append(row)
        if sig(before)!=sig(row):delta.append(dict(path=before['path'],before=sig(before),current=sig(row)))
unstable=[p for p in now if stat(Path(p))!={k:now[p][k] for k in ['exists','bytes','ticks'] if k in now[p]}]
# Process inventory is observation only: no launch, stop, focus, editor call, or import.
ps="@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^Godot.*\\.exe$' } | ForEach-Object { [pscustomobject]@{ pid=$_.ProcessId; name=$_.Name; executable=$_.ExecutablePath; command_line=$_.CommandLine } }) | ConvertTo-Json -Depth 3 -Compress"
process_result=subprocess.run(['powershell','-NoProfile','-Command',ps],capture_output=True,text=True,check=True)
processes=json.loads(process_result.stdout) if process_result.stdout.strip() else []
if isinstance(processes,dict):processes=[processes]
spec=load(dict(path=S24+'source_input_docks31_residual03_ROOT_REVIEW.json',sha256='12a8fddcd1e6e0e8fd253c6263dd3f202f152104533525bd9ccd3b2729e04cda'))
nodes={n['id']:n for n in spec['nodes']};targetnodes={n['target']:n for n in spec['nodes'] if 'target' in n};deps={p:set() for p in targetnodes}
for p,n in targetnodes.items():
    value=stage['nodes'].get(n['id'],{}).get('value')
    if isinstance(value,dict):
        fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
        for keys in fields:
            field=value
            for key in keys:field=field[key]
            deps[p].update(field)
    for row in n.get('operations',[])+n.get('replacements',[]):
        new=row.get('new')
        if isinstance(new,dict) and '$sha' in new:
            dependency=nodes.get(new['$sha'],{}).get('target')
            if dependency:deps[p].add(dependency)
affected={E}
while True:
    expanded=affected|{p for p,edges in deps.items() if affected&edges}
    if expanded==affected:break
    affected=expanded
assert len(affected)==18 and sum(p.endswith('.gd') for p in affected)==7
T='res://scripts/city/luoyang_temple_assembly_20261016.gd'
binding=load(dict(path=S24+'docks31_candidates01/Temple_binding_docks_CANDIDATE.json',sha256='bae18c26edef19b0a04041da38437d9553ee5ab88ba593dc16fb966de257bc06'))
parent_binding=load(dict(path=binding['parent_binding_path'],sha256=binding['parent_binding_sha256']))
assert E not in binding['source_delta'] and E not in parent_binding['source_sha256'] and T not in affected
expected_targets={r['target']:r for r in stage['targets']};rows=[]
for p in sorted(affected):
    if p==E:oldpin=declared[p]
    else:
        r=expected_targets[p];oldpin=dict(sha256=r['candidate_sha256'],bytes=resolve(r['candidate_path']).stat().st_size,immutable_candidate=r['candidate_path'])
    rows.append(dict(target=p,fixed_current_parent=oldpin,reason='FUNCTIONAL_ENV_VISUAL_CANDIDATE_ONLY_PENDING_SYSTEM' if p==E else 'EXISTING_LIVE_SOURCE_HEADER_VALUE_OR_INDEX_DEPENDENCY',direct_dependencies=sorted(deps.get(p,set())&affected)))
doc=dict(status='SOURCE25F_READONLY_CURRENT_PROTECTION_OBSERVATION_NOT_FUNCTIONAL_APPROVAL',namespace=S25,namespace_was_new=True,started_utc=started,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),parent24e_postguard=priorpin,current_fixed_stage=stagepin,current_fixed_deployment=deppin,observation_captured=True,capture_stable=not unstable,observed_count=2121,original_protected_count=2120,UI_extra_count=1,save_count=15,backup_count=98,new_mask_media_count=6,current_matches24e_guard=not changed and not backupchanges and not mediachanges,all_31_plus_ENV_Router_current_SHA_bytes_match_fixed=all(r['exact_SHA_bytes'] for r in declared_checks),all_33_declared_target_checks=declared_checks,changes_since24e_guard=changed,preexisting_save_changes=save_changes,preexisting_existing_target_changes=target_changes,preexisting_other_changes=other_changes,backup_changes=backupchanges,media_changes=mediachanges,unstable_during_capture=unstable,current_facts=[dict(path=p,**v) for p,v in now.items()],current_save_protection_start=[dict(path=p,**now[p]) for p in sorted(saves)],backup_facts=backupfacts,media_facts=mediafacts,running_Godot_readonly_inventory=processes,process_observation_only=True,minimum_ENV_visual_update_plan=dict(status='PROSPECT_ONLY_NO_CANDIDATE_NO_SCOPE_FREEZE',condition='Only ENV and its Market-only ordinary helper/spec/shader visuals change; no new assets, mask, geometry, room/arrival/NPC/perf/runtime API changes.',existing_target_count=18,partition=dict(GD=7,JSON=11),targets=rows,no_Temple_binding_or_code_hardpin_for_ENV=True,Temple_source_paths_for_dynamic_consumption_not_new_code_edge=True,C_Field_DT_G_Router_contract_registry_native_unchanged=True,OWNED10_proof162_depth16_unchanged=True,helper_spec_shader_new_ordinary_leaf_changes_need_final_System_package_and_Root_approval=True,source_classes_and_finite_AP_nested_header_dependency_preserved=True,future_four_maps_increment_from_fixed_8EA2_maps_not_old_AO_promote=True,current_Map_counts=[974,1352,1844,1874],no_new_8_812578_performance_credit=True),all_observed_user_changes_preserved_no_restore=True,functional_expectations_from_fixed_sources_not_current_observation=True,collector_calls=0,Stage_calls=0,engine_calls=0,imports=0,canonical_writes=0,save_writes=0,processes_stopped=0)
raw=(json.dumps(doc,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();dest=HERE/'fresh_current25f_READONLY.json';assert not dest.exists()
with dest.open('xb') as out:out.write(raw)
print(json.dumps(dict(path=S25+dest.name,sha256=sha(raw),bytes=len(raw),observed=2121,saves=15,backups=98,media=6,source_differences=len(changed),save_differences=len(save_changes),backup_differences=len(backupchanges),media_differences=len(mediachanges),unstable=len(unstable),fixed33_match=doc['all_31_plus_ENV_Router_current_SHA_bytes_match_fixed'],ENV_prospect=18,Godot_processes=[dict(pid=r['pid'],name=r['name']) for r in processes])))
