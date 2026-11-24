"""NEW exact14GD patch +14 generated JSON byte-copy partition. No stage."""
import ast
import difflib
import hashlib
import json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'a2_source_recipe07/'
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):return G/p[6:]
def read(p,s):
    b=path(p).read_bytes();assert sha(b)==s,p;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
old=read(S+'stage_a2_source06_READY.py','3a730aa96357e1dd54695f26fc75552b1e948120f12bb2be27f4bc6b6e54aeeb')
text=old.decode();changes=[]
def sub(a,b,label):
    global text
    assert text.count(a)==1,(label,text.count(a));text=text.replace(a,b,1);changes.append({'label':label,'old':a,'new':b})
a='''            if row['target']==EXE:
                need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_C668_TO85DF_COPY_ONLY')
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':PROPOSAL,'original_bytes_preserved':True};continue
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
'''
b='''            if row['target'].endswith('.json'):
                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_C668_TO85DF_EXECUTION_COPY_ONLY')
                    proof_id='fixed_Root_C668_to85DF_authority_inverse'
                else:
                    matches=[k for k,v in self.nodes.items() if v['path']==row['candidate_path'] and v['sha256']==row['candidate_sha256']]
                    need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_METADATA_COPY')
                    proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'ONLY_FOURTEEN_GD_PATCH_TARGETS')
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
'''
sub(a,b,'exact_generated_JSON_domain_uses_full_inverse_and_raw_byte_copy')
sub("need(len(copies)==1 and copies[0]['target']==EXE and len(reconstruction)==28,'PATCH27_COPY1_EXACT_DISJOINT_UNION28')", "need(len(copies)==14 and {r['target'] for r in copies}=={p for p in self.targets if p.endswith('.json')} and len(reconstruction)==28 and len([p for p in self.targets if p.endswith('.gd')])==14,'PATCH14_COPY14_EXACT_DISJOINT_UNION28')", 'exact14GD14JSON_partition')
sub("{'status':'ROOT_ONLY_EXACT_C668_TO85DF_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(set(self.targets)-{EXE}),'copy_targets':[EXE],'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True}", "{'status':'ROOT_ONLY_EXACT14_GENERATED_JSON_BYTE_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(p for p in self.targets if p.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}", 'JSON_copyplan14_not_a_megabyte_patch')
sub("'target_count':1},'target_partition':{'patch_count':27,'copy_count':1,'total':28", "'target_count':14},'target_partition':{'patch_count':14,'copy_count':14,'total':28", 'receipt_exact14_plus14')
ast.parse(text)
inverse=text
for r in reversed(changes):assert inverse.count(r['new'])==1;inverse=inverse.replace(r['new'],r['old'],1)
assert inverse.encode()==old
spec=json.loads(read(S+'a2_source_recipe06/source_input_PENDING_PROMOTION.json','14dd61ab4621c057c79f6f3679f49e32d319fdf93bb17676c4f0538f67b762b9'))
spec['required_generator']={'path':S+'stage_a2_source07_READY.py','sha256':sha(text.encode())}
spec['a2_contract']['deployment_partition']={'GD_apply_patch':14,'generated_JSON_exact_byte_copy':14,'union28_disjoint':True,'no_GD_copy':True}
proof={'status':'A2_TOOL07_JSON_PARTITION_ONLY_NOT_EXECUTED','parent06_sha256':sha(old),'whole_tool_byte_inverse':True,'changes':changes,'exact_scope_B2E_350D_unchanged':True,'no_stage_engine_collector_or_formal_writes':True}
outputs={S+'stage_a2_source07_READY.py':text.encode(),O+'source_input_PENDING_PROMOTION.json':js(spec),O+'tool07_exact_partition_inverse_READY.json':js(proof),O+'stage07_vs06.diff':''.join(difflib.unified_diff(old.decode().splitlines(True),text.splitlines(True),fromfile='frozen_stage06',tofile='stage07',n=4)).encode()}
assert not path(O).exists()
for p,b in outputs.items():
    assert not path(p).exists();path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'tool':{'path':S+'stage_a2_source07_READY.py','sha256':sha(text.encode())},'input':{'path':O+'source_input_PENDING_PROMOTION.json','sha256':sha(js(spec))},'proof_sha256':sha(js(proof)),'stage_runs':0}))
