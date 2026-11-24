"""Reuse the reviewed source closure, only Garden wall retirement and exact Router lifecycle."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_exit_wall31_code_NOTENGINE.py').read_text(encoding='utf8')
def ch(a,b):
 global t
 assert t.count(a)==1,(a[:90],t.count(a));t=t.replace(a,b,1)
ch("['promotion','trial']","['publication','promotion','trial']")
t=t.replace('exit_wall_repair_20261027b01/','garden_estate_exit_repair_20261027c01/')
t=t.replace('current_81C_exact31_scope_PREPARATION.json','current_CE38_exact32_scope_PREPARATION.json').replace('bb8f69b611461f35f10a32caf6486d658f14c2c406f83adb61dd18be9e2359c7','3d847a210c3ef7fdfa3aef840f3f067b5019db36e2d46389d47f23b263a0c6f8')
ch("sealold=load(load(scope['strict_full31_descriptor'])['seal'])","sealold=load(old['seal'])")
x=t.index("chunk='''SYS=");y=t.index("for key,arg in [('TRIAL_PIN'",x)
t=t[:x]+r'''chunk="""SYS='res://build/luoyang_garden_estate_exit_20261027c_system01/'
pubpin=PUBLICATION_PIN;pub=load(pubpin);assert pub['passed']is True and not pub['errors']and pub['whole_payload_inverse']is True and pub['whole_RGBA_inverse']is True
trial=TRIAL_PIN;tv=load(trial);assert tv['admitted']is True and tv['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'
promotion=PROMOTION_PIN;mp=load(promotion);assert mp['passed']is True and len(mp['written'])==2
binding=load(sealold['binding']);priorbinding=copy.deepcopy(binding);id='luoyang_riverside_garden_20261022ap';row=binding['scenes'][id]
row['payload']=pub['payload'];row['fingerprints']=pub['fingerprints'];row['publication_completion']=pubpin
row['trial']={**row['trial'],**trial,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False};required=row['required_source_sha256']
for pin in [pubpin,pub['payload'],trial]:required[pin['path']]=pin['sha256']
import re
m=pub['mask'];side=m['path']+'.import';sr=next(r for r in mp['written']if r['path']==side)
cp=re.findall(r'^path(?:\\.[A-Za-z0-9_]+)?="(res://[^"\\r\\n]+)"\\r?$',read(dict(path=side,sha256=sr['sha256'])).decode(),re.M);assert len(cp)==1
cr=next(r for r in mp['written']if r['path']==cp[0]);row['mask']={**m,'kind':'IMPORTED_RGBA8','import_path':side,'compiled_path':cp[0]}
for pin in [m,promotion,{'path':sr['path'],'sha256':sr['sha256']},{'path':cr['path'],'sha256':cr['sha256']}]:required[pin['path']]=pin['sha256']
art=dict(path='res://build/luoyang_city_finish_20261025i_art01/garden_one_isolated_wall_retire_20261027c_BUILD_ONLY.json',sha256='fd3201293d6c07d877714d3fa2a079624531fc0b7a3126dadef89620b5bfc1f4');load(art);required[art['path']]=art['sha256']
assert row['required_original_source_sha256']==priorbinding['scenes'][id]['required_original_source_sha256']
for key in binding['scenes']:
 if key!=id:assert binding['scenes'][key]==priorbinding['scenes'][key]
bind=out('finish8_binding_READY.json',enc(binding))
runtimefunctional=sealold['runtime']
routerfunctional=dict(path=SYS+'Router_garden_estate_CANDIDATE.gd',sha256='2687a0d72d6bf34654894905b9caf2082c3fdf97e7db4633e518996569d2650c')
runtimeproof=dict(path=SYS+'Router_whole_inverse_BUILD.json',sha256=ROUTER_PROOF_SHA);load(runtimeproof)
"""
''' +t[y:]
ch("[('TRIAL_PIN','trial'),('PROMOTION_PIN','promotion')]","[('PUBLICATION_PIN','publication'),('TRIAL_PIN','trial'),('PROMOTION_PIN','promotion')]")
proof=N.parents[1]/'build/luoyang_garden_estate_exit_20261027c_system01/Router_whole_inverse_BUILD.json'
import hashlib
t=t.replace('sha256=ROUTER_PROOF_SHA','sha256='+repr(hashlib.sha256(proof.read_bytes()).hexdigest()))
ch("mb=runtime_head(read(materialold));mb=exact(mb,'b33c0c0e6e0542606e28f32b1875a0d216e5b8904b942957101370429783b773',pub['components']['luoyang_artisan_residential_20261022ap']['payload']['sha256'])","mb=runtime_head(read(materialold))")
ch("e53code=load(load(scope['strict_full31_descriptor'])['code_proof'])","e53code=load(old['code_proof'])")
marker="change(\"len(prior['source_sha256'])==229\",\"len(prior['source_sha256'])==264\")"
assert marker in t
t=t.replace(marker,"change(\"ed=ordinary_successor(AA,C,'C',runtime_edits);ordinary_successor(AC,AA,'AA',ed)\",\"ed=ordinary_successor(AA,C,'C',runtime_edits);ordinary_successor(AC,AA,'AA',ed)\\nR='res://scripts/autoload/scene_router.gd';record(R,'Router_READY.gd',read(routerfunctional))\")\n"+marker)
t=t.replace('len(prior[\'source_sha256\'])==264','len(prior[\'source_sha256\'])==270').replace('len(new[\'source_sha256\'])==270','len(new[\'source_sha256\'])==277').replace('old_proof_count=264,new_proof_count=270','old_proof_count=270,new_proof_count=277').replace('old264_values_all_edges_retained=True','old270_values_all_edges_retained=True')
marker="x=t.index('seal=copy.deepcopy(sealold)')"
at=t.index(marker)
t=t[:at]+'''change("assert set(ctchanges)=={C,F}and json.loads(b)==v","assert set(ctchanges)=={C,F,R}and json.loads(b)==v")
change("changed=[F,CO,T,AC]","changed=[F,CO,T,AC,R]")
change("len(extra)==6","len(extra)==7")
''' +t[at:]
t=t.replace("ROOT_APPROVED_YAMEN_ARTISAN_PORTALS_AND_MARKET_ADULT_WALL_SOURCE_NOT_FIELD_RESULT","ROOT_APPROVED_GARDEN_ONE_WALL_AND_COLD_ESTATE_LIFECYCLE_NOT_FIELD_RESULT")
t=t.replace("only_three_changed_scene_rows=list(pub['components'])","only_Garden_changed_scene_row=True")
t=t.replace('functions_identical_to_approved_two_pair_successor=True','all_functions_unchanged=True').replace('only_published_payload_SHA_and_runtime_BIND_headers=True','only_runtime_BIND_headers=True')
t=t.replace('Portal_wall_publication=pubpin,Market_mask_promotion=promotion,runtime_function_proof=runtimeproof,material_only_payload_SHA_and_runtime_BIND_headers=True,all_other_scenes_payloads_masks_actors_geometry_unchanged=True','Garden_wall_publication=pubpin,Garden_mask_promotion=promotion,Router_function_proof=runtimeproof,material_only_runtime_BIND_headers=True,all_other_seven_scenes_payloads_masks_actors_geometry_unchanged=True')
t=t.replace('CURRENT_81C_EXIT_WALL_EXACT31_NOT_STAGE','CURRENT_CE38_GARDEN_ESTATE_EXACT32_NOT_STAGE').replace('runtime_function_proof=runtimeproof','Router_function_proof=runtimeproof')
marker="exec(compile(t,str(N/'prepare_exit_wall31_code_DERIVED_NOTENGINE.py')"
assert t.count(marker)==1;t=t.replace(marker,"change('assert len(records)==9','assert len(records)==10')\n"+marker)
exec(compile(t,str(N/'prepare_garden_estate32_code_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_garden_estate32_code_DERIVED_NOTENGINE.py')})
