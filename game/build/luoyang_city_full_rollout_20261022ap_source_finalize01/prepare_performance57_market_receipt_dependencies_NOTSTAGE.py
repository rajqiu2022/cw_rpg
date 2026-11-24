"""Single exact30 dependency proposal. NEW build artifacts, no Stage."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1];S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance57_market_receipt_dependencies/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration43/'
def p(v):return G/v[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(v,s):
    b=p(v).read_bytes();assert sha(b)==s,('PIN',v);return b
def read(v,s):return json.loads(fixed(v,s))
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ref(v,s):return{'path':v,'sha256':s}
def literal(a,b):return{'old':a,'new':b}
def apply(before,hunks):
    after=before
    for h in hunks:
        a,b=h['old'].encode(),h['new'].encode();assert after.count(a)==1,(h,'OLD_COUNT');after=after.replace(a,b,1)
    inverse=after
    for h in reversed(hunks):
        a,b=h['old'].encode(),h['new'].encode();assert inverse.count(b)==1,(h,'NEW_COUNT');inverse=inverse.replace(b,a,1)
    assert inverse==before;return after
ownerp=S+'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json';owners='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02';owner=read(ownerp,owners)
ep=S+'performance40_culture_C_source_repair/execution_successor_PROPOSAL.json';es='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d';oldexecbytes=fixed(ep,es);oldexec=json.loads(oldexecbytes)
rootp=R+'source_preparation30_approval_READY.json';roots='93e5b14e78f070a5c035fbe5a06d4477c9c622967ff3adb0b8788a18f71708e7';root=read(rootp,roots)
eofp=R+'adapter_exact_EOF_transport_preparation_approval_READY.json';eofs='25ff1b9474bb50ccc149e75a68959ccb0211c139d15f96c023983ba093ed2387';eof=read(eofp,eofs)
scopep=S+'performance56_market_parent_receipt_fix_scope_READONLY.json';scopes='5fdf8409e6866feb7f9306889446310c756c23951dc3313dccfbca992fedd311';scope=read(scopep,scopes)
assert root['approved_by_root']is True and root['scope_sha256']==scopes and len(oldexec['owned'])==10 and len(oldexec['source_sha256'])==85
adapter=S+'finite_adapter_production08/finite_adapter_READY.gd';oldA='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84';newA='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
ap=root['adapter_candidate']['path'];ab=fixed(ap,newA)
sysproofp='res://build/luoyang_city_full_rollout_20261022ap_system01/market_parent_receipt_fix_candidate_epoch01/whole_function_inverse_AUTHOR_NOTREADY.json';sysproof=read(sysproofp,'8d24b5152cb0700662b9592b95dea1fbafddbe09b660d555d5f9cd8cd454138b')
ah=[{'old':h['old'],'new':h['new']}for h in sysproof['hunks']]
def snapshot(target):
    s=owner['core_source_sha256'][target]
    if target in oldexec['owned']:
        row=oldexec['owned'][target];assert row['current_sha256']==s;v=row['edges'][-1]['new_snapshot']
    else:
        options=[v for v,h in oldexec['source_sha256'].items()if h==s and v!=target];assert options,(target,s);v=options[0]
    return ref(v,s)
records={};files={}
aparent=snapshot(adapter);assert aparent['sha256']==oldA and apply(fixed(aparent['path'],oldA),ah)==ab
records['adapter']={'target':adapter,'parent':aparent,'candidate':ref(ap,newA),'hunks':ah}
def candidate(name,target,hunks,filename=None):
    parent=snapshot(target);before=fixed(parent['path'],parent['sha256']);after=apply(before,hunks);v=O+(filename or name+'_CANDIDATE.gd');records[name]={'target':target,'parent':parent,'candidate':ref(v,sha(after)),'hunks':hunks};files[v]=after;return sha(after)
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';DT='res://scripts/city/luoyang_district_life_20261016f.gd';F='res://scripts/city/luoyang_district_life_fade_20261016f.gd';B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';CON='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
pin=[literal('const FINITE_ADAPTER_SHA := "'+oldA+'"','const FINITE_ADAPTER_SHA := "'+newA+'"')]
newC=candidate('C',C,pin);newDT=candidate('DT',DT,pin);newF=candidate('Fade',F,pin)
oldF=owner['core_source_sha256'][F];fp=records['Fade']['candidate']['path'];oldfp=S+'performance33_merged_code_dependencies/Fade_adapter_pin_CANDIDATE.gd'
bh=pin+[
 literal('\tvar next: String="'+oldF+'"','\tvar last_published: String="'+oldF+'"\n\tvar next: String="'+newF+'"'),
 literal('\tvar candidate: String="'+oldfp+'"','\tvar candidate: String="'+fp+'"'),
 literal('and finite_previous in history and delta.get("current_before_sha256")==finite_previous','and finite_previous in history and last_published in history and delta.get("current_before_sha256")==last_published')]
newB=candidate('B',B,bh)
oldC=owner['core_source_sha256'][C];newCon=candidate('runtime_contract',CON,[literal(oldC,newC)],'runtime_contract_C_literal_READY.json')
newCO=candidate('Coordinator',CO,[literal('const CONTRACT_SHA := "'+owner['core_source_sha256'][CON]+'"','const CONTRACT_SHA := "'+newCon+'"')])
bindp=S+'performance40_culture_C_source_repair/temple_binding_Culture_literals_READY.json';binds='2682fc0c3bd74e26d26149e56b9c736f7183193ae53c37b46f1754be89488aab';oldbind=fixed(bindp,binds);binding=json.loads(oldbind)
bsucc={C:newC,CO:newCO,CON:newCon};bindh=[literal(binding['source_delta'][path],s)for path,s in bsucc.items()];newbind=apply(oldbind,bindh);nextbind=json.loads(newbind)
inverse=copy.deepcopy(nextbind)
for path in bsucc:inverse['source_delta'][path]=binding['source_delta'][path]
assert inverse==binding
base=read(binding['parent_binding_path'],binding['parent_binding_sha256']);merged={**base['source_sha256'],**binding['source_delta']};mergednext={**base['source_sha256'],**nextbind['source_delta']};assert len(merged)==len(mergednext)==189 and {path for path in merged if merged[path]!=mergednext[path]}==set(bsucc)
bp=O+'temple_binding_three_literals_READY.json';files[bp]=newbind;records['temple_binding']={'parent':ref(bindp,binds),'candidate':ref(bp,sha(newbind)),'hunks':bindh,'merged189_only3values_other186_whole_same':True}
newT=candidate('Temple',T,[literal('const BIND_PATH="'+bindp+'"','const BIND_PATH="'+bp+'"'),literal('const BIND_SHA="'+binds+'"','const BIND_SHA="'+sha(newbind)+'"')])
contractold=json.loads(fixed(records['runtime_contract']['parent']['path'],records['runtime_contract']['parent']['sha256']));contractnext=json.loads(files[records['runtime_contract']['candidate']['path']]);ci=copy.deepcopy(contractnext);ci['source_sha256'][C]=oldC;assert ci==contractold
assert all(b'\r'not in data and data.endswith(b'\n')for path,data in files.items()if path.endswith('.gd'))
assert not ab.endswith(b'\n')and b'\r'not in ab and len(ab)==31206 and sha(ab+b'\n')==eof['patch_intermediate_sha256']=='9fc421182b8143f3fe0711322fe51788b443b5a5132dd7c524d961562b0f0025'
proofp=O+'whole_code_binding_contract_inverse_READY.json';proof={'status':'ROOT43_MARKET_COMPLETE_PARENT_AND_NECESSARY_LITERAL_SUCCESSORS_BUILD_ONLY','records':records,'all_whole_byte_forward_inverse':True,'culture_contract_one_C_value_whole_typed_inverse':True,'Temple189_exact3_other186_same':True,'source_FIRST_FINAL_and_all_native_whole_inverse_gates_unchanged':True,'only_runtime_behavior_delta':'System exactMarket adapter branch; all othercode edits sourceSHA/provenance literals only. Yamen unchanged, no22ECA.','Root_preparation':ref(rootp,roots),'Root_EOF':ref(eofp,eofs),'adapter_intermediate':{'sha256':sha(ab+b'\n'),'bytes':len(ab)+1,'sole_final0A_to_remove_after_actualpatch':True},'engine_Stage_collector_native_decode_formal_calls':0};proofb=js(proof);files[proofp]=proofb
proposal=copy.deepcopy(oldexec);edges=[]
for name in ['B','DT','Coordinator','Temple']:
    r=records[name];target=r['target'];assert proposal['owned'][target]['current_sha256']==r['parent']['sha256'];edge={'path':target,'old_sha256':r['parent']['sha256'],'new_sha256':r['candidate']['sha256'],'old_snapshot':r['parent']['path'],'new_snapshot':r['candidate']['path'],'whole_inverse':True,'replacements':copy.deepcopy(r['hunks'])};proposal['owned'][target]['edges'].append(edge);proposal['owned'][target]['current_sha256']=r['candidate']['sha256'];edges.append(edge)
newpins={r['candidate']['path']:r['candidate']['sha256']for r in records.values()};newpins[proofp]=sha(proofb);assert len(newpins)==10 and not(set(newpins)&set(oldexec['source_sha256']));proposal['source_sha256'].update(newpins)
back=copy.deepcopy(proposal)
for edge in edges:back['owned'][edge['path']]=copy.deepcopy(oldexec['owned'][edge['path']])
for path in newpins:back['source_sha256'].pop(path)
assert js(back)==oldexecbytes and len(proposal['source_sha256'])==95
newexecp=O+'execution_successor_PROPOSAL.json';eb=js(proposal);files[newexecp]=eb
hand={'status':'ROOT43_EXACT30_MARKET_PARENT_REPAIR_LITERAL_DEPENDENCIES_EXECUTION_PROPOSAL_NOT_STAGED','execution_parent':ref(ep,es),'execution_proposal':ref(newexecp,sha(eb)),'owned_changed_exactly4':edges,'other6_owned_rows_whole_unchanged':True,'old85_proof_pins_all_preserved':True,'new_exact10_proof_pins':newpins,'new95_proof_pins':True,'whole_execution_typed_and_serialized_UTF8_inverse':True,'whole_inverse_proof':ref(proofp,sha(proofb)),'scope':ref(scopep,scopes),'fixed_prior_owner':ref(ownerp,owners),'Root_preparation':ref(rootp,roots),'Root_EOF':ref(eofp,eofs),'Fade_source_migration_successor':{'path':F,'previous_sha256':oldF,'new_sha256':newF,'candidate_path':fp,'historical_keep_all_and_append_prior5846':True,'current_before_sha256':oldF},'future_metadata_required':'Registry exactly5DT values; Estate scalar and source entry same newregistrySHA; all30 currenttarget oldSHA perFC11, preserve Root39two SOURCE_ONLY leaves.4AO map rules and完整8scene5room independent sources.','engine_Stage_collector_formal_calls':0}
files[O+'handoff_EXECUTION_PROPOSAL_READY_NOT_STAGED.json']=js(hand)
for name,r in records.items():files[O+name+'_complete.diff']=''.join(difflib.unified_diff(fixed(r['parent']['path'],r['parent']['sha256']).decode().splitlines(True),fixed(r['candidate']['path'],r['candidate']['sha256']).decode().splitlines(True)if name=='adapter'else files[r['candidate']['path']].decode().splitlines(True),fromfile=r['parent']['path'],tofile=r['candidate']['path'])).encode()
assert not p(O).exists();p(O).mkdir()
for path,data in files.items():p(path).write_bytes(data)
print(json.dumps({path:sha(data)for path,data in files.items()},indent=2))
