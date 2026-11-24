"""Mechanical G-only successor of current2B86; reuse mature22 metadata recipe, no Stage/engine."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_pawnshop22_candidates_NOTENGINE.py').read_text(encoding='utf8')
for a,b in [('pawnshop_only_repair01/','artisan_return_guard_repair01/'),('current_47CC_exact22_scope_PREPARATION.json','current_2B86_exact22_scope_PREPARATION.json'),('85d08f7c5f95a14c725abc0ec6d0d008c3b56f6bf17269dd2658f70d8289a026','2127d8bc78b15404b8c408bccf1b27442dac4f9ed02949337798bac553f7676d'),('Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','seven_fields_layout_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54','c7ac1d0d213c7db851f93157010aeb3672633b57a87e2335bc5e101e2e69102a'),('root_Estate_wall_source_exact31_stage01','root_seven_fields_layout_exact31_stage01'),('bcf570aaf4da648b17612a2d8dd889cffafc8962ec0422313b9689972ed53f39','6b55260a308fbc01a20763ea749b871ddc064b00280c58e51bca0c01892f5c92'),('current_47CC_backup22_ROOT_ACTUAL.json','current_2B86_backup22_ROOT_ACTUAL.json'),('75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639','2a6c3794c3d175a0c2a98a4ce650abf340408a2782f86a131256ea620cd6fbea'),("backup['total_backups']==514","backup['total_backups']==648"),("len(prior['source_sha256'])==235","len(prior['source_sha256'])==258"),('old235_all_values_edges_preserved','old258_all_values_edges_preserved'),('pawnshop22_all_candidates_and_inverse_NOT_STAGE.json','artisan_return22_all_candidates_and_inverse_NOT_STAGE.json'),('PAWNSHOP_ONLY_EXACT22_PREPARED_NOT_STAGE','ARTISAN_EFFECTIVE_RETURN_G_ONLY_EXACT22_PREPARED_NOT_STAGE')]:
 assert a in t,a;t=t.replace(a,b)
a=t.index('function_proof=pin(');z=t.index('prepared={}',a)
t=t[:a]+'''function_proof=pin('res://build/luoyang_seven_fields_layout_20261026c_system01/G_effective_artisan_clearance_whole_inverse_BUILD.json','eab26cb86f6f80a5f7893ed703dedd8301c7408d210733a42339410bb1c2b9e7');load(function_proof)
''' +t[z:]
a=t.index('service_parent=pin(');z=t.index('prior=json.loads(raw(parents[EX]))',a)
t=t[:a]+'''g_parent=pin('res://build/luoyang_seven_fields_layout_20261026c_system01/G_effective_artisan_clearance_CANDIDATE.gd','f8b46e3b3673d32c0d5bbe764cc903d6e102aa11067c99c64ecdb3e248dc5dd3');g_new=raw(g_parent);g=out('G_READY.gd',g_new)
records[G]=dict(parent=parents[G],candidate=g,hunks=hunks(raw(parents[G]),g_new),whole_byte_forward_inverse=True);refs[G]=g
seal=out('G_functional_source_whole_inverse_READY.json',enc(dict(function_proof=function_proof,G_parent=parents[G],G=g,G_hunks=records[G]['hunks'],candidate_functions_exactly_reviewed_F8B46=True,no_mechanical_function_changes=True,canonical_writes=0,engine_calls=0)))
''' +t[z:]
t=t.replace("services={service['path']:service['sha256'],author['path']:author['sha256']}","services={}")
t=t.replace('ordinary=[service,author]','ordinary=[]')
t=t.replace("descriptor=dp,service=service,G=g","descriptor=dp,G=g")
import sys
argv=sys.argv;sys.argv=['derived','--root-approved-mechanical-ready']
try:exec(compile(t,str(N/'prepare_artisan_return22_candidates_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_artisan_return22_candidates_DERIVED_NOTENGINE.py')})
finally:sys.argv=argv
