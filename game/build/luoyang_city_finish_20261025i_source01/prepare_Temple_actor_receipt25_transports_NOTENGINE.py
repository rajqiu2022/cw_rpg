"""Reuse existing Root-only backup/Stage/finite preflight transports. Does not execute any of them."""
from pathlib import Path
import argparse,copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'Temple_actor_receipt_repair01/';O=N/'Temple_actor_receipt_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return json.loads(b)
def emit(name,b):
 p=O/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 pin=dict(path=B+name,sha256=sha(b),bytes=len(b));print(json.dumps(pin));return pin
SCOPE=dict(path=B+'current_E53E_exact25_scope_PREPARATION.json',sha256='f3736e4206935a35f5055bf0d7518f2ef1941e554329e7e6e828a29ba676e974')
RAW=dict(path=B+'unified25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='f862654ef6011332b7b0add6b17efee4a44f2db9f11f981692bdd9588693e532')
def prepare():
 scope=load(SCOPE);dep=load(scope['parent_actual']);old=load(dict(path=S+'visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_ACTUAL.json',sha256='2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3'))
 frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in old['frozen2121_current_facts']}
 def key(p):return str(G/p[6:]if p.startswith('res://')else Path(p)).replace('\\','/').casefold()
 lookup={key(p):p for p in frozen};current={r['target']:copy.deepcopy(r)for r in old['current34']};assert len(frozen)==2121
 for r in dep['targets']:
  f=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']);p=lookup.get(key(r['target']))
  if p is not None:frozen[p]=f
  current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=f)
 assert len(current)==36
 allbacks=copy.deepcopy(old['old403_backup_facts'])+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in old['new_backups']];assert len(allbacks)==436
 rows=[dict(**r,backup=B+'root_only_current25_backup/'+r['target'][6:])for r in scope['targets']]
 plan=dict(status='ROOT_ONLY_CURRENT_E53E_CREATE_NEW25_PLAN_NOT_EXECUTED',scope=SCOPE,parent_deployment=scope['parent_actual'],current25=rows,current36=list(current.values()),frozen2121_expected=frozen,save15_expected=old['save15'],old436_backup_facts=allbacks,media125=old['media_facts'],ui=old['ui'],Root_only_backup_prefix=B+'root_only_current25_backup/',expected_old_backup_total=436,expected_after_backup_total=461,canonical_writes=0,engine_calls=0)
 emit('current_E53E_backup25_ROOT_PLAN.json',enc(plan))
 parent=(N/'visible_doors_boundaries33_repair01/backup_current_signed31_33_ROOT_ONLY.py').read_bytes();t=parent.decode();changes=[]
 for a,b in [('CreateNew33','CreateNew25'),('visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_PLAN.json','Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_PLAN.json'),('--root-authorized-backup33','--root-authorized-backup25'),('root_authorized_backup33','root_authorized_backup25'),('current34','current36'),('current33','current25'),('old403','old436'),('NEW33_BACKUP_MUST_BE_ABSENT','NEW25_BACKUP_MUST_BE_ABSENT'),('ROOT_CURRENT_SIGNED31_FULL33_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_E53E_FULL25_BACKUP_AND_FRESH_OBSERVATION'),('ROOT_CURRENT_SIGNED31_FRESH_OBSERVATION_ONLY','ROOT_CURRENT_E53E_FRESH_OBSERVATION_ONLY'),('403+len(rows)','436+len(rows)')]:
  assert a in t,a;t=t.replace(a,b);changes.append(dict(old=a,new=b))
 back=t
 for h in reversed(changes):back=back.replace(h['new'],h['old'])
 assert back.encode()==parent;compile(t,'backup_current_E53E_25_ROOT_ONLY.py','exec')
 tool=emit('backup_current_E53E_25_ROOT_ONLY.py',t.encode());emit('backup_tool_mechanical_inverse_NOT_EXECUTED.json',enc(dict(parent_sha256=sha(parent),candidate=tool,changes=changes,whole_byte_inverse=True,backup_copy_calls=0,canonical_writes=0)))
 parent=(N/'stage_culture_Router_pin24_ROOT_ONLY.py').read_bytes();t=parent.decode();hs=[]
 def change(a,b):
  nonlocal t
  assert t.count(a)==1,(a[:100],t.count(a));t=t.replace(a,b,1);hs.append(dict(old=a,new=b))
 for a,b in [('class CulturePin24(M.Stage):','class TempleReceipt25(M.Stage):'),("self.scope['count']==len(self.parents)==24 and self.scope['partition']==dict(GD=10,JSON=14)","self.scope['count']==len(self.parents)==25 and self.scope['partition']==dict(GD=11,JSON=14)"),('ROOT_CURRENT_D581_FULL24_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_E53E_FULL25_BACKUP_AND_FRESH_OBSERVATION'),("self.backup['total_backups']==341","self.backup['total_backups']==461"),('len(rows)==24','len(rows)==25'),("len(self.backup['current34'])==34","len(self.backup['current36'])==36"),("self.backup['current34']:","self.backup['current36']:"),('culture_Router_pin_repair01/root_only_current24_backup/','Temple_actor_receipt_repair01/root_only_current25_backup/'),("len(prior['source_sha256'])==202 and len(self.authority['source_sha256'])==206","len(prior['source_sha256'])==224 and len(self.authority['source_sha256'])==229"),('len(changed)==2','len(changed)==3'),('len(extra)==4','len(extra)==5'),("set(contract['changes'])=={'res://scripts/autoload/scene_router.gd'}","set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd'}"),("set(temple['changes'])=={'res://scripts/autoload/scene_router.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'}","set(temple['changes'])=={'res://scripts/field/field_walkable_controller.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'}"),('len(self.targets)==24','len(self.targets)==25'),('len(reconstruction)==24','len(reconstruction)==25'),('CULTURE_ROUTER_EXACT24_STAGED_NOT_DEPLOYED','TEMPLE_ACTOR_RECEIPT_EXACT25_STAGED_NOT_DEPLOYED'),('dict(patch_count=10,copy_count=14,total=24)','dict(patch_count=11,copy_count=14,total=25)'),('targets=24,map_nodes=4','targets=25,map_nodes=4'),('CulturePin24(spec).run()','TempleReceipt25(spec).run()')]:change(a,b)
 # Labels are descriptive only; no check relaxed. Keep original five gates and pin new02 explicitly.
 change("trial['actual_Field_pass']is False,'TRIAL_PERMISSION_NOT_RESULT'","trial['actual_Field_pass']is False and self.inputs['trial']['path']==PREFIX+'finish8_ROOT_TRIAL_PERMISSION02.json'and self.inputs['trial']['sha256']=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','TRIAL_PERMISSION_NOT_RESULT'")
 back=t
 for h in reversed(hs):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
 assert back.encode()==parent;compile(t,'stage_Temple_actor_receipt25_ROOT_ONLY.py','exec')
 driver=emit('stage_Temple_actor_receipt25_ROOT_ONLY.py',t.encode());emit('Stage25_driver_full_inverse_NOT_STAGE.json',enc(dict(parent=dict(path=S+'stage_culture_Router_pin24_ROOT_ONLY.py',sha256=sha(parent)),candidate=driver,hunks=hs,whole_byte_inverse=True,old_five_gates_F120_all224_values_edges_preserved=True,CT26_Temple196_all_prospective_checks=True,Stage_calls=0,canonical_writes=0)))
