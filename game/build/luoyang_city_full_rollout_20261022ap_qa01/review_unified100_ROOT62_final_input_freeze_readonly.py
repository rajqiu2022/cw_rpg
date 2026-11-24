"""Small readiness delta only; never import/construct or execute a Stage."""
import copy,hashlib,json,pathlib
GAME=pathlib.Path(__file__).resolve().parents[2]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
R=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration62'
def raw(p):return p.read_bytes()
def sha(p):return hashlib.sha256(raw(p)).hexdigest()
def obj(p):return json.loads(raw(p))
def need(v,label):
    if not v:raise AssertionError(label)
def strict(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return list(a)==list(b)and all(strict(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(strict(x,y)for x,y in zip(a,b))
    return a==b
oldpath=S/'performance100_unified_life_garden_scholar_BUILD/source_input_NOTREADY.json'
newpath=R/'source_input100_READY.json'
authpath=R/'source_stage_preparation_authorization.json'
driver=S/'stage_unified100_BUILD.py'
need(sha(oldpath)=='573b9e6640260169f70f9c2e89d066005ce6cacba812068a7ab8ebe7c52b57b3','PARENT_FALSE573B')
need(sha(newpath)=='f432b6fc25a06e8be2b510b9ef2523972aaf6da2ef5e824b987a3aa8ca257fcc','FINAL_INPUT_F432')
need(sha(authpath)=='b96fc2b4f061e3d1994b4f22ad2e5117f7ba6512ebb8d6821202fc51b854f98e','ROOT_AUTH_B96F')
need(sha(driver)=='9291aac737526bfcbddeace9e3516e4ea6c708750f9c9c4c025887881a93e84a','DRIVER_UNCHANGED9291')
old=obj(oldpath);new=obj(newpath);auth=obj(authpath)
need(list(old)==list(new),'TOP_KEY_ORDER_NO_ADD_DELETE')
need(new['status']=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and new['blockers']==[],'READINESS_ONLY_STATUS_BLOCKER')
need(list(old['life_contract'])==list(new['life_contract']),'LIFE_CONTRACT_KEY_ORDER_UNCHANGED')
need(new['life_contract']['Root_preparation_input']=='Root62_preparation' and new['life_contract']['root_input_freeze_pending']is False,'EXACT_ROOT_PREPARATION_LOCK')
need(strict(new['life_contract']['expected_Root_preparation_document'],auth),'ENTIRE_ROOT_DOCUMENT_ORDERED_TYPED_EXACT')
need(len(old['pinned_inputs'])==61 and len(new['pinned_inputs'])==62 and strict(new['pinned_inputs'][:-1],old['pinned_inputs']),'ALL61_OLD_PINS_WHOLE_UNCHANGED')
expected_pin={'sha256':sha(authpath),'id':'Root62_preparation','path':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration62/source_stage_preparation_authorization.json'}
need(strict(new['pinned_inputs'][-1],expected_pin),'SOLE_ROOT_PREPARATION_PIN_FULL_SCHEMA')
need(len({p['id']for p in new['pinned_inputs']})==62,'NO_DUPLICATE_PIN_ID')
restored=copy.deepcopy(new)
restored['status']=old['status'];restored['blockers']=old['blockers'];restored['pinned_inputs'].pop()
for k in ['Root_preparation_input','expected_Root_preparation_document','root_input_freeze_pending']:restored['life_contract'][k]=copy.deepcopy(old['life_contract'][k])
need(strict(restored,old),'FULL_TYPED_ORDERED_REVERSE_TO_FALSE573B')
need((json.dumps(restored,ensure_ascii=False,indent=2)+'\n').encode('utf-8')==raw(oldpath),'FULL_SERIALIZED_UTF8_REVERSE_TO_FALSE_BYTES')
need(auth['approved_by_root']is True and auth['allowed_stage_calls']==1 and auth['target_count']==28 and auth['patch_GD_count']==auth['copy_JSON_count']==14,'EXACT_ROOT_SINGLE_STAGE_NOT_DEPLOYMENT_AUTHORITY')
need(auth['parent_input_sha256']==sha(oldpath) and auth['driver_sha256']==sha(driver) and auth['whole_city_complete_claim']is False and auth['only_build_output_not_formal_deployment']is True and auth['no_engine_collector_geometry_or_media_decode']is True,'ROOT_DOCUMENT_SOURCE_AND_SCOPE_LIMITS')
proof=S/'performance100_unified_life_garden_scholar_BUILD/driver_input_complete_byte_inverse_NOTREADY.json'
need(sha(proof)==auth['inverse_sha256']=='d9ddff3e579a3e17642b41673e4e5b2d366eda85ba99c9e6c5a4a001207204ab','UNCHANGED_ROOT_AUDITED_DRIVER_INPUT_INVERSE')
qa=GAME/'build/luoyang_city_full_rollout_20261022ap_qa01/Source100_exact28_code_data_execution_static_review_READY_NOT_STAGE.json'
need(sha(qa)==auth['QA_static_review_sha256']=='1cc4afc8999c461fd4e723f9046405184bb9b1b00f4375427229858587e55a7c','PRIOR_SCOPE_CODE_EXECUTION_QA_FIXED')
need(new['output_root'].startswith('res://build/') and not (GAME/new['output_root'][6:]).exists(),'NEW_OUTPUT_ABSENT')
out={'status':'UNIFIED100_ROOT62_FINAL_INPUT_MECHANICAL_FREEZE_NO_BLOCKER_ROOT_SINGLE_STAGE_MAY_PROCEED',
 'input_SHA':sha(newpath),'parent_FALSE_input_SHA':sha(oldpath),'driver_SHA':sha(driver),'Root_preparation_SHA':sha(authpath),
 'only_deltas':['status','blockers','pinned_inputs append exact Root62_preparation row','life_contract.Root_preparation_input','life_contract.expected_Root_preparation_document','life_contract.root_input_freeze_pending'],
 'full_ordered_typed_and_serialized_UTF8_inverse_to573B':True,'entire_expected_Root_document_exact':True,'old61pins_whole_same_plus1Rootpin':True,
 'unchanged_DAG':['28 target paths/order/old snapshots and14GD14JSON partition','all nodes/metadata operations/fourmap rules/source groups/native permissions','active10 only3edges/old96pins+5=101 and exact executionA971','fullFIRSTFINAL and buffered output checks; original8DE0 core','same new absent output root; no canonical/engine/import/collector/decode action'],
 'prior_code_scope_QA_SHA':sha(qa),'Root_audited_parent_driver_input_inverse_SHA':sha(proof),
 'runtime_or_formal_deployment_or_whole_ART_credit':False,
 'execution_by_QA':{'Stage':False,'constructor':False,'engine':False,'collector':False,'media_or_native_decode':False,'formal_write':False},
 'note':'Only Root may invoke this exact pinned input/driver once under B96F. Actual output, independent owner and formal deployment require separate review.'}
print(json.dumps(out,ensure_ascii=False,indent=2))
