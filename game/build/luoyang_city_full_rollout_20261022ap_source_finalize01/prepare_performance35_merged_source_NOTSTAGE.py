"""Prepare one NEW exact29 driver/input after Root exact final approval. No Stage."""
import argparse,ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance35_merged_source_recipe/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration29/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(fixed(path,s))
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
parser=argparse.ArgumentParser();parser.add_argument('--root-approval',required=True);parser.add_argument('--root-approval-sha256',required=True)
args=parser.parse_args();rootpath=args.root_approval;rootsha=args.root_approval_sha256;root=read(rootpath,rootsha)
oldtoolpath=S+'stage_performance25_canonical_B_READY.py';oldtoolsha='b7176b80b7be48c3114984909de35088eac55e446c44622a1293caf60516950c'
oldtool=fixed(oldtoolpath,oldtoolsha);tool=oldtool.decode()
handpath=S+'performance34_merged_DT_subspan_dependencies/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json';handsha='32eef713b78b4bc1595e5b29637b67ee71cecc437303bfcb44b830c831e1283f';hand=read(handpath,handsha)
proof=read(hand['whole_inverse_proof']['path'],hand['whole_inverse_proof']['sha256']);records=proof['records']
proposal=read(hand['execution_proposal']['path'],hand['execution_proposal']['sha256'])
request=read(hand['scope_request']['path'],hand['scope_request']['sha256'])
scopepath=R+'combined_copy_source_preparation_scope_READY.json';scopesha='09c745e69fb7bdffabb35faf86374005a198f494beca063f07638f0d0f3fbf48';scope=read(scopepath,scopesha)
backpath=R+'old_full_backups_READY.json';backsha='60385352065794b9e503c552e4ddc4232e96477576cc8794f05c2a5fbd9bf54c';backups=read(backpath,backsha)
diagpath=R+'DT_passive_subspan_preparation_approval_READY.json';diagsha='5bc5e44c2b40084b5934d1aa83d84ce48eae5420f91abea87f30bb056e9bf547';diag=read(diagpath,diagsha)
# The final Root document's exact schema is passed only after it exists.
# Its semantic proposal binding and approval bool are mandatory, not guessed.
assert root.get('approved_by_root')is True
assert root.get('status')=='ROOT_APPROVES_AP14_EXACT29_MERGED_COPY_AND_PASSIVE_DT_SOURCE_PREPARATION_NOT_STAGE_OR_DEPLOYMENT'
assert root.get('execution_proposal_sha256')==hand['execution_proposal']['sha256'] and root.get('DT_diagnostic_approval_sha256')==diagsha
assert scope['allowed_existing_targets']==29 and scope['scope_sha256']==hand['scope_request']['sha256']
assert backups['count']==29 and len(backups['targets'])==29 and diag['approved_by_root']is True and diag['candidate_sha256']==records['DT']['candidate']['sha256']
constructor=r'''        self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input'])
        need(self.inputs[c['production_input']]['sha256']==HAND and self.inputs[spec['authority_input']]['sha256']==PROPOSAL,'FIXED_MERGED_CODE_AND_FINAL_EXECUTION')
        code=self.read_json_input(c['code_inverse_input']);self.codes=code['records']
        need(self.inputs[c['code_inverse_input']]['sha256']==self.hand['whole_inverse_proof']['sha256'],'FIXED_ALL_CODE_INVERSE_DOCUMENT')
        root=self.read_json_input(c['execution_root_input'])
        need(self.inputs[c['execution_root_input']]['sha256']==c['expected_root_execution_sha256'] and same(root,c['expected_root_execution_document']) and root.get('approved_by_root') is True,'EXACT_FINAL_ROOT_EXECUTION_DIAGNOSTIC_APPROVAL')
        need(root.get('status')=='ROOT_APPROVES_AP14_EXACT29_MERGED_COPY_AND_PASSIVE_DT_SOURCE_PREPARATION_NOT_STAGE_OR_DEPLOYMENT' and root.get('execution_proposal_sha256')==PROPOSAL and root.get('parent_execution_sha256')==PARENT and root.get('scope_proposal_sha256')==REQUEST and root.get('full29_old_backup_sha256')=='60385352065794b9e503c552e4ddc4232e96477576cc8794f05c2a5fbd9bf54c' and root.get('DT_diagnostic_approval_sha256')=='5bc5e44c2b40084b5934d1aa83d84ce48eae5420f91abea87f30bb056e9bf547' and root.get('target_count')==29 and root.get('GD_count')==15 and root.get('JSON_count')==14 and root.get('stage_or_engine_or_formal_write_authorized') is False,'ROOT_FINAL_EXACT_EXECUTION_DIAGNOSTIC_PREPARATION_SCHEMA')
        diag=self.read_json_input(c['diagnostic_root_input'])
        need(self.inputs[c['diagnostic_root_input']]['sha256']=='5bc5e44c2b40084b5934d1aa83d84ce48eae5420f91abea87f30bb056e9bf547' and diag.get('approved_by_root') is True and diag.get('candidate_sha256')==self.codes['DT']['candidate']['sha256'],'EXPLICIT_DT_PASSIVE_DIAGNOSTIC_APPROVAL_NOT_OLD_SCOPE_TEXT')
        prior=self.read_json_input(c['parent_approval_input'])
        need(self.inputs[c['parent_approval_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'ORIGINAL_TEN_OWNED_MEMBERS')
        changed={self.codes[n]['target'] for n in ['B','G','DT','Temple']}
        need(set(self.hand['owned_changed_exactly4'])==changed,'EXACT_FOUR_OWNED_SUCCESSORS')
        restored=copy.deepcopy(self.authority)
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'APPEND_ONE_KEEP_COMPLETE_OLD_GRAPH')
                edge=after['edges'][-1]
                record=next(r for r in self.codes.values() if r.get('target')==path)
                need(edge['old_sha256']==before['current_sha256'] and edge['new_sha256']==after['current_sha256']==record['candidate']['sha256'] and edge['new_snapshot']==record['candidate']['path'] and same(edge['replacements'],record['hunks']),'EXACT_FOUR_WHOLE_BYTE_EDGES')
                restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_SIX_ROWS_WHOLE_UNCHANGED')
        need(len(prior['source_sha256'])==71 and len(self.authority['source_sha256'])==80 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()),'KEEP_OLD71_PROOF_PINS')
        extra={path:s for path,s in self.authority['source_sha256'].items() if path not in prior['source_sha256']}
        need(same(extra,self.hand['new_proof_sources_exact9']) and len(extra)==9,'EXACT_EIGHT_SOURCE_PLUS_ONE_WHOLE_PROOF_ADDITIONS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_03C4')
        for name,record in self.codes.items():
            before=self.read(record['parent']['path'],record['parent']['sha256']);candidate=self.read(record['candidate']['path'],record['candidate']['sha256'])
            forward=before;inverse=candidate
            for h in record['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'EXACT_UNIQUE_CODE_HUNK');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==candidate and inverse==before,'ALL_EIGHT_CODE_BINDING_BYTE_INVERSES')
        scope=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='09c745e69fb7bdffabb35faf86374005a198f494beca063f07638f0d0f3fbf48' and same(scope,c['expected_scope_document']) and scope.get('status')=='ROOT_APPROVED_PREPARATION_ONLY_EXACT29_MERGED_SOURCE_SUCCESSOR','EXACT_ROOT29_SCOPE_PREPARATION_DOCUMENT')
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST and scope.get('scope_sha256')==REQUEST and scope.get('allowed_existing_targets')==29 and scope.get('GD_count')==15 and scope.get('JSON_count')==14 and scope.get('fresh_before_sha256')==BEFORE,'ROOT29_FIXED_PATH_SCOPE_AND_FRESH_BASELINE')
        need(self.inputs[c['backup_input']]['sha256']=='60385352065794b9e503c552e4ddc4232e96477576cc8794f05c2a5fbd9bf54c' and backups.get('count')==29,'ROOT29_ALL_FULL_OLD_BACKUPS')
        self.oldtargets={r['target']:r['old_sha256'] for r in request['targets']}
        need(len(self.oldtargets)==29 and [r['target'] for r in request['targets']]==spec['root_target_allowlist'] and {r['target']:r['old_sha256'] for r in backups['targets']}==self.oldtargets,'EXACT29_ORDERED_TARGETS_AND_OLD_HASHES')
        for row in backups['targets']:
            backup=Path(row['backup_path']).resolve();need(backup.is_relative_to(M.ROOT),'ROOT_BACKUP_GAME_DOMAIN')
            rp='res://'+backup.relative_to(M.ROOT).as_posix()
            need(self.read(rp,row['old_sha256'])==self.read(row['target'],row['old_sha256']),'ALL29_OLD_BYTES_PRECISELY_BACKED_UP')
        parent_stage=self.read_json_input(c['actual_parent_stage_input']);prior_owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['actual_parent_stage_input']]['sha256']=='35ffd126b0ac5292c91e9ed0bd4ea97d8e7c0a4caa16ea36ddcc6ed0e587fa36' and self.inputs[c['prior_owner_input']]['sha256']=='65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be','FIXED_AP14_35FF_AND_INDEPENDENT65BE')
        need(prior_owner.get('expected_not_derived_from_live_collector_or_canonical_hash_crawl') is True and prior_owner.get('actual_stage_receipt',{}).get('sha256')=='35ffd126b0ac5292c91e9ed0bd4ea97d8e7c0a4caa16ea36ddcc6ed0e587fa36','NO_CURRENT_COLLECTOR_EXPECTED_FILL')
        native_old={r['target']:r['candidate_sha256']for r in parent_stage['targets']}
        declared=dict(prior_owner['core_source_sha256'])
        for row in prior_owner['scenes']:declared.update(row['source_sha256'])
        need(all(native_old.get(path,declared.get(path))==s for path,s in self.oldtargets.items()),'ALL29_OLDS_FROM_FROZEN_ACTUAL_OR_INDEPENDENT_DECLARATION')
'''
start=tool.index("        self.contract=spec['B_only_contract']");end=tool.index('\n    def target(',start);tool=tool[:start]+constructor+tool[end:]
runstart=tool.index("        for row in self.spec['pass_through_targets']:",tool.index('    def run(self):'));runend=tool.index("        for row in self.spec['nodes']:self.build_node(row)",runstart)
runpass=r'''        exact={r['target']:r['candidate']for r in self.codes.values()if 'target'in r}
        exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==8 and len(self.spec['pass_through_targets'])==8,'EXACT_SEVEN_CODE_AND_EXECUTION_PASSTHROUGHS')
        for row in self.spec['pass_through_targets']:
            need(row['target']in exact and row['old_sha256']==self.oldtargets[row['target']] and exact[row['target']]=={'path':row['candidate_path'],'sha256':row['candidate_sha256']},'ONLY_FIXED_SEVEN_CODE_AND_AUTHORITY_BYTES')
            self.read(row['candidate_path'],row['candidate_sha256']);self.read(row['target'],row['old_sha256']);self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
'''
tool=tool[:runstart]+runpass+tool[runend:]
changes=[
 ("PARENT='a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283'","PARENT='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'"),
 ("PROPOSAL='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'","PROPOSAL='"+hand['execution_proposal']['sha256']+"'"),
 ("HAND='3a6200e99bd2a9c2e9ce19aa47eb06f4bb84ba15099e2058bd21de2117f2ce7d'","HAND='"+handsha+"'"),
 ("REQUEST='8e23624053a9b6c317ccbe39cd6415c0e5455d96e1340a0a0b48f1b2491b4b50'","REQUEST='"+hand['scope_request']['sha256']+"'"),
 ("BEFORE='3b12823c4ca9d47397faa78e93b3f918bd6efba8729e79342c761cf6dbd957e5'","BEFORE='c2633e5dc77bd69a7821351fa288e01e1110556fc5fd20922ce53bdf08e7ea3d'"),
 (",'registry_final':'040664f7a2c73087b6c47e5f4d000cb4955648dd61b830d76d2a7ce54cafd95c'",''),
 ("class BOnlyStage(M.Stage):","class MergedCopyStage(M.Stage):"),
 ("print(json.dumps(BOnlyStage(spec).run()))","print(json.dumps(MergedCopyStage(spec).run()))"),
 ("and len(self.targets)==22","and len(self.targets)==29"),
 ("len(copies)==13 and len(reconstruction)==22 and len([path for path in self.targets if path.endswith('.gd')])==9","len(copies)==14 and len(reconstruction)==29 and len([path for path in self.targets if path.endswith('.gd')])==15"),
 ("'target_count':13","'target_count':14"),
 ("'patch_count':9,'copy_count':13,'total':22","'patch_count':15,'copy_count':14,'total':29"),
 ("'targets':22,'map_nodes':4","'targets':29,'map_nodes':4"),
 ('EXACT22','EXACT29'),('ALL22','ALL29'),('PATCH9_COPY13','PATCH15_COPY14'),('EXACT13_GENERATED_JSON','EXACT14_GENERATED_JSON'),
 ('EXACT_A816_TO03C4_EXECUTION_BYTES','EXACT_03C4_TO025E_EXECUTION_BYTES'),('fixed_Root_A816_to03C4_authority_inverse','fixed_Root_03C4_to025E_authority_inverse')]
