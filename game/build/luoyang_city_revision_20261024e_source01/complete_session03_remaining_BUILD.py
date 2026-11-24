"""Continue only unwritten generators after the preserved pre-output mapping refusal."""
from pathlib import Path
import json,hashlib,runpy,sys
HERE=Path(__file__).resolve().parent;S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
fr=(HERE/'runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json').read_bytes();assert sha(fr)=='d22b25c6fc5501ee6a6839a693ee427f2faa9d4b63b97fc67090d9fc49669a71'
er=(HERE/'runtime_ready03/ENV_whole_inverse_NOT_STAGE.json').read_bytes();assert sha(er)=='d1cae129675c1bbf69342d516adbdfbdc9094b58dea8d655696a2338c4aef067'
f=json.loads(fr);derived=runpy.run_path(str(HERE/'prepare_session10_final_residual03_BUILD.py'),run_name='prepared_functions_only')['derived']
ordinary_generator=derived('prepare_ordinary_outer03_BUILD.py','prepare_ordinary_outer01_BUILD.py',[
 ('runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json'),
 ('f=json.loads(freeze.read_bytes())',"assert sha(freeze.read_bytes())=='"+sha(fr)+"';f=json.loads(freeze.read_bytes())"),('ordinary_outer01_READY','ordinary_outer03_READY')])
ordinarysha=sha((HERE/'ordinary_outer03_READY/whole_inverse_NOT_STAGE.json').read_bytes())
dependency_generator=derived('prepare_dependencies_execution33_session03_BUILD.py','prepare_dependencies_execution33_BUILD.py',[
 ('runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json'),('ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad',sha(fr)),('ordinary_outer01_READY/whole_inverse_NOT_STAGE.json','ordinary_outer03_READY/whole_inverse_NOT_STAGE.json'),('26f9cd34b9c0aea9b782e267e3cf00ac279cea70cfe785a5055c331581d15618',ordinarysha),('clean_ENV02_READY/whole_inverse_NOT_STAGE.json','runtime_ready03/ENV_whole_inverse_NOT_STAGE.json'),('ef8f18da6267c0e542c4e288310ae15c9675756ce22cb394b4461b94b5f1e04f',sha(er)),('dependencies33_READY','dependencies33_session03_READY')])
depssha=sha((HERE/'dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json').read_bytes())
sys.argv=['prepare_stage33_session03_input_BUILD.py','--preparation-path','res://build/luoyang_city_revision_20261024e_root01/source_preparation33_authorization.json','--preparation-sha','0afc4fa309a352594177b80235c542c7278f90f7548913f8a12303a8245e8b50']
input_generator=derived('prepare_stage33_session03_input_BUILD.py','prepare_stage33_input_BUILD.py',[
 ('dependencies33_READY/code_execution_whole_inverse_NOT_STAGE.json','dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json'),('d6b4c0afcaac7f8f29ca8c15b7412abafa90ad7418c4106a8d113622c715913e',depssha),('runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json'),('ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad',sha(fr)),('outputs/root_market_blocks_prewarm_exact33_stage01/','outputs/root_market_blocks_prewarm_exact33_stage03/'),('source_input_market_blocks33_ROOT_REVIEW.json','source_input_market_blocks33_session03_ROOT_REVIEW.json'),('stage33_input_full_byte_patch_BUILD.json','stage33_session03_input_full_byte_patch_BUILD.json'),('stage33_package_review_BUILD.json','stage33_session03_package_review_BUILD.json')])
report=dict(status='FINAL_EXPLICIT_TYPE_SYNTAX_RESIDUAL_NOT_STAGED',freeze=dict(path=S+'runtime_ready03/mechanical_ready_whole_inverse_NOT_STAGE.json',sha256=sha(fr)),runtime=f['runtime']['candidate'],code_inverse=dict(path=S+'dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json',sha256=depssha),derived_generators=[ordinary_generator,dependency_generator,input_generator],original139_all_exact=True,formal24c_only_parent=True,all_old_FAIL_and_source_only_stages_preserved=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
raw=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode();dest=HERE/'session03_final_build_handoff_NOT_STAGE.json';assert not dest.exists()
with dest.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(handoff_path=S+dest.name,handoff_sha256=sha(raw),runtime_sha256=f['runtime']['candidate']['sha256'],code_inverse_sha256=depssha)))
