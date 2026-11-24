"""Mechanical text-only freeze under Root explicit two-key authorization. No engine."""
from pathlib import Path
import hashlib,json,difflib

GAME=Path('F:/Code/RPG_GAME/game')
Q=GAME/'build/luoyang_city_full_rollout_20261022ap_qa01'
OLD=Q/'hall_column_portal_tint_execution_NOTREADY'
NEW=Q/'hall_column_portal_tint_execution_READY'
assert not NEW.exists(),'PRESERVE_ALL_PRIOR_READY_OUTPUTS'
def sha(data): return hashlib.sha256(data).hexdigest()
def js(data): return (json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
def resource(path): return 'res://'+path.relative_to(GAME).as_posix()
def absolute(path): return GAME/path.removeprefix('res://')
def emit(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open('xb') as file: file.write(data)
    return {'path':resource(path),'sha256':sha(data),'bytes':len(data)}
old_geometry=json.loads((OLD/'hall_column_fixture_NOTREADY.json').read_bytes())
old_shader=json.loads((OLD/'portal_isolate/fixture_NOTREADY.json').read_bytes())
for path,digest in old_geometry['source_sha256'].items():
    assert sha(absolute(path).read_bytes())==digest,('SMALL_SOURCE_CHANGED',path)
for prefix in ['author','candidate_geometry','candidate_helper']:
    assert sha(absolute(old_geometry[prefix+'_path']).read_bytes())==old_geometry[prefix+'_sha256']
for prefix in ['texture','old_shader','candidate_shader']:
    assert sha(Path(old_shader[prefix+'_path']).read_bytes())==old_shader[prefix+'_sha256']
guard_path=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration66/final_guard.json'
assert sha(guard_path.read_bytes())=='a2321bcbb93b885f3f33aa98bf2663af853e0c056ebdf90dc34156e01a5d39e7'
old_guard=json.loads(guard_path.read_bytes())
assert old_guard['passed'] and len(old_guard['save_paths'])==15
g=old_geometry.copy();g.update(ready=True,status='ROOT_AUTHORIZED_PURE_BASE_COMPILE_AND_PHYSICS_READY_NOT_RUN',blockers=[])
s=old_shader.copy();s.update(ready=True,status='ROOT_AUTHORIZED_NOAUTOLOAD_PORTAL_RENDER_READY_NOT_RUN',blockers=[],save15_paths=old_guard['save_paths'])
s['source_sha256']={str(absolute(p)).replace('\\','/'):v for p,v in old_geometry['source_sha256'].items() if 'luoyang_hall_portal_fix_20261024a_system01/' in p}
s['source_sha256'].update({
 str(GAME/'scenes/exit_zone.tscn'):'6f2c45dd86aaa8eb4d8f2250473eff5425744da2236a943d4dc4a6d42ec921f9',
 str(GAME/'scripts/field/world_v15_exit_zone.gd'):'19665f50731eb90286372cbd0ebf55b43bf6edf1694e85885d50bb59cbe9e8ef',
 str(GAME/'project.godot'):'4e49287b58d3d3c5fddbEEE8db761a6ac8572a73f21d09a34d94c15d338a1cb2'.lower()
})
for path,digest in s['source_sha256'].items(): assert sha(Path(path).read_bytes())==digest
g_bytes=js(g);s_bytes=js(s)
g_path=NEW/'hall_column_fixture_READY.json';s_path=NEW/'portal_isolate/fixture_READY.json'
g_key=(OLD/'hall_column_physics_NOTREADY.gd').read_bytes()
s_key=(OLD/'portal_isolate/test_NOTREADY.gd').read_bytes()
g_changes=[(b'const READY=false',b'const READY=true'),(resource(OLD/'hall_column_fixture_NOTREADY.json').encode(),resource(g_path).encode()),(b'PENDING_MECHANICAL_FREEZE',sha(g_bytes).encode()),(b'/hall_column_portal_tint_execution_NOTREADY/geometry_output_NOTREADY/',b'/hall_column_portal_tint_execution_READY/geometry_output_READY/')]
s_changes=[(b'const READY=false',b'const READY=true'),(b'res://fixture_NOTREADY.json',b'res://fixture_READY.json'),(b'PENDING_MECHANICAL_FREEZE',sha(s_bytes).encode()),(b'res://output_NOTREADY/',b'res://output_READY/')]
def transform(data,changes):
    output=data
    for old,new in changes:
        assert output.count(old)==1,(old,output.count(old))
        output=output.replace(old,new)
    reverse=output
    for old,new in reversed(changes):
        assert reverse.count(new)==1
        reverse=reverse.replace(new,old)
    assert reverse==data
    return output
g_new=transform(g_key,g_changes);s_new=transform(s_key,s_changes)
g_inverse=g.copy()
for key in ['ready','status','blockers']: g_inverse[key]=old_geometry[key]
assert g_inverse==old_geometry
s_inverse=s.copy()
for key in ['ready','status','blockers','save15_paths','source_sha256']: s_inverse[key]=old_shader[key]
assert s_inverse==old_shader
files=[]
for path,data in [(g_path,g_bytes),(s_path,s_bytes),(NEW/'hall_column_physics_READY.gd',g_new),(NEW/'portal_isolate/test_READY.gd',s_new),(NEW/'portal_isolate/project.godot',(OLD/'portal_isolate/project.godot').read_bytes())]: files.append(emit(path,data))
for name,old,new in [('geometry_key',g_key,g_new),('shader_key',s_key,s_new),('geometry_fixture',js(old_geometry),g_bytes),('shader_fixture',js(old_shader),s_bytes)]:
    diff=''.join(difflib.unified_diff(old.decode('utf-8').splitlines(True),new.decode('utf-8').splitlines(True),fromfile=name+'_NOTREADY',tofile=name+'_READY'))
    files.append(emit(NEW/(name+'_complete.diff'),diff.encode('utf-8')))
handoff={
 'status':'TWO_ROOT_AUTHORIZED_READY_KEYS_TEXT_FROZEN_NOT_RUN','ready':True,'engine_run_by_QA':False,
 'files':files,'key_inverse':'Each4 exact literal transformations, whole original bytes including EOF restored',
 'fixture_inverse':{'geometry':'Only ready/status/blockers','shader':'Only ready/status/blockers plus15 fixed main-save absolute paths and explicit source pins; no render parameters/expected pixels changed'},
 'tested_API':'geometry canonical G OLD compile + helper60949.compile_bases + canonical safe_foot; no candidate G/Field runtime hook/session admission credit',
 'no_ghost_or_ART_credit':'Pillar runtime clipping/actor alpha needs future separately authorized real Field; no fabricated positive hit expectation',
 'source_guard':'All5 frozen candidates tracked, G/Field/world_v15 are SHA declarations not load/call by this test; shader source loaded only as text in empty project',
 'save_guard':'Godot fact snapshots includeSHA/bytes/seconds; exact UTCticks are Root external fresh guard before/after, never claimed measured in Godot',
 'launcher':'Root retained85C5 launcher only; reject any Godot except editor51856, no stopping user processes; WaitForExit true process exit and logSHA',
 'geometry_command':f"& '{GAME.as_posix()}/build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1' -Headless -ScriptResPath '{resource(NEW/'hall_column_physics_READY.gd')}' -ScriptSHA '{sha(g_new)}' -LogStem '{NEW.as_posix()}/geometry_once'",
 'shader_command':f"& '{GAME.as_posix()}/build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1' -Project '{(NEW/'portal_isolate').as_posix()}' -ScriptResPath 'res://test_READY.gd' -ScriptSHA '{sha(s_new)}' -LogStem '{NEW.as_posix()}/shader_once'",
 'script_budget_ms':15000,'single_run_each':True,'production_writes':False,'Stage':False,'source_collector':False
}
meta=emit(NEW/'handoff_READY_NOT_RUN.json',js(handoff))
print(json.dumps({'handoff':meta,'geometry':files[2],'shader':files[3],'project':files[4],'fixtures':files[:2]},ensure_ascii=False))
