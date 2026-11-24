"""Root-authorized mechanical transport, no run/canonical/import/Stage."""
from pathlib import Path
import hashlib,json,copy
N=Path(__file__).resolve().parent;G=N.parents[1]
OLD=N/'street_edges_yamen02_local01_NOTREADY';NEW=N/'street_edges_yamen02_local02_ROOT_READY'
assert not NEW.exists(),'NEW output only'
def sha(b):return hashlib.sha256(b).hexdigest()
def pin(p,b):return {'path':'res://'+str(p.relative_to(G)).replace('\\','/'),'sha256':sha(b),'bytes':len(b)}
def read(p,w):
    b=p.read_bytes();assert sha(b)==w;return b
input_raw=read(OLD/'input_NOTREADY.json','b0d3da2ac4d50c8d3c988b20e610263ceb650ba472ea50361c0b8aa2a1294aed')
script_raw=read(OLD/'check_two_yamen_walls_NOTREADY.gd','6249a32f7678f6434eb9861715c6b91a8555eb532992466bbfc3d10e790f6e94')
project_raw=read(OLD/'project.godot','a8e6c30c399665b4eebb42b989903f0fd5d688789da138a6ef7a8123907f028a')
old_input=json.loads(input_raw);new_input=copy.deepcopy(old_input)
assert old_input['ready'] is False and old_input['root_run_authorized'] is False
new_input['ready']=True;new_input['root_run_authorized']=True
new_input['output_root']=new_input['output_root'].replace('street_edges_yamen02_local01_NOTREADY/output_NOTREADY/','street_edges_yamen02_local02_ROOT_READY/output_ROOT_READY/')
new_input_raw=(json.dumps(new_input,ensure_ascii=False,indent=2)+'\n').encode('utf8')
back=copy.deepcopy(new_input);back['ready']=False;back['root_run_authorized']=False;back['output_root']=old_input['output_root']
assert back==old_input and (json.dumps(back,ensure_ascii=False,indent=2)+'\n').encode()==input_raw
changes=[('const READY: bool=false','const READY: bool=true'),('street_edges_yamen02_local01_NOTREADY','street_edges_yamen02_local02_ROOT_READY'),('input_NOTREADY.json','input_ROOT_READY.json'),('check_two_yamen_walls_NOTREADY.gd','check_two_yamen_walls_ROOT_READY.gd'),('b0d3da2ac4d50c8d3c988b20e610263ceb650ba472ea50361c0b8aa2a1294aed',sha(new_input_raw))]
script=script_raw.decode('utf8')
for before,after in changes:assert before in script;script=script.replace(before,after)
undo=script
for before,after in reversed(changes):assert after in undo;undo=undo.replace(after,before)
assert undo.encode()==script_raw
NEW.mkdir()
def write(name,b):
    if not isinstance(b,bytes):b=(json.dumps(b,ensure_ascii=False,indent=2)+'\n').encode('utf8')
    with (NEW/name).open('xb') as f:f.write(b)
    return pin(NEW/name,b)
input_pin=write('input_ROOT_READY.json',new_input_raw)
script_pin=write('check_two_yamen_walls_ROOT_READY.gd',script.encode())
project_pin=write('project.godot',project_raw)
proof={'status':'ROOT_AUTHORIZED_MECHANICAL_TWO_YAMEN_WALL_CPU_TRANSPORT_NOT_EXECUTED','old_script':pin(OLD/'check_two_yamen_walls_NOTREADY.gd',script_raw),'new_script':script_pin,'script_literal_changes':[{'old':a,'new':b}for a,b in changes],'whole_script_byte_inverse':undo.encode()==script_raw,'old_input':pin(OLD/'input_NOTREADY.json',input_raw),'new_input':input_pin,'only_input_changes':{'ready':[False,True],'root_run_authorized':[False,True],'output_root':[old_input['output_root'],new_input['output_root']]},'whole_input_byte_inverse':True,'original_author8C9D_and_all_sources_guards_unchanged':new_input['author']==old_input['author'] and new_input['sources']==old_input['sources'],'original_project_byte_identical_no_autoload':project_pin['sha256']==sha(project_raw),'Root_runner_script_respath':'res://check_two_yamen_walls_ROOT_READY.gd','new_domain_pixel_budget':5606,'actual_CPU_pass':False,'engine_calls':0,'Stage_calls':0,'canonical_writes':0}
proof_pin=write('mechanical_transport_complete_inverse_READY.json',proof)
handoff={'status':'ROOT_READY_FINITE_TWO_YAMEN_WALL_CPU_NOT_RUN','script':script_pin,'input':input_pin,'project':project_pin,'proof':proof_pin,'project_absolute':str(NEW),'script_respath':'res://check_two_yamen_walls_ROOT_READY.gd','Root_only_execute':True,'no_main_project_import_or_autoload':True,'old_artifacts_preserved':True}
print(json.dumps(write('handoff_ROOT_READY.json',handoff),ensure_ascii=False))
