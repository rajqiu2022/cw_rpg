"""Mechanical transport of reviewed31 Stage; finite declarations only, never execute Stage."""
from pathlib import Path
import hashlib,json,sys
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'market_living_street_repair01/';O=N/'market_living_street_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
parent=(N/'stage_Estate_wall_source31_ROOT_ONLY.py').read_bytes();assert sha(parent)=='eb66ddaca52e73871948d3718295291b7e00ac97fa782ca2870bbb73b7ea42b5';t=parent.decode();hs=[]
def change(a,b):
 global t
 assert t.count(a)==1,(a[:80],t.count(a));t=t.replace(a,b,1);hs.append(dict(old=a,new=b))
changes=[('Root-only0860 exact31 successor: Estate helper two type/scale hunks and Yamen existing wall texture tuple; Field receipt two lines retained. No engine/canonical writes.','Root-only AAF exact31 Market six-instance data/material successor. All C/Field/Router algorithms and pawnshop functions unchanged. No engine/canonical writes.'),('EstateWall31','MarketStreet31'),('ROOT_CURRENT_0860_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_AAF_FULL31_BACKUP_AND_FRESH_OBSERVATION'),("self.backup['total_backups']==492","self.backup['total_backups']==595"),('ROOT_ACTUAL_0860_BACKUP31','ROOT_ACTUAL_AAF_BACKUP31'),("len(self.backup['current36'])==36","len(self.backup['current37'])==37"),("self.backup['current36']","self.backup['current37']"),('CURRENT36_NOOP_G_AUTHORITY_PRESERVED','CURRENT37_NOOP_PAWN_G_AUTHORITY_PRESERVED'),('CURRENT36_IMMUTABLE_PARENT','CURRENT37_IMMUTABLE_PARENT'),('Estate_wall_source_repair01/root_only_current31_backup/','market_living_street_repair01/root_only_current31_backup/'),("len(prior['source_sha256'])==229 and len(self.authority['source_sha256'])==235","len(prior['source_sha256'])==246 and len(self.authority['source_sha256'])==252"),('OWNED10_229_PLUS6_EQUALS235','OWNED10_246_PLUS6_EQUALS252'),('ALL_OLD229_FIXED_SIX_NEW','ALL_OLD246_FIXED_SIX_NEW'),("PREFIX+'finish8_ROOT_TRIAL_PERMISSION02.json'","PREFIX+'finish8_ROOT_TRIAL_PERMISSION04.json'"),('7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','273434a5e551f8ff755c3beccb02d21227a3e6283d1dc56521527dce3cd24d36'),('PINNED_CURRENT0860_MAP_PARENT','PINNED_CURRENT_AAF_MAP_PARENT'),('ESTATE_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','MARKET_SIX_INSTANCE_SOURCE_EXACT31_STAGED_NOT_DEPLOYED'),('Pinned0860/773E exact31 successor. All owned10/old229 values and edges retained plus6 proofs=235 and4 real owned edges. Only Estate helper two type/scale hunks and Yamen three existing texture leaves admitted; Field preserves original0860 two receipt lines with pure source pointers. Runtime functions, Router, payloads, masks, geometry and actors unchanged; CT26/Temple196 prospective checks retained.','Pinned AAF exact31 successor. All owned10/old246 values and edges retained plus6 proofs=252 and4 real owned edges. Only Market six-instance payload/mask and existing-purpose material data change; all C/Field/Router and pawnshop functions unchanged. Runtime only SELF/BIND headers; CT26/Temple196 prospective checks retained. New six-body publication is finite source-component credit, not actual Field or whole-city ART pass.')]
changes=[("for r in self.backup['current36']:need","for r in self.backup['current37']:need") if a=="self.backup['current36']" else (a,b) for a,b in changes]
for a,b in changes:
 if a=='EstateWall31':assert t.count(a)==2;t=t.replace(a,b);hs.append(dict(old=a,new=b,count=2))
 else:change(a,b)
