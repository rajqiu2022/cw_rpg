"""Reuse the reviewed strict old-source sealer; one final Region/Gate successor."""
from pathlib import Path
import argparse, hashlib
N = Path(__file__).resolve().parent
G = N.parents[1]
S = G / 'build/luoyang_city_finish_20261025i_source01'
ap = argparse.ArgumentParser()
ap.add_argument('--manifest', required=True)
ap.add_argument('--manifest-sha256', required=True)
args = ap.parse_args()
text = (S / 'prepare_Estate_wall_source31_code_NOTENGINE.py').read_text(encoding='utf8').replace('get_grouped_opcodes(2)', 'get_grouped_opcodes(12)')
def change(before, after):
    global text
    assert text.count(before) == 1, before[:100]
    text = text.replace(before, after, 1)
change("B=S+'Estate_wall_source_repair01/';P=B+'closure_READY01/';O=N/'Estate_wall_source_repair01/closure_READY01'", "B=S+'region_integration_20261027d01/';P=B+'closure_READY01/';O=N/'region_integration_20261027d01/closure_READY01'")
start = text.index('scopepin=dict('); end = text.index('\ndef out(', start)
text = text[:start] + """scopepin=dict(path=B+'current_01656_exact32_scope_PREPARATION.json',sha256='1db5759bfd8ae094f8f5a7b623a55927d285d1f63cdccb378a811ddb49732494');scope=load(scopepin)
old=load(scope['parent_descriptor']);sealold=load(old['seal']);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']};data={};records={}
""" + text[end:]
change(" assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))", " if name.endswith('.gd'):b=b.rstrip(bytes([10]))+bytes([10])\n assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))")
start = text.index('tuplepin=dict('); end = text.index("rb=read(sealold['runtime'])", start)
insert = '''SYS='res://build/luoyang_city_rectification_20261027d_system01/'
REG='res://build/luoyang_regions_20261027d_source01/'
manifest=MANIFEST_PIN;mv=load(manifest);assert mv['adoption_enabled']is True and len(mv['compiled_bindings'])==9
trial=dict(path=REG+'root_integration_scope08_AUTHORIZED.json',sha256='9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919');tv=load(trial);assert tv['root_authorized']is True and tv['actual_field_pass']is False
pubpath=G/'build/luoyang_city_rectification_20261027d_system01/GATE_REAR_ROOT_READY01/output/82020/result.json';pubpin=dict(path=SYS+'GATE_REAR_ROOT_READY01/output/82020/result.json',sha256=sha(pubpath.read_bytes()));pub=load(pubpin)
assert pub['passed']is True and not pub['errors']and pub['checks']==106 and pub['whole_payload_inverse']is True and pub['whole_RGBA_inverse']is True and pub['source_first']==pub['source_final']
promotionpath=G/'build/luoyang_city_rectification_20261027d_system01/gate_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json';promotion=dict(path=SYS+'gate_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',sha256=sha(promotionpath.read_bytes()));mp=load(promotion);assert mp['passed']is True and len(mp['written'])==2
binding=load(sealold['binding']);priorbinding=copy.deepcopy(binding);id='ch4_s0_luoyang_gate';row=binding['scenes'][id]
row['payload']=pub['payload'];row['fingerprints']=pub['fingerprints'];row['publication_completion']=pubpin
row['trial']={**row['trial'],**trial,'admitted':True,'permission_kind':'TRIAL_PERMISSION_NOT_RESULT','actual_Field_pass':False}
required=row['required_source_sha256']
for pin in [pubpin,pub['payload'],trial,promotion]:required[pin['path']]=pin['sha256']
for p,h in pub['source_first'].items():
 if p not in [sealold['binding']['path']]:required[p]=h
import re
m=pub['mask'];side=m['path']+'.import';sr=next(r for r in mp['written']if r['path']==side)
cp=re.findall(r'^path(?:\\.[A-Za-z0-9_]+)?="(res://[^"\\r\\n]+)"\\r?$',read(dict(path=side,sha256=sr['sha256'])).decode(),re.M);assert len(cp)==1
cr=next(r for r in mp['written']if r['path']==cp[0]);row['mask']={**m,'kind':'IMPORTED_RGBA8','import_path':side,'compiled_path':cp[0]}
for pin in [m,{'path':sr['path'],'sha256':sr['sha256']},{'path':cr['path'],'sha256':cr['sha256']}]:required[pin['path']]=pin['sha256']
assert row['required_original_source_sha256']==priorbinding['scenes'][id]['required_original_source_sha256']
for key in binding['scenes']:
 if key!=id:assert binding['scenes'][key]==priorbinding['scenes'][key]
bind=out('finish8_binding_READY.json',enc(binding))
'''
insert = insert.replace('MANIFEST_PIN', repr({'path': args.manifest, 'sha256': args.manifest_sha256}))
text = text[:start] + insert + text[end:]
start = text.index('helperparent=dict('); end = text.index("materialold=sealold['material_helper']", start)
text = text[:start] + '''hookpin=dict(path=SYS+'gate_supply_Field_hook_PROPOSAL.json',sha256=sha((G/'build/luoyang_city_rectification_20261027d_system01/gate_supply_Field_hook_PROPOSAL.json').read_bytes()));hook=load(hookpin)
fb=read(parents[F]);fb=exact(fb,hook['anchor_before'],hook['insert_before_anchor']+hook['anchor_before']);record(F,'Field_READY.gd',runtime_head(fb))
record(C,'C_READY.gd',runtime_head(read(parents[C])));record(Q,'luoyang_quarters_family_20261022ap.gd',runtime_head(read(parents[Q])));record(E,'luoyang_estate_family_20261021am.gd',runtime_head(read(parents[E])))
R='res://scripts/autoload/scene_router.gd';rp=dict(path=REG+'Router_region_CANDIDATE02.gd',sha256='3b93c208dfe7d362474927c9c8604c5ac8af237e9e0cd377fe650b99789a6545')
rb_router=exact(read(rp),'PENDING_FINAL_AUTHOR_SHA_NOT_ADOPTABLE',manifest['sha256']);record(R,'Router_READY.gd',rb_router)
''' + text[end:]
change("e53code=load(dict(path=S+'visible_doors_boundaries33_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='e39fe38edd9c84955c04ff66904f5ccec1f1fd61ab852133c3b0def41b92f5cd'))", "e53code=load(old['code_proof'])")
change("assert set(ctchanges)=={C,F}and json.loads(b)==v", "assert set(ctchanges)=={C,F,R}and json.loads(b)==v")
change("b=helper_head(runtime_head(read(parents[T])))", "b=runtime_head(read(parents[T]))")
change("len(prior['source_sha256'])==229", "len(prior['source_sha256'])==277")
change("changed=[F,CO,T,AC]", "changed=[F,CO,T,AC,R]")
change("len(extra)==6 and len(new['source_sha256'])==235", "len(extra)==7 and len(new['source_sha256'])==284")
change("old_proof_count=229,new_proof_count=235", "old_proof_count=277,new_proof_count=284")
change("old229_values_all_edges_retained=True", "old277_values_all_edges_retained=True")
start = text.index('seal=copy.deepcopy(sealold)'); end = text.index('assert len(records)==9', start)
text = text[:start] + '''seal=copy.deepcopy(sealold)
seal.update(status='ROOT08_NEW_REGION_AND_EXACT_GATE_NOT_FIELD_ACCEPTANCE',runtime=runtime,binding=bind,Field=records[F]['candidate'],material_helper=material,Root_trial=trial,records={p:r for p,r in records.items()if p in [C,Q,E,ENV,T,R]},binding_inverse=dict(parent=sealold['binding'],candidate=bind,hunks=hunks(read(sealold['binding']),enc(binding)),only_Gate_changed=True,other_seven_rows_identical=True),runtime_seal=dict(parent=sealold['runtime'],candidate=runtime,hunks=hunks(read(sealold['runtime']),rb),only_SELF_BIND_path_SHA_headers=True,all_functions_unchanged=True),Gate_rear_publication=pubpin,Gate_mask_promotion=promotion,Gate_Field_hook=hookpin,region_manifest=manifest,Router_template=rp,source_header_only_other_modules=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal));codepin=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT01656_REGION_AND_GATE_STRICT_SUCCESSOR_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,parent_descriptor=scope['parent_descriptor'],Gate_publication=pubpin,Gate_mask_promotion=promotion,region_manifest=manifest,root_trial=trial,engine_calls=0,Stage_calls=0,canonical_writes=0)))
''' + text[end:]
change('assert len(records)==9', 'assert len(records)==10')
change('helper=helper,Field=records[F][\'candidate\']', 'material=material,Field=records[F][\'candidate\']')
compile(text, 'region_strict_code_DERIVED_BUILD.py', 'exec')
exec(compile(text, str(S / 'region_strict_code_DERIVED_BUILD.py'), 'exec'), {'__file__': str(S / 'region_strict_code_DERIVED_BUILD.py')})
