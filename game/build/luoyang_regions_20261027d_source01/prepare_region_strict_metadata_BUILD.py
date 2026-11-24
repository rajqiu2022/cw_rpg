"""Current mature metadata/map projection, with final NEW Region source leaves."""
from pathlib import Path
import argparse, hashlib, json
N = Path(__file__).resolve().parent
G = N.parents[1]
S = G / 'build/luoyang_city_finish_20261025i_source01'
ap = argparse.ArgumentParser(); ap.add_argument('--region-declarations', required=True); ap.add_argument('--region-declarations-sha256', required=True); args = ap.parse_args()
sha = lambda raw: hashlib.sha256(raw).hexdigest()
B = 'res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/'
C = B + 'closure_READY01/'
def pin(path):
    raw = path.read_bytes(); return {'path': 'res://' + path.relative_to(G).as_posix(), 'sha256': sha(raw)}
code_pin = pin(S / 'region_integration_20261027d01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json')
seal_pin = pin(S / 'region_integration_20261027d01/closure_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json')
scope = json.loads((S / 'region_integration_20261027d01/current_01656_exact32_scope_PREPARATION.json').read_bytes())
descriptor_pin = scope['parent_descriptor']
text = (S / 'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf8')
def change(before, after):
    global text
    assert text.count(before) == 1, before[:110]
    text = text.replace(before, after, 1)
change("OUT=N/'unified32_READY01';PREFIX=NS+OUT.name+'/'", "OUT=N/'region_integration_20261027d01/unified32_READY01';PREFIX=NS+'region_integration_20261027d01/unified32_READY01/'")
start = text.index('scopepin=dict('); end = text.index('\nparents=', start)
text = text[:start] + "scopepin=dict(path=" + repr(B + 'current_01656_exact32_scope_PREPARATION.json') + ",sha256='1db5759bfd8ae094f8f5a7b623a55927d285d1f63cdccb378a811ddb49732494');scope=load(scopepin)" + text[end:]
start = text.index('oldpin=dict('); end = text.index('\nbinding=', start)
text = text[:start] + 'oldpin=' + repr(descriptor_pin) + ';oldbundle=load(oldpin)\ncodepin=' + repr(code_pin) + ';code=load(codepin)\nsealpin=' + repr(seal_pin) + ';seal=load(sealpin)' + text[end:]
change("adapter=dict(path=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd',sha256='9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5')", "adapter=seal['adapter']")
change("for table in [ambient,env,room,extra,ordinary,*scopes.values()]:", "region_declarations=load(" + repr({'path': args.region_declarations, 'sha256': args.region_declarations_sha256}) + ")['source_sha256']\nfor table in [ambient,env,room,extra,ordinary,*scopes.values(),*seal['wing_source_entrypoints'].values(),region_declarations]:")
change("if k!='gate':merge(v,room)", "if k!='gate':merge(v,room)\n merge(v,region_declarations)\n if k=='artisan':merge(v,{seal['material_helper']['path']:seal['material_helper']['sha256']})\n if k in seal['wing_source_entrypoints']:merge(v,seal['wing_source_entrypoints'][k])")
change("if k in ['docks','market']:merge(v,scopes['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})", "if k in ['docks','market']:merge(v,scopes['temple']);merge(v,seal['wing_source_entrypoints']['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})")
change("meta('estate_final');meta('quarter_final')", "meta('estate_final')")
change("'ap_execution_index','ap_quarter_index']", "'ap_execution_index']")
change("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')", "meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')")
change("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:", "if ident in ['market_final','finite08_market']:")
change("root_backup=dict(path=NS+'immutable_current32_ROOT_EXECUTED.json',sha256='d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f')", "root_backup=dict(path=" + repr(B + 'current_01656_backup32_ROOT_ACTUAL.json') + ",sha256='5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1')")
change("trial=load(seal['binding'])['scenes'][ids['gate']]['trial']", "trial=seal['Root_trial']")
change("status='EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE'", "status='ROOT08_REGION_AND_GATE_EXACT32_PREPARED_NOT_STAGE'")
change('original_native_registry_Router_DT_unchanged=True', 'original_native_registry_DT_and_all_other_payloads_unchanged=True')
compile(text, 'region_metadata_DERIVED_BUILD.py', 'exec')
exec(compile(text, str(S / 'region_metadata_DERIVED_BUILD.py'), 'exec'), {'__file__': str(S / 'region_metadata_DERIVED_BUILD.py')})
