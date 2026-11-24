"""Mechanical one-ENV successor package. Does not import or execute any Stage."""
from pathlib import Path
import json,hashlib,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/';R='res://build/luoyang_city_revision_20261024b_root01/';P='res://build/luoyang_market_use_20261024b_system01/texture_union_fix01/'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h,(p,sha(b));assert b'tokens truncated' not in b;return b
def load(p,h=None):return json.loads(read(p,h))
def out(name,b):
    if (HERE/name).exists():assert (HERE/name).read_bytes()==b
    else:
        with (HERE/name).open('xb') as f:f.write(b)
    assert (HERE/name).read_bytes()==b
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
oldpath=S+'source_input_C_packed27_ROOT_READY.json';oldhash='c76126cf140b045ce14257a67652f1aa9bf3a53623a2fb8dc2fae3d3975efab6';old=load(oldpath,oldhash)
parentpath=S+'outputs/root_C_packed_exact27_stage01/receipt.json';parenthash='91a1e5d25a596436066f508a6ac13cc4518125a88a1c271aae8061e5024423ed';parent=load(parentpath,parenthash)
scopepath=S+'ENV_texture_union18_scope_PREPARATION_NOT_STAGE.json';scopehash='74f89e2b2cf2dadbb34f7070a1f3dcddff82bc9381fa2307f421fc0e6f9fa46d';scope=load(scopepath,scopehash);targets={r['target']:r['old_sha256'] for r in scope['targets']}
proofpath=P+'whole_byte_inverse_and_five_group_static_READY.json';proofhash='ae7d840b1a743c7ed49f2d5993b5e1fd39b24c766f3459dcfb60bd6ebadc59b1';proof=load(proofpath,proofhash)
approvalpath=R+'env18_preparation_approval.json';approvalhash='92cefb4b50eaef39cab784d3adf0eb35e2497fde598db47a72d1e6878d69bfdc';approval=load(approvalpath,approvalhash)
# Exact edits to the already-executed27 driver. Original8DE0 remains untouched.
driverpath=S+'stage_C_packed27_NOTREADY.py';driverhash='a1cd66653b73032d0d92369864b1fbd6af74c270dd75f053dee57209dee7b507';before=read(driverpath,driverhash).decode();driver=before;edits=[]
def change(a,b):
    global driver
    assert driver.count(a)==1,(a[:100],driver.count(a));offset=len(driver[:driver.index(a)].encode());driver=driver.replace(a,b,1);edits.append(dict(byte_offset_at_step=offset,old=a,new=b))
start=driver.index("        self.proof = self.read_json_input(c['code_inverse_input'])")
end=driver.index("        self.parent_stage =",start)
change(driver[start:end],'''        proof = self.read_json_input(c['code_inverse_input'])
        p = 'res://scripts/city/luoyang_environment_layer_20261022ap.gd'
        before = self.read(p, self.oldtargets[p])
        after = self.read(proof['candidate']['path'], proof['candidate']['sha256'])
        forward, inverse = before.decode('utf8'), after.decode('utf8')
        for h in proof['replacements']:
            need(forward.count(h['old']) == inverse.count(h['new']) == 1, 'UNIQUE_ENV_WHOLEBYTE_HUNK')
            forward = forward.replace(h['old'], h['new'], 1)
            inverse = inverse.replace(h['new'], h['old'], 1)
        need(forward.encode('utf8') == after and inverse.encode('utf8') == before
             and proof['parent']['sha256'] == self.oldtargets[p], 'ENV_FULL_FORWARD_AND_INVERSE')
        self.codes = {p:dict(candidate=proof['candidate'])}
        need(len(self.authority['owned']) == 10 and len(self.authority['source_sha256']) == 132
             and self.read(EXEC, self.inputs[spec['authority_input']]['sha256']) == self.input_bytes[spec['authority_input']], 'EXECUTION_10_MEMBERS132_PROOFS_ENTIRE_BYTES_UNCHANGED')
''')
for a,b in [
    ("len(self.oldtargets) == 27","len(self.oldtargets) == 18"),
    ("sum(p.endswith('.gd') for p in self.oldtargets) == 13","sum(p.endswith('.gd') for p in self.oldtargets) == 7"),
    ("backup['count'] == len(backup['records']) == 27","backup['count'] == len(backup['records']) == 18"),
    ("        expected[EXEC] = {k:self.inputs[self.spec['authority_input']][k] for k in ['path','sha256']}\n",''),
    ("len(expected) == len(self.spec['pass_through_targets']) == 6","len(expected) == len(self.spec['pass_through_targets']) == 1"),
    ("len(self.targets) == 27","len(self.targets) == 18"),
    ("len(copies) == 14 and len(reconstruction) == 27","len(copies) == 11 and len(reconstruction) == 18"),
    ("target_count=14","target_count=11"),
    ("dict(patch_count=13,copy_count=14,total=27)","dict(patch_count=7,copy_count=11,total=18)"),
    ("targets=27,map_nodes=4","targets=18,map_nodes=4"),
    ("status='MARKET_DIALOGUE_EXACT27_STAGED_NOT_DEPLOYED'","status='ENV_TEXTURE_UNION_EXACT18_STAGED_NOT_DEPLOYED'"),
    ("            need(same(expected, self.nodes[ident]['value']['source_sha256']), 'INDEPENDENT_FORMAL805791_PLUS_EXACT27_DECLARATIONS')","            need(same(expected, self.nodes[ident]['value']['source_sha256']) and set(expected) == set(self.parent_stage['nodes'][ident]['value']['source_sha256']), 'INDEPENDENT_FORMAL91A1_PLUS_EXACT18_SAME_KEYS')")]:change(a,b)
