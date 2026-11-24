"""Reviewed31 closure specialization; awaits one actual batch, six-mask promotion and strict Artisan helper."""
from pathlib import Path
import argparse
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/'
ap=argparse.ArgumentParser()
for name in ['publication','promotion','material','env','material-proof']:
 ap.add_argument('--'+name,required=True);ap.add_argument('--'+name+'-sha256',required=True)
args=vars(ap.parse_args())
t=(N/'prepare_Estate_wall_source31_code_NOTENGINE.py').read_text(encoding='utf8').replace('get_grouped_opcodes(2)','get_grouped_opcodes(12)')
def change(a,b):
 global t
 assert t.count(a)==1,(a[:100],t.count(a));t=t.replace(a,b,1)
change("B=S+'Estate_wall_source_repair01/';P=B+'closure_READY01/';O=N/'Estate_wall_source_repair01/closure_READY01'","B=S+'seven_fields_layout_repair01/';P=B+'closure_READY01/';O=N/'seven_fields_layout_repair01/closure_READY01'")
a=t.index('scopepin=dict(');z=t.index('\ndef out(',a)
t=t[:a]+'''scopepin=dict(path=B+'current_DFCF_exact31_scope_PREPARATION.json',sha256='c2fbb7dca13b28548199cdf06872cd8933afe03d7c11ca6ee1935258ebb70818');scope=load(scopepin)
currentpin=dict(path=S+'market_living_street_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='60f7504c23c9bfa98e8d8c8e436bd72da29c9a640c28b4c9003610c8a597b485');old=load(currentpin);sealold=load(old['seal']);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']};data={};records={}
''' +t[z:]
a=t.index('tuplepin=dict(');z=t.index("rb=read(sealold['runtime'])",a)
chunk='''SYS='res://build/luoyang_seven_fields_layout_20261026c_system01/'
pubpin=PUBLICATION_PIN;pub=load(pubpin);assert pub['passed'] is True and not pub['errors'] and len(pub['scenes'])==8
trial=dict(path=S+'finish8_ROOT_TRIAL_PERMISSION05.json',sha256='772cff2bc2c3199df2026427dd3f2bc7a022b9bb090a1bda7a9be46ed0d1b581');tv=load(trial);assert tv['admitted'] is True
promotion=PROMOTION_PIN;mp=load(promotion);assert mp['passed'] is True and len(mp['written'])==12
authpin=dict(path=SYS+'author_seven_fields_NOTREADY.json',sha256='e624a5e578f92fadbe2be2407d6b09be33d8e6b514c24aa99c3f59a9427b1845');author=load(authpin);assert len(author['scenes'])==7
routepin=dict(path=SYS+'author_two_routes_NOTREADY.json',sha256='4ea72850b9dcee3ef5f446385f9381a8fe5f2a9eae5e319cfc4e4ca9a0ffdefa');routeauthor=load(routepin)
assert routeauthor['assets']==author['assets'] and all(routeauthor['scenes'][id]['placements']==author['scenes'][id]['placements']for id in author['scenes'])
binding=load(sealold['binding']);priorbinding=copy.deepcopy(binding);parentstage=load(scope['parent_stage']);inherited={}
for node in parentstage['nodes'].values():
 if isinstance(node,dict) and isinstance(node.get('value'),dict):
  for p,h in node['value'].get('source_sha256',{}).items():assert p not in inherited or inherited[p]==h;inherited[p]=h
import re
for id,result in pub['scenes'].items():
 row=binding['scenes'][id];before=priorbinding['scenes'][id]
 if id!='ch4_s3_luoyang_market':assert result['parent_payload']==before['payload']
 row['payload']=result['payload'];row['fingerprints']=result['fingerprints'];row['publication_completion']=pubpin
 row['trial']={**row['trial'],**trial,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False}
 required=row['required_source_sha256']
 for pin in [pubpin,trial,result['payload'],pub['inherited_report']]:required[pin['path']]=pin['sha256']
 if id=='ch4_s3_luoyang_market':
  assert result['only_changed_field']=='npc_migrations' and result['six_street_instances_material_mask_unchanged']is True and result['mask']==before['mask']
  assert {k:h for k,h in result['fingerprints'].items()if k!='npc_migrations'}=={k:h for k,h in before['fingerprints'].items()if k!='npc_migrations'}
 elif id=='ch4_s4_ancient_temple':
  assert result['mask']=={'kind':'SOURCE_POLYGON_ONLY'} and before['mask']['kind']=='SOURCE_POLYGON_ONLY'
 else:
  m=result['mask'];side=m['path']+'.import';sr=next(r for r in mp['written']if r['path']==side)
  remaps=re.findall(r'^path(?:\\.[A-Za-z0-9_]+)?="(res://[^"\\r\\n]+)"\\r?$',read(dict(path=side,sha256=sr['sha256'])).decode(),re.M);assert len(remaps)==1;ctex=remaps[0];assert ctex.startswith('res://.godot/imported/')
  leaves=[sr,next(r for r in mp['written']if r['path']==ctex)]
  row['mask']={**m,'kind':'IMPORTED_RGBA8','import_path':side,'compiled_path':ctex}
  required[m['path']]=m['sha256'];required[promotion['path']]=promotion['sha256']
  for r in leaves:required[r['path']]=r['sha256'];read(dict(path=r['path'],sha256=r['sha256']))
 if id in author['scenes']:
  required[authpin['path']]=authpin['sha256']
  if id in pub['recomputed_scene_ids']:required[routepin['path']]=routepin['sha256']
  for placement in author['scenes'][id]['placements']:
   asset=author['assets'][placement['asset_id']];p=asset['texture'];side=p+'.import';assert inherited[p]==asset['source_sha256'].lower()
   required[p]=inherited[p];required[side]=inherited[side]
   for cp in re.findall(r'^path(?:\\.[A-Za-z0-9_]+)?="(res://[^"\\r\\n]+)"\\r?$',read(dict(path=side,sha256=inherited[side])).decode(),re.M):required[cp]=inherited[cp]
  row['seven_layout_source_successor']={'actual':pubpin,'author':authpin,'added_ids':result['added_ids'],'old_independent_prior_scope':'retained original geometry only; new bodies are finite source-publication credit, not actual Field or whole-city ART pass','actual_Field_pass':False}
 assert row['required_original_source_sha256']==before['required_original_source_sha256'] and row['world_size_px']==before['world_size_px']
bind=out('finish8_binding_READY.json',enc(binding))
'''
import json
for key,arg in [('PUBLICATION_PIN','publication'),('PROMOTION_PIN','promotion')]:chunk=chunk.replace(key,repr(dict(path=args[arg],sha256=args[arg+'_sha256'])))
t=t[:a]+chunk+t[z:]
a=t.index('helperparent=dict(');z=t.index("materialold=sealold['material_helper']",a)
t=t[:a]+'''record(F,'Field_READY.gd',runtime_head(read(parents[F])))
record(C,'C_READY.gd',runtime_head(read(parents[C])));record(Q,'luoyang_quarters_family_20261022ap.gd',runtime_head(read(parents[Q])));record(E,'luoyang_estate_family_20261021am.gd',runtime_head(read(parents[E])))
''' +t[z:]
change("materialold=sealold['material_helper'];mb=runtime_head(read(materialold))","materialold=sealold['material_helper'];materialfunctional="+repr(dict(path=args['material'],sha256=args['material_sha256']))+";materialproof="+repr(dict(path=args['material_proof'],sha256=args['material_proof_sha256']))+";load(materialproof);mb=runtime_head(read(materialfunctional))")
change("material=out('material_runtime_finish139_READY.gd',mb);eb=runtime_head(read(parents[ENV]))","material=out('material_runtime_finish139_READY.gd',mb);envfunctional="+repr(dict(path=args['env'],sha256=args['env_sha256']))+";eb=runtime_head(read(envfunctional))")
change("[(materialold['path'],material['path']),(materialold['sha256'],material['sha256'])]","[(materialfunctional['path'],material['path']),(materialfunctional['sha256'],material['sha256'])]")
change("e53code=load(dict(path=S+'visible_doors_boundaries33_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='e39fe38edd9c84955c04ff66904f5ccec1f1fd61ab852133c3b0def41b92f5cd'))","e53code=load(old['code_proof'])")
change("b=helper_head(runtime_head(read(parents[T])))","b=runtime_head(read(parents[T]))")
change("len(prior['source_sha256'])==229","len(prior['source_sha256'])==252")
change("len(new['source_sha256'])==235","len(new['source_sha256'])==258")
change("old_proof_count=229,new_proof_count=235","old_proof_count=252,new_proof_count=258")
change("old229_values_all_edges_retained=True","old252_values_all_edges_retained=True")
a=t.index('seal=copy.deepcopy(sealold)');z=t.index("assert len(records)==9",a)
t=t[:a]+'''seal=copy.deepcopy(sealold)
seal.update(status='ROOT_APPROVED_SEVEN_FIELD_CONTENT_AND_ONLY_MARKET_PATROL_SOURCE_NOT_FIELD_RESULT',runtime=runtime,binding=bind,Field=records[F]['candidate'],material_helper=material,Root_trial=trial,records={p:r for p,r in records.items()if p in [C,Q,E,ENV,T]},binding_inverse=dict(parent=sealold['binding'],candidate=bind,hunks=hunks(read(sealold['binding']),enc(binding)),seven_content_rows_and_one_Market_migration=True),runtime_seal=dict(parent=sealold['runtime'],candidate=runtime,hunks=hunks(read(sealold['runtime']),rb),only_SELF_BIND_path_SHA_headers=True,all_functions_unchanged=True),Seven_publication=pubpin,Six_mask_promotion=promotion,Artisan_material_function_proof=materialproof,material_functional_parent=materialfunctional,ENV_functional_parent=envfunctional,Field_pawn_bodies_and_prior_receipt_functions_unchanged=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal));codepin=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT_DFCF_SEVEN_FIELD_CONTENT_CLOSURE_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,parent_descriptor=currentpin,material_function_proof=materialproof,publication=pubpin,mask_promotion=promotion,root_trial=trial,engine_calls=0,Stage_calls=0,canonical_writes=0)))
''' +t[z:]
change("helper=helper,Field=records[F]['candidate']","material=material,Field=records[F]['candidate']")
exec(compile(t,str(N/'prepare_seven_fields31_code_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_seven_fields31_code_DERIVED_NOTENGINE.py')})
