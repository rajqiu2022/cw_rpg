"""NEW AP13->canonical-B proposal and exact22 old scope; no Stage or engine."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance24_canonical_B_dependencies/'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
stagepath=S+'outputs/root_B_only_symmetric_wire_stage01/receipt.json';stagesha='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf'
stage=json.loads(fixed(stagepath,stagesha))
priorpath=S+'performance12_B_only_dependencies/execution_successor_PROPOSAL.json';priorsha='a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283'
priorbytes=fixed(priorpath,priorsha);prior=json.loads(priorbytes)
oldrow=next(r for r in stage['targets'] if r['target']==B);old=fixed(oldrow['candidate_path'],oldrow['candidate_sha256'])
assert oldrow['candidate_sha256']=='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'
candidate=S+'performance20_canonical_keys_candidate01/Bundle_canonical_keys_wire_CANDIDATE.gd';candidatesha='9d5b9b379f5e7962d91550a95b2b9a12a35b98d7fb4402cdfa5947e7152f9e54'
new=fixed(candidate,candidatesha)
anchor='static func _symmetric_record_wire_equal(left: Variant,right: Variant) -> bool:\n'
text=new.decode();start=text.index('static func _numeric_leaf_record_wire_success(');end=text.index(anchor,start)
added=text[start:end]
assert added.startswith('static func _numeric_leaf_record_wire_success(') and 'static func _canonical_keys_record_wire_success('in added
hunks=[{'old':anchor,'new':added+anchor},
 {'old':'if _strict_record_json_equal(left,right): return true\n\treturn equal(_wire(left),_wire(right))',
  'new':'if _canonical_keys_record_wire_success(left,right): return true\n\treturn equal(_wire(left),_wire(right))'}]
forward=old
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1;forward=forward.replace(a,b,1)
assert forward==new
# The frozen authority validator walks inverse replacements in their listed order.
inverse=new
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse==old
proofpath=O+'whole_B7123_to9D5B_inverse_READY.json'
proof={'status':'DIRECT_DEPLOYED_AP13_B7123_TO_CANONICAL9D5B_WHOLE_SOURCE_BYTE_INVERSE_NOT_DEPLOYMENT',
 'parent':{'path':oldrow['candidate_path'],'sha256':sha(old)},'candidate':{'path':candidate,'sha256':sha(new)},
 'hunks':hunks,'whole_forward_and_inverse_in_authority_validator_order':True,
 'previous_strict_helper_unchanged':True,'symmetric_wrapper_only_numeric_and_StringName_domain_success_extension':True,
 'old_full_wire_fallback_DT_non_symmetric_owner_source_FIRST_FINAL_copies_unchanged':True,
 'no_intermediate_3F002_formal_edge_or_proof_adoption':True,'Stage_engine_collector_formal_calls':0}
proofbytes=js(proof)
edge={'path':B,'old_sha256':sha(old),'new_sha256':sha(new),'old_snapshot':oldrow['candidate_path'],'new_snapshot':candidate,'whole_inverse':True,'replacements':copy.deepcopy(hunks)}
assert len(prior['owned'])==10 and len(prior['source_sha256'])==69 and prior['owned'][B]['current_sha256']==sha(old)
proposal=copy.deepcopy(prior);proposal['owned'][B]['current_sha256']=sha(new);proposal['owned'][B]['edges'].append(edge)
extra={candidate:sha(new),proofpath:sha(proofbytes)}
assert not set(extra)&set(prior['source_sha256']);proposal['source_sha256'].update(extra)
restored=copy.deepcopy(proposal);restored['owned'][B]=copy.deepcopy(prior['owned'][B]);restored['source_sha256']=copy.deepcopy(prior['source_sha256'])
assert restored==prior and js(restored)==priorbytes
targets=[{'target':r['target'],'old_sha256':r['candidate_sha256'],'old_snapshot':r['candidate_path'],'kind':'GD'if r['target'].endswith('.gd')else'JSON'}for r in stage['targets']]
assert len(targets)==22 and sum(r['kind']=='GD'for r in targets)==9 and sum(r['kind']=='JSON'for r in targets)==13
excluded=['res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_parallel_source_hash_20261017k.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd','res://data/maps/luoyang_estate_rooms_20261021am/registry.json','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']
assert not set(excluded)&{r['target']for r in targets}
request={'status':'PROPOSED_EXACT22_CANONICAL_B_SOURCE_SUCCESSOR_NOT_STAGE_OR_DEPLOYMENT_AUTHORITY','target_count':22,'GD_count':9,'JSON_count':13,'actual_parent_stage':{'path':stagepath,'sha256':stagesha},'actual_parent_execution':{'path':priorpath,'sha256':priorsha},'targets':targets,
 'excluded_unchanged':excluded,'no_geometry_native_media_NPC_quest_or_gameplay_delta':True,'no_AP12_D058_old_target_values':True,'source_stage_engine_collector_calls':0}
requestpath=O+'exact22_existing_scope_PROPOSAL_NOT_APPROVED.json';requestbytes=js(request)
proposalpath=O+'execution_successor_PROPOSAL.json';proposalbytes=js(proposal)
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldrow['candidate_path'],tofile=candidate)).encode()
hand={'status':'CANONICAL_B_ONLY_ONE_CURRENT_AP13_OWNED_SUCCESSOR_PROPOSAL_NOT_ROOT_APPROVED',
 'execution_parent':{'snapshot':priorpath,'sha256':priorsha},'execution_proposal':{'path':proposalpath,'sha256':sha(proposalbytes)},
 'owned_changed_exactly1':[edge],'new_proof_pins':extra,'original_owned_members':10,'other_owned_rows_unchanged':9,'old_proof_pin_count':69,'new_proof_pin_count':71,
 'whole_execution_typed_and_serialized_byte_inverse':True,'B_whole_source_byte_inverse':True,
 'direct_B_inverse_proof':{'path':proofpath,'sha256':sha(proofbytes)},'direct_B_diff':{'path':O+'complete_vs_AP13_B7123.diff','sha256':sha(diff)},
 'scope_request':{'path':requestpath,'sha256':sha(requestbytes)},'actual_parent_stage':{'path':stagepath,'sha256':stagesha},
 'fixed_prior_owner':{'path':S+'performance15_B_only_actual_independent_review/owner_source_maps_READY.json','sha256':'5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e'},
 'current_stage_approval_and_full_old_backup_pending':True,'source_stage_engine_collector_calls':0}
files={'whole_B7123_to9D5B_inverse_READY.json':proofbytes,'complete_vs_AP13_B7123.diff':diff,'execution_successor_PROPOSAL.json':proposalbytes,'exact22_existing_scope_PROPOSAL_NOT_APPROVED.json':requestbytes,'handoff_PRODUCTION_PROPOSAL.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
