"""One exact30 dependency-DAG text producer; no Stage, engine or formal write.

Requires a fresh explicit Root approval pin for the final647949 proposal before
writing any final driver/input. Original51 and38 tools remain unchanged.
"""
import argparse,ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1];S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance58_market_parent30_source_recipe/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration43/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
ap=argparse.ArgumentParser();ap.add_argument('--execution-approval',required=True);ap.add_argument('--execution-approval-sha256',required=True);args=ap.parse_args()
xp=args.execution_approval;xs=args.execution_approval_sha256;xr=read(xp,xs)
tp=S+'stage_performance51_market_tuple3_READY.py';ts='b446d7fe3c5aa9b0e5dce35d21053f12ea3ef22ad6af71bc6b8058f33304da7c';oldtool=fixed(tp,ts)
ip=S+'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json';iss='30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c';oldinput=fixed(ip,iss);old=json.loads(oldinput)
template=read(S+'performance42_culture24_source_recipe/source_input_ROOT_LOCKED.json','decabd917e9a3526c561cdcd0ed3f91e12406696d1a30ae72cad281597b8f277')
regtemplate=read(S+'performance38_exact_EOF_transport_recipe/source_input_ROOT_LOCKED.json','077ee41741b8037c016b32d267dae03d8237b760677b486c16ba26c09908d8a8')
hp=S+'performance57_market_receipt_dependencies/handoff_EXECUTION_PROPOSAL_READY_NOT_STAGED.json';hs='e12394b9f9f47524f5118c3fb4ddad9a38306d042289eaddbe9f830a7398d953';hand=read(hp,hs);proof=read(hand['whole_inverse_proof']['path'],hand['whole_inverse_proof']['sha256']);records=proof['records']
proposal=read(hand['execution_proposal']['path'],hand['execution_proposal']['sha256']);parent=read(hand['execution_parent']['path'],hand['execution_parent']['sha256'])
newexecsha='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3';oldexecsha='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
assert hand['execution_proposal']['sha256']==newexecsha and xr.get('approved_by_root')is True
approvalfields=[{'pointer':[k],'value':v}for k,v in xr.items()if isinstance(v,str)and v.lower()in [newexecsha,oldexecsha]]
assert {r['value'].lower()for r in approvalfields}=={newexecsha,oldexecsha},'ROOT_EXACT_PARENT_AND_FINAL_PROPOSAL_FIELDS_REQUIRED'
scopep=hand['scope']['path'];scopes=hand['scope']['sha256'];scope=read(scopep,scopes);rootp=R+'source_preparation30_approval_READY.json';roots='93e5b14e78f070a5c035fbe5a06d4477c9c622967ff3adb0b8788a18f71708e7';root=read(rootp,roots)
backp=R+'old_full_backups_READY.json';backs='447052f129c1e9fde1e06788cc6e12c09e038a78aee733befe293c1740630769';back=read(backp,backs)
eofp=R+'adapter_exact_EOF_transport_preparation_approval_READY.json';eofs='25ff1b9474bb50ccc149e75a68959ccb0211c139d15f96c023983ba093ed2387';eof=read(eofp,eofs)
stagep=S+'outputs/root_market_source_only_tuple3_stage01/receipt.json';stages='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999';stage=read(stagep,stages)
ownerp=hand['fixed_prior_owner']['path'];owners=hand['fixed_prior_owner']['sha256'];owner=read(ownerp,owners)
allow={r['target']:r['old_sha256']for r in scope['targets']};assert len(allow)==30 and back['target_count']==30
backrows={'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r for r in back['targets']};assert {path:r['sha256']for path,r in backrows.items()}==allow
def backupref(path):
    r=backrows[path];return{'path':'res://'+Path(r['backup_path']).resolve().relative_to(G).as_posix(),'sha256':r['sha256']}
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,v,s):pins[i]={'id':i,'path':v,'sha256':s}
for i,r in [('execution_approval',hand['execution_proposal']),('repair30_parent_execution',hand['execution_parent']),('repair30_hand',{'path':hp,'sha256':hs}),('repair30_inverse',hand['whole_inverse_proof']),('repair30_scope',hand['scope']),('repair30_Root',{'path':rootp,'sha256':roots}),('repair30_backups',{'path':backp,'sha256':backs}),('repair30_EOF',{'path':eofp,'sha256':eofs}),('repair30_execution_Root',{'path':xp,'sha256':xs}),('repair30_prior_owner',hand['fixed_prior_owner']),('repair30_prior_stage',{'path':stagep,'sha256':stages}),('repair30_contract_candidate',records['runtime_contract']['candidate'])]:pin(i,r['path'],r['sha256'])
current={}
for n in old['nodes']:
    if n['kind']=='map':continue
    r=stage['nodes'][n['id']];b=fixed(r['path'],r['sha256']);is_json=n.get('is_json',False)or n['kind']=='metadata'
    current[n['id']]={**r,'bytes':b,'value':json.loads(b)if is_json else None}
