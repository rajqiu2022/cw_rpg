import copy
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
SF = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
DIR = SF / 'performance38_exact_EOF_transport_recipe'
OUT = QA / 'exactEOF38_4449_077E_independent_transport_static_admission_READY.json'
assert not OUT.exists()
res = lambda p: GAME / p.removeprefix('res://')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
tool = SF / 'stage_performance38_exact_EOF_transport_READY.py'
inputfile = DIR / 'source_input_ROOT_LOCKED.json'
proofile = DIR / 'driver_input_owner_whole_inverse_READY.json'
assert sha(tool) == '4449A867DBAED67528000507C8F8903C7CDB46F3E36A50FDC9F0B47FD1C220B1'.lower()
assert sha(inputfile) == '077EE41741B8037C016B32D267DAE03D8237B760677B486C16BA26C09908D8A8'.lower()
assert sha(proofile) == 'FC1BB220B44775774AD9972CB65BA20DA1CF11AADE0102BB1726FB88A90E6237'.lower()
p = read(proofile)
oldtool = res(p['parent_tool']['path']).read_bytes()
newtool = tool.read_bytes()
forward, inverse = [], []
oc = nc = 0
for h in p['tool_hunks']:
    a, b, c, e = h['old_start'], h['old_end'], h['new_start'], h['new_end']
    assert oldtool[a:b] == h['old'].encode() and newtool[c:e] == h['new'].encode()
    assert oldtool[oc:a] == newtool[nc:c]
    forward += [oldtool[oc:a], h['new'].encode()]
    inverse += [newtool[nc:c], h['old'].encode()]
    oc, nc = b, e
forward.append(oldtool[oc:]); inverse.append(newtool[nc:])
assert b''.join(forward) == newtool and b''.join(inverse) == oldtool and len(p['tool_hunks']) == 3
oldfile = res(p['parent_input']['path'])
old, new = read(oldfile), read(inputfile)
back = copy.deepcopy(new)
back['output_root'] = old['output_root']
back['required_generator'] = copy.deepcopy(old['required_generator'])
del back['B_only_contract']['eof_transport_input']
added = back['pinned_inputs'].pop()
assert added['id'] == new['B_only_contract']['eof_transport_input'] == 'adapter_exact_EOF_transport_Root'
assert added['sha256'] == '184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97' and sha(res(added['path'])) == added['sha256']
assert back == old and (json.dumps(back, ensure_ascii=False, indent=2) + '\n').encode() == oldfile.read_bytes()
assert len(new['pinned_inputs']) == 50 and len(old['pinned_inputs']) == 49 and new['pinned_inputs'][:-1] == old['pinned_inputs']
assert new['authority_input'] == old['authority_input'] and new['nodes'] == old['nodes'] and new['source_groups'] == old['source_groups']
assert new['output_root'].endswith('outputs/root_merged_G_parentcopy_DT_source_stage02/') and not res(new['output_root']).exists()
approval = read(res(added['path']))
before = res(approval['target']).read_bytes()
after = (SF / 'performance30_domain_parent_copy_candidate01/finite_adapter_domain_copies_CANDIDATE.gd').read_bytes()
assert hashlib.sha256(before).hexdigest() == approval['old_sha256'] and len(before) == 30356 and not before.endswith(b'\n')
assert hashlib.sha256(after).hexdigest() == approval['candidate_sha256'] and len(after) == 30746 and not after.endswith(b'\n')
assert b'\r' not in before + after
assert hashlib.sha256(before + b'\n').hexdigest() == '658d258521194a63557fc255f1e8c05b975b389ed7103924af536dd3ecdaa72c'
assert hashlib.sha256(after + b'\n').hexdigest() == approval['patch_intermediate_sha256'] and len(after + b'\n') == 30747
isolated = (GAME / 'build/luoyang_city_full_rollout_20261022ap_root01/integration29/apply_patch_crlf_mechanism_probe.source').read_bytes()
assert isolated == after + b'\n' and isolated[:-1] == after
assert sha(SF / 'stage_unified06_04_READY.py') == '8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
owner = res(p['owner_tool_new']['path']).read_bytes()
oldowner = res(p['owner_tool_parent']['path']).read_bytes()
assert hashlib.sha256(owner).hexdigest() == p['owner_tool_new']['sha256'] and hashlib.sha256(oldowner).hexdigest() == p['owner_tool_parent']['sha256']
changes = [
    ('performance39_merged_EOF_actual_independent_review/', 'performance36_merged_actual_independent_review/'),
    ('performance38_exact_EOF_transport_recipe/source_input_ROOT_LOCKED.json', 'performance35_merged_source_recipe/source_input_ROOT_LOCKED.json'),
    ('077ee41741b8037c016b32d267dae03d8237b760677b486c16ba26c09908d8a8', 'e90077daf5c95a22559b6fd82ceff31cf9974cc42be0021e4bbf2e5b1e654d6b'),
    ('outputs/root_merged_G_parentcopy_DT_source_stage02/receipt.json', 'outputs/root_merged_G_parentcopy_DT_source_stage01/receipt.json')
]
for a, b in changes:
    assert owner.count(a.encode()) == 1
    owner = owner.replace(a.encode(), b.encode())
