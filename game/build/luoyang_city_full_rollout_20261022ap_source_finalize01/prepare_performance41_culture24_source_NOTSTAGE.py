"""One NEW strict culture24 driver/input, no Stage, no EOF transport."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance41_culture24_source_recipe/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration31/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(fixed(path,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
tp=S+'stage_performance35_merged_copy_READY.py';ts='71c6f60e9bad794f650398b7c2221a2ba8716d2c9ffc46e760502c78b0fb5c62';oldtool=fixed(tp,ts);tool=oldtool.decode()
ip=S+'performance38_exact_EOF_transport_recipe/source_input_ROOT_LOCKED.json';iss='077ee41741b8037c016b32d267dae03d8237b760677b486c16ba26c09908d8a8';oldinput=fixed(ip,iss);old=json.loads(oldinput)
hp=S+'performance40_culture_C_source_repair/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json';hs='7b42c338f2f33e08b9d38b27cc4318ef4be0add9e72b2ae40e9d055c7154cda8';hand=read(hp,hs)
proof=read(hand['inverse_proof']['path'],hand['inverse_proof']['sha256']);records=proof['records'];proposal=read(hand['execution_proposal']['path'],hand['execution_proposal']['sha256']);request=read(hand['scope_request']['path'],hand['scope_request']['sha256'])
rp=R+'culture24_source_preparation_scope_READY.json';rs='2ecb2f090c26d4ae0f6f03ddfb533c95e6619ce5423fd4e72ddee414e978c0a1';root=read(rp,rs)
backp=R+'old_full_backups_READY.json';backs='3a817cc0b9205df9909603715f8e077fafef4747bad0731d36788bf041b9bdb9';backups=read(backp,backs)
assert root['status']=='ROOT_APPROVED_EXACT24_CULTURE_C_SOURCE_SUCCESSOR_PREPARATION_ONLY'and root['execution_candidate_sha256']==hand['execution_proposal']['sha256']and root['old_full_backups_sha256']==backs
stagep=hand['actual_parent_stage']['path'];stages=hand['actual_parent_stage']['sha256'];stage=read(stagep,stages)
constructor=r'''        self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input']);self.codes=self.read_json_input(c['code_inverse_input'])['records']
        need(self.inputs[c['production_input']]['sha256']==HAND and self.inputs[spec['authority_input']]['sha256']==PROPOSAL and self.inputs[c['code_inverse_input']]['sha256']==self.hand['inverse_proof']['sha256'],'FIXED_CULTURE_ONLY_CODE_DATA_AND_EXECUTION')
        root=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='2ecb2f090c26d4ae0f6f03ddfb533c95e6619ce5423fd4e72ddee414e978c0a1' and same(root,c['expected_scope_document']) and root.get('status')=='ROOT_APPROVED_EXACT24_CULTURE_C_SOURCE_SUCCESSOR_PREPARATION_ONLY' and root.get('scope_sha256')==REQUEST and root.get('execution_candidate_sha256')==PROPOSAL and root.get('whole_inverse_sha256')==self.hand['inverse_proof']['sha256'],'EXACT_ROOT_CULTURE24_PREPARATION_SCHEMA')
        need(root.get('existing_targets')==24 and root.get('GD_targets')==10 and root.get('JSON_targets')==14 and root.get('fresh_before_sha256')==BEFORE and root.get('Stage_execution_authorized') is False and root.get('deployment_authorized') is False and root.get('engine_authorized') is False,'ROOT_SCOPE_AND_NO_UNREQUESTED_EXECUTION')
        need(self.inputs[c['backup_input']]['sha256']=='3a817cc0b9205df9909603715f8e077fafef4747bad0731d36788bf041b9bdb9' and root.get('old_full_backups_sha256')==self.inputs[c['backup_input']]['sha256'] and backups.get('count')==24,'ROOT_FULL24_OLD_BACKUPS')
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST,'FIXED24_SCOPE_REQUEST')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']}
        need(len(self.oldtargets)==24 and [r['target']for r in request['targets']]==spec['root_target_allowlist'] and {r['target']:r['old_sha256']for r in backups['targets']}==self.oldtargets,'EXACT24_ORDERED_OLD_VALUES')
        for r in backups['targets']:
            backup=Path(r['backup_path']).resolve();need(backup.is_relative_to(M.ROOT),'ROOT_BACKUP_GAME_DOMAIN')
            need(self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['old_sha256'])==self.read(r['target'],r['old_sha256']),'ALL24_OLD_BYTES_BACKED_UP')
        prior=self.read_json_input(c['parent_approval_input'])
        need(self.inputs[c['parent_approval_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'ORIGINAL_OWNED_TEN_MEMBERS')
        changed={self.codes[n]['target']for n in ['Coordinator','Temple']};restored=copy.deepcopy(self.authority)
        need({e['path']for e in self.hand['owned_changed_exactly2']}==changed,'ONLY_TWO_OWNED_SUCCESSORS')
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                r=next(v for v in self.codes.values()if v.get('target')==path)
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONE_NEW_EDGE_KEEP_WHOLE_HISTORY')
                e=after['edges'][-1];need(e['old_sha256']==before['current_sha256'] and e['new_sha256']==after['current_sha256']==r['candidate']['sha256'] and e['new_snapshot']==r['candidate']['path'] and same(e['replacements'],r['hunks']),'EXACT_COORDINATOR_AND_TEMPLE_EDGES');restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_EIGHT_OWNED_ROWS_WHOLE_SAME')
        extra={path:s for path,s in self.authority['source_sha256'].items()if path not in prior['source_sha256']}
        need(len(prior['source_sha256'])==80 and len(self.authority['source_sha256'])==85 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()) and same(extra,self.hand['new_exact5_proof_pins']),'OLD80_PINS_AND_ONLY_FIVE_NEW_PINS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_025E')
        for r in self.codes.values():
            before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=after
            for h in r['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'UNIQUE_LITERAL_HUNKS');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==after and inverse==before,'ALL_FOUR_WHOLE_CODE_DATA_BYTE_INVERSES')
        priorstage=self.read_json_input(c['actual_parent_stage_input']);owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['actual_parent_stage_input']]['sha256']=='eb875d3aeed4c750d907cacfe8c5b12c93750d8bddc84d63040a25295f082f6f' and self.inputs[c['prior_owner_input']]['sha256']=='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c' and owner.get('expected_not_derived_from_live_collector_or_canonical_hash_crawl') is True,'FIXED_AP15_EB875_B285_NOT_CURRENT_FILL')
        declared=dict(owner['core_source_sha256'])
        for r in owner['scenes']:declared.update(r['source_sha256'])
        actual={r['target']:r['candidate_sha256']for r in priorstage['targets']}
        need(all(actual.get(path,declared.get(path))==s for path,s in self.oldtargets.items()),'ALL24_OLD_TARGETS_INDEPENDENTLY_DECLARED')
'''
start=tool.index("        self.contract=spec['B_only_contract']");end=tool.index('\n    def target(',start);tool=tool[:start]+constructor+tool[end:]
start=tool.index('    def build_node(self,row):');end=tool.index('\n    def run(self):',start)
build=r'''    def build_node(self,row):
        if row['kind']=='culture_frozen_node':
            ident=row['id'];need(ident in FROZEN and self.inputs[row['base_input']]['sha256']==FROZEN[ident] and row['immutable_sha256']==FROZEN[ident],'ONLY_UNCHANGED_REGISTRY_AND_ENV_INDEX')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if ident=='registry_final'else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target_or_reformatted_output':True};return
        if row['kind']=='culture_contract_literal':
            target='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
            oldsha='7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e';newsha='59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1'
            oldC='8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b';newC='b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be'
            expected=[{'op':'set','pointer':['source_sha256',C],'existed':True,'old':oldC,'new':newC}]
            need(row.get('target')==target and row.get('old_sha256')==oldsha and self.inputs[row['base_input']]['sha256']==oldsha and same(row['operations'],expected) and not row.get('source_fields') and not row.get('source_bundle'),'SOLE_EXACT_CULTURE_C_SOURCE_METADATA_OPERATION')
            literal=row['literal_candidate_input'];need(self.inputs[literal]['sha256']==newsha,'ONLY_EXACT59CF_LITERAL_CANDIDATE')
            work=copy.deepcopy(row);work['kind']='metadata';del work['literal_candidate_input']
            super().build_node(work) # Original source-only and FULL typed inverse.
            ident=row['id'];node=self.nodes[ident];candidate=self.input_bytes[literal];before=self.input_bytes[row['base_input']]
            need(same(node['value'],self.read_json_input(literal)) and self.proofs[ident].get('whole_typed_inverse') is True,'LITERAL_EXACT_TYPED_MATCH_AFTER_ORIGINAL_WHOLE_INVERSE')
            need(candidate.count(newC.encode())==1 and before.count(oldC.encode())==1 and candidate.replace(newC.encode(),oldC.encode(),1)==before and before.replace(oldC.encode(),newC.encode(),1)==candidate,'CULTURE_LITERAL_FULL_BYTE_FORWARD_INVERSE_ONE_VALUE')
            self.outputs[node['path']]=candidate;node['sha256']=newsha;self.targets[target]['candidate_sha256']=newsha
            self.proofs[ident]['exact59CF_literal_after_original_typed_inverse']=True;self.proofs[ident]['whole_literal_byte_inverse_7EE']=True
            return
        return super().build_node(row)
'''
tool=tool[:start]+build+tool[end:]
tool=tool.replace("exact={r['target']:r['candidate']for r in self.codes.values()if 'target'in r}","exact={r['target']:r['candidate']for r in self.codes.values()if 'target'in r and r['target'].endswith('.gd')}")
tool=tool.replace('len(exact)==8 and len(self.spec[\'pass_through_targets\'])==8','len(exact)==3 and len(self.spec[\'pass_through_targets\'])==3')
registrysha=stage['nodes']['registry_final']['sha256']
changes=[
 ("PARENT='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'","PARENT='025eff4adb4bf396c5480539316d8efac36c0b435598b6f85b9ed152e4b1330c'"),
 ("PROPOSAL='025eff4adb4bf396c5480539316d8efac36c0b435598b6f85b9ed152e4b1330c'","PROPOSAL='"+hand['execution_proposal']['sha256']+"'"),
 ("HAND='32eef713b78b4bc1595e5b29637b67ee71cecc437303bfcb44b830c831e1283f'","HAND='"+hs+"'"),
 ("REQUEST='c431b9725252268cffbe9fead091bc0230e491b85dfbcddd912bc21983983c4f'","REQUEST='"+hand['scope_request']['sha256']+"'"),
 ("BEFORE='c2633e5dc77bd69a7821351fa288e01e1110556fc5fd20922ce53bdf08e7ea3d'","BEFORE='4e3c18f870c1af9c1a4ee677bfb6e1b653be9ab9f33461eab557fc6af6a68285'"),
 ("FROZEN={'runtime_contract_final':'7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e','ap_environment_index'", "FROZEN={'registry_final':'"+registrysha+"','ap_environment_index'"),
 ('class MergedCopyStage(M.Stage):','class CultureSourceStage(M.Stage):'),('print(json.dumps(MergedCopyStage(spec).run()))','print(json.dumps(CultureSourceStage(spec).run()))'),
 ('len(self.targets)==29','len(self.targets)==24'),('len(reconstruction)==29','len(reconstruction)==24'),("len([path for path in self.targets if path.endswith('.gd')])==15","len([path for path in self.targets if path.endswith('.gd')])==10"),
 ("'patch_count':15,'copy_count':14,'total':29","'patch_count':10,'copy_count':14,'total':24"),("'targets':29,'map_nodes':4","'targets':24,'map_nodes':4"),('EXACT29','EXACT24'),('PATCH15_COPY14','PATCH10_COPY14'),('EXACT_03C4_TO025E','EXACT_025E_TOBF04'),('fixed_Root_03C4_to025E','fixed_Root_025E_toBF04'),('Exact22 B-only source compiler','Exact24 C-only culture-source repair compiler')]
for a,b in changes:assert a in tool,a;tool=tool.replace(a,b)
toolbytes=tool.encode();ast.parse(toolbytes);newtp=S+'stage_performance41_culture24_READY.py'
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,path,s):pins[i]={'id':i,'path':path,'sha256':s};return{'$pin':i}
for i,r in [('execution_approval',hand['execution_proposal']),('B_only_parent_approval',hand['execution_parent']),('B_only_production',{'path':hp,'sha256':hs}),('B_only_scope_request',hand['scope_request']),('B_only_actual_parent_stage',{'path':stagep,'sha256':stages}),('B_only_scope',{'path':rp,'sha256':rs}),('canonical_prior_owner',hand['fixed_prior_owner']),('culture_code_inverse',hand['inverse_proof']),('culture_old_backups',{'path':backp,'sha256':backs}),('culture_exact_literal',records['runtime_contract']['candidate'])]:pin(i,r['path'],r['sha256'])
oldtargets={r['target']:r['old_sha256']for r in request['targets']};EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
refs={r['target']:r['candidate']['sha256']for r in records.values()if'target'in r};refs[EXE]={'$pin':'execution_approval'}
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    a=stage['nodes'][n['id']];raw=fixed(a['path'],a['sha256']);cur[n['id']]={**a,'bytes':raw,'value':json.loads(raw)if n['kind']!='index'and n['id']!='ap_environment_index'else None}
for n in old['nodes']:
    if n.get('target')in oldtargets:refs[n['target']]={'$sha':n['id']}
refs[records['runtime_contract']['target']]={'$sha':'runtime_contract_final'}
def known(v):
    if isinstance(v,dict)and '$pin'in v:return pins[v['$pin']]['sha256']
    if isinstance(v,dict)and '$sha'in v:return None
    return v
def source_ops(base,fields):
    out=[]
    for keys in fields:
        table=ptr(base,keys)
        for path,v in refs.items():
            if path in table and(known(v)is None or table[path]!=known(v)):out.append({'op':'set','pointer':keys+[path],'existed':True,'old':table[path],'new':v})
    return out
nodes=[]
for oldn in old['nodes']:
    n=copy.deepcopy(oldn);ident=n['id']
    if n['kind']=='map':
        n['operations']=[op for op in n['operations']if op['pointer'][-1]not in proposal['owned']]
        for op in n['operations']:
            if op['pointer'][-1]in refs:op['new']=refs[op['pointer'][-1]]
        nodes.append(n);continue
    c=cur[ident];inputid='culture_parent_'+ident;pin(inputid,c['path'],c['sha256']);n['base_input']=inputid
    if ident in ['registry_final','ap_environment_index']:
        n={'id':ident,'kind':'culture_frozen_node','base_input':inputid,'immutable_sha256':c['sha256']};nodes.append(n);continue
    if ident=='runtime_contract_final':
        n={'id':ident,'kind':'culture_contract_literal','base_input':inputid,'target':records['runtime_contract']['target'],'old_sha256':c['sha256'],'file':'runtime_contract_source_successor.json','source_policy':'old_city_or_market','operations':[{'op':'set','pointer':['source_sha256','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'],'existed':True,'old':'8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b','new':'b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be'}],'literal_candidate_input':'culture_exact_literal'};nodes.append(n);continue
    if n.get('target'):n['old_sha256']=c['sha256'];assert oldtargets[n['target']]==c['sha256']
    if n['kind']=='index':
        reps=[]
        for rep in n['replacements']:
            if rep['old']=='const FORMAL_ENABLED=true':reps.append(rep);continue
            v=rep['new'];before=cur[v['$sha']]['sha256']if isinstance(v,dict)and '$sha'in v else hand['execution_parent']['sha256']if v=={'$pin':'execution_approval'}else rep['old'];assert c['bytes'].decode().count(before)==1;reps.append({'old':before,'new':v})
        n['replacements']=reps;nodes.append(n);continue
    fields=[f['pointer']for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[]);n['operations']=source_ops(c['value'],fields);nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for path,v in refs.items():
            if path in group['leaves']:group['leaves'][path]=v
passes=[{'target':records[n]['target'],'old_sha256':records[n]['parent']['sha256'],'candidate_path':records[n]['candidate']['path'],'candidate_sha256':records[n]['candidate']['sha256']}for n in ['Coordinator','Temple']]
passes.append({'target':EXE,'old_sha256':hand['execution_parent']['sha256'],'candidate_path':hand['execution_proposal']['path'],'candidate_sha256':hand['execution_proposal']['sha256']})
spec=copy.deepcopy(old);spec.update(output_root=S+'outputs/root_culture_C_source_repair_stage01/',nodes=nodes,source_groups=groups,pass_through_targets=passes,prospective_targets=[{'target':r['target'],'candidate_path':r['candidate_path'],'sha256':r['candidate_sha256']}for r in passes],root_target_allowlist=[r['target']for r in request['targets']],required_generator={'path':newtp,'sha256':sha(toolbytes)},source_baseline='FormalAP15 EB875 plus independentB285 and exact24 culture C-pin source successors. Only C pin/Coordinator literal/Templebinding2values; no new gameplay or native changes, no observed expected fill.')
spec['B_only_contract']={'production_input':'B_only_production','code_inverse_input':'culture_code_inverse','scope_input':'B_only_scope','scope_request_input':'B_only_scope_request','backup_input':'culture_old_backups','parent_approval_input':'B_only_parent_approval','actual_parent_stage_input':'B_only_actual_parent_stage','prior_owner_input':'canonical_prior_owner','expected_scope_document':root,'historical_schema_key_only_not_B_only_scope':True}
for gate in spec['required_gates']:
    if gate['input']=='B_only_scope':gate['pointer']=['existing_targets'];gate['equals']=24
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input']and isinstance(x,str)and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(spec['required_gates']);used.update(v for v in spec['B_only_contract'].values()if isinstance(v,str)and v in pins)
spec['pinned_inputs']=[r for r in pins.values()if r['id']in used]
for r in spec['pinned_inputs']:fixed(r['path'],r['sha256'])
assert set(r['target']for r in passes)|{n['target']for n in nodes if'target'in n}==set(oldtargets)
EOF=[]
for name in ['Coordinator','Temple']:
    r=records[name];before=fixed(r['parent']['path'],r['parent']['sha256']);after=fixed(r['candidate']['path'],r['candidate']['sha256']);assert before.endswith(b'\n')and after.endswith(b'\n')and b'\r'not in after and not after.startswith(b'\xef\xbb\xbf');EOF.append({'target':r['target'],'old_final_LF':True,'candidate_final_LF':True,'candidate_CR_count':0})
for n in nodes:
    if n['kind']=='index':
        b=cur[n['id']]['bytes'];assert b.endswith(b'\n')and b'\r'not in b and not b.startswith(b'\xef\xbb\xbf');EOF.append({'target':n['target'],'old_final_LF':True,'candidate_EOL_unchanged_ASCII_SHA_replacements':True})
assert len(EOF)==10
def typed(a,b,path=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():return[d for k in a for d in typed(a[k],b[k],path+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):return[d for i in range(len(a))for d in typed(a[i],b[i],path+[i])]
    if same(a,b):return[]
    return[{'pointer':path,'old':a,'new':b}]
deltas=typed(old,spec);back=copy.deepcopy(spec)
for d in reversed(deltas):
    holder=ptr(back,d['pointer'][:-1]);assert same(holder[d['pointer'][-1]],d['new']);holder[d['pointer'][-1]]=copy.deepcopy(d['old'])
assert same(back,old)and js(back)==oldinput
hh=[];aa=oldtool.decode().splitlines(True);bb=toolbytes.decode().splitlines(True)
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hh.append({'old_start':len(''.join(aa[:i]).encode()),'old_end':len(''.join(aa[:j]).encode()),'new_start':len(''.join(bb[:k]).encode()),'new_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
fwd=oldtool;rev=toolbytes
for h in reversed(hh):fwd=fwd[:h['old_start']]+h['new'].encode()+fwd[h['old_end']:];rev=rev[:h['new_start']]+h['old'].encode()+rev[h['new_end']:]
assert fwd==toolbytes and rev==oldtool
td=''.join(difflib.unified_diff(aa,bb,fromfile=tp,tofile=newtp)).encode()
outproof={'status':'CULTURE24_THIN_DRIVER_BYTE_INPUT_TYPED_AND_EXACT_LITERAL_INVERSE_NOT_STAGED','parent_tool':{'path':tp,'sha256':ts},'new_tool':{'path':newtp,'sha256':sha(toolbytes)},'whole_tool_forward_inverse':True,'tool_hunks':hh,'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_UTF8_inverse':True,'input_deltas':deltas,'GD_EOF_preflight_exact10':EOF,'original8DE0_no_change_and_no_EOF_extension':True,'runtime_contract_literal_only_after_original_metadata_wholetyped_inverse':True,'engine_Stage_collector_native_decode_formal_calls':0}
newip=O+'source_input_ROOT_LOCKED.json';ib=js(spec)
handoff={'status':'ROOT31_CULTURE24_SINGLE_STRICT_SOURCE_REPAIR_DRIVER_INPUT_READY_NOT_STAGED','tool':{'path':newtp,'sha256':sha(toolbytes)},'input':{'path':newip,'sha256':sha(ib)},'inverse':{'path':O+'driver_and_input_whole_inverse_READY.json','sha256':sha(js(outproof))},'driver_diff':{'path':O+'driver_complete_vs71C6.diff','sha256':sha(td)},'target_count':24,'GD':10,'JSON':14,'pinned_inputs':len(spec['pinned_inputs']),'no_runtime_EOF_or_geometry_extension':True,'engine_Stage_collector_calls':0,'Root_only_command_NOT_EXECUTED':'python '+str(p(newtp))+' '+str(p(newip))+' --input-sha256 '+sha(ib)}
files={newtp:toolbytes,newip:ib,O+'driver_and_input_whole_inverse_READY.json':js(outproof),O+'driver_complete_vs71C6.diff':td,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(newtp).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
