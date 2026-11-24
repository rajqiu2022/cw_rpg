"""Mechanical specialization of the previously reviewed finite candidate constructor."""
from pathlib import Path
import hashlib,ast,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
old=GAME/'build/luoyang_city_revision_20261024e_source01/prepare_docks31_candidates_BUILD.py'
a=old.read_bytes();assert hashlib.sha256(a).hexdigest()=='dd27468d2f93c9dd2a5812781d47cda0092c1d1bd6cba9a4630a1a5a15fb7ee0'
s=a.decode()
def change(x,y,count=None):
    global s
    assert x in s,x
    if count is not None:assert s.count(x)==count,(x,s.count(x))
    s=s.replace(x,y)
change('NEW fixed-FE154 Docks','NEW fixed9876 courtyard45')
change("S='res://build/luoyang_city_revision_20261024e_source01/'","S='res://build/luoyang_city_revision_20261025g_source01/';OLD='res://build/luoyang_city_revision_20261024e_source01/'")
change("D='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/'","D='res://build/luoyang_market_courtyard_links_20261025g_system01/runtime02_READY/'")
change("OUT=HERE/'docks31_candidates01'","OUT=HERE/'courtyard32_candidates01'")
change("scopepin=dict(path=S+'docks31_scope_PREPARATION.json',sha256='b641239df4f2f3828d37bf3372051d8f1b7b4971ab14c81a3a8dda28be43a092')","scopepin=dict(path=S+'courtyard45_exact32_scope_PREPARATION.json',sha256='823dcc493006e0a439dc4f4caa1ce8a1ad6b029fb9c3e8f847620731defac4d5')")
change("priorpin=dict(path=S+'prewarm_profile29_candidates01/code_execution_whole_inverse_NOT_STAGE.json',sha256='a32ab44edd0a8d3e72409f40ae89a118691b73398cf184761e59f0cf103e6982')","priorpin=dict(path=OLD+'docks31_candidates01/code_execution_whole_inverse_NOT_STAGE.json',sha256='a2dbfb4b89255649df89918c4dba48e71cb0717ad32dc4d6f98a4130a86b2507')")
start=s.index('functional={');end=s.index('for p,(name,h) in functional.items():',start)
s=s[:start]+'''handoff=load(D+'handoff_READY_NOT_STAGE.json','4b9de1c4c235285793dd1727462074e4b23a027d9791d1829d71088bb bfb9329'.replace(' ',''))
files={r['file']:r for r in handoff['files']}
E='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
functional={p:(role+'_courtyard45_READY.gd',files[role+'_courtyard45_READY.gd']['sha256']) for p,role in [(C,'C'),(DT,'DT'),(F,'Field'),(G,'G'),(E,'ENV')]}
''' +s[end:]
change("basepin=load(S+'ordinary_outer03_READY/whole_inverse_NOT_STAGE.json'","basepin=load(OLD+'ordinary_outer03_READY/whole_inverse_NOT_STAGE.json'")
change("len(original['source_sha256'])==154","len(original['source_sha256'])==162")
change("len(authority['source_sha256'])==162","len(authority['source_sha256'])==170")
start=s.index("helper=dict(path=D+");end=s.index('result=dict(',start)
s=s[:start]+'''helper=dict(path=D+'market_courtyard_session_READY.gd',sha256=files['market_courtyard_session_READY.gd']['sha256'])
bindpin=dict(path=D+'binding_READY.json',sha256=files['binding_READY.json']['sha256']);bv=load(bindpin['path'],bindpin['sha256']);assert bv['ready'] is True and len(bv['required_source_sha256'])==24
assert bv['local_art']['admitted'] is True and bv['resolved_parent_components']['sha256']=='cafee170b4e33b159c8ad769e96ceeb97987d70eb561ee9b5049a8e25e827194'
full={**bv['required_source_sha256'],helper['path']:helper['sha256'],bindpin['path']:bindpin['sha256']};assert len(full)==26
shared={helper['path']:helper['sha256'],bindpin['path']:bindpin['sha256'],bv['author']['path']:bv['author']['sha256'],bv['pure']['path']:bv['pure']['sha256']};assert len(shared)==4
# Read only small metadata/code; media/large component SHA authority is fixed Root/Stage evidence.
for p,h in full.items():
    if p.endswith('.gd') or p.endswith('.json') and not p.endswith('components_FIXED_NOT_RUNTIME.json'):read(p,h)
''' +s[end:]
change('DOCKS_EXACT31_CODE_DEPENDENCY_PREPARATION_NOT_STAGE','COURTYARD45_EXACT32_CODE_DEPENDENCY_PREPARATION_NOT_STAGE')
change('old_proof_count=154,new_proof_count=162','old_proof_count=162,new_proof_count=170')
change('all_old154_key_values_and_all_old_edges_retained','all_old162_key_values_and_all_old_edges_retained')
change('Docks_full18=full','Market_full26=full')
change('ENV_Router_B_adapter_unchanged=True','Router_B_adapter_unchanged=True,ENV_only_runtime_pair_materials_unchanged=True')
change('geometry_native_immutable=True','old_native4_immutable=True,new45_overlay_requires_actual_pins=True')
ast.parse(s)
dest=HERE/'prepare_courtyard32_candidates_BUILD.py'
with dest.open('xb') as out:out.write(s.encode())
print(json.dumps(dict(builder=str(dest),sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),Stage_imports=0)))
