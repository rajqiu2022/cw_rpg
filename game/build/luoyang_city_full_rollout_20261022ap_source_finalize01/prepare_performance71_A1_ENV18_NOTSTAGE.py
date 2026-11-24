"""One selected C215/F1D0 source recipe, text only; do not import/run Stage."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/';Y='res://build/luoyang_city_full_rollout_20261022ap_system01/';O=S+'performance71_A1_ENV18_source_recipe/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s.lower(),('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
tp=S+'stage_performance62_ground8_READY.py';ts='b7114e62b03dca467030ad2c6fde04bbd8367aa1267776866e5fe92fc983067c';oldtool=fixed(tp,ts)
ip=S+'performance62_ground8_source_recipe/source_input_ROOT_LOCKED.json';iss='48d8f26e1b16cfde0636feab432a21ec20e137279ac9b1e9c5bae02b2e4ff277';oldinput=fixed(ip,iss);old=json.loads(oldinput)
templates=read(S+'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json','a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140')
stagep=S+'outputs/root_market_ground_exact8_stage01/receipt.json';stages='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe';stage=read(stagep,stages)
ownerp=S+'performance64_ground8_actual_independent_review/owner_source_maps_READY.json';owners='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0'
scopep=S+'performance66_ENV_A1_existing_scope_READONLY_PROSPECT.json';scopes='f9366efd437e41f85cc6f0802f3373b2525e142a5336f0456ab142e71e447979';scope=read(scopep,scopes)
rootp=R+'integration48/A1_ENV18_preparation_approval_READY.json';roots='c97b0e91f0856f8c8840ccd1a3035087da465f36b4d12cbf033300efe9daa3e7';root=read(rootp,roots)
backp=R+'integration48/old_full_backups_READY.json';backs='316af8888619590a9f28eeee09cd6b8a349a381ab448fbe4e1827cbef3eea914';back=read(backp,backs)
beforep=R+'integration48/guard_before.json';befores='e6265c42b67b46f47b7c6d2ddaa60bb7877dcaed0019016ce6936e9fd761089e'
authorp=Y+'market_L_continuous_material_epoch01/author_interface_READY_NOT_RUNTIME.json';authors='1183eda4f35cc8eea176a53797d0c3ed9d63d232940b245cd39dfae9e8268caa'
proofp=Y+'market_L_continuous_material_epoch01/ENV_wholebyte_inverse_READY.json';proofs='1091f241c877fa5d4ce575f3e2bf56165539de7a55305f43d832c447e03a7e95';proof=read(proofp,proofs)
tonep=Y+'market_L_continuous_material_epoch01/OPTIONAL_forecourt_tone_one_hunk_inverse_READY.json';tones='fa9d5e131c4ae4b12e1ceb27e4a13db0b6a02e1e91543ba85e1e982e428de548';tone=read(tonep,tones)
reviewp=S+'performance70_A1_combined_C215_F1D0_independent_static_review_READY.json';reviews='72d566463948d3e128b60fca6f0c93d9674c97c528d9da46adc8f05ff5b77774'
env=proof['parent']['path'];envold=proof['parent']['sha256'].lower();envnew=root['selected_ENV_sha256'];shaderpath=root['new_Market_only_shader_path'];shaders=root['new_Market_only_shader_sha256']
allow={r['target']:r['old_sha256']for r in scope['existing_targets']};assert len(allow)==back['target_count']==18
assert {'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r['sha256']for r in back['targets']}==allow
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,v,s):pins[i]={'id':i,'path':v,'sha256':s.lower()}
for i,v,s in [('a1_scope',scopep,scopes),('a1_root',rootp,roots),('a1_backups',backp,backs),('a1_before',beforep,befores),('a1_author',authorp,authors),('a1_base_proof',proofp,proofs),('a1_tone_proof',tonep,tones),('a1_review',reviewp,reviews),('a1_prior_stage',stagep,stages),('a1_prior_owner',ownerp,owners),('a1_candidate',root['selected_ENV_path'],envnew),('a1_shader',shaderpath,shaders)]:pin(i,v,s)
cur={}
for ident,row in stage['nodes'].items():
    if ident.startswith('expected_ch4_'):continue
    raw=fixed(row['path'],row['sha256']);cur[ident]={**row,'bytes':raw,'parsed':json.loads(raw)if row.get('value')is not None else None}
refs={n['target']:{'$sha':n['id']}for n in templates['nodes']if n.get('target')in allow};refs[env]={'$pin':'a1_candidate'}
nodes=[{'id':'ENV_code','kind':'a1_code','base_input':'a1_candidate','target':env,'old_sha256':envold}];frozen={}
ground=copy.deepcopy(next(n for n in old['nodes']if n['id']=='ground_code'));ground['kind']='a1_frozen';ground.pop('target');ground.pop('old_sha256');ground['immutable_sha256']=cur['ground_code']['sha256'];ground['is_json']=False;frozen['ground_code']=cur['ground_code']['sha256'];nodes.append(ground)
for original in templates['nodes']:
    if original['kind']=='map':continue
    n=copy.deepcopy(original);ident=n['id'];v=cur[ident];base='a1_parent_'+ident;pin(base,v['path'],v['sha256'])
    if n.get('target')not in allow:
        frozen[ident]=v['sha256'];nodes.append({'id':ident,'kind':'a1_frozen','base_input':base,'immutable_sha256':v['sha256'],'is_json':v['parsed']is not None});continue
    n['base_input']=base;n['old_sha256']=v['sha256'];assert allow[n['target']]==v['sha256']
    if n['kind']=='index':
        for rep in n['replacements']:
            x=rep['new']
            if isinstance(x,dict)and'$sha'in x:rep['old']=cur[x['$sha']]['sha256'];assert v['bytes'].count(rep['old'].encode())==1
        nodes.append(n);continue
    assert n['kind']=='metadata';n['operations']=[]
    fields=n['source_bundle']['fields']if'source_bundle'in n else[f['pointer']for f in n.get('source_fields',[])]
    for ks in fields:
        for path,new in refs.items():
            if path in ptr(v['parsed'],ks):n['operations'].append({'op':'set','pointer':ks+[path],'existed':True,'old':ptr(v['parsed'],ks)[path],'new':new})
    assert any(op['pointer'][-1]==env for op in n['operations'])or ident=='market_final'
    if ident in ['market_final','finite08_market']:n['source_bundle']['groups'].append('A1_Market_runtime_shader')
    nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit'and env in group['leaves']:assert group['leaves'][env]==envold;group['leaves'][env]={'$pin':'a1_candidate'}
groups.append({'id':'A1_Market_runtime_shader','kind':'explicit','leaves':{shaderpath:{'$pin':'a1_shader'}}})
for original in old['nodes']:
    if original['kind']!='map':continue
    n=copy.deepcopy(original)
    baseline=read(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])
    if env in baseline['source_sha256']:n['operations'].append({'op':'set','pointer':['source_sha256',env],'existed':True,'old':baseline['source_sha256'][env],'new':{'$pin':'a1_candidate'}})
    if n['scene_id']=='ch4_s3_luoyang_market':n['groups'].append('A1_Market_runtime_shader')
    nodes.append(n)
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=groups,root_target_allowlist=list(allow),pass_through_targets=[],prospective_targets=[],output_root=S+'outputs/root_A1_ENV18_stage01/',source_baseline='Fixed1DFF current metadata and independent669 fullsource. One selected C215 nonowned ENV code, one F1D0 ordinary runtime shader onlyMarket. Exact18 existing value successors, Market1713 only+1shader; other scenes/rooms existing domains. Execution647949/10owned/95proof/native/groundC1EF/Root39SOURCE_ONLY2/registry/Estate triple unchanged.')
spec['B_only_contract']={'scope_input':'a1_scope','admission_input':'a1_root','backup_input':'a1_backups','before_input':'a1_before','author_input':'a1_author','proof_input':'a1_base_proof','tone_input':'a1_tone_proof','review_input':'a1_review','candidate_input':'a1_candidate','shader_input':'a1_shader','parent_stage_input':'a1_prior_stage','prior_owner_input':'a1_prior_owner'}
for gate in spec['required_gates']:
    if gate['input']=='ground8_backups':gate['input']='a1_backups';gate['pointer']=['target_count'];gate['equals']=18
source=oldtool.decode();header=source[:source.index('FROZEN=')]
header=header[:header.index('"""')]+'"""Exact18 selected A1 ENV source compiler; Root-only future Stage, never deployment."""\n'+header[header.index('import argparse'):]
header+='FROZEN='+repr(frozen)+'\nENV='+repr(env)+'\nOLD_ENV='+repr(envold)+'\nNEW_ENV='+repr(envnew)+'\nSHADER='+repr(shaderpath)+'\nSHADER_SHA='+repr(shaders)+'\n'
body='''class A1EnvironmentStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_A1_EXACT18')
        super().__init__(spec);c=spec['B_only_contract'];request=self.read_json_input(c['scope_input']);root=self.read_json_input(c['admission_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']==root['scope_sha256']=='f9366efd437e41f85cc6f0802f3373b2525e142a5336f0456ab142e71e447979' and self.inputs[c['admission_input']]['sha256']=='c97b0e91f0856f8c8840ccd1a3035087da465f36b4d12cbf033300efe9daa3e7' and root['status']=='ROOT_ENV_NONOWNED_A1_PLUS_TONE_EXACT18_PREPARATION_APPROVED_NOT_STAGE_OR_DEPLOYMENT','EXACT_ROOT_SELECTED_A1_ENV18')
        need(self.inputs[c['backup_input']]['sha256']==root['old18_full_backups_sha256']=='316af8888619590a9f28eeee09cd6b8a349a381ab448fbe4e1827cbef3eea914' and self.inputs[c['before_input']]['sha256']==root['root48_before_sha256']=='e6265c42b67b46f47b7c6d2ddaa60bb7877dcaed0019016ce6936e9fd761089e' and backups['target_count']==18 and backups['scope_sha256']==self.inputs[c['scope_input']]['sha256'],'EXACT18_BACKUPS_ROOT48_FRESH')
        self.oldtargets={r['target']:r['old_sha256']for r in request['existing_targets']};need(len(self.oldtargets)==18 and list(self.oldtargets)==spec['root_target_allowlist'],'EXACT18_ORDERED_EXISTING_TARGETS')
        backed={}
        for r in backups['targets']:
            target=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'EXACT_BACKUP_GAME_PATHS')
            path='res://'+target.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'COMPLETE_EIGHTEEN_OLD_BYTE_BACKUPS')
        need(backed==self.oldtargets and self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and len(self.authority['owned'])==10 and len(self.authority['source_sha256'])==95 and ENV not in self.authority['owned'] and ENV not in self.authority['source_sha256'] and not spec['pass_through_targets'] and not spec['prospective_targets'],'UNCHANGED_EXECUTION647949_OWNED10_PROOF95_NONOWNED_ENV')
        stage=self.read_json_input(c['parent_stage_input']);self.owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['parent_stage_input']]['sha256']=='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe' and self.inputs[c['prior_owner_input']]['sha256']==root['current_owner_sha256']=='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0','FIXED1DFF_OWNER669_NOT_CURRENT_FILL')
        need(all(self.owner['core_source_sha256'].get(path)==old for path,old in self.oldtargets.items()) and self.oldtargets[ENV]==OLD_ENV,'ALL18_OLD_VALUES_FROM_FIXED669_CORE')
        self.baseproof=self.read_json_input(c['proof_input']);self.toneproof=self.read_json_input(c['tone_input']);author=self.read_json_input(c['author_input']);review=self.read_json_input(c['review_input'])
        need(self.inputs[c['proof_input']]['sha256']==root['A1_full_inverse_sha256']=='1091f241c877fa5d4ce575f3e2bf56165539de7a55305f43d832c447e03a7e95' and self.inputs[c['tone_input']]['sha256']==root['tone_single_hunk_inverse_sha256']=='fa9d5e131c4ae4b12e1ceb27e4a13db0b6a02e1e91543ba85e1e982e428de548' and self.inputs[c['author_input']]['sha256']==root['A1_author_sha256']=='1183eda4f35cc8eea176a53797d0c3ed9d63d232940b245cd39dfae9e8268caa','EXACT_TWO_SELECTED_ENV_INVERSE_PROOFS')
        need(self.inputs[c['candidate_input']]['sha256']==root['selected_ENV_sha256']==NEW_ENV and self.inputs[c['candidate_input']]['path']==root['selected_ENV_path'] and self.inputs[c['shader_input']]['sha256']==root['new_Market_only_shader_sha256']==SHADER_SHA and self.inputs[c['shader_input']]['path']==root['new_Market_only_shader_path']==SHADER,'ONE_SELECTED_C215_AND_F1D0_RUNTIME_SHADER')
        need(self.inputs[c['review_input']]['sha256']=='72d566463948d3e128b60fca6f0c93d9674c97c528d9da46adc8f05ff5b77774' and review['findings']==[] and review['selected_single_ENV_candidate']['sha256']==NEW_ENV and author['runtime_ready'] is False,'INDEPENDENT_STATIC_NOT_GPU_OR_ART_CREDIT')
        group=[r for r in spec['source_groups']if r['id']=='A1_Market_runtime_shader'];need(len(group)==1 and same(group[0],{'id':'A1_Market_runtime_shader','kind':'explicit','leaves':{SHADER:{'$pin':c['shader_input']}}}),'EXACT_ONE_ORDINARY_MARKET_SHADER_GROUP')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT18_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='a1_code':
            need(row['id']=='ENV_code' and row['target']==ENV and row['old_sha256']==OLD_ENV,'EXACT_NONOWNED_ENV_ONLY')
            raw=self.input_bytes[row['base_input']];before=self.read(ENV,OLD_ENV);ops=self.baseproof['operations_in_order'];tone=self.toneproof['one_hunk'];need(len(ops)==10 and sha(raw)==NEW_ENV,'TEN_A1_OPERATIONS_PLUS_ONE_RGB')
            forward=before
            for h in ops:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1,'UNIQUE_A1_OLD_HUNK');forward=forward.replace(a,b,1)
            need(sha(forward)==self.baseproof['candidate']['sha256'].lower()==self.toneproof['parent_A1_ENV']['sha256'].lower(),'FIXED047B_INTERMEDIATE')
            a,b=tone['old'].encode(),tone['new'].encode();need(forward.count(a)==1 and raw.count(b)==1 and forward.replace(a,b,1)==raw,'EXACT_ONE_RGB_FORWARD')
            inverse=raw.replace(b,a,1)
            for h in reversed(ops):
                a,b=h['old'].encode(),h['new'].encode();need(inverse.count(b)==1,'UNIQUE_A1_NEW_HUNK');inverse=inverse.replace(b,a,1)
            need(inverse==before and b'\\r'not in raw and raw.endswith(b'\\n'),'WHOLE_ENV_BYTE_INVERSE_STRICT_LF_NO_NORMALIZATION')
            path=self.inputs[row['base_input']]['path'];self.nodes[row['id']]={'path':path,'sha256':sha(raw),'value':None};self.proofs[row['id']]={'whole_byte_forward_inverse':True,'A1_operations':10,'RGB_operations':1,'nonowned_no_execution_change':True};self.target(ENV,OLD_ENV,path,sha(raw));return
        if row['kind']=='a1_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'EXACT_FROZEN_OTHER_DOMAINS')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['kind']=='metadata':
            before=self.read_json_input(row['base_input']);value=self.nodes[row['id']]['value'];expected=copy.deepcopy(before)
            fields=row['source_bundle']['fields']if'source_bundle'in row else[f['pointer']for f in row.get('source_fields',[])]
            for keys in fields:
                values=M.pointer(expected,keys)
                for path,target in self.targets.items():
                    if path in values:need(values[path]==target['old_sha256'],'EXACT_EXISTING_SOURCE_OLD');values[path]=target['candidate_sha256']
            if row['id']in ['market_final','finite08_market']:
                need(all(SHADER not in M.pointer(before,k)for k in fields),'ONE_NEW_MARKET_SHADER_ABSENT_BEFORE');expected['legacy_source_sha256'][SHADER]=SHADER_SHA
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse'] is True,'ONLY_ENV_EXISTING_HEADER_VALUES_AND_ONE_MARKET_SHADER')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:need(expected[path]==target['old_sha256'],'FIXED669_OLD_VALUE');expected[path]=target['candidate_sha256']
            if row['scene_id']=='ch4_s3_luoyang_market':need(len(old)==1712 and SHADER not in old,'FIXED669_MARKET1712');expected[SHADER]=SHADER_SHA
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_FULL_FIXED669_MAPS_EXACT18_VALUES_ONLY_MARKET_PLUS1')
'''
run=source[source.index('    def run(self):'):source.index('\ndef main():')]
for a,b in [('len(self.targets)==8','len(self.targets)==18'),('len(copies)==4','len(copies)==11'),('len(reconstruction)==8','len(reconstruction)==18'),("endswith('.gd')])==4","endswith('.gd')])==7"),("'target_count':4","'target_count':11"),("'patch_count':4,'copy_count':4,'total':8","'patch_count':7,'copy_count':11,'total':18"),("'targets':8,'map_nodes':4","'targets':18,'map_nodes':4"),('EXACT8','EXACT18'),('PATCH4_COPY4','PATCH7_COPY11'),('UNION8','UNION18'),('EXACT4_GENERATED','EXACT11_GENERATED')]:run=run.replace(a,b)
main=source[source.index('\ndef main():'):].replace('GroundSourceStage(spec)','A1EnvironmentStage(spec)')
nt=S+'stage_performance71_A1_ENV18_READY.py';tool=(header+body+run+main).encode();ast.parse(tool);spec['required_generator']={'path':nt,'sha256':sha(tool)}
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
    if r['id'].startswith('a1_'):fixed(r['path'],r['sha256'])
