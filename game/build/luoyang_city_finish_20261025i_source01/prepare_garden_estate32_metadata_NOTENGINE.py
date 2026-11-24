"""Existing full metadata/maps projection; one Garden data delta and original Router lifecycle successor."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_exit_wall31_metadata_NOTENGINE.py').read_text(encoding='utf8')
for a,b in [('exit_wall_repair_20261027b01/','garden_estate_exit_repair_20261027c01/'),('current_81C_exact31_scope_PREPARATION.json','current_CE38_exact32_scope_PREPARATION.json'),('bb8f69b611461f35f10a32caf6486d658f14c2c406f83adb61dd18be9e2359c7','3d847a210c3ef7fdfa3aef840f3f067b5019db36e2d46389d47f23b263a0c6f8'),('Field_EOF_adoption01/unified24_READY01/Field_EOF24_all_candidates_and_inverse_NOT_STAGE.json','exit_wall_repair_20261027b01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('7a3f1a441af63c425aad230945fb9ec07dbbe2aa2a3607d3bcfc843111ece993','02f60be34643cbe2d62278dcd85b97ea8798e0874edadf6eb314bc2533df9899'),('current_81C_backup31_ROOT_ACTUAL.json','current_CE38_backup32_ROOT_ACTUAL.json'),('50361a4002319918b2afc17a7f4e65ea4593fec72a1812af4d384e707eb4e567','5137bc82f3a2aee973e47eac2127d4e00c2e310cffe5d83c7a1910dd5359f148'),('CURRENT_81C_EXIT_WALL_EXACT31_NOT_STAGE','CURRENT_CE38_GARDEN_ESTATE_EXACT32_NOT_STAGE')]:
 assert a in t,a;t=t.replace(a,b)
# This is an additional canonical Router function target, not an extra metadata layer.
marker="exec(compile(t,str(N/'prepare_exit_wall31_metadata_DERIVED_NOTENGINE.py')"
addition="t=t.replace('garden_estate_exit_repair_20261027c01/unified31_READY01','garden_estate_exit_repair_20261027c01/unified32_READY01').replace('len(records)==17','len(records)==18').replace('dict(GD=17,JSON=14,total=31)','dict(GD=18,JSON=14,total=32)')\n"
assert t.count(marker)==1;t=t.replace(marker,addition+marker)
exec(compile(t,str(N/'prepare_garden_estate32_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_garden_estate32_metadata_DERIVED_NOTENGINE.py')})
