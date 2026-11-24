"""Static data/bytes audit; never import or execute any production Stage module."""
from pathlib import Path
import ast
import copy
import hashlib
import json

QA=Path(__file__).resolve().parent
GAME=QA.parents[1]
SRC=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
D=SRC/'performance42_culture24_source_recipe'
P=SRC/'performance41_culture24_source_recipe'
checks=[]
def ck(v,m):
    assert v,m
    checks.append(m)
def p(r): return GAME/r[6:] if str(r).startswith('res://') else Path(r)
def raw(r): return p(r).read_bytes()
def sha(r): return hashlib.sha256(raw(r)).hexdigest()
def load(r): return json.loads(raw(r))
def same(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return list(a)==list(b) and all(same(a[k],b[k])for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(same(x,y)for x,y in zip(a,b))
    return a==b
def at(v,keys):
    for k in keys:v=v[k]
    return v
tool=SRC/'stage_performance42_culture24_READY.py'
ip=D/'source_input_ROOT_LOCKED.json'
ck(sha(tool)=='13a460cac31cc565328a887a50200a9672d9e461b4f1164c7978ab7009c32df2','final driver pin')
ck(sha(ip)=='decabd917e9a3526c561cdcd0ed3f91e12406696d1a30ae72cad281597b8f277','final input pin')
t=raw(tool).decode('utf-8');s=load(ip)
ast.parse(t) # Python syntax only: no import, constructor or Stage invocation.
pr=load(D/'schema_adapter_and_input_inverse_READY.json')
before=raw(pr['parent_driver']['path']);new=raw(tool)
ck(sha(pr['parent_driver']['path'])==pr['parent_driver']['sha256'],'parent41 tool pin')
f=before
for h in pr['driver_unique_replacements']:
    a,b=h['old'].encode(),h['new'].encode();ck(f.count(a)==1,'unique schema forward');f=f.replace(a,b,1)
ck(f==new,'42 full forward bytes from41')
for h in reversed(pr['driver_unique_replacements']):new=new.replace(h['new'].encode(),h['old'].encode(),1)
ck(new==before,'42 full inverse bytes to41')
parentinput=load(pr['parent_input']['path']);inv=copy.deepcopy(s)
inv['required_generator']=parentinput['required_generator']
newpin=[x for x in inv['pinned_inputs']if x['id']=='culture_dependency_independent_review']
ck(len(newpin)==1 and sha(newpin[0]['path'])==newpin[0]['sha256']=='1fb6968b3f142784bc8ebdbd2d468b2365be825be85ac31064480e9cb93bee2e','one new QA fixed pin')
inv['pinned_inputs']=[x for x in inv['pinned_inputs']if x['id']!='culture_dependency_independent_review']
del inv['B_only_contract']['independent_dependency_review_input']
ck(same(inv,parentinput),'42 input full ordered typed inverse to41')
ck((json.dumps(inv,ensure_ascii=False,indent=2)+'\n').encode()==raw(pr['parent_input']['path']),'42 input UTF8 inverse to41')
oldproof=load(P/'driver_and_input_whole_inverse_READY.json')
oldtool=raw(oldproof['parent_tool']['path']);fortyone=raw(oldproof['new_tool']['path'])
ck(hashlib.sha256(oldtool).hexdigest()==oldproof['parent_tool']['sha256'],'71C6 inherited driver pin')
chunks=[];pos=0
for h in oldproof['tool_hunks']:
    ck(oldtool[h['old_start']:h['old_end']]==h['old'].encode(),'41 offset old slice')
    ck(fortyone[h['new_start']:h['new_end']]==h['new'].encode(),'41 offset new slice')
    chunks.extend([oldtool[pos:h['old_start']],h['new'].encode()]);pos=h['old_end']
chunks.append(oldtool[pos:]);ck(b''.join(chunks)==fortyone,'41 full offset forward bytes from71C6')
oldinput=load(oldproof['parent_input']['path']);work=copy.deepcopy(parentinput)
for h in reversed(oldproof['input_deltas']):
    ck(same(at(work,h['pointer']),h['new']),'41 input exact typed new delta')
    holder=at(work,h['pointer'][:-1]);holder[h['pointer'][-1]]=copy.deepcopy(h['old'])
ck(same(work,oldinput),'41 input full ordered typed inverse to parent35')
ck((json.dumps(work,ensure_ascii=False,indent=2)+'\n').encode()==raw(oldproof['parent_input']['path']),'41 input full UTF8 inverse to parent35')
pins={x['id']:x for x in s['pinned_inputs']}
ck(len(pins)==len(s['pinned_inputs'])==48,'48 unique fixed inputs')
ck(s['status']=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and s['blockers']==[],'locked input no blockers')
small=0;inherited_large=[]
oldpins={x['id']:x for x in parentinput['pinned_inputs']}
for key,row in pins.items():
    if p(row['path']).stat().st_size<=1048576:
        ck(sha(row['path'])==row['sha256'],'small fixed input current '+key);small+=1
    else:
        ck(oldpins.get(key)==row,'large immutable pin declaration unchanged '+key);inherited_large.append(key)
c=s['B_only_contract'];root=load(pins[c['scope_input']]['path']);backups=load(pins[c['backup_input']]['path']);scope=load(pins[c['scope_request_input']]['path'])
ck(same(root,c['expected_scope_document']),'Root31 actual document typed exactly matches input')
ck(root['old_full_backups_sha256']==sha(pins[c['backup_input']]['path'])=='3a817cc0b9205df9909603715f8e077fafef4747bad0731d36788bf041b9bdb9','actual3A817 backup document pin')
ck(backups['target_count']==24 and len(backups['targets'])==24,'actual target_count/targets schema')
expected={x['target']:x['old_sha256']for x in scope['targets']};mapped={}
for row in backups['targets']:
    prod=Path(row['path']).resolve();bp=Path(row['backup_path']).resolve()
    ck(prod.is_relative_to(GAME) and bp.is_relative_to(GAME),'backup domain')
    key='res://'+prod.relative_to(GAME).as_posix();ck(key not in mapped,'unique actual backup target')
    mapped[key]=row['sha256']
    # These24 are metadata/code only, never native or image files.
    ck(sha(bp)==row['sha256'] and len(raw(bp))==row['bytes'] and raw(bp)==raw(prod),'full backed old exact bytes '+key)
ck(mapped==expected and s['root_target_allowlist']==[x['target']for x in scope['targets']],'actual path/sha256 schema projects exact24 old targets')
ck(sum(k.endswith('.gd')for k in expected)==10 and sum(k.endswith('.json')for k in expected)==14,'10GD14JSON partition')
nodes={r['id']:r for r in s['nodes']};owned=load(pins[s['authority_input']]['path'])['owned']
def promoted(v):
    x=copy.deepcopy(v)
    for k in x:
        if k in owned:x[k]=owned[k]['current_sha256']
    return x
opcount=0
for row in s['nodes']:
    if row['kind'] in ('metadata','culture_contract_literal','map'):
        base=load(pins[row['base_input']]['path'])
        value={'source_sha256':promoted(base['source_sha256'])}if row['kind']=='map'else copy.deepcopy(base)
        for op in row.get('operations',[]):
            holder=at(value,op['pointer'][:-1]);key=op['pointer'][-1]
            ck((key in holder)==op['existed'] and (not op['existed']or same(holder[key],op['old'])),'exact raw/promote-first operation old '+row['id'])
            ck(op['pointer'][0] in {'source_sha256','owned_source_sha256','legacy_source_sha256','runtime_authority_sha256','registry_sha256','source_migration','ap_source_successor'},'source-only operation '+row['id'])
            if op['op']=='remove':del holder[key]
            else:holder[key]=op['new']
            opcount+=1
    if row['kind']=='index':
        b=raw(pins[row['base_input']]['path']);ck(b.endswith(b'\n') and b'\r'not in b and not b.startswith(b'\xef\xbb\xbf'),'index original strictLF '+row['id'])
        b.decode('utf-8')
        ck(all(isinstance(h['old'],str)and raw(pins[row['base_input']]['path']).count(h['old'].encode())==1for h in row['replacements']),'index unique literal sources '+row['id'])
        ck(all(isinstance(h['new'],dict)and set(h['new'])=={'$sha'}or h['new']=='const FORMAL_ENABLED=false'for h in row['replacements']),'index only SHA or boolean replacements preserve LF '+row['id'])
literal=nodes['runtime_contract_final']
ck(literal['kind']=='culture_contract_literal' and len(literal['operations'])==1 and not literal.get('source_fields')and not literal.get('source_bundle'),'contract exactly one op without group/promotion')
b=raw(pins[literal['base_input']]['path']);a=raw(pins[literal['literal_candidate_input']]['path'])
old=b'8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b';new=b'b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be'
ck(hashlib.sha256(b).hexdigest()=='7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e'and hashlib.sha256(a).hexdigest()=='59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1','contract exact7EE/59CF')
ck(b.count(old)==1 and a.count(new)==1 and b.replace(old,new)==a and a.replace(new,old)==b,'contract full raw-byte one-value inverse')
ck("super().build_node(work)"in t and "work['kind']='metadata';del work['literal_candidate_input']"in t and "whole_typed_inverse"in t,'special literal retains original metadata source-only/wholetyped path before exact byte overlay')
for row in s['pass_through_targets']:
    if row['target'].endswith('.gd'):
        for ref in (row['target'],row['candidate_path']):
            b=raw(ref);b.decode('utf-8');ck(b.endswith(b'\n')and b'\r'not in b and not b.startswith(b'\xef\xbb\xbf'),'pass GD strictLF '+ref)
ck(len([r for r in s['nodes']if r['kind']=='index'])==8 and len(s['pass_through_targets'])==3,'8index plus2code strictLF; execution JSON separate')
fy=nodes['finite08_yamen'];base=load(pins[fy['base_input']]['path'])
T='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
rt=base['runtime_authority_sha256'];lg=base['legacy_source_sha256']
four=[k for k in rt if k.startswith(T)]
ck(len(four)==4 and not any(k.startswith(T)for k in lg),'all4T native/header leaves remain runtimeauthority')
ck(any(r['prefix']==T and r['destination']==['runtime_authority_sha256']for r in fy['source_bundle']['new_source_routes']),'future T routed runtimeauthority notlegacy')
ck(all(op['op']=='set'for op in fy['operations'])and not any(op['pointer'][0]=='legacy_source_sha256' and str(op['pointer'][-1]).startswith(T)for op in fy['operations']),'no T class move or native removal')
ck("M._strict_lf_build_file_patch"in t and '_exact_eof_transport_patch'not in t,'all10GD original strict transport, noEOF extension')
ck("ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED"in t and t.index("ALL_PINNED_SOURCE_FIRST_FINAL_SAME")<t.index("with dest.open('xb')"),'all FIRSTFINAL/inverses buffered before any new output')
ck(sha(SRC/'stage_unified06_04_READY.py')=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28','original core8DE0 byte identity unchanged')
out=QA/'culture42_13A460_DECABD_independent_final_static_admission_READY.json'
ck(not out.exists(),'NEW receipt absent')
out.write_text(json.dumps({'status':'CULTURE42_STATIC_NO_BLOCKER_FOR_ONE_ROOT_CONTROLLED_STAGE_NOT_EXECUTED_BY_QA','driver_sha256':sha(tool),'input_sha256':sha(ip),'checks':len(checks),'Root31_schema':'actual target_count24/targets/path absolute/sha256/bytes/backup_path projected exactly24','full_old_backup_bytes_checked':24,'fixed_inputs48':{'small_SHA_checked':small,'large_declarations_inherited_without_rehash':inherited_large},'strict_EOF':{'GD10':True,'original8index_literal_only':True,'2code_parent_and_candidate_UTF8_LF_noCR_noBOM':True,'adapter_not_target_noEOFextension':True},'original_metadata_wholetyped_then_exact7EE_59CF_one_literal_inverse':True,'ops_old_value_checks':opcount,'all4T_runtimeauthority_preserved':True,'driver42_to41_fullbyte_inverse':True,'driver41_to71C6_fullbyte_offset_forward':True,'input42_to41_to35_fullorderedtyped_UTF8_inverse':True,'stage_engine_collector_native_or_media_decode_formal_calls':0,'boundaries':['This is static readiness for one Root-authorized Stage, not actual outputs or deployment proof','No original full-source or media rehash; final Stage must execute untouched48pins/FIRSTFINAL and whole metadata/groups gates','Initial41 schema assumption preserved unexecuted; only42 is admitted','07 FAIL/C0000005 retained; no new performance or complete-city claim']},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'checks':len(checks),'small_pins':small,'inherited_large_pin_count':len(inherited_large),'opcount':opcount}))