basebyid={n['id']:copy.deepcopy(n)for n in template['nodes']};basebyid['registry_final']=copy.deepcopy(next(n for n in regtemplate['nodes']if n['id']=='registry_final'))
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';DT=records['DT']['target'];F=records['Fade']['target'];C=records['C']['target'];CON=records['runtime_contract']['target'];REG='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
refs={r['target']:r['candidate']['sha256']for r in records.values()if'target'in r};refs[EXE]={'$pin':'execution_approval'}
for n in basebyid.values():
    if n.get('target')in allow:refs[n['target']]={'$sha':n['id']}
refs[CON]={'$sha':'runtime_contract_final'}
def sourceops(value,fields):
    return[{'op':'set','pointer':ks+[path],'existed':True,'old':ptr(value,ks)[path],'new':x}for ks in fields for path,x in refs.items()if path in ptr(value,ks)]
nodes=[];frozen={};FADEROWS={'legacy_manifest_2','legacy_manifest_7','finite08_yamen','finite08_market'};fade_ids=[]
for oldn in old['nodes']:
    ident=oldn['id'];n=copy.deepcopy(basebyid[ident])
    if oldn['kind']=='map':
        n=copy.deepcopy(oldn);n['operations']=[op for op in n['operations']if op['pointer'][-1]not in proposal['owned']]
        for op in n['operations']:
            if op['pointer'][-1]in refs:op['new']=refs[op['pointer'][-1]]
        nodes.append(n);continue
    v=current[ident]
    if ident=='ap_environment_index':
        i='repair30_frozen_'+ident;pin(i,v['path'],v['sha256']);frozen[ident]=v['sha256'];nodes.append({'id':ident,'kind':'repair30_frozen','base_input':i,'immutable_sha256':v['sha256']});continue
    target=n.get('target')
    if ident=='runtime_contract_final':target=CON;n['target']=CON
    assert target in allow,(ident,target)
    r=backupref(target);i='repair30_parent_'+ident;pin(i,r['path'],r['sha256']);b=fixed(r['path'],r['sha256']);v['value']=json.loads(b)if n['kind']!='index'else None
    n['base_input']=i;n['old_sha256']=r['sha256']
    if n['kind']=='index':
        for rep in n['replacements']:
            x=rep['new']
            if isinstance(x,dict)and '$sha'in x:rep['old']=current[x['$sha']]['sha256']
            elif x=={'$pin':'execution_approval'}:rep['old']=oldexecsha
            assert b.count(rep['old'].encode())==1
        nodes.append(n);continue
    if ident=='runtime_contract_final':
        n['kind']='repair30_contract_literal';n['literal_candidate_input']='repair30_contract_candidate';n['operations']=[{'op':'set','pointer':['source_sha256',C],'existed':True,'old':owner['core_source_sha256'][C],'new':records['C']['candidate']['sha256']}];nodes.append(n);continue
    assert n['kind']=='metadata',(ident,n['kind'])
    fields=[f['pointer']for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[]);n['operations']=sourceops(v['value'],fields)
    if ident=='registry_final':
        ids=[op['pointer'][1]for op in n['operations']];assert not ids
        ids=[op['pointer'][1]for op in basebyid[ident]['operations']];assert len(set(ids))==5
        n['operations']=[{'op':'set','pointer':['rooms',id,'source_sha256',DT],'existed':True,'old':v['value']['rooms'][id]['source_sha256'][DT],'new':records['DT']['candidate']['sha256']}for id in ids]
    if ident=='estate_final':
        assert v['value']['registry_path']==REG and v['value']['registry_sha256']==v['value']['source_sha256'][REG]=='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28'
        n['operations'].insert(0,{'op':'set','pointer':['registry_sha256'],'existed':True,'old':v['value']['registry_sha256'],'new':{'$sha':'registry_final'}})
    if ident in FADEROWS:
        oldrow=v['value']['source_migration']['source_delta'][F];newrow=copy.deepcopy(oldrow);assert oldrow['new_sha256']==owner['core_source_sha256'][F]
        if owner['core_source_sha256'][F]not in newrow['historical_sha256']:newrow['historical_sha256'].append(owner['core_source_sha256'][F])
        newrow.update(current_before_sha256=owner['core_source_sha256'][F],new_sha256=records['Fade']['candidate']['sha256'],candidate_path=records['Fade']['candidate']['path'])
        n['operations'].append({'op':'set','pointer':['source_migration','source_delta',F],'existed':True,'old':oldrow,'new':newrow});fade_ids.append(ident)
    if ident in ['market_final','finite08_market']:
        # Keep the Root39 exact2 group where current51 legitimately installed it.
        gid='source_only_proof_autoimport_exact2'
        if gid not in n['source_bundle']['groups']:n['source_bundle']['groups'].append(gid)
    nodes.append(n)