for a,b in changes:
    assert a in tool,a;tool=tool.replace(a,b)
toolbytes=tool.encode();ast.parse(toolbytes);toolpath=S+'stage_performance35_merged_copy_READY.py'
oldinputpath=S+'performance25_canonical_B_source_recipe/source_input_ROOT_LOCKED.json';oldinputsha='706c58929266d6e0a9cf58a6b94f959383b5d34133acf059cc424251634473bd';oldinputbytes=fixed(oldinputpath,oldinputsha);old=json.loads(oldinputbytes)
stagepath=hand['actual_parent_stage']['path'];stagesha=hand['actual_parent_stage']['sha256'];stage=read(stagepath,stagesha)
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,path,s):pins[i]={'id':i,'path':path,'sha256':s};return {'$pin':i}
for i,r in [('execution_approval',hand['execution_proposal']),('B_only_parent_approval',hand['execution_parent']),('B_only_production',{'path':handpath,'sha256':handsha}),('B_only_scope_request',hand['scope_request']),('B_only_actual_parent_stage',{'path':stagepath,'sha256':stagesha}),('B_only_scope',{'path':scopepath,'sha256':scopesha}),('B_only_root_execution',{'path':rootpath,'sha256':rootsha}),('canonical_prior_owner',hand['fixed_independent_owner']),('merged_code_inverse',hand['whole_inverse_proof']),('merged_old_backups',{'path':backpath,'sha256':backsha}),('merged_DT_root',{'path':diagpath,'sha256':diagsha})]:pin(i,r['path'],r['sha256'])
targetolds={r['target']:r['old_sha256']for r in request['targets']}
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
refs={r['target']:r['candidate']['sha256']for r in records.values()if'target'in r};refs[EXE]={'$pin':'execution_approval'}
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    row=stage['nodes'][n['id']];raw=fixed(row['path'],row['sha256'])
    cur[n['id']]={**row,'bytes':raw,'value':json.loads(raw)if n['kind']!='index'and n['id']!='ap_environment_index'else None}
