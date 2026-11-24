"""Existing31 metadata/maps projection for current81C, with no collector or Stage."""
from pathlib import Path
import hashlib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'exit_wall_repair_20261027b01/'
cp=B+'closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json';sp=B+'closure_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'
digest=lambda p:hashlib.sha256((N/p[len(S):]).read_bytes()).hexdigest()
t=(N/'prepare_market_living_street31_metadata_NOTENGINE.py').read_text(encoding='utf8')
for x,y in [
 ('market_living_street_repair01/','exit_wall_repair_20261027b01/'),('current_AAF_exact31_scope_PREPARATION.json','current_81C_exact31_scope_PREPARATION.json'),('fc3aaa0ad232d603d64eefba0d691d46d9d2a3cede67c83edc3a6d1e08a01a54','bb8f69b611461f35f10a32caf6486d658f14c2c406f83adb61dd18be9e2359c7'),
 ('pawnshop_collision_Gbinding_repair01/unified25_READY01/pawn_Gbinding25_all_candidates_and_inverse_NOT_STAGE.json','Field_EOF_adoption01/unified24_READY01/Field_EOF24_all_candidates_and_inverse_NOT_STAGE.json'),('4e8f536f2517ff331f376bac871bd26a0d33cc87e29f5a7230a889d6b534ece4','7a3f1a441af63c425aad230945fb9ec07dbbe2aa2a3607d3bcfc843111ece993'),
 ('current_AAF_backup31_ROOT_ACTUAL.json','current_81C_backup31_ROOT_ACTUAL.json'),('31970cb86774421e36bca2b520569f2cf17b4c0672f8aeb845abc0eb470eebc0','50361a4002319918b2afc17a7f4e65ea4593fec72a1812af4d384e707eb4e567'),
 ('CURRENT_AAF_MARKET_SIX_INSTANCES_EXACT31_NOT_STAGE','CURRENT_81C_EXIT_WALL_EXACT31_NOT_STAGE')]:
 assert x in t,x;t=t.replace(x,y)
# The reused wrapper computes its own cp/sp pins from these new files, then retains the original maps expression.
exec(compile(t,str(N/'prepare_exit_wall31_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_exit_wall31_metadata_DERIVED_NOTENGINE.py')})