assert set(fade_ids)==FADEROWS
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for path,x in refs.items():
            if path in group['leaves']:group['leaves'][path]=x
passes=[{'target':records[name]['target'],'old_sha256':records[name]['parent']['sha256'],'candidate_path':records[name]['candidate']['path'],'candidate_sha256':records[name]['candidate']['sha256']}for name in ['adapter','B','C','DT','Fade','Coordinator','Temple']]
passes.append({'target':EXE,'old_sha256':oldexecsha,'candidate_path':hand['execution_proposal']['path'],'candidate_sha256':newexecsha})
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=groups,root_target_allowlist=list(allow),pass_through_targets=passes,prospective_targets=[{'target':r['target'],'candidate_path':r['candidate_path'],'sha256':r['candidate_sha256']}for r in passes],output_root=S+'outputs/root_market_complete_parent30_stage01/',source_baseline='Fixed formalAP15 FC11 and Root43 exact30 old backups. SystemCF2AA complete frozenAP parent fix only; all other runtime changes SHA/provenance literals.85 oldpins +10 exact snapshots; Root39SOURCE_ONLY2 retained. Registry5DT source values and Estate triple equality, four independent AO maps; no collector expectation fill.')
spec['B_only_contract']={'production_input':'repair30_hand','inverse_input':'repair30_inverse','scope_input':'repair30_scope','Root_input':'repair30_Root','backup_input':'repair30_backups','eof_transport_input':'repair30_EOF','execution_Root_input':'repair30_execution_Root','expected_execution_Root_document':xr,'expected_execution_Root_sha256':xs,'exact_execution_pointer_fields':approvalfields,'parent_execution_input':'repair30_parent_execution','prior_owner_input':'repair30_prior_owner','prior_stage_input':'repair30_prior_stage','contract_candidate_input':'repair30_contract_candidate'}
for gate in spec['required_gates']:
    if gate['input']=='tuple3_backups':gate['input']='repair30_backups';gate['pointer']=['target_count'];gate['equals']=30
