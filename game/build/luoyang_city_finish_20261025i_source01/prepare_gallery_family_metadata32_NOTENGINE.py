"""Reuse reviewed source-expression model, authority20 overlay and exact current parents."""
from pathlib import Path
import json,hashlib,copy,argparse
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';Y='res://build/luoyang_city_finish_20261025i_system01/'
P=S+'docks_gallery_family_repair01/';C=P+'closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
ap=argparse.ArgumentParser();ap.add_argument('--code-sha256',required=True);ap.add_argument('--seal-sha256',required=True);a=ap.parse_args()
code=load(C+'code_execution_all_whole_inverse_NOT_STAGE.json',a.code_sha256);seal=load(C+'runtime_consumers_mechanical_seal_whole_inverse_READY.json',a.seal_sha256)
base=load(S+'market_ground25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4')
authority=load(Y+'execution_declared_edges_source02/stage20_READY02/all_candidates20_full_inverse_NOT_STAGE.json','b88801a505b0136ecf7e69f09543e190ee6c7bd55c72b05831071c77e1e8bfb1')
for key in ['metadata','index_proofs','records']:base[key].update(authority[key])
base['authority_helper']=authority['authority_helper']['candidate']
merged=(json.dumps(base,ensure_ascii=False,indent=2)+'\n').encode();mp=P+'authority20_current_schema_model_NOT_STAGE.json'
dest=G/mp[6:];assert not dest.exists()
with dest.open('xb')as f:f.write(merged)
text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf-8')
changes=[
 ('unified32_READY01','docks_gallery_family_repair01/unified32_READY01'),
 ("PREFIX=NS+OUT.name+'/'","PREFIX=NS+'docks_gallery_family_repair01/unified32_READY01/'"),
 ("NS+'finish8_existing_target_scope32_PREPARATION.json'","'"+P+"current_authority20_exact32_scope_PREPARATION.json'"),
 ('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589','e252869c32121af260b27d3b65fc85ce8590959035fcd47757da1675ab20a703'),
 ('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',mp),
 ('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e',sha(merged)),
 ("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'","'"+C+"code_execution_all_whole_inverse_NOT_STAGE.json'"),
 ('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200',a.code_sha256),
 ("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'","'"+C+"runtime_consumers_mechanical_seal_whole_inverse_READY.json'"),
 ('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',a.seal_sha256),
 ("meta('estate_final');meta('quarter_final')","meta('estate_final')"),
 ("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),
 ("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),
 ("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),
 ("NS+'immutable_current32_ROOT_EXECUTED.json'","'"+P+"current_authority20_backup32_ROOT_ACTUAL.json'"),
 ('d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f','5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3'),
 ('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','AUTHORITY20_GALLERY_RETIREMENT_FAMILY_DIRECT_ENTRY_EXACT32_NOT_STAGE'),
 ('original_native_registry_Router_DT_unchanged=True','original_native_registry_DT_unchanged=True,Router_only_exact3_family_entry=True'),
]
for x,y in changes:assert x in text,x;text=text.replace(x,y)
exec(compile(text,str(N/'prepare_gallery_family_metadata32_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_gallery_family_metadata32_DERIVED_NOTENGINE.py')})
