"""NEW-only cumulative original-before provenance; no baseline rewriting."""
import importlib.util, json
from pathlib import Path

OWN = Path(__file__).resolve().parent
REPO = OWN.parents[2]
spec = importlib.util.spec_from_file_location('header05', OWN / 'prepare_culture_header05.py')
p05 = importlib.util.module_from_spec(spec); spec.loader.exec_module(p05)
h = p05.h
root03 = REPO / 'game/build/world_coast_20261031h_system03/sealed_candidate03'
root04 = REPO / 'game/build/world_coast_20261031h_system04/sealed_candidate04'
root05 = OWN / 'sealed_candidate05'
r03 = json.loads((root03 / 'receipt_REVIEW_ONLY.json').read_bytes())
r04 = json.loads((root04 / 'receipt_REVIEW_ONLY.json').read_bytes())
r05 = json.loads((root05 / 'receipt_REVIEW_ONLY.json').read_bytes())
baseline_path = REPO / 'game/build/world_coast_20261031h_qa01/baseline_NOW_ACTUAL.json'
baseline_raw = baseline_path.read_bytes(); baseline = json.loads(baseline_raw)
facts = {p.lower(): fact for p, fact in baseline['facts'].items()}
rows = []
entries = [(row['path'], row['before_sha256'], root03 / 'before' / row['path']) for row in r03['targets']]
entries += [('game/' + p05.COORD[6:], r04['all_38_before_pins'][p05.COORD], root04 / 'before/game' / p05.COORD[6:])]
entries += [('game/' + p05.CT[6:], r05['all_39_before_pins'][p05.CT], root05 / 'before/game' / p05.CT[6:])]
assert len(entries) == len({p for p, _, _ in entries}) == 39
for relative, digest, frozen in entries:
    raw = frozen.read_bytes(); assert h.sha(raw) == digest
    absolute = (REPO / relative).as_posix()
    fact = facts.get(absolute.lower())
    if fact is not None: assert fact['sha256'] == digest and fact['bytes'] == len(raw)
    rows.append({'path': relative, 'original_before_sha256': digest, 'original_before_bytes': len(raw), 'frozen_original_before_archive': frozen.as_posix(), 'original3221_fact_present': fact is not None, 'original3221_fact': fact})
result = {'status': 'CUMULATIVE_ORIGINAL39_PROVENANCE_NOT_A_NEW_BASELINE', 'original3221_baseline_sha256': h.sha(baseline_raw), 'original3221_source_count': baseline['source_count'], 'original3221_save_count': baseline['save_count'], 'original_baseline_not_modified': True, 'original_37_from': root03.as_posix(), 'Coordinator_original_from': root04.as_posix(), 'CT_original_from': root05.as_posix(), 'CT_original3221_fact_present': False, 'all39_original_before_sha256': {'res://' + row['path'][5:]: row['original_before_sha256'] for row in rows}, 'rows': rows, 'count': 39, 'engine_runs': 0, 'production_writes': 0, 'real_save_reads_or_writes': 0}
encoded = h.encode(result)
h.write_new(root05, 'cumulative39_original_before_PROVENANCE.json', encoded)
print(json.dumps({'count': 39, 'present_in_original3221_facts': sum(row['original3221_fact_present'] for row in rows), 'CT_present_in_original3221_facts': False, 'sha256': h.sha(encoded)}))
