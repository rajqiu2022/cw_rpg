"""One-pin NOTREADY successor: protect portal shader without adding city keys."""
import argparse
import importlib.util
import json
from pathlib import Path

p = Path(__file__).with_name('prepare_source_input_NOTSTAGE.py')
s = importlib.util.spec_from_file_location('hall_recipe_parent', p)
P = importlib.util.module_from_spec(s)
s.loader.exec_module(P)


def prepare():
    previous = P.prepare()
    raw = previous[P.O+'source_input_NOTREADY.json']
    assert P.sha(raw) == 'c6f86de2b9cfcef686b15230a86b7db8921b693dd5f9e7a51f1b76afa0932a40'
    value = json.loads(raw)
    assert not any(r['id'] == 'hall_portal_shader' for r in value['pinned_inputs'])
    value['pinned_inputs'].append({'id': 'hall_portal_shader', 'path': P.PORTAL_SHADER, 'sha256': P.PORTAL_SHADER_SHA})
    inverse = json.loads(P.encode(value))
    inverse['pinned_inputs'].pop()
    assert P.strict(inverse, json.loads(raw)) and P.encode(inverse) == raw
    return {P.O+'source_input_shaderpin_NOTREADY.json': P.encode(value)}


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--file-index', type=int)
    ap.add_argument('--start', type=int, default=0)
    ap.add_argument('--length', type=int, default=12000)
    args = ap.parse_args()
    outputs = prepare()
    if args.file_index is None:
        print(json.dumps([{'path': k, 'sha256': P.sha(v), 'bytes': len(v)} for k, v in outputs.items()]))
    else:
        key = list(outputs)[args.file_index]
        print(json.dumps({'path': key, 'text': outputs[key].decode('utf8')[args.start:args.start+args.length]}, ensure_ascii=True))
