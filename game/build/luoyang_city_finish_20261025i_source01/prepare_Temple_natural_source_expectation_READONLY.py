"""Static exact T.source_paths expression; values from Root Stage, never executing a collector."""
from pathlib import Path
import json,hashlib,re
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
stagepath=NS+'outputs/root_finish8_exact32_stage01/receipt.json';sb=(G/stagepath[6:]).read_bytes();assert sha(sb)=='37d79bce73a637c46dd9790453650a48da79cc1a521c7436fbf07f326cb6ba33';stage=json.loads(sb)
authority=stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'];keys=set();selectors=[]
def fixed(p):
 assert p in authority,('NO_STAGE_AUTHORITY',p);b=(G/p[6:]).read_bytes();assert sha(b)==authority[p],p;return b
def add(*paths):
 for p in paths:assert p in authority,('UNEXPECTED_SOURCE_KEY',p);keys.add(p)
def constants(p):
 text=fixed(p).decode();values=dict(re.findall(r'const\s+(\w+)(?:\s*:\s*\w+)?\s*(?::=|=)\s*"([^"\n]+)"',text));return text,values
def dictionary_paths(p,field):
 value=json.loads(fixed(p));assert isinstance(value[field],dict);add(*value[field]);selectors.append(dict(path=p,sha256=authority[p],pointer=[field],expression='dictionary keys only; current exact values selected from Root fixed Stage authority'))
T='res://scripts/city/luoyang_temple_assembly_20261016.gd';t,tc=constants(T)
required=['SELF','BIND_PATH','SCENE_PATH','LAYOUT_PATH','ORIGINAL','ORIGINAL_LAYOUT'];add(*(tc[k]for k in required),'res://scripts/city/luoyang_temple_task_adapter_20261016.gd','res://scripts/city/luoyang_temple_fade_20261016.gd','res://scripts/autoload/scene_router.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd')
successor=json.loads(fixed(tc['BIND_PATH']));parent=json.loads(fixed(successor['parent_binding_path']));add(successor['parent_binding_path']);add(*parent['source_sha256']);add(*successor['source_delta']);selectors.append(dict(path=T,sha256=authority[T],selector='source_paths lines93-119; binding parent.source_sha256 keys union successor.source_delta keys; no original source values normalized or current filled'))
EX='res://scripts/city/luoyang_execution_authority_20261022ap.gd';_,xc=constants(EX);add(xc['SELF'],xc['INDEX'],xc['APPROVAL']);dictionary_paths(xc['APPROVAL'],'source_sha256')
for p,data_name,field in [('res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd','AUTHOR','source_sha256'),('res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd','DATA','source_sha256')]:
 _,c=constants(p);add(c['SELF'],c[data_name],c['PREDECESSOR']);dictionary_paths(c[data_name],field)
TASK='res://scripts/city/luoyang_city_tasks_20261016.gd';_,c=constants(TASK);add(TASK,c['SPEC_PATH'],c['TASK_BIND_PATH']);dictionary_paths(c['SPEC_PATH'],'source_pins');dictionary_paths(c['TASK_BIND_PATH'],'source_sha256')
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';et,ec=constants(ENV);add(ec['SELF'],ec['INDEX'],ec['AUTHOR'],ec['RECT_TRANSITION_SHADER']);dictionary_paths(ec['AUTHOR'],'source_sha256');ep=json.loads(re.search(r'const FINISH25I_PURPOSE_PINS: Dictionary=(\{[^\n]+\})',et).group(1));add(*ep)
runtime=tc['FINISH25I_RUNTIME'];_,rc=constants(runtime);binding=json.loads(fixed(rc['BIND']));add(rc['SELF'],rc['BIND'],tc['FINISH25I_ADAPTER']);add(*binding['scenes']['ch4_s4_ancient_temple']['required_source_sha256'])
# T._hash_sources hashes exactly returned paths: unlike C, it performs no import discovery.
expected={p:authority[p]for p in sorted(keys)}
report=dict(status='STATIC_SOURCE_EXPRESSION_NATURAL_TEMPLE_SESSION_EXPECTATION_NOT_OBSERVATION',scene_id='ch4_s4_ancient_temple',source_sha256=expected,count=len(expected),authority=dict(path=stagepath,sha256=sha(sb),selector=['nodes','expected_ch4_s2_canal_docks_true','value','source_sha256']),selectors=selectors,contracts=['T.source_paths exact static expression, full task/presentation/people/execution/ENV plus exact Temple finish scope.','No C collector, no get-source-path invocation, no Temple prepare/finalize/engine.','This complete map is for original Temple session source_first/source_final, not just overlay required subset.'],engine_calls=0,collector_calls=0,canonical_writes=0)
p=N/'expected_Temple_natural_session_sources_READONLY.json';assert not p.exists();raw=enc(report)
with p.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=NS+p.name,sha256=sha(raw),count=len(expected))))
