import copy
import difflib
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
SF = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT = GAME / 'build/luoyang_city_full_rollout_20261022ap_root01'
OUT = QA / 'yamen_performance07_ROOT30_READY'
assert not OUT.exists()
res = lambda p: GAME / p.removeprefix('res://')
rp = lambda p: 'res://' + p.relative_to(GAME).as_posix()
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
def fixed(p, digest):
    assert sha(p) == digest.lower(), str(p)
    return {'path': rp(p), 'sha256': digest.lower()}

oldkey = SF / 'performance28_yamen_light06_ROOT26/test_yamen_performance06_ROOT26_READY.gd'
oldfixture = SF / 'performance28_yamen_light06_ROOT26/yamen_performance06_fixture_ROOT26_READY.json'
fixed(oldkey, '6B5989D7401425AD138A8BDBC9B0FD7D8CE7B6E07B225A2566CAE3D32EC053D5')
fixed(oldfixture, '8174D7C32F48B666099CE753EE0306E0B372BB2B4841C73CED70E7C369DF8953')
ownerfile = SF / 'performance39_merged_EOF_actual_independent_review/owner_source_maps_READY.json'
ownerdesc = fixed(ownerfile, 'B2858260460AFE9C655FDD0ECA0B2408F11267E1AA313D23B0EE4CCBEE0A1D0C')
stagefile = SF / 'outputs/root_merged_G_parentcopy_DT_source_stage02/receipt.json'
stagedesc = fixed(stagefile, 'EB875D3AEED4C750D907CACFE8C5B12C93750D8BDDC84D63040A25295F082F6F')
guarddesc = fixed(ROOT / 'integration29/final_guard.json', '1F7815918EAB2341B82D38F7FDBF1274F85DD4A46C1AC963A93B3DF7585031A5')
copydesc = fixed(ROOT / 'integration29/generated_JSON_deployment_actual.json', '2FFD52CC40B0DBACAE3EE663251EB64E7D8C2D6CD0D287E487A5F35DD9F84592')
freshdesc = fixed(ROOT / 'integration30/guard_before.json', '0DF692A956F3F90FF2570982B4F3722B029292B41A5D8E1EBC66CDF20804BD9C')
owner, stage = read(ownerfile), read(stagefile)
guard, copies = read(res(guarddesc['path'])), read(res(copydesc['path']))
assert guard['passed'] and guard['checked'] == 2118 and guard['authorized_change_count'] == 29 and guard['exact_unchanged'] == 2089 and guard['save_count'] == 15 and guard['save_change_count'] == guard['unexpected_change_count'] == 0
assert copies['GD_copied'] == 0 and copies['native_or_save_writes'] == 0 and len(copies['rows']) == 14
targets = {x['target']: x for x in stage['targets']}
assert len(targets) == 29
for path, row in targets.items():
    assert sha(res(path)) == row['candidate_sha256'] and res(path).stat().st_size == res(row['candidate_path']).stat().st_size
adapter = res('res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd')
assert adapter.stat().st_size == 30746 and not adapter.read_bytes().endswith(b'\n') and sha(adapter) == '5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84'
assert owner['actual_stage_receipt'] == stagedesc and owner['fixed_prior_owner_sha256'] == '65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be'
yamen = next(x for x in owner['scenes'] if x['id'] == 'ch4_s1_luoyang_yamen')
assert len(yamen['source_sha256']) == 1234 and yamen['source_sha256'] == yamen['receipt_source_sha256']
old = read(oldfixture); fixture = copy.deepcopy(old)
fixture.update(status='AP15_ROOT30_PERFORMANCE07_ONE_DEFAULT_YAMEN_WITH_SIX_PASSIVE_DT_CHILDREN_READY_NOT_RUN', ready=True, blockers=[], pending_authority_not_in_source_guard_until_real_freeze=False)
table = dict(old['source_sha256'])
for path, value in owner['core_source_sha256'].items():
    if path in table: table[path] = value
table.update(yamen['source_sha256'])
oldauthority = old['authority']
replace_authorities = [(oldauthority['independent_owner'], ownerdesc), (oldauthority['actual_source_stage'], stagedesc), (oldauthority['actual_Root_deployment_guard'], guarddesc), (oldauthority['actual_Root_deployment_copy'], copydesc), (oldauthority['Root26_fresh_before'], freshdesc)]
for a, b in replace_authorities:
    assert table.pop(a['path']) == a['sha256']
    assert b['path'] not in table
    table[b['path']] = b['sha256']
