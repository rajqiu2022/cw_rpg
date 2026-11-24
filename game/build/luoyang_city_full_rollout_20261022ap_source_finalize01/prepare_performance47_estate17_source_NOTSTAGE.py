"""One NEW metadata-only17 recipe; generates text, never imports/runs Stage."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance47_estate17_source_recipe/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration35/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
tp=S+'stage_performance42_culture24_READY.py';ts='13a460cac31cc565328a887a50200a9672d9e461b4f1164c7978ab7009c32df2';parenttool=fixed(tp,ts)
ip=S+'performance42_culture24_source_recipe/source_input_ROOT_LOCKED.json';iss='decabd917e9a3526c561cdcd0ed3f91e12406696d1a30ae72cad281597b8f277';parentinput=fixed(ip,iss);old=json.loads(parentinput)
stagep=S+'outputs/root_culture_C_source_repair_stage01/receipt.json';stages='5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e';stage=read(stagep,stages)
scopep=S+'performance46_estate_registry_scalar_scope/exact17_existing_scope_PROPOSAL.json';scopes='a7d5fc152a5740a435d6f8314c825862127fffce1635d97bc7fbacf319695b6a';scope=read(scopep,scopes)
rootp=R+'preparation_scope_approval.json';roots='61696f03de75249a8ce133319106b258e3f78d6efbfae1db52095b7fd0605bf2';root=read(rootp,roots)
backp=R+'old_full_backups_READY.json';backs='17fb9dc23ec6236a5eaac7183a3e31983ce2c60d3eed0d49e96f19cec679ee1d';backup=read(backp,backs)
proofp=S+'performance46_estate_registry_scalar_scope/scalar_whole_inverse_READY.json';proofs='9f782008132b157acfd6e33f18c71c70bc6d17cffa3f0491dad0e2efdb83db20';proof=read(proofp,proofs)
allow={r['target']:r['old_sha256']for r in scope['targets']};assert len(allow)==17
assert backup['target_count']==17 and {'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r['sha256']for r in backup['targets']}==allow
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,path,s):pins[i]={'id':i,'path':path,'sha256':s}
for i,path,s in [('estate17_scope_request',scopep,scopes),('estate17_Root_approval',rootp,roots),('estate17_Root_backups',backp,backs),('estate17_scalar_inverse',proofp,proofs),('estate17_scalar_candidate',proof['candidate']['path'],proof['candidate']['sha256']),('estate17_parent_stage',stagep,stages),('estate17_prior_owner',scope['prior_owner']['path'],scope['prior_owner']['sha256'])]:pin(i,path,s)
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    r=stage['nodes'][n['id']];b=fixed(r['path'],r['sha256']);cur[n['id']]={**r,'bytes':b,'value':json.loads(b)if n['kind']not in ['index']and n['id']!='ap_environment_index'else None}
refs={n['target']:{'$sha':n['id']}for n in old['nodes']if n.get('target')in allow}
nodes=[];frozen={}
for original in old['nodes']:
    n=copy.deepcopy(original);ident=n['id']
    if n['kind']=='map':nodes.append(n);continue
    v=cur[ident];base='estate17_parent_'+ident;pin(base,v['path'],v['sha256'])
    if n.get('target')not in allow:
        frozen[ident]=v['sha256'];nodes.append({'id':ident,'kind':'estate17_frozen','base_input':base,'immutable_sha256':v['sha256'],'is_json':v['value']is not None});continue
    n['base_input']=base;n['old_sha256']=v['sha256'];assert allow[n['target']]==v['sha256']
    if n['kind']=='index':
        for rep in n['replacements']:
            x=rep['new']
            if isinstance(x,dict)and '$sha'in x:rep['old']=cur[x['$sha']]['sha256'];assert v['bytes'].count(rep['old'].encode())==1
        nodes.append(n);continue
    assert n['kind']=='metadata'
    fields=[f['pointer']for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[])
    n['operations']=[]
    for ks in fields:
        table=ptr(v['value'],ks)
        for path,x in refs.items():
            if path in table:n['operations'].append({'op':'set','pointer':ks+[path],'existed':True,'old':table[path],'new':x})
    if ident=='estate_final':n['operations'].insert(0,copy.deepcopy(proof['operation']))
    nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
# Existing symbolic header refs already name these exact nodes. Reassert the17
# current successor refs; immutable history remains untouched.
for group in groups:
    if group['kind']=='explicit':
        for path,x in refs.items():
            if path in group['leaves']:group['leaves'][path]=x
nt=S+'stage_performance47_estate17_READY.py'
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=groups,root_target_allowlist=list(allow),pass_through_targets=[],prospective_targets=[],output_root=S+'outputs/root_estate_registry_scalar17_stage01/',source_baseline='Formal AP15 culture-repaired5B455 plus fixed544819 expectations. Only Estate root registry_sha256 aligns with already-declared immutableF529; exact17 metadata/header succession, no execution/code/native change.')
spec['B_only_contract']={'scope_input':'estate17_Root_approval','scope_request_input':'estate17_scope_request','backup_input':'estate17_Root_backups','parent_stage_input':'estate17_parent_stage','prior_owner_input':'estate17_prior_owner','scalar_inverse_input':'estate17_scalar_inverse','scalar_candidate_input':'estate17_scalar_candidate','expected_Root_document':root}
for gate in spec['required_gates']:
    if gate['input']=='B_only_scope':gate['input']='estate17_Root_approval';gate['pointer']=['existing_targets'];gate['equals']=17
header=parenttool.decode().split('class CultureSourceStage')[0]
header=header[:header.index("PARENT='")]+"FIXED_AUTHORITY='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'\nFROZEN="+repr(frozen)+'\n'
constructor='''class EstateScalarStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_ESTATE17_INPUT')
        super().__init__(spec)
        c=spec['B_only_contract'];root=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='61696f03de75249a8ce133319106b258e3f78d6efbfae1db52095b7fd0605bf2' and same(root,c['expected_Root_document']) and root.get('status')=='ROOT_APPROVED_EXACT17_ESTATE_REGISTRY_SCALAR_SUCCESSOR_PREPARATION_ONLY','ROOT_EXACT17_APPROVAL_SCHEMA')
        need(root.get('existing_targets')==17 and root.get('GD_targets')==6 and root.get('JSON_targets')==11 and root.get('fresh_before_sha256')=='fc90fc19342eb7c31228165751674ae1af9206bfb6b12e041281a4b3dfd191f1' and root.get('Stage_execution_authorized') is False and root.get('deployment_authorized') is False and root.get('engine_authorized') is False,'ROOT_PREPARATION_ONLY_NO_BROAD_AUTHORITY')
        need(root.get('scope_sha256')==self.inputs[c['scope_request_input']]['sha256']=='a7d5fc152a5740a435d6f8314c825862127fffce1635d97bc7fbacf319695b6a' and root.get('old_full_backups_sha256')==self.inputs[c['backup_input']]['sha256']=='17fb9dc23ec6236a5eaac7183a3e31983ce2c60d3eed0d49e96f19cec679ee1d','FIXED_SCOPE_AND_BACKUPS')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==17 and list(self.oldtargets)==spec['root_target_allowlist'] and backups.get('target_count')==17 and len(backups['targets'])==17,'EXACT_ORDERED17_TARGETS')
        backed={}
        for r in backups['targets']:
            target_path=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target_path.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'BACKUP_GAME_DOMAIN')
            path='res://'+target_path.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP_TARGET');backed[path]=r['sha256']
            before=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(len(before)==r['bytes'] and before==self.read(path,r['sha256']),'FULL17_OLD_BYTES_BACKED_UP')
        need(backed==self.oldtargets,'BACKUP_SCOPE_EXACT17')
        need(self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and not spec['pass_through_targets'] and not spec['prospective_targets'],'UNCHANGED_EXECUTION_NO_NEW_CODE_OR_EDGES')
        stage=self.read_json_input(c['parent_stage_input']);owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['parent_stage_input']]['sha256']=='5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e' and self.inputs[c['prior_owner_input']]['sha256']=='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0','FIXED_CURRENT_AP15_AND_INDEPENDENT_OWNER')
        prior={r['target']:r['candidate_sha256']for r in stage['targets']};need(all(prior.get(path)==s for path,s in self.oldtargets.items()),'ONLY_FIXED_CURRENT_CANDIDATE_OLD_PINS')
        self.scalar=self.read_json_input(c['scalar_inverse_input']);candidate=self.input_bytes[c['scalar_candidate_input']]
        need(self.inputs[c['scalar_inverse_input']]['sha256']=='9f782008132b157acfd6e33f18c71c70bc6d17cffa3f0491dad0e2efdb83db20' and sha(candidate)==root['scalar_candidate_sha256']=='2410ed000f79c898742106d455f7b79b26fcad7a57acb6d2632e71bc18c521eb','EXACT_SINGLE_SCALAR_CANDIDATE_AND_INVERSE')
        before=self.read(self.scalar['parent']['path'],self.scalar['parent']['sha256']);a,b=self.scalar['operation']['old'],self.scalar['operation']['new'];old=json.loads(before);new=json.loads(candidate)
        need(old['registry_path']=='res://data/maps/luoyang_estate_rooms_20261021am/registry.json' and old['source_sha256'][old['registry_path']]==b,'NEW_SCALAR_FROM_SAME_PARENT_DECLARED_SOURCE_NOT_CURRENT_FILL')
        inverse=copy.deepcopy(new);inverse['registry_sha256']=a;need(same(inverse,old) and encode(inverse)==before and before.replace(('"registry_sha256": "'+a+'"').encode(),('"registry_sha256": "'+b+'"').encode(),1)==candidate,'SCALAR_WHOLE_TYPED_AND_BYTE_INVERSE')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT17_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='estate17_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'ONLY_FIXED_UNCHANGED_NODE')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['id']=='estate_final':
            need(same(row['operations'],[self.scalar['operation']]),'ESTATE_ONLY_ONE_SCALAR_OPERATION')
            value=self.nodes[row['id']];candidate=self.input_bytes[self.spec['B_only_contract']['scalar_candidate_input']]
            need(self.proofs[row['id']].get('whole_typed_inverse') is True and self.outputs[value['path']]==candidate,'ORIGINAL_METADATA_INVERSE_AND_ENCODE_EXACT2410')
'''
source=parenttool.decode();start=source.index('    def run(self):');end=source.index('\ndef main():',start);run=source[start:end]
a=run.index('        exact=');b=run.index("        for row in self.spec['nodes']",a);run=run[:a]+run[b:]
a=run.index("                if row['target']==EXE:");b=run.index("                copies.append(",a)
run=run[:a]+'''                matches=[k for k,v in self.nodes.items() if v['path']==path and v['sha256']==row['candidate_sha256']]
                need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
'''+run[b:]
for a,b in [('len(self.targets)==24','len(self.targets)==17'),('len(copies)==14','len(copies)==11'),('len(reconstruction)==24','len(reconstruction)==17'),("endswith('.gd')])==10","endswith('.gd')])==6"),("'patch_count':10,'copy_count':14,'total':24","'patch_count':6,'copy_count':11,'total':17"),("'target_count':14","'target_count':11"),("'targets':24,'map_nodes':4","'targets':17,'map_nodes':4"),('EXACT24','EXACT17'),('PATCH10_COPY14','PATCH6_COPY11'),('UNION22','UNION17'),('EXACT14_GENERATED','EXACT11_GENERATED')]:run=run.replace(a,b)
main=source[end:].replace('CultureSourceStage(spec)','EstateScalarStage(spec)')
tool=(header+constructor+run+main).encode();ast.parse(tool);spec['required_generator']={'path':nt,'sha256':sha(tool)}
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input']and isinstance(x,str)and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(spec['required_gates']);used.update(spec['B_only_contract'][k]for k in spec['B_only_contract']if k.endswith('_input'))
spec['pinned_inputs']=[r for r in pins.values()if r['id']in used]
assert len({n['target']for n in nodes if'target'in n})==17 and {n['target']for n in nodes if'target'in n}==set(allow)
def changes(a,b,ks=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():return[d for k in a for d in changes(a[k],b[k],ks+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):return[d for i in range(len(a))for d in changes(a[i],b[i],ks+[i])]
    return []if type(a)is type(b)and a==b else[{'pointer':ks,'old':a,'new':b}]
deltas=changes(old,spec);inverse=copy.deepcopy(spec)
for d in reversed(deltas):ptr(inverse,d['pointer'][:-1])[d['pointer'][-1]]=d['old']
assert js(inverse)==parentinput
aa=parenttool.decode().splitlines(True);bb=tool.decode().splitlines(True);hunks=[]
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hunks.append({'old_start':len(''.join(aa[:i]).encode()),'old_end':len(''.join(aa[:j]).encode()),'new_start':len(''.join(bb[:k]).encode()),'new_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
forward=parenttool;reverse=tool
for h in reversed(hunks):forward=forward[:h['old_start']]+h['new'].encode()+forward[h['old_end']:];reverse=reverse[:h['new_start']]+h['old'].encode()+reverse[h['new_end']:]
assert forward==tool and reverse==parenttool
ib=js(spec);np=O+'source_input_ROOT_LOCKED.json';diff=''.join(difflib.unified_diff(aa,bb,fromfile=tp,tofile=nt)).encode()
review={'status':'EXACT17_METADATA_ONLY_DRIVER_BYTE_AND_INPUT_TYPED_SERIALIZED_INVERSE_NOT_STAGED','parent_driver':{'path':tp,'sha256':ts},'driver_hunks':hunks,'whole_driver_forward_reverse':True,'parent_input':{'path':ip,'sha256':iss},'input_deltas':deltas,'whole_input_typed_serialized_inverse':True,'frozen_nodes':frozen,'unchanged_authority_SHA':pins[spec['authority_input']]['sha256'],'original8DE0_unchanged_registry_scalar_allowlist_no_exception':True,'no_new_runtime_code_owned_edge_registry_native_collector':True,'target_count':17,'GD':6,'JSON':11,'Stage_calls':0}
rb=js(review);handoff={'status':'ROOT35_EXACT17_ESTATE_SCALAR_SOURCE_READY_NOT_STAGED','driver':{'path':nt,'sha256':sha(tool)},'input':{'path':np,'sha256':sha(ib)},'complete_driver_diff':{'path':O+'driver_complete_vs42.diff','sha256':sha(diff)},'whole_inverse':{'path':O+'driver_input_whole_inverse_READY.json','sha256':sha(rb)},'target_count':17,'GD':6,'JSON':11,'frozen_owned_authority_registry_and_native':True,'Root_only_NOT_EXECUTED_command':'python '+str(p(nt))+' '+str(p(np))+' --input-sha256 '+sha(ib)}
files={nt:tool,np:ib,O+'driver_complete_vs42.diff':diff,O+'driver_input_whole_inverse_READY.json':rb,O+'handoff_READY_NOT_STAGED.json':js(handoff)}
assert not p(O).exists()and not p(nt).exists()
for path,b in files.items():p(path).parent.mkdir(parents=True,exist_ok=True);p(path).write_bytes(b)
print(json.dumps({path:sha(b)for path,b in files.items()},indent=2))
