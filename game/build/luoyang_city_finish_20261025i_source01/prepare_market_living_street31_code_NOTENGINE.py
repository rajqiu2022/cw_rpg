"""Current AAF six-instance Market data and necessary literal-source closure. BUILD only."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'market_living_street_repair01/';P=B+'closure_READY01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
t=(N/'prepare_Estate_wall_source31_code_NOTENGINE.py').read_text(encoding='utf8')
t=t.replace('get_grouped_opcodes(2)','get_grouped_opcodes(12)')
def change(a,b):
 global t
 assert t.count(a)==1,(a[:90],t.count(a));t=t.replace(a,b,1)
change("B=S+'Estate_wall_source_repair01/';P=B+'closure_READY01/';O=N/'Estate_wall_source_repair01/closure_READY01'","B=S+'market_living_street_repair01/';P=B+'closure_READY01/';O=N/'market_living_street_repair01/closure_READY01'")
a=t.index('scopepin=dict(');z=t.index('\ndef out(',a)
t=t[:a]+'''scopepin=dict(path=B+'current_AAF_exact31_scope_PREPARATION.json',sha256='fc3aaa0ad232d603d64eefba0d691d46d9d2a3cede67c83edc3a6d1e08a01a54');scope=load(scopepin)
currentpin=dict(path=S+'pawnshop_collision_Gbinding_repair01/unified25_READY01/pawn_Gbinding25_all_candidates_and_inverse_NOT_STAGE.json',sha256='4e8f536f2517ff331f376bac871bd26a0d33cc87e29f5a7230a889d6b534ece4');old=load(currentpin)
original=load(dict(path=S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54'))
sealold=load(original['seal']);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']};data={};records={}
''' +t[z:]
a=t.index('tuplepin=dict(');z=t.index("rb=read(sealold['runtime'])",a)
t=t[:a]+'''SYS='res://build/luoyang_market_workcourts_20261026b_system01/'
pubpin=dict(path=SYS+'ROOT_READY01/output/80492/result.json',sha256='aacb4919b73fdab6f71de5a6606c9b279a992684c8b415f6b6048da61d3256cd');pub=load(pubpin)
assert pub['passed'] is True and pub['checks']==741 and not pub['errors'] and len(pub['added_ids'])==6
trial=dict(path=S+'finish8_ROOT_TRIAL_PERMISSION04.json',sha256='273434a5e551f8ff755c3beccb02d21227a3e6283d1dc56521527dce3cd24d36');tv=load(trial);assert tv['admitted'] is True
promotionpath=SYS+'mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
promotion=dict(path=promotionpath,sha256='255425f3be0b07fbf7dee8d8063152b25d97bf08ca7c88c1a4a5b22fbd595506');mpbytes=read(promotion);mp=json.loads(mpbytes);assert mp['passed'] is True and len(mp['written'])==2
# These two exact values are the Root actual promotion parameters, never inferred from current media.
for r in mp['written']:read(dict(path=r['path'],sha256=r['sha256']))
binding=load(sealold['binding']);priorbinding=copy.deepcopy(binding);row=binding['scenes']['ch4_s3_luoyang_market']
row['payload']=pub['payload'];row['fingerprints']=pub['fingerprints'];row['publication_completion']=pubpin
row['mask']={**row['mask'],**pub['mask'],'import_path':pub['mask']['path']+'.import','compiled_path':'res://.godot/imported/walk_overlay.png-38720307df236670d7b93cdb4bab527c.ctex'}
row['trial']={**row['trial'],**trial,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False}
authpin=dict(path=SYS+'author_living_street01_NOTREADY.json',sha256='f40371999db51688c2c4f71bf4a7362161f1446f2539e7447389b7c826cf8ceb');author=load(authpin)
layoutproof=dict(path=SYS+'material_street02_direct_whole_inverse_BUILD.json',sha256='f466b0d3779009f684563804cc1aa3e43107031bb4be12ad2270e2c8c11c25c9');load(layoutproof)
required=row['required_source_sha256']
for pin in [pubpin,trial,promotion,authpin,pub['payload'],pub['mask']]:required[pin['path']]=pin['sha256']
for r in mp['written']:required[r['path']]=r['sha256']
assert set(r['path']for r in mp['written'])=={row['mask']['import_path'],row['mask']['compiled_path']}
# All five asset PNG/import/ctex tuples are inherited from the frozen AAF Market map.
parentstage=load(scope['parent_stage']);marketmap=parentstage['nodes']['expected_ch4_s3_luoyang_market_true']['value']['source_sha256']
for asset in author['assets'].values() if isinstance(author['assets'],dict) else author['assets']:
 png=asset.get('texture',asset.get('texture_path',asset.get('path','')))
 if not png:continue
 assert png in marketmap,('INHERITED_ASSET',png)
 required[png]=marketmap[png];side=png+'.import';required[side]=marketmap[side]
 import re
 for cp in re.findall(r'^path(?:\\.[A-Za-z0-9_]+)?="(res://[^"\\r\\n]+)"\\r?$',read(dict(path=side,sha256=marketmap[side])).decode(),re.M):required[cp]=marketmap[cp]
for scene in binding['scenes']:
 if scene!='ch4_s3_luoyang_market':assert binding['scenes'][scene]==priorbinding['scenes'][scene]
row['market_street_source_successor']={'actual':pubpin,'author':authpin,'six_ids':pub['added_ids'],'new_domain_pixels':pub['changed_domain_pixels'],'old_independent_prior_scope':'retained original geometry only; six new bodies are source-publication credit, not independent QA or Field pass','actual_Field_pass':False}
bind=out('finish8_binding_READY.json',enc(binding))
''' +t[z:]
a=t.index('helperparent=dict(');z=t.index("materialold=sealold['material_helper']",a)
t=t[:a]+'''record(F,'Field_READY.gd',runtime_head(read(parents[F])))
record(C,'C_READY.gd',runtime_head(read(parents[C])));record(Q,'luoyang_quarters_family_20261022ap.gd',runtime_head(read(parents[Q])));record(E,'luoyang_estate_family_20261021am.gd',runtime_head(read(parents[E])))
''' +t[z:]
change("material=out('material_runtime_finish139_READY.gd',mb);eb=runtime_head(read(parents[ENV]))","material=out('material_runtime_finish139_READY.gd',mb);envfunctional=dict(path=SYS+'ENV_street02_CANDIDATE.gd',sha256='1c4812a9e9d80f9f9c532b0e3621953bd15ac29ff3c3dd02f59ee05ebd945bf0');eb=runtime_head(read(envfunctional))")
change("e53code=load(dict(path=S+'visible_doors_boundaries33_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='e39fe38edd9c84955c04ff66904f5ccec1f1fd61ab852133c3b0def41b92f5cd'))","e53code=load(original['code_proof'])")
change("b=helper_head(runtime_head(read(parents[T])))","b=runtime_head(read(parents[T]))")
change("len(prior['source_sha256'])==229","len(prior['source_sha256'])==246")
change("len(new['source_sha256'])==235","len(new['source_sha256'])==252")
change("old_proof_count=229,new_proof_count=235","old_proof_count=246,new_proof_count=252")
change("old229_values_all_edges_retained=True","old246_values_all_edges_retained=True")
a=t.index('seal=copy.deepcopy(sealold)');z=t.index("assert len(records)==9",a)
t=t[:a]+'''seal=copy.deepcopy(sealold)
seal.update(status='ROOT_APPROVED_MARKET_SIX_INSTANCES_SOURCE_ONLY_NOT_FIELD_RESULT',runtime=runtime,binding=bind,Field=records[F]['candidate'],material_helper=material,Root_trial=trial,records={p:r for p,r in records.items()if p in [C,Q,E,ENV,T]},binding_inverse=dict(parent=sealold['binding'],candidate=bind,hunks=hunks(read(sealold['binding']),enc(binding)),only_Market_row_changed=True,other_seven_rows_exactly_unchanged=True),runtime_seal=dict(parent=sealold['runtime'],candidate=runtime,hunks=hunks(read(sealold['runtime']),rb),only_SELF_BIND_path_SHA_headers=True,all_functions_unchanged=True),Market_publication=pubpin,Market_mask_promotion=promotion,Market_material_function_proof=layoutproof,Field_pawn_bodies_and_prior_receipt_functions_unchanged=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal));codepin=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT_AAF_ONLY_MARKET_SIX_INSTANCE_CLOSURE_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,parent_descriptor=currentpin,material_function_proof=layoutproof,publication=pubpin,mask_promotion=promotion,root_trial=trial,engine_calls=0,Stage_calls=0,canonical_writes=0)))
''' +t[z:]
change("scope=scopepin)))","scope=scopepin)))") if False else None
change("helper=helper,Field=records[F]['candidate']","Market_material_helper=dict(path=SYS+'market_purpose_layer_street02_CANDIDATE.gd',sha256='b5dc92f52434ef84b1fed33eeb8cb2e3fac37062ab207c53e557727a4adb24a6'),Field=records[F]['candidate']")
exec(compile(t,str(N/'prepare_market_living_street31_code_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_market_living_street31_code_DERIVED_NOTENGINE.py')})
