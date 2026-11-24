"""Root-approved exact Temple shortcut, unchanged range16 and all old edges."""
from pathlib import Path
import json,hashlib,copy,difflib,collections
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024c_source01/'
OUT=HERE/'temple_depth_residual02';OUT.mkdir(exist_ok=False);PREFIX=S+'temple_depth_residual02/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h and b'tokens truncated' not in b;return b
def out(name,b):
    with (OUT/name).open('xb') as f:f.write(b)
    return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
ep=S+'code_dependencies30_READY/execution_successor_PREPARATION.json';eh='9e7b5166bcc8e93a69d2e5f136fe339635001ae17215383f19b6427bebd3475f'
original=json.loads(read(ep,eh));value=copy.deepcopy(original);p='res://scripts/city/luoyang_temple_assembly_20261016.gd';row=value['owned'][p]
oldedge=row['edges'][0];newedge=row['edges'][-1];assert len(row['edges'])==16
before=read(oldedge['old_snapshot'],oldedge['old_sha256']);after=read(newedge['new_snapshot'],newedge['new_sha256'])
assert oldedge['old_sha256']=='3a033cc56525997ee3b7d96b87d08f19f6088accba8d35b183641ffd886f2827' and newedge['new_sha256']=='60efcd07834e4b245551becec6e656420989dbf771d983714c51c6953c8e93dc'
assert value['source_sha256'][oldedge['old_snapshot']]==sha(before) and value['source_sha256'][newedge['new_snapshot']]==sha(after)
left,right=before.decode().splitlines(keepends=True),after.decode().splitlines(keepends=True)
for context in [3,6,12,24,48,96,max(len(left),len(right))]:
    hunks=[dict(old=''.join(left[g[0][1]:g[-1][2]]),new=''.join(right[g[0][3]:g[-1][4]])) for g in difflib.SequenceMatcher(None,left,right,autojunk=False).get_grouped_opcodes(context)]
    f,i=before.decode(),after.decode();good=True
    for h in hunks:
        if f.count(h['old'])!=1 or i.count(h['new'])!=1:good=False;break
        f=f.replace(h['old'],h['new'],1);i=i.replace(h['new'],h['old'],1)
    if good and f.encode()==after and i.encode()==before:break
else:raise AssertionError('EXACT_HISTORICAL_SHORTCUT_WHOLEBYTE_INVERSE')
shortcut=dict(path=p,old_sha256=sha(before),new_sha256=sha(after),old_snapshot=oldedge['old_snapshot'],new_snapshot=newedge['new_snapshot'],whole_inverse=True,replacements=hunks)
row['edges'].append(shortcut)
restored=copy.deepcopy(value);assert restored['owned'][p]['edges'].pop()==shortcut
assert restored==original and enc(restored)==read(ep,eh)
assert value['source_sha256']==original['source_sha256'] and len(value['source_sha256'])==139 and len(value['owned'])==10
execution=out('execution_successor_PREPARATION.json',enc(value))
pp=S+'code_dependencies30_READY/seven_code_execution_whole_inverse_NOT_STAGE.json';ph='559c7447719c31305ae27b90557f8223349704c5cb59a7d4e674eb31e0a7326c';proof=json.loads(read(pp,ph))
proof['execution']['candidate']=execution;proof['execution']['historical_shortcut']=shortcut;proof['execution']['historical_shortcut_sha256']=sha(enc(shortcut));proof['execution']['historical_shortcut_only_member']=p
proof['execution']['changed_existing_owned_count_remains']=5;proof['execution']['new_actual_code_edges']=5;proof['execution']['new_historical_shortcuts']=1
proof['status']='24C_EXACT30_FIVE_REAL_EDGES_ONE_EXACT_HISTORICAL_TEMPLE_SHORTCUT_NOT_STAGE'
pr=out('seven_code_execution_whole_inverse_NOT_STAGE.json',enc(proof))
dp=S+'stage_courts_scholar30_NOTREADY.py';dh='007835570ff10f00a9621c55cf47c6c0ebb5d407e87b09d578e0ad4956fefd44';old_driver=read(dp,dh);text=old_driver.decode();edits=[]
def change(a,b):
    global text
    assert text.count(a)==1,(a[:70],text.count(a));i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
