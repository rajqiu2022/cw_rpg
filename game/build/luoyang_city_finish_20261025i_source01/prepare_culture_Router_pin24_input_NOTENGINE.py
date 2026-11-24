"""Reuse finite non-Stage preflight, with full strict CT26/Temple196 semantic assertions."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_gallery_family_Stage_input32_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [
 ("P=S+'docks_gallery_family_repair01/'","P=S+'culture_Router_pin_repair01/'"),
 ('unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('stage_gallery_family32_ROOT_ONLY.py','stage_culture_Router_pin24_ROOT_ONLY.py'),
 ('d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af','41904c4c3abd0fd774ecd2db04b60e597f549bc8d5aed9f153332fc45dfb6f83'),
 ('root_gallery_family_ferry_exact32_stage01/','root_culture_Router_pin_exact24_stage01/'),
 ('len(targets)==32','len(targets)==24'),('len(patchproof)==18','len(patchproof)==10'),
 ('M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new)','M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new)'),
 ('EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE','EXACT24_CT26_TEMPLE196_SEMANTIC_SOURCE_AND_BYTE_INVERSE_PREFLIGHT_NOT_STAGE'),
 ('count=32,partition=dict(GD=18,JSON=14)','count=24,partition=dict(GD=10,JSON=14)'),
 ('old195_all_values_edges_preserved_plus7','old202_all_values_edges_preserved_plus4'),
 ("N/'docks_gallery_family_repair01'/name","N/'culture_Router_pin_repair01'/name"),
 ('source_input_gallery_family32_ROOT_REVIEW.json','source_input_culture_Router_pin24_ROOT_REVIEW.json'),
 ('finite_preStage32_source_inverse_READONLY.json','finite_preStage24_source_semantics_inverse_READONLY.json'),
]:assert a in t,a;t=t.replace(a,b)
marker="audit=dict(status='EXACT24_CT26_TEMPLE196_SEMANTIC_SOURCE_AND_BYTE_INVERSE_PREFLIGHT_NOT_STAGE'"
semantic="""# Full strict consumer source schemas: fixed CE3E map plus this declared exact24.
parent_stage=load(b['parent_stage']);fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
for p,r in targets.items():fixed[p]=r['candidate']['sha256']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newbytes[CT]);assert len(ct['source_sha256'])==26
tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(merged)==196
for table in [ct['source_sha256'],merged]:
 for p,h in table.items():
  assert fixed[p]==h,('STRICT_CONSUMER_EXPECTATION_NOT_PROSPECTIVE_CURRENT',p,h,fixed.get(p))
  source=newbytes[p]if p in targets else(G/p[6:]).read_bytes();assert sha(source)==h,('STRICT_PIN_PHYSICAL_FIXED_SOURCE',p)
audit=dict(status='EXACT24_CT26_TEMPLE196_SEMANTIC_SOURCE_AND_BYTE_INVERSE_PREFLIGHT_NOT_STAGE'"""
assert t.count(marker)==1;t=t.replace(marker,semantic)
exec(compile(t,str(N/'prepare_culture_pin24_input_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_culture_pin24_input_DERIVED_NOTENGINE.py')})
