"""Bind only fixed Root CPU native facts into a NEW still-closed draft sidecar."""
import copy
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'a2_runtime_draft01/';OUT=S+'a2_runtime_draft02/'
A2='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/'
def path(p):
    assert p.startswith('res://') and '..' not in p;return GAME/p[6:]
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN',p);return b
def encoded(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
old_handoff=json.loads(fixed(P+'handoff_DRAFT_NOTREADY.json','755a759c3cdabbcff67f93263bfd19f676bf3b0810e34d802ce33785c491b6d7'))
old_binding=json.loads(fixed(old_handoff['binding']['path'],old_handoff['binding']['sha256']))
report_pin={'path':A2+'output_crossings6/runs/118352_1733/result.json','sha256':'a5f2200e76ca6bb7932c5760b3954748c0578c0c093755af86493a51a4ce25b7'}
report=json.loads(fixed(report_pin['path'],report_pin['sha256']))
assert report['passed'] is True and report['published'] is True and report['checks']==1941 and report['elapsed_ms']==3624
assert report['whole_packet_inverse'] is True and report['whole_scene_layout_inverse'] is True
assert report['source_first']==report['source_final']
expected_artifacts={
 'layout.res':'105b75ae0bfe20aed0eb2f740c518cccef3d779f1597bb5ad74580eb175bf352',
 'packet.bin':'1758e8b3ee9d21d619c0a494722f5891b1ee6bf47fc0ae0a763f1bccc675daea',
 'scene.res':'63e927760570cadb9fd911537d484bd22918465b5020fce08c2bf9307a77c4fc',
 'walk.png':'9d6edceee42e4d075f920fc1d1cffb388cb8ffc66b5c223084e671a70aff852c',
}
assert report['artifacts']=={A2+'output_crossings6/native/'+n:s for n,s in expected_artifacts.items()}
binding=copy.deepcopy(old_binding)
for suffix,leaf in binding['child'].items():
    assert leaf['sha256'] is None and leaf['path']==A2+'output_crossings6/native/'+suffix
    leaf['sha256']=expected_artifacts[suffix]
    assert leaf['path'] not in binding['source_sha256']
    binding['source_sha256'][leaf['path']]=leaf['sha256']
binding['publisher_report']=report_pin
binding['source_sha256'][report_pin['path']]=report_pin['sha256']
author=json.loads(fixed(binding['author']['path'],binding['author']['sha256']))
parent_author_pin=next((p,s) for p,s in binding['source_sha256'].items() if p.endswith('artisan_revision4/author_READY.json'))
parent_author=json.loads(fixed(*parent_author_pin))
new_atlas_pins={p:s for p,s in author['source_sha256'].items() if p not in parent_author['source_sha256']}
assert len(new_atlas_pins)==21 and all(p.endswith('.tres') and '/artisan_a2_workyards_epoch01/atlases/' in p for p in new_atlas_pins)
for p,s in new_atlas_pins.items():
    assert report['source_first'].get(p)==s
    binding['source_sha256'][p]=s
binding['child_rgba_sha256_from_fixed_independent_prior_and_Root_report']=report['finite_proof']['local_mask']['child_rgba_sha256']
binding['actual_native_publication_only_not_ART_or_runtime']=True
binding['four_native_pins_not_hashed_from_current_or_observed_collectors']=True
binding['new_21_Atlas_pins_declared_by_frozen_author_not_live_scan']=new_atlas_pins
binding['pending_source_leaves']=['eventual new walk import/ctex if required; no hashes guessed','Root finite ART authority','final code-only source pins in the shared Quarter manifest, no binding->final manifest back edge']
assert binding['ready'] is False and binding['root_art_admission']=={'path':None,'sha256':None}
inverse=copy.deepcopy(binding)
for suffix in inverse['child']:inverse['child'][suffix]['sha256']=None
inverse['publisher_report']=copy.deepcopy(old_binding['publisher_report'])
inverse['source_sha256']=copy.deepcopy(old_binding['source_sha256'])
inverse['pending_source_leaves']=copy.deepcopy(old_binding['pending_source_leaves'])
for k in ['child_rgba_sha256_from_fixed_independent_prior_and_Root_report','actual_native_publication_only_not_ART_or_runtime','four_native_pins_not_hashed_from_current_or_observed_collectors','new_21_Atlas_pins_declared_by_frozen_author_not_live_scan']:del inverse[k]
assert inverse==old_binding
binding_desc={'path':OUT+'a2_binding_ACTUAL_NATIVE_ART_PENDING.json','sha256':sha(encoded(binding))}
handoff=copy.deepcopy(old_handoff)
handoff['status']='A2_RUNTIME_DRAFT_HAS_ROOT_ACTUAL_NATIVE_DEPENDENCIES_ART_AND_SOURCE_AUTHOR_PENDING'
handoff['predecessor_handoff']={'path':P+'handoff_DRAFT_NOTREADY.json','sha256':'755a759c3cdabbcff67f93263bfd19f676bf3b0810e34d802ce33785c491b6d7','preserved':True}
handoff['binding']=binding_desc
handoff['Root_actual_native_report']=report_pin
handoff['binding_typed_inverse_to01_unknown_native_parent']=True
handoff['not_code_bound_yet']='All01 code drafts remain exact and false. Family still points01 PENDING binding with empty bindingSHA. Final Root-reviewed successor must bind this actual/native sidecar plus real ART schema before flags can close.'
handoff['new_native_Atlas_sources_count']=21
handoff['not_yet_satisfied']=['Root finite outdoor ART actual schema/pin','new walk import/ctex if required by Field','Root final code binding/schema review and authorized minimal parse','final exact source-only metadata/index/owned successor DAG and scope','runtime source identity/material/body/loading actual']
outputs={binding_desc['path']:encoded(binding),OUT+'handoff_DRAFT_NATIVE_ACTUAL_ART_PENDING.json':encoded(handoff)}
assert not path(OUT).exists()
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as h:h.write(b)
print(json.dumps({'handoff':{'path':OUT+'handoff_DRAFT_NATIVE_ACTUAL_ART_PENDING.json','sha256':sha(encoded(handoff))},'binding':binding_desc,'native_count':4,'new_atlas_count':21,'all_ready_flags_remain_false':True,'canonical_writes':0}))
