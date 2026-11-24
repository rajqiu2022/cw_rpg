"""Fixed24c declarations and future finite integration parameters, no implementation."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';C='res://build/luoyang_city_revision_20261024c_source01/';B='res://build/luoyang_city_space_20261024b_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
stage_path=C+'outputs/root_courts_scholar_exact30_stage03/receipt.json';stage_sha='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce';stage=load(stage_path,stage_sha)
old=load(C+'current24b_formal_target_declarations_READONLY.json','4b591c8043820fd4ccc0d614a33dce6b3c9a53ae28f30de6937751e9e38c7fb7')
fresh_path=S+'fresh_24e_current_observation_READONLY.json';fresh_sha='63c08eb5de773549676d6352de5772f56201c6061fe9320c4de1ef08ee312a85';fresh=load(fresh_path,fresh_sha)
parents={r['target']:dict(path=r['immutable_snapshot'],sha256=r['old_sha256'],declaration=r['declaration']) for r in old['targets']}
for i,r in enumerate(stage['targets']):parents[r['target']]=dict(path=r['candidate_path'],sha256=r['candidate_sha256'],declaration=dict(path=stage_path,sha256=stage_sha,pointer=['targets',i,'candidate_sha256']))
assert len(parents)==36 and fresh['formal30_all_exact'] and fresh['stable_capture']
e=stage['nodes']['execution_final'];authority=load(e['path'],e['sha256'])
assert len(authority['owned'])==10 and len(authority['source_sha256'])==139
DG='res://scripts/city/luoyang_district_life_geometry_20261016f.gd';DG_AUTHOR='res://data/maps/luoyang_district_life_20261016f/author.json'
assert stage['source_first'][DG]=='c3203d99ad1c5d3de86ed04ee9fdb4672606c9669f47792cd1c500d2e9f5e133'
author=load(DG_AUTHOR,stage['source_first'][DG_AUTHOR]);docks=author['districts']['ch4_s2_canal_docks']
assert len(docks['placements'])==10 and all('replaces' not in r for r in docks['placements'])
readback_path='res://build/luoyang_city_revision_20261024b_root01/ratio_readback_READY/output/result.json';readback_sha='a789e73761b3ef903759d36ca5a30b341104fe224da75830a568eef4833c680c';readback=load(readback_path,readback_sha)
native=next(r for r in readback['regions'] if r['scene_id']=='ch4_s2_canal_docks');ids=['harbour_rope_shop','harbour_quay_supply_shop']
rows=[r for r in native['layout_visuals'] if r.get('id') in ids];assert len(rows)==2
annex=[{k:r.get(k) for k in ['id','texture','world_foot_px','render_size_px','pos']} for r in rows]
codepaths=['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_docks_district08_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd']
template=dict(status='24E_SOURCE_MINIMAL_SUCCESSOR_INTERFACE_NOTREADY',ready=False,
 fixed_formal_parent=dict(stage=dict(path=stage_path,sha256=stage_sha),deployment=dict(path='res://build/luoyang_city_revision_20261024c_root01/deployment30_actual.json',sha256='bcac9111f4abd016b8eed497aa11ce03e221760870abfeb956839401afe2e291')),
 protection=dict(path=fresh_path,sha256=fresh_sha,protected=2120,extra_UI=1,save_count=15,external_save_changes_since24c=2,external_other_changes_since24c=0,rule='Protect CURRENT observed SHA/bytes/exactticks. Do not restore old saves or reuse24c zero-difference claim; this is not a functional expected-source fill.'),
 fixed_current_code_parents={p:parents[p] for p in codepaths},
 fixed_all36_latest_declared_targets=parents,
 DG_original=dict(path=DG,sha256=stage['source_first'][DG],author_path=DG_AUTHOR,author_sha256=stage['source_first'][DG_AUTHOR],Docks_placement_count=10,Docks_replacement_count=0),
 Docks_two_current_native_rows=dict(origin=dict(path=readback_path,sha256=readback_sha),native_packet=dict(path=native['packet_path'],sha256=native['packet_sha256']),rows=annex,final_consumer='Current DG10 additions contain no replacement for either native shop; unlike the Yamen official-annex correction, these two remain shop.png at the stored transforms. G/room mapping must be read before any doorway change.'),
 scholar=dict(already_formal=True,current_Field=parents['res://scripts/field/field_walkable_controller.gd'],portrait='res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png',png_sha256='ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74',accepted_actual_51180_inherited=True,new_generation=False,new_image_validation=False,DP_UI_tasks_feet_scale_frozen=True),
 authority=dict(parent=dict(path=e['path'],sha256=e['sha256']),members=10,proofs=139,C_AA_nonowned=True,approved_loop_limit=16,Temple_edges=17,Temple_explicit_historical_shortcut_must_remain=True,all_old_edges_and_source_pins_retained=True,new_edge_count='PENDING_ACTUAL_CHANGED_EXISTING_OWNED_MEMBERS_ONLY'),
 future_minimal_template=dict(
  author_delta='Only Root-approved new street density and Docks two-shop placement/scale/ground primitives; preserve current24c annex lease, hall/portal and dedicated scholar. System owns implementation.',
  behavioral_candidates='PENDING_SYSTEM_IMMUTABLE_CANDIDATES; do not fabricate new hashes/target count or include noops',
  functional_edges=['Read final render consumers before authoring. A moved/scaled visible building must retire its exact old physical/mask base and install the new source-derived base in the same bound session.','Keep original native parent full inverse before local projection. Rebuild only independently declared changed mask domains; no old875/city replay.','Source FIRST/FINAL, sameScene/layout/token leases, ordinary C/AA source layers and fixed runtime whitelist remain strict.'],
  literal_dependencies=['If C changes: exact ordinary C successor layer then AA and AC literal/source proof chain, plus exact culture C value. C/AA never acquire owned status.','If Field changes: culture Field value and existing dependent source fields. Keep the exact EBD portrait hook.','Coordinator only if culture contract SHA changes; Temple binding only actual changed existing source values and its two code literals.','If DT changes: registry five existing DT values, Estate registry/path/source triple, then only actually affected header indices.','Execution: append only changed existing-owned exact byte edges/snapshots, preserve all139; test fixed historical baseline reachability without changing16.','All new ordinary helper/proof/media go legacy/default ordinary classification, never runtime_authority by build/root prefix.','After code hashes close, derive four complete expected maps and relevant8scene/5receipt source domains only from fixed current declarations plus approved finite delta, never collector/live observations.'],
  finalizer=dict(core='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py',core_sha256='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28',parent_recipe=C+'driver_path_residual03/source_input_courts_scholar30_residual03_ROOT_REVIEW.json',parent_recipe_sha256='317b4227f09057bc30fe9436e9815523d042403a496a93d935e261be813128bb',new_scope_and_full_backup='PENDING_ROOT_AFTER_EXACT_CANDIDATES',mechanism='Exact changed-target set only, strict LF GD apply_patch plus generated JSON mechanical copy; preserve EOF. Current-enabled indices go through sole-disabled intermediate then core enable; complete byte/typed/serialized inverse.'),
  atomicity='Build finite local author/mask/media independently; combine overlapping source-literal/execution propagation into one minimal Stage after all exact candidates are fixed. Do not publish separate shared-header rounds or touch UI/DP/tasks/noop/native without a real approved change.'),
 explicitly_preserved=['24b worker four bound artifact source facts','finite PackedVector2Array decoder and original Array fallback','ENV Market five-purpose texture preload union','Root64 ordinary-vs-runtime_authority classification repair','24a hall bases/ActorLayer/portal-only shader','24c same-owner40/10 Yamen overlay and immutable native4','all existing task/reward/flag/door semantics and old failures/backups','24d world bridge is BUILD-only, never a formal source parent'],
 pending=['System approved24e author/functional candidate hashes','Independent finite changed-domain prior/actual only if geometry changes','Root exact final target backup/authorization'],
 engine_calls=0,collector_calls=0,packet_decode=0,PNG_decode=0,canonical_writes=0,Stage_calls=0)
b=(json.dumps(template,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();out=HERE/'source_successor_template_NOTREADY.json'
with out.open('xb') as f:f.write(b)
assert json.loads(out.read_bytes())==template
print(json.dumps(dict(path=S+out.name,sha256=sha(b),bytes=len(b),fixed_declared_parents=36,formal_owned=10,formal_proofs=139,engine=0)))
