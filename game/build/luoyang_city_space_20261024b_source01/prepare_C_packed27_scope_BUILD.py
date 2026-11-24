"""Exact27 current declarations from deployed AF129, not a current crawl."""
from pathlib import Path
import json,hashlib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
p=S+'outputs/root_market_worker_facts_exact35_stage01/receipt.json';raw=(GAME/p[6:]).read_bytes();sha=lambda b:hashlib.sha256(b).hexdigest()
assert sha(raw)=='af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c'
stage=json.loads(raw)
excluded={
 'res://scripts/city/luoyang_precomputed_bundle_20261018r.gd',
 'res://scripts/city/luoyang_district_life_20261016f.gd',
 'res://scripts/city/luoyang_district_life_fade_20261016f.gd',
 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd',
 'res://scripts/field/field_walkable_controller.gd',
 'res://scripts/city/luoyang_environment_layer_20261022ap.gd',
 'res://scripts/city/luoyang_market_ground_20261020ae.gd',
 'res://data/maps/luoyang_estate_rooms_20261021am/registry.json'}
rows=[dict(target=r['target'],old_sha256=r['candidate_sha256'],old_declaration=dict(path=p,sha256=sha(raw),pointer=['targets',i,'candidate_sha256'])) for i,r in enumerate(stage['targets']) if r['target'] not in excluded]
assert len(rows)==27 and sum(r['target'].endswith('.gd') for r in rows)==13
value=dict(status='C_PACKED_FINITE_DECODER_EXACT27_PREPARATION_NOT_STAGE',ready=False,parent_stage=dict(path=p,sha256=sha(raw)),target_count=27,targets=rows,
    partition=dict(strict_apply_patch_GD=13,exact_copy_JSON=14),
    sole_behavior='C._polygon finite PackedVector2Array decoder with independent duplicate; original BASE Array/unknown fallback unchanged',
    frozen_existing_targets=sorted(excluded),also_frozen=['runtime08CA','adapter86CF','binding003EC','UI FE816','all native packets/scenes/layouts/walks','all raw authors and geometry','Field/Task/dialogue behavior','media imports'],
    dependent_code_only=['ordinary AA C byte-chain','ordinary AC AA byte-chain','Coordinator culture contract SHA','Temple binding path/SHA'],
    active_owned_members=10,changed_existing_owned=['AC','Coordinator','Temple'],prior_proof_sources=127,new_proof_sources=132,
    no_execution_membership_change=True,no_current_expected_fill=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'C_packed27_scope_PREPARATION_NOT_STAGE.json'
with out.open('xb') as stream:stream.write(b)
print(json.dumps(dict(path=S+out.name,sha256=sha(b),bytes=len(b),targets=27,GD=13,JSON=14)))
