"""Read-only audio adoption guard. Reports are new-only; never launches Godot."""
from __future__ import annotations
import argparse
import configparser
import json
import sys
import wave
from pathlib import Path
import numpy as np
from verify_wuxia_audio_loops import ROOT, record, changes, sha

OUT = ROOT / 'assets/processed/audio/wuxia_audio_install_qa_20261011'
MANIFEST = ROOT / 'assets/processed/audio/wuxia_music_integration_20261011/asset_manifest.json'

def verify() -> dict:
    before = json.loads((OUT / 'before.json').read_text(encoding='utf-8'))
    sealed = json.loads((OUT / 'sealed_sources_before.json').read_text(encoding='utf-8'))
    manifest = json.loads(MANIFEST.read_text(encoding='utf-8'))
    rows = []
    for asset in manifest['assets']:
        source = ROOT / asset['source']['path']
        dest = ROOT / asset['destination']['path']
        r = record(dest)
        assert r['sha256'] == asset['destination']['sha256'] == asset['source']['sha256'] == sha(source), asset['id']
        assert r['bytes'] == asset['destination']['size'] == asset['source']['size']
        with wave.open(str(dest), 'rb') as wav:
            frames, rate, channels, width = wav.getnframes(), wav.getframerate(), wav.getnchannels(), wav.getsampwidth()
            pcm = np.frombuffer(wav.readframes(frames), dtype='<i2')
        assert channels == 2 and rate == 44100 and width == 2 and len(pcm) == frames * channels
        assert frames == asset['audio']['frames'] == asset['required_runtime_loop']['loop_end']
        assert len(pcm) and np.any(pcm) and not np.any((pcm == -32768) | (pcm == 32767))
        importer = Path(str(dest) + '.import')
        importer_record = None
        if importer.exists():
            config = configparser.ConfigParser(interpolation=None)
            config.read(importer, encoding='utf-8')
            params = config['params']
            assert params['compress/mode'] == '0', asset['id'] + ' must remain PCM'
            for key in ('force/8_bit', 'force/mono', 'force/max_rate', 'edit/trim', 'edit/normalize'):
                assert params[key] == 'false', asset['id'] + ' ' + key
            importer_record = record(importer)
        rows.append(dict(id=asset['id'], resource_path=asset['resource_path'], frames=frames, rate=rate, channels=channels, peak=float(np.max(np.abs(pcm.astype(np.int32)))) / 32768, destination=r, importer=importer_record))
    assert len(rows) == len({x['id'] for x in rows}) == 23
    protection = {key: changes(before[key]) for key in ('player_files', 'original_audio_files', 'canonical_scene_tres_files')}
    # Existing source changes are authorized and reviewed separately; asset and save changes are not.
    protection['sealed_sources'] = changes(sealed['files'])
    copy_journal = json.loads((MANIFEST.parent / 'adoption_source_journal.json').read_text(encoding='utf-8'))
    original_inventory = [dict(path=str((ROOT / row['path']).resolve()), exists=True, bytes=row['size'], mtime_ns=row['mtime_ns'], sha256=row['sha256']) for row in copy_journal['old_audio_before']]
    protection['producer_before_full_audio_inventory'] = changes(original_inventory)
    archive_journal = OUT / 'archived_class_ignore_journal.json'
    if archive_journal.exists():
        archive = json.loads(archive_journal.read_text(encoding='utf-8'))
        protection['archive_604_existing_files'] = changes(archive['archive_files_before'])
        protection['first_archive_marker'] = changes([archive['ignore_after']])
    roots_plan = OUT / 'archive_roots_ignore_plan.json'
    roots_applied = OUT / 'archive_roots_ignore_applied.json'
    if roots_plan.exists() and roots_applied.exists():
        plan = json.loads(roots_plan.read_text(encoding='utf-8'))
        applied = json.loads(roots_applied.read_text(encoding='utf-8'))
        protection['collision_321_gd_sources'] = changes(plan['collision_source_files'])
        protection['four_existing_archive_markers'] = changes([r for r in plan['markers'] if r['exists']])
        protection['two_added_archive_markers'] = changes(applied['added_markers'])
    return dict(scope='23_COPIES_PCM_AND_PROTECTED_ORIGINALS_ONLY', asset_manifest=record(MANIFEST), assets=rows, protection=protection, pass_=not any(protection.values()), godot_started=False, musical_quality='USER_APPROVED_SELECTION; runtime verification separate')

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    path = OUT / args.report
    assert path.resolve().is_relative_to(OUT.resolve()) and path.suffix == '.json' and not path.exists()
    try:
        result = verify()
    except Exception as exc:
        result = {'pass_': False, 'exception': type(exc).__name__ + ': ' + str(exc)}
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'pass': result['pass_'], 'report': str(path), 'sha256': sha(path)}))
    return 0 if result['pass_'] else 1

if __name__ == '__main__':
    sys.exit(main())
