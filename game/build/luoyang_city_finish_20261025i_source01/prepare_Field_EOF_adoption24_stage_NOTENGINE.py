"""Reviewed25 Stage narrowed to24 writes and one already-current exact Field adoption. No Stage execution."""
from pathlib import Path
import json,hashlib,difflib,importlib.util,copy
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'Field_EOF_adoption01/';O=N/'Field_EOF_adoption01';F='res://scripts/field/field_walkable_controller.gd'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def raw(pin):
 b=(GAME/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(raw(pin))
def emit(p,b):
 d=GAME/p[6:];assert not d.exists();d.parent.mkdir(parents=True,exist_ok=True)
 with d.open('xb')as f:f.write(b)
 return dict(path=p,sha256=sha(b),bytes=len(b))
bp=dict(path=P+'unified24_READY01/Field_EOF24_all_candidates_and_inverse_NOT_STAGE.json',sha256=sha((O/'unified24_READY01/Field_EOF24_all_candidates_and_inverse_NOT_STAGE.json').read_bytes()));bundle=load(bp)
parentpin=dict(path=S+'stage_Temple_actor_receipt25_ROOT_ONLY03.py',sha256='40630e45e2f9c40b9f7ecf42ca9cd1f86115195989520d0280695d9e5861767a');parent=raw(parentpin);t=parent.decode()
changes=[('Root-only E53E exact25 Temple actor receipt successor; Field only two-line true top-level matched propagation. No engine/canonical writes.','Root-only E370 exact24 source-pin successor; already-current Field9CBB adopts exact4201 minus two terminal LF. No Field write, runtime hash waiver, engine or canonical writes.'),('TempleReceipt25','FieldEOF24'),("self.scope['count']==len(self.parents)==25 and self.scope['partition']==dict(GD=11,JSON=14)","self.scope['count']==len(self.parents)==24 and self.scope['partition']==dict(GD=10,JSON=14)"),('EXACT25_11GD14JSON_SCOPE','EXACT24_10GD14JSON_SCOPE'),('ROOT_CURRENT_E53E_FULL25_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_E370_FULL24_PLUS2_FIELD_BACKUP_AND_FRESH_OBSERVATION'),("self.backup['total_backups']==461","self.backup['total_backups']==674"),('ROOT_ACTUAL_E53E_BACKUP25','ROOT_ACTUAL_E370_BACKUP24_PLUS2'),('len(rows)==25','len(rows)==24'),('ROOT_BACKUP25_EXACT_DOMAIN','ROOT_BACKUP24_EXACT_DOMAIN'),("self.backup['current36']","self.backup['current37']"),('==36','==37'),('CURRENT36','CURRENT37'),('Temple_actor_receipt_repair01/root_only_current25_backup/','Field_EOF_adoption01/root_only_current24_backup/'),("len(prior['source_sha256'])==224 and len(self.authority['source_sha256'])==229","len(prior['source_sha256'])==259 and len(self.authority['source_sha256'])==264"),('OWNED10_224_PLUS5_EQUALS229','OWNED10_259_PLUS5_EQUALS264'),("r=self.bundle['records'][p];edge=new['edges'][-1]","r=self.adopt if p==self.adopt['target']else self.bundle['records'][p];edge=new['edges'][-1]"),('ALL_OLD224_FIXED_FIVE_NEW','ALL_OLD259_FIXED_FIVE_NEW'),('len(self.targets)==25','len(self.targets)==24'),('EXACT25_NO_NOOP_TARGETS','EXACT24_NO_NOOP_TARGETS'),('PINNED_CURRENT_E53E_MAP_PARENT','PINNED_CURRENT_E370_MAP_PARENT'),('len(copies)==14 and len(reconstruction)==25','len(copies)==14 and len(reconstruction)==24'),('EXACT11_GD_PATCH14_JSON_COPY','EXACT10_GD_PATCH14_JSON_COPY'),('TEMPLE_ACTOR_RECEIPT_EXACT25_STAGED_NOT_DEPLOYED','FIELD_EOF_ADOPTION_EXACT24_STAGED_NOT_DEPLOYED'),('dict(patch_count=11,copy_count=14,total=25)','dict(patch_count=10,copy_count=14,total=24)'),('targets=25,map_nodes=4','targets=24,map_nodes=4'),('Pinned E53E/DC81 exact25 successor. All owned10/old224 values and edges preserved plus5 proofs=229 and3 real owned edges. Field only two-line true top-level matched-to-Temple-receipt propagation; CT26/Temple196 prospective checks preserved. Other runtime/Router/Family/geometry logic unchanged.','Pinned E370/95F3 exact24 source-only successor. All owned10/old259 values and edges retained plus5=264; Field exact4201 minus two LF is already current9CBB and is not written. Only Coordinator/Temple/index source pins and14JSON change. All runtime hash algorithms, code semantics, geometry, masks and actors remain unchanged. Fresh user saves and same-content media current timestamps are preserved; CT26/Temple196 all prospective values remain strict.')]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
marker="  need(self.scope['count']==len(self.parents)==24"
at=t.index(marker)
addition="""  self.adopt=self.bundle['adopted_Field'];need(self.adopt['target']=='res://scripts/field/field_walkable_controller.gd'and self.adopt['target']not in self.parents and self.adopt['only_removed_final_two_ASCII_LF']is True,'ONLY_EXACT_ALREADY_SAVED_FIELD_ADOPTION')
  a=self.read(self.adopt['parent']['path'],self.adopt['parent']['sha256']);b=self.read(self.adopt['candidate']['path'],self.adopt['candidate']['sha256']);need(self.adopt['parent']['sha256']=='4201a29c4791e099300ec5841bca0e9a7a1571bb71e6ccd74bf8cd8d9598e3aa'and self.adopt['candidate']['sha256']=='9cbb187a586eade1326090b2ef81bd69bd352e621d3acfc5ace1e72c4283ec4a'and a.endswith(bytes([10,10,10]))and b==a[:-2]and self.read(self.adopt['target'],self.adopt['candidate']['sha256'])==b,'FIELD_ALL_BYTES_EXACT_ONLY_TWO_FINAL_LF_REMOVED')
  need(len(self.backup['adoption_backups'])==2,'TWO_FULL_FIELD_BACKUPS')
  for r in self.backup['adoption_backups']:need(self.read(r['backup'],r['sha256'])in [a,b]and r['sha256']in [self.adopt['parent']['sha256'],self.adopt['candidate']['sha256']],'FIELD_BACKUPS_EXACT_LOCKED_OR_CURRENT')
"""
t=t[:at]+addition+t[at:]
a="need(path in self.parents and c['old']==self.parents[path]['old_sha256']and h==self.spec['declared_candidates'][path]['sha256'],'EXISTING_SOURCE_EXACT_CURRENT_TARGET')"
b="need((path in self.parents or path==self.adopt['target']) and c['old']==(self.adopt['parent']['sha256']if path==self.adopt['target']else self.parents[path]['old_sha256'])and h==self.spec['declared_candidates'][path]['sha256'],'EXISTING_SOURCE_EXACT_CURRENT_TARGET_OR_LOCKED_FIELD_ADOPTION')"
assert a in t;t=t.replace(a,b)
a="  trial=self.read_json_input('trial');need(trial['admitted']is True and trial['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'and trial['actual_Field_pass']is False and self.inputs['trial']['path']==PREFIX+'finish8_ROOT_TRIAL_PERMISSION02.json'and self.inputs['trial']['sha256']=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','TRIAL_PERMISSION_NOT_RESULT')"
b="  need(self.inputs['backup']['sha256']==self.bundle['root_backup']['sha256'] and self.backup['scope']['sha256']==self.inputs['scope']['sha256'],'ROOT_EXACT24_PLUS_FIELD_ADOPTION_BACKUP_NOT_FIELD_RESULT')"
assert a in t;t=t.replace(a,b)
a="   for p,t in self.targets.items():"
b="""   if self.adopt['target']in expected:
    need(expected[self.adopt['target']]==self.adopt['parent']['sha256'],'MAP_LOCKED_FIELD_PREDECESSOR');expected[self.adopt['target']]=self.adopt['candidate']['sha256']
   for p,t in self.targets.items():"""
assert a in t;t=t.replace(a,b)
t=t.replace("receipt=dict(status='FIELD_EOF_ADOPTION_EXACT24_STAGED_NOT_DEPLOYED',","receipt=dict(status='FIELD_EOF_ADOPTION_EXACT24_STAGED_NOT_DEPLOYED',adopted_Field=self.adopt,Field_writes=0,")
compile(t,'stage_Field_EOF_adoption24_ROOT_ONLY.py','exec');driver=emit(S+'stage_Field_EOF_adoption24_ROOT_ONLY.py',t.encode())
aa=parent.decode().splitlines(True);bb=t.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=t
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==t and v.encode()==parent
proof=emit(P+'Stage24_transport_inverse_NOT_STAGE.json',enc(dict(parent=parentpin,candidate=driver,hunks=hs,whole_UTF8_inverse=True,only_exact_Field_adoption_not_runtime_waiver=True,Stage_calls=0,engine_calls=0)))
pins=[dict(id='driver',**driver),dict(id='candidates',**bp),dict(id='scope',**bundle['scope']),dict(id='backup',**bundle['root_backup']),dict(id='execution',**bundle['execution']['candidate']),dict(id='authority_helper',**bundle['authority_helper']),dict(id='publication',**bundle['publication']),dict(id='parent_stage',**bundle['parent_stage']),dict(id='function_proof',**bundle['function_proof']),dict(id='code',**bundle['code_proof'])]
gates=[]
for i,g in enumerate(bundle['old_required_gates']):
 k='gate_'+str(i);pins.append(dict(id=k,**g['pin']));gates.append(dict(id=g['id'],input=k,pointer=g['pointer'],equals=g['equals']))
gates.append(dict(id='root_target_preauthorization',input='backup',pointer=['passed'],equals=True))
declared={r['target']:r['candidate']for r in bundle['targets']};declared[F]=bundle['adopted_Field']['candidate']
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=S+'outputs/root_Field_EOF_adoption_exact24_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'])for r in bundle['targets']],declared_candidates=declared,five_owned_targets=bundle['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
# Existing finite declaration preflight only; no Stage instance or collector.
assert len(bundle['targets'])==24 and F not in {r['target']for r in bundle['targets']}
fixed=dict(load(bundle['parent_stage'])['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256']);fixed.update({p:r['sha256']for p,r in declared.items()})
ct=load(bundle['contract']['candidate'])['source_sha256'];tb=load(bundle['temple_binding']['candidate']);tp=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));ts={**tp['source_sha256'],**tb['source_delta']};assert len(ct)==26 and len(ts)==196
for table in [ct,ts]:
 for p,h in table.items():assert fixed[p]==h,(p,h,fixed.get(p))
inp=emit(P+'source_input_Field_EOF_adoption24_ROOT_REVIEW.json',enc(spec));print(json.dumps(dict(driver=driver,input=inp,proof=proof,adopted_Field=bundle['adopted_Field']['candidate'],maps={k:r['count']for k,r in bundle['maps'].items()})))
