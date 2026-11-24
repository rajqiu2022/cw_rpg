"""Exact existing29 scope proposal from frozen AP14 evidence, no Stage."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance32_merged_dependencies/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(fixed(path,s))
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
sp=S+'outputs/root_B_canonical_keys_stage01/receipt.json';ss='35ffd126b0ac5292c91e9ed0bd4ea97d8e7c0a4caa16ea36ddcc6ed0e587fa36';stage=read(sp,ss)
op=S+'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json';os='65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be';owner=read(op,os)
assert owner['actual_stage_receipt']=={'path':sp,'sha256':ss} and len(stage['targets'])==22
targets=[{'target':r['target'],'old_sha256':r['candidate_sha256'],'old_snapshot':r['candidate_path'],'kind':'GD'if r['target'].endswith('.gd')else'JSON'}for r in stage['targets']]
extras=[
 ('res://scripts/city/luoyang_assembled_interiors_20261016g.gd','7b1954f9b44fb8e56fc69c29d09d99a66f3730c62a73ec5af692fa475d38e6e5',S+'portal_clone_field_timing01/G_local_catalogue_READY.gd','Exact approved cached membership hunk'),
 ('res://scripts/city/luoyang_district_life_20261016f.gd','39242c343d2e4981c2773b39fd79d84a451aab923a173a099eb8fb9b290acbe2',S+'yamen_loading_perf04/District_scalar_timings_READY.gd','Unique adapter SHA literal only'),
 ('res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b',S+'finite_adapter_production08/C_consumer_READY.gd','Unique adapter SHA literal only'),
 ('res://scripts/city/luoyang_district_life_fade_20261016f.gd','55de6f3c7ca77b5c1dd756b723d32b06f0381eb43a022334bff403d70840d6f6',S+'finite_adapter_production08/Fade_consumer_READY.gd','Unique adapter SHA literal only'),
 ('res://scripts/city/luoyang_temple_assembly_20261016.gd','c345349c17307eca89ecfb05e7f5089edab704ae7d7808e0c65572071805d5e8',S+'performance05_dependencies/Temple_hash_binding_READY.gd','Temple merged189 actually pins C8C145; new binding C-only successor requires two binding literals'),
 (S+'finite_adapter_production08/finite_adapter_READY.gd','999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90',S+'finite_adapter_production08/finite_adapter_READY.gd','Root-approved exact-domain two independent copies; Root must back up this existing build target before deployment'),
 ('res://data/maps/luoyang_estate_rooms_20261021am/registry.json','040664f7a2c73087b6c47e5f4d000cb4955648dd61b830d76d2a7ce54cafd95c',S+'outputs/root_performance05_source_stage01/registry_source_successor.json','Only five AP room source_sha256 DT current3924 successors; other seven and native rows unchanged')]
for target,s,snapshot,reason in extras:
    if target in owner['core_source_sha256']:assert owner['core_source_sha256'][target]==s
    else:
        declared=[r['source_sha256'].get(target)for r in owner['scenes']if target in r['source_sha256']]
        assert declared and all(v==s for v in declared)
    # Small code/registry snapshots only. Never hash media or decode native.
    fixed(snapshot,s)
    targets.append({'target':target,'old_sha256':s,'old_snapshot':snapshot,'kind':'GD'if target.endswith('.gd')else'JSON','reason':reason})
assert len(targets)==len({r['target']for r in targets})==29
assert sum(r['kind']=='GD'for r in targets)==15 and sum(r['kind']=='JSON'for r in targets)==14
request={'status':'PROPOSED_EXACT29_MERGED_G_MEMBERSHIP_AND_FINITE_PARENT_COPIES_SOURCE_SUCCESSOR_NOT_AUTHORIZED',
 'target_count':29,'GD_count':15,'JSON_count':14,'targets':targets,
 'parent_actual_stage':{'path':sp,'sha256':ss},'fixed_independent_owner':{'path':op,'sha256':os},
 'parent_execution':{'path':S+'performance24_canonical_B_dependencies/execution_successor_PROPOSAL.json','sha256':'03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'},
 'Root29_fresh_before':{'path':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration29/guard_before.json','sha256':'c2633e5dc77bd69a7821351fa288e01e1110556fc5fd20922ce53bdf08e7ea3d'},
 'execution_plan':'OWNED10 unchanged membership; append exactly B/G/DT/Temple four edges, keep other6 complete rows and old71 proof pins. C/Fade/adapter remain direct nonowned source successors.',
 'additional_B_source_literal_contract':'Besides deferred-child hunk and unique adapter SHA literal, B.ao_fade_source_matches:498-506 pins current55DE Fade and candidate path. Its exact source-only successor must retain F359/BC295/3F2D/55DE history and admit only the new literal-only Fade; four city migration rows must match old55DE -> new with explicit candidate. No functional fade gate removal.',
 'Temple_actual_dependency':'Frozen E43B merged189 contains C8C145 and no B/G/DT/Fade/adapter entries. Only C source_delta changes; remaining188 source values preserved; new binding is NEW build source, not overwrite E43B or an additional existing target.',
 'registry_actual_dependency':'Five AP rooms declare DT3924; other seven keep older historical declarations and are not mass-rewritten. G itself is not a registry row source pin.',
 'unchanged_existing_code':['Family','ENV','Field','Router','Coordinator','runtime_contract','hash','execution_authority OWNED definition','adapter bindingDC21'],
 'single_Stage_plan':'After Root29 scope/old backups/execution approval and QA review only: reuse 8DE0 metadata core with a NEW thin29 driver. One combined Stage,15GD apply_patch+14generatedJSON exactcopy. No component-specific stage/Field. Fresh whole FIRST/FINAL remains full.',
 'source_inheritance':'AP14 actual35FF declares3009 source facts. Expected owners derive only from fixed65BE plus exact targets, explicitly new proof leaves and classified header successors; preserve original2924 declarations and9 inherited-source rule rather than crawl current collector or media.',
 'native_geometry_NAV_NPC_quest_receipt_FIRST_FINAL_unchanged':True,
 'sourceStage_engine_collector_native_decode_formal_writes':0}
assert not p(O).exists();p(O).mkdir()
out=js(request);(p(O)/'exact29_existing_scope_PROPOSAL_NOT_APPROVED.json').write_bytes(out)
print(sha(out))
