"""Root actual backup seal + data-only preflight/input; no Stage instance/run."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'temple_signed_iid_repair01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
source=N/'temple_signed_iid_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json';raw=source.read_bytes();assert sha(raw)=='12c4fe72c45a935cf317f9d9ffcafbc6dc0c46a780964644e247928805b8be72';b=json.loads(raw)
backup=dict(path=P+'current_377B_backup31_ROOT_ACTUAL.json',sha256='8e8f484f0f9b0531969b4e227b5f71abd818dc4935fd568890ad79501bb76026')
actualraw=(G/backup['path'][6:]).read_bytes();assert sha(actualraw)==backup['sha256'];actual=json.loads(actualraw);assert actual['passed'] and actual['total_backups']==403 and len(actual['new_backups'])==31 and actual['differences']==[] and actual['external_save_changes']==[]
b['root_backup']=backup
dest=source.with_name('unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json')
with dest.open('xb')as stream:stream.write(enc(b))
finalpin=dict(path=P+'unified31_READY01/'+dest.name,sha256=sha(enc(b)),bytes=len(enc(b)))
proof=dict(status='DESCRIPTOR_BACKUP_ONLY_MECHANICAL_ROOT_ACTUAL_SEAL_NOT_STAGE',parent=dict(path=S+source.relative_to(N).as_posix(),sha256=sha(raw)),candidate=finalpin,changed_pointer=['root_backup'],old=json.loads(raw)['root_backup'],new=backup,all_other_values_unchanged=True,actual_Field_pass=False)
with(N/'temple_signed_iid_repair01/descriptor_backup_only_inverse_READONLY.json').open('xb')as stream:stream.write(enc(proof))

t=(N/'prepare_gallery_family_Stage_input32_NOTENGINE.py').read_text(encoding='utf8')
for a,c in [
 ("P=S+'docks_gallery_family_repair01/'","P=S+'temple_signed_iid_repair01/'"),
 ('unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json'),
 ('stage_gallery_family32_ROOT_ONLY.py','stage_signed_Temple31_ROOT_ONLY.py'),
 ('d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af','c5b64d27b14f3a79936ae1fb1dbaf739b4dad9807cc0ab8e30904c34175125b8'),
 ('root_gallery_family_ferry_exact32_stage01/','root_signed_Temple_exact31_stage01/'),
 ('len(targets)==32','len(targets)==31'),('len(patchproof)==18','len(patchproof)==17'),
 ('M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new)','M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new)'),
 ('EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE','EXACT31_SIGNED_TEMPLE_CT26_TEMPLE196_INVERSE_NOT_STAGE'),
 ('count=32,partition=dict(GD=18,JSON=14)','count=31,partition=dict(GD=17,JSON=14)'),
 ('old195_all_values_edges_preserved_plus7','old212_all_values_edges_preserved_plus6'),
 ("N/'docks_gallery_family_repair01'/name","N/'temple_signed_iid_repair01'/name"),
 ('source_input_gallery_family32_ROOT_REVIEW.json','source_input_signed_Temple31_ROOT_REVIEW.json'),
 ('finite_preStage32_source_inverse_READONLY.json','finite_preStage31_source_semantics_inverse_READONLY.json'),
]:assert a in t,a;t=t.replace(a,c)
marker="audit=dict(status='EXACT31_SIGNED_TEMPLE_CT26_TEMPLE196_INVERSE_NOT_STAGE'"
semantic="""parent_stage=load(b['parent_stage']);fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
for p,r in targets.items():fixed[p]=r['candidate']['sha256']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newbytes[CT]);assert len(ct['source_sha256'])==26
tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(merged)==196
semantic_rows={}
for name,table in [('CT26',ct['source_sha256']),('Temple196',merged)]:
 semantic_rows[name]=[]
 for p,h in table.items():
  assert fixed[p]==h,('STRICT_CONSUMER_NOT_PROSPECTIVE_CURRENT',name,p,h,fixed.get(p))
  source=newbytes[p]if p in targets else(G/p[6:]).read_bytes();assert sha(source)==h,('STRICT_PHYSICAL_FIXED_SOURCE',name,p)
  semantic_rows[name].append(dict(path=p,expected=h,source='declared_candidate'if p in targets else'fixed_377B_unchanged'))
semantics=dict(status='ALL_CT26_TEMPLE196_EXACT_PROSPECTIVE_SIGNED_TEMPLE_PINS_READONLY',passed=True,tables=semantic_rows,no_historical_fallback=True,no_observed_expected_fill=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
semdest=N/'temple_signed_iid_repair01/CT26_Temple196_all_prospective_pins_READONLY.json'
with semdest.open('xb')as stream:stream.write(enc(semantics))
print(semdest.name,sha(enc(semantics)),len(enc(semantics)))
audit=dict(status='EXACT31_SIGNED_TEMPLE_CT26_TEMPLE196_INVERSE_NOT_STAGE'"""
assert t.count(marker)==1;t=t.replace(marker,semantic)
# Set argparse only for this preparation module, not Stage.
import sys
sys.argv=[str(N/'prepare_signed_Temple_final_input_DERIVED_NOTENGINE.py'),'--descriptor-sha256',finalpin['sha256']]
exec(compile(t,sys.argv[0],'exec'),{'__file__':sys.argv[0]})
print('FINAL_DESCRIPTOR',json.dumps(finalpin))
