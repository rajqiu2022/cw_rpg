from pathlib import Path
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';C=S+'market_ground_texture_repair02/closure_READY01/'
text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text()
changes=[
('unified32_READY01','market_ground25_READY01'),
("NS+'finish8_existing_target_scope32_PREPARATION.json'","'"+S+"market_ground_texture_repair02/current5D6C_exact25_scope_PREPARATION.json'"),
('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589','a0f69caeec43fc22c0edf9af4898375aa2404b7c945873783bad201ba3624fa5'),
('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',S+'repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e','319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98'),
("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'","'"+C+"code_execution_all_whole_inverse_NOT_STAGE.json'"),
('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200','a6a96caf1ef102fcc5a0a945c6d26c668e0b1f5d2b3e353156c2ff66746615b0'),
("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'","'"+C+"runtime_consumers_mechanical_seal_whole_inverse_READY.json'"),
('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa','29d24a2aa5f2ac3dbc72946beb4da3a575d2a9099b29f2d5c8c51930cc01d8ea'),
("envtext=read(next(r['candidate']['path']for p,r in records.items()if 'environment_layer' in p),next(r['candidate']['sha256']for p,r in records.items()if 'environment_layer' in p)).decode()","envpin=oldbundle['records']['res://scripts/city/luoyang_environment_layer_20261022ap.gd']['candidate'];envtext=read(envpin['path'],envpin['sha256']).decode()"),
("meta('estate_final');meta('quarter_final')","meta('estate_final')"),
("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),
("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),
("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),
('len(records)==18','len(records)==11'),('dict(GD=18,JSON=14,total=32)','dict(GD=11,JSON=14,total=25)'),
("NS+'immutable_current32_ROOT_EXECUTED.json'","NS+'market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json'"),
('d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f','c0a57be99104c703df9ef876a7168821497a448242c2acc86457acae4c32169a'),
('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','CURRENT5D6C_SINGLE_MARKET_RENDER_TEXTURE_EXACT25_NOT_STAGE')]
for a,b in changes:assert a in text,a;text=text.replace(a,b)
exec(compile(text,str(N/'prepare_Market_ground25_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_Market_ground25_metadata_DERIVED_NOTENGINE.py')})
