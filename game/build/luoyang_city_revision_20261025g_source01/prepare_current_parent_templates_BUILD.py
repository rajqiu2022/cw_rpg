"""Only fixed current parents and a non-executable draft domain for System45."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025g_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(pin):
    raw=(GAME/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
def put(name,value):
    raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=HERE/name;assert not p.exists();p.write_bytes(raw);return dict(path=S+name,sha256=sha(raw),bytes=len(raw))
freshpin=dict(path=S+'fresh_current25g_READONLY.json',sha256='4b8b0fbf7a7577ea0119cf1a7a9500cf87844f6ca07df4488266bd8c651a4e55');fresh=load(freshpin)
assert fresh['current33_fixed_SHA_bytes_match'] is True and fresh['current_matches25f_guard'] is True
stage=load(fresh['current_stage']);assert stage['source_first']==stage['source_final']
maps={}
for ident,node in stage['nodes'].items():
    if not ident.startswith('expected_'):continue
    value=load(dict(path=node['path'],sha256=node['sha256']));assert value==node['value']
    maps[ident]=dict(path=node['path'],sha256=node['sha256'],scene_id=value['scene_id'],count=len(value['source_sha256']),original_AO_baseline_path=value['baseline_path'],original_AO_baseline_sha256=value['baseline_sha256'])
assert len(maps)==4 and [m['count'] for m in maps.values()]==[974,1352,1844,1877]
template=dict(status='25G_FIXED_CURRENT_MAP_INHERITANCE_TEMPLATE_NOT_EXECUTABLE',ready=False,blockers=['System final45 candidate/package SHA not frozen','independent finite new-domain prior/publication/import/trial and actual required evidence not yet authorized'],current_stage=fresh['current_stage'],current_deployment=fresh['current_deployment'],fresh=freshpin,parent_maps=maps,expected_future_target_deltas=None,expected_future_new_ordinary_sources_by_actual_caller=None,merge_contract=dict(start='Clone the complete pinned current map, not a live collector and not the oldest AO map.',existing_target_value='Require pinned parent value equals fixed old target SHA before replacing with the approved candidate SHA.',owned='Existing actual requested owned history still goes through original approved() at depth16; do not invent or add unused shortcut.',source_keys='Retain all old declared source/history keys and source classes. Only explicitly approved new ordinary leaves in proven caller domains; never blanket runtime_authority.',parent_model='An optional original AO mathematical equality model is evidence only, never historical permission.',independence='Expected maps must be source-derived before Field runtime; no observed scene/collector hash fill.'),current_execution=dict(path='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json',immutable='res://build/luoyang_city_revision_20261024e_source01/docks31_candidates01/execution_successor_docks_PREPARATION.json',sha256='cf1cd7376c59e8ab11c21947eaba5b10ea3a8ffe7d03182a0fbe64337d5615c6',OWNED=10,proof_leaf_count=162,depth_limit=16,old_all_edges_and_pins_keep=True,future_edges='Only actual changed existing owned code with explicit old/new snapshot and complete byte inverse, after Root approval. No member expansion.'),no_Stage_driver_or_input=True,no_collector_or_native_republication=True)
templatepin=put('current_map_inheritance_TEMPLATE_NOTREADY.json',template)
Router='res://scripts/autoload/scene_router.gd';rows=[]
for row in fresh['all33_fixed_target_checks']:
    p=row['target']
    if p==Router:continue
    old=row['fixed_expected'];rows.append(dict(target=p,old_sha256=old['sha256'],old_bytes=old['bytes'],immutable_old=old['immutable_candidate'],candidate=None,actual_change_required_before_final_scope=True))
assert len(rows)==32 and sum(r['target'].endswith('.gd') for r in rows)==17
draft=dict(status='25G_CURRENT32_IMPACT_DOMAIN_DRAFT_NOT_FINAL_SCOPE_NOT_BACKUP_AUTHORIZATION',ready=False,geometry_candidate_count_plan=dict(current_render=43,proposed_render=45,net_new=2,author_and_pure_SHA_pending=True),source_parent_template=templatepin,current_parent_deployment=fresh['current_deployment'],fresh=freshpin,conditional_existing_target_count=32,conditional_partition=dict(GD=17,JSON=15),targets=rows,unchanged_Router=dict(path=Router,sha256=next(r['fixed_expected']['sha256'] for r in fresh['all33_fixed_target_checks'] if r['target']==Router)),reason='System confirms C/DT/Field/G plus ENV scoped runtime consumers. Their exact code, ordinary C-AA-AC chain, C/Field culture declaration, Coordinator/Temple, DT five room-source values, registry/Estate triple, metadata/index dependencies predict current33 minus Router. Final package must remove any actual no-op and justify every real edge before freeze.',owned_members_not_increased=True,old_execution162_all_values_frozen_until_specific_new_real_edges_approved=True,no_shortcut_or_depth_expansion=True,backup_plan_only=dict(prefix='res://build/luoyang_city_revision_20261025g_root01/predeploy32_backup/',count_not_locked_until_final_scope=True,Root_exclusive_CreateNew_after_fixed_old_SHA_bytes_comparison=True,prior116_backups_keep=True),no_changes_allowed_to=['old native4 artifacts','original packet/B complete inverse','six room returns and external arrivals','NPC/dialogue/portrait/task state','Router/default arrival','25f five-use material provenance and source classes'],new_source_evidence_not_fabricated=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
scopepin=put('courtyard45_source_domain_DRAFT_NOTREADY.json',draft)
print(json.dumps(dict(map_template=templatepin,old_domain_draft=scopepin,targets_pending_final=32,no_Stage=True)))