old_ancestor = SF / 'performance17_yamen_light05_ROOT21/test_yamen_performance05_ROOT21_READY.gd'
assert table.pop(rp(old_ancestor)) == sha(old_ancestor)
table[rp(oldkey)] = sha(oldkey)
fixture['source_sha256'] = table
fixture['expected_city_source_sha256'] = dict(yamen['source_sha256'])
fixture['authority'] = {
    'fixed_prior_owner': oldauthority['independent_owner'], 'independent_owner': ownerdesc,
    'actual_source_stage': stagedesc, 'actual_Root_deployment_guard': {**guarddesc, 'pending': False},
    'actual_Root_deployment_copy': {**copydesc, 'pending': False}, 'Root30_fresh_before': freshdesc, 'formal_revision': 'AP15',
    'guard_count_boundary': 'Root29 checked2118 = original2117 protected domain plus explicitly declared existing adapter; legacy2117 status text retained.29authorized+2089same,15saves exactticks0.'
}
fixture['expected_source_count_recipe'] = {'fixed65BE': 1225, 'nine_new_declared_proof_leaves': 9, 'expected_count': 1234, 'actual_independent_owner_count_confirmed': 1234, 'not_actual_collector_observation': True}
fixture['required_DT_projection_children'] = ['projection_detail.g_project', 'projection_detail.layout_author', 'projection_detail.t_transform', 'projection_detail.parent_clones_and_receipts', 'projection_detail.b_restore_t', 'projection_detail.same_wire']
fixture['DT_children_rule'] = 'After frozen draw and natural owner only, inspect six required scalar children from the same single DT getter. Exact started/finished/wall relation, sequential order, each contained within original outer. Sum children only <=outer; no adding to outer. Other branch labels absent are missing, not measured zero. g_project includes SHA/read/JSON and prop projection, not isolated parsing.'
fixture['guard_derivation'] = 'Fixed06 guard; explicit B285 core replacement only for preexisting keys, all1234 independent Yamen values; replace five archived authority leaves with actualB285/EB875/Root29guard-copy/Root30before, and fixed05QAancestor with fixed06parent. No current-source hashes used to generate expected runtime values.'
fixture['district_timing_rule'] += ' Required six projection_detail child clocks must fit same recorded projection_and_whole_parent_inverse outer. No extra getter or per-frame DT read.'
assert all(table[p] == v for p, v in yamen['source_sha256'].items())
keypath = OUT / 'test_yamen_performance07_ROOT30_READY.gd'
fixturepath = OUT / 'yamen_performance07_fixture_ROOT30_READY.json'
fixture_bytes = (json.dumps(fixture, ensure_ascii=False, indent=2) + '\n').encode()
fixture_sha = hashlib.sha256(fixture_bytes).hexdigest()
text = oldkey.read_bytes().decode()
old_return = '\treturn check(same_owner and metrics.get("profile_origin")=="DISTRICT_SETUP_NOT_WARM_RESUME" and metrics.get("fresh_source_validation_credit")==false,"Saved DT setup token matches natural resident proof; never new freshness credit")\n'
new_return = '''\tif not check(same_owner and metrics.get("profile_origin")=="DISTRICT_SETUP_NOT_WARM_RESUME" and metrics.get("fresh_source_validation_credit")==false,"Saved DT setup token matches natural resident proof; never new freshness credit"): return false
\tvar spans: Variant=metrics.get("spans")
\tif not check(spans is Dictionary and fixture.required_DT_projection_children.size()==6,"Recorded DT spans and fixed six required children"): return false
\tvar outer: Variant=spans.get("projection_and_whole_parent_inverse")
\tif not check(outer is Dictionary,"Original DT outer span present; missing is not zero"): return false
\tvar outer_start: int=int(outer.get("started_usec",-1));var outer_end: int=int(outer.get("finished_usec",-1));var outer_wall: int=int(outer.get("wall_usec",-1))
\tif not check(outer_start>0 and outer_end>=outer_start and outer_wall==outer_end-outer_start,"Original DT outer clock units and interval exact"): return false
\tvar previous_end: int=outer_start;var child_sum: int=0;var child_facts: Array[Dictionary]=[]
\tfor label: String in fixture.required_DT_projection_children:
\t\tvar child: Variant=spans.get(label)
\t\tif not check(child is Dictionary,"Required passive DT child present, no synthetic zero: "+label): return false
\t\tvar child_start: int=int(child.get("started_usec",-1));var child_end: int=int(child.get("finished_usec",-1));var child_wall: int=int(child.get("wall_usec",-1))
\t\tif not check(child_start>=previous_end and child_end>=child_start and child_end<=outer_end and child_wall==child_end-child_start,"Sequential passive child contained in same outer: "+label): return false
\t\tprevious_end=child_end;child_sum+=child_wall
\t\tchild_facts.append({"label":label,"started_usec":child_start,"finished_usec":child_end,"wall_usec":child_wall})
\trecords.append({"kind":"PERF07_SIX_DT_CHILD_SPANS","same_owner":same_owner,"getter_read_count":district_timing_reads,"outer":outer,"children":child_facts,"child_sum_usec":child_sum,"outer_residual_usec":outer_wall-child_sum,"children_not_added_to_outer":true,"g_project_not_isolated_JSON_parse":true,"freshsource_credit":false})
\treturn check(child_sum<=outer_wall,"Six sequential child walls are contained, never added to outer")
'''
hunks = []
def change(a, b):
    global text
    assert text.count(a) == 1, a[:100]
    text = text.replace(a, b, 1); hunks.append({'old': a, 'new': b})
