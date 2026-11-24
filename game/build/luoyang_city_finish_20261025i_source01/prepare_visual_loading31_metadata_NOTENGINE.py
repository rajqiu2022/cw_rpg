"""Derive the reviewed finite source-expression model from current F67E, no Stage."""
from pathlib import Path
N=Path(__file__).resolve().parent
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'family_visual_material_loading_repair01/';C=P+'closure_READY01/'
t=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf-8')
changes=[
 ('unified32_READY01','family_visual_material_loading_repair01/unified31_READY01'),
 ("PREFIX=NS+OUT.name+'/'","PREFIX=NS+'family_visual_material_loading_repair01/unified31_READY01/'"),
 ("NS+'finish8_existing_target_scope32_PREPARATION.json'","'"+P+"current_F67E_exact31_scope_PREPARATION.json'"),
 ('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589','b9a60746fe3ed3e12144d88746512b6e609b6262bd7784a4b68421a22654ba07'),
 ('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',S+'culture_Router_pin_repair01/unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e','85ca1a489a550bde0b410888110c77f322ef6e9f0464a45c7e407fddc2aa4976'),
 ("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'","'"+C+"code_execution_all_whole_inverse_NOT_STAGE.json'"),
 ('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200','987a3e67884af6e4c91fbd2890820e19238353066083b03c130782e7aff3090c'),
 ("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'","'"+C+"runtime_consumers_mechanical_seal_whole_inverse_READY.json'"),
 ('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa','b56fae98ffaa997b883edd6bc46f3122140cb122f84415874c8a6cc297edc87d'),
 ("if k!='gate':merge(v,room)","if k!='gate':merge(v,room)\n if k=='artisan':merge(v,{seal['material_helper']['path']:seal['material_helper']['sha256']})"),
 ("meta('estate_final');meta('quarter_final')","meta('estate_final')"),
 ("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),
 ("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),
 ("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),
 ('len(records)==18','len(records)==17'),('dict(GD=18,JSON=14,total=32)','dict(GD=17,JSON=14,total=31)'),
 ("NS+'immutable_current32_ROOT_EXECUTED.json'","'"+P+"current_F67E_backup31_ROOT_ACTUAL.json'"),
 ('d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f','a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9'),
 ('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','F67E_THREE_VISUAL_BRIDGES_AND_LOADING_NPC_EXACT31_NOT_STAGE'),
]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
exec(compile(t,str(N/'prepare_visual_loading31_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_visual_loading31_metadata_DERIVED_NOTENGINE.py')})
