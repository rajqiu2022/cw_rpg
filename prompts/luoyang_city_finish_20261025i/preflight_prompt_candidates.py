"""Offline exact prompt rendering + append-only task patch proposal. No generation/network."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUT = ROOT / 'game/build/luoyang_city_finish_20261025i_art01'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def new(path, raw):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(raw)
    return {'path': str(path.relative_to(ROOT)).replace('\\', '/'), 'sha256': sha(raw), 'bytes': len(raw)}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--candidates', nargs='+', required=True)
    parser.add_argument('--output-stem', required=True)
    args = parser.parse_args()
    assert '/' not in args.output_stem and '\\' not in args.output_stem
    spec = importlib.util.spec_from_file_location('existing_prompt_renderer_25i', ROOT / 'scripts/gen_assets.py')
    gen = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gen)
    table_path = ROOT / 'prompts/tasks.yaml'
    before = table_path.read_bytes()
    before_stat = table_path.stat()
    queue = gen.load_yaml(table_path)
    tasks = queue['tasks'] if isinstance(queue, dict) else queue
    old_ids = [row['id'] for row in tasks]
    shared = gen.load_yaml(gen.SHARED_FILE)
    suffix = ''
    rows = []
    seen = set(old_ids)
    for candidate in args.candidates:
        path = HERE / candidate
        assert path.parent == HERE
        raw = path.read_bytes()
        parsed = gen.load_yaml(path)
        assert isinstance(parsed, list) and len(parsed) >= 1
        suffix += '\n' + raw.decode('utf-8').strip('\n') + '\n'
        for task in parsed:
            assert task['id'] not in seen
            seen.add(task['id'])
            assert task['execution_backend'] == 'builtin_image_gen'
            assert task['skip'] is True and task['attempt_budget'] == 1
            assert task['retries_allowed'] is False and task['cli_fallback_allowed'] is False
            assert task['model'] is None and task['provider'] is None and task['cost'] is None
            assert task['reference_images'] == []
            prompt_path = ROOT / task['prompt_path']
            assert prompt_path.parent == HERE
            prompt = prompt_path.read_text(encoding='utf-8')
            rendered = gen.render_template(task['template'], {'asset_prompt': prompt}, shared)
            assert rendered['prompt'] == prompt.strip()
            assert rendered['reference_images'] == []
            assert rendered['background'] == ('transparent' if task['transparent_background'] else 'opaque')
            rows.append({'id': task['id'], 'prompt_path': task['prompt_path'], 'prompt_sha256': sha(prompt_path.read_bytes()), 'rendered_prompt': rendered['prompt'], 'rendered_prompt_sha256': sha(rendered['prompt'].encode()), 'candidate_path': str(path.relative_to(ROOT)).replace('\\', '/'), 'candidate_sha256': sha(raw), 'transparent_background': task['transparent_background'], 'builtin_brand_new_call_omit_both_reference_parameters': True})
    after = before + suffix.encode()
    assert after[:-len(suffix.encode())] == before
    assert table_path.read_bytes() == before and table_path.stat().st_mtime_ns == before_stat.st_mtime_ns
    # A proposal only. Root reviews and applies it; this script never changes tasks.yaml.
    final_line = before.decode('utf-8').rstrip('\n').splitlines()[-1]
    patch = '*** Begin Patch\n*** Update File: F:/Code/RPG_GAME/prompts/tasks.yaml\n@@\n ' + final_line + '\n' + ''.join('+' + line + '\n' for line in suffix.splitlines()) + '*** End Patch\n'
    patch_record = new(OUT / (args.output_stem + '.apply_patch'), patch.encode())
    report = {'status': 'BUILTIN_CANDIDATE_OFFLINE_DRY_RENDER_PASS_NOT_REGISTERED_NOT_GENERATED', 'passed': True, 'task_table_before': {'path': 'prompts/tasks.yaml', 'sha256': sha(before), 'bytes': len(before), 'mtime_ns': before_stat.st_mtime_ns}, 'proposed_appended_table_sha256': sha(after), 'append_suffix': suffix, 'exact_append_inverse': True, 'prompt_rows': rows, 'append_patch': patch_record, 'generation_calls': 0, 'network_calls': 0, 'Godot_calls': 0, 'root_task_table_edits': 0, 'model': None, 'provider': None, 'cost': None}
    receipt = new(OUT / (args.output_stem + '.json'), (json.dumps(report, ensure_ascii=False, indent=2) + '\n').encode())
    print(json.dumps({'passed': True, 'count': len(rows), 'report': receipt, 'patch': patch_record, 'prompts': [{k: row[k] for k in ('id','prompt_path','prompt_sha256')} for row in rows]}, ensure_ascii=False))

if __name__ == '__main__':
    main()