for n in old['nodes']:
    if n.get('target'):refs[n['target']]={'$sha':n['id']}
registrytarget='res://data/maps/luoyang_estate_rooms_20261021am/registry.json';refs[registrytarget]={'$sha':'registry_final'}
def known(v):
    if isinstance(v,dict)and set(v)=={'$pin'}:return pins[v['$pin']]['sha256']
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
DT=records['DT']['target'];fade=proof['fade_metadata_recipe']['path']
for oldn in old['nodes']:
    n=copy.deepcopy(oldn);ident=n['id']
    if n['kind']=='map':
        n['operations']=[op for op in n['operations']if op['pointer'][-1]not in proposal['owned']]
        for op in n['operations']:
            if op['pointer'][-1]in refs:op['new']=refs[op['pointer'][-1]]
        nodes.append(n);continue
    c=cur[ident];inputid='B_parent_'+ident;pin(inputid,c['path'],c['sha256']);n['base_input']=inputid
    if ident=='registry_final':
        ids=['luoyang_functional_pawnshop_candidate_20261016','luoyang_market_north_market_front_interior_20261015','luoyang_market_market_west_ward_frontage_interior_20261015','luoyang_market_market_northwest_rear_frontage_interior_20261015','luoyang_market_southeast_market_front_interior_20261015']
        n={'id':ident,'kind':'metadata','base_input':inputid,'target':registrytarget,'old_sha256':c['sha256'],'file':'registry_source_successor.json','source_policy':'old_city_or_market','operations':[{'op':'set','pointer':['rooms',i,'source_sha256',DT],'existed':True,'old':c['value']['rooms'][i]['source_sha256'][DT],'new':refs[DT]}for i in ids],'protected_pointers':[['ap_return_successor'],['history']]}
        nodes.append(n);continue
    if n.get('target'):n['old_sha256']=c['sha256'];assert targetolds[n['target']]==c['sha256']
    if n['kind']=='B_only_frozen_node':assert n['immutable_sha256']==c['sha256'];nodes.append(n);continue
    if n['kind']=='index':
        reps=[]
        for rep in n['replacements']:
            if rep['old']=='const FORMAL_ENABLED=true':reps.append(rep);continue
            v=rep['new'];before=cur[v['$sha']]['sha256']if isinstance(v,dict)and '$sha'in v else hand['execution_parent']['sha256']if v=={'$pin':'execution_approval'}else rep['old']
            assert c['bytes'].decode().count(before)==1;reps.append({'old':before,'new':v})
        n['replacements']=reps;nodes.append(n);continue
    fields=[f['pointer']for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[])
    n['operations']=source_ops(c['value'],fields)
    delta=c['value'].get('source_migration',{}).get('source_delta',{}).get(fade)
    if delta is not None:
        newdelta=copy.deepcopy(delta)
        for k in ['historical_sha256','current_before_sha256','new_sha256','candidate_path']:newdelta[k]=copy.deepcopy(proof['fade_metadata_recipe'][k])
        n['operations'].append({'op':'set','pointer':['source_migration','source_delta',fade],'existed':True,'old':delta,'new':newdelta})
    nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for path,v in refs.items():
            if path in group['leaves']:group['leaves'][path]=v
