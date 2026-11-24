"""Root-only mechanical freezer, NOT RUN and deployment-schema blocked.

Stage schema is pinned to Source E303/2120. Deployment schema must be supplied
by Root from its real receipt before a NEW successor may enable this tool.
No Stage constructor/import, engine, collector, PNG/packet read, current-source
scan, or current-value fallback is used. Only explicitly pinned JSON/text.
"""
from pathlib import Path
import argparse, copy, hashlib, json, re, difflib

Q = Path(__file__).resolve().parent
GAME = Q.parent.parent
OLD = Q / 'market_apothecary_vendor_journey_ui_successor01_NOTREADY'
PATHS = Q / 'market_apothecary_vendor_route_contract_source06_NOTREADY'
DEPLOYMENT_SCHEMA_READY = False
CITY = 'ch4_s3_luoyang_market'
ROOM = 'luoyang_market_market_northeast_rear_frontage_interior_20261015'
MAP_NODE = 'expected_ch4_s3_luoyang_market_true'
BINDING = GAME / 'build/luoyang_city_space_20261024b_source01/runtime_READY02/market_space_binding_READY.json'
BINDING_SHA = '003ec7f690ed9494f315132a4f3f6e16263ad3ca38ccb34392913ae07c5f4cdb'

def need(value, why):
    if not value: raise ValueError(why)
def sha(raw): return hashlib.sha256(raw).hexdigest()
def resolve(path):
    p = GAME / path[6:] if path.startswith('res://') else Path(path)
    p = p.resolve()
    need(p.is_relative_to(GAME.resolve()), 'PINNED_INPUT_INSIDE_GAME_ONLY')
    return p
def res(p): return 'res://' + p.resolve().relative_to(GAME.resolve()).as_posix()
def read_fixed(path, expected):
    need(type(expected) is str and re.fullmatch('[0-9a-fA-F]{64}', expected), 'FULL_EXTERNAL_SHA_REQUIRED')
    p = resolve(path);raw = p.read_bytes()
    need(sha(raw) == expected.lower(), 'EXACT_PINNED_BYTES:' + str(p))
    return p, raw, json.loads(raw)
def encoded(value): return (json.dumps(value, ensure_ascii=True, indent=2) + '\n').encode('ascii')

def stage_map(stage):
    need(stage.get('status') == 'MARKET_DIALOGUE_EXACT36_STAGED_NOT_DEPLOYED', 'EXACT_SOURCE36_STAGE_STATUS')
    need(stage.get('target_partition') == {'patch_count':21,'copy_count':15,'total':36}, 'EXACT36_21GD15JSON_PARTITION')
    need(type(stage.get('targets')) is list and len(stage['targets']) == 36, 'EXACT36_TARGET_RECEIPT')
    need(stage.get('source_first') and stage.get('source_first') == stage.get('source_final'), 'DECLARED_STAGE_FIRST_FINAL_IDENTICAL_NO_RESCAN')
    node = stage['nodes'][MAP_NODE]
    path, raw, value = read_fixed(node['path'], node['sha256'])
    need(value == node['value'] and value.get('scene_id') == CITY, 'ACTUAL_MAP_JSON_EXACT_STAGE_NODE_VALUE')
    sources = value.get('source_sha256')
    need(type(sources) is dict and len(sources) > 0, 'FIXED_INDEPENDENT_MARKET_SOURCE_DICTIONARY')
    need(all(type(p) is str and p.startswith('res://') and '..' not in p and type(h) is str and re.fullmatch('[0-9a-f]{64}',h) for p,h in sources.items()), 'SOURCE_MAP_STRING_PATH_SHA_DOMAIN')
    return path, sha(raw), sources

def validate_deployment(deployment, stage, stage_sha):
    # Root has not yet delivered its real deployment receipt schema. Do not
    # guess passed/targets/records or treat nonempty JSON as deployment success.
    need(DEPLOYMENT_SCHEMA_READY, 'ROOT_REAL_DEPLOYMENT_SCHEMA_NOT_LOCKED_NO_OUTPUTS')
    raise ValueError('NEW_SCHEMA_SUCCESSOR_REQUIRED_NOT_IMPLEMENTED')

