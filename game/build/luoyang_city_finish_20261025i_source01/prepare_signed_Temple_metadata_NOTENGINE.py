"""Reviewed current-map incremental source expression, no collector/Stage."""
from pathlib import Path
N=Path(__file__).resolve().parent
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'temple_signed_iid_repair01/';C=P+'closure_READY01/'
t=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf8')
changes=[
 ('unified32_READY01','temple_signed_iid_repair01/unified31_READY01'),
 ("PREFIX=NS+OUT.name+'/'","PREFIX=NS+'temple_signed_iid_repair01/unified31_READY01/'"),
 ("NS+'finish8_existing_target_scope32_PREPARATION.json'","'"+P+"current_377B_exact31_scope_PREPARATION.json'"),
 ('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589','9e314a4d78bf08d9e4b336a5d49a6ce95f5d84a2f266043ebf86ff1cf294b527'),
 ('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',S+'family_visual_material_loading_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e','75ce628d299b772f95f05065b9cb6490106130b2aaac1e26205ebe4b5f0c78ea'),
 ("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'","'"+C+"code_execution_all_whole_inverse_NOT_STAGE.json'"),
 ('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200','76d32aa916b64cc9597120b247b7726196c59b5022265d1092d8674a099353d9'),
 ("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'","'"+C+"runtime_consumers_mechanical_seal_whole_inverse_READY.json'"),
 ('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa','1665938e4462304124e2a35b4c1abe8623ac7e9c158aac67001edcfa221f89e8'),
 ("adapter=dict(path=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd',sha256='9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5')","adapter=seal['adapter']"),
 ("if k!='gate':merge(v,room)","if k!='gate':merge(v,room)\n if k=='artisan':merge(v,{seal['material_helper']['path']:seal['material_helper']['sha256']})"),
 ("meta('estate_final');meta('quarter_final')","meta('estate_final')"),
 ("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),
 ("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),
 ("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),
 ('len(records)==18','len(records)==17'),('dict(GD=18,JSON=14,total=32)','dict(GD=17,JSON=14,total=31)'),
 ("root_backup=dict(path=NS+'immutable_current32_ROOT_EXECUTED.json',sha256='d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f')","root_backup=dict(status='ROOT_CURRENT_377B_NEW_BACKUP_PENDING_OLD372_PRESERVED')"),
 ('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','CURRENT_377B_SIGNED_TEMPLE_IID_SOURCE_INCREMENT_EXACT31_NOT_STAGE'),
]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
exec(compile(t,str(N/'prepare_signed_Temple_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_signed_Temple_metadata_DERIVED_NOTENGINE.py')})
