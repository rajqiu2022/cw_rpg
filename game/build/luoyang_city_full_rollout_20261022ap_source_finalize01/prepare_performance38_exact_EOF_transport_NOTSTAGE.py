"""NEW sole adapter EOF transport; same runtime candidates/DAG/025E. No Stage."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance38_exact_EOF_transport_recipe/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def diff(a,b,ap,bp):return ''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile=ap,tofile=bp)).encode()
def byte_hunks(a,b):
    aa=a.decode().splitlines(True);bb=b.decode().splitlines(True);hs=[]
    for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
        if tag!='equal':hs.append({'old_start':len(''.join(aa[:i]).encode()),'old_end':len(''.join(aa[:j]).encode()),'new_start':len(''.join(bb[:k]).encode()),'new_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
    forward=a;inverse=b
    for h in reversed(hs):forward=forward[:h['old_start']]+h['new'].encode()+forward[h['old_end']:];inverse=inverse[:h['new_start']]+h['old'].encode()+inverse[h['new_end']:]
    assert forward==b and inverse==a
    return hs
tp=S+'stage_performance35_merged_copy_READY.py';ts='71c6f60e9bad794f650398b7c2221a2ba8716d2c9ffc46e760502c78b0fb5c62';oldtool=fixed(tp,ts);text=oldtool.decode()
ip=S+'performance35_merged_source_recipe/source_input_ROOT_LOCKED.json';iss='e90077daf5c95a22559b6fd82ceff31cf9974cc42be0021e4bbf2e5b1e654d6b';oldinput=fixed(ip,iss);old=json.loads(oldinput)
rp='res://build/luoyang_city_full_rollout_20261022ap_root01/integration29/adapter_exact_EOF_transport_preparation_approval_READY.json';rs='184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97';root=json.loads(fixed(rp,rs))
assert root['approved_by_root']is True and root['candidate_sha256']=='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84'and root['old_sha256']=='999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90'
anchor="        prior=self.read_json_input(c['parent_approval_input'])\n"
insert=r'''        self.eof_approval=self.read_json_input(c['eof_transport_input'])
        eof=self.eof_approval
        need(self.inputs[c['eof_transport_input']]['sha256']=='184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97' and eof.get('status')=='ROOT_APPROVES_ONE_EXACT_ADAPTER_EOF_TRANSPORT_PREPARATION_NOT_STAGE_OR_DEPLOYMENT' and eof.get('approved_by_root') is True,'EXACT_ROOT_SINGLE_ADAPTER_EOF_TRANSPORT_APPROVAL')
        need(eof.get('target')==S+'finite_adapter_production08/finite_adapter_READY.gd' and eof.get('old_sha256')=='999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90' and eof.get('candidate_sha256')=='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84' and eof.get('candidate_bytes')==30746 and eof.get('patch_intermediate_sha256')=='5676455a1a40646dadd9832fe27f124596e0624a58b137ff052b729cd6d88216' and eof.get('patch_intermediate_bytes')==30747,'FIXED_EOF_OLD_NEW_INTERMEDIATE_DOMAIN')
'''
assert text.count(anchor)==1;text=text.replace(anchor,insert+anchor,1)
anchor='    def target(self,target,old,path,expected):\n'
method=r'''    def _exact_eof_transport_patch(self,target,before,after):
        eof=self.eof_approval
        if target!=res(eof['target']).as_posix():
            return M._strict_lf_build_file_patch(target,before,after)
        need(sha(before)==eof['old_sha256'] and sha(after)==eof['candidate_sha256'] and len(before)==30356 and len(after)==30746,'ONLY_EXACT_999A_TO5709_EOF_PAIR')
        need(before and after and not before.endswith(b'\n') and not after.endswith(b'\n') and b'\r'not in before and b'\r'not in after and not before.startswith(b'\xef\xbb\xbf') and not after.startswith(b'\xef\xbb\xbf'),'SOLE_MISSING_FINAL_LF_NOT_GENERAL_EOL_NORMALIZATION')
        old_shadow=before+b'\n';new_shadow=after+b'\n'
        need(sha(new_shadow)==eof['patch_intermediate_sha256'] and len(new_shadow)==30747 and new_shadow[:-1]==after and new_shadow[-1:]==b'\n' and old_shadow[:-1]==before,'EXACT_IN_MEMORY_SINGLE_LF_SHADOWS')
        piece,proof=M._strict_lf_build_file_patch(target,old_shadow,new_shadow)
        need(proof.get('forward_exact_bytes') is True and proof.get('whole_inverse_exact_bytes') is True and proof.get('reconstructed_sha256')==eof['patch_intermediate_sha256'],'ORIGINAL_STRICT_WHOLE_SHADOW_FORWARD_AND_INVERSE')
        proof.update(candidate_sha256=sha(after),forward_exact_bytes=False,whole_inverse_exact_bytes=False,
                     forward_exact_intermediate_bytes=True,whole_shadow_inverse_exact_bytes=True,
                     original_before_sha256=sha(before),original_before_bytes=len(before),
                     old_shadow_sha256=sha(old_shadow),old_shadow_bytes=len(old_shadow),
                     patch_intermediate_sha256=sha(new_shadow),patch_intermediate_bytes=len(new_shadow),
                     final_requires_exact_root_authorized_EOF_formatting=True,
                     exact_original_before_and_after_recovered_by_removing_only_shadow_final_0A=True,
                     eof_format={'path':eof['target'],'approval_path':self.inputs[self.contract['eof_transport_input']]['path'],'approval_sha256':'184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97','required_deployed_intermediate_sha256':sha(new_shadow),'required_deployed_intermediate_bytes':30747,'only_remove_exact_final_byte_hex':'0a','required_final_sha256':sha(after),'required_final_bytes':30746,'must_first_apply_patch_then_mechanically_remove_one_final_byte_from_deployed_characters':True,'never_copy_GD_candidate_or_strip_general_whitespace':True})
        return piece,proof

'''
assert text.count(anchor)==1;text=text.replace(anchor,method+anchor,1)
call="            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)"
assert text.count(call)==1;text=text.replace(call,"            piece,proof=self._exact_eof_transport_patch(res(row['target']).as_posix(),before,candidate)",1)
tool=text.encode();ast.parse(tool)
newtp=S+'stage_performance38_exact_EOF_transport_READY.py'
spec=copy.deepcopy(old);spec['output_root']=S+'outputs/root_merged_G_parentcopy_DT_source_stage02/'
spec['required_generator']={'path':newtp,'sha256':sha(tool)}
spec['pinned_inputs'].append({'id':'adapter_exact_EOF_transport_Root','path':rp,'sha256':rs})
spec['B_only_contract']['eof_transport_input']='adapter_exact_EOF_transport_Root'
reverse=copy.deepcopy(spec)
reverse['output_root']=old['output_root'];reverse['required_generator']=copy.deepcopy(old['required_generator']);reverse['pinned_inputs'].pop();del reverse['B_only_contract']['eof_transport_input']
assert reverse==old and js(reverse)==oldinput
newip=O+'source_input_ROOT_LOCKED.json';newib=js(spec)
proof={'status':'SOLE_EXACT_ADAPTER_EOF_TRANSPORT_DRIVER_INPUT_BYTE_TYPED_INVERSE_NOT_STAGE',
 'parent_tool':{'path':tp,'sha256':ts},'new_tool':{'path':newtp,'sha256':sha(tool)},'whole_tool_forward_inverse':True,'tool_hunks':byte_hunks(oldtool,tool),
 'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_serialized_byte_inverse':True,
 'input_changed_exactly':['output_root stage01->stage02','required_generator exactNEWtool','append exactRootEOFapproval pin','B_only_contract eof_transport_input'],
 'all_nodes_groups_candidate_bytes_025E_scope29_partition15GD14JSON_unchanged':True,
 'original_8DE0_strict_function_unchanged':True,'only_adapter_999A_5709_uses_single_final_LF_shadows':True,
 'strict_proof_is_intermediate_not_final_candidate':True,'Root_formatter_must_match_full567645_before_sole_final_0A_removal_to5709':True,
 'failed_35_tool_input_session95129_preserved':True,'engine_collector_Stage_formal_GDcopy_calls':0}
td=diff(oldtool,tool,tp,newtp);idiff=diff(oldinput,newib,ip,newip)
ownerp=S+'prepare_performance36_merged_actual_owner_NOTRUN.py';owners='e24bdc1b1578503d038deb17e63b9c0e42c840be4a504691433700a1520d7cb4';oldowner=fixed(ownerp,owners);owner=oldowner
changes=[('performance36_merged_actual_independent_review/','performance39_merged_EOF_actual_independent_review/'),('performance35_merged_source_recipe/source_input_ROOT_LOCKED.json','performance38_exact_EOF_transport_recipe/source_input_ROOT_LOCKED.json'),(iss,sha(newib)),('outputs/root_merged_G_parentcopy_DT_source_stage01/receipt.json','outputs/root_merged_G_parentcopy_DT_source_stage02/receipt.json')]
for a,b in changes:
    assert owner.count(a.encode())==1,(a,owner.count(a.encode()));owner=owner.replace(a.encode(),b.encode(),1)
back=owner
for a,b in reversed(changes):assert back.count(b.encode())==1;back=back.replace(b.encode(),a.encode(),1)
assert back==oldowner;ast.parse(owner)
newownerp=S+'prepare_performance39_merged_EOF_actual_owner_NOTRUN.py'
proof['owner_tool_parent']={'path':ownerp,'sha256':owners};proof['owner_tool_new']={'path':newownerp,'sha256':sha(owner)};proof['owner_whole_byte_inverse_and_only4header_literals']=True
hand={'status':'ROOT29_SINGLE_ADAPTER_EOF_TRANSPORT_STAGE02_INPUT_READY_NOT_STAGED','tool':{'path':newtp,'sha256':sha(tool)},'input':{'path':newip,'sha256':sha(newib)},'inverse':{'path':O+'driver_input_owner_whole_inverse_READY.json','sha256':sha(js(proof))},'scope29_15GD14JSON_same_runtime_candidates':True,'future_owner_tool':proof['owner_tool_new'],'diffs':{'driver':sha(td),'input':sha(idiff)},'engine_Stage_collector_formal_calls':0,'Root_only_command_NOT_EXECUTED':'python '+str(p(newtp))+' '+str(p(newip))+' --input-sha256 '+sha(newib)}
files={newtp:tool,newip:newib,newownerp:owner,O+'driver_input_owner_whole_inverse_READY.json':js(proof),O+'driver_complete_vs71C6.diff':td,O+'input_complete_vsE900.diff':idiff,O+'owner_complete_vsE24B.diff':diff(oldowner,owner,ownerp,newownerp),O+'handoff_READY_NOT_STAGED.json':js(hand)}
assert not p(O).exists()and not p(newtp).exists()and not p(newownerp).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
