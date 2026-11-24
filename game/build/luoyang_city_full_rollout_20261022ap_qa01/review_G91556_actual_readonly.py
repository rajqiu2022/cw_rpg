import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
BUILD = GAME / 'build'
ROOT = BUILD / 'luoyang_city_full_rollout_20261022ap_root01/integration27'
REPORT = BUILD / 'luoyang_city_full_rollout_20261022ap_system01/room_known_real_domain_probe_epoch01/output/91556_1785/result.json'
OUT = QA / 'G91556_independent_actual_component_review_READY.json'
assert not OUT.exists()
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest().upper()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
d = read(REPORT)
assert sha(REPORT) == '96F480968315D99D62BB1B4D243AEEA12203770614E86BD6156FADECA1E7FD8E'
pfile = ROOT / 'G_cached_domain_once_process_receipt.json'
p = read(pfile)
assert sha(pfile) == 'B83B9BF357A928D95C42CB9EECD0B75754D94B3A3E8F21B5DCB993A65BC5F66F'
assert p['actual_natural_console_exit_code'] == 0 and p['exit_code_from_retained_process_WaitForExit'] is True and not p['process_stopped_by_tool']
assert p['script_sha256'] == p['script_after_sha256'] == '03f2494df72d3b16f9324af0741cdf784afba036074fa25c403de493ee2e8c51'
assert d['passed'] and d['checks'] == 1266 and not d['failures'] and d['elapsed_ms'] == 715 < d['limit_ms'] == 15000
assert d['source_first'] == d['source_final'] and len(d['source_first']) == 42
savedir = Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for path, fact in d['source_first'].items():
    file = GAME / path.removeprefix('res://')
    assert fact['exists'] and sha(file) == fact['sha256'] and file.stat().st_size == fact['bytes'] and int(file.stat().st_mtime) == fact['mtime_seconds'], path
assert len(d['fifteen_saves_before']) == 15 and d['fifteen_saves_before'] == d['fifteen_saves_after']
for path, fact in d['fifteen_saves_after'].items():
    file = savedir / path.removeprefix('user://')
    assert file.exists() == fact['exists'], path
    if file.exists():
        assert sha(file) == fact['sha256'] and file.stat().st_size == fact['bytes'] and int(file.stat().st_mtime) == fact['mtime_seconds'], path
assert d['autoload_identity_before'] == d['autoload_identity_after'] and len(d['autoload_identity_before']) == 16
o = d['observations']
assert o['synthetic_cases'] == 288 and len(o['actual_domain']['ids']) == 12
assert o['actual_domain']['same_complete_public_typed_bytes'] and o['actual_domain']['complete_public_catalogue_bytes'] == 1886144
assert o['actual_domain']['complete_public_catalogue_sha256'] == 'D8EC8B07B9099E0C41D8DD228131EFCE7A16C001F98D5A41AF6444A66C3A358E'
assert len(o['queries']) == len(set(o['queries'])) == 22 and sum(o['expected_membership'].values()) == 12
assert o['scripts']['old']['resource_id'] != o['scripts']['new']['resource_id']
for label in ('old', 'new'):
    s = o['scripts'][label]
    assert s['cache_empty_before'] and not s['cache_empty_after'] and s['explicit_catalogue_calls'] == 1
    assert sum(row[label]['calls'] for row in d['paired_cached_rows']) == o['cached_totals'][label + '_calls'] == 88
    assert sum(row[label]['elapsed_usec'] for row in d['paired_cached_rows']) == o['cached_totals'][label + '_usec']
for i, row in enumerate(d['paired_cached_rows']):
    assert row['round'] == i and row['order'] == (['old', 'new'] if i % 2 == 0 else ['new', 'old'])
    assert all(row[label]['calls'] == 22 and row[label]['hits'] == 12 for label in ('old', 'new'))
logs = {}
for label in ('stdout', 'stderr'):
    file = Path(p[label + '_path'])
    assert sha(file).lower() == p[label + '_sha256']
    logs[label] = file.read_text(encoding='utf-8-sig')
combined = '\n'.join(logs.values())
assert combined.count('WARNING:') == 1 and 'ObjectDB instances leaked at exit' in combined
assert 'ERROR:' not in combined and 'SCRIPT ERROR:' not in combined
guardfile = ROOT / 'final_guard.json'
guard = read(guardfile)
assert sha(guardfile) == '66D2A3D24C733119D59ADE3DC73586600FD4EE41191070D0F77A34E21A4D3F3D'
assert guard['passed'] and guard['checked'] == guard['exact_unchanged'] == 2117 and guard['save_count'] == 15 and guard['save_change_count'] == guard['unexpected_change_count'] == guard['authorized_change_count'] == 0
out = {
    'status': 'INDEPENDENT_READONLY_ACTUAL_G_COMPONENT_OBSERVATION_CONFIRMED_NOT_FIELD_OR_FORMAL_ADMISSION',
    'actual_report': {'path': str(REPORT), 'sha256': sha(REPORT), 'checks': 1266, 'failed_checks': 0, 'elapsed_ms': 715},
    'process': {'receipt_sha256': sha(pfile), 'true_console_exit': 0, 'wall_ms': p['elapsed_wall_ms'], 'warnings': 1, 'errors': 0, 'script_errors': 0, 'warning_clean': False},
    'source': {'first_final_current_exact_seconds': 42, 'fifteen_saves_first_final_current_exact_seconds': True, 'external_guard_sha256': sha(guardfile), 'external_guard_2117_and_save_exactticks_credit_only_not_rehashed': True, 'autoload_identities_exact': 16},
    'semantics': {'synthetic_cases': 288, 'real_room_keys': 12, 'public_catalogue_bytes': 1886144, 'public_catalogue_sha256': o['actual_domain']['complete_public_catalogue_sha256'], 'complete_typed_equal_actual_assertion_inherited_not_redecoded': True, 'both_natural_caches_empty_before_populated_after': True, 'distinct_script_resource_ids': True},
    'timing': {'explicit_catalogue_calls_per_version': 1, 'old_first_explicit_usec': o['scripts']['old']['first_explicit_catalogue_usec'], 'new_first_explicit_usec': o['scripts']['new']['first_explicit_catalogue_usec'], 'timed_calls_per_version': 88, 'extra_before_after_semantic_calls_per_version': 44, 'old_cached_total_usec': 158446, 'new_cached_total_usec': 1545, 'old_per_query_mean_usec': 158446 / 88, 'new_per_query_mean_usec': 1545 / 88, 'rounds': d['paired_cached_rows']},
    'limits': ['Warm component only; four deterministic alternating pairs share dependencies, CPU and OS caches. No disk/process-cold or statistical significance claim.', '158446 and1545 are totals across all four rounds, not per-round values to multiply again. No assumed number of Field queries or guaranteed Field latency saving.', 'Cache-cold only refers to each observed pre-empty Script cache; initial authentication excluded from warm clocks.', 'No Field, collector, geometry, source runtime FIRST/FINAL, media, <10s, full-city ART or formal G promotion credit.', 'ObjectDB exit warning preserved. Root retained actual exit0, not warning-free clean.'],
    'review_operations': {'engine': 0, 'collector': 0, 'registry_payload_parse': 0, 'typed_packet_decode': 0, 'canonical_writes': 0, 'new_review_receipt_only': True}
}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(OUT), 'sha256': sha(OUT), 'status': out['status']}))
