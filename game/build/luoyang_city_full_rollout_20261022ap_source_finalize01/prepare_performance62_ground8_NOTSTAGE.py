"""Prepare exact8 ground source successor; text generation only, never import Stage."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/';Y='res://build/luoyang_city_full_rollout_20261022ap_system01/';O=S+'performance62_ground8_source_recipe/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s.lower(),('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
tp=S+'stage_performance51_market_tuple3_READY.py';ts='b446d7fe3c5aa9b0e5dce35d21053f12ea3ef22ad6af71bc6b8058f33304da7c';oldtool=fixed(tp,ts)
ip=S+'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json';iss='a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140';oldinput=fixed(ip,iss);old=json.loads(oldinput)
stagep=S+'outputs/root_market_complete_parent30_stage01/receipt.json';stages='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f';stage=read(stagep,stages)
ownerp=S+'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json';owners='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
scopep=S+'performance61_ground_finite35_exact8_scope_READONLY.json';scopes='ceaab710ea5aba573cb892e06acd21c6549c67e1f0b9e1a136f2d22496119deb';scope=read(scopep,scopes)
rootp=R+'integration45/ground_exact8_preparation_approval_READY.json';roots='53150c2d09c80ca4ba3388e7392f4710acc0a94989c5f568de97ee0de41c5487';root=read(rootp,roots)
backp=R+'integration45/old_full_backups_READY.json';backs='e488247289964b59af23f794c90946054b51ce452c498900e27e5c4700419aef';back=read(backp,backs)
beforep=R+'integration45/guard_before.json';befores='c168a30baf8a4d9435468e276810f6220d445864813bdecfb795e065b3d2e355'
proofp=Y+'market_ground_finite_count_candidate_epoch01/authorproof_and_wholebyte_inverse_READY_NOT_RUNTIME.json';proofs='2cb284c359ece3eff07efe379d02a1ea7f88fa6f1e717896b821b184eb20d00d';proof=read(proofp,proofs)
ground=proof['parent']['path'];groundold=proof['parent']['sha256'].lower();groundnew=proof['candidate']['sha256'].lower()
allow={r['target']:r['old_sha256']for r in scope['targets']};assert back['target_count']==len(allow)==8
assert {'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r['sha256']for r in back['targets']}==allow
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,v,s):pins[i]={'id':i,'path':v,'sha256':s.lower()}
for i,v,s in [('ground8_scope',scopep,scopes),('ground8_root',rootp,roots),('ground8_backups',backp,backs),('ground8_before',beforep,befores),('ground8_authorproof',proofp,proofs),('ground8_prior_stage',stagep,stages),('ground8_prior_owner',ownerp,owners),('ground8_candidate',proof['candidate']['path'],groundnew)]:pin(i,v,s)
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    row=stage['nodes'][n['id']];raw=fixed(row['path'],row['sha256']);value=None
    if row.get('value')is not None:value=json.loads(raw)
    cur[n['id']]={**row,'bytes':raw,'parsed':value}
refs={n['target']:{'$sha':n['id']}for n in old['nodes']if n.get('target')in allow};refs[ground]={'$pin':'ground8_candidate'}
nodes=[{'id':'ground_code','kind':'ground8_code','base_input':'ground8_candidate','target':ground,'old_sha256':groundold}];frozen={}
for original in old['nodes']:
    n=copy.deepcopy(original);ident=n['id']
    if n['kind']=='map':
        if n['scene_id']=='ch4_s3_luoyang_market':
            n['operations'].append({'op':'set','pointer':['source_sha256',ground],'existed':True,'old':groundold,'new':{'$pin':'ground8_candidate'}})
        nodes.append(n);continue
    v=cur[ident];base='ground8_parent_'+ident;pin(base,v['path'],v['sha256'])
    if n.get('target')not in allow:
        frozen[ident]=v['sha256'];nodes.append({'id':ident,'kind':'ground8_frozen','base_input':base,'immutable_sha256':v['sha256'],'is_json':v['parsed']is not None});continue
    n['base_input']=base;n['old_sha256']=v['sha256'];assert allow[n['target']]==v['sha256']
    if n['kind']=='index':
        for rep in n['replacements']:
            x=rep['new']
            if isinstance(x,dict)and '$sha'in x:
                rep['old']=cur[x['$sha']]['sha256'];assert v['bytes'].count(rep['old'].encode())==1
        nodes.append(n);continue
    assert n['kind']=='metadata'and ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']
    n['operations']=[]
    fields=n['source_bundle']['fields']if'source_bundle'in n else[f['pointer']for f in n.get('source_fields',[])]
    assert fields
    for ks in fields:
        for path,new in refs.items():
            if path in ptr(v['parsed'],ks):n['operations'].append({'op':'set','pointer':ks+[path],'existed':True,'old':ptr(v['parsed'],ks)[path],'new':new})
    assert any(op['pointer'][-1]==ground for op in n['operations']);nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit'and ground in group['leaves']:
        assert group['leaves'][ground]==groundold;group['leaves'][ground]={'$pin':'ground8_candidate'}
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=groups,root_target_allowlist=list(allow),pass_through_targets=[],prospective_targets=[],output_root=S+'outputs/root_market_ground_exact8_stage01/',source_baseline='Fixed464BA current metadata/E717 complete independent source maps. Only ground02A4->C1EF exact existing nonowned source leaf and existing4metadata/3index header cascade. Original36 and strict finite35 source bound; unchanged execution647949/95pins/native/Root39SOURCE_ONLY2/registry/Estate triple.')
spec['B_only_contract']={'scope_input':'ground8_scope','admission_input':'ground8_root','backup_input':'ground8_backups','before_input':'ground8_before','proof_input':'ground8_authorproof','candidate_input':'ground8_candidate','parent_stage_input':'ground8_prior_stage','prior_owner_input':'ground8_prior_owner'}
for gate in spec['required_gates']:
    if gate['id']=='root_target_scope':raise AssertionError('UNEXPECTED_SCOPE_GATE_ID')
    if gate['input']=='repair30_backups':gate['input']='ground8_backups';gate['pointer']=['target_count'];gate['equals']=8
assert any(g['input']=='ground8_backups'for g in spec['required_gates'])
source=oldtool.decode();header=source[:source.index('FIXED_AUTHORITY=')]
header=header[:header.index('"""')]+ '"""Exact8 ground finite35 source compiler; Root-only future Stage, never deployment."""\n'+header[header.index('import argparse'):]
header+="FIXED_AUTHORITY='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'\nFROZEN="+repr(frozen)+'\nGROUND='+repr(ground)+'\nOLD_GROUND='+repr(groundold)+'\nNEW_GROUND='+repr(groundnew)+'\n'
body='''class GroundSourceStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_GROUND_EXACT8')
        super().__init__(spec);c=spec['B_only_contract'];request=self.read_json_input(c['scope_input']);root=self.read_json_input(c['admission_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='ceaab710ea5aba573cb892e06acd21c6549c67e1f0b9e1a136f2d22496119deb' and self.inputs[c['admission_input']]['sha256']=='53150c2d09c80ca4ba3388e7392f4710acc0a94989c5f568de97ee0de41c5487' and root.get('status')=='ROOT_EXACT8_GROUND_FINITE35_PREPARATION_APPROVED_NOT_STAGE_OR_DEPLOYMENT','EXACT_ROOT_GROUND_PREPARATION')
        need(self.inputs[c['backup_input']]['sha256']==root['old_full_backups_sha256']=='e488247289964b59af23f794c90946054b51ce452c498900e27e5c4700419aef' and self.inputs[c['before_input']]['sha256']==root['before_sha256']=='c168a30baf8a4d9435468e276810f6220d445864813bdecfb795e065b3d2e355' and backups['target_count']==8 and root['scope_sha256']==self.inputs[c['scope_input']]['sha256'],'EXACT8_BACKUPS_AND_ROOT45_FRESH')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==8 and list(self.oldtargets)==spec['root_target_allowlist'],'EXACT8_ORDERED_TARGETS')
        backed={}
        for r in backups['targets']:
            target=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'EXACT_BACKUP_GAME_PATHS')
            path='res://'+target.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'COMPLETE_EIGHT_OLD_BYTE_BACKUPS')
        need(backed==self.oldtargets and self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and len(self.authority['owned'])==10 and len(self.authority['source_sha256'])==95 and GROUND not in self.authority['owned'] and GROUND not in self.authority['source_sha256'] and not spec['pass_through_targets'] and not spec['prospective_targets'],'UNCHANGED647949_OWNED10_PROOF95_GROUND_NONOWNED')
        stage=self.read_json_input(c['parent_stage_input']);self.owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['parent_stage_input']]['sha256']=='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f' and self.inputs[c['prior_owner_input']]['sha256']=='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03','FIXED464BA_E717_NOT_CURRENT_FILL')
        prior={r['target']:r['candidate_sha256']for r in stage['targets']};prior[GROUND]=next(r for r in self.owner['scenes']if r['id']=='ch4_s3_luoyang_market')['source_sha256'][GROUND]
        need(all(prior.get(path)==s for path,s in self.oldtargets.items()) and prior[GROUND]==OLD_GROUND,'EXACT8_OLD_FROM_FIXED_PRIOR_DECLARATIONS')
        self.authorproof=self.read_json_input(c['proof_input']);need(self.inputs[c['proof_input']]['sha256']==root['authorproof_sha256']=='2cb284c359ece3eff07efe379d02a1ea7f88fa6f1e717896b821b184eb20d00d' and self.inputs[c['candidate_input']]['sha256']==root['ground_candidate_sha256']==NEW_GROUND and self.authorproof['parent']['path']==GROUND and self.authorproof['parent']['sha256'].lower()==OLD_GROUND and self.authorproof['candidate']['sha256'].lower()==NEW_GROUND and self.authorproof['wholebyte_inverse'] is True,'EXACT_GROUND_TWO_HUNK_CANDIDATE_AND_ROOT_PIN')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT8_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='ground8_code':
            need(row['id']=='ground_code' and row['target']==GROUND and row['old_sha256']==OLD_GROUND,'EXACT_NONOWNED_GROUND_ONLY')
            raw=self.input_bytes[row['base_input']];before=self.read(GROUND,OLD_GROUND);hunks=self.authorproof['hunks'];need(len(hunks)==2 and sha(raw)==NEW_GROUND,'EXACT_TWO_GROUND_HUNKS')
            insertion=hunks[0]['new'].encode();anchor=b'static func prepare(';need(before.count(anchor)==1 and insertion and raw.count(insertion)==1,'GROUND_INSERTION_UNIQUE')
            forward=before.replace(anchor,insertion+anchor,1);old=hunks[1]['old'].encode();new=hunks[1]['new'].encode();need(forward.count(old)==1 and raw.count(new)==1,'GROUND_COUNT_CONDITION_UNIQUE')
            need(forward.replace(old,new,1)==raw and raw.replace(new,old,1).replace(insertion,b'',1)==before and b'\\r'not in raw and raw.endswith(b'\\n'),'WHOLE_GROUND_BYTE_FORWARD_INVERSE_STRICT_LF')
            path=self.inputs[row['base_input']]['path'];self.nodes[row['id']]={'path':path,'sha256':sha(raw),'value':None};self.proofs[row['id']]={'whole_byte_forward_inverse':True,'nonowned_no_execution_change':True};self.target(GROUND,OLD_GROUND,path,sha(raw));return
        if row['kind']=='ground8_frozen':
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
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse'] is True,'ONLY_GROUND_AND_EXISTING_DECLARED_HEADER_VALUE_SUCCESSION')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:need(expected[path]==target['old_sha256'],'FIXED_E717_OLD_VALUE');expected[path]=target['candidate_sha256']
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_FULL_FIXED_E717_MAPS_EXACT8_VALUES_KEYS_COUNTS_UNCHANGED')
'''
run=source[source.index('    def run(self):'):source.index('\ndef main():')]
for a,b in [('len(self.targets)==3','len(self.targets)==8'),('len(copies)==2','len(copies)==4'),('len(reconstruction)==3','len(reconstruction)==8'),("endswith('.gd')])==1","endswith('.gd')])==4"),("'target_count':2","'target_count':4"),("'patch_count':1,'copy_count':2,'total':3","'patch_count':4,'copy_count':4,'total':8"),("'targets':3,'map_nodes':4","'targets':8,'map_nodes':4"),('EXACT3','EXACT8'),('PATCH1_COPY2','PATCH4_COPY4'),('UNION3','UNION8'),('EXACT2_GENERATED','EXACT4_GENERATED')]:run=run.replace(a,b)
main=source[source.index('\ndef main():'):].replace('MarketSourceTupleStage(spec)','GroundSourceStage(spec)')
nt=S+'stage_performance62_ground8_READY.py';tool=(header+body+run+main).encode();ast.parse(tool);spec['required_generator']={'path':nt,'sha256':sha(tool)}
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
    if r['id'].startswith('ground8_'):fixed(r['path'],r['sha256'])
