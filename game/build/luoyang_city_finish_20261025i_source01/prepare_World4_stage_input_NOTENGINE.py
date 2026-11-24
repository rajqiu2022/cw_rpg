from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
driver=dict(path=NS+'stage_World4_visual_ROOT_ONLY.py',sha256=sha((N/'stage_World4_visual_ROOT_ONLY.py').read_bytes()))
v=dict(status='ROOT_LOCKED_SEPARATE_WORLD4_VISUAL_STAGE_INPUT',driver=driver,plan=dict(path=NS+'world4_READY01/world4_candidates_and_sources_ROOT_REVIEW.json',sha256='db13a08ffd1c27c45900d55d8b8366b2009f2273b53d77e20695673b7f4b70d4'),city_deployment=dict(path=NS+'exact32_deployed_ROOT_ACTUAL.json',sha256='4160b4c149a71bd0e6dfa8975b0fc5f463f782f0fcff50acd630335b5ccd3142'),city_Stage=dict(path=NS+'outputs/root_finish8_exact32_stage01/receipt.json',sha256='37d79bce73a637c46dd9790453650a48da79cc1a521c7436fbf07f326cb6ba33'),city_OWNED_or_execution_changes=0,output_root=NS+'outputs/root_World_visual_exact4_stage01/')
raw=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();p=N/'source_input_World_visual_exact4_ROOT_REVIEW.json';assert not p.exists()
with p.open('xb')as f:f.write(raw)
print(json.dumps(dict(driver=driver,input=dict(path=NS+p.name,sha256=sha(raw)))))
