"""NEW Root-document/input lock and tool whole-byte diff only; never import Stage."""
import argparse,ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance14_B_only_source_recipe/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
parser=argparse.ArgumentParser();parser.add_argument('--root-approval',required=True);parser.add_argument('--root-approval-sha256',required=True)
args=parser.parse_args()
pendingpath=S+'performance13_B_only_source_recipe/source_input_PENDING_ROOT.json';pendingsha='858a05fa8c2c07bdd645593f28f15e1ab42460a4655a91794a2c0131b8208d2d'
original=json.loads(fixed(pendingpath,pendingsha));spec=copy.deepcopy(original)
scopepath='res://build/luoyang_city_full_rollout_20261022ap_root01/integration21/scope22_full_old_backups_READY.json';scopesha='f028426e4d70e80a822d3f41dc23cccd371e19807d94730b672f6d1d7a1dffc5'
scope=json.loads(fixed(scopepath,scopesha));root=json.loads(fixed(args.root_approval,args.root_approval_sha256))
assert scope['approved_by_root'] is True and scope['target_count']==22 and scope['GD_count']==9 and scope['JSON_count']==13
assert scope['before_sha256']=='0f0236cff802aebf4d416e0626b2505cf018a897557d703fd5bd1e6f97c67332'
assert scope['proposal_sha256']=='0df58c434b6bf549c2fd7fcf37b4587a91067d7664a90ba588d95196dcb33b47'
assert root['approved_by_root'] is True
assert 'a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283' in json.dumps(root)
toolpath=S+'stage_performance13_B_only_PREPARATION_ONLY.py';toolsha='0c709b1da8fcc823d41d25d771ca4fe179f82d0288b9111ef31b87122a037fc2'
tool=fixed(toolpath,toolsha);ast.parse(tool)
spec['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';spec['blockers']=[]
spec['required_generator']={'path':toolpath,'sha256':toolsha}
spec['B_only_contract'].update(expected_scope_sha256=scopesha,expected_scope_document=scope,expected_root_execution_sha256=args.root_approval_sha256,expected_root_execution_document=root)
added=[{'id':'B_only_scope','path':scopepath,'sha256':scopesha},{'id':'B_only_root_execution','path':args.root_approval,'sha256':args.root_approval_sha256}]
spec['pinned_inputs']+=added
inverse=copy.deepcopy(spec)
for key in ['status','blockers','required_generator']:inverse[key]=copy.deepcopy(original[key])
for key in ['expected_scope_sha256','expected_scope_document','expected_root_execution_sha256','expected_root_execution_document']:del inverse['B_only_contract'][key]
inverse['pinned_inputs']=inverse['pinned_inputs'][:-2]
assert inverse==original and js(inverse)==fixed(pendingpath,pendingsha)
priorpath=S+'stage_performance07_READY.py';priorsha='5db6aadad7de09caac94579633ce99f03da05aa1d42ad62c9a32c296e0d8709f'
prior=fixed(priorpath,priorsha)
aa,bb=prior.decode().splitlines(True),tool.decode().splitlines(True)
hunks=[]
for tag,a,z,b,y in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag=='equal':continue
    hunks.append({'old_byte_start':len(''.join(aa[:a]).encode()),'old_byte_end':len(''.join(aa[:z]).encode()),'new_byte_start':len(''.join(bb[:b]).encode()),'new_byte_end':len(''.join(bb[:y]).encode()),'old':''.join(aa[a:z]),'new':''.join(bb[b:y])})
forward=prior
for h in reversed(hunks):
    assert forward[h['old_byte_start']:h['old_byte_end']]==h['old'].encode()
    forward=forward[:h['old_byte_start']]+h['new'].encode()+forward[h['old_byte_end']:]
back=tool
for h in reversed(hunks):
    assert back[h['new_byte_start']:h['new_byte_end']]==h['new'].encode()
    back=back[:h['new_byte_start']]+h['old'].encode()+back[h['new_byte_end']:]
assert forward==tool and back==prior
diff=''.join(difflib.unified_diff(aa,bb,fromfile=priorpath,tofile=toolpath)).encode()
proof={'status':'B_ONLY_SOURCE_TOOL_BYTE_AND_INPUT_TYPED_INVERSE_NO_STAGE','passed':True,
 'parent_tool':{'path':priorpath,'sha256':priorsha},'new_tool':{'path':toolpath,'sha256':toolsha},
 'frozen_validation_core':{'path':S+'stage_unified06_04_READY.py','sha256':'8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'},
 'whole_tool_forward_and_inverse':True,'whole_locked_input_inverse_to_pending_858A':True,'hunks':hunks,
 'scope_delta':'26 to22 by excluding unchanged DT/hash/Temple/registry; registry becomes frozen original-bytes node. One B owned edge and2 proof pins only; exact9GD/13JSON. Metadata source-only operations use actualD058 old values before owned promotion; AO map source operations remain after owned promotion.',
 'Root_scope':{'path':scopepath,'sha256':scopesha},'Root_execution':{'path':args.root_approval,'sha256':args.root_approval_sha256},
 'same_native_media_classification_domains':True,'stage_engine_collector_calls':0}
inputpath=O+'source_input_ROOT_LOCKED.json';inputbytes=js(spec)
hand={'status':'EXACT22_B_ONLY_SOURCE_DRIVER_AND_INPUT_READY_FOR_ROOT_EXTERNAL_REVIEW_NOT_EXECUTED',
 'input':{'path':inputpath,'sha256':sha(inputbytes)},'tool':{'path':toolpath,'sha256':toolsha},
 'proof':{'path':O+'source_tool_and_input_inverse_READY.json','sha256':sha(js(proof))},
 'tool_diff':{'path':O+'tool_vs_performance07_complete.diff','sha256':sha(diff)},'pinned_inputs':len(spec['pinned_inputs']),
 'targets':22,'GD_apply_patch':9,'generated_JSON_copy':13,'source_stage_engine_collector_calls':0,
 'Root_only_command_not_executed':'python '+str(p(toolpath))+' '+str(p(inputpath))+' --input-sha256 '+sha(inputbytes)}
files={'source_input_ROOT_LOCKED.json':inputbytes,'source_tool_and_input_inverse_READY.json':js(proof),'tool_vs_performance07_complete.diff':diff,'handoff_READY_NOT_STAGED.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b) for name,b in files.items()},indent=2))
