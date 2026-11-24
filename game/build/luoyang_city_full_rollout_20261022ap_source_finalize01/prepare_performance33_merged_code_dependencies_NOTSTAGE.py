"""NEW AP14 merged semantic/literal candidates and execution proposal only."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance33_merged_code_dependencies/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def apply(raw,hunks):
    forward=raw
    for h in hunks:
        a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1;forward=forward.replace(a,b,1)
    reverse=forward
    # Runtime execution authority applies inverse hunks in LISTED order.
    for h in hunks:
        a,b=h['old'].encode(),h['new'].encode();assert reverse.count(b)==1;reverse=reverse.replace(b,a,1)
    assert reverse==raw
    return forward
def literal(old,new):return {'old':old,'new':new}
def ref(path,s):return {'path':path,'sha256':s}
execp=S+'performance24_canonical_B_dependencies/execution_successor_PROPOSAL.json';execs='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'
execbytes=fixed(execp,execs);parent=json.loads(execbytes)
assert len(parent['owned'])==10 and len(parent['source_sha256'])==71
scopep=S+'performance32_merged_dependencies/exact29_existing_scope_PROPOSAL_NOT_APPROVED.json';scopes='c431b9725252268cffbe9fead091bc0230e491b85dfbcddd912bc21983983c4f'
scope=json.loads(fixed(scopep,scopes));scope_rows={r['target']:r for r in scope['targets']}
ap=S+'finite_adapter_production08/finite_adapter_READY.gd';oldas='999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90'
newap=S+'performance30_domain_parent_copy_candidate01/finite_adapter_domain_copies_CANDIDATE.gd';newas='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84'
baseproof=json.loads(fixed(S+'performance30_domain_parent_copy_candidate01/whole_byte_inverse_and_test_handoff_NOT_RUN.json','a4fd1e8b716c28a90d203c4a0c6a61df6d2e0fd822742599c82f7adec49f4d63'))
oldadapter=fixed(ap,oldas);newadapter=fixed(newap,newas);assert apply(oldadapter,baseproof['hunks']['adapter'])==newadapter
records={};files={}
def add(name,target,oldpath,olds,candidate_path,hunks,expected_bytes=None):
    old=fixed(oldpath,olds);new=apply(old,hunks)
    if expected_bytes is not None:assert new==expected_bytes
    assert scope_rows[target]['old_sha256']==olds
    records[name]={'target':target,'parent':ref(oldpath,olds),'candidate':ref(candidate_path,sha(new)),'hunks':hunks,'whole_forward_inverse_listed_order':True}
    if candidate_path.startswith(O):files[candidate_path.removeprefix(O)]=new
    files[name+'_complete.diff']=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile=oldpath,tofile=candidate_path)).encode()
    return new
add('adapter',ap,ap,oldas,newap,baseproof['hunks']['adapter'],newadapter)
g='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
gp='res://build/luoyang_city_full_rollout_20261022ap_system01/room_known_membership_candidate_epoch01/G_membership_CANDIDATE.gd';gs='0ef50da8075616341d0967e071767e3bbf6db297a6baa1c8788aa0fdb29e8b08'
gproof=json.loads(fixed('res://build/luoyang_city_full_rollout_20261022ap_system01/room_known_membership_candidate_epoch01/inverse_and_scope_NOT_RUNTIME_READY.json','3b496d1fe897f8b7ca659e56d89fed6661389eef634a18ab4e5c9f0da2475d1a'))
add('G',g,scope_rows[g]['old_snapshot'],scope_rows[g]['old_sha256'],gp,[literal(gproof['old_exact'],gproof['new_exact'])],fixed(gp,gs))
for name,target in [('C','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'),('DT','res://scripts/city/luoyang_district_life_20261016f.gd'),('Fade','res://scripts/city/luoyang_district_life_fade_20261016f.gd')]:
    row=scope_rows[target]
    add(name,target,row['old_snapshot'],row['old_sha256'],O+name+'_adapter_pin_CANDIDATE.gd',[literal('const FINITE_ADAPTER_SHA := "'+oldas+'"','const FINITE_ADAPTER_SHA := "'+newas+'"')])
oldC=records['C']['parent']['sha256'];newC=records['C']['candidate']['sha256']
bindp=S+'performance05_dependencies/temple_binding_READY.json';binds='e43b17610adf1601d5b10a2a441421432842d92162178a2c8f2b4d019407b375'
oldbind=fixed(bindp,binds);newbind=apply(oldbind,[literal(oldC,newC)])
oldbindobj=json.loads(oldbind);newbindobj=json.loads(newbind)
Ctarget=records['C']['target'];assert oldbindobj['source_delta'][Ctarget]==oldC
inv=copy.deepcopy(newbindobj);inv['source_delta'][Ctarget]=oldC;assert same(inv,oldbindobj)
parentbind=json.loads(p(oldbindobj['parent_binding_path']).read_bytes())
assert sha(p(oldbindobj['parent_binding_path']).read_bytes())==oldbindobj['parent_binding_sha256']
merged=copy.deepcopy(parentbind['source_sha256']);merged.update(oldbindobj['source_delta'])
mergednew=copy.deepcopy(parentbind['source_sha256']);mergednew.update(newbindobj['source_delta'])
assert len(merged)==len(mergednew)==189 and [k for k in merged if merged[k]!=mergednew[k]]==[Ctarget]
newbindp=O+'temple_binding_C_literal_READY.json';files['temple_binding_C_literal_READY.json']=newbind
records['temple_binding']={'parent':ref(bindp,binds),'candidate':ref(newbindp,sha(newbind)),'hunks':[literal(oldC,newC)],'whole_forward_inverse_listed_order':True,'whole_typed_source_delta_inverse':True,'merged_sources':189,'only_C_changed_other188_same':True,'original_E43B_EOL_all_preserved':True}
files['temple_binding_complete.diff']=''.join(difflib.unified_diff(oldbind.decode().splitlines(True),newbind.decode().splitlines(True),fromfile=bindp,tofile=newbindp)).encode()
t='res://scripts/city/luoyang_temple_assembly_20261016.gd';tr=scope_rows[t]
add('Temple',t,tr['old_snapshot'],tr['old_sha256'],O+'Temple_C_binding_CANDIDATE.gd',[
 literal('const BIND_PATH="'+bindp+'"','const BIND_PATH="'+newbindp+'"'),literal('const BIND_SHA="'+binds+'"','const BIND_SHA="'+sha(newbind)+'"')])
b='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd';br=scope_rows[b]
fadeold=records['Fade']['parent']['sha256'];fadenew=records['Fade']['candidate']['sha256'];fadepath=records['Fade']['candidate']['path']
bh=copy.deepcopy(baseproof['hunks']['B'])+[
 literal('const FINITE_ADAPTER_SHA := "'+oldas+'"','const FINITE_ADAPTER_SHA := "'+newas+'"'),
 literal('\tvar next: String="'+fadeold+'"\n\tvar candidate: String="'+S+'finite_adapter_production08/Fade_consumer_READY.gd"',
         '\tvar finite_previous: String="'+fadeold+'"\n\tvar next: String="'+fadenew+'"\n\tvar candidate: String="'+fadepath+'"'),
 literal('and previous in history and delta.get("current_before_sha256")==previous and delta.get("new_sha256")==next',
         'and previous in history and finite_previous in history and delta.get("current_before_sha256")==finite_previous and delta.get("new_sha256")==next')]
add('B',b,br['old_snapshot'],br['old_sha256'],O+'Bundle_merged_copy_adapter_fade_CANDIDATE.gd',bh)
proofpath=O+'whole_code_and_binding_inverse_READY.json'
proof={'status':'AP14_MERGED_COMPONENT_AND_NECESSARY_LITERAL_WHOLE_INVERSES_NOT_SOURCE_STAGE_OR_DEPLOYMENT',
 'records':records,'all_source_bytes_forward_and_reverse_proven':True,'new_functional_scope_only':'G cached membership, adapter exact-domain two independent copies, B finite initial-child deferral. Other changes are required source/binding literals or exact Fade historical-source chain succession.',
 'fade_metadata_recipe':{'path':records['Fade']['target'],'historical_sha256':['f359a43a88470ff220fa095cbd7f73ea04637c55c2faadd0a3b5f325e4b7a244','bc2958cc8f9a60ac9952891c30037441a62e289d8fee2fa235e6b864abf3a1bf','3f2d43276f89341a450579fa07a0dd0bb2369d059ad928e7187fb35df59f1ac7',fadeold],'current_before_sha256':fadeold,'new_sha256':fadenew,'candidate_path':fadepath,'all_other_existing_row_fields_preserved':True},
 'adapter_binding_DC21_unchanged':True,'Temple_merged189_only_C_changed':True,
 'no_geometry_receipt_NAV_NPC_quest_FIRST_FINAL_validation_changes':True,'engine_collector_Stage_formal_calls':0}
proofbytes=js(proof);files['whole_code_and_binding_inverse_READY.json']=proofbytes
proposal=copy.deepcopy(parent);edges=[]
for name in ['B','G','DT','Temple']:
    r=records[name];target=r['target'];assert proposal['owned'][target]['current_sha256']==r['parent']['sha256']
    edge={'path':target,'old_sha256':r['parent']['sha256'],'new_sha256':r['candidate']['sha256'],'old_snapshot':r['parent']['path'],'new_snapshot':r['candidate']['path'],'whole_inverse':True,'replacements':copy.deepcopy(r['hunks'])}
    proposal['owned'][target]['current_sha256']=r['candidate']['sha256'];proposal['owned'][target]['edges'].append(edge);edges.append(edge)
newpins={r['candidate']['path']:r['candidate']['sha256']for r in records.values()};newpins[proofpath]=sha(proofbytes)
assert len(newpins)==9 and not(set(newpins)&set(parent['source_sha256']))
proposal['source_sha256'].update(newpins)
inverse=copy.deepcopy(proposal)
for edge in edges:inverse['owned'][edge['path']]=copy.deepcopy(parent['owned'][edge['path']])
for path in newpins:inverse['source_sha256'].pop(path)
assert same(inverse,parent) and js(inverse)==execbytes
assert len(proposal['source_sha256'])==80 and len(proposal['owned'])==10
ep=O+'execution_successor_PROPOSAL.json';eb=js(proposal);files['execution_successor_PROPOSAL.json']=eb
hand={'status':'MERGED_AP14_EXACT29_CODE_AND_EXECUTION_PROPOSAL_NOT_ROOT_AUTHORIZED_NOT_STAGED',
 'execution_parent':ref(execp,execs),'execution_proposal':ref(ep,sha(eb)),'original_owned_members':10,'owned_changed_exactly4':[e['path']for e in edges],'other_owned_rows_whole_unchanged':6,
 'old_proof_pins':71,'new_proof_pins':80,'new_proof_sources_exact9':newpins,
 'whole_execution_strict_typed_and_UTF8_serialized_byte_inverse':True,'all_owned_prior_edges_and_old71pins_preserved':True,
 'whole_inverse_proof':ref(proofpath,sha(proofbytes)),'scope_request':ref(scopep,scopes),
 'actual_parent_stage':scope['parent_actual_stage'],'fixed_independent_owner':scope['fixed_independent_owner'],'Root29_fresh_before':scope['Root29_fresh_before'],
 'metadata_not_yet_generated':'Root must approve exact29 and execution proposal before NEW thin driver/input. Registry fiveDT source values, four Fade migration rows, C binding and all required explicit source/header differences must form one DAG; no individual component Stage.',
 'single_Stage_partition_proposal':{'existing_targets':29,'GD_apply_patch':15,'generated_JSON_exactcopy':14},
 'unchanged':'OWNED members/authority code, Family/ENV/Field/Router/Coordinator/runtime_contract/hash/adapter binding/native/navigation/NPC/quests/fullFIRSTFINAL',
 'diffs':{n:ref(O+n,sha(raw))for n,raw in files.items()if n.endswith('.diff')},
 'engine_packet_decode_collector_sourceStage_formal_calls':0}
files['handoff_EXECUTION_AND_SCOPE_PROPOSAL.json']=js(hand)
assert not p(O).exists();p(O).mkdir()
for name,raw in files.items():(p(O)/name).write_bytes(raw)
print(json.dumps({name:sha(raw)for name,raw in files.items()},indent=2))
