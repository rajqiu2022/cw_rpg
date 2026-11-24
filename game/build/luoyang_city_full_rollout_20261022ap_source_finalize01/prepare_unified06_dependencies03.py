"""NEW source-only dependency proposal for Router06 four-foot comparison.

Starts at deployed EF969/0D06. Never stages, edits canonical or runs Godot.
"""
from prepare_handoff10 import HERE, sha

raw = (HERE / "prepare_unified_finish_dependencies01.py").read_bytes()
assert sha(raw) == "2a0715a9d4f17b4ea636f17d629b18ec14b01aa51568504dfeb6f94e53fe8ae5"
text = raw.decode("utf-8")
for old, new in [
    ("unified_finish_dependencies01/", "unified06_dependencies03/"),
    ("unified_runtime_visual_finish_candidates_v2_READY.json", "exact_market_artisan_resident_candidate06/handoff_READY.json"),
    ("84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee", "4dce66ac6474565712e617bd893d41b09e161ec0f82d0efc509cd1e070626c38"),
    ("80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11", "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"),
    ("4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a", "acf3fd349454f6f25f98c0ed9de895f8a8b51c7b7a0e7732adf689b21b947b1c"),
    ("9e9b67b0c22000be9d9637b3c3cd1184c730c2ae8bc287196ccfe963e350ebad", "babfaeca014fa0b4d06299379ea137f4200588a94c1f4115ac27a6792c827d53"),
    ("d9cd4138c1cfb8d8346c723110bdb1b1b5df99b9ac4a2fe555699aa43a8312c0", "61ccb0a092c8a7f58016411ed84b235a4ba1bac61fcec2b73821c99f9e565cf5"),
    ("res://build/luoyang_city_full_rollout_20261022ap_system01/temple_binding_pin_successor_retry1/binding_READY.json", "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified_finish_dependencies02/temple_binding_READY.json"),
    ("cc9dec2b08cb58e6a192a41e3e1bdc508f42f4a81317e0eb074ca6b13752414c", "030922f31f42ee0bb281e2f5267923501300cf87f4ad9be0826b9d650c19c211"),
]:
    assert text.count(old) == 1, old
    text = text.replace(old, new)
start = text.index('system = json.loads(read(SYSTEM, SYSTEM_SHA))')
end = text.index('contract_old = read(CONTRACT, CONTRACT_SHA)', start)
text = text[:start] + '''system = json.loads(read(SYSTEM, SYSTEM_SHA))
assert system["finite_keys"] == ["forward.source_foot", "forward.target_foot", "backward.source_foot", "backward.target_foot"]
router_sha = system["candidate"]["sha256"]
assert router_sha == "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb"
before_router = read(ROUTER, system["parent"]["sha256"])
assert before_router == read(system["parent"]["path"], system["parent"]["sha256"])
router_hunks = [{"old": system["old"], "new": system["new"]}]
assert exact_replacements(before_router, router_hunks) == read(system["candidate"]["path"], router_sha)
system_targets = {ROUTER: {"candidate": system["candidate"]}}
system_replacements = {ROUTER: router_hunks}
''' + text[end:]
old = 'for p, value in [(FIELD, field_sha), (ROUTER, router_sha)]]'
assert text.count(old) == 1
text = text.replace(old, 'for p, value in [(ROUTER, router_sha)]]')
old = 'for p in [FIELD, ROUTER]:'
assert text.count(old) == 1
text = text.replace(old, 'for p in [ROUTER]:')
old = 'binding_updates = {FIELD: field_sha, ROUTER: router_sha,'
assert text.count(old) == 1
text = text.replace(old, 'binding_updates = {ROUTER: router_sha,')
old = '    FIELD: {"candidate": system_targets[FIELD]["candidate"], "replacements": system_replacements[FIELD]},\n'
assert text.count(old) == 1
text = text.replace(old, '')
text = text.replace('len(approval0["source_sha256"]) == 37', 'len(approval0["source_sha256"]) == 44')
text = text.replace('"changed_source_paths": [FIELD, ROUTER]', '"changed_source_paths": [ROUTER]')
text = text.replace('"owned_changed_exactly4"', '"owned_changed_exactly3"')
text = text.replace('"other6_owned_rows_whole_typed_identical"', '"other7_owned_rows_whole_typed_identical"')
text = text.replace('"original37_proof_pins_unchanged"', '"original44_proof_pins_unchanged"')
text = text.replace('"whole_typed_inverse_to_original80A"', '"whole_typed_inverse_to_deployed0D06"')
text = text.replace('PENDING_ROOT_EXACT80A_SUCCESSOR_APPROVAL_AND_UNIFIED_TARGET_SCOPE_NOT_STAGED', 'PENDING_ROOT_EXACT0D06_SUCCESSOR_APPROVAL_AND_NEW24_SCOPE_NOT_STAGED')
text = text.replace('"system6_candidates_and2shaders_unchanged"', '"previous_system6_except_router_and2shaders_unchanged"')
exec(compile(text, str(HERE / "prepare_unified_finish_dependencies01.py") + "#deployed0D06-Router06", "exec"))
