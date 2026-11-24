"""Four existing owned successors from final service READY02. No Stage."""
from pathlib import Path
import json,copy,hashlib,difflib
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/owned4_service_READY02/'
OUT=P/'owned4_service_READY02';assert not OUT.exists()
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));assert b'tokens truncated'not in b;return b
def exact(b,a,c):
 assert b.count(a.encode())==1,(a,b.count(a.encode()));return b.replace(a.encode(),c.encode(),1)
prepared={}
def out(name,b):
 assert name not in prepared;prepared[name]=b;return dict(path=R+name,sha256=sha(b),bytes=len(b))
def hunks(a,b):
 al=a.decode().splitlines(keepends=True);bl=b.decode().splitlines(keepends=True);ops=[]
 for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
 f,v=a,b
 for op in ops:f=exact(f,op['old'],op['new'])
 for op in reversed(ops):v=exact(v,op['new'],op['old'])
 assert f==b and v==a and max(max(len(o['old'].encode()),len(o['new'].encode()))for o in ops)<18000
 return ops
scopepin=dict(path='res://build/luoyang_city_revision_20261025h_source01/service_garden_exact28_scope_PREPARATION.json',sha256='a249b542308b2173133d3c868980465a8b90eee7042daa9e509fdb4f3cc9a19f')
scope=json.loads(read(scopepin['path'],scopepin['sha256']));parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
priorpath='res://build/luoyang_city_revision_20261025g_source01/courtyard32_candidates01/code_execution_whole_inverse_NOT_STAGE.json'
prior=json.loads(read(priorpath,'e4c12661d767a9f72db3848adaf75557d6341f74103d7a1c56f81b45047a016e'))
F='res://scripts/field/field_walkable_controller.gd';ROOM='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
S='res://build/luoyang_indoor_services_20261025h_system01/'
records={}
def record(p,pin,b):
 old=read(parents[p]['path'],parents[p]['sha256']);assert old!=b and b.endswith(b'\n')and b'\r'not in b
 records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(old,b),whole_byte_forward_inverse=True)
for p,path,h in [(ROOM,S+'runtime_READY02/G_READY.gd','537ca3d782a97144a19c6f22683833f4541640deb4a8fc981dafe3a790d09105'),(F,S+'Field_services03_CANDIDATE.gd','fcc943fe3d188da41097ca20b9abd912a9a6dc32e09ba43f15691aa30f8ef4f0')]:
 b=read(path,h);record(p,dict(path=path,sha256=h,bytes=len(b)),b)
old=read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']);v=json.loads(old);a=v['source_sha256'][F];assert a==parents[F]['sha256'];v['source_sha256'][F]=records[F]['candidate']['sha256'];b=exact(old,a,v['source_sha256'][F]);assert json.loads(b)==v
contract=out('runtime_contract_Field_services_READY.json',b);contract_info=dict(target=CONTRACT,parent=parents[CONTRACT],candidate=contract,changes={F:dict(old=a,new=v['source_sha256'][F])},hunks=hunks(old,b),whole_typed_UTF8_inverse=True)
b=exact(read(parents[CO]['path'],parents[CO]['sha256']),parents[CONTRACT]['sha256'],contract['sha256']);pin=out('Coordinator_services_CANDIDATE.gd',b);record(CO,pin,b)
oldbind=prior['temple_binding']['candidate'];old=read(oldbind['path'],oldbind['sha256']);value=json.loads(old);binding=copy.deepcopy(value);b=old;changes={}
refs={p:r['candidate']['sha256']for p,r in records.items()};refs[CONTRACT]=contract['sha256']
for p,a in value['source_delta'].items():
 if p not in refs:continue
 assert a==parents[p]['sha256'];binding['source_delta'][p]=refs[p];b=exact(b,json.dumps(p)+': '+json.dumps(a),json.dumps(p)+': '+json.dumps(refs[p]));changes[p]=dict(old=a,new=refs[p])
assert set(changes)=={F,CO,CONTRACT} and json.loads(b)==binding
bind=out('Temple_binding_services_READY.json',b)
b=read(parents[T]['path'],parents[T]['sha256']);b=exact(exact(b,oldbind['path'],bind['path']),oldbind['sha256'],bind['sha256']);pin=out('Temple_services_CANDIDATE.gd',b);record(T,pin,b)
before=read(parents[EXEC]['path'],parents[EXEC]['sha256']);authority=json.loads(before);assert enc(authority)==before and len(authority['owned'])==10 and len(authority['source_sha256'])==170
nexta=copy.deepcopy(authority)
for p,r in records.items():
 row=nexta['owned'][p];assert row['current_sha256']==r['parent']['sha256']
 snapshot=next(e['new_snapshot']for e in reversed(row['edges'])if e['new_sha256']==row['current_sha256'])
 assert read(snapshot,row['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
 row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));row['current_sha256']=r['candidate']['sha256'];nexta['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for r in [contract,bind]:nexta['source_sha256'][r['path']]=r['sha256']
extra={p:h for p,h in nexta['source_sha256'].items()if p not in authority['source_sha256']};assert len(extra)==6 and len(nexta['source_sha256'])==176
back=copy.deepcopy(nexta)
for p in records:back['owned'][p]=copy.deepcopy(authority['owned'][p])
back['source_sha256']=copy.deepcopy(authority['source_sha256']);assert enc(back)==before
assert all(nexta['source_sha256'][p]==h for p,h in authority['source_sha256'].items())
execution=out('execution_successor_services_PREPARATION.json',enc(nexta))
proof=out('four_owned_code_execution_whole_inverse_NOT_STAGE.json',enc(dict(status='FOUR_EXISTING_OWNED_SERVICE_CODE_SUCCESSORS_NOT_STAGE',scope=scopepin,records=records,contract=contract_info,temple_binding=dict(parent=oldbind,candidate=bind,changes=changes,whole_typed_UTF8_inverse=True,hunks=hunks(old,prepared['Temple_binding_services_READY.json'])),execution=dict(parent=parents[EXEC],candidate=execution,changed_existing_owned=list(records),owned_count=10,old_proof_count=170,new_proof_count=176,extra=extra,all_old170_key_values_and_all_edges_retained=True,other6_owned_rows_identical=True,depth_limit=16,no_shortcut=True,whole_typed_UTF8_inverse=True),unmodified=['C','AA','AC','DT','ENV','Router','UI','registry12','all_room_native'],engine_calls=0,Stage_calls=0,canonical_writes=0)))
OUT.mkdir()
for name,b in prepared.items():
 if name.endswith('.json'):json.loads(b)
 with (OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(proof=proof,execution=execution,codes={p:r['candidate']for p,r in records.items()},contract=contract,temple_binding=bind)))
