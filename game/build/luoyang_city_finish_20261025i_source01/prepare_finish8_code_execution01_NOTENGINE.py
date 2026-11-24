"""Exact ordinary prelayers and five existing owned edges; no Stage/engine/canonical write."""
from pathlib import Path
import json,hashlib,copy,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
OUT=N/'code_execution_READY01';PREFIX=NS+OUT.name+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,h,sha(b));return b
def load(pin):return json.loads(read(pin['path'],pin['sha256']))
scope=load(dict(path=NS+'finish8_existing_target_scope32_PREPARATION.json',sha256='2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589'))
parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
sealpin=dict(path=NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json',sha256='bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa')
seal=load(sealpin);prepared={};records={}
def out(name,b):
 assert name not in prepared;prepared[name]=b;return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
 for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
 f,v=a,b
 for op in ops:f=exact(f,op['old'],op['new'])
 for op in reversed(ops):v=exact(v,op['new'],op['old'])
 assert f==b and v==a
 return ops
def value(pin):return prepared[pin['path'][len(PREFIX):]]if pin['path'].startswith(PREFIX)else read(pin['path'],pin['sha256'])
def record(p,pin):
 a=read(parents[p]['path'],parents[p]['sha256']);b=value(pin);assert a!=b
 records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(a,b),whole_byte_forward_inverse=True)
for p,r in seal['records'].items():record(p,r['candidate'])
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';ROOM='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
record(F,seal['Field'])
ordinary=[]
def ordinary_layer(consumer,target,stem,name):
 targetpin=records[target]['candidate'];ops=records[target]['hunks'];parent=parents[target]
 proof=out(stem+'_to_fixed25h_ordinary_proof_READY.json',enc(dict(schema_version=1,status='EXACT_25I_'+stem+'_TO_FIXED25H_ORDINARY_LAYER',path=target,old_sha256=parent['sha256'],new_sha256=targetpin['sha256'],whole_inverse_exact=True,replacements=ops)))
 old=read(parents[consumer]['path'],parents[consumer]['sha256']);text=old.decode();base='ORDINARY_'+stem
 guard='FileAccess.get_sha256('+base+'_PATH)!='+base+'_OUTER_SHA'
 count=text.count(guard);assert count==(3 if stem=='C'else 4),count
 text=text.replace(guard,'FileAccess.get_sha256('+base+'_PATH)!=FINISH_'+stem+'_SHA')
 before='var bytes: PackedByteArray=FileAccess.get_file_as_bytes('+base+'_PATH)';assert text.count(before)==1
 text=text.replace(before,'var bytes: PackedByteArray=_finish_'+stem.lower()+'_parent_bytes()')
 func=f'''const FINISH_{stem}_SHA="{targetpin['sha256']}"
const FINISH_{stem}_PROOF="{proof['path']}"
const FINISH_{stem}_PROOF_SHA="{proof['sha256']}"
static func _finish_{stem.lower()}_parent_bytes() -> PackedByteArray:
\tif FileAccess.get_sha256({base}_PATH)!=FINISH_{stem}_SHA or FileAccess.get_sha256(FINISH_{stem}_PROOF)!=FINISH_{stem}_PROOF_SHA: return PackedByteArray()
\tvar layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(FINISH_{stem}_PROOF))
\tif not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="EXACT_25I_{stem}_TO_FIXED25H_ORDINARY_LAYER" or layer.get("path")!={base}_PATH or layer.get("old_sha256")!={base}_OUTER_SHA or layer.get("new_sha256")!=FINISH_{stem}_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!={len(ops)}: return PackedByteArray()
\tvar bytes: PackedByteArray=FileAccess.get_file_as_bytes({base}_PATH)
\tvar text: String=bytes.get_string_from_utf8()
\tif text.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=FINISH_{stem}_SHA: return PackedByteArray()
\tfor index: int in range(layer.replacements.size()-1,-1,-1):
\t\tvar row: Variant=layer.replacements[index]
\t\tif not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or text.count(row.new)!=1: return PackedByteArray()
\t\ttext=text.replace(row.new,row.old)
\treturn text.to_utf8_buffer() if b().bytes_sha(text.to_utf8_buffer())=={base}_OUTER_SHA else PackedByteArray()
'''
 marker='const '+base+'_OUTER_SHA=';assert text.count(marker)==1;text=text.replace(marker,func+marker)
 key=base+'_OUTER_PROOF:true';assert text.count(key)==1;text=text.replace(key,key+',FINISH_'+stem+'_PROOF:true')
 pin=out(name,text.encode());record(consumer,pin);ordinary.append(dict(consumer=consumer,target=target,proof=proof,old_inner_gates_unchanged=True,actual_file_guard_count=count))