change("            record, edge = self.codes[p], new['edges'][-1]\n            need(len(new['edges']) == len(old['edges']) + 1 and same(new['edges'][:-1], old['edges'])",'''            shortcut_member = 'res://scripts/city/luoyang_temple_assembly_20261016.gd'
            extra_count = 2 if p == shortcut_member else 1
            record, edge = self.codes[p], new['edges'][-extra_count]
            if p == shortcut_member:
                shortcut = self.proof['execution']['historical_shortcut']
                need(same(new['edges'][-1], shortcut)
                     and sha(encode(shortcut)) == self.proof['execution']['historical_shortcut_sha256']
                     and shortcut['path'] == p and shortcut['old_sha256'] == '3a033cc56525997ee3b7d96b87d08f19f6088accba8d35b183641ffd886f2827'
                     and shortcut['new_sha256'] == record['candidate']['sha256']
                     and shortcut['new_snapshot'] == record['candidate']['path']
                     and self.authority['source_sha256'].get(shortcut['old_snapshot']) == shortcut['old_sha256']
                     and self.authority['source_sha256'].get(shortcut['new_snapshot']) == shortcut['new_sha256'], 'ONLY_EXACT_PINNED_TEMPLE_HISTORICAL_SHORTCUT')
            need(len(new['edges']) == len(old['edges']) + extra_count and same(new['edges'][:-extra_count], old['edges'])''')
compile(text,'stage_courts_scholar30_residual02_NOTREADY.py','exec')
back=text.encode()
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert back[i:i+len(b)]==b;back=back[:i]+a+back[i+len(b):]
assert back==old_driver
driver=out('stage_courts_scholar30_residual02_NOTREADY.py',text.encode())
ip=S+'source_input_courts_scholar30_READY_FOR_ROOT_REVIEW.json';ih='fd745c8c2a1eb54d1b28277fc7233b63598c07b8e3ca1e3469c20ba4b9d10357';old_input=json.loads(read(ip,ih));spec=copy.deepcopy(old_input)
for r in spec['pinned_inputs']:
    if r['id']=='execution_approval':r.update(path=execution['path'],sha256=execution['sha256'])
    if r['id']=='space_code_inverse':r.update(path=pr['path'],sha256=pr['sha256'])
spec['required_generator']={k:driver[k] for k in ['path','sha256']}
spec['output_root']=S+'outputs/root_courts_scholar_exact30_stage02/'
for r in spec['pass_through_targets']:
    if r['target']=='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json':r.update(candidate_path=execution['path'],candidate_sha256=execution['sha256'])
for r in spec['prospective_targets']:
    if r['target']=='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json':r.update(candidate_path=execution['path'],sha256=execution['sha256'])
inp=out('source_input_courts_scholar30_residual02_ROOT_REVIEW.json',enc(spec))
inverse=copy.deepcopy(spec)
inverse['pinned_inputs']=copy.deepcopy(old_input['pinned_inputs']);inverse['required_generator']=copy.deepcopy(old_input['required_generator']);inverse['output_root']=old_input['output_root'];inverse['pass_through_targets']=copy.deepcopy(old_input['pass_through_targets']);inverse['prospective_targets']=copy.deepcopy(old_input['prospective_targets'])
assert inverse==old_input and enc(inverse)==read(ip,ih)
review=out('residual02_whole_inverse_BUILD.json',enc(dict(status='EXACT_TEMPLE_DEPTH_SHORTCUT_RESIDUAL02_NOT_RUN',execution_parent=dict(path=ep,sha256=eh),execution=execution,execution_one_edge_inverse=True,shortcut=shortcut,shortcut_sha256=sha(enc(shortcut)),hunk_count=len(hunks),prior_fixed_edges=16,post_shortcut_edges=17,source_keys_entirely_unchanged_139=True,driver_parent=dict(path=dp,sha256=dh),driver=driver,driver_edits=edits,driver_whole_byte_inverse=True,input_parent=dict(path=ip,sha256=ih),input=inp,input_exact_changed_fields=['pinned_inputs.execution_approval','pinned_inputs.space_code_inverse','required_generator','output_root','pass_through_targets.execution_candidate','prospective_targets.execution_candidate'],input_whole_typed_and_serialized_UTF8_inverse=True,code_inverse=pr,core_range16_unchanged=True,all_previous_historical_edges_preserved=True,only_Temple_second_appended_edge=True,engine_calls=0,Stage_calls=0,collector_calls=0,canonical_writes=0)))
print(json.dumps(dict(driver=driver,input=inp,execution=execution,review=review,code_inverse=pr,shortcut_hunks=len(hunks))))
