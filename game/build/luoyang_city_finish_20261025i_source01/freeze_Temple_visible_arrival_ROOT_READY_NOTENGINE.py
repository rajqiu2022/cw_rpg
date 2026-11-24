"""Root-only y926 local CPU mechanical seal; no invocation or semantic edit."""
from pathlib import Path
import hashlib,json,copy
N=Path(__file__).resolve().parent;G=N.parents[1]
OLD=N/'Temple_visible_arrival_local01_NOTREADY';NEW=N/'Temple_visible_arrival_local02_ROOT_READY'
assert not NEW.exists(),'NEW output only'
def h(b):return hashlib.sha256(b).hexdigest()
def read(p,w):
    b=p.read_bytes();assert h(b)==w;return b
def pin(p,b):return {'path':'res://'+str(p.relative_to(G)).replace('\\','/'),'sha256':h(b),'bytes':len(b)}
script0=read(OLD/'check_visible_arrival_NOTREADY.gd','3788f34e6f41b63d24df53773d840c096f0e1e2ff19ac3c986a5be91deb2e1ef')
input0=read(OLD/'input_NOTREADY.json','2e6d8fcef3dd8ebb0ac7de75a35e2a45659104022f9e70a4f7b369709e69f4d4')
project=(OLD/'project.godot').read_bytes();old_cfg=json.loads(input0);cfg=copy.deepcopy(old_cfg)
assert cfg['ready']is False and cfg['root_run_authorized']is False
cfg['ready']=True;cfg['root_run_authorized']=True
cfg['output_root']=cfg['output_root'].replace('Temple_visible_arrival_local01_NOTREADY/output_NOTREADY/','Temple_visible_arrival_local02_ROOT_READY/output_ROOT_READY/')
raw=(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n').encode('utf8')
back=copy.deepcopy(cfg);back['ready']=False;back['root_run_authorized']=False;back['output_root']=old_cfg['output_root']
assert back==old_cfg and (json.dumps(back,ensure_ascii=False,indent=2)+'\n').encode()==input0
changes=[('const READY: bool=false','const READY: bool=true'),('Temple_visible_arrival_local01_NOTREADY','Temple_visible_arrival_local02_ROOT_READY'),('input_NOTREADY.json','input_ROOT_READY.json'),('check_visible_arrival_NOTREADY.gd','check_visible_arrival_ROOT_READY.gd'),('PENDING_FIXED_INPUT',h(raw))]
text=script0.decode('utf8')
for a,b in changes:assert a in text;text=text.replace(a,b)
undo=text
for a,b in reversed(changes):assert b in undo;undo=undo.replace(b,a)
assert undo.encode()==script0
NEW.mkdir()
def emit(name,b):
    if not isinstance(b,bytes):b=(json.dumps(b,ensure_ascii=False,indent=2)+'\n').encode('utf8')
    with (NEW/name).open('xb')as f:f.write(b)
    return pin(NEW/name,b)
sp=emit('check_visible_arrival_ROOT_READY.gd',text.encode());ip=emit('input_ROOT_READY.json',raw);pp=emit('project.godot',project)
proof=emit('mechanical_transport_full_inverse_READY.json',{'status':'ROOT_APPROVED_ONLY_MECHANICAL_TRANSPORT_NOT_EXECUTED','parent_script':pin(OLD/'check_visible_arrival_NOTREADY.gd',script0),'candidate_script':sp,'literal_changes':[{'old':a,'new':b}for a,b in changes],'whole_script_byte_inverse':undo.encode()==script0,'parent_input':pin(OLD/'input_NOTREADY.json',input0),'candidate_input':ip,'only_input_changes':{'ready':[False,True],'root_run_authorized':[False,True],'output_root':[old_cfg['output_root'],cfg['output_root']]},'whole_input_byte_inverse':True,'all_source_pins_author_routes_guard_algorithms_and_three_parent_payloads_identical':True,'project_exact_bytes_unchanged':pp['sha256']==h(project),'no_autoload_main_import_or_mask_replay':True,'engine_calls':0,'canonical_writes':0})
handoff={'status':'ROOT_READY_TEMPLE_TWO_VISIBLE_PORTALS_THREE_PAYLOADS_LOCAL_CPU_NOT_EXECUTED','script':sp,'input':ip,'project':pp,'proof':proof,'project_absolute':str(NEW),'script_respath':'res://check_visible_arrival_ROOT_READY.gd','Root_only_execute':True,'old_failed_or_NOTREADY_artifacts_preserved':True}
print(json.dumps(emit('handoff_ROOT_READY.json',handoff)))
