"""One reviewed31 closure specialization for current81C: three payloads, one mask, two portal pairs."""
from pathlib import Path
import argparse,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/'
ap=argparse.ArgumentParser()
for name in ['promotion','trial']:
 ap.add_argument('--'+name,required=True);ap.add_argument('--'+name+'-sha256',required=True)
a=vars(ap.parse_args())
t=(N/'prepare_Estate_wall_source31_code_NOTENGINE.py').read_text(encoding='utf8').replace('get_grouped_opcodes(2)','get_grouped_opcodes(12)')
def change(x,y):
 global t
 assert t.count(x)==1,(x[:100],t.count(x));t=t.replace(x,y,1)
change("B=S+'Estate_wall_source_repair01/';P=B+'closure_READY01/';O=N/'Estate_wall_source_repair01/closure_READY01'","B=S+'exit_wall_repair_20261027b01/';P=B+'closure_READY01/';O=N/'exit_wall_repair_20261027b01/closure_READY01'")
x=t.index('scopepin=dict(');y=t.index('\ndef out(',x)
t=t[:x]+'''scopepin=dict(path=B+'current_81C_exact31_scope_PREPARATION.json',sha256='bb8f69b611461f35f10a32caf6486d658f14c2c406f83adb61dd18be9e2359c7');scope=load(scopepin)
old=load(scope['parent_descriptor']);sealold=load(load(scope['strict_full31_descriptor'])['seal']);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']};data={};records={}
''' +t[y:]
change(" assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))"," if name.endswith('.gd'):b=b.rstrip(bytes([10]))+bytes([10])\n assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))")
x=t.index('tuplepin=dict(');y=t.index("rb=read(sealold['runtime'])",x)
chunk='''SYS='res://build/luoyang_exit_wall_fix_20261027b_system01/'
pubpin=dict(path=SYS+'ROOT_READY01/output/108580/result.json',sha256='8f14b9bf11ce635fe037e3cb9689a59052bbc04653dc6861bd99740375d7fb2e');pub=load(pubpin);assert pub['passed']is True and not pub['errors']and len(pub['components'])==3
trial=TRIAL_PIN;tv=load(trial);assert tv['admitted']is True and tv['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'
promotion=PROMOTION_PIN;mp=load(promotion);assert mp['passed']is True and len(mp['written'])==2
inputpin=dict(path=SYS+'input_NOTREADY.json',sha256='fd5069204b51595e7c0f5ca8f6a8459539e27dd85fac07ffe8bada45bf836848');fixedinput=load(inputpin)
binding=load(sealold['binding']);priorbinding=copy.deepcopy(binding)
for id,result in pub['components'].items():
 row=binding['scenes'][id];row['payload']=result['payload'];row['fingerprints']=result['fingerprints'];row['publication_completion']=pubpin
 row['trial']={**row['trial'],**trial,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False}
 required=row['required_source_sha256']
 for pin in [pubpin,result['payload'],trial,inputpin]:required[pin['path']]=pin['sha256']
 if id=='ch4_s3_luoyang_market':
  import re
  m=result['mask'];side=m['path']+'.import';sr=next(r for r in mp['written']if r['path']==side)
  cp=re.findall(r'^path(?:\\.[A-Za-z0-9_]+)?="(res://[^"\\r\\n]+)"\\r?$',read(dict(path=side,sha256=sr['sha256'])).decode(),re.M);assert len(cp)==1
  cr=next(r for r in mp['written']if r['path']==cp[0]);row['mask']={**m,'kind':'IMPORTED_RGBA8','import_path':side,'compiled_path':cp[0]}
  for pin in [m,promotion,{'path':sr['path'],'sha256':sr['sha256']},{'path':cr['path'],'sha256':cr['sha256']}]:required[pin['path']]=pin['sha256']
  for p,h in fixedinput['sources'].items():
   if p.endswith('v13_gate_west_plot_wall_1.png')or p.endswith('v13_gate_west_plot_wall_1.png.import')or ('v13_gate_west_plot_wall_1.png-'in p and p.endswith('.ctex')):read(dict(path=p,sha256=h));required[p]=h
  required[fixedinput['art']['path']]=fixedinput['art']['sha256']
 assert row['required_original_source_sha256']==priorbinding['scenes'][id]['required_original_source_sha256']
for id in binding['scenes']:
 if id not in pub['components']:assert binding['scenes'][id]==priorbinding['scenes'][id]
bind=out('finish8_binding_READY.json',enc(binding))
runtimefunctional=dict(path=SYS+'finish8_runtime_portals_CANDIDATE.gd',sha256='840daeabf655888fc032e4b16a45a11ed985459b4f77b804d1ff078a52206f17')
runtimeproof=dict(path=SYS+'runtime_portal_whole_inverse_BUILD.json',sha256='c0e6bc58b9a295dd1fadda5b4f4e40e2b12b2301252b71cad1b0d171aa8f4b18');load(runtimeproof)
'''
for key,arg in [('TRIAL_PIN','trial'),('PROMOTION_PIN','promotion')]:chunk=chunk.replace(key,repr(dict(path=a[arg],sha256=a[arg+'_sha256'])))
t=t[:x]+chunk+t[y:]
change("rb=read(sealold['runtime'])","rb=read(runtimefunctional)")
x=t.index('helperparent=dict(');y=t.index("materialold=sealold['material_helper']",x)
t=t[:x]+'''record(F,'Field_READY.gd',runtime_head(read(parents[F])))
record(C,'C_READY.gd',runtime_head(read(parents[C])));record(Q,'luoyang_quarters_family_20261022ap.gd',runtime_head(read(parents[Q])));record(E,'luoyang_estate_family_20261021am.gd',runtime_head(read(parents[E])))
''' +t[y:]
change("materialold=sealold['material_helper'];mb=runtime_head(read(materialold))","materialold=sealold['material_helper'];mb=runtime_head(read(materialold));mb=exact(mb,'b33c0c0e6e0542606e28f32b1875a0d216e5b8904b942957101370429783b773',pub['components']['luoyang_artisan_residential_20261022ap']['payload']['sha256'])")
change("e53code=load(dict(path=S+'visible_doors_boundaries33_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='e39fe38edd9c84955c04ff66904f5ccec1f1fd61ab852133c3b0def41b92f5cd'))","e53code=load(load(scope['strict_full31_descriptor'])['code_proof'])")
change("b=helper_head(runtime_head(read(parents[T])))","b=runtime_head(read(parents[T]))")
change("len(prior['source_sha256'])==229","len(prior['source_sha256'])==264")
change("len(new['source_sha256'])==235","len(new['source_sha256'])==270")
change('old_proof_count=229,new_proof_count=235','old_proof_count=264,new_proof_count=270')
change('old229_values_all_edges_retained=True','old264_values_all_edges_retained=True')
x=t.index('seal=copy.deepcopy(sealold)');y=t.index('assert len(records)==9',x)
t=t[:x]+'''seal=copy.deepcopy(sealold)
seal.update(status='ROOT_APPROVED_YAMEN_ARTISAN_PORTALS_AND_MARKET_ADULT_WALL_SOURCE_NOT_FIELD_RESULT',runtime=runtime,binding=bind,Field=records[F]['candidate'],material_helper=material,Root_trial=trial,records={p:r for p,r in records.items()if p in [C,Q,E,ENV,T]},binding_inverse=dict(parent=sealold['binding'],candidate=bind,hunks=hunks(read(sealold['binding']),enc(binding)),only_three_changed_scene_rows=list(pub['components'])),runtime_seal=dict(parent=runtimefunctional,candidate=runtime,hunks=hunks(read(runtimefunctional),rb),only_SELF_BIND_path_SHA_headers=True,functions_identical_to_approved_two_pair_successor=True),material_seal=dict(parent=materialold,candidate=material,hunks=hunks(read(materialold),value(material)),only_published_payload_SHA_and_runtime_BIND_headers=True,all_algorithms_preserved=True),Portal_wall_publication=pubpin,Market_mask_promotion=promotion,runtime_function_proof=runtimeproof,material_only_payload_SHA_and_runtime_BIND_headers=True,all_other_scenes_payloads_masks_actors_geometry_unchanged=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal));codepin=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT_81C_EXIT_WALL_EXACT31_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,parent_descriptor=scope['parent_descriptor'],runtime_function_proof=runtimeproof,publication=pubpin,mask_promotion=promotion,root_trial=trial,engine_calls=0,Stage_calls=0,canonical_writes=0)))
''' +t[y:]
change("helper=helper,Field=records[F]['candidate']","material=material,Field=records[F]['candidate']")
exec(compile(t,str(N/'prepare_exit_wall31_code_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_exit_wall31_code_DERIVED_NOTENGINE.py')})
