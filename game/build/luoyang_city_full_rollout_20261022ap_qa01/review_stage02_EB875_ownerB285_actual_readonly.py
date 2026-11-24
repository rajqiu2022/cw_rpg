import copy
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
SF = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT = QA / 'stage02_EB875_ownerB285_independent_actual_merge_admission_READY.json'
assert not OUT.exists()
res = lambda p: GAME / p.removeprefix('res://')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
def strict(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return set(a) == set(b) and all(strict(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(strict(x, y) for x, y in zip(a, b))
    return a == b
def at(value, keys):
    for k in keys: value = value[k]
    return value
def restore(value, changes):
    value = copy.deepcopy(value)
    for d in reversed(changes):
        holder, key = at(value, d['pointer'][:-1]), d['pointer'][-1]
        if d['existed']: holder[key] = d['old']
        else: del holder[key]
    return value
def merge(*tables):
    result = {}
    for table in tables:
        for k, v in table.items():
            assert k not in result or result[k] == v, k
            result[k] = v
    return result
def replay(value, chunks):
    cursor, result = 0, []
    for a, b in chunks:
        pos = value.find(a, cursor)
        assert pos >= 0
        result += [value[cursor:pos], b]; cursor = pos + len(a)
    return ''.join(result) + value[cursor:]
def chunks(lines):
    result, left, right = [], [], []
    for line in lines:
        if line == '@@\n':
            if left or right: result.append((''.join(left), ''.join(right)))
            left, right = [], []
        else:
            assert line and line[0] in ' +-'
            if line[0] in ' -': left.append(line[1:])
            if line[0] in ' +': right.append(line[1:])
    if left or right: result.append((''.join(left), ''.join(right)))
    return result

receiptfile = SF / 'outputs/root_merged_G_parentcopy_DT_source_stage02/receipt.json'
ownerfile = SF / 'performance39_merged_EOF_actual_independent_review/owner_source_maps_READY.json'
reviewfile = SF / 'performance39_merged_EOF_actual_independent_review/source_stage_review_READY.json'
assert sha(receiptfile) == 'EB875D3AEED4C750D907CACFE8C5B12C93750D8BDDC84D63040A25295F082F6F'.lower()
assert sha(ownerfile) == 'B2858260460AFE9C655FDD0ECA0B2408F11267E1AA313D23B0EE4CCBEE0A1D0C'.lower()
assert sha(reviewfile) == 'ABD22EC9FB2F1FCDB34B5BDA383712D44B8568CC463BEC9538343AC52320C0F9'.lower()
d, owner, review = read(receiptfile), read(ownerfile), read(reviewfile)
assert d['source_first'] == d['source_final'] and len(d['source_first']) == 3033
assert d['target_partition'] == {'patch_count': 15, 'copy_count': 14, 'total': 29, 'intersection_empty': True, 'union_exact_targets': True}
planfile = SF / 'performance38_exact_EOF_transport_recipe/source_input_ROOT_LOCKED.json'
plan = read(planfile); pins = {x['id']: x for x in plan['pinned_inputs']}
assert sha(planfile) == d['source_first']['res://' + planfile.relative_to(GAME).as_posix()] == '077ee41741b8037c016b32d267dae03d8237b760677b486c16ba26c09908d8a8'
targets = {x['target']: x for x in d['targets']}
assert len(targets) == 29 and set(targets) == set(plan['root_target_allowlist'])
raws, unchanged_current = {}, []
for target, row in targets.items():
    candidate = res(row['candidate_path']).read_bytes()
    assert hashlib.sha256(candidate).hexdigest() == row['candidate_sha256']
    assert sha(res(target)) == row['old_sha256'] != row['candidate_sha256']
    raws[target] = candidate; unchanged_current.append(target)
metadata, indices = [], []
for n in plan['nodes']:
    ident = n['id']; node = d['nodes'][ident]
    raw = res(node['path']).read_bytes(); assert hashlib.sha256(raw).hexdigest() == node['sha256']
    if n['kind'] == 'metadata':
        original = read(res(pins[n['base_input']]['path']))
        assert strict(restore(node['value'], d['proofs'][ident]['source_delta']), original)
        assert strict(json.loads(raw), node['value']); metadata.append(ident)
    elif n['kind'] == 'index':
        original = res(pins[n['base_input']]['path']).read_bytes(); text = original.decode(); resolved = []
        for h in n['replacements']:
            v = h['new']
            if isinstance(v, dict): v = d['nodes'][v['$sha']]['sha256'] if '$sha' in v else pins[v['$pin']]['sha256']
            assert text.count(h['old']) == 1
            text = text.replace(h['old'], v, 1); resolved.append((h['old'], v))
        assert hashlib.sha256(text.encode()).hexdigest() == d['proofs'][ident]['disabled_sha256']
        assert text.count(n['disabled_literal']) == 1 and text.replace(n['disabled_literal'], n['enabled_literal'], 1).encode() == raw
        for a, b in reversed(resolved):
            assert text.count(b) == 1; text = text.replace(b, a, 1)
        assert text.encode() == original; indices.append(ident)
assert len(metadata) == 13 and len(indices) == 8
patchfile = res(d['patch_path']); assert sha(patchfile) == d['patch_sha256']
lines = patchfile.read_text(encoding='utf-8', newline='').splitlines(keepends=True) if False else patchfile.read_bytes().decode().splitlines(keepends=True)
assert lines[0] == '*** Begin Patch\n' and lines[-1] == '*** End Patch\n'
sections, current, body = {}, None, []
for line in lines[1:-1]:
    if line.startswith('*** Update File: '):
        if current is not None: sections[current] = chunks(body)
        current = line[len('*** Update File: '):].rstrip('\n'); body = []
    else: body.append(line)
if current is not None: sections[current] = chunks(body)
assert len(sections) == 15
adapter = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd'
for target, row in targets.items():
    if not target.endswith('.gd'): continue
    old, new = res(target).read_bytes(), raws[target]
    proof = d['patch_reconstruction'][target]
    if target == adapter:
        assert not old.endswith(b'\n') and not new.endswith(b'\n')
        old, new = old + b'\n', new + b'\n'
        assert proof['forward_exact_bytes'] is False and proof['whole_inverse_exact_bytes'] is False and proof['whole_shadow_inverse_exact_bytes'] is True
        assert proof['reconstructed_sha256'] == proof['patch_intermediate_sha256'] == '5676455a1a40646dadd9832fe27f124596e0624a58b137ff052b729cd6d88216'
        assert proof['candidate_sha256'] == proof['eof_format']['required_final_sha256'] == row['candidate_sha256']
        assert new[:-1] == raws[target] and len(new) == 30747 and proof['final_requires_exact_root_authorized_EOF_formatting']
    else:
        assert proof['forward_exact_bytes'] is True and proof['whole_inverse_exact_bytes'] is True
    c = sections[res(target).as_posix()]
    assert replay(old.decode(), c).encode() == new and replay(new.decode(), [(b, a) for a, b in c]).encode() == old
copyfile = res(d['byte_copy_plan']['path']); copies = read(copyfile)
assert sha(copyfile) == d['byte_copy_plan']['sha256'] and len(copies['rows']) == 14
copytargets = {x['target'] for x in copies['rows']}
assert copytargets == {x for x in targets if x.endswith('.json')}
assert {Path(x).as_posix() for x in sections}.isdisjoint({res(x).as_posix() for x in copytargets})
priorfile = SF / 'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json'
assert sha(priorfile) == '65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be'
prior = read(priorfile); prior_scenes = {x['id']: x for x in prior['scenes']}
new_scenes = {x['id']: x for x in owner['scenes']}
hand = read(res(pins[plan['B_only_contract']['production_input']]['path']))
newproofs = hand['new_proof_sources_exact9']; assert len(newproofs) == 9
def replace(table):
    v = dict(table)
    for path, row in targets.items():
        if path in v:
            assert v[path] == row['old_sha256']; v[path] = row['candidate_sha256']
    return v
for n in plan['nodes']:
    if n['kind'] == 'map':
        row = new_scenes[n['scene_id']]
        assert row['source_sha256'] == row['receipt_source_sha256'] == d['nodes'][n['id']]['value']['source_sha256']
quarter = d['nodes']['quarter_final']['value']['source_sha256']
for ident in ['luoyang_artisan_residential_20261022ap', 'luoyang_riverside_garden_20261022ap']:
    old = prior_scenes[ident]; headers = {p: s for p, s in old['source_sha256'].items() if p not in old['receipt_source_sha256']}
    assert new_scenes[ident]['source_sha256'] == merge(quarter, replace(headers)) and new_scenes[ident]['receipt_source_sha256'] == quarter
ident = 'luoyang_estate_riverside_20261021ai'
assert new_scenes[ident]['source_sha256'] == replace(prior_scenes[ident]['source_sha256']) and new_scenes[ident]['receipt_source_sha256'] == replace(prior_scenes[ident]['receipt_source_sha256'])
ident = 'ch4_s4_ancient_temple'; expected = merge(replace(prior_scenes[ident]['source_sha256']), newproofs)
assert new_scenes[ident]['source_sha256'] == new_scenes[ident]['receipt_source_sha256'] == expected
for ident, old in prior_scenes.items():
    assert {k: v for k, v in new_scenes[ident].items() if k not in ['source_sha256', 'receipt_source_sha256', 'recipe']} == {k: v for k, v in old.items() if k not in ['source_sha256', 'receipt_source_sha256', 'recipe']}
old_rooms = {x['id']: x for x in prior['rooms']}
for row in owner['rooms']:
    old = old_rooms[row['id']]
    assert row['source_sha256'] == merge(replace(old['source_sha256']), newproofs)
    assert row['receipt_source_sha256'] == replace(old['receipt_source_sha256']) == d['nodes']['registry_final']['value']['rooms'][row['id']]['source_sha256']
assert owner['core_source_sha256'] == {**prior['core_source_sha256'], **{p: r['candidate_sha256'] for p, r in targets.items()}}
union = merge(*(r[f] for r in owner['scenes'] + owner['rooms'] for f in ['source_sha256', 'receipt_source_sha256']))
oldunion = merge(*(r[f] for r in prior['scenes'] + prior['rooms'] for f in ['source_sha256', 'receipt_source_sha256']))
counts = {'changed_targets': 0, 'stage_declared': 0, 'inherited_not_rehashed': 0}
for path, value in union.items():
    if path in targets: assert value == targets[path]['candidate_sha256']; counts['changed_targets'] += 1
    elif path in d['source_first']: assert value == d['source_first'][path]; counts['stage_declared'] += 1
    else: assert value == oldunion[path]; counts['inherited_not_rehashed'] += 1
assert counts == {'changed_targets': 25, 'stage_declared': 2929, 'inherited_not_rehashed': 6} and len(union) == 2960
guardfile = GAME / 'build/luoyang_city_full_rollout_20261022ap_root01/integration29/guard_before.json'
guard = read(guardfile)
assert sha(guardfile) == 'c2633e5dc77bd69a7821351fa288e01e1110556fc5fd20922ce53bdf08e7ea3d'
savefacts = [x for x in guard['facts'] if x['path'] in guard['save_paths']]
assert len(savefacts) == 15
for f in savefacts:
    path = Path(f['path'])
    if f['sha256'] == 'ABSENT': assert not path.exists()
    else: assert sha(path) == f['sha256'] and path.stat().st_size == f['bytes']
out = {
    'status': 'INDEPENDENT_ACTUAL_STAGE02_AND_OWNER_CONFIRMED_FOR_ROOT_EXACT_MERGE_PLANNING_NOT_DEPLOYED_OR_FIELD_PASS',
    'stage_receipt_sha256': sha(receiptfile), 'owner_sha256': sha(ownerfile), 'source_review_sha256': sha(reviewfile),
    'actual': {'targets': 29, 'GD_patch': 15, 'JSON_exactcopy': 14, 'metadata_whole_strict_typed_inverse': metadata, 'index_complete_byte_inverse': indices, 'literal_patch_forward_inverse': 14, 'adapter_only_whole_shadow_forward_inverse': 1, 'source_first_final_exact_declarations_not_rehashed': 3033, 'current29_still_old_SHA': True, 'fifteen_save_current_SHA_bytes_equal_Root_C263_before': True, 'save_exactticks_before_guard_inherited_not_new_after_measurement': True},
    'EOF': {'final_candidate_sha256': targets[adapter]['candidate_sha256'], 'intermediate_sha256': d['patch_reconstruction'][adapter]['patch_intermediate_sha256'], 'intermediate_bytes': 30747, 'final_bytes': 30746, 'direct_final_patch_credit': False, 'Root_authorized_formatter_still_required_before_engine': True, 'no_candidate_GDcopy': True},
    'independent_owner_recipe': {'fixed65BE_plus_explicit29_and9_proofs': True, 'no_current_collector_fill': True, 'union': len(union), **counts, 'scene_counts': {k: {'collector': len(v['source_sha256']), 'receipt': len(v['receipt_source_sha256'])} for k, v in new_scenes.items()}, 'room_counts': {x['id']: {'collector': len(x['source_sha256']), 'receipt': len(x['receipt_source_sha256'])} for x in owner['rooms']}, 'all_scene_native_identities_inherited': True, 'only_five_receipt_DT_values_migrated': True},
    'boundary': 'Stage02 actual success does not rewrite Stage35/session95129 failure or2A4F missing EOF transport check. No canonical deployment performed here. Runtime owner pins remain expected future sources until Root deployment and exact EOF finalization. Next key can inherit original06 single-entry scope with1234 expected sources and passive DT child labels; no warm/menu/geometry expansion.',
    'operations': {'engine': 0, 'Stage_or_stager_import': 0, 'collector': 0, 'packet_or_image_decode': 0, 'large_media_hash': 0, '3033_source_rehash': 0, 'canonical_writes': 0, 'NEW_QA_receipt_only': True}
}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(OUT), 'sha256': sha(OUT), 'counts': counts}))
