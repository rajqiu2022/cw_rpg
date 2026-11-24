"""Generate NEW future owner tool from fixed65BE recipe. Never execute it."""
import ast,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
oldpath=H/'prepare_performance26_canonical_B_actual_owner_NOTRUN.py'
raw=oldpath.read_bytes();assert hashlib.sha256(raw).hexdigest()=='b05fd7c2abf3c55ecc7aee6cb3b81ed75e4cf6c508903563b12c1509f9e5bd0c'
text=raw.decode()
changes=[
 ('Future actual22 review and source-only owner successor to fixed5050.','Future actual29 review and source-only owner successor to fixed65BE.'),
 ("OUT=S+'performance26_canonical_B_actual_independent_review/'","OUT=S+'performance36_merged_actual_independent_review/'"),
 ("PRIOR=S+'performance15_B_only_actual_independent_review/owner_source_maps_READY.json'","PRIOR=S+'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json'"),
 ('5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e','65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be'),
 ("PLAN=S+'performance25_canonical_B_source_recipe/source_input_ROOT_LOCKED.json'","PLAN=S+'performance35_merged_source_recipe/source_input_ROOT_LOCKED.json'"),
 ('706c58929266d6e0a9cf58a6b94f959383b5d34133acf059cc424251634473bd','e90077daf5c95a22559b6fd82ceff31cf9974cc42be0021e4bbf2e5b1e654d6b'),
 ("HAND=S+'performance24_canonical_B_dependencies/handoff_PRODUCTION_PROPOSAL.json'","HAND=S+'performance34_merged_DT_subspan_dependencies/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json'"),
 ('3a6200e99bd2a9c2e9ce19aa47eb06f4bb84ba15099e2058bd21de2117f2ce7d','32eef713b78b4bc1595e5b29637b67ee71cecc437303bfcb44b830c831e1283f'),
 ('outputs/root_B_canonical_keys_stage01/receipt.json','outputs/root_merged_G_parentcopy_DT_source_stage01/receipt.json'),
 ("{'patch_count':9,'copy_count':13,'total':22","{'patch_count':15,'copy_count':14,'total':29"),
 ('assert len(targets)==22','assert len(targets)==29'),
 ("hand['new_proof_pins']","hand['new_proof_sources_exact9']"),
 ('EXACT_INHERITED5050_OLD_VALUE','EXACT_INHERITED65BE_OLD_VALUE'),
 ('Original frozen AO independent map through unchanged validators; actualAP13_7912 metadata plus only B owned/source/index succession and2 proof declarations. Never collector-derived.','Original frozen AO independent map through unchanged validators; actualAP14_35FF plus exact29 merged target/header succession and9 declared proof leaves. Never collector-derived.'),
 ('Fixed5050 Quarter identity/native plus B-only shared source and71 execution-proof/header successor; receipt domain excludes independent collector header.','Fixed65BE Quarter identity/native plus merged source and80 execution-proof/header successor; receipt domain excludes collector header.'),
 ('Fixed331 Estate keyset B-only value successor; registry/native unchanged; no shared new proof group.','Fixed331 Estate keyset only necessary target values and new registry header; native unchanged; no shared new proof group.'),
 ('Fixed5050 complete Temple source domain plus only target/header value replacement and2 execution proof leaves; Temple code/binding/native unchanged.','Fixed65BE complete Temple source domain plus necessary target/header replacements and9 execution proof leaves including NEW C-only binding; native/other188 binding source values unchanged.'),
 ("assert same(receipt,row['receipt_source_sha256']),('FROZEN_REGISTRY_ROOM_RECEIPT_EXACT',row['id'])","assert same(receipt,replace(row['receipt_source_sha256'])),('REGISTRY_FIVE_DT_ONLY_RECEIPT_SUCCESSION',row['id'])"),
 ('Fixed5050 G-family full collector with B-only target/header and2 proof leaves; independent per-room receipt entirely unchanged, no DT/native/return mutation.','Fixed65BE G-family full collector with exact29 target/header and9 proof leaves; per-room receipt only DT source value successor, no native/return mutation.'),
 ('unchanged_inherited5050_leaves_not_rehashed','unchanged_inherited65BE_leaves_not_rehashed'),
 ('All5050 scene/layout/worldsize/native identities inherited; B-only performance source successor. Registry/Temple/DT/hash/Family/ENV/G/Field/Coordinator unchanged.','All65BE scene/layout/worldsize/native identities inherited.29-source successor only,5room DT declarations and new registry header, C-only Temple binding; hash/Family/ENV/Field/Router/Coordinator unchanged.'),
 ('INDEPENDENT22_BYTE_TYPED_FIXED5050_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','INDEPENDENT29_BYTE_TYPED_FIXED65BE_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT'),
 ("'target_count':22","'target_count':29")]
