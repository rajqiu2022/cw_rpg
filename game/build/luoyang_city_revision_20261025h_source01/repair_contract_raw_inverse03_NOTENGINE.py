"""One CT validator inverse correction; original exact raw candidate stays unchanged."""
from pathlib import Path
import json,hashlib,copy,ast
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(n,b):
 p=P/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=R+n,sha256=sha(b),bytes=len(b))
proof=json.loads((P/'owned4_service_READY02/four_owned_code_execution_whole_inverse_NOT_STAGE.json').read_bytes());ct=proof['contract'];old=(G/ct['parent']['path'][6:]).read_bytes();candidate=(G/ct['candidate']['path'][6:]).read_bytes()
assert sha(old)==ct['parent']['sha256']and sha(candidate)==ct['candidate']['sha256']
delta=next(iter(ct['changes'].values()));a,b=delta['old'].encode(),delta['new'].encode();assert old.count(a)==candidate.count(b)==1 and old.replace(a,b,1)==candidate and candidate.replace(b,a,1)==old
back=json.loads(candidate);back['source_sha256']['res://scripts/field/field_walkable_controller.gd']=delta['old'];assert back==json.loads(old)
different=next(i for i,(a,b)in enumerate(zip(old,enc(back)))if a!=b)
audit=[]
bundle=json.loads((P/'NG_bytes_residual02/unified28_candidates_exact_bytes.json').read_bytes())
for p,r in bundle['metadata'].items():
 raw=(G/r['parent']['path'][6:]).read_bytes();v=json.loads((G/r['candidate']['path'][6:]).read_bytes())
 for c in reversed(r['changes']):
  holder=v
  for key in c['pointer'][:-1]:holder=holder[key]
  if c['existed']:holder[c['pointer'][-1]]=copy.deepcopy(c['old'])
  else:del holder[c['pointer'][-1]]
 assert enc(v)==raw;audit.append(dict(target=p,exact_serialized_inverse=True))
ex=bundle['execution'];eraw=(G/ex['parent']['path'][6:]).read_bytes();assert enc(json.loads(eraw))==eraw
dp=P/'stage_service_garden_exact28_ROOT_ONLY.py';source=dp.read_bytes();assert sha(source)=='49b7fff096197ead04a880d7fe80ba9ef185706959a605d6baeb46484f4919b9'
oldline="  need(enc(back)==before,'CONTRACT_WHOLE_TYPED_BYTE_INVERSE');self.add_target(CT,contract['candidate']);self.nodes['runtime_contract_final']=dict(path=contract['candidate']['path'],sha256=contract['candidate']['sha256'],value=value);self.proofs['runtime_contract_final']=dict(whole_typed_inverse=True)"
newline="""  change=contract['changes']['res://scripts/field/field_walkable_controller.gd'];old_literal,new_literal=change['old'].encode(),change['new'].encode()
  need(same(back,old)and before.count(old_literal)==after.count(new_literal)==1 and before.replace(old_literal,new_literal,1)==after and after.replace(new_literal,old_literal,1)==before,'CONTRACT_FIXED_RAW_ONE_HASH_TYPED_FULL_BYTE_INVERSE');self.add_target(CT,contract['candidate']);self.nodes['runtime_contract_final']=dict(path=contract['candidate']['path'],sha256=contract['candidate']['sha256'],value=value);self.proofs['runtime_contract_final']=dict(whole_typed_inverse=True,original_raw_inline_array_format_preserved=True)"""
assert source.count(oldline.encode())==1;newsource=source.replace(oldline.encode(),newline.encode(),1);assert newsource.replace(newline.encode(),oldline.encode(),1)==source;ast.parse(newsource.decode())
driver=out('stage_service_garden_exact28_CT_raw03_ROOT_ONLY.py',newsource)
ip=P/'NG_bytes_residual02/source_input_ROOT_REVIEW.json';ib=ip.read_bytes();assert sha(ib)=='7913ec1f25cca9e117960cac44536eec23c19bf32c38460deadaac07efa4a3e0';original=json.loads(ib);v=copy.deepcopy(original)
pin=next(p for p in v['pinned_inputs']if p['id']=='driver');pin.update(path=driver['path'],sha256=driver['sha256']);v['output_root']=R+'outputs/root_services_garden_exact28_stage03/'
back=copy.deepcopy(v);back['pinned_inputs']=copy.deepcopy(original['pinned_inputs']);back['output_root']=original['output_root'];assert enc(back)==ib
inp=out('CT_raw_inverse_residual03/source_input_ROOT_REVIEW.json',enc(v))
small=out('CT_raw_inverse_residual03/diagnostic_and_exact_validator_inverse_NOT_STAGE.json',enc(dict(status='ONLY_FIXED_CT_RAW_INVERSE_VALIDATOR_REPAIR',cause='Fixed original CT has three inline coordinate arrays. Standard JSON re-encoding expands them, although typed and raw one-hash inverse were already exact.',old_CT_sha256=sha(old),candidate_CT_sha256=sha(candidate),old_bytes=len(old),encoder_bytes=len(enc(json.loads(old))),first_format_difference=different,old_near=old[different-20:different+90].decode(),encoder_near=enc(json.loads(old))[different-20:different+90].decode(),exact_raw_one_hash_forward_inverse=True,all_other12_metadata_serialized_inverse_audit=audit,old_execution_serialization_exact=True,driver=driver,input=inp,driver_only_change=dict(old=oldline,new=newline),whole_driver_byte_inverse=True,whole_input_typed_serialized_inverse=True,no_candidate_expected_or_resource_changes=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(driver=driver,input=inp,proof=small,other_metadata_audited=len(audit),unchanged_candidate_CT=ct['candidate'])))
