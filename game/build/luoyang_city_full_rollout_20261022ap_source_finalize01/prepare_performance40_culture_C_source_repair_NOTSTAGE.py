"""AP15 culture C-only pin repair proposal. No Stage/engine/formal writes."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance40_culture_C_source_repair/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(path,s):return json.loads(fixed(path,s))
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def ref(path,s):return{'path':path,'sha256':s}
def apply(raw,hs):
    out=raw
    for h in hs:
        a,b=h['old'].encode(),h['new'].encode();assert out.count(a)==1;out=out.replace(a,b,1)
    back=out
    for h in hs:
        a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
    assert back==raw
    return out
def literal(a,b):return{'old':a,'new':b}
stagep=S+'outputs/root_merged_G_parentcopy_DT_source_stage02/receipt.json';stages='eb875d3aeed4c750d907cacfe8c5b12c93750d8bddc84d63040a25295f082f6f';stage=read(stagep,stages);targets={r['target']:r for r in stage['targets']}
ownerp=S+'performance39_merged_EOF_actual_independent_review/owner_source_maps_READY.json';owners='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c';owner=read(ownerp,owners)
assert owner['actual_stage_receipt']==ref(stagep,stages)
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';exerow=targets[EXE];parentbytes=fixed(exerow['candidate_path'],exerow['candidate_sha256']);parent=json.loads(parentbytes)
assert exerow['candidate_sha256']=='025eff4adb4bf396c5480539316d8efac36c0b435598b6f85b9ed152e4b1330c'and len(parent['owned'])==10 and len(parent['source_sha256'])==80
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';oldC='8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b';newC=targets[C]['candidate_sha256'];assert newC=='b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';contractold=stage['nodes']['runtime_contract_final'];oldcontract=fixed(contractold['path'],contractold['sha256']);assert contractold['sha256']=='7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e'
newcontract=apply(oldcontract,[literal(oldC,newC)]);contract=json.loads(oldcontract);nextcontract=json.loads(newcontract)
assert len(contract['source_sha256'])==26 and contract['source_sha256'][C]==oldC
inverse=copy.deepcopy(nextcontract);inverse['source_sha256'][C]=oldC;assert same(inverse,contract)
# Cross-check declared contract edges against fixed AP15 Stage target changes,
# not by rehashing26 media/data/code leaves or invoking runtime readiness.
assert set(contract['source_sha256'])&set(targets)=={C}
contractp=O+'runtime_contract_C_literal_READY.json';contractsha=sha(newcontract)
COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';coordrow=parent['owned'][COORD];coordoldp=coordrow['edges'][-1]['new_snapshot'];coordolds=coordrow['current_sha256'];oldcoord=fixed(coordoldp,coordolds)
coordh=[literal('const CONTRACT_SHA := "'+contractold['sha256']+'"','const CONTRACT_SHA := "'+contractsha+'"')];newcoord=apply(oldcoord,coordh);coordp=O+'Coordinator_C_contract_CANDIDATE.gd';coordsha=sha(newcoord)
T='res://scripts/city/luoyang_temple_assembly_20261016.gd';templerow=targets[T];oldtemple=fixed(templerow['candidate_path'],templerow['candidate_sha256'])
bindp=S+'performance33_merged_code_dependencies/temple_binding_C_literal_READY.json';binds='a5fadbd1466eafa84c0d3a78e96f02a609802af35d2b17848cb9bfb1744b5c9c';oldbind=fixed(bindp,binds);binding=json.loads(oldbind)
assert binding['source_delta'][COORD]==coordolds and binding['source_delta'][CONTRACT]==contractold['sha256']
bindh=[literal(coordolds,coordsha),literal(contractold['sha256'],contractsha)];newbind=apply(oldbind,bindh);newbindobj=json.loads(newbind)
back=copy.deepcopy(newbindobj);back['source_delta'][COORD]=coordolds;back['source_delta'][CONTRACT]=contractold['sha256'];assert same(back,binding)
base=read(binding['parent_binding_path'],binding['parent_binding_sha256']);merged=copy.deepcopy(base['source_sha256']);merged.update(binding['source_delta']);mergednew=copy.deepcopy(base['source_sha256']);mergednew.update(newbindobj['source_delta'])
assert len(merged)==len(mergednew)==189 and set(k for k in merged if merged[k]!=mergednew[k])=={COORD,CONTRACT}
newbindp=O+'temple_binding_Culture_literals_READY.json';newbindsha=sha(newbind)
th=[literal('const BIND_PATH="'+bindp+'"','const BIND_PATH="'+newbindp+'"'),literal('const BIND_SHA="'+binds+'"','const BIND_SHA="'+newbindsha+'"')]
newtemple=apply(oldtemple,th);templep=O+'Temple_Culture_binding_CANDIDATE.gd';templesha=sha(newtemple)
records={
 'runtime_contract':{'target':CONTRACT,'parent':ref(contractold['path'],contractold['sha256']),'candidate':ref(contractp,contractsha),'hunks':[literal(oldC,newC)],'whole_typed_inverse_one_C_source_value':True},
 'Coordinator':{'target':COORD,'parent':ref(coordoldp,coordolds),'candidate':ref(coordp,coordsha),'hunks':coordh},
 'temple_binding':{'parent':ref(bindp,binds),'candidate':ref(newbindp,newbindsha),'hunks':bindh,'whole_typed_inverse_two_values_187others_unchanged':True},
 'Temple':{'target':T,'parent':ref(templerow['candidate_path'],templerow['candidate_sha256']),'candidate':ref(templep,templesha),'hunks':th}}
proofp=O+'whole_culture_code_data_inverse_READY.json'
proof={'status':'AP15_EXACT_CULTURE_C_PIN_AND_LITERAL_DEPENDENCY_REPAIR_PROPOSAL_NOT_DEPLOYED','records':records,'all_forward_and_listed_inverse_bytes_equal':True,'runtime_contract_source_fields_only_C_changed':True,'contract_other25_source_values_and_all_story_NPC_pickup_flags_rewards_unchanged':True,'Temple_merged189_only_Coordinator_and_contract_changed':True,'other187_values_same':True,
 'cause':'Formal C changed8C145->B14A underAP15; frozen culture contract7EE and CoordinatorD590 kept old C pin. readiness53-57 correctly refused at Field cultural projection; no readiness/freshness gate is removed.',
 'contract_AP15_changed_target_intersection_only_C':True,'no_new_media_hash_or_runtime_collector_observation':True,'engine_Stage_collector_native_decode_formal_calls':0}
proofbytes=js(proof)
proposal=copy.deepcopy(parent);edges=[]
for name in ['Coordinator','Temple']:
    r=records[name];target=r['target'];assert parent['owned'][target]['current_sha256']==r['parent']['sha256']
    edge={'path':target,'old_sha256':r['parent']['sha256'],'new_sha256':r['candidate']['sha256'],'old_snapshot':r['parent']['path'],'new_snapshot':r['candidate']['path'],'whole_inverse':True,'replacements':copy.deepcopy(r['hunks'])}
    proposal['owned'][target]['current_sha256']=r['candidate']['sha256'];proposal['owned'][target]['edges'].append(edge);edges.append(edge)
pins={r['candidate']['path']:r['candidate']['sha256']for r in records.values()};pins[proofp]=sha(proofbytes)
assert len(pins)==5 and not(set(pins)&set(parent['source_sha256']));proposal['source_sha256'].update(pins)
back=copy.deepcopy(proposal)
for edge in edges:back['owned'][edge['path']]=copy.deepcopy(parent['owned'][edge['path']])
for path in pins:back['source_sha256'].pop(path)
assert same(back,parent)and js(back)==parentbytes
excluded={
 'res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_district_life_20261016f.gd',C,
 'res://scripts/city/luoyang_district_life_fade_20261016f.gd',S+'finite_adapter_production08/finite_adapter_READY.gd','res://data/maps/luoyang_estate_rooms_20261021am/registry.json'}
assert len(excluded)==7 and excluded<=set(targets)
scope=[{'target':r['target'],'old_sha256':r['candidate_sha256'],'old_snapshot':r['candidate_path'],'kind':'GD'if r['target'].endswith('.gd')else'JSON'}for r in stage['targets']if r['target']not in excluded]
scope.extend([{'target':COORD,'old_sha256':coordolds,'old_snapshot':coordoldp,'kind':'GD'},{'target':CONTRACT,'old_sha256':contractold['sha256'],'old_snapshot':contractold['path'],'kind':'JSON'}])
assert len(scope)==24 and len({r['target']for r in scope})==24 and sum(r['kind']=='GD'for r in scope)==10 and sum(r['kind']=='JSON'for r in scope)==14
scopeobj={'status':'PROPOSED_EXACT24_AP15_CULTURE_C_PIN_SOURCE_REPAIR_NOT_AUTHORIZED','targets':scope,'target_count':24,'GD_count':10,'JSON_count':14,'actual_parent_stage':ref(stagep,stages),'fixed_prior_owner':ref(ownerp,owners),'excluded_unchanged_exact7':sorted(excluded),
 'direct_runtime_literal_targets_exact3':[CONTRACT,COORD,T],'necessary_generated_authority_and_header_targets':21,
 'new_build_binding_not_existing_target':ref(newbindp,newbindsha),'one_Stage_plan':'Reuse exact8DE0 metadata validators and existing24 necessary targets only. Runtime contract metadata must verify source-only C operation/wholetyped inverse then match exact literal candidate bytes; no generic data passthrough or formatting relaxation. Full FIRST/FINAL, fourT authority classification, native/registry/NAV/portal/quest/NPC/rewards unchanged.',
 'Root_old_backups_freshguard_and_final_execution_approval_pending':True,'engine_Stage_collector_formal_calls':0}
ep=O+'execution_successor_PROPOSAL.json';eb=js(proposal);scopep=O+'exact24_existing_scope_PROPOSAL_NOT_APPROVED.json';scopeb=js(scopeobj)
hand={'status':'AP15_CULTURE_SOURCE_REPAIR_ONLY_C_VALUE_LITERALS_AND_EXECUTION_PROPOSAL_NOT_STAGED','execution_parent':ref(exerow['candidate_path'],exerow['candidate_sha256']),'execution_proposal':ref(ep,sha(eb)),'owned_changed_exactly2':edges,'old_owned10_members_unchanged':True,'other8_owned_rows_whole_same':True,'old80_proof_pins_unchanged':True,'new_exact5_proof_pins':pins,'new_total85_proof_pins':True,'whole_execution_strict_typed_and_UTF8_serialized_byte_inverse':True,'inverse_proof':ref(proofp,sha(proofbytes)),'scope_request':ref(scopep,sha(scopeb)),'actual_parent_stage':ref(stagep,stages),'fixed_prior_owner':ref(ownerp,owners),
 'dependency_graph':[CONTRACT+' [C8C->B14 only] -> '+COORD+' [CONTRACT_SHA literal]',COORD+' + '+CONTRACT+' -> NEW Temple binding [2/189 source values] -> '+T+' [2binding literals]',COORD+' + '+T+' -> existing execution authority [only2owned append] -> required metadata/index headers [no native changes]'],
 'all_gameplay_NPC_dialogue_reward_logic_and_validation_retained':True,'no_runtime_C_G_B_DT_Fade_adapter_or_registry_change':True,'engine_Stage_collector_native_decode_formal_calls':0}
files={'runtime_contract_C_literal_READY.json':newcontract,'Coordinator_C_contract_CANDIDATE.gd':newcoord,'temple_binding_Culture_literals_READY.json':newbind,'Temple_Culture_binding_CANDIDATE.gd':newtemple,'whole_culture_code_data_inverse_READY.json':proofbytes,'execution_successor_PROPOSAL.json':eb,'exact24_existing_scope_PROPOSAL_NOT_APPROVED.json':scopeb,'handoff_EXECUTION_AND_SCOPE_PROPOSAL.json':js(hand)}
for name,r in records.items():files[name+'_complete.diff']=''.join(difflib.unified_diff(fixed(r['parent']['path'],r['parent']['sha256']).decode().splitlines(True),files[r['candidate']['path'].removeprefix(O)].decode().splitlines(True),fromfile=r['parent']['path'],tofile=r['candidate']['path'])).encode()
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
