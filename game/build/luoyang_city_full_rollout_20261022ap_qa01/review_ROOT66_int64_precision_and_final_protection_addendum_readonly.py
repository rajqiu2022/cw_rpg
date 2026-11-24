"""NEW precision correction only; keep original review and actual immutable."""
import hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2];Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=raw(p);assert h is None or sha(b)==h,p;return json.loads(b)
oldp=Q+'ROOT66_scholar_residual75660_independent_actual_review_READY.json';oldh='9592f6ce82c0bbdb13b235ab57e9556ab1162e5ad390023c834c6f67a2928679';old=read(oldp,oldh)
rp=R+'integration66/scholar_residual_READY/output/75660_2737/result.json';rh='545322a2ca324565d0d7edff75a87942a64fe59f0769841276b19fb06974169c';a=read(rp,rh)
owners=[x for x in a['records']if x['kind']=='RESIDUAL_PASSIVE_C_OWNER_SCALARS'];assert len(owners)==2 and owners[0]['identity']==owners[1]['identity']
exact=owners[0]['identity'];assert exact['Scene']==-9223371733673702887 and exact['layout']==-9223371733942138289
copied=old['completed_components']['natural_C_same_Field_Scene_layout_token_1741_passive_only']
assert copied['Scene']!=exact['Scene']and copied['layout']!=exact['layout'],'EXPECTED_ORIGINAL_TRANSCRIPTION_PRECISION_LOSS'
exact_strings={k:str(exact[k])for k in('Field','Scene','layout','token')}
assert all(isinstance(exact[k],int)for k in('Field','Scene','layout','token'))and exact['source_count']==1741
gp=R+'integration66/final_guard.json';gh='a2321bcbb93b885f3f33aa98bf2663af853e0c056ebdf90dc34156e01a5d39e7';guard=read(gp,gh)
before=read(R+'integration66/guard_before.json','34b58e47930af5106c2ed4d135e4860b214470a767c39e58057416d2a1272f00')
assert guard['passed']and guard['checked']==2119 and guard['exact_unchanged']==2119 and guard['authorized_change_count']==0 and guard['unexpected_change_count']==0 and guard['save_count']==15 and guard['save_change_count']==0 and guard['parent_fact_values_copied']is False
assert guard['facts']==before['facts'],'ALL_EXISTING_ROOT_FACT_FIELDS_INCLUDING_TICKS_IDENTICAL'
tp=R+'integration66/source_only_three_facts_after.json';th='1540ba1d014c8853ca4f753118ed651c18435fdf124884449644bc7a6c6cc604';three=read(tp,th)
prior=read(R+'integration39/proof_autoimport_tuple_before_retry1.json','19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296')
assert len(three['facts'])==3 and three['facts']==prior['facts']and three['runtime_texture_credit']is False
mp=R+'integration66/five_media_final_facts.json';mh='021a758a63c875b9f4303ea818e8bf68839e1ba9b1fe6b891e3256505f0e72aa';media=read(mp,mh)
admission=read(R+'integration61/media_five_promotion_actual.json','1a4ddf823a5ec3767d99428ea0866bd8f18bcfd926522149759df8b068cb53b5')
assert len(media['facts'])==5 and media['facts']==admission['written']
assert a['checks']==35 and a['failures']==0 and a['complete']is True
print(json.dumps({'status':'ROOT66_ORIGINAL9592_REVIEW_INT64_TRANSCRIPTION_PRECISION_CORRECTION_AND_FINAL_PROTECTION_ADDENDUM','original_review_retained':{'path':oldp,'sha256':oldh},'actual_immutable':{'path':rp,'sha256':rh},'correction':'Original9592 review serialized exact Python integer IDs through JavaScript Number, rounding Scene/layout beyond2^53. Those numeric transcriptions must not be used as exact IDs. Godot same-owner assertions and source actual were never altered. This NEW addendum reads original actual with exact Python int64 integers and emits identity strings only.','exact_original_actual_identity_as_strings':exact_strings,'source_count_safe_integer':1741,'before_after_actual_identity_exact_integer_equality_rechecked':True,'original_component_conclusions_supported_by_in_engine_exact_assertions_not_rounded_copy':True,'Root66_final_protection':{'final_guard':{'path':gp,'sha256':gh},'checked':2119,'exact_unchanged':2119,'authorized_changes':0,'unexpected':0,'save15_changes':0,'all_original_fact_fields_SHA_bytes_exactticks_equal_before':True,'values_not_copied_from_before':True},'three_SOURCE_ONLY_proof_facts':{'path':tp,'sha256':th,'all3_SHA_bytes_exactticks_same_as_Root39':True,'not_runtime_texture_admission':True},'five_admitted_media':{'path':mp,'sha256':mh,'all5_SHA_bytes_exactticks_same_as_Root61_promotion':True,'no_rehash_or_decode_by_QA':True},'limits':'No new expected runtime state, no new Field/source/performance/ART credit;35/0 residual component result unchanged, true C0000005/nonclean retained, original65FAIL retained. Original9592 only superseded on identity numeric-copy precision and now-supplied final guards.','QA_actions':{'engine':False,'collector':False,'media_hash':False,'decode':False,'production_or_actual_write':False}},indent=2))