def audit_natural():
 b=load(RAW);targets={r['target']:r for r in b['targets']};assert len(targets)==25
 parent=load(b['parent_stage']);fixed=dict(parent['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256']);newraw={}
 for p,r in targets.items():
  before=(G/r['parent']['path'][6:]).read_bytes();after=(G/r['candidate']['path'][6:]).read_bytes()
  assert sha(before)==r['parent']['sha256']and len(before)==r['parent']['bytes']and sha(after)==r['candidate']['sha256']and len(after)==r['candidate']['bytes']and before!=after
  fixed[p]=r['candidate']['sha256'];newraw[p]=after
 CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newraw[CT]);tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(ct['source_sha256'])==26 and len(merged)==196
 for table in [ct['source_sha256'],merged]:
  for p,h in table.items():assert fixed[p]==h and sha(newraw[p]if p in newraw else(G/p[6:]).read_bytes())==h,('ALL222_FIXED_PROSPECTIVE',p)
 emit('CT26_Temple196_all_prospective_pins_READONLY.json',enc(dict(status='STATIC_CURRENT_E53E_PLUS_EXACT25_PROSPECTIVE_NOT_OBSERVATION',passed=True,parent_stage=b['parent_stage'],descriptor=RAW,CT_source_sha256=ct['source_sha256'],Temple_effective_source_sha256=merged,checked=222,Stage_calls=0,engine_calls=0,canonical_writes=0)))
 t=(N/'prepare_visible_doors_boundaries33_Temple_natural_NOTENGINE.py').read_text(encoding='utf8')
 for a,c in [('visible_doors_boundaries33_repair01/unified33_READY02/unified32_all_candidates_and_inverse_NOT_STAGE.json','Temple_actor_receipt_repair01/unified25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('7a774f70b33735ec1785920b05e0d9ad07ae89329f1d14aba9d06e3551e5478c',RAW['sha256']),('visible_doors_boundaries33_repair01/expected_Temple_natural_sources_READONLY.json','Temple_actor_receipt_repair01/expected_Temple_natural_sources_READONLY.json')]:assert a in t,a;t=t.replace(a,c)
 exec(compile(t,str(N/'prepare_Temple_actor_receipt25_natural_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_Temple_actor_receipt25_natural_DERIVED_NOTENGINE.py')})
def finalize(backupsha):
 b=load(RAW);backup=dict(path=B+'current_E53E_backup25_ROOT_ACTUAL.json',sha256=backupsha);v=load(backup);assert v['passed']and v['total_backups']==461 and v['external_save_changes']==[]and v['scope']==SCOPE and v['parent_deployment']==load(SCOPE)['parent_actual']
 b['root_backup']=backup;b['trial']=dict(path=S+'finish8_ROOT_TRIAL_PERMISSION02.json',sha256='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a');b['parent_current_guard']=dict(path=S+'visible_doors_boundaries33_repair01/post_116100_guard_ROOT_ACTUAL.json',sha256='350e13039ee44cd75931fb80b730f2f4de304d68763f523941e87105d7caabdf');guard=load(b['parent_current_guard']);assert guard['passed']and guard['differences']==[];bp=emit('unified25_READY01/unified25_ROOT_BACKUP_FIXED_NOT_STAGE.json',enc(b))
 # Reuse the already-reviewed full finite preStage data checks, not a Stage instance/run.
 t=(N/'prepare_gallery_family_Stage_input32_NOTENGINE.py').read_text(encoding='utf8');dp=B+'stage_Temple_actor_receipt25_ROOT_ONLY.py';dh=sha((G/dp[6:]).read_bytes())
 for a,c in [("P=S+'docks_gallery_family_repair01/'","P=S+'Temple_actor_receipt_repair01/'"),('unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','unified25_READY01/unified25_ROOT_BACKUP_FIXED_NOT_STAGE.json'),('stage_gallery_family32_ROOT_ONLY.py','Temple_actor_receipt_repair01/stage_Temple_actor_receipt25_ROOT_ONLY.py'),('d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af',dh),('root_gallery_family_ferry_exact32_stage01/','root_Temple_actor_receipt_exact25_stage01/'),('len(targets)==32','len(targets)==25'),('len(patchproof)==18','len(patchproof)==11'),('M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new)','M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new)'),('EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE','EXACT25_TEMPLE_RECEIPT_SOURCE_SEMANTICS_AND_INVERSE_NOT_STAGE'),('count=32,partition=dict(GD=18,JSON=14)','count=25,partition=dict(GD=11,JSON=14)'),('old195_all_values_edges_preserved_plus7','old224_all_values_edges_preserved_plus5'),("N/'docks_gallery_family_repair01'/name","N/'Temple_actor_receipt_repair01'/name"),('source_input_gallery_family32_ROOT_REVIEW.json','source_input_Temple_actor_receipt25_ROOT_REVIEW.json'),('finite_preStage32_source_inverse_READONLY.json','finite_preStage25_source_inverse_READONLY.json')]:assert a in t,a;t=t.replace(a,c)
 marker="audit=dict(status='EXACT25_TEMPLE_RECEIPT_SOURCE_SEMANTICS_AND_INVERSE_NOT_STAGE'"
 semantic="""parent_stage=load(b['parent_stage']);fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
for p,r in targets.items():fixed[p]=r['candidate']['sha256']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newbytes[CT]);assert len(ct['source_sha256'])==26
tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(merged)==196
for table in [ct['source_sha256'],merged]:
 for p,h in table.items():
  assert fixed[p]==h,('STRICT_ALL222_PROSPECTIVE_PIN',p,h,fixed.get(p))
  source=newbytes[p]if p in targets else(G/p[6:]).read_bytes();assert sha(source)==h
audit=dict(status='EXACT25_TEMPLE_RECEIPT_SOURCE_SEMANTICS_AND_INVERSE_NOT_STAGE'"""
 assert t.count(marker)==1;t=t.replace(marker,semantic)
 import sys
 oldargv=sys.argv;sys.argv=['derived','--descriptor-sha256',bp['sha256']]
 try:exec(compile(t,str(N/'prepare_Temple_actor_receipt25_input_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_Temple_actor_receipt25_input_DERIVED_NOTENGINE.py')})
 finally:sys.argv=oldargv
def driver_location():
 oldpath=B+'stage_Temple_actor_receipt25_ROOT_ONLY.py';newpath=S+'stage_Temple_actor_receipt25_ROOT_ONLY.py';raw=(G/oldpath[6:]).read_bytes();assert sha(raw)=='d90067b0d83a0624ad280c396cf5a677bac5bbc0526ed60d4c62759ee02dbda5'
 dest=G/newpath[6:];assert not dest.exists()
 with dest.open('xb')as f:f.write(raw)
 pin=dict(path=newpath,sha256=sha(raw),bytes=len(raw));oldinput=(O/'source_input_Temple_actor_receipt25_ROOT_REVIEW.json').read_bytes();assert sha(oldinput)=='ac4cac81b06a3ec8940d18fc96abf1d975825397122394c8e6fa9aafcf728e0d'and oldinput.count(oldpath.encode())==1
 newinput=oldinput.replace(oldpath.encode(),newpath.encode(),1);assert newinput.replace(newpath.encode(),oldpath.encode(),1)==oldinput
 v=json.loads(newinput);assert next(p for p in v['pinned_inputs']if p['id']=='driver')==dict(id='driver',path=newpath,sha256=pin['sha256'])
 inp=emit('source_input_Temple_actor_receipt25_ROOT_REVIEW02.json',newinput)
 emit('driver_location_transport_inverse_READONLY.json',enc(dict(status='ROOT_DRIVER_PLACED_AT_ORIGINAL_SAME_RELATIVE_GAME_DEPTH_NOT_STAGE',old_driver=dict(path=oldpath,sha256=sha(raw)),driver=pin,whole_driver_bytes_unchanged=True,old_input_sha256=sha(oldinput),input=inp,single_input_raw_literal_change=dict(old=oldpath,new=newpath),whole_input_byte_inverse=True,Stage_calls=0,canonical_writes=0)))
 print(json.dumps(dict(driver=pin,input=inp)))
def labels03():
 oldpath=S+'stage_Temple_actor_receipt25_ROOT_ONLY.py';newpath=S+'stage_Temple_actor_receipt25_ROOT_ONLY03.py';parent=(G/oldpath[6:]).read_bytes();assert sha(parent)=='d90067b0d83a0624ad280c396cf5a677bac5bbc0526ed60d4c62759ee02dbda5';t=parent.decode();hs=[]
 changes=[('Root-only current4160 Gate texture / Market portal exact31 source successor; no engine/canonical writes.','Root-only E53E exact25 Temple actor receipt successor; Field only two-line true top-level matched propagation. No engine/canonical writes.'),('EXACT24_10GD14JSON_SCOPE','EXACT25_11GD14JSON_SCOPE'),('ROOT_ACTUAL_CURRENT_AUTHORITY20_BACKUP32','ROOT_ACTUAL_E53E_BACKUP25'),('ROOT_BACKUP32_EXACT_DOMAIN','ROOT_BACKUP25_EXACT_DOMAIN'),('CURRENT33_NOOP_G_AUTHORITY_PRESERVED','CURRENT36_NOOP_G_AUTHORITY_PRESERVED'),('CURRENT33_IMMUTABLE_PARENT','CURRENT36_IMMUTABLE_PARENT'),('ROOT_BACKUP32_FIXED_NAMESPACE','ROOT_BACKUP25_FIXED_NAMESPACE'),('ROOT_FULL_BACKUP32_WHOLE_CURRENT_IMMUTABLE','ROOT_FULL_BACKUP25_WHOLE_CURRENT_IMMUTABLE'),('OWNED10_202_PLUS4','OWNED10_224_PLUS5_EQUALS229'),('ONLY_TWO_REAL_OWNED_EDGES','ONLY_THREE_REAL_OWNED_EDGES'),('OTHER_EIGHT_OWNED_IDENTICAL','OTHER_SEVEN_OWNED_IDENTICAL'),('ALL_OLD202_FIXED_FOUR_NEW','ALL_OLD224_FIXED_FIVE_NEW'),('ONLY_CT_ROUTER_ONE_LITERAL','ONLY_CT_FIELD_ONE_LITERAL'),('CONTRACT_TYPED_RAW_TWO_LITERAL_FULL_INVERSE','CONTRACT_TYPED_RAW_ONE_LITERAL_FULL_INVERSE'),('against fixed CE3E expected data','against fixed DC81 expected data'),('TEMPLE_ONLY_ROUTER_CT_COORDINATOR_SOURCE_VALUES','TEMPLE_ONLY_FIELD_CT_COORDINATOR_SOURCE_VALUES'),('EXACT24_NO_NOOP_TARGETS','EXACT25_NO_NOOP_TARGETS'),('PINNED_CURRENT_AUTHORITY20_MAP_PARENT','PINNED_CURRENT_E53E_MAP_PARENT'),('EXACT10_GD_PATCH14_JSON_COPY','EXACT11_GD_PATCH14_JSON_COPY'),('Pinned D581/CE3E exact current source counter increment only. All owned10/old202 values/edges preserved+4. CT full26 and Temple merged196 exact prospective source equality. No geometry/runtime/Router/Family/Field logic changes.','Pinned E53E/DC81 exact25 successor. All owned10/old224 values and edges preserved plus5 proofs=229 and3 real owned edges. Field only two-line true top-level matched-to-Temple-receipt propagation; CT26/Temple196 prospective checks preserved. Other runtime/Router/Family/geometry logic unchanged.')]
 for a,b in changes:assert t.count(a)==1,(a,t.count(a));t=t.replace(a,b,1);hs.append(dict(old=a,new=b))
 back=t
 for h in reversed(hs):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
 assert back.encode()==parent
 # AST normalized after restoring only literal strings/docstring/comments is the same source text byte-for-byte.
 compile(t,'stage_Temple_actor_receipt25_ROOT_ONLY03.py','exec');dest=G/newpath[6:];assert not dest.exists();raw=t.encode()
 with dest.open('xb')as f:f.write(raw)
 driver=dict(path=newpath,sha256=sha(raw),bytes=len(raw));oldinput=(O/'source_input_Temple_actor_receipt25_ROOT_REVIEW02.json').read_bytes();assert sha(oldinput)=='a555b25d2d455b6eb9f7eb4785537cc63d53b87b7157205eb57dcd4030561a6c'
 oldhash=sha(parent);assert oldinput.count(oldpath.encode())==1 and oldinput.count(oldhash.encode())==1;newinput=oldinput.replace(oldpath.encode(),newpath.encode(),1).replace(oldhash.encode(),driver['sha256'].encode(),1)
 assert newinput.replace(newpath.encode(),oldpath.encode(),1).replace(driver['sha256'].encode(),oldhash.encode(),1)==oldinput
 pin=emit('source_input_Temple_actor_receipt25_ROOT_REVIEW03.json',newinput)
 emit('driver_description03_whole_inverse_NOT_STAGE.json',enc(dict(status='ROOT_REQUESTED_DESCRIPTION_ONLY_SUCCESSOR_NOT_STAGE',parent=dict(path=oldpath,sha256=sha(parent)),driver=driver,description_literal_hunks=hs,whole_byte_inverse=True,verification_logic_and_expectations_unchanged=True,input=pin,input_raw_hunks=[dict(old=oldpath,new=newpath),dict(old=oldhash,new=driver['sha256'])],whole_input_byte_inverse=True,Stage_calls=0,canonical_writes=0)))
 print(json.dumps(dict(driver=driver,input=pin)))
def copy_guard():
 proof=[]
 for oldname,newname in [('copy_Market_ground25_JSON14_after_GD11_ROOT_ONLY.py','copy_Temple_actor_receipt25_JSON14_after_GD11_ROOT_ONLY.py'),('guard_Market_ground25_current2121_ROOT_ONLY.py','guard_Temple_actor_receipt25_current2121_ROOT_ONLY.py')]:
  parent=(N/oldname).read_bytes();t=parent.decode();hs=[]
  def change(a,b):
   nonlocal t
   assert a in t,a;t=t.replace(a,b);hs.append(dict(old=a,new=b))
  for a,b in [('market_ground_texture_repair02/current5D6C_exact25_scope_PREPARATION.json','Temple_actor_receipt_repair01/current_E53E_exact25_scope_PREPARATION.json'),('a0f69caeec43fc22c0edf9af4898375aa2404b7c945873783bad201ba3624fa5','f3736e4206935a35f5055bf0d7518f2ef1941e554329e7e6e828a29ba676e974'),('market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json','Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_ACTUAL.json'),('c0a57be99104c703df9ef876a7168821497a448242c2acc86457acae4c32169a','6cbdb68683733bc819978936225476bf4bf5ff16b2efb7f01b05a7af23b9e6bf'),('MARKET_AE_TEXTURE_EXACT25_STAGED_NOT_DEPLOYED','TEMPLE_ACTOR_RECEIPT_EXACT25_STAGED_NOT_DEPLOYED'),('ROOT_MARKET_AE25','ROOT_TEMPLE_ACTOR_RECEIPT25'),('old240','old436')]:
   if a in t:change(a,b)
  if oldname.startswith('copy'):
   for a,b in [('current4160 immutable parent','current E53E immutable parent; only Temple receipt bridge logic plus source pins'),("backup['total_backups']==265","backup['total_backups']==461"),("backup['current32']","backup['current36']"),('backup_count=265','backup_count=461'),('current5D6C_backup_sha256','current_E53E_backup_sha256')]:change(a,b)
  else:
   for a,b in [('market_ground25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','Temple_actor_receipt_repair01/unified25_READY01/unified25_ROOT_BACKUP_FIXED_NOT_STAGE.json'),('c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4','71b482ffa28debabfe7c3ed39b77d266745cdbda5b24dbdad41de88344c18549'),('all113_media_exactticks','all125_media_exactticks'),('backups_total=265','backups_total=461'),('tasks_preexisting_1D33_preserved_not_reauthorized','tasks_Root_authorized_F1C1_preserved')]:change(a,b)
   change(" check(backup['ui']['path'],backup['ui'],'UI')"," check(backup['ui']['path'],backup['ui'],'UI')\n for r in backup['current36']:\n  p=r['target'];check(p,dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p in actual else r['current'],'current36')")
  marker=" stage=load(a.stage,a.stage_sha256);"
  if marker in t:change(marker," stage=load(a.stage,a.stage_sha256);assert stage['source_first'].get(S+'finish8_ROOT_TRIAL_PERMISSION02.json')=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a';")
  back=t
  for h in reversed(hs):back=back.replace(h['new'],h['old'])
  assert back.encode()==parent;compile(t,newname,'exec');dest=N/newname;assert not dest.exists()
  with dest.open('xb')as f:f.write(t.encode())
  pin=dict(path=S+newname,sha256=sha(t.encode()),bytes=len(t.encode()));proof.append(dict(parent=dict(path=S+oldname,sha256=sha(parent)),candidate=pin,changes=hs,whole_byte_inverse=True));print(json.dumps(pin))
 emit('copy_guard_mechanical_source_changes_NOT_EXECUTED.json',enc(dict(status='ROOT_ONLY_TRANSPORTS_NOT_EXECUTED',proofs=proof,canonical_writes=0,guard_calls=0,engine_calls=0,Stage_calls=0)))
ap=argparse.ArgumentParser();ap.add_argument('--backup-sha256');ap.add_argument('--audit-natural',action='store_true');ap.add_argument('--fix-driver-location',action='store_true');ap.add_argument('--labels03',action='store_true');ap.add_argument('--copy-guard',action='store_true');a=ap.parse_args()
if a.backup_sha256:finalize(a.backup_sha256)
elif a.audit_natural:audit_natural()
elif a.fix_driver_location:driver_location()
elif a.labels03:labels03()
elif a.copy_guard:copy_guard()
else:prepare()
