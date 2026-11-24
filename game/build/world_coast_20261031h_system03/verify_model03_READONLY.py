"""Pure byte/source graph model checks. NOT approval or a C runtime collector."""
from __future__ import annotations
import importlib.util,json
from pathlib import Path

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('coast_successor_candidate',HERE/'prepare_source_successors03.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

targets=m.old_targets();before={p:m.read(p) for p in targets};old={p:m.sha(b) for p,b in before.items()}
expected=json.loads((HERE/'template03/SourceExpected_TEMPLATE.json').read_bytes())
assert expected['old_sources']==old
denied=False
try:m.seal(HERE/'template03/SourceExpected_TEMPLATE.json',m.sha((HERE/'template03/SourceExpected_TEMPLATE.json').read_bytes()))
except AssertionError:denied=True
assert denied and not (HERE/'sealed_candidate03').exists()
integration=json.loads(m.read(m.SYSTEM02+'prepared03/receipt_REVIEW_ONLY.json'))
known={m.resource(r['path']):r['candidate_sha256'] for r in integration['targets']}
c=m.c_candidate({p:'ROOT_APPROVAL_REQUIRED' for p in list(m.ARTIFACTS.values())+[m.CANONICAL]})
assert b'world_map_jianghu_v16->ch4_s0_luoyang_gate' in c
assert b'_fresh_world_v16_portal_matches(source,target,normalized,route)' in c
assert m.edit(before[m.C],[(h['old'],h['new']) for h in m.hunks(before[m.C],c)])==c
maps_checked=0
for p in targets:
    if not p.endswith('.json'):continue
    original=json.loads(before[p])
    for name in ['sources','runtime_modules','source_sha256','legacy_source_sha256']:
        if name not in original:continue
        data=m.map_update(before[p],name,known,old)
        parsed=json.loads(data)
        assert set(parsed[name])==set(original[name])
        assert {k:v for k,v in parsed.items() if k!=name}=={k:v for k,v in original.items() if k!=name}
        for k,v in original[name].items():
            assert parsed[name][k]==(known[k] if k in known and v==old.get(k) else v)
        maps_checked+=1
# The last19 metadata/index targets must have an acyclic old-header dependency
# order once the explicitly authored leaves/native/Region/EX are composed.
ready=set(known)|{m.C,m.CANONICAL,m.NATIVE,m.REGION,m.EX,m.EI}
pending=[p for p in targets if p not in ready];order=[]
while pending:
    progress=False
    for p in list(pending):
        deps={q for q,h in old.items() if q!=p and h.encode() in before[p]}
        if deps.intersection(pending):continue
        order.append(p);ready.add(p);pending.remove(p);progress=True
    assert progress,('SOURCE_PIN_CYCLE',pending)
native=json.loads(before[m.NATIVE]);region=json.loads(before[m.REGION])
assert len(native['sources'])==226 and len(region['runtime_modules'])==567
dispatch=m.read(m.ARTIFACTS['dispatcher']).decode('utf-8')
contract=m.read(m.ARTIFACTS['contract']).decode('utf-8')
assert 'if V16.declared_identity(scene):return 16' in dispatch
assert 'if scene==null or _modern_declaration_present(scene):return -1' in dispatch
assert 'if _modern_declaration_present(scene):return null' in dispatch
assert 'static func declared_identity(scene: SceneScript) -> bool:' in contract
router02=m.read(m.SYSTEM02+'prepared03/copies/game/scripts/autoload/scene_router.gd').decode('utf-8')
assert 'not is_world_map_scene(scene_id) or world_version_for_scene(scene_id) not in [12,13,14,15,16]' in router02
assert 'if not is_world_map_scene(target_id) or world_version_for_scene(target_id) not in [12,13,14,15,16]:return false' in router02
ex=json.loads(before[m.EX]);snapshots=[]
for p in [m.ROUTER,m.FIELD]:
    row=ex['owned'][p]
    assert row['current_sha256']==old[p]
    assert m.read(row['edges'][-1]['new_snapshot'])==before[p]
    assert m.SNAPSHOTS[p] not in ex['source_sha256'] and not m.disk(m.SNAPSHOTS[p]).exists()
    candidate=m.read(m.SYSTEM02+'prepared03/copies/game/'+p[6:])
    inverse=candidate.decode('utf-8')
    for replacement in m.hunks(before[p],candidate):
        assert inverse.count(replacement['new'])==1
        inverse=inverse.replace(replacement['new'],replacement['old'],1)
    assert inverse.encode('utf-8')==before[p]
    snapshots.append({'source':p,'old_edge_count':len(row['edges']),'planned_extra_edges':1})
print(json.dumps({'status':'READONLY_BYTE_MODEL_NOT_SOURCE_AUTHORITY_OR_ENGINE_QA','old_targets':len(targets),'source_maps_checked':maps_checked,'metadata_topological_order_count':len(order),'deny_template_rejected':denied,'C_whole_inverse_exact':True,'native_expected_model':'226 + two explicitly Root-approved code keys','region_expected_model':'567 + same two explicitly Root-approved code keys','EX_original_source_keys':len(ex['source_sha256']),'EX_rows':snapshots,'old_source_writes':0,'engine_runs':0,'real_save_API_calls':0},ensure_ascii=False,indent=2))

