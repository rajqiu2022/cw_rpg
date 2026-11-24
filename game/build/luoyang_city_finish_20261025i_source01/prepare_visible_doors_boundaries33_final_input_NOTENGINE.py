"""Root actual backup binding and finite raw/typed/source preflight; no Stage object."""
from pathlib import Path
import copy,hashlib,json,sys
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'visible_doors_boundaries33_repair01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
source=N/'visible_doors_boundaries33_repair01/unified33_READY02/unified32_all_candidates_and_inverse_NOT_STAGE.json'
raw=source.read_bytes();assert sha(raw)=='7a774f70b33735ec1785920b05e0d9ad07ae89329f1d14aba9d06e3551e5478c'
b=json.loads(raw)
backup=dict(path=B+'current_signed31_backup33_ROOT_ACTUAL.json',sha256='2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3')
br=(G/backup['path'][6:]).read_bytes();assert sha(br)==backup['sha256'];actual=json.loads(br)
assert actual['passed'] and actual['total_backups']==436 and len(actual['new_backups'])==33 and actual['external_save_changes']==[]
assert len(actual['differences'])==1
diff=actual['differences'][0]
assert diff['path'].replace('\\','/').casefold().endswith('/prompts/tasks.yaml')
assert diff['expected']['sha256']=='1d337a0c8f9b220f0d36cf7ff87e50159d59f468bc0f39c4a3f6927f3de976b7' and diff['expected']['bytes']==786954
assert diff['current']['sha256']=='f1c19ee105a114ef1878219c4834afc0b5f1ce04859eaae9498370fee2db8b3f' and diff['current']['bytes']==790177
b['root_backup']=backup
dest=source.with_name('unified33_ROOT_BACKUP_FIXED_NOT_STAGE.json');content=enc(b)
assert not dest.exists()
with dest.open('xb')as stream:stream.write(content)
finalpin=dict(path=S+dest.relative_to(N).as_posix(),sha256=sha(content),bytes=len(content))
proof=dict(status='DESCRIPTOR_ONLY_ROOT_ACTUAL_BACKUP_SEAL_NOT_STAGE',parent=dict(path=S+source.relative_to(N).as_posix(),sha256=sha(raw)),candidate=finalpin,changed_pointer=['root_backup'],old=json.loads(raw)['root_backup'],new=backup,all_other_values_unchanged=True,authorized_tasks_difference_only=diff,actual_Field_pass=False)
with (N/'visible_doors_boundaries33_repair01/descriptor_backup_only_inverse_READONLY.json').open('xb')as stream:stream.write(enc(proof))
text=(N/'prepare_gallery_family_Stage_input32_NOTENGINE.py').read_text(encoding='utf8')
for old,new in [
    ("P=S+'docks_gallery_family_repair01/'","P=S+'visible_doors_boundaries33_repair01/'"),
    ('unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','unified33_READY02/unified33_ROOT_BACKUP_FIXED_NOT_STAGE.json'),
    ('stage_gallery_family32_ROOT_ONLY.py','stage_visible_doors_boundaries33_ROOT_ONLY.py'),
    ('d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af','c7ebe8a17e59240b60a91d85fa26708ae028a20d3375308f008c40094ae57e41'),
    ('root_gallery_family_ferry_exact32_stage01/','root_visible_doors_boundaries_exact33_stage01/'),
    ('len(targets)==32','len(targets)==33'),
    ('M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new)','M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new)'),
    ('EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE','EXACT33_SOURCE_PROSPECTIVE_AND_RAW_TYPED_INVERSE_NOT_STAGE'),
    ('count=32,partition=dict(GD=18,JSON=14)','count=33,partition=dict(GD=18,JSON=15)'),
    ('all32_raw_inverse','all33_raw_inverse'),
    ('old195_all_values_edges_preserved_plus7','old218_all_values_edges_preserved_plus6'),
    ("N/'docks_gallery_family_repair01'/name","N/'visible_doors_boundaries33_repair01'/name"),
    ('source_input_gallery_family32_ROOT_REVIEW.json','source_input_visible_doors_boundaries33_ROOT_REVIEW.json'),
    ('finite_preStage32_source_inverse_READONLY.json','finite_preStage33_source_inverse_READONLY.json'),
]:
    assert old in text,old;text=text.replace(old,new)
marker="audit=dict(status='EXACT33_SOURCE_PROSPECTIVE_AND_RAW_TYPED_INVERSE_NOT_STAGE'"
injected="""parent_stage=load(b['parent_stage']);fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
for p,r in targets.items():fixed[p]=r['candidate']['sha256']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newbytes[CT]);assert len(ct['source_sha256'])==26
tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(merged)==196
semantic_rows={}
for name,table in [('CT26',ct['source_sha256']),('Temple196',merged)]:
 semantic_rows[name]=[]
 for p,h in table.items():
  assert fixed[p]==h,('STRICT_CONSUMER_NOT_PROSPECTIVE',name,p,h,fixed.get(p))
  physical=newbytes[p]if p in targets else(G/p[6:]).read_bytes();assert sha(physical)==h
  semantic_rows[name].append(dict(path=p,expected=h,source='declared_candidate'if p in targets else'fixed_signed31_unchanged'))
semantics=dict(status='ALL_CT26_TEMPLE196_EXACT_PROSPECTIVE_PINS_READONLY',passed=True,tables=semantic_rows,no_historical_fallback=True,no_observed_expected_fill=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
semantic_path=N/'visible_doors_boundaries33_repair01/CT26_Temple196_all_prospective_pins_READONLY.json'
with semantic_path.open('xb')as stream:stream.write(enc(semantics))
print(semantic_path.name,sha(enc(semantics)),len(enc(semantics)))
audit=dict(status='EXACT33_SOURCE_PROSPECTIVE_AND_RAW_TYPED_INVERSE_NOT_STAGE'"""
assert text.count(marker)==1;text=text.replace(marker,injected)
sys.argv=[str(N/'prepare_visible_doors_boundaries33_final_input_DERIVED_NOTENGINE.py'),'--descriptor-sha256',finalpin['sha256']]
exec(compile(text,sys.argv[0],'exec'),{'__file__':sys.argv[0]})
print('FINAL_DESCRIPTOR',json.dumps(finalpin))
