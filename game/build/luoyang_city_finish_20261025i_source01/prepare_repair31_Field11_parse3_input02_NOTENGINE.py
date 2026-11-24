from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def write(name,b):
 p=N/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=S+name,sha256=sha(b),bytes=len(b))
b=json.loads((N/'repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json').read_bytes());code=json.loads((G/b['code_proof']['path'][6:]).read_bytes())
oldinput=(N/'gate_texture_repair01/parse10_ROOT_READY/input_ROOT_READY.json').read_bytes();spec=json.loads(oldinput);spec['status']='ROOT_ONLY_FIELD11_THREE_NECESSARY_GD_PARSE_NO_BUSINESS';spec['scripts']=[code['records'][p]['candidate']for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd']];spec['source_proof']=b['code_proof'];spec['output_prefix']=S+'gate_texture_repair01/parse3_Field11_ROOT_READY/output/'
ip=write('gate_texture_repair01/parse3_Field11_ROOT_READY/input_ROOT_READY.json',enc(spec));parent=(N/'gate_texture_repair01/parse10_ROOT_READY/parse_ROOT_READY.gd').read_bytes();t=parent.decode();hunks=[]
for a,c in [(S+'gate_texture_repair01/parse10_ROOT_READY/input_ROOT_READY.json',ip['path']),(sha(oldinput),ip['sha256']),('raw.get("scripts",[]).size()==10','raw.get("scripts",[]).size()==3'),('EXACT_TEN_SCRIPTS_FIFTEEN_SAVE_FACTS','EXACT_THREE_SCRIPTS_FIFTEEN_SAVE_FACTS'),('collect all10 results.','collect all3 results.'),('rows.size()==10,"ALL_TEN_RESULTS_WITHOUT_EARLY_BREAK"','rows.size()==3,"ALL_THREE_RESULTS_WITHOUT_EARLY_BREAK"')]:
 assert t.count(a)==1;t=t.replace(a,c);hunks.append(dict(old=a,new=c))
back=t
for h in reversed(hunks):back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent
key=write('gate_texture_repair01/parse3_Field11_ROOT_READY/parse_ROOT_READY.gd',t.encode());proof=write('gate_texture_repair01/parse3_Field11_ROOT_READY/mechanical_whole_inverse_READY.json',enc(dict(parent_sha256=sha(parent),input=ip,key=key,hunks=hunks,whole_byte_inverse=True,other9_Root_parse40516_components_inherited=True,engine_calls=0)))
print('PARSE',json.dumps(dict(key=key,input=ip,proof=proof)))
text=(N/'prepare_repair31_stage_input_NOTENGINE.py').read_text()
for a,c in [('repair31_READY02','repair31_READY03'),('7b50bec8b6f34f3f93dd050f35c10776013e2ebebdc8383824ca60176e05bf39','319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98'),('root_gate_texture_market_portal_exact31_stage01/','root_gate_texture_market_portal_exact31_stage02/'),('source_input_gate_portal_repair31_ROOT_REVIEW.json','source_input_gate_portal_repair31_Field11_ROOT_REVIEW.json'),('finite_preStage31_declaration_audit_READONLY.json','finite_preStage31_Field11_declaration_audit_READONLY.json')]:assert a in text;text=text.replace(a,c)
exec(compile(text,str(N/'prepare_repair31_Field11_stage_input_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_repair31_Field11_stage_input_DERIVED_NOTENGINE.py')})