inverse=driver.encode()
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert inverse[i:i+len(b)]==b;inverse=inverse[:i]+a+inverse[i+len(b):]
assert inverse==before.encode()
forward=before
for e in edits:assert forward.count(e['old'])==1;forward=forward.replace(e['old'],e['new'],1)
assert forward==driver
compile(driver,'stage_ENV_texture_union18_ROOT_READY.py','exec')
dr=out('stage_ENV_texture_union18_ROOT_READY.py',driver.encode())
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h);return {'$pin':i}
pin('space_scope',scopepath,scopehash);pin('space_parent_stage',parentpath,parenthash);pin('space_Root_backup',R+'env_predeploy18/backup_receipt.json','bc416091290df1d84d471736f8cbf7f9b7cc6cda154dba2e5e84a4831ca49f1e');pin('space_Root_preparation',approvalpath,approvalhash);pin('space_code_inverse',proofpath,proofhash)
envref=pin('ENV_union_candidate',proof['candidate']['path'],proof['candidate']['sha256'])
refs={ENV:envref}
for n in old['nodes']:
    if n.get('target') in targets:refs[n['target']]={'$sha':n['id']}
groups=copy.deepcopy(old['source_groups'])
for g in groups:
    if g['kind']=='explicit':
        for p in g['leaves']:
            if p in refs:g['leaves'][p]=copy.deepcopy(refs[p])
authority=load(pins[old['authority_input']]['path'],pins[old['authority_input']]['sha256'])
assert len(authority['owned'])==10 and len(authority['source_sha256'])==132
def at(v,ks):
    for k in ks:v=v[k]
    return v