marker="  for p,r in self.bundle['records'].items():"
extra="""  seal=self.read_json_input('seal');binding=json.loads(self.read(seal['binding']['path'],seal['binding']['sha256']));prior_binding=json.loads(self.read(seal['binding_inverse']['parent']['path'],seal['binding_inverse']['parent']['sha256']));market=binding['scenes']['ch4_s3_luoyang_market']
  need(market['trial']['path']==self.inputs['trial']['path'] and market['trial']['sha256']==self.inputs['trial']['sha256'] and market['required_source_sha256'].get(self.inputs['trial']['path'])==self.inputs['trial']['sha256'],'MARKET_ACTUAL_ROOT04_BOUND')
  need(all(binding['scenes'][id]==prior_binding['scenes'][id]for id in binding['scenes']if id!='ch4_s3_luoyang_market'),'OTHER_SEVEN_BIND_ROWS_IDENTICAL')
  finite=self.read_json_input('market_publication');need(finite['passed']is True and finite['checks']==741 and not finite['errors'] and len(finite['added_ids'])==6 and finite['effective_navigation_count']==55 and finite['effective_solids_count']==69 and market['payload']==finite['payload'] and market['fingerprints']==finite['fingerprints'],'EXACT_ACTUAL_FINITE_MARKET_PUBLICATION')
  for p,r in self.bundle['records'].items():"""
change(marker,extra)
back=t
for h in reversed(hs):assert back.count(h['new'])==h.get('count',1);back=back.replace(h['new'],h['old'])
assert back.encode()==parent;compile(t,'stage_market_living_street31_ROOT_ONLY.py','exec')
driverpath=S+'stage_market_living_street31_ROOT_ONLY.py';db=t.encode();dest=N/'stage_market_living_street31_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(db)
proof=dict(parent=dict(path=S+'stage_Estate_wall_source31_ROOT_ONLY.py',sha256=sha(parent)),driver=dict(path=driverpath,sha256=sha(db)),hunks=hs,whole_byte_inverse=True,unchanged_Core_F120_metadata_26_196_gates=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
with(O/'Stage31_driver_whole_inverse_NOT_STAGE.json').open('xb')as f:f.write(enc(proof))
bp=O/'unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json';bh=sha(bp.read_bytes());b=json.loads(bp.read_bytes())
t=(N/'prepare_gallery_family_Stage_input32_NOTENGINE.py').read_text(encoding='utf8')
changes=[("P=S+'docks_gallery_family_repair01/'","P=S+'market_living_street_repair01/'"),('unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('stage_gallery_family32_ROOT_ONLY.py','stage_market_living_street31_ROOT_ONLY.py'),('d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af',sha(db)),('root_gallery_family_ferry_exact32_stage01/','root_market_living_street_exact31_stage01/'),('len(targets)==32','len(targets)==31'),('len(patchproof)==18','len(patchproof)==17'),('M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new)','M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new)'),('EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE','EXACT31_MARKET_DATA_SOURCE_INVERSE_NOT_STAGE'),('count=32,partition=dict(GD=18,JSON=14)','count=31,partition=dict(GD=17,JSON=14)'),('old195_all_values_edges_preserved_plus7','old246_all_values_edges_preserved_plus6'),("N/'docks_gallery_family_repair01'/name","N/'market_living_street_repair01'/name"),('source_input_gallery_family32_ROOT_REVIEW.json','source_input_market_living_street31_ROOT_REVIEW.json'),('finite_preStage32_source_inverse_READONLY.json','finite_preStage31_source_inverse_READONLY.json')]
for a,c in changes:assert a in t,a;t=t.replace(a,c)
marker="gates=[]"
extra="pins.append(dict(id='seal',**b['seal']));pins.append(dict(id='market_publication',**load(b['seal'])['Market_publication']))\ngates=[]"
assert t.count(marker)==1;t=t.replace(marker,extra)
marker="audit=dict(status='EXACT31_MARKET_DATA_SOURCE_INVERSE_NOT_STAGE'"
extra="""parent_stage=load(b['parent_stage']);fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
for p,r in targets.items():fixed[p]=r['candidate']['sha256']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newbytes[CT]);assert len(ct['source_sha256'])==26
tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(merged)==196
for table in [ct['source_sha256'],merged]:
 for p,h in table.items():assert fixed[p]==h,('EXACT_PROSPECTIVE_PIN',p,h,fixed.get(p))
audit=dict(status='EXACT31_MARKET_DATA_SOURCE_INVERSE_NOT_STAGE'"""
assert t.count(marker)==1;t=t.replace(marker,extra)
oldargv=sys.argv;sys.argv=['derived','--descriptor-sha256',bh]
try:exec(compile(t,str(N/'prepare_market_living_street31_input_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_market_living_street31_input_DERIVED_NOTENGINE.py')})
finally:sys.argv=oldargv
print(json.dumps(dict(driver=proof['driver'],descriptor=dict(path=B+'unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256=bh),driver_proof_sha256=sha(enc(proof)))))
