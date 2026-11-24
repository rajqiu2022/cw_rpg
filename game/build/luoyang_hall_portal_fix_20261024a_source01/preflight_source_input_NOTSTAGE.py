"""Read-only symbolic recipe order/old-pointer proof, no Stage/media reads."""
import copy
import importlib.util
import json
from pathlib import Path

fp = Path(__file__).with_name('prepare_source_input_shaderpin_NOTSTAGE.py')
sp = importlib.util.spec_from_file_location('hall_recipe', fp)
P = importlib.util.module_from_spec(sp)
sp.loader.exec_module(P)
D = P.P.D


def preflight():
    raw = next(iter(P.prepare().values()))
    spec = json.loads(raw)
    pins = {r['id']: r for r in spec['pinned_inputs']}
    groups = {r['id']: r for r in spec['source_groups']}
    authority = D.json.loads(D.read(pins[spec['authority_input']]['path'], pins[spec['authority_input']]['sha256']))
    source_docs, nodes, stack = {}, {}, set()
    counts = {'exact_old_pointers': 0, 'index_old_literals': 0, 'source_groups_expanded': 0, 'metadata_nodes': 0, 'map_nodes': 0}
    def document(ident):
        if ident not in source_docs:
            # These are fixed JSON declarations, never media or native bytes.
            p = pins[ident]
            source_docs[ident] = json.loads(D.path(p['path']).read_bytes())
        return source_docs[ident]
    def ptr(v, ks):
        for k in ks:
            v = v[k]
        return v
    def approved(p, old):
        seen, todo = set(), [authority['owned'][p]['current_sha256']]
        while todo:
            h = todo.pop()
            if h == old:
                return True
            if h in seen:
                continue
            seen.add(h)
            todo += [e['old_sha256'] for e in authority['owned'][p]['edges'] if e['new_sha256'] == h]
        return False
    def promote(values):
        out = copy.deepcopy(values)
        for p, old in out.items():
            if p in authority['owned']:
                assert approved(p, old), ('NO_HISTORICAL_EDGE', p)
                out[p] = authority['owned'][p]['current_sha256']
        return out
    def value(v):
        if isinstance(v, dict):
            if '$sha' in v:
                assert v['$sha'] in nodes, ('FUTURE_NODE_REF', v)
                return nodes[v['$sha']]['sha256']
            if '$pin' in v:
                return pins[v['$pin']]['sha256']
            if '$owned' in v:
                return authority['owned'][v['$owned']]['current_sha256']
            return {k: value(w) for k, w in v.items()}
        if isinstance(v, list):
            return [value(w) for w in v]
        return v
    def merge(a, b):
        for p, h in b.items():
            if p in a and a[p] != h:
                assert p in authority['owned'] and approved(p, a[p]) and h == authority['owned'][p]['current_sha256'], ('UNDECLARED_GROUP_REPLACEMENT', p, a[p], h)
            a[p] = h
    def group(ident):
        assert ident in groups and ident not in stack, ('UNKNOWN_OR_CYCLIC_GROUP', ident)
        stack.add(ident)
        g = groups[ident]
        if g['kind'] == 'explicit':
            out = value(g['leaves'])
        elif g['kind'] == 'input_dictionary':
            out = copy.deepcopy(ptr(document(g['input']), g['pointer']))
        elif g['kind'] == 'node_dictionary':
            assert g['node'] in nodes, ('FUTURE_GROUP_NODE', ident)
            out = copy.deepcopy(ptr(nodes[g['node']]['value'], g['pointer']))
        elif g['kind'] == 'union':
            out = {}
            for child in g['groups']:
                merge(out, group(child))
        else:
            raise AssertionError(g['kind'])
        if g.get('promote_owned'):
            out = promote(out)
        stack.remove(ident)
        counts['source_groups_expanded'] += 1
        return out
    def operations(v, ops):
        for op in ops:
            holder, k = ptr(v, op['pointer'][:-1]), op['pointer'][-1]
            assert (k in holder) == op['existed'] and (not op['existed'] or D.strict(holder[k], op['old'])), ('EXACT_OLD_POINTER', op['pointer'])
            if op['op'] == 'remove':
                del holder[k]
            else:
                holder[k] = value(op['new'])
            counts['exact_old_pointers'] += 1
    for n in spec['nodes']:
        ident, kind = n['id'], n['kind']
        symbol = 'NODE:'+ident
        if kind == 'hall_execution':
            nodes[ident] = {'sha256': pins[n['base_input']]['sha256'], 'value': authority}
            continue
        if kind == 'hall_frozen':
            nodes[ident] = {'sha256': pins[n['base_input']]['sha256'], 'value': document(n['base_input']) if n.get('is_json') else None}
            continue
        if kind == 'index':
            text = D.path(pins[n['base_input']]['path']).read_bytes().decode('utf8')
            for r in n['replacements']:
                assert text.count(r['old']) == 1, ('EXACT_INDEX_LITERAL', ident, r['old'])
                text = text.replace(r['old'], value(r['new']), 1)
                counts['index_old_literals'] += 1
            nodes[ident] = {'sha256': symbol, 'value': None}
            continue
        base = document(n['base_input'])
        v = {'source_sha256': promote(base['source_sha256'])} if kind == 'map' else copy.deepcopy(base)
        operations(v, n.get('operations', []))
        if kind == 'hall_contract':
            assert D.strict(v, document(n['literal_candidate_input']))
            nodes[ident] = {'sha256': pins[n['literal_candidate_input']]['sha256'], 'value': v}
            continue
        for f in n.get('source_fields', []):
            into = ptr(v, f['pointer'])
            if f.get('promote_owned'):
                updated = promote(into)
                into.clear()
                into.update(updated)
            for g in f.get('groups', []):
                additions = group(g)
                # The original core removes external headers/self from these
                # fields; no parser or source guard is executed/replaced here.
                for p in n.get('forbidden_source_paths', []):
                    additions.pop(p, None)
                merge(into, additions)
        bundle = n.get('source_bundle')
        if bundle:
            dictionaries = [ptr(v, ks) for ks in bundle['fields']]
            for d in dictionaries:
                updated = promote(d)
                d.clear()
                d.update(updated)
            for gid in bundle['groups']:
                for p, h in group(gid).items():
                    # Same source union semantics; class whitelist/native
                    # restrictions remain the unchanged core's responsibility.
                    hits = [d for d in dictionaries if p in d]
                    assert len(hits) <= 1, ('EXISTING_CROSS_CLASS_DUPLICATE', ident, p)
                    if hits:
                        merge(hits[0], {p: h})
                    else:
                        dictionaries[0][p] = h
        if kind == 'map':
            for gid in n['groups']:
                merge(v['source_sha256'], group(gid))
            counts['map_nodes'] += 1
        else:
            counts['metadata_nodes'] += 1
        nodes[ident] = {'sha256': symbol, 'value': v}
    return {'status': 'HALL_SOURCE_INPUT_SYMBOLIC_ORDER_OLD_POINTER_PREFLIGHT_NOT_STAGE', 'input_sha256': D.sha(raw),
            'counts': counts, 'nodes': len(nodes), 'four_independent_baseline_maps_present': counts['map_nodes'] == 4,
            'classification_native_media_and_current_SHA_gates_not_executed_or_bypassed': True,
            'no_Stage_constructor_or_runtime_collector_or_media_native_read': True}


if __name__ == '__main__':
    print(json.dumps(preflight(), ensure_ascii=False))