change('const FIXTURE="' + rp(oldfixture) + '"', 'const FIXTURE="' + rp(fixturepath) + '"')
change('const FIXTURE_SHA="' + sha(oldfixture) + '"', 'const FIXTURE_SHA="' + fixture_sha + '"')
change('fixture.expected_city_source_sha256.size()==1225', 'fixture.expected_city_source_sha256.size()==1234')
change('Fixed60s/0pictures/one default public entry/source1225', 'Fixed60s/0pictures/one default public entry/source1234')
change('Natural full1225 source map equals independent canonical-B successor owner', 'Natural full1234 source map equals independent merged AP15 owner')
change(old_return, new_return)
change('res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance27_yamen_light06/output/%d_%d', 'res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance07_ROOT30_READY/output/%d_%d')
text = text.replace('PERF06', 'PERF07')
text = text.replace('YAMEN_PERF07_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR', 'YAMEN_PERF07_ONE_DEFAULT_PUBLIC_ENTRY_SIX_DT_CHILDREN_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR')
key_bytes = text.encode()
inverse = text.replace('YAMEN_PERF07_ONE_DEFAULT_PUBLIC_ENTRY_SIX_DT_CHILDREN_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR', 'YAMEN_PERF07_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR').replace('PERF07', 'PERF06')
for h in reversed(hunks):
    replacement = h['new'].replace('PERF07', 'PERF06')
    assert inverse.count(replacement) == 1
    inverse = inverse.replace(replacement, h['old'], 1)
assert inverse.encode() == oldkey.read_bytes()
assert key_bytes.count(b'district.call("loading_timing_state")') == 1 and key_bytes.count(b'go_field_smart') == 1 and b'const WHOLE_MS=60000' in key_bytes
OUT.mkdir()
fixturepath.write_bytes(fixture_bytes); keypath.write_bytes(key_bytes)
keydiff = ''.join(difflib.unified_diff(oldkey.read_bytes().decode().splitlines(keepends=True), text.splitlines(keepends=True), fromfile=rp(oldkey), tofile=rp(keypath)))
fixdiff = ''.join(difflib.unified_diff(oldfixture.read_bytes().decode().splitlines(keepends=True), fixture_bytes.decode().splitlines(keepends=True), fromfile=rp(oldfixture), tofile=rp(fixturepath)))
(OUT / 'complete_key_vs06.diff').write_text(keydiff, encoding='utf-8', newline='')
(OUT / 'complete_fixture_vs06.diff').write_text(fixdiff, encoding='utf-8', newline='')
handoff = {'status': 'ROOT30_AP15_PERFORMANCE07_READY_NOT_RUN_NOT_PARSE_PASS', 'ready': True, 'key': {'path': rp(keypath), 'sha256': sha(keypath)}, 'fixture': {'path': rp(fixturepath), 'sha256': sha(fixturepath)}, 'parent06_key': {'path': rp(oldkey), 'sha256': sha(oldkey)}, 'whole_key_reverse_to_original06': True, 'hunks_before_label_only_replacement': hunks, 'label_only_replacement': 'PERF06->PERF07 plus six-children output label', 'owner_expected1234': ownerdesc, 'guard_count': len(table), 'five_authority_and_parent_key_replacements': True, 'no_live_collector_or_current_source_expected_fill': True, 'formal29_SHA_bytes_exact_and_adapter_final5709_30746_noLF': True, 'Root29_guard': guarddesc, 'Root29_copy': copydesc, 'Root30_before': freshdesc, 'all_original_cadence_drawfirst_naturalproof_getter1_scope60s_preserved': True, 'only_extra_behavior': 'After sole DT getter, six required passive scalar child intervals contained sequentially in same outer; missing fails, no synthetic zero.', 'no_warm_input_picture_geometry_collector_or_prior_FAIL_replay': True, 'diffs': {'key': {'path': rp(OUT / 'complete_key_vs06.diff'), 'sha256': sha(OUT / 'complete_key_vs06.diff')}, 'fixture': {'path': rp(OUT / 'complete_fixture_vs06.diff'), 'sha256': sha(OUT / 'complete_fixture_vs06.diff')}}, 'engine_parse_collector_native_decode_Stage_formal_writes': 0}
handfile = OUT / 'handoff_ROOT30_READY_NOT_RUN.json'
handfile.write_text(json.dumps(handoff, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'key': handoff['key'], 'fixture': handoff['fixture'], 'handoff': {'path': rp(handfile), 'sha256': sha(handfile)}, 'guard_count': len(table)}))