assert {n['target']for n in nodes if'target'in n}==set(allow)and len(allow)==18
def delta(a,b,ks=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():return[d for k in a for d in delta(a[k],b[k],ks+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):return[d for i in range(len(a))for d in delta(a[i],b[i],ks+[i])]
    return []if type(a)is type(b)and a==b else[{'pointer':ks,'old':a,'new':b}]
deltas=delta(old,spec);inverse=copy.deepcopy(spec)
for d in reversed(deltas):ptr(inverse,d['pointer'][:-1])[d['pointer'][-1]]=d['old']
assert js(inverse)==oldinput
aa=oldtool.decode().splitlines(True);bb=tool.decode().splitlines(True);hunks=[]
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hunks.append({'old_start':len(''.join(aa[:i]).encode()),'old_end':len(''.join(aa[:j]).encode()),'new_start':len(''.join(bb[:k]).encode()),'new_end':len(''.join(bb[k:z]).encode())+len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
forward=oldtool;reverse=tool
for h in reversed(hunks):forward=forward[:h['old_start']]+h['new'].encode()+forward[h['old_end']:];reverse=reverse[:h['new_start']]+h['old'].encode()+reverse[h['new_end']:]
assert forward==tool and reverse==oldtool
diff=''.join(difflib.unified_diff(aa,bb,fromfile=tp,tofile=nt)).encode();ib=js(spec);np=O+'source_input_ROOT_LOCKED.json'
proofout={'status':'ROOT48_SELECTED_C215_ENV18_DRIVER_BYTE_INPUT_TYPED_INVERSE_NOT_STAGED','parent_driver':{'path':tp,'sha256':ts},'whole_driver_byte_forward_inverse':True,'driver_hunks':hunks,'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_serialized_inverse':True,'input_deltas':deltas,'unchanged8DE0_core':True,'metadata_templates_from_fixed58_only_structure_not_old_values':True,'frozen_other_nodes':frozen,'execution647949_owned10_proof95_frozen':True,'one_ordinary_Market_shader_only_not_proof':{'path':shaderpath,'sha256':shaders},'target_count':18,'GD':7,'JSON':11,'engine_Stage_collector_formal_calls':0};pb=js(proofout)
handoff={'status':'ROOT48_A1_SELECTED_C215_ENV18_READY_NOT_STAGED','driver':{'path':nt,'sha256':sha(tool)},'input':{'path':np,'sha256':sha(ib)},'driver_complete_diff':{'path':O+'driver_complete_vs62.diff','sha256':sha(diff)},'whole_inverse':{'path':O+'driver_input_whole_inverse_READY.json','sha256':sha(pb)},'target_count':18,'GD':7,'JSON':11,'Root_only_NOT_EXECUTED_command':'python '+str(p(nt))+' '+str(p(np))+' --input-sha256 '+sha(ib)}
files={nt:tool,np:ib,O+'driver_complete_vs62.diff':diff,O+'driver_input_whole_inverse_READY.json':pb,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(nt).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
