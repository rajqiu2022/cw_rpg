"""Fixed-table impact prospect only. No candidate code, Stage, or live fill."""
from pathlib import Path
import json,hashlib,copy,collections
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;return json.loads(b)
stagepin=dict(path=S+'outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json',sha256='ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc')
stage=load(**{'p':stagepin['path'],'h':stagepin['sha256']})
rows={r['target']:dict(target=r['target'],old_sha256=r['candidate_sha256'],immutable_old=r['candidate_path']) for r in stage['targets']}
parents=[]
for p,h in [(R+'wall_tuple3_deployed_actual.json','3550aa2efa1eedc4ba97a353bb085d992ce8507a306d01923199962312d08d78'),(R+'finite_AP_header2_deployed_actual.json','d596ef3c7cd7177fc302f25aac3cdba6b7ad2772e1ec0122aaed2afa8549e799')]:
    d=load(p,h);parents.append(dict(path=p,sha256=h))
    for r in d['targets']:
        assert rows[r['target']]['old_sha256']==r['old_sha256'];rows[r['target']].update(old_sha256=r['candidate']['sha256'],immutable_old=r['candidate']['path'])
prefix='res://scripts/city/'
C=prefix+'luoyang_enclosure_v11_candidate_contract.gd';F='res://scripts/field/field_walkable_controller.gd';AA=prefix+'luoyang_docks_district08_20261019aa.gd';AC=prefix+'luoyang_docks_workyard_20261019ac.gd';CO=prefix+'luoyang_cultural_sidequests_coordinator_20261019x.gd';T=prefix+'luoyang_temple_assembly_20261016.gd'
excluded={prefix+'luoyang_district_life_20261016f.gd',prefix+'luoyang_assembled_interiors_20261016g.gd',prefix+'luoyang_environment_layer_20261022ap.gd','res://scripts/autoload/scene_router.gd','res://data/maps/luoyang_estate_rooms_20261021am/registry.json'}
assert excluded<=set(rows);wanted={p:r for p,r in rows.items() if p not in excluded};assert len(wanted)==28
for p,r in wanted.items():
    b=(GAME/r['immutable_old'][6:]).read_bytes();assert sha(b)==r['old_sha256'];r['old_bytes']=len(b)
    r['role']='literal_index_or_source_metadata'
    if p==C:r['role']='single_helper_preload_path_literal'
    elif p==F:r['role']='two_helper_load_path_literals'
    elif p==AA:r['role']='exact_ordinary_C_outer_proof_path_SHA_and_current_SHA_literals'
    elif p==AC:r['role']='exact_ordinary_AA_outer_proof_path_SHA_and_current_SHA_literals'
    elif p==CO:r['role']='sole_contract_SHA_literal'
    elif p==T:r['role']='sole_binding_path_and_SHA_literals'
assert sum(p.endswith('.gd') for p in wanted)==14 and sum(p.endswith('.json') for p in wanted)==14
oldhelper='res://build/luoyang_loading_20261024e_perf01/candidate03/gate_source_prewarm02.gd'
newhelper='res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd'
hh='d81ecdbb6e333886f50ad19aea8612791d64eee47300088521a9a7dac4b31778'
assert sha((GAME/newhelper[6:]).read_bytes())==hh
for p,n in [(C,1),(F,2)]:assert (GAME/rows[p]['immutable_old'][6:]).read_text(encoding='utf8').count(oldhelper)==n
e=stage['nodes']['execution_final']['value'];temple=e['owned'][T]
adj=collections.defaultdict(list)
for edge in temple['edges']:adj[edge['new_sha256']].append(edge['old_sha256'])
depth={temple['current_sha256']:0};q=collections.deque(depth)
while q:
    n=q.popleft()
    for x in adj[n]:
        if x not in depth:depth[x]=depth[n]+1;q.append(x)
base='3a033cc56525997ee3b7d96b87d08f19f6088accba8d35b183641ffd886f2827'
assert len(temple['edges'])==18 and depth[base]==2
proofroles=['Field_new_snapshot','AC_new_snapshot','Coordinator_new_snapshot','Temple_new_snapshot','new_C_Field_contract_literal_document','new_Temple_binding_literal_document']
report=dict(status='PREWARM8_EXACT28_IMPACT_PROSPECT_NOT_CANDIDATE_NOT_STAGE',fixed_parent_stage=stagepin,subsequent_fixed_metadata_deployments=parents,source_expected_authority='Fixed EA657 candidates + Root3550 tuple3 + D596 header2, not current hash fill.',target_count=28,partition=dict(GD=14,JSON=14),targets=list(wanted.values()),excluded_unchanged_targets=sorted(excluded),helper=dict(path=newhelper,sha256=hh,ordinary=True,existing_owned=False,geometry_or_function_changes=False,not_benchmarked=True),C_Field_only_path_occurrences={C:1,F:2},necessary_owned_existing_members=[F,AC,CO,T],owned_count_unchanged=10,existing_proof_leaves=148,old139_inherited_exact=True,proposed_new_execution_proof_roles=proofroles,proposed_execution_proof_count_if_only_six=154,ordinary_C_AA_proof_documents=2,ordinary_documents_not_execution_members=True,Temple_depth=dict(existing_edges=18,current_sha256=temple['current_sha256'],core_iteration_limit_unchanged=16,core_approved_depths='0 through15 inclusive',required_fixed_BASE=dict(sha256=base,current_depth=2,after_one_real_edge_depth=3),historical_deep=[dict(sha256=h,current_depth=d,after_one_real_edge_depth=d+1,currently_approved_by_depth=d<16) for h,d in depth.items() if d>=15],no_shortcut_implemented=True,shortcut_decision='Required BASE remains reachable. D9CD historical depth15 would become16; only if preserving approval of this specific old snapshot is required, propose exact D9CD-to-currentA4E4 composite byte edge using existing fixed snapshots, retaining every old edge/proof. Requires explicit Root approval first; no depth expansion.'),source_key_policy_proposal=dict(retain_old03DEC_as_declared_history=True,add_exact_D81EC_ordinary_leaf=True,no_runtime_authority_classification=True,Estate_requires_Root_single_new_ordinary_leaf_exception=True,all_4city_and_Quarter_Estate_Temple_source_consumers=True,Docks_only_new_C_AA_proof_leaves=2,no_new_room_publication_or_registry_values=True,all_2_wall_tuple_and_AP_parent_manifest_edges_inherited=True),no_new_map_count_assertion='Pending exact approved candidate sources; do not substitute anticipated counts for source tables.',no_new_code_generated=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
raw=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'prewarm8_exact28_closure_PROSPECT_READONLY.json'
with out.open('xb') as f:f.write(raw)
print(json.dumps(dict(path=S+out.name,sha256=sha(raw),targets=28,GD=14,JSON=14,execution_new_proof_roles=6,Stage_calls=0)))
