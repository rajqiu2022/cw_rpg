"""Only Field11 parse correction and necessary source values. Runtime/BIND/functions unchanged."""
from pathlib import Path
import json,hashlib,copy,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/';P=NS+'gate_texture_repair01/closure_READY02/';OUT=N/'gate_texture_repair01/closure_READY02'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(read(pin))
def pin(name,h):return dict(path=NS+name,sha256=h)
old=load(pin('gate_texture_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json','48f07dd62f7bdf452830d5345a386bef43497c537ab38a8092ea8400cba3ccd9'))
code=copy.deepcopy(old);seal=load(code['seal']);records=code['records'];data={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(p):return data[p['path'][len(P):]]if p['path'].startswith(P)else read(p)
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert b.count(a)==1;return b.replace(a,c,1)
def hunks(a,b):
 al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
 for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in ops:f=exact(f,h['old'],h['new'])
 for h in reversed(ops):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return ops
def replace_record(p,name,b):
 r=records[p];a=read(r['parent']);records[p]=dict(parent=r['parent'],candidate=out(name,b),hunks=hunks(a,b),whole_byte_forward_inverse=True)
F='res://scripts/field/field_walkable_controller.gd';C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
proof=load(dict(path='res://build/luoyang_city_finish_20261025i_system01/Field11_gate_fixed_source_keys_full_inverse_BUILD.json',sha256='5d12fd4bf671a177cc6c7bf124706d3d984c0814971b2d303c22b185699b6f8d'))
a=read(records[F]['candidate']);b=read(proof['candidate']);forward=a
for h in proof['replacements']:forward=exact(forward,h['old'],h['new'])
assert forward==b
replace_record(F,'Field_READY.gd',b)
ct=code['contract'];a=read(ct['parent']);b=a;v=json.loads(a);changes={}
for p in [C,F]:
 before=v['source_sha256'][p];after=records[p]['candidate']['sha256'];b=exact(b,before,after);v['source_sha256'][p]=after;changes[p]=dict(old=before,new=after)
assert json.loads(b)==v
code['contract']=dict(parent=ct['parent'],candidate=out('runtime_contract_C_Field_READY.json',b),changes=changes,hunks=hunks(a,b),whole_typed_UTF8_inverse=True)
r=records[CO];replace_record(CO,'Coordinator_READY.gd',exact(read(r['parent']),ct['changes'][CT]['old']if CT in ct['changes']else sha(read(ct['parent'])),code['contract']['candidate']['sha256']))
tb=code['temple_binding'];a=read(tb['parent']);b=a;v=json.loads(a);changes={};refs={p:r['candidate']['sha256']for p,r in records.items()};refs[CT]=code['contract']['candidate']['sha256']
for p in [C,F,CO,CT]:
 before=v['source_delta'][p];after=refs[p];b=exact(b,json.dumps(p)+': '+json.dumps(before),json.dumps(p)+': '+json.dumps(after));v['source_delta'][p]=after;changes[p]=dict(old=before,new=after)
assert json.loads(b)==v
code['temple_binding']=dict(parent=tb['parent'],candidate=out('Temple_binding_READY.json',b),changes=changes,hunks=hunks(a,b),whole_typed_UTF8_inverse=True)
r=records[T];b=read(r['candidate']);b=exact(b,tb['candidate']['path'],code['temple_binding']['candidate']['path']);b=exact(b,tb['candidate']['sha256'],code['temple_binding']['candidate']['sha256']);replace_record(T,'Temple_READY.gd',b)
ex=code['execution'];parent=load(ex['parent']);new=copy.deepcopy(parent)
for p in ex['changed_existing_owned']:
 r=records[p];owner=new['owned'][p];snapshot=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256'])
 assert owner['current_sha256']==r['parent']['sha256']and read(dict(path=snapshot,sha256=owner['current_sha256']))==read(r['parent'])
 owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for q in [code['contract']['candidate'],code['temple_binding']['candidate']]:new['source_sha256'][q['path']]=q['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in parent['source_sha256']};assert len(extra)==6 and len(new['source_sha256'])==189 and all(new['source_sha256'][p]==h for p,h in parent['source_sha256'].items())
back=copy.deepcopy(new)
for p in ex['changed_existing_owned']:back['owned'][p]=copy.deepcopy(parent['owned'][p])
back['source_sha256']=copy.deepcopy(parent['source_sha256']);assert enc(back)==read(ex['parent'])
ex.update(candidate=out('execution_successor_READY.json',enc(new)),extra=extra)
seal['Field']=records[F]['candidate'];seal['records']={p:r for p,r in records.items()if p in seal['records']};seal['Field11_parse_source_proof']=proof;seal['runtime_and_binding_unchanged_from_closure01']=True
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal));code['seal']=sealpin
code['Field11_source_successor']=dict(proof_path='res://build/luoyang_city_finish_20261025i_system01/Field11_gate_fixed_source_keys_full_inverse_BUILD.json',proof_sha256='5d12fd4bf671a177cc6c7bf124706d3d984c0814971b2d303c22b185699b6f8d',only_Field_CT_Coordinator_Temple_changed_from_closure01=True)
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(code));assert not OUT.exists();OUT.mkdir()
for name,b in data.items():
 with(OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(code=cp,seal=sealpin,Field=records[F]['candidate'],runtime=seal['runtime'],binding=seal['binding'])))
# Reuse the exact reviewed current4160 metadata recipe, only final code/seal pins and NEW output.
text=(N/'prepare_repair31_metadata02_NOTENGINE.py').read_text()
for a,b in [('repair31_READY02','repair31_READY03'),("C=NS+'gate_texture_repair01/closure_READY01/'","C=NS+'gate_texture_repair01/closure_READY02/'"),('48f07dd62f7bdf452830d5345a386bef43497c537ab38a8092ea8400cba3ccd9',cp['sha256']),('44725cfe5bd3a411635d2015dc6516b7a4c4e8b195d448974c7c4b3c30f7777f',sealpin['sha256'])]:assert a in text;text=text.replace(a,b)
# Scope is the unchanged current4160/31 domain, not a newly minted authority.
text=text.replace("C+\"current4160_repair31_scope_PREPARATION.json'\"","NS+\"gate_texture_repair01/closure_READY01/current4160_repair31_scope_PREPARATION.json'\"")
exec(compile(text,str(N/'prepare_repair31_metadata03_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_repair31_metadata03_DERIVED_NOTENGINE.py')})
