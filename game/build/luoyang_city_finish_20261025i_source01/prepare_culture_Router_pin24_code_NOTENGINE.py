"""Only CT.Router exact pin and its necessary executable/source-counter successors."""
from pathlib import Path
import json,hashlib,copy,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'culture_Router_pin_repair01/closure_READY01/';OUT=N/'culture_Router_pin_repair01/closure_READY01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(read(pin))
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a,b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
 for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
 f,v=a,b
 for h in hs:f=exact(f,h['old'],h['new'])
 for h in reversed(hs):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return hs
scopepin=dict(path=S+'culture_Router_pin_repair01/current_D581_exact24_scope_PREPARATION.json',sha256='464ed8df58b3a7fc2147aa1236794bfa82da03a0382e1020825ffaa0dcd5016b');scope=load(scopepin);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
old=load(scope['parent_descriptor']);data={};records={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(pin):return data[pin['path'][len(P):]]if pin['path'].startswith(P)else read(pin)
def record(p,name,b):
 a=read(parents[p]);assert a!=b;records[p]=dict(parent=parents[p],candidate=out(name,b),hunks=hunks(a,b),whole_byte_forward_inverse=True)
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';R='res://scripts/autoload/scene_router.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
router=next(r['candidate']for r in old['targets']if r['target']==R);assert router['sha256']=='e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745'
before=read(parents[CT]);v=json.loads(before);assert len(v['source_sha256'])==26;oldrouter=v['source_sha256'][R];assert oldrouter=='908f2254539010557b7ebfdc1cb77f86f6a05b068d1386741268b39a9cadeb51';v['source_sha256'][R]=router['sha256'];after=exact(before,oldrouter,router['sha256']);assert json.loads(after)==v
contract=dict(parent=parents[CT],candidate=out('runtime_contract_Router_READY.json',after),changes={R:dict(old=oldrouter,new=router['sha256'])},hunks=hunks(before,after),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
tbparent=old['temple_binding']['candidate'];before=read(tbparent);v=json.loads(before);after=before;changes={}
for p,h in [(R,router['sha256']),(CT,contract['candidate']['sha256']),(CO,records[CO]['candidate']['sha256'])]:
 oldhash=v['source_delta'][p];assert oldhash==(oldrouter if p==R else parents[p]['sha256']);v['source_delta'][p]=h;after=exact(after,json.dumps(p)+': '+json.dumps(oldhash),json.dumps(p)+': '+json.dumps(h));changes[p]=dict(old=oldhash,new=h)
assert json.loads(after)==v;tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',after),changes=changes,hunks=hunks(before,after),whole_typed_UTF8_inverse=True)
b=read(parents[T]);b=exact(b,tbparent['path'],tb['candidate']['path']);b=exact(b,tbparent['sha256'],tb['candidate']['sha256']);record(T,'Temple_READY.gd',b)
prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==202;new=copy.deepcopy(prior);changed=[CO,T]
for p in changed:
 r=records[p];owner=new['owned'][p];assert owner['current_sha256']==parents[p]['sha256'];snap=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snap,sha256=owner['current_sha256']))==read(parents[p]);owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==4 and len(new['source_sha256'])==206 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(new)
for p in changed:back['owned'][p]=copy.deepcopy(prior['owned'][p])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX])
execution=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=202,new_proof_count=206,extra=extra,old202_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)
seal=load(old['seal']);seal['records'][T]=records[T];seal.update(status='D581_CT_ROUTER_AND_TEMPLE_EXACT_CURRENT_SOURCE_PINS_ONLY',runtime_and_binding_unchanged_from_D581=True,Field_Router_Families_C_AA_AC_ENV_unchanged=True,CT_source26_only_Router_changed=True,Temple_source_delta_only_Router_CT_Coordinator_changed=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='D581_TWO_OWNED_SOURCE_COUNTER_SUCCESSORS_NO_FUNCTION_CHANGE_NOT_STAGE',seal=sealpin,records=records,ordinary=[],contract=contract,temple_binding=tb,execution=execution,consumer_audit=dict(path=S+'culture_Router_pin_repair01/all_CT26_Temple_consumer_pin_audit_READONLY.json',sha256='d49ab9b582cd1302befba25d1d1265312d88c0652c16ea94f779d26b06fa6f52'),engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
assert len(records)==2 and not OUT.exists();OUT.mkdir()
for name,b in data.items():
 with(OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(code=cp,seal=sealpin,contract=contract['candidate'],Temple_binding=tb['candidate'],records={p:r['candidate']for p,r in records.items()},execution=execution['candidate'])))
