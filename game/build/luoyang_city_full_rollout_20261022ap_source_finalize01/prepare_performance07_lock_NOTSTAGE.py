"""NEW final input and source-text comparisons only; no Stage/import/engine."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance07_source_recipe/'
sha=lambda b:hashlib.sha256(b).hexdigest();p=lambda x:G/x.removeprefix('res://')
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(x):return (json.dumps(x,ensure_ascii=False,indent=2)+'\n').encode()
old=fixed(S+'performance06_source_recipe/source_input_PENDING_ROOT.json','ac133ff6b91cb6addcdd004b3a459e1a177f1efbe733598eb7d37cc78eb3f96c')
original=json.loads(old);spec=copy.deepcopy(original)
authority_path='res://build/luoyang_city_full_rollout_20261022ap_root01/integration18/execution_successor_preparation_approval_READY.json'
authority_sha='f934dff214d96eb1cc9dbe45914db90a8094d8be0d9560fc9a9cbe5f907b878b'
root=json.loads(fixed(authority_path,authority_sha))
assert root['status']=='ROOT_APPROVED_PERFORMANCE05_EXACT_EXECUTION_SUCCESSOR_FOR_SOURCE_PREPARATION_ONLY' and root['approved_by_root'] is True
toolpath=S+'stage_performance07_READY.py';toolsha='5db6aadad7de09caac94579633ce99f03da05aa1d42ad62c9a32c296e0d8709f'
tool=fixed(toolpath,toolsha);ast.parse(tool)
spec['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';spec['blockers']=[]
spec['required_generator']={'path':toolpath,'sha256':toolsha}
spec['performance_contract']['execution_root_input']='performance_root_execution'
spec['performance_contract']['expected_root_execution_document']=root
spec['pinned_inputs'].append({'id':'performance_root_execution','path':authority_path,'sha256':authority_sha})
inv=copy.deepcopy(spec)
for k in ['status','blockers','required_generator']:inv[k]=copy.deepcopy(original[k])
inv['performance_contract']['execution_root_input']=original['performance_contract']['execution_root_input'];del inv['performance_contract']['expected_root_execution_document']
inv['pinned_inputs']=inv['pinned_inputs'][:-1]
assert inv==original
parentpath=S+'stage_a2_source07_READY.py';parentsha='6dd7ff3b39841461d1c6573bbd60230e8afce578dbfdc271c7604e71e0152920'
parent=fixed(parentpath,parentsha)
def compare(before,after):
    aa,bb=before.decode().splitlines(True),after.decode().splitlines(True)
    for context in [3,8,20,1000000]:
        hs=[]
        for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context):
            hs.append({'old':''.join(aa[group[0][1]:group[-1][2]]),'new':''.join(bb[group[0][3]:group[-1][4]])})
        try:
            current=before
            for h in hs:
                a,b=h['old'].encode(),h['new'].encode();assert a and current.count(a)==1;current=current.replace(a,b,1)
            assert current==after
            for h in reversed(hs):
                a,b=h['old'].encode(),h['new'].encode();assert b and current.count(b)==1;current=current.replace(b,a,1)
            assert current==before;return hs
        except AssertionError:pass
    raise AssertionError('WHOLE_TOOL_BYTE_INVERSE')
hs=compare(parent,tool)
diff=''.join(difflib.unified_diff(parent.decode().splitlines(True),tool.decode().splitlines(True),fromfile=parentpath,tofile=toolpath)).encode()
proof={'status':'PURE_INPUT_TYPED_AND_SOURCE_TOOL_BYTE_INVERSE_NO_STAGE','passed':True,'parent_tool':{'path':parentpath,'sha256':parentsha},'new_tool':{'path':toolpath,'sha256':toolsha},'whole_tool_forward_and_inverse':True,'whole_input_inverse_to_pending_AC133F':True,'unchanged_imported_validation_core':{'path':S+'stage_unified06_04_READY.py','sha256':'8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'},'hunks':hs,'code_changes':'Replace A2-only28/C668-to85DF/four-edge/geometry-declaration wrapper with exact26/85DF-to428A/three-edge source-only wrapper; preserve imported typed authority metadata group map media and LF patch algorithms. Registry is a real metadata target; contract and ENVindex remain fixed non-target nodes.','partition':{'GD_patch':12,'generated_JSON_copy':14},'stage_executed':False,'engine':False,'collector':False}
out={O+'source_input_ROOT_LOCKED.json':js(spec),O+'tool_vs_A2_source07_complete.diff':diff,O+'source_tool_and_input_inverse_READY.json':js(proof)}
assert not p(O).exists()
for path,b in out.items():
    p(path).parent.mkdir(parents=True,exist_ok=True)
    with p(path).open('xb') as f:f.write(b)
print(json.dumps({'input':{'path':O+'source_input_ROOT_LOCKED.json','sha256':sha(out[O+'source_input_ROOT_LOCKED.json'])},'tool':{'path':toolpath,'sha256':toolsha},'comparison':{'path':O+'source_tool_and_input_inverse_READY.json','sha256':sha(out[O+'source_tool_and_input_inverse_READY.json'])},'stage_runs':0}))
