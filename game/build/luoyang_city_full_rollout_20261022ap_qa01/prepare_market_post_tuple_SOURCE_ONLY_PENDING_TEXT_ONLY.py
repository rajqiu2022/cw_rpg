"""False successor skeleton only. No actual owner/source values invented."""
from pathlib import Path
import copy,difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
P=QA/'market_pawn_single_visual_ROOT38_READY'
D=QA/'market_pawn_post_SOURCE_ONLY_PENDING_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return'res://'+p.relative_to(GAME).as_posix()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def emit(name,data):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(data)
    return{'path':rel(p),'sha256':sha(p),'bytes':p.stat().st_size}
kp=P/'test_market_pawn_single_visual_ROOT38_READY.gd';fp=P/'market_pawn_single_visual_fixture_ROOT38_READY.json'
assert sha(kp)=='08e9da3acd99281f2196ffd6060a1c5eb0383953a2b274f106d837b174554274'
assert sha(fp)=='b57f43d13a1251f933928467883d6c74d100ceedc248669f49586d939c79881b'
approval=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration39/source_only_two_leaf_admission.json'
assert sha(approval)=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4'
a=rd(approval);assert a['approved_by_root']and len(a['source_leaves'])==2
old=rd(fp);f=copy.deepcopy(old)
f.update({'status':'NEW_MARKET_SINGLEIMAGE_AFTER_SOURCE_ONLY_CLOSURE_PENDING_NOTREADY','ready':False,'blockers':['Exact3 actualStage and independent newcomplete1702 owner not supplied.','Formal exact3 deployment/finalguard and fresh observation authority not supplied.'],'expected_sources':{},'source_sha256':{},'authority':{},'pending_source_count':1702,'actual_stage':None,'independent_owner':None,'formal_deployment':None,'fresh_before':None,'fixed_ROOT38_fixture':{'path':rel(fp),'sha256':sha(fp)},'SOURCE_ONLY_admission':{'path':rel(approval),'sha256':sha(approval)},'pending_no_current_fill':True})
fixture=emit('market_pawn_after_SOURCE_ONLY_fixture_PENDING_NOTREADY.json',enc(f))
oldkey=kp.read_bytes();key=oldkey
assert key.count(b'1700')==5
changes=[('const FIXTURE_READY=true','const FIXTURE_READY=false'),(rel(fp),fixture['path']),(sha(fp),fixture['sha256']),('market_pawn_single_visual_ROOT38_READY/output/','market_pawn_post_SOURCE_ONLY_PENDING_NOTREADY/output/'),('1700','1702')]
for x,y in changes:
    assert key.count(x.encode())==(5 if x=='1700'else 1)
    key=key.replace(x.encode(),y.encode())
back=key
for x,y in reversed(changes):
    assert back.count(y.encode())==(5 if x=='1700'else 1)
    back=back.replace(y.encode(),x.encode())
assert back==oldkey
k=emit('test_market_pawn_after_SOURCE_ONLY_PENDING_NOTREADY.gd',key)
diff=emit('complete_key_vs_ROOT38.diff',''.join(difflib.unified_diff(oldkey.decode().splitlines(True),key.decode().splitlines(True),fromfile='ROOT38_FAILED_PRESERVED',tofile='PENDING_READY_FALSE')).encode())
handoff=emit('handoff_PENDING_NOTREADY_NOT_RUN.json',enc({'status':'PENDING_NEW_MARKET_SINGLEIMAGE_SOURCE_ONLY_CLOSURE_NOT_RUN','key':k,'fixture':fixture,'fullkeydiff':diff,'byte_inverse_ROOT38_exact':True,'sourcecount_changes':'Exactly5text occurrences1700→1702:2strictsizepredicates+2labels+1recordkind; no other functionsemantic change.','otherchanges':'readinessfalse+fixturepath/SHA+NEWoutputdirectory only','scope_unchanged':{'whole_ms':60000,'entry_ms':20000,'input':[[570,1928],[570,1904]],'one_public_near':True,'one_normal1920x1080_zoom1_PNG':True,'Space':0,'rooms':0,'crossdistrict':0,'collector':0,'newgeometry':0,'camera_or_player_positionwrites':0},'expected_sources_guard_empty_until_independent_actual_owner':True,'no_observed2leaf_or_currentheader_backfill':True,'oldROOT38failed_expected_and_failure_snapshot_draft_preserved_not_replayed':True,'SOURCE_ONLY_admission_SHA':sha(approval),'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'canonical_write':0}}))
print(json.dumps({'key':k,'fixture':fixture,'handoff':handoff}))
