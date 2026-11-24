"""Only small text/code inverse and issued receipt declarations; no native/media decode."""
import hashlib,json,pathlib

GAME=pathlib.Path(__file__).resolve().parents[2]
BASE=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
SRC=BASE/'performance99_artisan_life_family_material_NOTREADY'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
def raw(p): return pathlib.Path(p).read_bytes()
def text(p): return raw(p).decode('utf-8-sig')
def obj(p): return json.loads(text(p))
def sha(p): return hashlib.sha256(raw(p)).hexdigest()
def need(v,label):
    if not v: raise AssertionError(label)
def res(p):
    need(p.startswith('res://') and '..' not in p,'FIXED_RES')
    return GAME/p[6:]
def inverse(pairs):
    counts=[]
    for pair in pairs:
        a=res(pair['parent']['path']);b=res(pair['candidate']['path'])
        need(sha(a)==pair['parent']['sha256'] and sha(b)==pair['candidate']['sha256'],'PAIR_SHA')
        old=text(a);new=text(b);forward=old;back=new
        for h in sorted(pair['hunks'],key=lambda h:h['old_char_offset'],reverse=True):
            at=h['old_char_offset'];need(forward[at:at+len(h['before'])]==h['before'],'OLD_EXACT_OFFSET')
            forward=forward[:at]+h['after']+forward[at+len(h['before']):]
        for h in sorted(pair['hunks'],key=lambda h:h['new_char_offset'],reverse=True):
            at=h['new_char_offset'];need(back[at:at+len(h['after'])]==h['after'],'NEW_EXACT_OFFSET')
            back=back[:at]+h['before']+back[at+len(h['after']):]
        need(forward==new and back==old,'WHOLE_BOTH_INVERSES')
        counts.append(len(pair['hunks']))
    return counts
def reverse_literals(child,changes):
    for old,new in reversed(changes):
        need(child.count(new)==1,'SINGLE_HEADER_REVERSE')
        child=child.replace(new,old)
    return child

proof=obj(SRC/'wholebyte_inverse_BUILD_NOTREADY.json')
hunks=inverse(proof['pairs'])
need(hunks==[9,2],'FINITE_ORIGINAL_DIFF_COUNTS')
media=obj(SRC/'MEDIA_bound_inverse_NOTREADY.json')
art_family=text(SRC/'quarters_family_life_ART_bound_CANDIDATE_NOTREADY.gd')
media_family=text(SRC/'quarters_family_life_MEDIA_bound_CANDIDATE_NOTREADY.gd')
need(reverse_literals(media_family,[(r['old'],r['new']) for r in media['code_replacements']])==art_family,'MEDIA_ONLY2_CODE_HEADERS')
art=obj(SRC/'life_binding_ART_bound_NOTREADY.json');binding=obj(SRC/'life_binding_MEDIA_bound_NOTREADY.json')
need(binding['ready'] is False and binding['formal_enabled'] is False,'SOURCE_DRAFT_FLAGS_FALSE')
added=set(binding['source_sha256'])-set(art['source_sha256'])
need(added==set(media['binding_added_source_paths']),'MEDIA_EXACT3_DECLARED_SOURCE_ADDITIONS')
for p,h in art['source_sha256'].items(): need(binding['source_sha256'][p]==h,'OLD_BINDING_SOURCE_EXACT')
auth=obj(ROOT/'integration62/life_candidates_readiness_authorization.json')
ready=BASE/'life_production100_READY'
rf=ready/'Family_life_READY.gd';rm=ready/'material_runtime_life_READY.gd';rb=ready/'life_binding_READY.json'
need(sha(rf)==auth['candidate_Family_sha256'] and sha(rm)==auth['candidate_material_sha256'] and sha(rb)==auth['candidate_binding_sha256'],'ROOT_READY3_ACTUAL_SHA')
need(reverse_literals(text(rf),auth['Family_header_changes'])==media_family,'ROOT_READY_FAMILY_ONLY3_HEADERS')
material=text(SRC/'material_runtime_life_CANDIDATE_NOTREADY.gd')
need(reverse_literals(text(rm),[('const LIFE_READY=false','const LIFE_READY=true')])==material,'ROOT_READY_MATERIAL_ONLY1_FLAG')
ready_binding=obj(rb)
need(ready_binding['ready'] is True and ready_binding['formal_enabled'] is True and ready_binding['blockers']==[],'ROOT_READY_BINDING3_FIELDS')
restored=dict(ready_binding)
for k in ('ready','formal_enabled','blockers'): restored[k]=binding[k]
need(restored==binding,'ROOT_READY_BINDING_WHOLE_TYPED_INVERSE')
need(ready_binding['source_sha256']==binding['source_sha256'],'ALL_BINDING_SOURCE_VALUES_RETAINED')

