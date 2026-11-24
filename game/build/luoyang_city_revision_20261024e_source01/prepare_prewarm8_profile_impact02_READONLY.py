"""Consumer-specific depth/conditional ENV prospect; no candidate or Stage."""
from pathlib import Path
import json,hashlib,copy,collections,functools
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower();return json.loads(b)
def at(v,p):return functools.reduce(lambda a,k:a[k],p,v)
old=load(S+'prewarm8_exact28_closure_PROSPECT_READONLY.json','1a06ffaffb7c32b56c93e8f7babb3da4a8cbce9c414c3be78fd9fe505445e156')
stage=load(old['fixed_parent_stage']['path'],old['fixed_parent_stage']['sha256'])
# Exact physical source recipe SHA, not reconstructed from displayed tool text.
recipe=HERE/'source_input_market_blocks33_session03_ROOT_REVIEW.json'
assert sha(recipe.read_bytes())=='afd712afd624d26d24320d258497f0bafba3c2979d38b2b369ab0f48f3a1ee65'
spec=json.loads(recipe.read_bytes());pins={r['id']:r for r in spec['pinned_inputs']}
T='res://scripts/city/luoyang_temple_assembly_20261016.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
e=stage['nodes']['execution_final']['value'];row=e['owned'][T]
adj=collections.defaultdict(list)
for edge in row['edges']:adj[edge['new_sha256']].append(edge['old_sha256'])
depth={row['current_sha256']:0};q=collections.deque(depth)
while q:
    n=q.popleft()
    for z in adj[n]:
        if z not in depth:depth[z]=depth[n]+1;q.append(z)
requests=[]
# The next candidate parents are actual EA657+exact3+exact2, not 24c base docs.
current={r['target']:dict(path=r['candidate_path'],sha256=r['candidate_sha256']) for r in stage['targets']}
for pin in old['subsequent_fixed_metadata_deployments']:
    for r in load(pin['path'],pin['sha256'])['targets']:current[r['target']]=r['candidate']
for node in spec['nodes']:
    fields=node.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in node.get('source_fields',[])]
    if node.get('target') in current:
        p=current[node['target']]
        if not p['path'].endswith('.json'):continue
        value=load(p['path'],p['sha256'])
        origin='fixed_current_target_parent'
    elif node['kind']=='map':
        p=pins[node['base_input']];value=load(p['path'],p['sha256']);fields.append(['source_sha256']);origin='fixed_independent_AO_map_seed'
    else:continue
    for pointer in fields:
        data=at(value,pointer)
        if T in data:requests.append(dict(consumer=node['id'],origin=origin,pointer=pointer,historical_sha256=data[T]))
for group in spec['source_groups']:
    if group['kind']!='input_dictionary':continue
    pin=pins[group['input']];v=load(pin['path'],pin['sha256']);data=at(v,group['pointer'])
    if T in data:requests.append(dict(consumer='source_group:'+group['id'],origin='fixed_input_dictionary',pointer=group['pointer'],historical_sha256=data[T]))
for r in requests:
    assert r['historical_sha256'] in depth
    r['current_shortest_depth']=depth[r['historical_sha256']];r['after_one_new_Temple_edge_shortest_depth']=depth[r['historical_sha256']]+1
    r['within_unchanged_Stage16_loop']=r['after_one_new_Temple_edge_shortest_depth']<16
assert requests and all(r['within_unchanged_Stage16_loop'] for r in requests)
report=copy.deepcopy(old)
report['status']='PREWARM8_CONSUMER_DEPTH_AND_CONDITIONAL_PROFILE29_PROSPECT_NOT_STAGE'
report['supersedes_prospect_only']=dict(path=S+'prewarm8_exact28_closure_PROSPECT_READONLY.json',sha256='1a06ffaffb7c32b56c93e8f7babb3da4a8cbce9c414c3be78fd9fe505445e156')
report['helper'].pop('geometry_or_function_changes',None);report['helper']['gameplay_geometry_validation_changes']=False
report['Temple_depth']['actual_source_guard_requests']=requests
report['Temple_depth']['all_needed_requests_within_16_after_one_edge']=True
report['Temple_depth']['shortcut_decision']='No shortcut necessary for the actual fixed parent source fields and independent AO map inputs enumerated here. Unrequested deep snapshots are not used to justify any added edge.'
report['Temple_depth']['runtime_note']='Stage Python core tests frontier nodes at depths0..15; runtime GDScript tests edge.old within16 iterations, up to depth16. This prospect uses the stricter Stage criterion; neither implementation changes.'
env=next(r for r in stage['targets'] if r['target']==ENV)
profile_pin=dict(path='res://build/luoyang_city_blocks_20261024e_system01/profile04_ENV05_whole_inverse_BUILD.json',sha256='e7306b8f16aef5afd9bb865f1f1a1f0ecf40abb3666f456d01d87a8cd008b78e')
profile=load(profile_pin['path'],profile_pin['sha256'])
report['conditional_profile_batch']=dict(only_after_Root_overview_admission=True,new_existing_target=dict(target=ENV,old_sha256=env['candidate_sha256'],immutable_old=env['candidate_path']),existing_target_count=29,partition=dict(GD=15,JSON=14),source_candidates=profile_pin,pure_profile_helper_spec_values_only=True,no_new_mask_native_geometry=True,ENV_not_owned=True,no_additional_execution_proof_snapshot_for_ENV=True,existing_metadata_and_Temple_ENV_source_value_also_update=True,purpose_helper_spec_ordinary_new_paths_only=True)
report['candidate_or_Stage_generated']=False
raw=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'prewarm8_profile29_consumer_depth_PROSPECT_READONLY.json'
with out.open('xb') as f:f.write(raw)
print(json.dumps(dict(path=S+out.name,sha256=sha(raw),actual_Temple_requests=len(requests),unique_requested_sha256=sorted({r['historical_sha256'] for r in requests}),max_after_new_edge=max(r['after_one_new_Temple_edge_shortest_depth'] for r in requests),shortcut_needed=False,conditional_targets=29)))
