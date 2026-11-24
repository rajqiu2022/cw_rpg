"""NEW Root25 exact22 thin driver/input from actual AP13; no Stage import/run."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance25_canonical_B_source_recipe/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration25/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
oldtoolpath=S+'stage_performance13_B_only_PREPARATION_ONLY.py';oldtoolsha='0c709b1da8fcc823d41d25d771ca4fe179f82d0288b9111ef31b87122a037fc2'
oldtool=fixed(oldtoolpath,oldtoolsha);tool=oldtool.decode()
toolchanges=[
 ("PARENT='428a3484e0a995803d95677dbd36f545313c622142605fce292ffd493b6bea03'","PARENT='a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283'"),
 ("PROPOSAL='a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283'","PROPOSAL='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'"),
 ("HAND='0b475ef75769431cb02b46a2a6e3daab6312ab3a7289b837d361ad2bdedfb79c'","HAND='3a6200e99bd2a9c2e9ce19aa47eb06f4bb84ba15099e2058bd21de2117f2ce7d'"),
 ("REQUEST='0df58c434b6bf549c2fd7fcf37b4587a91067d7664a90ba588d95196dcb33b47'","REQUEST='8e23624053a9b6c317ccbe39cd6415c0e5455d96e1340a0a0b48f1b2491b4b50'"),
 ("BEFORE='0f0236cff802aebf4d416e0626b2505cf018a897557d703fd5bd1e6f97c67332'","BEFORE='3b12823c4ca9d47397faa78e93b3f918bd6efba8729e79342c761cf6dbd957e5'"),
 ("len(prior['source_sha256'])==67 and len(self.authority['source_sha256'])==69","len(prior['source_sha256'])==69 and len(self.authority['source_sha256'])==71"),
 ('ALL_OLD67_PINS_UNCHANGED','ALL_OLD69_PINS_UNCHANGED'),('EXACT_DEPLOYED_B77_TO7123_EDGE','EXACT_DEPLOYED_AP13_B7123_TO9D5B_EDGE'),
 ('WHOLE_EXECUTION_TYPED_INVERSE428A','WHOLE_EXECUTION_TYPED_INVERSE_A816'),('ROOT21_FRESH_SCOPE_BASELINE','ROOT25_FRESH_SCOPE_BASELINE'),
 ('d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282','7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf'),
 ('FIXED_ACTUAL_D058_PARENT_NOT_CURRENT_COLLECTOR','FIXED_ACTUAL_AP13_7912_PARENT_NOT_CURRENT_COLLECTOR'),('ALL22_PARENT_VALUES_FROM_ACTUAL_D058','ALL22_PARENT_VALUES_FROM_ACTUAL_AP13_7912'),
 ('77dfc4987f21fa280c526cf62cb6c94316a40c4236fb1005761408859a0b8c16','71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57'),
 ('EXACT428A_TO_A816_EXECUTION_BYTES','EXACT_A816_TO03C4_EXECUTION_BYTES'),('fixed_Root_428A_toA816_authority_inverse','fixed_Root_A816_to03C4_authority_inverse')]
for a,b in toolchanges:
    assert tool.count(a)==1,(a,tool.count(a));tool=tool.replace(a,b,1)
anchor="        need(all(any(r['target']==path and r['candidate_sha256']==s for r in parent_stage['targets']) for path,s in self.oldtargets.items()),'ALL22_PARENT_VALUES_FROM_ACTUAL_AP13_7912')\n"
extra="        prior_owner=self.read_json_input(c['prior_owner_input'])\n        need(self.inputs[c['prior_owner_input']]['sha256']=='5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e' and prior_owner.get('actual_stage_receipt',{}).get('sha256')=='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf' and prior_owner.get('expected_not_derived_from_live_collector_or_canonical_hash_crawl') is True,'FIXED_AP13_INDEPENDENT_OWNER5050_NOT_OBSERVED_FILL')\n"
assert tool.count(anchor)==1;tool=tool.replace(anchor,anchor+extra,1)
toolbytes=tool.encode();ast.parse(toolbytes)
toolpath=S+'stage_performance25_canonical_B_READY.py'
oldinputpath=S+'performance14_B_only_source_recipe/source_input_ROOT_LOCKED.json';oldinputsha='231b66e6beaebdf7c72966e2ce1a19ee56bb3a643f254fbbe20efbcc6f713697'
oldinputbytes=fixed(oldinputpath,oldinputsha);old=json.loads(oldinputbytes)
stagepath=S+'outputs/root_B_only_symmetric_wire_stage01/receipt.json';stagesha='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf'
stage=json.loads(fixed(stagepath,stagesha))
handpath=S+'performance24_canonical_B_dependencies/handoff_PRODUCTION_PROPOSAL.json';handsha='3a6200e99bd2a9c2e9ce19aa47eb06f4bb84ba15099e2058bd21de2117f2ce7d'
hand=json.loads(fixed(handpath,handsha));approval=json.loads(fixed(hand['execution_proposal']['path'],hand['execution_proposal']['sha256']))
request=json.loads(fixed(hand['scope_request']['path'],hand['scope_request']['sha256']))
scopepath=R+'scope22_full_old_backups_READY.json';scopesha='e12015172ba201b9b5cee989e617d42d9ea30b0f5865d859928b58bb1ac6229f';scope=json.loads(fixed(scopepath,scopesha))
rootpath=R+'execution_successor_preparation_approval_READY.json';rootsha='cea7e23ae7d79af8933a0871ce83178c0cceb465a3a31672b4aa9492af2840ed';root=json.loads(fixed(rootpath,rootsha))
assert scope['approved_by_root']is True and scope['target_count']==22 and scope['GD_count']==9 and scope['JSON_count']==13 and scope['proposal_sha256']==hand['scope_request']['sha256'] and scope['before_sha256']=='3b12823c4ca9d47397faa78e93b3f918bd6efba8729e79342c761cf6dbd957e5'
assert root['approved_by_root']is True and root['execution_proposal_sha256']==hand['execution_proposal']['sha256'] and root['parent_actual_stage_sha256']==stagesha and root['full22_old_backup_sha256']==scopesha
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,path,s):pins[i]={'id':i,'path':path,'sha256':s};return {'$pin':i}
pin('execution_approval',hand['execution_proposal']['path'],hand['execution_proposal']['sha256'])
pin('B_only_parent_approval',hand['execution_parent']['snapshot'],hand['execution_parent']['sha256'])
pin('B_only_production',handpath,handsha);pin('B_only_scope_request',hand['scope_request']['path'],hand['scope_request']['sha256'])
pin('B_only_actual_parent_stage',stagepath,stagesha);pin('B_only_scope',scopepath,scopesha);pin('B_only_root_execution',rootpath,rootsha)
pin('canonical_prior_owner',S+'performance15_B_only_actual_independent_review/owner_source_maps_READY.json','5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e')
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd';EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
edge=hand['owned_changed_exactly1'][0];refs={B:edge['new_sha256'],EXE:{'$pin':'execution_approval'}}
targetolds={r['target']:r['old_sha256']for r in request['targets']};cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    a=stage['nodes'][n['id']];raw=fixed(a['path'],a['sha256'])
    cur[n['id']]={**a,'bytes':raw,'value':json.loads(raw)if n['kind']!='index'and n['id']!='ap_environment_index'else None}
    if n.get('target')in targetolds:refs[n['target']]={'$sha':n['id']}
def known(ref):
    if isinstance(ref,dict)and set(ref)=={'$pin'}:return pins[ref['$pin']]['sha256']
    if isinstance(ref,dict)and set(ref)=={'$owned'}:return approval['owned'][ref['$owned']]['current_sha256']
    if isinstance(ref,dict)and '$sha'in ref:return None
    return ref
def source_ops(base,fields):
    result=[]
    for keys in fields:
        table=ptr(base,keys)
        for path,ref in refs.items():
            if path in table and (known(ref)is None or table[path]!=known(ref)):result.append({'op':'set','pointer':keys+[path],'existed':True,'old':table[path],'new':ref})
    return result
nodes=[]
for oldn in old['nodes']:
    n=copy.deepcopy(oldn);ident=n['id']
    if n['kind']=='map':
        for op in n['operations']:
            if op['pointer'][-1]in refs:op['new']=refs[op['pointer'][-1]]
        assert not any(op['pointer'][-1]in approval['owned']for op in n['operations']);nodes.append(n);continue
    c=cur[ident];inputid='B_parent_'+ident;pin(inputid,c['path'],c['sha256']);n['base_input']=inputid
    if n.get('target'):n['old_sha256']=c['sha256'];assert c['sha256']==targetolds[n['target']]
    if n['kind']=='B_only_frozen_node':assert n['immutable_sha256']==c['sha256'];nodes.append(n);continue
    if n['kind']=='index':
        replacements=[]
        for rep in n['replacements']:
            if rep['old']=='const FORMAL_ENABLED=true':replacements.append(rep);continue
            ref=rep['new'];before=cur[ref['$sha']]['sha256']if isinstance(ref,dict)and '$sha'in ref else hand['execution_parent']['sha256']if ref=={'$pin':'execution_approval'}else rep['old']
            assert c['bytes'].decode().count(before)==1;replacements.append({'old':before,'new':ref})
        n['replacements']=replacements;nodes.append(n);continue
    fields=[f['pointer']for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[])
    n['operations']=source_ops(c['value'],fields);nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for path,ref in refs.items():
            if path in group['leaves']:group['leaves'][path]=ref
spec=copy.deepcopy(old)
spec.update(output_root=S+'outputs/root_B_canonical_keys_stage01/',source_groups=groups,nodes=nodes,
 prospective_targets=[{'target':B,'candidate_path':edge['new_snapshot'],'sha256':edge['new_sha256']}],
 pass_through_targets=[{'target':B,'old_sha256':edge['old_sha256'],'candidate_path':edge['new_snapshot'],'candidate_sha256':edge['new_sha256']},
 {'target':EXE,'old_sha256':hand['execution_parent']['sha256'],'candidate_path':hand['execution_proposal']['path'],'candidate_sha256':hand['execution_proposal']['sha256']}],
 root_target_allowlist=[r['target']for r in request['targets']],required_generator={'path':toolpath,'sha256':sha(toolbytes)},
 source_baseline='Frozen AO independent maps plus actualAP13 7912 metadata/5050 independent owner; only B7123-to9D5B successor and2 exact proof leaves, no current collector expectations')
c=spec['B_only_contract'];c['actual_parent_stage_sha256']=stagesha;c['prior_owner_input']='canonical_prior_owner'
c['new_proof_pin_count']=71;c['original69_proof_pins_exact']=c.pop('original67_proof_pins_exact')
c['current_AP13_four_parent_classification_kept']=c.pop('current_AP12_four_parent_classification_kept')
c.update(expected_scope_sha256=scopesha,expected_scope_document=scope,expected_root_execution_sha256=rootsha,expected_root_execution_document=root)
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input']and isinstance(x,str)and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(spec['required_gates']);used.update(v for v in c.values()if isinstance(v,str)and v in pins)
spec['pinned_inputs']=[row for row in pins.values()if row['id']in used]
for row in spec['pinned_inputs']:fixed(row['path'],row['sha256'])
assert set(r['target']for r in spec['pass_through_targets'])|{n['target']for n in nodes if'target'in n}==set(targetolds)
def byte_changes(a,b):
    aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
    for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
        if tag!='equal':hs.append({'old_byte_start':len(''.join(aa[:i]).encode()),'old_byte_end':len(''.join(aa[:j]).encode()),'new_byte_start':len(''.join(bb[:k]).encode()),'new_byte_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
    fwd=a;back=b
    for h in reversed(hs):fwd=fwd[:h['old_byte_start']]+h['new'].encode()+fwd[h['old_byte_end']:]
    for h in reversed(hs):back=back[:h['new_byte_start']]+h['old'].encode()+back[h['new_byte_end']:]
    assert fwd==b and back==a;return hs
def typed_changes(a,b,path=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():
        return [op for k in a for op in typed_changes(a[k],b[k],path+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):
        return [op for i in range(len(a))for op in typed_changes(a[i],b[i],path+[i])]
    if type(a)is type(b)and a==b:return []
    return [{'pointer':path,'old':a,'new':b}]
typed=typed_changes(old,spec);back=copy.deepcopy(spec)
for d in reversed(typed):holder=ptr(back,d['pointer'][:-1]);assert holder[d['pointer'][-1]]==d['new'];holder[d['pointer'][-1]]=copy.deepcopy(d['old'])
assert back==old and js(back)==oldinputbytes
toolhs=byte_changes(oldtool,toolbytes)
td=''.join(difflib.unified_diff(oldtool.decode().splitlines(True),toolbytes.decode().splitlines(True),fromfile=oldtoolpath,tofile=toolpath)).encode()
proof={'status':'PURE_CANONICAL_B_INPUT_TYPED_AND_THIN_DRIVER_BYTE_INVERSE_NOT_STAGE','passed':True,
 'parent_tool':{'path':oldtoolpath,'sha256':oldtoolsha},'new_tool':{'path':toolpath,'sha256':sha(toolbytes)},'whole_tool_forward_and_inverse':True,'tool_hunks':toolhs,
 'parent_input':{'path':oldinputpath,'sha256':oldinputsha},'whole_input_typed_and_serialized_byte_inverse':True,'input_deltas':typed,
 'unchanged_imported_validation_core':{'path':S+'stage_unified06_04_READY.py','sha256':'8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'},
 'actual_AP13_parent_7912_and_independent_owner5050_required':True,'22_target_9GD13JSON_unchanged_domain':True,'native_and_four_T_authority_classification_unchanged':True,'Stage_engine_collector_native_decode_calls':0}
inputpath=O+'source_input_ROOT_LOCKED.json';inputbytes=js(spec)
handout={'status':'ROOT25_CANONICAL_B_EXACT22_DRIVER_INPUT_PREPARED_NOT_STAGED','input':{'path':inputpath,'sha256':sha(inputbytes)},'tool':{'path':toolpath,'sha256':sha(toolbytes)},
 'inverse':{'path':O+'driver_and_input_whole_inverse_READY.json','sha256':sha(js(proof))},'tool_complete_diff':{'path':O+'driver_vs_0C709_complete.diff','sha256':sha(td)},'pinned_inputs':len(spec['pinned_inputs']),'targets':22,'GD':9,'JSON':13,
 'Root_only_command_not_executed':'python '+str(p(toolpath))+' '+str(p(inputpath))+' --input-sha256 '+sha(inputbytes),'Stage_engine_collector_native_decode_calls':0}
files={toolpath:toolbytes,O+'source_input_ROOT_LOCKED.json':inputbytes,O+'driver_and_input_whole_inverse_READY.json':js(proof),O+'driver_vs_0C709_complete.diff':td,O+'handoff_READY_NOT_STAGED.json':js(handout)}
assert not p(O).exists()and not p(toolpath).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