# Runtime driver: keep frozen base and its validators. Explicit scopes below
# validate the complete graph, not a generalized JSON or whitespace exception.
source=oldtool.decode();header=source[:source.index('FIXED_AUTHORITY=')]
header+="PARENT='"+oldexecsha+"'\nPROPOSAL='"+newexecsha+"'\nEXE='"+EXE+"'\nFROZEN="+repr(frozen)+'\n'
constructor='''class MarketCompleteParentStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_EXACT30')
        super().__init__(spec);self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input']);self.codes=self.read_json_input(c['inverse_input'])['records']
        need(self.inputs[c['production_input']]['sha256']=='e12394b9f9f47524f5118c3fb4ddad9a38306d042289eaddbe9f830a7398d953' and self.inputs[spec['authority_input']]['sha256']==PROPOSAL,'FIXED57_CODE_AND_PROPOSAL')
        root=self.read_json_input(c['Root_input']);request=self.read_json_input(c['scope_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['Root_input']]['sha256']=='93e5b14e78f070a5c035fbe5a06d4477c9c622967ff3adb0b8788a18f71708e7' and root.get('approved_by_root') is True and root.get('status')=='ROOT_APPROVES_EXACT30_MARKET_COMPLETE_FROZEN_PARENT_SOURCE_PREPARATION_ONLY' and root.get('existing_targets')==30 and root.get('GD_targets')==15 and root.get('JSON_targets')==15 and root.get('Stage_execution_authorized') is False and root.get('deployment_authorized') is False,'EXACT_ROOT43_PREPARATION_SCOPE')
        need(self.inputs[c['scope_input']]['sha256']==root['scope_sha256']=='5fdf8409e6866feb7f9306889446310c756c23951dc3313dccfbca992fedd311' and root['fresh_before_sha256']=='25374fe35efa1d64f7efeadb8ccaec28e6e0574b53e471d77af837a48fc75c20' and self.inputs[c['backup_input']]['sha256']==root['old_full_backups_sha256']=='447052f129c1e9fde1e06788cc6e12c09e038a78aee733befe293c1740630769','FIXED_SCOPE_FRESH_AND_BACKUPS')
        approval=self.read_json_input(c['execution_Root_input']);need(self.inputs[c['execution_Root_input']]['sha256']==c['expected_execution_Root_sha256'] and same(approval,c['expected_execution_Root_document']) and approval.get('approved_by_root') is True,'FINAL_FIXED_EXECUTION_ROOT_APPROVAL')
        need(c['exact_execution_pointer_fields'] and {str(r['value']).lower()for r in c['exact_execution_pointer_fields']}=={PARENT,PROPOSAL} and all(same(M.pointer(approval,r['pointer']),r['value'])for r in c['exact_execution_pointer_fields']),'ROOT_EXPLICIT_PARENT_AND_PROPOSAL_IDENTITY')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==30 and list(self.oldtargets)==spec['root_target_allowlist'] and backups.get('target_count')==30 and len(backups['targets'])==30,'EXACT30_TARGETSET')
        backed={}
        for r in backups['targets']:
            q=Path(r['path']).resolve();b=Path(r['backup_path']).resolve();need(q.is_relative_to(M.ROOT) and b.is_relative_to(M.ROOT),'BACKUP_GAME_DOMAIN')
            path='res://'+q.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];old=self.read('res://'+b.relative_to(M.ROOT).as_posix(),r['sha256']);need(len(old)==r['bytes'] and old==self.read(path,r['sha256']),'ALL30_FULL_OLD_BYTES_BACKED_UP')
        need(backed==self.oldtargets,'BACKUP_EXACT_SCOPE')
        owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['prior_owner_input']]['sha256']=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02' and all(owner['core_source_sha256'].get(path)==s for path,s in self.oldtargets.items()),'EXACT_CURRENT_FC11_NOT_CURRENT_FILL')
        prior=self.read_json_input(c['parent_execution_input']);need(self.inputs[c['parent_execution_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'TEN_ORIGINAL_OWNED_MEMBERS')
        changed={self.codes[name]['target']for name in ['B','DT','Coordinator','Temple']};restored=copy.deepcopy(self.authority)
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                r=next(r for r in self.codes.values()if r.get('target')==path);need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONLY_ONE_EDGE_KEEP_HISTORY');e=after['edges'][-1]
                need(e['old_sha256']==before['current_sha256']==r['parent']['sha256'] and e['new_sha256']==after['current_sha256']==r['candidate']['sha256'] and e['new_snapshot']==r['candidate']['path'] and same(e['replacements'],r['hunks']),'EXACT_FOUR_LITERAL_WHOLE_BYTE_EDGES');restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_SIX_WHOLE_ROWS_SAME')
        extra={path:s for path,s in self.authority['source_sha256'].items()if path not in prior['source_sha256']};need(len(prior['source_sha256'])==85 and len(self.authority['source_sha256'])==95 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()) and same(extra,self.hand['new_exact10_proof_pins']),'OLD85_AND_EXACT10_PROOF_SNAPSHOTS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_BF043')
        for r in self.codes.values():
            before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=after
            for h in r['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'UNIQUE_WHOLE_LITERAL_HUNKS');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==after and inverse==before,'ALL_NINE_CODE_DATA_WHOLE_BYTE_INVERSES')
        self.eof_approval=self.read_json_input(c['eof_transport_input']);eof=self.eof_approval
        need(self.inputs[c['eof_transport_input']]['sha256']=='25ff1b9474bb50ccc149e75a68959ccb0211c139d15f96c023983ba093ed2387' and eof.get('approved_by_root') is True and eof.get('old_sha256')=='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84' and eof.get('candidate_sha256')=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736' and eof.get('patch_intermediate_sha256')=='9fc421182b8143f3fe0711322fe51788b443b5a5132dd7c524d961562b0f0025','EXACT_NEW_SINGLE_EOF_AUTHORITY')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY30_CHANGED_TARGETS_NO_NOOP')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='repair30_frozen':
            ident=row['id'];need(ident in FROZEN and self.inputs[row['base_input']]['sha256']==row['immutable_sha256']==FROZEN[ident] and 'target'not in row,'ONLY_UNCHANGED_ENV_INDEX');raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':None};self.proofs[ident]={'frozen_original_bytes':True};return
        if row['kind']=='repair30_contract_literal':
            work=copy.deepcopy(row);work['kind']='metadata';literal=work.pop('literal_candidate_input');need(row['target']=='res://data/luoyang_culture_integration_20261019x/runtime_contract.json' and row['old_sha256']=='59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1' and self.inputs[literal]['sha256']=='d258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b','ONLY_EXACT_CULTURE_C_LITERAL_SUCCESSOR')
            super().build_node(work);ident=row['id'];node=self.nodes[ident];before=self.input_bytes[row['base_input']];candidate=self.input_bytes[literal];need(same(node['value'],self.read_json_input(literal)) and self.proofs[ident]['whole_typed_inverse'] is True,'ORIGINAL_SOURCE_ONLY_WHOLE_TYPED_INVERSE_BEFORE_LITERAL')
            oldC='b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be';newC='1dbd8c1357608a96c04a602f2c0a3c5f4478928bbc969c43963c6f430ef2c2b7';need(candidate.count(newC.encode())==1 and before.count(oldC.encode())==1 and candidate.replace(newC.encode(),oldC.encode(),1)==before and before.replace(oldC.encode(),newC.encode(),1)==candidate,'CONTRACT_SINGLE_C_VALUE_FULL_BYTE_INVERSE')
            self.outputs[node['path']]=candidate;node['sha256']=sha(candidate);self.targets[row['target']]['candidate_sha256']=sha(candidate);self.proofs[ident]['exact_literal_bytes_after_original_typed_inverse']=True;return
        super().build_node(row)
        if row['id']=='registry_final':
            before=self.read_json_input(row['base_input']);after=self.nodes[row['id']]['value'];inverse=copy.deepcopy(after);need(len(row['operations'])==5,'ONLY_FIVE_DT_REGISTRY_VALUES')
            for op in row['operations']:need(len(op['pointer'])==4 and op['pointer'][0]=='rooms' and op['pointer'][2]=='source_sha256' and op['pointer'][3]=='res://scripts/city/luoyang_district_life_20261016f.gd','ONLY_DT_ROOM_SOURCE_OP');M.pointer(inverse,op['pointer'][:-1])[op['pointer'][-1]]=op['old']
            need(same(inverse,before),'FULL_REGISTRY_OTHER_FIELDS_UNCHANGED')
        if row['id']=='estate_final':
            value=self.nodes[row['id']]['value'];registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json';need(value.get('registry_path')==registry and value.get('registry_sha256')==value.get('source_sha256',{}).get(registry)==self.nodes['registry_final']['sha256'],'ESTATE_REGISTRY_PATH_SCALAR_SOURCE_TRIPLE_EQUALITY')
'''
# Use only the already-reviewed exact EOF shadow mechanism, with new fixed pair.
eofsource=fixed(S+'stage_performance38_exact_EOF_transport_READY.py','4449a867dbaed67528000507c8f8903c7cdb46f3e36a50fdc9f0b47fd1c220b1').decode();a=eofsource.index('    def _exact_eof_transport_patch(');z=eofsource.index('\n    def target(',a);eofmethod=eofsource[a:z]
for a,b in [('30356','30746'),('30746','31206'),('30747','31207'),('184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97',eofs),('ONLY_EXACT_999A_TO5709_EOF_PAIR','ONLY_EXACT_5709_TOCF2AA_EOF_PAIR')]:eofmethod=eofmethod.replace(a,b)
# Correct the old-byte constant separately: sequential replacement above also
# touched the just-inserted old length. No generalized EOL transformation.
eofmethod=eofmethod.replace('len(before)==31206 and len(after)==31206','len(before)==30746 and len(after)==31206')
run=source[source.index('    def run(self):'):source.index('\ndef main():')]
at=run.index("        for row in self.spec['nodes']")
run=run[:at]+'''        exact={r['target']:r['candidate']for r in self.codes.values()if r.get('target','').endswith('.gd')};exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==8 and len(self.spec['pass_through_targets'])==8,'EXACT_SEVEN_GD_PLUS_EXECUTION_PASSTHROUGHS')
        for row in self.spec['pass_through_targets']:
            need(row['target']in exact and row['old_sha256']==self.oldtargets[row['target']] and exact[row['target']]=={'path':row['candidate_path'],'sha256':row['candidate_sha256']},'ONLY_FIXED_RUNTIME_CANDIDATE_BYTES');self.read(row['candidate_path'],row['candidate_sha256']);self.read(row['target'],row['old_sha256']);self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
'''+run[at:]
a=run.index("                matches=[k for k,v in self.nodes.items()");z=run.index('                copies.append(',a)
run=run[:a]+'''                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_BF043_TO647949_EXECUTION_BYTES');proof_id='fixed_Root_execution_whole_inverse'
                else:
                    matches=[k for k,v in self.nodes.items()if v['path']==path and v['sha256']==row['candidate_sha256']];need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
'''+run[z:]
for a,b in [('len(self.targets)==3','len(self.targets)==30'),('len(copies)==2','len(copies)==15'),('len(reconstruction)==3','len(reconstruction)==30'),("endswith('.gd')])==1","endswith('.gd')])==15"),("'target_count':2","'target_count':15"),("'patch_count':1,'copy_count':2,'total':3","'patch_count':15,'copy_count':15,'total':30"),("'targets':3,'map_nodes':4","'targets':30,'map_nodes':4"),('EXACT3_CHANGED','EXACT30_CHANGED'),('PATCH1_COPY2','PATCH15_COPY15'),('UNION3','UNION30'),('EXACT2_GENERATED','EXACT15_GENERATED'),('M._strict_lf_build_file_patch(res(row[\'target\']).as_posix(),before,candidate)','self._exact_eof_transport_patch(res(row[\'target\']).as_posix(),before,candidate)')]:run=run.replace(a,b)
main=source[source.index('\ndef main():'):].replace('MarketSourceTupleStage(spec)','MarketCompleteParentStage(spec)')
nt=S+'stage_performance58_market_parent30_READY.py';tool=(header+constructor+eofmethod+'\n'+run+main).encode();ast.parse(tool);spec['required_generator']={'path':nt,'sha256':sha(tool)}
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input']and isinstance(x,str)and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(spec['required_gates']);used.update(x for k,x in spec['B_only_contract'].items()if k.endswith('_input'));spec['pinned_inputs']=[r for r in pins.values()if r['id']in used]
assert {r['target']for r in passes}|{n['target']for n in nodes if'target'in n}==set(allow)and len(passes)==8
assert len([n for n in nodes if n['kind']=='index'])==8 and len([n for n in nodes if n['kind']in ['metadata','repair30_contract_literal']])==14
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
proofout={'status':'EXACT30_MARKET_COMPLETE_PARENT_DRIVER_BYTE_INPUT_TYPED_INVERSE_NOT_STAGED','parent_driver':{'path':tp,'sha256':ts},'whole_driver_byte_forward_inverse':True,'driver_hunks':hunks,'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_serialized_inverse':True,'input_deltas':deltas,'original8DE0_unchanged':True,'only_adapter_EXACT_EOF_transport':{'approval':{'path':eofp,'sha256':eofs},'intermediate_sha256':eof['patch_intermediate_sha256'],'sole_final0A_format_required_after_Root_actualpatch':True},'current_authority95only4edges_and_prior85kept':True,'registry_only5DT_and_Estate_triple':True,'four_current_Fade_rows':sorted(FADEROWS),'Root39_SOURCE_ONLY2_preserved_Market_only':True,'engine_Stage_collector_formal_calls':0};pb=js(proofout)
handoff={'status':'ROOT43_EXACT30_MARKET_COMPLETE_PARENT_FINAL_DRIVER_INPUT_NOT_STAGED','driver':{'path':nt,'sha256':sha(tool)},'input':{'path':np,'sha256':sha(ib)},'complete_driver_diff':{'path':O+'driver_complete_vs51.diff','sha256':sha(diff)},'whole_inverse':{'path':O+'driver_input_whole_inverse_READY.json','sha256':sha(pb)},'targets':30,'GD':15,'JSON':15,'execution_proposal_sha256':newexecsha,'Root_only_NOT_EXECUTED_command':'python '+str(p(nt))+' '+str(p(np))+' --input-sha256 '+sha(ib)}
files={nt:tool,np:ib,O+'driver_complete_vs51.diff':diff,O+'driver_input_whole_inverse_READY.json':pb,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(nt).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
