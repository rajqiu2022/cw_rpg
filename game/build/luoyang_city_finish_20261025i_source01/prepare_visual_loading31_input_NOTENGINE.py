"""Finite offline preflight + strict CT26/Temple196 source-expression audit, no Stage."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_gallery_family_Stage_input32_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [
 ("P=S+'docks_gallery_family_repair01/'","P=S+'family_visual_material_loading_repair01/'"),
 ('unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('stage_gallery_family32_ROOT_ONLY.py','stage_visual_material_loading31_ROOT_ONLY.py'),
 ('d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af','a510b0496548f58d986fc0a47ad9879a3d4fa756ff15c9805d3445cbabafbfee'),
 ('root_gallery_family_ferry_exact32_stage01/','root_family_visual_material_loading_exact31_stage01/'),
 ('len(targets)==32','len(targets)==31'),('len(patchproof)==18','len(patchproof)==17'),
 ('M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new)','M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new)'),
 ('EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE','EXACT31_CT26_TEMPLE196_SOURCE_SEMANTIC_AND_BYTE_INVERSE_NOT_STAGE'),
 ('count=32,partition=dict(GD=18,JSON=14)','count=31,partition=dict(GD=17,JSON=14)'),
 ('old195_all_values_edges_preserved_plus7','old206_all_values_edges_preserved_plus6'),
 ("N/'docks_gallery_family_repair01'/name","N/'family_visual_material_loading_repair01'/name"),
 ('source_input_gallery_family32_ROOT_REVIEW.json','source_input_visual_material_loading31_ROOT_REVIEW.json'),
 ('finite_preStage32_source_inverse_READONLY.json','finite_preStage31_source_semantics_inverse_READONLY.json'),
]:assert a in t,a;t=t.replace(a,b)
marker="audit=dict(status='EXACT31_CT26_TEMPLE196_SOURCE_SEMANTIC_AND_BYTE_INVERSE_NOT_STAGE'"
semantic="""# Full exact semantic consumers: fixed actual F67E sources + declared current candidates.
parent_stage=load(b['parent_stage']);fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
for p,r in targets.items():fixed[p]=r['candidate']['sha256']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';ct=json.loads(newbytes[CT]);assert len(ct['source_sha256'])==26
tb=load(b['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));merged={**base['source_sha256'],**tb['source_delta']};assert len(merged)==196
semantic_rows={}
for name,table in [('CT26',ct['source_sha256']),('Temple196',merged)]:
 semantic_rows[name]=[]
 for p,h in table.items():
  assert fixed[p]==h,('STRICT_CONSUMER_NOT_PROSPECTIVE_CURRENT',name,p,h,fixed.get(p))
  source=newbytes[p]if p in targets else(G/p[6:]).read_bytes();assert sha(source)==h,('STRICT_PHYSICAL_FIXED_SOURCE',name,p)
  semantic_rows[name].append(dict(path=p,expected=h,source='declared_candidate'if p in targets else'fixed_actual_F67E_unchanged'))
audit_semantics=dict(status='ALL_CT26_TEMPLE196_EXACT_PROSPECTIVE_SOURCE_PINS_READONLY',passed=True,tables=semantic_rows,no_historical_fallback=True,no_observed_expected_fill=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
sem_path=N/'family_visual_material_loading_repair01/CT26_Temple196_all_prospective_pins_READONLY.json';assert not sem_path.exists()
with sem_path.open('xb')as stream:stream.write(enc(audit_semantics))
print(sem_path.name,sha(enc(audit_semantics)),len(enc(audit_semantics)))
audit=dict(status='EXACT31_CT26_TEMPLE196_SOURCE_SEMANTIC_AND_BYTE_INVERSE_NOT_STAGE'"""
assert t.count(marker)==1;t=t.replace(marker,semantic)
exec(compile(t,str(N/'prepare_visual_loading31_input_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_visual_loading31_input_DERIVED_NOTENGINE.py')})