ordinary_layer(AA,C,'C','AA_READY.gd');ordinary_layer(AC,AA,'AA','AC_READY.gd')
old=read(parents[CT]['path'],parents[CT]['sha256']);v=json.loads(old);b=old;ctchanges={}
for p in [C,F]:
 a=v['source_sha256'][p];assert a==parents[p]['sha256'];h=records[p]['candidate']['sha256'];v['source_sha256'][p]=h;b=exact(b,a,h);ctchanges[p]=dict(old=a,new=h)
assert json.loads(b)==v
contract=out('runtime_contract_C_Field_READY.json',b);contractinfo=dict(parent=parents[CT],candidate=contract,changes=ctchanges,hunks=hunks(old,b),whole_typed_UTF8_inverse=True)
co=out('Coordinator_READY.gd',exact(read(parents[CO]['path'],parents[CO]['sha256']),parents[CT]['sha256'],contract['sha256']));record(CO,co)
oldbind=dict(path='res://build/luoyang_city_revision_20261025h_source01/owned4_service_READY02/Temple_binding_services_READY.json',sha256='4c6addea680cfc0df7f3b1ae42b324d32bdaca6b3693e60caa80d909c1145fdc')
old=read(oldbind['path'],oldbind['sha256']);v=json.loads(old);b=old;changes={}
refs={p:r['candidate']['sha256']for p,r in records.items()};refs[CT]=contract['sha256']
for p in [C,F,CO,CT]:
 a=v['source_delta'][p];assert a==parents[p]['sha256'];v['source_delta'][p]=refs[p];b=exact(b,json.dumps(p)+': '+json.dumps(a),json.dumps(p)+': '+json.dumps(refs[p]));changes[p]=dict(old=a,new=refs[p])
assert json.loads(b)==v
binding=out('Temple_binding_READY.json',b);bindinginfo=dict(parent=oldbind,candidate=binding,changes=changes,hunks=hunks(old,b),whole_typed_UTF8_inverse=True)
tb=value(records[T]['candidate']);tb=exact(exact(tb,oldbind['path'],binding['path']),oldbind['sha256'],binding['sha256']);tp=out('Temple_READY.gd',tb);record(T,tp)
before=read(parents[EX]['path'],parents[EX]['sha256']);authority=json.loads(before);assert enc(authority)==before and len(authority['owned'])==10 and len(authority['source_sha256'])==176
nexta=copy.deepcopy(authority);owned=[ROOM,F,CO,T,AC]
for p in owned:
 r=records[p];row=nexta['owned'][p];assert row['current_sha256']==r['parent']['sha256'];snapshot=next(e['new_snapshot']for e in reversed(row['edges'])if e['new_sha256']==row['current_sha256'])
 assert read(snapshot,row['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
 row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));row['current_sha256']=r['candidate']['sha256'];nexta['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract,binding]:nexta['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in nexta['source_sha256'].items()if p not in authority['source_sha256']};assert len(extra)==7 and len(nexta['source_sha256'])==183
back=copy.deepcopy(nexta)
for p in owned:back['owned'][p]=copy.deepcopy(authority['owned'][p])
back['source_sha256']=copy.deepcopy(authority['source_sha256']);assert enc(back)==before
assert all(nexta['source_sha256'][p]==h for p,h in authority['source_sha256'].items())
execution=out('execution_successor_READY.json',enc(nexta))
proof=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='FIVE_EXISTING_OWNED_EDGES_ORDINARY_PRELAYERS_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contractinfo,temple_binding=bindinginfo,execution=dict(parent=parents[EX],candidate=execution,changed_existing_owned=owned,owned_count=10,old_proof_count=176,new_proof_count=183,extra=extra,old176_values_all_edges_retained=True,depth_limit=16,no_shortcut=True,whole_typed_UTF8_inverse=True),canonical_writes=0,engine_calls=0,Stage_calls=0)))
assert not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
 with (OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(proof=proof,records={p:r['candidate']for p,r in records.items()},contract=contract,temple_binding=binding,execution=execution,ordinary=ordinary)))
