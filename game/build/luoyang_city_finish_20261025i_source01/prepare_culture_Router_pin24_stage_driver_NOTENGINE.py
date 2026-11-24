"""Thin necessary24 Stage recipe plus exact semantic CT26/Temple196 pin checks. No Stage call."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;parent=(N/'stage_gallery_family32_ROOT_ONLY.py').read_bytes();t=parent.decode();hunks=[]
def change(a,b):
 global t
 assert t.count(a)==1,(a[:100],t.count(a));t=t.replace(a,b,1);hunks.append(dict(old=a,new=b))
for a,b in [
 ('class GalleryFamily32(M.Stage):','class CulturePin24(M.Stage):'),
 ("M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745',13)}\n",'# Router is an exact unchanged parent this epoch; no EOL transport is needed.\n'),
 ("self.scope['count']==len(self.parents)==32 and self.scope['partition']==dict(GD=18,JSON=14),'EXACT32_18GD14JSON_SCOPE'","self.scope['count']==len(self.parents)==24 and self.scope['partition']==dict(GD=10,JSON=14),'EXACT24_10GD14JSON_SCOPE'"),
 ('ROOT_CURRENT_AUTHORITY20_FULL32_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_D581_FULL24_BACKUP_AND_FRESH_OBSERVATION'),
 ("self.backup['total_backups']==317","self.backup['total_backups']==341"),
 ("len(rows)==32 and {r['target']for r in rows}==set(self.parents)","len(rows)==24 and {r['target']for r in rows}==set(self.parents)"),
 ("len(self.backup['current33'])==33","len(self.backup['current34'])==34"),
 ("self.backup['current33']:","self.backup['current34']:"),
 ("docks_gallery_family_repair01/root_only_current32_backup/","culture_Router_pin_repair01/root_only_current24_backup/"),
 ("len(prior['source_sha256'])==195 and len(self.authority['source_sha256'])==202,'OWNED10_195_PLUS7'","len(prior['source_sha256'])==202 and len(self.authority['source_sha256'])==206,'OWNED10_202_PLUS4'"),
 ("len(changed)==5,'ONLY_FIVE_REAL_OWNED_EDGES'","len(changed)==2,'ONLY_TWO_REAL_OWNED_EDGES'"),
 ('OTHER_FIVE_OWNED_IDENTICAL','OTHER_EIGHT_OWNED_IDENTICAL'),
 ('len(extra)==7 and all','len(extra)==4 and all'),('ALL_OLD195_FIXED_SEVEN_NEW','ALL_OLD202_FIXED_FOUR_NEW'),
 ("set(contract['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd'},'ONLY_C_FIELD_TWO_CONTRACT_VALUES'","set(contract['changes'])=={'res://scripts/autoload/scene_router.gd'},'ONLY_CT_ROUTER_ONE_LITERAL'"),
 ("len(self.targets)==32,'EXACT32_NO_NOOP_TARGETS'","len(self.targets)==24,'EXACT24_NO_NOOP_TARGETS'"),
 ('M.build_file_patch(res(p).as_posix(),before,after)','M._strict_lf_build_file_patch(res(p).as_posix(),before,after)'),
 ("len(reconstruction)==32,'EXACT18_GD_PATCH14_JSON_COPY'","len(reconstruction)==24,'EXACT10_GD_PATCH14_JSON_COPY'"),
 ('GALLERY_FAMILY_ROUTER_EXACT32_STAGED_NOT_DEPLOYED','CULTURE_ROUTER_EXACT24_STAGED_NOT_DEPLOYED'),
 ('dict(patch_count=18,copy_count=14,total=32)','dict(patch_count=10,copy_count=14,total=24)'),
 ('targets=32,map_nodes=4','targets=24,map_nodes=4'),
 ('GalleryFamily32(spec).run()','CulturePin24(spec).run()'),
 ('Pinned authority20/1BC99 increment. All OWNED10/old195 proof values and edges preserved+7. F120 bounded registered edges/visited. No shortcut. Only gallery/four posts local delta, ferry contract, exact3 Router and strict Family cold abort.','Pinned D581/CE3E exact current source counter increment only. All owned10/old202 values/edges preserved+4. CT full26 and Temple merged196 exact prospective source equality. No geometry/runtime/Router/Family/Field logic changes.'),
]:change(a,b)
marker="  for p,r in self.bundle['metadata'].items():self.verify_metadata(p,r)"
semantic="""  # These consumers do NOT accept EX historical pins. Verify every semantic source
  # against fixed CE3E expected data plus declared prospective targets, never observed SHA.
  parent_stage=self.read_json_input('parent_stage');fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
  for p,pin in self.spec['declared_candidates'].items():fixed[p]=pin['sha256']
  need(len(value['source_sha256'])==26,'CT_EXACT_ALL26_SOURCE_DOMAIN')
  for p,h in value['source_sha256'].items():need(fixed.get(p)==h,'CT_ALL26_EXACT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
  temple=self.bundle['temple_binding'];tb=json.loads(self.read(temple['candidate']['path'],temple['candidate']['sha256']))
  old_tb=json.loads(self.read(temple['parent']['path'],temple['parent']['sha256']));parent_tb=json.loads(self.read(tb['parent_binding_path'],tb['parent_binding_sha256']))
  need(set(temple['changes'])=={'res://scripts/autoload/scene_router.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'},'TEMPLE_ONLY_ROUTER_CT_COORDINATOR_SOURCE_VALUES')
  reconstructed=json.loads(self.read(temple['parent']['path'],temple['parent']['sha256']));raw_tb=self.read(temple['parent']['path'],temple['parent']['sha256'])
  for p,c in temple['changes'].items():
   need(reconstructed['source_delta'][p]==c['old']and raw_tb.count((json.dumps(p)+': '+json.dumps(c['old'])).encode())==1,'TEMPLE_EXACT_OLD_SOURCE_LITERAL')
   reconstructed['source_delta'][p]=c['new'];raw_tb=raw_tb.replace((json.dumps(p)+': '+json.dumps(c['old'])).encode(),(json.dumps(p)+': '+json.dumps(c['new'])).encode(),1)
  need(same(reconstructed,tb)and raw_tb==self.read(temple['candidate']['path'],temple['candidate']['sha256']),'TEMPLE_ALL_OTHER_TYPED_BYTES_UNCHANGED')
  merged={**parent_tb['source_sha256'],**tb['source_delta']};need(len(merged)==196,'TEMPLE_EXACT196_MERGED_SOURCE_DOMAIN')
  for p,h in merged.items():need(fixed.get(p)==h,'TEMPLE_ALL196_EXACT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
  for p,r in self.bundle['metadata'].items():self.verify_metadata(p,r)"""
change(marker,semantic)
back=t
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(t,'stage_culture_Router_pin24_ROOT_ONLY.py','exec')
sha=lambda b:hashlib.sha256(b).hexdigest();child=t.encode();proof=dict(status='NECESSARY_CT_ROUTER24_THIN_DRIVER_FULL_INVERSE_NOT_STAGE',parent_sha256=sha(parent),candidate_sha256=sha(child),hunks=hunks,whole_byte_inverse=True,all_original_edge_source_classification_five_gates_preserved=True,extra_strict_CT26_Temple196_semantic_source_current_checks=True,no_historical_fallback_for_CT_or_Temple=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
for f,b in [('stage_culture_Router_pin24_ROOT_ONLY.py',child),('culture_Router_pin_repair01/Stage24_driver_full_inverse_NOT_STAGE.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())]:
 p=N/f;assert not p.exists()
 with p.open('xb')as w:w.write(b)
 print(f,sha(b),len(b))
