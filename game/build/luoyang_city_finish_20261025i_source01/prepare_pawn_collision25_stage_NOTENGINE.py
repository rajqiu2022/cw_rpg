"""Reuse the actual-reviewed Field-only exact25 Stage; no Stage instance/run."""
from pathlib import Path
import json,hashlib,copy,difflib,importlib.util
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_repair01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def raw(p):
    b=(GAME/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'];return b
def load(p):return json.loads(raw(p))
def emit(path,b):
    p=GAME/path[6:];assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return dict(path=path,sha256=sha(b),bytes=len(b))
bp=dict(path=P+'unified25_READY01/pawn_collision25_all_candidates_and_inverse_NOT_STAGE.json',sha256='4d850a9d16b675af9262b345140643cfa3dcb28e3abe8f9b81c9ae405dc87df9');b=load(bp)
parentpin=dict(path=S+'stage_Temple_actor_receipt25_ROOT_ONLY03.py',sha256='40630e45e2f9c40b9f7ecf42ca9cd1f86115195989520d0280695d9e5861767a');parent=raw(parentpin);text=parent.decode()
changes=[
('Root-only E53E exact25 Temple actor receipt successor; Field only two-line true top-level matched propagation. No engine/canonical writes.','Root-only current9C1245 exact25 pawn body successor. One exact-pawn Field hunk replaces local collider rows from the approved nine source bases. Other functions and native storage unchanged. No engine/canonical writes.'),
('TempleReceipt25','PawnCollision25'),('ROOT_CURRENT_E53E_FULL25','ROOT_CURRENT9C1245_FULL25'),("self.backup['total_backups']==461","self.backup['total_backups']==539"),('ROOT_ACTUAL_E53E_BACKUP25','ROOT_ACTUAL9C1245_BACKUP25'),("len(self.backup['current36'])==36","len(self.backup['current37'])==37"),("self.backup['current36']","self.backup['current37']"),('CURRENT36_NOOP_G_AUTHORITY_PRESERVED','CURRENT37_CURRENT_G22_PRESERVED'),('CURRENT36_IMMUTABLE_PARENT','CURRENT37_IMMUTABLE_PARENT'),('Temple_actor_receipt_repair01/root_only_current25_backup/','pawnshop_collision_repair01/root_only_current25_backup/'),("len(prior['source_sha256'])==224 and len(self.authority['source_sha256'])==229","len(prior['source_sha256'])==236 and len(self.authority['source_sha256'])==241"),('OWNED10_224_PLUS5_EQUALS229','OWNED10_236_PLUS5_EQUALS241'),('ALL_OLD224_FIXED_FIVE_NEW','ALL_OLD236_FIXED_FIVE_NEW'),('PINNED_CURRENT_E53E_MAP_PARENT','PINNED_CURRENT9C1245_MAP_PARENT'),('TEMPLE_ACTOR_RECEIPT_EXACT25_STAGED_NOT_DEPLOYED','PAWN_LOCAL_COLLISION_EXACT25_STAGED_NOT_DEPLOYED'),('Pinned E53E/DC81 exact25 successor. All owned10/old224 values and edges preserved plus5 proofs=229 and3 real owned edges. Field only two-line true top-level matched-to-Temple-receipt propagation; CT26/Temple196 prospective checks preserved. Other runtime/Router/Family/geometry logic unchanged.','Pinned current9C1245/23C504 exact25 successor. All owned10 and old236 proof values/edges retained plus5=241 and exactly3 real Field/Coordinator/Temple successor edges. One exact-pawn Field local-blocker conversion hunk consumes approved G effective nine bases via the original collider constructor. Native Scene/layout/registry, G C96B/service4C83/author4405, C/ENV/Router/Family/finish runtime/BIND/exterior payloads/masks/media unchanged. CT26/Temple196 all prospective values checked; original22 partial deployment and its authorized backup differences preserved, not claimed as a completed pawn Field result.')]
for a,c in changes:assert a in text,a;text=text.replace(a,c)
a="  trial=self.read_json_input('trial');need(trial['admitted']is True and trial['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'and trial['actual_Field_pass']is False and self.inputs['trial']['path']==PREFIX+'finish8_ROOT_TRIAL_PERMISSION02.json'and self.inputs['trial']['sha256']=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','TRIAL_PERMISSION_NOT_RESULT')\n"
c="  classification=self.read_json_input('backup_classification');need(classification['passed']is True and classification['backup']['sha256']==self.inputs['backup']['sha256'] and classification['authorized_count']==22 and classification['other2099_no_difference_in_actual_report']is True and len(self.backup['differences'])==22,'ONLY_PREVIOUS_ROOT_DEPLOYED22_BACKUP_DIFFERENCES_PRESERVED')\n  need(self.inputs['backup']['sha256']=='50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0','ROOT_CURRENT_EXACT25_BACKUP_SCOPE_AND_LOCKED_INPUT_NOT_FIELD_PASS')\n"
assert text.count(a)==1;text=text.replace(a,c)
aa=parent.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'stage_pawn_collision_exact25_ROOT_ONLY.py','exec')
driver=emit(S+'stage_pawn_collision_exact25_ROOT_ONLY.py',text.encode())
proof=emit(P+'Stage25_driver_whole_inverse_NOT_STAGE.json',enc(dict(parent=parentpin,candidate=driver,hunks=hs,whole_UTF8_inverse=True,original_F120_bounded_full_edge_validation_unchanged=True,original_CT26_Temple196_all_prospective_checks_preserved=True,only_Field_function_hunk_Coord_Temple_pointers=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
pins=[dict(id='driver',**driver),dict(id='candidates',**bp),dict(id='scope',**b['scope']),dict(id='backup',**b['root_backup']),dict(id='execution',**b['execution']['candidate']),dict(id='authority_helper',**b['authority_helper']),dict(id='publication',**b['publication']),dict(id='parent_stage',**b['parent_stage']),dict(id='backup_classification',**b['backup_authorized22_classification']),dict(id='function_proof',**b['function_proof']),dict(id='code',**b['code_proof'])]
gates=[]
for i,g in enumerate(b['old_required_gates']):
    k='gate_'+str(i);pins.append(dict(id=k,**g['pin']));gates.append(dict(id=g['id'],input=k,pointer=g['pointer'],equals=g['equals']))
gates.append(dict(id='root_target_preauthorization',input='backup',pointer=['passed'],equals=True))
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=S+'outputs/root_pawn_local_collision_exact25_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'])for r in b['targets']],declared_candidates={r['target']:r['candidate']for r in b['targets']},five_owned_targets=b['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
# Run only reviewed data/format expressions, never Stage.
core=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('pawn25_patch_formatter_only',core);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M)
targets={r['target']:r for r in b['targets']};patches={}
for p,r in targets.items():
    old,new=raw(r['parent']),raw(r['candidate']);assert old!=new and (GAME/p[6:]).read_bytes()==old
    if p.endswith('.gd'):_,pr=M._strict_lf_build_file_patch((GAME/p[6:]).resolve().as_posix(),old,new);patches[p]=pr
