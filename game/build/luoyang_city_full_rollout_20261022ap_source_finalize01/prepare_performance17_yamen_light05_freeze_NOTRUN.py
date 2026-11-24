"""NEW performance05 mechanical actual-owner/deployment freeze; no engine."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance16_yamen_light05/';O=S+'performance17_yamen_light05_ROOT21/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/integration21/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(fixed(path,s))
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
kp=P+'test_yamen_performance05_PENDING_ROOT.gd';ks='107d57cc7c3598ce261cbfce1864608d15dc9b751be55aac8af8aa9c2a9d2e8a'
fp=P+'yamen_performance05_fixture_PENDING_ROOT.json';fs='a3034a62ecfafc2716d11e7f27f71a0b867ea690648ff21d4a93b2e465004fec'
hp=P+'handoff_PENDING_ROOT_NOT_RUN.json';hs='dbafbccd40585921b45735337c9d5ac561572fbfa6aa1f001337bdb852d23705'
key=fixed(kp,ks);pending=read(fp,fs);pendinghand=read(hp,hs)
op=S+'performance15_B_only_actual_independent_review/owner_source_maps_READY.json';os='5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e'
owner=read(op,os)
review=read(S+'performance15_B_only_actual_independent_review/source_stage_review_READY.json','4909d6c71a05c35030951366d725dbb070cdaae55b4b34beba9b681efd829ebc')
gp=R+'final_guard.json';gs='009a83cabdcfc5dba2044d1eaf48cdd5aa7e0842e431eccbc7f0d1999456ea4e'
cp=R+'generated_json_deployment_actual.json';cs='55035788040aa8f8f71e3ff0ca6b56f09dac7de7abf3521af365d4f7a76d8bf4'
guard=read(gp,gs);actual=read(cp,cs)
assert guard['passed']is True and guard['checked']==2117 and guard['authorized_change_count']==22 and guard['exact_unchanged']==2095 and guard['unexpected_change_count']==0 and guard['save_change_count']==0 and guard['save_count']==15
assert actual['status']=='ACTUAL9_GD_APPLY_PATCH_AND13_GENERATED_JSON_EXACT_COPY_COMPLETED' and actual['all22_exact']is True and actual['GD_apply_patch_count']==9 and actual['JSON_exact_copy_count']==13 and actual['save_writes']==0
assert owner['status']=='ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS' and owner['actual_stage_receipt']==review['actual_stage_receipt']
assert owner['actual_stage_receipt']=={'path':S+'outputs/root_B_only_symmetric_wire_stage01/receipt.json','sha256':'7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf'}
row=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
assert len(row['source_sha256'])==1223 and row['source_sha256']==row['receipt_source_sha256']
parentkeypath=pendinghand['parent_key']['path'];parentkeysha=pendinghand['parent_key']['sha256'];parentkey=fixed(parentkeypath,parentkeysha)
oldfixturepath=S+'performance10_yamen_light04_ROOT18/yamen_performance04_fixture_ROOT18_READY.json';oldfixturesha='1e8926959c79c2819253da70befac4d64ad619770eab838a1f2b1b88e01d97c5'
oldfixture=read(oldfixturepath,oldfixturesha)
priorownerref=oldfixture['authority']['independent_owner'];priorowner=read(priorownerref['path'],priorownerref['sha256'])
sources=copy.deepcopy(oldfixture['source_sha256'])
for table in [row['source_sha256'],owner['core_source_sha256']]:
    for path,s in table.items():
        if path in sources and sources[path]!=s:
            assert path in priorowner['core_source_sha256'] or path in next(r for r in priorowner['scenes']if r['id']=='ch4_s1_luoyang_yamen')['source_sha256']
        sources[path]=s
old_parent03='res://tests/test_luoyang_ap_yamen_performance03_LIGHT_ROOT16_READY_20261023.gd'
for path in [old_parent03,priorownerref['path'],oldfixture['authority']['actual_source_stage']['path'],oldfixture['authority']['actual_Root_deployment_guard']['path'],oldfixture['authority']['actual_Root_deployment_copy']['path']]:
    assert path in sources;del sources[path]
for path,s in [(parentkeypath,parentkeysha),(op,os),(owner['actual_stage_receipt']['path'],owner['actual_stage_receipt']['sha256']),(gp,gs),(cp,cs)]:
    assert path not in sources;sources[path]=s
assert len(sources)==1246
fixture=copy.deepcopy(pending)
fixture.update(status='ROOT21_DEPLOYED_PERFORMANCE05_ONE_DEFAULT_ENTRY_ONLY_READY_NOT_RUN',ready=True,blockers=[],source_sha256=sources,expected_city_source_sha256=copy.deepcopy(row['source_sha256']),
 authority={'fixed_prior_owner':copy.deepcopy(pending['authority']['fixed_prior_owner']),
 'independent_owner':{'path':op,'sha256':os},'actual_source_stage':copy.deepcopy(owner['actual_stage_receipt']),
 'actual_Root_deployment_guard':{'path':gp,'sha256':gs,'pending':False},'actual_Root_deployment_copy':{'path':cp,'sha256':cs,'pending':False}},
 pending_authority_not_in_source_guard_until_real_freeze=False)
fixture['expected_source_count_recipe']['actual_independent_owner_count_confirmed']=1223
inverse=copy.deepcopy(fixture)
changed=['status','ready','blockers','source_sha256','expected_city_source_sha256','authority','pending_authority_not_in_source_guard_until_real_freeze','expected_source_count_recipe']
for name in changed:inverse[name]=copy.deepcopy(pending[name])
assert js(inverse)==fixed(fp,fs)
newfp=O+'yamen_performance05_fixture_ROOT21_READY.json';newfb=js(fixture)
newkey=key;hunks=[{'old':'const FIXTURE="'+fp+'"','new':'const FIXTURE="'+newfp+'"'},{'old':'const FIXTURE_SHA="'+fs+'"','new':'const FIXTURE_SHA="'+sha(newfb)+'"'}]
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert newkey.count(a)==1;newkey=newkey.replace(a,b,1)
back=newkey
for h in reversed(hunks):back=back.replace(h['new'].encode(),h['old'].encode(),1)
assert back==key
for h in reversed(pendinghand['hunks']):
    assert back.count(h['new'].encode())==1;back=back.replace(h['new'].encode(),h['old'].encode(),1)
assert back==parentkey and newkey.count(b'district.call("loading_timing_state")')==1
newkp=O+'test_yamen_performance05_ROOT21_READY.gd'
def diff(a,b,ap,bp):return ''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile=ap,tofile=bp)).encode()
files={'test_yamen_performance05_ROOT21_READY.gd':newkey,'yamen_performance05_fixture_ROOT21_READY.json':newfb,
 'freeze_vs_PENDING_key.diff':diff(key,newkey,kp,newkp),'freeze_vs_PENDING_fixture.diff':diff(fixed(fp,fs),newfb,fp,newfp),'complete_vs_51FDD947.diff':diff(parentkey,newkey,parentkeypath,newkp)}
source_deltas=[{'path':path,'old':oldfixture['source_sha256'].get(path),'new':sources.get(path)}for path in sorted(set(oldfixture['source_sha256'])|set(sources))if oldfixture['source_sha256'].get(path)!=sources.get(path)]
hand={'status':'ROOT21_ACTUAL_DEPLOYMENT_BOUND_PERFORMANCE05_READY_NOT_PARSED_NOT_RUN','ready':True,
 'script':{'path':newkp,'sha256':sha(newkey)},'fixture':{'path':newfp,'sha256':sha(newfb),'expected_city_sources':1223,'source_guard':len(sources)},
 'parent_key':{'path':parentkeypath,'sha256':parentkeysha},'pending_key':{'path':kp,'sha256':ks},'pending_fixture':{'path':fp,'sha256':fs},
 'actual_independent_owner':{'path':op,'sha256':os},'actual_source_stage':owner['actual_stage_receipt'],'actual_Root_deployment_guard':{'path':gp,'sha256':gs},'actual_Root_deployment_copy':{'path':cp,'sha256':cs},
 'whole_PENDING_key_byte_inverse':True,'whole_51FDD947_key_byte_inverse':True,'whole_pending_fixture_serialized_byte_inverse':True,'mechanical_ready_key_hunks_only':hunks,
 'source_guard_recipe':'Fixed ROOT18 light04 guard plus independent5050 Yamen/core declared source successors; replace prior03/9D004/D058/Root18 authority leaves with fixed04/5050/7912/Root21, no current collector or filesystem expected filling.',
 'source_guard_deltas_from_ROOT18':source_deltas,'DT_getter_once_after_frozen_draw_and_natural_receipt_unchanged':True,'60s_default_null_Yamen_zeroINPUT_picture_geometry_collector_unchanged':True,
 'diffs':{name:{'path':O+name,'sha256':sha(b)}for name,b in files.items()if name.endswith('.diff')},
 'engine_parse_collector_Stage_public_requests':0,'runtime_loading_pass_claim':False,
 'Root_only_command_not_executed':'godot --path F:/Code/RPG_GAME/game --script '+newkp}
files['handoff_ROOT21_READY_NOT_RUN.json']=js(hand)
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
assert fixed(kp,ks)==key and js(pending)==fixed(fp,fs)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