spec=copy.deepcopy(old)
codes=[r for r in records.values()if'target'in r]
passes=[{'target':r['target'],'old_sha256':r['parent']['sha256'],'candidate_path':r['candidate']['path'],'candidate_sha256':r['candidate']['sha256']}for r in codes]
passes.append({'target':EXE,'old_sha256':hand['execution_parent']['sha256'],'candidate_path':hand['execution_proposal']['path'],'candidate_sha256':hand['execution_proposal']['sha256']})
spec.update(output_root=S+'outputs/root_merged_G_parentcopy_DT_source_stage01/',nodes=nodes,source_groups=groups,prospective_targets=[{'target':r['target'],'candidate_path':r['candidate_path'],'sha256':r['candidate_sha256']}for r in passes],pass_through_targets=passes,
 root_target_allowlist=[r['target']for r in request['targets']],required_generator={'path':toolpath,'sha256':sha(toolbytes)},
 source_baseline='Frozen AO independent maps plus formalAP14 actual35FF/independent65BE, exact29 declared successors and9 new proof leaves; preserve native/history/fourT classes; no observed collector expected filling')
spec['B_only_contract']={'production_input':'B_only_production','execution_root_input':'B_only_root_execution','parent_approval_input':'B_only_parent_approval','scope_input':'B_only_scope','scope_request_input':'B_only_scope_request','backup_input':'merged_old_backups','diagnostic_root_input':'merged_DT_root','code_inverse_input':'merged_code_inverse','actual_parent_stage_input':'B_only_actual_parent_stage','prior_owner_input':'canonical_prior_owner','expected_scope_document':scope,'expected_root_execution_document':root,'expected_root_execution_sha256':rootsha,'historical_schema_key_only_not_B_only_scope':True}
for gate in spec['required_gates']:
    if gate['input']=='B_only_scope':gate['pointer']=['root_read_complete_29_targets_and_necessary_direct_dependencies'];gate['equals']=True
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
for row in spec['pinned_inputs']:fixed(row['path'],row['sha256'])
assert len(passes)==8 and set(r['target']for r in passes)|{n['target']for n in nodes if'target'in n}==set(targetolds)
assert sum(1 for r in request['targets']if r['kind']=='GD')==15
def typed_changes(a,b,path=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():return[d for k in a for d in typed_changes(a[k],b[k],path+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):return[d for i in range(len(a))for d in typed_changes(a[i],b[i],path+[i])]
    if same(a,b):return[]
    return[{'pointer':path,'old':a,'new':b}]
typed=typed_changes(old,spec);reverse=copy.deepcopy(spec)
for d in reversed(typed):
    if not d['pointer']:reverse=copy.deepcopy(d['old'])
    else:holder=ptr(reverse,d['pointer'][:-1]);assert same(holder[d['pointer'][-1]],d['new']);holder[d['pointer'][-1]]=copy.deepcopy(d['old'])
assert same(reverse,old)and js(reverse)==oldinputbytes
toolhs=[];aa=oldtool.decode().splitlines(True);bb=toolbytes.decode().splitlines(True)
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':toolhs.append({'old_byte_start':len(''.join(aa[:i]).encode()),'old_byte_end':len(''.join(aa[:j]).encode()),'new_byte_start':len(''.join(bb[:k]).encode()),'new_byte_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
fwd=oldtool;rev=toolbytes
for h in reversed(toolhs):fwd=fwd[:h['old_byte_start']]+h['new'].encode()+fwd[h['old_byte_end']:];rev=rev[:h['new_byte_start']]+h['old'].encode()+rev[h['new_byte_end']:]
assert fwd==toolbytes and rev==oldtool
td=''.join(difflib.unified_diff(oldtool.decode().splitlines(True),toolbytes.decode().splitlines(True),fromfile=oldtoolpath,tofile=toolpath)).encode()
proofout={'status':'MERGED29_THIN_DRIVER_BYTE_AND_INPUT_TYPED_UTF8_INVERSE_NOT_STAGED','parent_tool':{'path':oldtoolpath,'sha256':oldtoolsha},'new_tool':{'path':toolpath,'sha256':sha(toolbytes)},'whole_tool_forward_inverse':True,'tool_hunks':toolhs,'parent_input':{'path':oldinputpath,'sha256':oldinputsha},'whole_input_typed_and_UTF8_byte_inverse':True,'input_deltas':typed,'unchanged_core8DE0':True,'engine_collector_Stage_native_decode_calls':0}
inputpath=O+'source_input_ROOT_LOCKED.json';inputbytes=js(spec)
handoff={'status':'ROOT29_MERGED_EXACT29_DRIVER_INPUT_PREPARED_NOT_STAGED','tool':{'path':toolpath,'sha256':sha(toolbytes)},'input':{'path':inputpath,'sha256':sha(inputbytes)},'inverse':{'path':O+'driver_and_input_whole_inverse_READY.json','sha256':sha(js(proofout))},'driver_diff':{'path':O+'driver_complete_vsB717.diff','sha256':sha(td)},'targets':29,'partition':{'GD':15,'JSON':14},'pinned_inputs':len(spec['pinned_inputs']),'one_stage_only':True,'engine_collector_Stage_native_decode_calls':0,'Root_only_command_NOT_EXECUTED':'python '+str(p(toolpath))+' '+str(p(inputpath))+' --input-sha256 '+sha(inputbytes)}
files={toolpath:toolbytes,O+'source_input_ROOT_LOCKED.json':inputbytes,O+'driver_and_input_whole_inverse_READY.json':js(proofout),O+'driver_complete_vsB717.diff':td,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(toolpath).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
