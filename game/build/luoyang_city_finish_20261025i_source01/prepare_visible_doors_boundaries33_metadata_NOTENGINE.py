"""Reuse the reviewed incremental metadata expression; no collector or Stage."""
from pathlib import Path
import argparse, hashlib

N=Path(__file__).resolve().parent
S='res://build/luoyang_city_finish_20261025i_source01/'
B=S+'visible_doors_boundaries33_repair01/'
C=B+'closure_READY01/'
ap=argparse.ArgumentParser()
ap.add_argument('--code-sha256',required=True)
ap.add_argument('--seal-sha256',required=True)
ap.add_argument('--scope-sha256',required=True)
a=ap.parse_args()
text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf8')
changes=[
 ('unified32_READY01','visible_doors_boundaries33_repair01/unified33_READY02'),
 ("PREFIX=NS+OUT.name+'/'","PREFIX=NS+'visible_doors_boundaries33_repair01/unified33_READY02/'"),
 ("NS+'finish8_existing_target_scope32_PREPARATION.json'",repr(C+'current_signed31_exact33_scope_PREPARATION.json')),
 ('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589',a.scope_sha256),
 ('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',S+'temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json'),
 ('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e','c7896af45a53d8eb45f6bc0f5f6fd794fa40c8999af1757906fa8ec7812a8aa7'),
 ("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'",repr(C+'code_execution_all_whole_inverse_NOT_STAGE.json')),
 ('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200',a.code_sha256),
 ("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'",repr(C+'runtime_consumers_mechanical_seal_whole_inverse_READY.json')),
 ('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',a.seal_sha256),
 ("adapter=dict(path=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd',sha256='9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5')","adapter=seal['adapter']"),
 ("for table in [ambient,env,room,extra,ordinary,*scopes.values()]:","for table in [ambient,env,room,extra,ordinary,*scopes.values(),*seal['wing_source_entrypoints'].values()]:"),
 ("if k!='gate':merge(v,room)","if k!='gate':merge(v,room)\n if k=='artisan':merge(v,{seal['material_helper']['path']:seal['material_helper']['sha256']})\n if k in seal['wing_source_entrypoints']:merge(v,seal['wing_source_entrypoints'][k])"),
 ("if k in ['docks','market']:merge(v,scopes['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})","if k in ['docks','market']:merge(v,scopes['temple']);merge(v,seal['wing_source_entrypoints']['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})"),
 ("meta('estate_final');meta('quarter_final')","meta('estate_final')"),
 ("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),
 ("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),
 ("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),
 ('len(records)==18','len(records)==19'),
 ('dict(GD=18,JSON=14,total=32)','dict(GD=18,JSON=15,total=33)'),
 ("root_backup=dict(path=NS+'immutable_current32_ROOT_EXECUTED.json',sha256='d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f')","root_backup=dict(status='ROOT_CURRENT_SIGNED31_NEW_EXACT33_BACKUP_PENDING_OLD403_PRESERVED')"),
 ('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','CURRENT_SIGNED31_VISIBLE_DOORS_BOUNDARIES_BELL_ONLY_EXACT33_NOT_STAGE'),
]
for old,new in changes:
    assert old in text,old
    text=text.replace(old,new)
# The new existing ENV index has the same pre-existing sole FORMAL_ENABLED gate.
# Its AUTHOR_SHA successor is in code.records; expose the original bool gate too.
marker="meta('estate_final')\nfor ident in"
replacement="""env_index='res://scripts/city/luoyang_environment_index_20261022ap.gd'
env_pin=refs[env_index];on=val(env_pin);enabled='const FORMAL_ENABLED=true';disabled='const FORMAL_ENABLED=false'
assert on.count(enabled.encode())==1 and disabled.encode()not in on
off=out('indexes/ap_environment_index_disabled.gd',exact(on,enabled,disabled))
indexproof[env_index]=dict(id='ap_environment_index',disabled=off,disabled_literal=disabled,enabled_literal=enabled,replacements=[dict(old=parents['res://data/maps/luoyang_full_city_20261022ap/environment.json']['sha256'],new=refs['res://data/maps/luoyang_full_city_20261022ap/environment.json']['sha256'],target='res://data/maps/luoyang_full_city_20261022ap/environment.json')],only_disabled_bool_transition=True)
meta('estate_final')
for ident in"""
assert text.count(marker)==1
text=text.replace(marker,replacement)
# No writes until the original generator's full in-memory inverse and source
# checks finish. Output namespace is new and exclusive.
compile(text,str(N/'prepare_visible_doors_boundaries33_metadata_DERIVED_NOTENGINE.py'),'exec')
exec(compile(text,str(N/'prepare_visible_doors_boundaries33_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_visible_doors_boundaries33_metadata_DERIVED_NOTENGINE.py')})
