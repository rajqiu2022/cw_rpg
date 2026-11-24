"""NEW mechanical AP14/ROOT26 light06 freeze. Text only; no engine/collector."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance27_yamen_light06/';O=S+'performance28_yamen_light06_ROOT26/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(fixed(path,s))
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ref(path,s):return {'path':path,'sha256':s}
kp=P+'test_yamen_performance06_PENDING_ROOT.gd';ks='29f92580d60f22c4615213b4f9bb4ad32b568c0945d3eed7ef118e1a109ad455'
fp=P+'yamen_performance06_fixture_PENDING_ROOT.json';fs='363b4deb9f0186698a332c49de0f399a8814fb7b35bf018b86c23cd463c93839'
hp=P+'handoff_PENDING_ROOT_NOT_RUN.json';hs='9fcc7da01e11245d9e188cb82a99bb7aa8b4261cc6e9a3d26d0b8bef0f33d390'
key=fixed(kp,ks);pending=read(fp,fs);pendinghand=read(hp,hs)
op=S+'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json';os='65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be'
owner=read(op,os)
rp=S+'performance26_canonical_B_actual_independent_review/source_stage_review_READY.json';rs='80e507366857feb3ea02c68f35042a64f27968853a8f93a8aa8d194b8f896c97'
review=read(rp,rs)
gp=R+'integration25/final_guard.json';gs='478f624b666ceb55346343fb60e4e21cc10a009e0ea459438a95446d020098c9'
cp=R+'integration25/generated_json_deployment_actual.json';cs='d39a49f1a232dab960d8ea62670d394cef61b21b5e76dd4efbaa565f7a8417e4'
bp=R+'integration26/guard_before.json';bs='5b9add35deb6c01be3eb07be6afe2c5f5ff89fb4291ce0967b3c71539e7196d5'
guard=read(gp,gs);actual=read(cp,cs);before=read(bp,bs)
assert guard['passed']is True and guard['checked']==2117 and guard['authorized_change_count']==22 and guard['exact_unchanged']==2095
assert guard['unexpected_change_count']==guard['save_change_count']==0 and guard['save_count']==15
assert actual['status']=='ROOT_ACTUAL_EXACT13_GENERATED_JSON_BYTE_COPIES_AFTER9_GD_APPLY_PATCH'
assert actual['copy_count']==13 and actual['GD_apply_patch_count']==9 and actual['native_or_save_or_media_writes']==0 and actual['normalization']is False
assert before['passed']is True and before['mode']=='before' and before['checked']==2117
assert before['unexpected_change_count']==before['save_change_count']==0 and before['save_count']==15
assert owner['status']=='ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS' and owner['actual_stage_receipt']==review['actual_stage_receipt']
assert owner['actual_stage_receipt']==ref(S+'outputs/root_B_canonical_keys_stage01/receipt.json','35ffd126b0ac5292c91e9ed0bd4ea97d8e7c0a4caa16ea36ddcc6ed0e587fa36')
assert review['owner_source_maps']==ref(op,os) and review['source_first_final_same']is True
row=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
assert len(row['source_sha256'])==1225 and row['source_sha256']==row['receipt_source_sha256']
parentkeypath=pendinghand['parent_key']['path'];parentkeysha=pendinghand['parent_key']['sha256'];parentkey=fixed(parentkeypath,parentkeysha)
oldfp=S+'performance17_yamen_light05_ROOT21/yamen_performance05_fixture_ROOT21_READY.json'
oldfs='e8b1bea1a4b84f3227c1dacfffc353f2a101f5f481867765d5210e45463c27e7'
oldfixture=read(oldfp,oldfs);priorref=oldfixture['authority']['independent_owner'];prior=read(priorref['path'],priorref['sha256'])
priorrow=next(r for r in prior['scenes']if r['id']=='ch4_s1_luoyang_yamen')
assert priorref==pending['authority']['fixed_prior_owner'] and len(priorrow['source_sha256'])==1223
assert set(row['source_sha256'])-set(priorrow['source_sha256'])=={
 S+'performance20_canonical_keys_candidate01/Bundle_canonical_keys_wire_CANDIDATE.gd',
 S+'performance24_canonical_B_dependencies/whole_B7123_to9D5B_inverse_READY.json'}
sources=copy.deepcopy(oldfixture['source_sha256']);assert len(sources)==1246
for table in [row['source_sha256'],owner['core_source_sha256']]:
    for path,s in table.items():
        if path in sources and sources[path]!=s:
            assert path in prior['core_source_sha256'] or path in priorrow['source_sha256']
        sources[path]=s
oldparent=S+'performance10_yamen_light04_ROOT18/test_yamen_performance04_ROOT18_READY.gd'
removed=[oldparent,priorref['path'],oldfixture['authority']['actual_source_stage']['path'],oldfixture['authority']['actual_Root_deployment_guard']['path'],oldfixture['authority']['actual_Root_deployment_copy']['path']]
for path in removed:assert path in sources;del sources[path]
added=[(parentkeypath,parentkeysha),(op,os),(owner['actual_stage_receipt']['path'],owner['actual_stage_receipt']['sha256']),(gp,gs),(cp,cs)]
for path,s in added:assert path not in sources;sources[path]=s
assert len(sources)==1248
assert bp not in sources;sources[bp]=bs
assert len(sources)==1249
fixture=copy.deepcopy(pending)
fixture.update(status='AP14_FORMALLY_DEPLOYED_ROOT26_PERFORMANCE06_ONE_DEFAULT_ENTRY_READY_NOT_RUN',ready=True,blockers=[],source_sha256=sources,expected_city_source_sha256=copy.deepcopy(row['source_sha256']),
 authority={'fixed_prior_owner':copy.deepcopy(pending['authority']['fixed_prior_owner']),
 'independent_owner':ref(op,os),'actual_source_stage':copy.deepcopy(owner['actual_stage_receipt']),
 'actual_Root_deployment_guard':{**ref(gp,gs),'pending':False},'actual_Root_deployment_copy':{**ref(cp,cs),'pending':False},
 'Root26_fresh_before':ref(bp,bs),'formal_revision':'AP14'},
 pending_authority_not_in_source_guard_until_real_freeze=False)
fixture['expected_source_count_recipe']['actual_independent_owner_count_confirmed']=1225
changed=['status','ready','blockers','source_sha256','expected_city_source_sha256','authority','pending_authority_not_in_source_guard_until_real_freeze','expected_source_count_recipe']
inverse=copy.deepcopy(fixture)
for name in changed:inverse[name]=copy.deepcopy(pending[name])
assert js(inverse)==fixed(fp,fs)
newfp=O+'yamen_performance06_fixture_ROOT26_READY.json';newfb=js(fixture)
newkey=key;hunks=[{'old':'const FIXTURE="'+fp+'"','new':'const FIXTURE="'+newfp+'"'},{'old':'const FIXTURE_SHA="'+fs+'"','new':'const FIXTURE_SHA="'+sha(newfb)+'"'}]
for h in hunks:
    a,b=h['old'].encode(),h['new'].encode();assert newkey.count(a)==1;newkey=newkey.replace(a,b,1)
back=newkey
for h in reversed(hunks):
    assert back.count(h['new'].encode())==1;back=back.replace(h['new'].encode(),h['old'].encode(),1)
assert back==key
for h in reversed(pendinghand['hunks']):
    assert back.count(h['new'].encode())==1;back=back.replace(h['new'].encode(),h['old'].encode(),1)
assert back==parentkey and newkey.count(b'district.call("loading_timing_state")')==1
newkp=O+'test_yamen_performance06_ROOT26_READY.gd'
def diff(a,b,ap,bp):return ''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile=ap,tofile=bp)).encode()
files={'test_yamen_performance06_ROOT26_READY.gd':newkey,'yamen_performance06_fixture_ROOT26_READY.json':newfb,
 'freeze_vs_PENDING_key.diff':diff(key,newkey,kp,newkp),'freeze_vs_PENDING_fixture.diff':diff(fixed(fp,fs),newfb,fp,newfp),'complete_vs_b88B.diff':diff(parentkey,newkey,parentkeypath,newkp)}
deltas=[{'path':path,'old':oldfixture['source_sha256'].get(path),'new':sources.get(path)}for path in sorted(set(oldfixture['source_sha256'])|set(sources))if oldfixture['source_sha256'].get(path)!=sources.get(path)]
hand={'status':'AP14_FORMAL_ROOT25_ACTUAL_AND_ROOT26_FRESH_BOUND_PERFORMANCE06_READY_NOT_PARSED_NOT_RUN','ready':True,
 'script':ref(newkp,sha(newkey)),'fixture':{**ref(newfp,sha(newfb)),'expected_city_sources':1225,'source_guard':len(sources)},
 'parent_key':ref(parentkeypath,parentkeysha),'pending_key':ref(kp,ks),'pending_fixture':ref(fp,fs),
 'actual_independent_owner':ref(op,os),'actual_owner_review':ref(rp,rs),'actual_source_stage':owner['actual_stage_receipt'],
 'actual_Root25_deployment_guard':ref(gp,gs),'actual_Root25_deployment_copy':ref(cp,cs),'Root26_fresh_before':ref(bp,bs),
 'formal_revision':'AP14','whole_PENDING_key_byte_inverse':True,'whole_b88B_key_byte_inverse':True,
 'whole_pending_fixture_serialized_byte_inverse':True,'mechanical_ready_key_hunks_only':hunks,
 'source_guard_recipe':'Fixed ROOT21 light05 guard plus independent65BE Yamen/core successors from5050+exact22+two frozen proof leaves; replace prior04/5050/7912/Root21 leaves by fixed05/65BE/35FF/Root25, then add fixed Root26 fresh before. No current collector or filesystem expected filling.',
 'source_guard_deltas_from_ROOT21':deltas,'source_guard_removed_authority_leaves':removed,
 'source_guard_added_authority_leaves':[ref(path,s)for path,s in added]+[ref(bp,bs)],
 'DT_getter_once_after_frozen_draw_and_natural_receipt_unchanged':True,'60s_default_null_Yamen_zeroINPUT_picture_geometry_collector_unchanged':True,
 'no_G_change_or_warm_travel':True,'diffs':{name:ref(O+name,sha(b))for name,b in files.items()if name.endswith('.diff')},
 'engine_parse_collector_Stage_public_requests':0,'runtime_loading_pass_claim':False,
 'Root_only_command_not_executed':'godot --path F:/Code/RPG_GAME/game --script '+newkp}
files['handoff_ROOT26_READY_NOT_RUN.json']=js(hand)
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
assert fixed(kp,ks)==key and js(pending)==fixed(fp,fs)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