assert {n['target']for n in nodes if'target'in n}==set(allow)and len(allow)==8
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
forward=oldtool;reverse=tool
for h in reversed(hunks):forward=forward[:h['old_start']]+h['new'].encode()+forward[h['old_end']:];reverse=reverse[:h['new_start']]+h['old'].encode()+reverse[h['new_end']:]
assert forward==tool and reverse==oldtool
diff=''.join(difflib.unified_diff(aa,bb,fromfile=tp,tofile=nt)).encode();ib=js(spec);np=O+'source_input_ROOT_LOCKED.json'
proofout={'status':'ROOT45_EXACT8_GROUND_DRIVER_BYTE_INPUT_TYPED_INVERSE_NOT_STAGED','parent_driver':{'path':tp,'sha256':ts},'whole_driver_byte_forward_inverse':True,'driver_hunks':hunks,'parent_input':{'path':ip,'sha256':iss},'whole_input_typed_serialized_inverse':True,'input_deltas':deltas,'unchanged8DE0_core':True,'frozen_other_nodes':frozen,'source_groups_same_except_possible_declared_ground_leaf':True,'ground_nonowned_execution647949_and95pins_frozen':True,'no_new_runtime_source_keys':True,'only8targets_4GD_4JSON':True,'engine_Stage_collector_formal_calls':0};pb=js(proofout)
handoff={'status':'ROOT45_GROUND_EXACT8_READY_NOT_STAGED','driver':{'path':nt,'sha256':sha(tool)},'input':{'path':np,'sha256':sha(ib)},'driver_complete_diff':{'path':O+'driver_complete_vs51.diff','sha256':sha(diff)},'whole_inverse':{'path':O+'driver_input_whole_inverse_READY.json','sha256':sha(pb)},'target_count':8,'GD':4,'JSON':4,'Root_only_NOT_EXECUTED_command':'python '+str(p(nt))+' '+str(p(np))+' --input-sha256 '+sha(ib)}
files={nt:tool,np:ib,O+'driver_complete_vs51.diff':diff,O+'driver_input_whole_inverse_READY.json':pb,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(nt).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