def op(ks,a,b,ex=True):return dict(op='set',pointer=ks,existed=ex,old=copy.deepcopy(a),new=copy.deepcopy(b))
nodes=[];oldptr=0
for original in old['nodes']:
    n=copy.deepcopy(original);ident,kind=n['id'],n['kind']
    if kind=='map':
        wanted=parent['nodes'][ident]['value']['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256'];promoted=copy.deepcopy(seed)
        for p in promoted:
            if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
        n['operations']=[op(['source_sha256',p],promoted.get(p),refs.get(p,h),p in promoted) for p,h in wanted.items() if p not in promoted or p in refs or promoted[p]!=h]
        n['operations'] += [dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None) for p in set(promoted)-set(wanted)]
        n['declared_new_groups']=[];nodes.append(n);continue
    if n.get('target') not in targets:
        r=parent['nodes'][ident];i='ENV18_frozen_'+ident;pin(i,r['path'],r['sha256'])
        nodes.append(dict(id=ident,kind='space_frozen',base_input=i,immutable_sha256=r['sha256'],is_json=r.get('value') is not None));continue
    r=parent['nodes'][ident];i='ENV18_parent_'+ident;pin(i,r['path'],r['sha256']);n['base_input']=i;n['old_sha256']=r['sha256'];assert r['sha256']==targets[n['target']]
    if kind=='index':
        n['replacements']=[dict(old=parent['nodes'][h['new']['$sha']]['sha256'],new=h['new']) for h in n['replacements'] if isinstance(h['new'],dict) and h['new'].get('$sha') in {x['id'] for x in old['nodes'] if x.get('target') in targets}]
        assert n['replacements'];nodes.append(n);continue
    assert kind=='metadata'
    base=r['value'];fields=n.get('source_bundle',{}).get('fields',[])+[f['pointer'] for f in n.get('source_fields',[])]
    n['operations']=[op(ks+[p],h,refs[p]) for ks in fields for p,h in at(base,ks).items() if p in refs]
    oldptr+=len(n['operations']);assert n['operations'];nodes.append(n)
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=groups,root_target_allowlist=list(targets),pass_through_targets=[dict(target=ENV,old_sha256=targets[ENV],candidate_path=proof['candidate']['path'],candidate_sha256=proof['candidate']['sha256'])],prospective_targets=[dict(target=ENV,candidate_path=proof['candidate']['path'],sha256=proof['candidate']['sha256'])],output_root=S+'outputs/root_ENV_texture_union_exact18_stage01/',required_generator=dict(path=dr['path'],sha256=dr['sha256']),source_baseline='Formal91A1/5609 with exact18 existing source/header successors; sole ENV Market fixed texture used union; no new source keys, owned/execution/native/media/gameplay unchanged')
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate['equals']=18
c=spec['space_contract'];c.update(Root_backup_prefix=R+'env_predeploy18/backups/',expected_Root_preparation_document=approval,root_input_freeze_pending=False,expected_proofs=132)
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec);used.update(['space_scope','space_parent_stage','space_code_inverse','space_Root_backup','space_Root_preparation','space_binding','space_publication','space_temple_binding','space_dialogue_admission'])
spec['pinned_inputs']=[r for k,r in pins.items() if k in used]
assert len(targets)==18 and sum('target' in n for n in nodes)==17
# Static schema, exact old metadata pointers and node/group dependency order.
known=set();gg={g['id']:g for g in groups}
def refscheck(v):
    if isinstance(v,dict):
        if '$sha' in v:assert v['$sha'] in known,v
        if '$pin' in v:assert v['$pin'] in used,v
        for w in v.values():refscheck(w)
    elif isinstance(v,list):
        for w in v:refscheck(w)
def groupcheck(i,stack):
    assert i not in stack;g=gg[i];refscheck(g)
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for j in g['groups']:groupcheck(j,stack+[i])
for n in nodes:
    refscheck(n.get('operations',[]));refscheck(n.get('replacements',[]))
    if n.get('operations') and n['kind']!='map':
        base=parent['nodes'][n['id']]['value']
        for o in n['operations']:assert at(base,o['pointer'])==o['old'] and o['existed']
    for i in n.get('source_bundle',{}).get('groups',[])+n.get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:groupcheck(i,[])
    known.add(n['id'])
inp=out('source_input_ENV_texture_union18_ROOT_READY.json',enc(spec))
pr=out('ENV_texture_union18_offset_inverse_BUILD.json',enc(dict(status='ENV18_MECHANICAL_PACKAGE_NOT_EXECUTED',parent_driver=dict(path=driverpath,sha256=driverhash),driver=dr,driver_edits=edits,driver_full_forward_exact=True,driver_full_byte_inverse_exact=True,input_parent=dict(path=oldpath,sha256=oldhash),input=inp,targets=18,GD=7,JSON=11,old_metadata_pointers=oldptr,pins=len(spec['pinned_inputs']),node_group_order_checked=True,source_keysets_fixed=True,no_Stage_import_or_execution=True)))
print(json.dumps(dict(driver=dr,input=inp,proof=pr,targets=18,pins=len(spec['pinned_inputs']),oldptr=oldptr)))
