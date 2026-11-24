"""Build one exact3 SOURCE_ONLY recipe after Root admission; never Stage."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1];S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance51_market_tuple3_source_recipe/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
tp=S+'stage_performance48_estate17_READY.py';ts='868c36954db0397c320a93eb04ab4f9ff95f3cf1e1d5c432ab1fa06de1d0c0c8';oldtool=fixed(tp,ts)
ip=S+'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json';iss='c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a';oldinput=fixed(ip,iss);old=json.loads(oldinput)
stagep=S+'outputs/root_estate_registry_scalar17_stage01/receipt.json';stages='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7';stage=read(stagep,stages)
scopep=S+'performance50_market_autoimport_exact3_pending_scope_READONLY.json';scopes='cba12cace9f6ffb44be694ce6a27ccc9152793e460c2e03e79c109b8fa151342';scope=read(scopep,scopes)
rootp=R+'integration39/source_only_two_leaf_admission.json';roots='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4';admit=read(rootp,roots)
backp=R+'integration40/old_full_backups_READY.json';backs='c36a4468c463554402fdb1d3a8e7e363a7fb974e30ee8e50da9929bc3177611f';back=read(backp,backs)
beforep=R+'integration40/guard_before.json';befores='43c680af9d180b0e7c8330d28ad5671faaa24da2329129d74307bb8f9ee98987'
capturep=R+'integration39/proof_autoimport_tuple_before_retry1.json';captures='19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296'
afterp=R+'integration39/proof_tuple_after_exactfacts.json';afters='2d30691c5ceaf6b4b5657c445d147d13985c30edef24dbf0d882f25d207bec05'
qap='res://build/luoyang_city_full_rollout_20261022ap_qa01/proof_tuple39_117100_SOURCE_ONLY_two_leaf_evidence_independent_review_READY.json';qas='e935cede7865d93a98b67919872609d1db1ef19682fd154d008c9c5a9f08c202';qa=read(qap,qas)
reportp='res://build/luoyang_city_full_rollout_20261022ap_qa01/proof_source_tuple_ROOT39_READY/output/117100_84/result.json';reports='7477cdb2826f96d0d915bf51ab5da534f1fb24729e0d2f1c145c776c645dccc7'
ownerp=S+'performance49_estate17_actual_independent_review/owner_source_maps_READY.json';owners='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
allow={r['target']:r['old_sha256']for r in scope['targets']};assert back['target_count']==len(allow)==3 and back['scope_sha256']==scopes
assert {'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r['sha256']for r in back['targets']}==allow
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,v,s):pins[i]={'id':i,'path':v,'sha256':s}
for i,v,s in [('tuple3_scope',scopep,scopes),('tuple3_admission',rootp,roots),('tuple3_backups',backp,backs),('tuple3_before',beforep,befores),('tuple3_capture',capturep,captures),('tuple3_after',afterp,afters),('tuple3_qa',qap,qas),('tuple3_actual',reportp,reports),('tuple3_prior_stage',stagep,stages),('tuple3_prior_owner',ownerp,owners)]:pin(i,v,s)
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    r=stage['nodes'][n['id']];b=fixed(r['path'],r['sha256']);cur[n['id']]={**r,'bytes':b,'value':json.loads(b)if n['kind']!='index'and n['id']!='ap_environment_index'and not(n['kind']=='estate17_frozen'and not n['is_json'])else None}
refs={n['target']:{'$sha':n['id']}for n in old['nodes']if n.get('target')in allow};nodes=[];frozen={};groupid='source_only_proof_autoimport_exact2'
for original in old['nodes']:
    n=copy.deepcopy(original);ident=n['id']
    if n['kind']=='map':
        if n['scene_id']=='ch4_s3_luoyang_market':n['groups'].append(groupid)
        nodes.append(n);continue
    v=cur[ident];base='tuple3_parent_'+ident;pin(base,v['path'],v['sha256'])
    if n.get('target')not in allow:
        frozen[ident]=v['sha256'];nodes.append({'id':ident,'kind':'tuple3_frozen','base_input':base,'immutable_sha256':v['sha256'],'is_json':v['value']is not None});continue
    n['base_input']=base;n['old_sha256']=v['sha256'];assert allow[n['target']]==v['sha256']
    if n['kind']=='index':
        count=0
        for rep in n['replacements']:
            x=rep['new']
            if isinstance(x,dict)and '$sha'in x:
                rep['old']=cur[x['$sha']]['sha256'];assert v['bytes'].count(rep['old'].encode())==1
                if x['$sha']in ['market_final','finite08_market']:count+=1
        assert count==2;nodes.append(n);continue
    assert ident in ['market_final','finite08_market']and n['kind']=='metadata'
    n['operations']=[]
    for ks in n['source_bundle']['fields']:
        for path,x in refs.items():
            if path in ptr(v['value'],ks):n['operations'].append({'op':'set','pointer':ks+[path],'existed':True,'old':ptr(v['value'],ks)[path],'new':x})
    n['source_bundle']['groups'].append(groupid);nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for path,x in refs.items():
            if path in group['leaves']:group['leaves'][path]=x
groups.append({'id':groupid,'kind':'explicit','leaves':admit['source_leaves']})
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=groups,root_target_allowlist=list(allow),pass_through_targets=[],prospective_targets=[],output_root=S+'outputs/root_market_source_only_tuple3_stage01/',source_baseline='Fixed96CA formal metadata and5857 independent source maps plus Root39 SOURCE_ONLY exact2 preexisting autoimport leaves. Current detect1/fixalpha true retained. Only two Market legacy fields and two APCityIndex SHA literals; no new runtime/native or geometry authority.')
spec['B_only_contract']={'scope_input':'tuple3_scope','admission_input':'tuple3_admission','backup_input':'tuple3_backups','before_input':'tuple3_before','capture_input':'tuple3_capture','after_input':'tuple3_after','qa_input':'tuple3_qa','actual_input':'tuple3_actual','parent_stage_input':'tuple3_prior_stage','prior_owner_input':'tuple3_prior_owner','literal_group':groupid}
for gate in spec['required_gates']:
    if gate['input']=='estate17_Root_approval':gate['input']='tuple3_backups';gate['pointer']=['target_count'];gate['equals']=3
source=oldtool.decode();header=source[:source.index('FROZEN=')];header+='FROZEN='+repr(frozen)+'\nNEW_LEAVES='+repr(admit['source_leaves'])+'\n'
body='''class MarketSourceTupleStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_SOURCE_ONLY_TUPLE3')
        super().__init__(spec);c=spec['B_only_contract'];request=self.read_json_input(c['scope_input']);root=self.read_json_input(c['admission_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='cba12cace9f6ffb44be694ce6a27ccc9152793e460c2e03e79c109b8fa151342' and self.inputs[c['admission_input']]['sha256']=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4' and root.get('status')=='ROOT_EXPLICIT_NEW_SOURCE_ONLY_TWO_LEAF_ADMISSION' and root.get('approved_by_root') is True and same(root['source_leaves'],NEW_LEAVES),'EXACT_ROOT_SOURCE_ONLY_TWO_LEAF_ADMISSION')
        need(self.inputs[c['backup_input']]['sha256']=='c36a4468c463554402fdb1d3a8e7e363a7fb974e30ee8e50da9929bc3177611f' and self.inputs[c['before_input']]['sha256']=='43c680af9d180b0e7c8330d28ad5671faaa24da2329129d74307bb8f9ee98987' and backups.get('target_count')==3 and backups['scope_sha256']==self.inputs[c['scope_input']]['sha256'],'EXACT3_OLD_BACKUP_AND_ROOT40_FRESH')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==3 and list(self.oldtargets)==spec['root_target_allowlist'] and len(backups['targets'])==3,'EXACT3_ORDERED_TARGETS')
        backed={}
        for r in backups['targets']:
            target=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'EXACT_BACKUP_GAME_PATHS')
            path='res://'+target.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'COMPLETE_THREE_OLD_BYTE_BACKUPS')
        need(backed==self.oldtargets and self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and not spec['pass_through_targets'] and not spec['prospective_targets'],'NO_CODE_EXECUTION_NATIVE_SUCCESSOR')
        stage=self.read_json_input(c['parent_stage_input']);self.owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['parent_stage_input']]['sha256']=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7' and self.inputs[c['prior_owner_input']]['sha256']=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f','FIXED96CA_AND5857_NOT_CURRENT_FILL')
        prior={r['target']:r['candidate_sha256']for r in stage['targets']};need(all(prior.get(path)==s for path,s in self.oldtargets.items()),'CURRENT_OLD3_FROM_FIXED_STAGE_CANDIDATES')
        qa=self.read_json_input(c['qa_input']);actual=self.read_json_input(c['actual_input']);capture=self.read_json_input(c['capture_input']);after=self.read_json_input(c['after_input'])
        need(self.inputs[c['qa_input']]['sha256']==root['independent_review_sha256']=='e935cede7865d93a98b67919872609d1db1ef19682fd154d008c9c5a9f08c202' and self.inputs[c['actual_input']]['sha256']==root['actual_report_sha256']=='7477cdb2826f96d0d915bf51ab5da534f1fb24729e0d2f1c145c776c645dccc7','NEW_PIXEL_ACTUAL_AND_INDEPENDENT_REVIEW_PINS')
        need(actual.get('complete') is True and actual.get('failures')==[] and actual.get('import_calls')==0 and actual.get('collector_Field_Scene_geometry_calls')==0 and qa['checks']['complete'] is True and qa['checks']['failures']==0 and qa['checks']['23currentparams_fixalpha_true_detect1_unchanged'] is True,'SOURCE_ONLY_FULL_RGBA_ACTUAL_NO_RUNTIME_IMPORT_CREDIT')
        need(self.inputs[c['capture_input']]['sha256']==root['facts_before_sha256']=='19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296' and self.inputs[c['after_input']]['sha256']==root['facts_after_sha256']=='2d30691c5ceaf6b4b5657c445d147d13985c30edef24dbf0d882f25d207bec05' and qa['guard']['new3facts_before_after_exactticks_same'] is True,'CAPTURE_AND_AFTER_FACTS_BOUND_TO_NEW_PIXEL_PROOF')
        facts={'res://'+Path(r['path']).resolve().relative_to(M.ROOT).as_posix():r['sha256']for r in capture['facts']};need(all(facts.get(path)==s for path,s in NEW_LEAVES.items()) and root['raw_rgba_sha256']=='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da','EXACT_NEW_TWO_LEAVES_NOT_BORROWED_OLD_TUPLE')
        groups=[r for r in spec['source_groups']if r['id']==c['literal_group']];need(len(groups)==1 and same(groups[0],{'id':c['literal_group'],'kind':'explicit','leaves':NEW_LEAVES}),'EXACT_TWO_LITERAL_MEDIA_GROUP')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT3_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='tuple3_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'EXACT_FROZEN_OTHER_DOMAINS')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['id']in ['market_final','finite08_market']:
            before=self.read_json_input(row['base_input']);value=self.nodes[row['id']]['value'];expected=copy.deepcopy(before)
            for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
                for path,target in self.targets.items():
                    if path in expected[field]:need(expected[field][path]==target['old_sha256'],'EXACT_HEADER_OLD');expected[field][path]=target['candidate_sha256']
            for path,s in NEW_LEAVES.items():
                need(all(path not in before[field]for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']),'ONLY_TWO_NEW_LEAVES');expected['legacy_source_sha256'][path]=s
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse'] is True,'ONLY_LEGACY_TWO_AND_EXISTING_HEADER_SUCCESSION_FULL_TYPED_INVERSE')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:need(expected[path]==target['old_sha256'],'FIXED5857_HEADER_OLD');expected[path]=target['candidate_sha256']
            if row['scene_id']=='ch4_s3_luoyang_market':
                need(len(old)==1700 and not(set(old)&set(NEW_LEAVES)),'FIXED_MARKET1700');expected.update(NEW_LEAVES)
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_INDEPENDENT_AO_MAPS_EXACT_FIXED5857_PLUS3HEADERS_MARKET2_NO_COLLECTOR_FILL')
'''
for n in nodes:
    if n['kind']=='estate17_frozen':raise AssertionError('OLD_FROZEN_KIND')
    if n['kind']=='tuple3_frozen':continue
# The generated input uses the new kind, not the previous scalar gate.
for n in nodes:
    if n['kind']=='tuple3_frozen':continue
run=source[source.index('    def run(self):'):source.index('\ndef main():')]
for a,b in [('len(self.targets)==17','len(self.targets)==3'),('len(copies)==11','len(copies)==2'),('len(reconstruction)==17','len(reconstruction)==3'),("endswith('.gd')])==6","endswith('.gd')])==1"),("'target_count':11","'target_count':2"),("'patch_count':6,'copy_count':11,'total':17","'patch_count':1,'copy_count':2,'total':3"),("'targets':17,'map_nodes':4","'targets':3,'map_nodes':4"),('EXACT17','EXACT3'),('PATCH6_COPY11','PATCH1_COPY2'),('UNION17','UNION3'),('EXACT11_GENERATED','EXACT2_GENERATED')]:run=run.replace(a,b)
main=source[source.index('\ndef main():'):].replace('EstateScalarStage(spec)','MarketSourceTupleStage(spec)')
nt=S+'stage_performance51_market_tuple3_READY.py';tool=(header+body+run+main).encode();ast.parse(tool);spec['required_generator']={'path':nt,'sha256':sha(tool)}
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','predecessor_input','proof_input']and isinstance(x,str)and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(spec['required_gates']);used.update(x for k,x in spec['B_only_contract'].items()if k.endswith('_input'));spec['pinned_inputs']=[r for r in pins.values()if r['id']in used]
for r in spec['pinned_inputs']:
    if r['id'].startswith('tuple3_'):fixed(r['path'],r['sha256'])
assert {n['target']for n in nodes if'target'in n}==set(allow)and len(allow)==3
def delta(a,b,ks=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():return[d for k in a for d in delta(a[k],b[k],ks+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):return[d for i in range(len(a))for d in delta(a[i],b[i],ks+[i])]
    return []if type(a)is type(b)and a==b else[{'pointer':ks,'old':a,'new':b}]
deltas=delta(old,spec);inverse=copy.deepcopy(spec)
for d in reversed(deltas):ptr(inverse,d['pointer'][:-1])[d['pointer'][-1]]=d['old']
assert js(inverse)==oldinput
aa=oldtool.decode().splitlines(True);bb=tool.decode().splitlines(True);hunks=[]
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hunks.append({'old_start':len(''.join(aa[:i]).encode()),'old_end':len(''.join(aa[:j]).encode()),'new_start':len(''.join(bb[:k]).encode()),'new_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
fwd=oldtool;rev=tool
for h in reversed(hunks):fwd=fwd[:h['old_start']]+h['new'].encode()+fwd[h['old_end']:];rev=rev[:h['new_start']]+h['old'].encode()+rev[h['new_end']:]
assert fwd==tool and rev==oldtool
diff=''.join(difflib.unified_diff(aa,bb,fromfile=tp,tofile=nt)).encode();ib=js(spec);np=O+'source_input_ROOT_LOCKED.json'
proof={'status':'ROOT39_SOURCE_ONLY_EXACT3_DRIVER_BYTE_INPUT_TYPED_INVERSE_NOT_STAGED','parent_driver':{'path':tp,'sha256':ts},'whole_driver_byte_forward_inverse':True,'driver_hunks':hunks,'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_serialized_inverse':True,'input_deltas':deltas,'unchanged8DE0_core':True,'frozen_other_nodes':frozen,'only2_source_leaves':admit['source_leaves'],'no_receipt_or_key_added_to_runtime_source_maps':True,'only3targets_1GD_2JSON':True,'engine_Stage_collector_formal_calls':0};pb=js(proof)
handoff={'status':'ROOT40_SOURCE_ONLY_EXACT3_READY_NOT_STAGED','driver':{'path':nt,'sha256':sha(tool)},'input':{'path':np,'sha256':sha(ib)},'driver_complete_diff':{'path':O+'driver_complete_vs48.diff','sha256':sha(diff)},'whole_inverse':{'path':O+'driver_input_whole_inverse_READY.json','sha256':sha(pb)},'target_count':3,'GD':1,'JSON':2,'Root_only_NOT_EXECUTED_command':'python '+str(p(nt))+' '+str(p(np))+' --input-sha256 '+sha(ib)}
files={nt:tool,np:ib,O+'driver_complete_vs48.diff':diff,O+'driver_input_whole_inverse_READY.json':pb,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(nt).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
