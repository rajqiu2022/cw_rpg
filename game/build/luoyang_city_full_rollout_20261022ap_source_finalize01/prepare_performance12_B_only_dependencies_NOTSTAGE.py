"""NEW B-only one-edge approval proposal and exact22 scope; no Stage or engine."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance12_B_only_dependencies/'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EXCLUDED={'res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_parallel_source_hash_20261017k.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd','res://data/maps/luoyang_estate_rooms_20261021am/registry.json'}
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
stagepath=S+'outputs/root_performance05_source_stage01/receipt.json';stagesha='d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282'
stage=json.loads(fixed(stagepath,stagesha))
priorpath=S+'performance05_dependencies/execution_successor_PROPOSAL.json';priorsha='428a3484e0a995803d95677dbd36f545313c622142605fce292ffd493b6bea03'
priorbytes=fixed(priorpath,priorsha);prior=json.loads(priorbytes)
proofpath=S+'performance11_symmetric_wire_candidate01/whole_byte_inverse_and_design_READY.json';proofsha='2d84e87ef942a910f07aa5c416bf01bbbda9e74097af1a9674d6ede977ebe0e4'
proof=json.loads(fixed(proofpath,proofsha))
oldrow=next(r for r in stage['targets'] if r['target']==B)
oldbytes=fixed(oldrow['candidate_path'],oldrow['candidate_sha256'])
newbytes=fixed(proof['candidate']['path'],proof['candidate']['sha256'])
assert oldrow['candidate_sha256']==proof['parent']['sha256']=='77dfc4987f21fa280c526cf62cb6c94316a40c4236fb1005761408859a0b8c16'
forward=oldbytes
for h in proof['hunks']:
    a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1;forward=forward.replace(a,b,1)
assert forward==newbytes
back=newbytes
for h in reversed(proof['hunks']):
    a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
assert back==oldbytes
edge={'path':B,'old_sha256':sha(oldbytes),'new_sha256':sha(newbytes),'old_snapshot':oldrow['candidate_path'],'new_snapshot':proof['candidate']['path'],'whole_inverse':True,'replacements':copy.deepcopy(proof['hunks'])}
proposal=copy.deepcopy(prior)
assert len(prior['owned'])==10 and len(prior['source_sha256'])==67
proposal['owned'][B]['current_sha256']=sha(newbytes);proposal['owned'][B]['edges'].append(edge)
extra={proof['candidate']['path']:sha(newbytes),proofpath:proofsha}
assert not set(extra)&set(prior['source_sha256'])
proposal['source_sha256'].update(extra)
inverse=copy.deepcopy(proposal);inverse['owned'][B]=copy.deepcopy(prior['owned'][B]);inverse['source_sha256']=copy.deepcopy(prior['source_sha256'])
assert inverse==prior and js(inverse)==priorbytes
targets=[{'target':r['target'],'old_sha256':r['candidate_sha256'],'old_snapshot':r['candidate_path'],'kind':'GD' if r['target'].endswith('.gd') else 'JSON'} for r in stage['targets'] if r['target'] not in EXCLUDED]
assert len(targets)==22 and sum(r['kind']=='GD' for r in targets)==9 and sum(r['kind']=='JSON' for r in targets)==13
request={'status':'PROPOSED_EXACT22_B_ONLY_SOURCE_SUCCESSOR_NOT_STAGE_OR_DEPLOYMENT_AUTHORIZATION','target_count':22,'GD_count':9,'JSON_count':13,'actual_parent_stage':{'path':stagepath,'sha256':stagesha},'targets':targets,'excluded_from_prior26':sorted(EXCLUDED),'unchanged_DT_hash_Temple_registry_Family_ENV_G_Field_Coordinator_contract':True,'no_geometry_native_media_or_gameplay_delta':True,'source_stage_engine_collector_calls':0}
proposalpath=O+'execution_successor_PROPOSAL.json';proposalbytes=js(proposal)
hand={'status':'B_ONLY_ONE_EXISTING_OWNED_SUCCESSOR_PROPOSAL_NOT_ROOT_APPROVED','execution_parent':{'snapshot':priorpath,'sha256':priorsha},'execution_proposal':{'path':proposalpath,'sha256':sha(proposalbytes)},'owned_changed_exactly1':[edge],'new_proof_pins':extra,'original_owned_members':10,'other_owned_rows_unchanged':9,'old_proof_pin_count':67,'new_proof_pin_count':69,'whole_execution_typed_and_serialized_byte_inverse':True,'B_whole_source_byte_inverse':True,'scope_request':{'path':O+'exact22_existing_scope_PROPOSAL_NOT_APPROVED.json','sha256':sha(js(request))},'source_stage_engine_collector_calls':0}
files={'execution_successor_PROPOSAL.json':proposalbytes,'exact22_existing_scope_PROPOSAL_NOT_APPROVED.json':js(request),'handoff_PRODUCTION_PROPOSAL.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({k:sha(v) for k,v in files.items()},indent=2))
