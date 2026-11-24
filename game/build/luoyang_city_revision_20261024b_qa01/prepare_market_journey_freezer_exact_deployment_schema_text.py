"""NEW freezer successor for Root's declared exact deployment schema; no run."""
from pathlib import Path
import hashlib, json, difflib

Q = Path(__file__).resolve().parent
old = Q / 'freeze_market_journey36_SCHEMA_PENDING_NOTRUN.py'
new = Q / 'freeze_market_journey36_exact_receipts_READY_NOTRUN.py'
sha = lambda b: hashlib.sha256(b).hexdigest()
source = old.read_bytes()
assert sha(source) == '04ad3a2d55274e4ce6c0ff99daadedb7c85e9b671fc97147d95449a52941cbe1'
old_function = '''def validate_deployment(deployment, stage, stage_sha):
    # Root has not yet delivered its real deployment receipt schema. Do not
    # guess passed/targets/records or treat nonempty JSON as deployment success.
    need(DEPLOYMENT_SCHEMA_READY, 'ROOT_REAL_DEPLOYMENT_SCHEMA_NOT_LOCKED_NO_OUTPUTS')
    raise ValueError('NEW_SCHEMA_SUCCESSOR_REQUIRED_NOT_IMPLEMENTED')
'''
new_function = '''def validate_deployment(deployment, stage, stage_sha, stage_path):
    # Root's exact declared schema; the supplied document must be the final
    # real deployment receipt. No current files are read to make expectations.
    need(DEPLOYMENT_SCHEMA_READY and deployment.get('status') == 'ROOT_EXACT36_DEPLOYED_FIRST_FINAL_VERIFIED'
         and deployment.get('passed') is True, 'REAL_ROOT_SUCCESSFUL_DEPLOYMENT_REQUIRED')
    bound = deployment.get('stage', {})
    need(type(bound) is dict and resolve(bound.get('path', '')) == stage_path
         and bound.get('sha256') == stage_sha, 'DEPLOYMENT_BOUND_TO_EXACT_ACTUAL_STAGE')
    need(deployment.get('target_count') == 36 and deployment.get('partition')
         == {'apply_patch_GD':21,'exact_copy_JSON':15}, 'EXACT_REAL_DEPLOYMENT36_PARTITION')
    rows = deployment.get('targets')
    need(type(rows) is list and len(rows) == 36, 'ALL_REAL_DEPLOYMENT_TARGET_RECORDS')
    expected = {row['target']:row for row in stage['targets']}
    need(len(expected) == 36, 'NO_DUPLICATE_STAGE_TARGET')
    seen = set()
    for row in rows:
        need(type(row) is dict and set(row) == {'target','old_sha256','candidate_path','candidate_sha256','actual_sha256','bytes'}, 'EXACT_ROOT_TARGET_SCHEMA')
        target = row['target']
        need(target in expected and target not in seen, 'EXACT_UNIQUE_REAL_TARGET')
        seen.add(target); approved = expected[target]
        need(row['old_sha256'] == approved['old_sha256']
             and resolve(row['candidate_path']) == resolve(approved['candidate_path'])
             and row['candidate_sha256'] == approved['candidate_sha256'] == row['actual_sha256'], 'ROOT_ACTUAL_SHA_EXACT_STAGE_CANDIDATE')
        need(type(row['bytes']) is int and row['bytes'] > 0, 'ROOT_RETAINED_ACTUAL_BYTE_COUNT')
    need(seen == set(expected), 'EXACT36_NO_UNEXPECTED_OR_MISSING_DEPLOYMENT_TARGET')
'''
ops = [
    (b'DEPLOYMENT_SCHEMA_READY = False', b'DEPLOYMENT_SCHEMA_READY = True'),
    (old_function.encode(), new_function.encode()),
    (b'validate_deployment(deployment,stage,sha(stage_raw))  # Refuses before any output while schema is pending.',
     b'validate_deployment(deployment,stage,sha(stage_raw),stage_path)  # Real Root exact receipt required before any output.'),
    (b"        need(p not in fixture['source_sha256'] or fixture['source_sha256'][p] == h, 'NO_EXTRA_GUARD_COLLISION')",
     b"        need(p not in fixture['source_sha256'], 'ONLY_NEW_FIXED_RECEIPT_GUARDS_NO_COLLISION')"),
    (b"    for p,h in original['source_sha256'].items(): restored['source_sha256'][p] = h\n", b''),
    (b'"""Root-only mechanical freezer, NOT RUN and deployment-schema blocked.\n\nStage schema is pinned to Source E303/2120. Deployment schema must be supplied\nby Root from its real receipt before a NEW successor may enable this tool.',
     b'"""Root-only mechanical freezer, NOT RUN. Exact real receipts are mandatory.\n\nStage schema is the same Source36 output contract, including residual stage02.\nDeployment schema is exactly Root\'s declared ROOT_EXACT36 document, not inferred.')
]
inverse_ops = []
for before, after in ops:
    assert source.count(before) == 1, before[:100]
    # Deletion inverse records its original byte offset, not ambiguous empty-string replace.
    offset = source.index(before)
    source = source[:offset] + after + source[offset + len(before):]
    inverse_ops.append((offset,before,after))
inverse = source
for offset,before,after in reversed(inverse_ops):
    assert inverse[offset:offset+len(after)] == after
    inverse = inverse[:offset] + before + inverse[offset+len(after):]
assert inverse == old.read_bytes()
# Python-only syntax compilation. Does not execute the freezer or any imports.
compile(source, str(new), 'exec')
assert not new.exists()
new.write_bytes(source)
proof = {'status':'EXACT_ROOT_SCHEMA_FREEZER_TEXT_ONLY_NOT_EXECUTED',
    'old_pending_tool_sha256':sha(old.read_bytes()),'new_tool_sha256':sha(source),
    'wholebyte_offset_inverse':True,'Python_syntax_only_no_import_or_execution':True,
    'deployment_success_status':'ROOT_EXACT36_DEPLOYED_FIRST_FINAL_VERIFIED',
    'required_real_inputs':['Stage receipt path+SHA','deployment receipt path+SHA','NEW QA output directory'],
    'Stage_map_field':'nodes.expected_ch4_s3_luoyang_market_true.{path,sha256,value.source_sha256}',
    'not_current_fill':True,'real_actual_deployment_not_yet_claimed':True,
    'no_whole_guard_restore_fallback':True,
    'DB6B_key_functions_unchanged_future_exact4literal_freeze':True,
    'Source_Stage01_FAIL_not_retried_by_QA':True,'engine_or_Stage_collector_media_or_packet_calls':0}
proof_path = Q / 'freeze_market_journey36_exact_receipts_tool_inverse_NOTRUN.json'
assert not proof_path.exists()
proof_path.write_bytes((json.dumps(proof,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
diff = Q / 'freeze_market_journey36_exact_receipts_complete.diff'
assert not diff.exists()
diff.write_bytes(''.join(difflib.unified_diff(old.read_text().splitlines(True),source.decode().splitlines(True),fromfile=str(old),tofile=str(new))).encode())
print(json.dumps({'tool':sha(source),'proof':sha(proof_path.read_bytes())},indent=2))