def freeze(args):
    stage_path, stage_raw, stage = read_fixed(args.stage_receipt_path,args.stage_receipt_sha256)
    deploy_path, deploy_raw, deployment = read_fixed(args.deployment_receipt_path,args.deployment_receipt_sha256)
    need(type(stage) is dict and type(deployment) is dict, 'TWO_FIXED_JSON_DOCUMENTS')
    map_path, map_sha, sources = stage_map(stage)
    validate_deployment(deployment,stage,sha(stage_raw))  # Refuses before any output while schema is pending.
    _, _, contract = read_fixed(res(PATHS/'route_contract_SOURCE_APPROVAL_PENDING.json'),'6dea7d7651846bf14a19eadeb955d25b8ad5b27b274d19ec83e8acf722518ada')
    _, _, approval = read_fixed(res(PATHS/'Source_approval_READONLY.json'),'32fc47b8794eab454fe09a92e6869b8b943f32ed142a26bc6eb6f4e53aac5ab7')
    need(approval['approved_contract_sha256'] == '6dea7d7651846bf14a19eadeb955d25b8ad5b27b274d19ec83e8acf722518ada', 'SOURCE_APPROVED_EXACT_ROUTE_CONTRACT')
    _, _, fixture = read_fixed(res(PATHS/'fixture_NOTREADY.json'),'a8d470e8fe4b8d8675f97779588a8000ef2ed73f1e26f727220751dad8404d06')
    _, _, binding = read_fixed(res(BINDING),BINDING_SHA)
    returns = binding['room_returns'][ROOM]
    need(returns['new_return_px'] == fixture['author_return_world'] == fixture['near_return_world']
         and returns['new_threshold_px'] == fixture['city_threshold_world'], 'EXACT_FIXED_RUNTIME_RETURN_OVERLAY_NOT_RAW_AUTHOR_REWRITE')
    need(fixture['paths'] == contract['paths'] and fixture['whole_ms'] == 60000
         and fixture['entry_ms'] == 20000 and fixture['max_pictures'] == 3, 'ROUTES_UI_AND_BUDGETS_FROZEN')
    original = copy.deepcopy(fixture)
    fixture.update(ready=True,formal_deployed=True,status='ROOT_FROZEN_ONE_FINITE_MARKET_APOTHECARY_VENDOR_TASK_DECLINE',blockers=[],
        expected_city_sources=copy.deepcopy(sources),expected_city_count=len(sources),
        independent_owner={'path':res(map_path),'sha256':map_sha,'kind':'ACTUAL_SOURCE_STAGE_INDEPENDENT_MAP_NOT_COLLECTOR'},
        stage_receipt={'path':res(stage_path),'sha256':sha(stage_raw)},
        deployment_actual={'path':res(deploy_path),'sha256':sha(deploy_raw)})
    # Only values supplied by the fixed independent Stage map, never current files.
    guard_delta = {}
    for p, old in list(fixture['source_sha256'].items()):
        if p in sources and sources[p] != old:
            guard_delta[p] = {'old':old,'new':sources[p]};fixture['source_sha256'][p] = sources[p]
    required = ['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd',
                'res://scripts/city/luoyang_assembled_interiors_20261016g.gd',
                'res://scripts/field/field_walkable_controller.gd', 'res://scripts/ui/dialog_box.gd']
    for p in required:
        need(p in sources, 'REQUIRED_RUNTIME_PATH_IN_FIXED_STAGE_MAP:' + p)
        if p not in fixture['source_sha256']: guard_delta[p] = {'old':None,'new':sources[p]}
        fixture['source_sha256'][p] = sources[p]
    extra = {res(stage_path):sha(stage_raw),res(deploy_path):sha(deploy_raw),res(map_path):map_sha,
             res(PATHS/'Source_approval_READONLY.json'):'32fc47b8794eab454fe09a92e6869b8b943f32ed142a26bc6eb6f4e53aac5ab7',
             res(BINDING):BINDING_SHA}
    for p,h in extra.items():
        need(p not in fixture['source_sha256'] or fixture['source_sha256'][p] == h, 'NO_EXTRA_GUARD_COLLISION')
        fixture['source_sha256'][p] = h
    out = resolve(args.output_directory)
    need(out.is_relative_to(Q.resolve()) and out != Q.resolve() and not out.exists(), 'NEW_QA_OUTPUT_DIRECTORY_ONLY')
    fx = encoded(fixture);fpath = out/'fixture_READY.json';keypath = out/'test_READY.gd'
    old_key = (OLD/'test_NOTREADY.gd').read_bytes()
    need(sha(old_key) == 'db6b77e65a9973bde2636e7718ea9558e9932fc9cf5f26fa6b6bbd3e5862de5c', 'EXACT_DB6B_FUNCTION_SOURCE')
    ops = [(b'const JOURNEY_READY=false',b'const JOURNEY_READY=true'),
        (res(OLD/'fixture_NOTREADY.json').encode(),res(fpath).encode()),
        (b'7486a667fca87f34b0e9299fc2847f6bcb5e9ad4a6118891e677cf3738736d60',sha(fx).encode()),
        (res(OLD/'output_NOTREADY').encode(),res(out/'output_READY').encode())]
    key = old_key
    for before,after in ops:
        need(key.count(before) == 1,'EXACT_FOUR_LITERAL_FREEZE');key = key.replace(before,after,1)
    inverse = key
    for before,after in reversed(ops):
        need(inverse.count(after) == 1,'EXACT_FOUR_LITERAL_INVERSE');inverse = inverse.replace(after,before,1)
    need(inverse == old_key,'FULL_DB6B_BYTE_INVERSE_INCLUDING_EOF')
    # Preserve all untouched nested fields, including raw/UI labels, finite paths.
    restored = copy.deepcopy(fixture)
    for p in extra: restored['source_sha256'].pop(p,None)
    for p,delta in guard_delta.items():
        if delta['old'] is None: restored['source_sha256'].pop(p,None)
        else: restored['source_sha256'][p] = delta['old']
    for p,h in original['source_sha256'].items(): restored['source_sha256'][p] = h
    for k in list(restored):
        if k not in original: del restored[k]
    for k in ['ready','formal_deployed','status','blockers','expected_city_sources','expected_city_count','independent_owner','deployment_actual']:
        restored[k] = original[k]
    need(restored == original,'ONLY_DECLARED_FIXTURE_READINESS_AND_FIXED_STAGE_PROOF_DELTA')
    proof = dict(status='FOUR_LITERAL_DB6B_FREEZE_NOT_ENGINE_RUN',key_sha256=sha(key),fixture_sha256=sha(fx),
        stage_receipt_sha256=sha(stage_raw),deployment_receipt_sha256=sha(deploy_raw),map_sha256=map_sha,
        expected_city_count=len(sources),key_wholebyte_inverse_including_EOF=True,fixture_wholetyped_inverse=True,
        source_guard_delta=guard_delta,source_guards_from_fixed_stage_only=True,collector_or_current_fill=False,
        raw_room_author_and_native_paths_unchanged=True,engine_or_Stage_or_media_decode_calls=0)
    diff = ''.join(difflib.unified_diff(old_key.decode().splitlines(True),key.decode().splitlines(True),fromfile=res(OLD/'test_NOTREADY.gd'),tofile=res(keypath))).encode()
    outputs = {fpath:fx,keypath:key,out/'freeze_inverse_READY_NOTRUN.json':encoded(proof),out/'complete_vs_DB6B.diff':diff}
    need(all(not p.exists() for p in outputs),'ALL_NEW_OUTPUTS_ONLY')
    out.mkdir(parents=True,exist_ok=False)
    for p,raw in outputs.items():
        with p.open('xb') as stream: stream.write(raw)
    print(json.dumps({'key_sha256':sha(key),'fixture_sha256':sha(fx),'expected_city_count':len(sources),'output':res(out)}))

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--stage-receipt-path',required=True);parser.add_argument('--stage-receipt-sha256',required=True)
    parser.add_argument('--deployment-receipt-path',required=True);parser.add_argument('--deployment-receipt-sha256',required=True)
    parser.add_argument('--output-directory',required=True)
    freeze(parser.parse_args())