assert len(targets)==25 and len(patches)==11
def at(v,p):
    for k in p:v=v[k]
    return v
for p,r in b['metadata'].items():
    old,new=load(r['parent']),load(r['candidate']);v=copy.deepcopy(old);before={};after={}
    for f in r['source_fields']:
        for k,h in at(old,f).items():assert k not in before;before[k]=h
        for k,h in at(new,f).items():assert k not in after;after[k]=h
        assert set(at(old,f))<=set(at(new,f))
    assert {k:h for k,h in after.items()if k not in before}==r['explicit_new_ordinary']
    for c in r['changes']:
        d=at(v,c['pointer'][:-1]);k=c['pointer'][-1];assert(k in d)==c['existed']and(not c['existed']or d[k]==c['old']);d[k]=c['new']
    assert v==new
    for c in reversed(r['changes']):
        d=at(v,c['pointer'][:-1]);k=c['pointer'][-1]
        if c['existed']:d[k]=c['old']
        else:del d[k]
    assert enc(v)==raw(r['parent'])
fixed=dict(load(b['parent_stage'])['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
fixed.update({p:r['candidate']['sha256']for p,r in targets.items()})
ct=load(b['contract']['candidate'])['source_sha256'];tb=load(b['temple_binding']['candidate']);tp=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));ts={**tp['source_sha256'],**tb['source_delta']};assert len(ct)==26 and len(ts)==196
for table in [ct,ts]:
    for p,h in table.items():assert fixed[p]==h,(p,h,fixed.get(p))
inputpin=emit(P+'source_input_pawn_collision25_ROOT_REVIEW.json',enc(spec))
audit=emit(P+'finite_preStage25_inverse_READONLY.json',enc(dict(status='PAWN_LOCAL_BODIES_EXACT25_DATA_PREFLIGHT_NOT_STAGE',passed=True,count=25,all_source_classes_keys_preserved=True,all_CT26_Temple196_prospective_values=True,all_metadata_raw_typed_inverse=True,patches=patches,map_counts={k:r['count']for k,r in b['maps'].items()},Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(driver=driver,proof=proof,input=inputpin,audit=audit)))