assert owner == oldowner
out = {
    'status': 'NO_STATIC_BLOCKER_FOR_ROOT_ONE_NEW_EXACT_EOF_STAGE02_NOT_DEPLOYMENT',
    'tool_sha256': sha(tool), 'input_sha256': sha(inputfile), 'inverse_sha256': sha(proofile),
    'inherited35_DAG_review': '2A4F322B3038D36A8F6CD11A896FFAB2799843A44CD1FB2FD6AD16B4C6123B46 with preserved missedEOF limitation715526; not a Stage35 PASS',
    'new_checks': {'three_tool_hunks_offset_whole_forward_reverse_to71C6': True, 'four_input_fields_whole_typed_and_UTF8_byte_inverse_toE900': True, 'original49_pins_and_all_nodes_groups_025E_candidate_bytes_unchanged': True, 'new50th_pin_Root184A_SHA_current_exact': True, 'core8DE0_SHA_exact_not_imported': True, 'owner_tool_only_four_header_literals_whole_byte_inverse_E24B': True, 'stage02_output_root_absent': True},
    'EOF_contract': {'only_target': approval['target'], 'old_sha256': approval['old_sha256'], 'candidate_sha256': approval['candidate_sha256'], 'old_shadow_bytes': 30357, 'old_shadow_sha256': '658d258521194a63557fc255f1e8c05b975b389ed7103924af536dd3ecdaa72c', 'new_shadow_bytes': 30747, 'new_shadow_sha256': approval['patch_intermediate_sha256'], 'actual_Root_isolated_file_full30746_leading_equal_and_sole_final0A_reconfirmed': True, 'strict_generator_only_invoked_on_two_in_memory_shadows': True, 'other14_GD_direct_original_strict_rule': True, 'no_CR_BOM_whitespace_normalization': True, 'final5709_not_claimed_direct_patch_reconstruction': True},
    'proof_reading': 'New proof marks forward_exact_bytes and whole_inverse_exact_bytes false, intermediate and shadow whole-inverse true; it retains distinct raw before/candidate and intermediate hashes/lengths. Future Root must require complete deployed567645/30747B, remove only final0A from deployed characters and require final5709/30746B; no candidate GD copy. Stage prepares evidence only; it does not perform formatting or deployment.',
    'preservation': 'Same29 targets,15GD14JSON, source FIRST/FINAL validators, required gates, all buffered writes,025E authority, native/room geometry and source candidates unchanged. Stage35/session95129 trueFAIL and earlier missed transport check retained. No new key/warm test.',
    'operations': {'Stage_or_stager_import': 0, 'engine': 0, 'collector': 0, 'packet_decode': 0, 'large_media_hash': 0, 'canonical_writes': 0, 'only_new_QA_receipt': True}
}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(OUT), 'sha256': sha(OUT)}))