for a,b in changes:
    assert a in text,a;text=text.replace(a,b)
oldblock="""    edge=hand['owned_changed_exactly1'][0];inverse=raw(edge['new_snapshot'],edge['new_sha256']).decode()
    for h in reversed(edge['replacements']):assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'],1)
    assert inverse.encode()==raw(edge['old_snapshot'],edge['old_sha256'])
"""
newblock="""    code=read(hand['whole_inverse_proof']['path'],hand['whole_inverse_proof']['sha256'])
    for record in code['records'].values():
        before=raw(record['parent']['path'],record['parent']['sha256']);candidate=raw(record['candidate']['path'],record['candidate']['sha256']);forward=before;inverse=candidate
        for h in record['hunks']:
            a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1 and inverse.count(b)==1;forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
        assert forward==candidate and inverse==before
    # Existing E43B binding remains an execution-history source. NEW binding
    # enters exactly through the nine final execution-proof declarations.
    assert code['records']['temple_binding']['candidate']['path']in hand['new_proof_sources_exact9']
"""
assert text.count(oldblock)==1;text=text.replace(oldblock,newblock,1)
new=text.encode();ast.parse(new)
hs=[];aa=raw.decode().splitlines(True);bb=new.decode().splitlines(True)
for tag,i,j,k,z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':hs.append({'old_start':len(''.join(aa[:i]).encode()),'old_end':len(''.join(aa[:j]).encode()),'new_start':len(''.join(bb[:k]).encode()),'new_end':len(''.join(bb[:z]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:z])})
fwd=raw;rev=new
for h in reversed(hs):fwd=fwd[:h['old_start']]+h['new'].encode()+fwd[h['old_end']:];rev=rev[:h['new_start']]+h['old'].encode()+rev[h['new_end']:]
assert fwd==new and rev==raw
path=H/'prepare_performance36_merged_actual_owner_NOTRUN.py';assert not path.exists();path.write_bytes(new)
out=H/'performance36_owner_tool_preparation';assert not out.exists();out.mkdir()
diff=''.join(difflib.unified_diff(aa,bb,fromfile=str(oldpath),tofile=str(path))).encode();(out/'owner_tool_complete_vsB05F.diff').write_bytes(diff)
proof={'status':'TEXT_ONLY_FUTURE_MERGED29_OWNER_RECIPE_NOT_EXECUTED','parent_sha256':hashlib.sha256(raw).hexdigest(),'tool_path':str(path),'tool_sha256':hashlib.sha256(new).hexdigest(),'whole_tool_forward_inverse':True,'hunks':hs,'fixed_prior':'Independent65BE only; no collector/canonical expectation crawl','actual_receipt_sha256':'PENDING_ROOT_REAL_STAGE_REQUIRED_CLI_ARG_NOT_INVENTED','four_cities':'Final declared map nodes built from independent frozen AO baselines and explicit successor operations','quarter':'Declared final source table plus three independent headers; receipt domain independent','Estate':'Fixed331 keys with explicit target/registry value successors only','Temple':'Fixed65BE values replaced only where target olds match, plus exact9 executionproof leaves including C-only binding; E43B historical leaf kept','G_rooms':'Fixed65BE complete collector plus exact29 target/header and9 proof declarations; five room receipts independently from registry and compared to fixed per-room receipt with DT target-only replacement','all_native_geometry_paths_unchanged':True,'engine_Stage_collector_native_decode_or_owner_execution_calls':0,'diff_sha256':hashlib.sha256(diff).hexdigest()}
(out/'owner_tool_whole_inverse_NOT_RUN.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'tool_sha256':hashlib.sha256(new).hexdigest(),'diff_sha256':hashlib.sha256(diff).hexdigest(),'proof_sha256':hashlib.sha256((out/'owner_tool_whole_inverse_NOT_RUN.json').read_bytes()).hexdigest()},indent=2))
