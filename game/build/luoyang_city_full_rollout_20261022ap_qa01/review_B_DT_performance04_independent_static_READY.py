"""Independent byte inverse and same-stack/source-lifecycle audit; no engine."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;BASE=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_loading_perf04'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,s):
    b=p.read_bytes();assert sha(b)==s;return json.loads(b)
h=load(BASE/'handoff_BUILD_ONLY_READY.json','ed18323355212c8fb218f7b4dccb13eb15f7790b34561e3a792be4c7ab0198e3')
proof=load(BASE/'exact_byte_hunks_READY.json','b175dc41ec99b24a980cbf8ab4b4d6f5f8e61233520f65f76b52d12ba01cb3c8')
def funcs(text):
    matches=list(re.finditer(r'^(?:static )?func ([A-Za-z_][A-Za-z0-9_]*)\(',text,re.M));out={}
    for i,m in enumerate(matches):out[m[1]]=text[m.start():matches[i+1].start() if i+1<len(matches) else len(text)]
    return out
rows=[];texts=[]
for row,decl in zip(proof['files'],h['candidates']):
    old=(ROOT.parent/row['before']).read_bytes();candidate=(ROOT.parent/row['candidate']).read_bytes();canonical=(ROOT.parent/row['canonical']).read_bytes()
    assert sha(old)==decl['old_sha256'] and sha(candidate)==decl['candidate_sha256'] and canonical==old
    rebuilt=old.decode()
    for edit in row['hunks']:
        assert rebuilt.count(edit['old'])==1;rebuilt=rebuilt.replace(edit['old'],edit['new'],1)
    assert rebuilt.encode()==candidate
    back=candidate.decode()
    for edit in reversed(row['hunks']):assert back.count(edit['new'])==1;back=back.replace(edit['new'],edit['old'],1)
    assert back.encode()==old
    rows.append({'target':decl['target'],'old_sha256':sha(old),'candidate_sha256':sha(candidate),'hunks':len(row['hunks']),'whole_forward_and_inverse_exact_bytes':True,'canonical_unchanged':True});texts.append((old.decode(),candidate.decode()))
oldb,b=texts[0];oldf,dt=texts[1];bf=funcs(b);oldbf=funcs(oldb);df=funcs(dt);olddf=funcs(oldf)
helper='_finite_yamen_child_state_from_bound'
assert b.count(helper+'(scene)')==3
for name in ['layout_author','restore_parent_record','finite_yamen_child_state']:
    part=bf[name];assert part.index('if not whole_bound(scene):')<part.index(helper+'(scene)')
    pre=part[:part.index(helper+'(scene)')];assert 'await ' not in pre and 'scene.set(' not in pre and 'scene.map_layout=' not in pre
assert bf['whole_bound']==oldbf['whole_bound'] and bf['bound']==oldbf['bound'] and bf['storage']==oldbf['storage']
oldpublic=oldbf['finite_yamen_child_state'].split('\tvar proof: Dictionary=',1)[0]
assert bf['finite_yamen_child_state'].startswith(oldpublic)
assert 'whole_bound(' not in bf[helper] and 'yamen_public_session_proof' in bf[helper] and 'typeof(proof.get("token"))!=TYPE_INT or proof.token<=0' in bf[helper]
unchanged=[]
for name in ['state','finalize','release','_reject','source_paths','_published_source_matches','_proof','_parent_bound','cpu_proof_valid','author','binding','safe_foot','texture_matches']:
    assert df[name]==olddf[name],name;unchanged.append(name)
assert df['_render_objects_for_loading'].replace('_render_objects_for_loading','render_objects',1)==olddf['render_objects']
assert df['_npcs_for_loading'].replace('_npcs_for_loading','npcs',1)==olddf['npcs']
for token in ['await ', 'FileAccess.', 'ResourceLoader.load(', '.get_image()', '.convert(', '_transition_bytes_sha(', 'owner.call()', '_published_source_matches(', 'source_paths()']:
    assert oldf.count(token)==dt.count(token),(token,oldf.count(token),dt.count(token))
assert 'static var _loading_timings' not in dt and 'var _loading_timings: Dictionary={}' in dt
assert '_loading_timings.spans.has(label)' in df['_loading_span'] and 'details.duplicate(true)' in df['_loading_span']
assert 'fresh_source_validation_credit"]=false' in df['loading_timing_state'] and '_scene.get_instance_id()' in df['loading_timing_state'] and '_scene.map_layout.get_instance_id()' in df['loading_timing_state']
assert 'DISTRICT_SETUP_NOT_WARM_RESUME' in df['prepare']
out=QA/'B77DFC_DT39242C_performance04_independent_static_review_READY.json'
result={'status':'INDEPENDENT_BUILD_ONLY_NO_STATIC_BLOCKER_NOT_PARSE_OR_RUNTIME_READY','candidates':rows,'B_contract':{'same_synchronous_stack_whole_bound_retained':3,'private_convention_helper_only_internal_three_callsites':True,'public_child_state_original_prechecks_and_whole_bound_retained':True,'whole_bound_bound_storage_functions_byte_unchanged':True,'no_cross_call_cache_or_await_or_Scene_mutation_between_bound_and_helper':True,'GDScript_underscore_note':'Internal naming convention, not language-enforced access control; frozen consumer source closure must remain exact.'},'DT_contract':{'unchanged_function_wholebytes':unchanged,'wrapped_render_and_NPC_body_wholebytes_unchanged':True,'original_IO_fullRGBA_owner_and_await_call_counts_unchanged':True,'timing_storage_instance_local':True,'same_label_first_record_only':True,'state_receipt_not_modified':True,'getter_freshsource_credit_always_false':True,'getter_limit':'Scene/layout setup identity only; reader must additionally match the Field-owned district instance and saved token to this request. Not a warm-resume/new-final-source proof.'},'FIRST_FINAL_hash_protocol':'No skipped read/hash/source path or validation, C/Field/Router not edited in this candidate.','blocking_findings':[],'runtime_savings_or_speedup_claim':False,'engine_parse_collector_or_candidate_method_calls':0,'canonical_writes':0}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
