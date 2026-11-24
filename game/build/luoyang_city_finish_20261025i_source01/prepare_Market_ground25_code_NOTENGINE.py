"""Field13 only functional delta; current5D6C strict source successor, no runtime change."""
from pathlib import Path
import json,copy,hashlib,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'market_ground_texture_repair02/closure_READY01/';OUT=N/'market_ground_texture_repair02/closure_READY01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p):
 b=(G/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'];return b
def load(p):return json.loads(read(p))
old=load(dict(path=S+'repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98'));dep=load(dict(path=S+'repair31_Field11_deployed_ROOT_ACTUAL.json',sha256='5d6c2f7aa10d5c4763ade8d3eb7ce60983f011bbb677ed0e6b5e4e5148dc29a1'));parents={r['target']:dict(path=r['candidate_path'],sha256=r['sha256'],bytes=r['bytes'])for r in dep['targets']};seal=load(old['seal']);data={};records={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(p):return data[p['path'][len(P):]]if p['path'].startswith(P)else read(p)
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1;return b.replace(a,c,1)
def hunks(a,b):
 al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
 for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in ops:f=exact(f,h['old'],h['new'])
 for h in reversed(ops):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return ops
def record(p,name,b):
 a=read(parents[p]);assert a!=b;records[p]=dict(parent=parents[p],candidate=out(name,b),hunks=hunks(a,b),whole_byte_forward_inverse=True)
F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
proofpin=dict(path='res://build/luoyang_city_finish_20261025i_system01/Field13_market_ground_exact_bridge_full_inverse_BUILD.json',sha256='a16d71a16e38e4c75177c005220afa5e5521feb120b46402001bebcd2fe62424');proof=load(proofpin)
fieldpin=dict(path='res://build/luoyang_city_finish_20261025i_system01/Field13_market_ground_exact_bridge_CANDIDATE.gd',sha256='f84a037eba57d64696fc06fbfd763caf88a987de1090150c379196a5c43f3698');a=read(parents[F]);b=read(fieldpin);record(F,'Field_READY.gd',b);assert len(records[F]['hunks'])==2
# Entire runtime/path/BIND and all other existing field text are fixed by the
# exact two physical replacements in the System proof and the direct inverse.
forward=a;reverse=b
for h in proof['hunks']:forward=exact(forward,h['old'],h['new'])
for h in reversed(proof['hunks']):reverse=exact(reverse,h['new'],h['old'])
assert forward==b and reverse==a
a=read(parents[CT]);oldct=json.loads(a);newct=copy.deepcopy(oldct);before=oldct['source_sha256'][F];after=records[F]['candidate']['sha256'];assert before==parents[F]['sha256'];b=exact(a,before,after);newct['source_sha256'][F]=after;assert json.loads(b)==newct
contract=dict(parent=parents[CT],candidate=out('runtime_contract_Field_READY.json',b),changes={F:dict(old=before,new=after)},hunks=hunks(a,b),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
tbparent=old['temple_binding']['candidate'];a=read(tbparent);v=json.loads(a);b=a;changes={};refs={F:records[F]['candidate']['sha256'],CO:records[CO]['candidate']['sha256'],CT:contract['candidate']['sha256']}
for p,h in refs.items():
 before=v['source_delta'][p];assert before==parents[p]['sha256'];b=exact(b,json.dumps(p)+': '+json.dumps(before),json.dumps(p)+': '+json.dumps(h));v['source_delta'][p]=h;changes[p]=dict(old=before,new=h)
assert json.loads(b)==v;tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=changes,hunks=hunks(a,b),whole_typed_UTF8_inverse=True)
b=read(parents[T]);b=exact(b,tbparent['path'],tb['candidate']['path']);b=exact(b,tbparent['sha256'],tb['candidate']['sha256']);record(T,'Temple_READY.gd',b)
prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==189;new=copy.deepcopy(prior);changed=[F,CO,T]
for p in changed:
 r=records[p];owner=new['owned'][p];assert owner['current_sha256']==parents[p]['sha256'];snapshot=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snapshot,sha256=owner['current_sha256']))==read(parents[p]);owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for p in [contract['candidate'],tb['candidate']]:new['source_sha256'][p['path']]=p['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==5 and len(new['source_sha256'])==194 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(new)
for p in changed:back['owned'][p]=copy.deepcopy(prior['owned'][p])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX])
ex=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=189,new_proof_count=194,extra=extra,old189_values_all_edges_retained=True,depth_limit=16,no_shortcut=True,whole_typed_UTF8_inverse=True)
seal['Field']=records[F]['candidate'];seal['records'][T]=records[T];seal['runtime_and_binding_unchanged_from_5D6C']=True;seal['Field13_source_proof']=proofpin;sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT5D6C_ONLY_MARKET_AE_FIELD_THREE_OWNED_SUCCESSORS_NOT_STAGE',seal=sealpin,records=records,ordinary=[],contract=contract,temple_binding=tb,execution=ex,only_Functional_Field13=True,Field13_source_proof=proofpin,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
assert not OUT.exists();OUT.mkdir()
for name,b in data.items():
 with(OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(code=cp,seal=sealpin,Field=records[F]['candidate'],records={p:r['candidate']for p,r in records.items()},execution=ex['candidate'],runtime=seal['runtime'],binding=seal['binding'])))
