"""Fixed four-stage declarations only; no canonical or runtime source crawl."""
from pathlib import Path
import hashlib,json
GAME=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
PREFIX='res://build/luoyang_city_revision_20261024c_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
baseline_path=PREFIX+'current24b_formal_target_declarations_READONLY.json'
raw=(GAME/baseline_path[6:]).read_bytes()
assert sha(raw)=='4b591c8043820fd4ccc0d614a33dce6b3c9a53ae28f30de6937751e9e38c7fb7'
baseline=json.loads(raw)
excluded={
 'res://scripts/city/luoyang_precomputed_bundle_20261018r.gd',
 'res://scripts/city/luoyang_district_life_fade_20261016f.gd',
 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd',
 'res://scripts/city/luoyang_environment_layer_20261022ap.gd',
 'res://scripts/city/luoyang_market_ground_20261020ae.gd',
 'res://scripts/ui/dialog_box.gd'}
rows=[r for r in baseline['targets'] if r['target'] not in excluded]
assert len(rows)==30 and sum(r['target'].endswith('.gd') for r in rows)==15
targets={r['target'] for r in rows}
owned=[
 'res://scripts/city/luoyang_district_life_20261016f.gd',
 'res://scripts/field/field_walkable_controller.gd',
 'res://scripts/city/luoyang_docks_workyard_20261019ac.gd',
 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
 'res://scripts/city/luoyang_temple_assembly_20261016.gd']
assert set(owned)<=targets
value=dict(status='24C_EXACT30_OLD_DECLARATION_SCOPE_PREPARATION_NOT_STAGE',ready=False,
 baseline=dict(path=baseline_path,sha256=sha(raw)),target_count=30,
 partition=dict(strict_GD_apply_patch=15,exact_generated_JSON_copy=15),targets=rows,
 excluded_frozen_targets=sorted(excluded),
 functional_existing_targets=['C Yamen-only safe_body lease hook and source paths','DT Yamen same-owner ground/render/mask session','Field effective mask plus exact Market scholar portrait'],
 literal_or_source_only_existing_targets=['AA exact new C layer before unchanged historical 2-row inverse','AC exact new AA layer before unchanged historical 3-row inverse','culture contract exact C/Field source values','Coordinator contract SHA','Temple existing merged194 source values and binding literals','DT5 registry values and Estate registry/source triple','existing metadata/index source and header propagation'],
 execution=dict(parent_proofs=132,active_members=10,new_members=[],changed_existing_owned=owned,
  new_snapshot_count=5,dependency_proof_snapshots=['new exact culture contract','new exact Temple binding'],
  proposed_proof_count=139,note='132 existing preserved + five real owned snapshots + two dependency snapshots; two new ordinary C/AA layer proofs belong to Docks source closure, not execution-owned membership'),
 source_domains=dict(Yamen_only='new courts runtime/binding/author/pure projection/mask/closed-prior and publication source leaves from fixed approved declarations',Market_only='exact three dedicated scholar portrait media leaves from Root6D520',Docks_only='two new layered ordinary inverse proof leaves; old historical proof leaves retained',global_inherited='existing changed code/metadata/execution sources through original declarations; no new Yamen or portrait leaf in unrelated local branches'),
 frozen=['original Yamen four native artifacts','Market25 and all other native artifacts','DG original author and global geometry','all hall/portal/room geometry and return feet','24b worker four facts','C finite Packed decoder','ENV texture union','all task/dialogue behavior and UI'],
 pending=['System final overlay actual/binding readiness and immutable hashes','Root final source/owned proposal admission','Root exact30 fresh/full old backup and preparation authorization'],
 inverse_contract='Whole typed/serialized UTF8 source-only inverse for all metadata, whole-byte code inverse, current-enabled index to sole-disabled intermediate before original core enable; no generic gate or whitelist exception',
 no_current_expected_fill=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
out=HERE/'exact30_old_scope_PREPARATION_NOT_STAGE.json'
b=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with out.open('xb') as stream:stream.write(b)
assert json.loads(out.read_bytes())==value
print(json.dumps(dict(path=PREFIX+out.name,sha256=sha(b),bytes=len(b),targets=30,GD=15,JSON=15)))