author=obj(GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json')
marker='const LIFE_ROWS=';start=material.index(marker)+len(marker);end=material.index('\nstatic func _attach_life_exact_runtime',start)
rows=json.loads(material[start:end])
need(len(rows)==4,'ONLY4_MATERIAL_ROWS')
for actual,source in zip(rows,author['placements']):
    for k,v in actual.items(): need(v==source[k],'ALL_MATERIAL_ROW_VALUES_ORIGINAL_SOURCE')
begin=material.index('\tfor entry: Dictionary in ground_nodes:');stop=material.index('\tif not owner.call():',begin)
shader_block=material[begin:stop]
need(material.count(shader_block)==2,'EXACT_ORIGINAL118_GROUND_SHADER_BLOCK_TWICE')
parent_family=text(res(proof['pairs'][0]['parent']['path']))
for name in ('manifest','validation_begin','validation_finish','validation_receipt','source_paths','matches'):
    token='static func '+name+'(';start=parent_family.index(token);end=parent_family.find('\nstatic func ',start+1)
    body=parent_family[start:end if end>=0 else len(parent_family)]
    need(body in media_family,'UNCHANGED_ORIGINAL_FIRST_FINAL_AND_OWNER_'+name)
need('FileAccess.get_file_as_bytes(parent.child' not in media_family,'NO_PARENT_PACKET_REPLAY')

report=obj(res(binding['publisher_report']['path']))
need(sha(res(binding['publisher_report']['path']))==binding['publisher_report']['sha256'],'ROOT59_FIXED_REPORT_SHA')
need(report['source_first']==report['source_final']==binding['publication_source_first'],'ROOT59_SOURCE20_FIXED')
need(len(report['source_first'])==20 and report['finite_proof']==binding['publication_finite_proof'],'ROOT59_FULL_SMALL_PROOF_EXACT')
for leaf in binding['child'].values(): need(report['artifacts'][leaf['path']]==leaf['sha256'],'CHILD_SHA_FROM_FIXED_REPORT_NO_NATIVE_READ')
promo=ROOT/'integration61/media_five_promotion_actual.json'
need(sha(promo)==binding['mask_import_promotion']['sha256'],'ROOT61_MEDIA_PROMOTION_REPORT_FIXED')
promotion=obj(promo);need(promotion['passed'] and promotion['target_count']==5,'ROOT61_EXACT5_PROMOTION_SUCCESS')
for p,h in binding['mask_import_source_sha256'].items(): need(sha(res(p))==h,'SMALL_WALK_IMPORT_LEAVES_CURRENT')
guard=ROOT/'integration62/guard_before.json'
need(sha(guard)==auth['guard_before_sha256'] and obj(guard)['passed'] and obj(guard)['checked']==2118,'ROOT62_FRESH_GUARD_EXACT')

out={
 'status':'SOURCE99_AND_ROOT62_READINESS_STATIC_REVIEW_NO_CODE_BLOCKER_SOURCE_DAG_FORMAL_RUNTIME_PENDING',
 'inverse_hunks':hunks,'all_whole_byte_inverses':True,'media_Family_only2_headers':True,
 'Root62_Family_only3_headers_material_only1flag_binding_only3readiness_fields':True,
 'Root62_candidates':{p.name:sha(p) for p in (rf,rm,rb)},
 'binding_source_count':len(binding['source_sha256']),'media_only_added_sources':sorted(added),
 'four_material_rows_exact_original_author':True,'original118_shader_install_block_byte_identical':True,
 'manifest_begin_finish_receipt_sourcepaths_matches_original_bodies_byte_retained':True,
 'root59_fixed20_sources_and_small_finite_proof_exact':True,'native_child4_SHA_checked_against_issued_report_without_native_read':True,
 'Root61_promoted_exact5_and_binding_walk2_small_current_SHA':True,'Root62_guard2118':True,
 'semantic_boundary':[
  'Original132/27 and Garden path retained. New branch requires explicit life declaration + A2 parent binding and full finite admission; malformed or false branch cannot gain admission by count alone.',
  'Runtime childpacket SHA then existing plain/kind/scene/walkbytes fullSHA and whole Scene/Layout storage equality remain. Small native int proof versus JSON float proof uses original symmetric wire; explicit native int counts retained.',
  'No newly introduced parent25MB packet decode/copy/domain replay or old875 routing. Fixed publication and local ART do not become whole district, Field ghost or loading credit.',
  'Original complete shared Quarter source-FIRST/FINAL and natural Scene/layout weakref ownership remain unchanged; no cache/mtime source bypass.',
  'Material selector is not admission: new branch still requires real Field/world/Scene and Family source-FIRST storage matches; unique136 IDs then118ground/14oldprops/4newprops, exact full texture/native transform, opaque no material/region/frame/flip/alpha edits.',
  'Only after all136 whitelist and owner checks are shader materials assigned to original118ground; old stamp/ENV/rut attachment is outside this candidate and must remain byte-identical in final ENV successor.'
 ],
 'remaining_before_runtime':['Complete independently reviewed source-DAG/classification/execution/ENV closure and fresh Stage/owner/deployment guard still required. Explicitly declare Root59 build native reports/artifacts and promoted2walk imports, and separate scholar3 under their real consumer domains; no collector fill.','No parse or runtime execution credited; actor-local ghost/body behavior awaits Root-authorized false key after final source owner.'],
 'engine_parse_collector_packet_media_decode_raster_NAV_production_write_by_QA':False,
 'local_or_whole_Field_ART_or_loading_PASS':False
}
print(json.dumps(out,ensure_ascii=False,indent=2))
