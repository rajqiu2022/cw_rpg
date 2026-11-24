"""NEW direct recipe: retain fixed BDF3 core ancestry absent from narrow23.

Independent source assembly only; only E Market/Artisan remains runtime scope.
Old05 read-only KeyError is preserved and no engine/collector is invoked.
"""
from prepare_handoff10 import HERE, sha

raw = (HERE / "prepare_repair_stage03_qa_sources_READY.py").read_bytes()
assert sha(raw) == "d17f4738e2937f64812be4be74f6f3148e2400a92f9de10ed171dea1490d9109"
text = raw.decode("utf-8")
for old, new in [
    ("outputs/root_integration3_repair_stage03/receipt.json", "outputs/root_unified06_numeric_stage03/receipt.json"),
    ("6c8c26972186df5dac249f3fac467fc5fbe01751017ff44b30031931a55d4723", "5fe4b02960a4f23692f5d94c5fcaab7a193fc6be6bdda2bf5efb2ce0c7cb40e5"),
    ("source_finalization_input_handoff17_repair_ROOT_LOCKED.json", "unified06_input05_ROOT_LOCKED.json"),
    ('{"patch_count": 19, "copy_count": 1, "total": 20,', '{"patch_count": 22, "copy_count": 1, "total": 23,'),
    ("len(targets) == 20", "len(targets) == 23"),
    ('"candidate_hashes_verified": 20', '"candidate_hashes_verified": 23'),
    ('"target_count": 20', '"target_count": 23'),
    ("80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11", "a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75"),
    ("cc9dec2b08cb58e6a192a41e3e1bdc508f42f4a81317e0eb074ca6b13752414c", "1724624c6f85b9c8daa3593d259089ed1b9b8f1e60106f0dff67582d6686d840"),
    ("repair_stage03_independent_qa_owner_source_maps_READY.json", "unified06_06_independent_qa_owner_source_maps_READY.json"),
    ("repair_stage03_independent_source_review.json", "unified06_06_independent_source_review_READY.json"),
]:
    assert old in text, old
    text = text.replace(old, new)
old = 'full_target_hashes = {r["target"]: r["candidate_sha256"] for r in parent_stage["targets"]}'
new = '''previous_owner = read_pin("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified_finish02_independent_qa_owner_source_maps_READY.json", "bdf3d09e33ce56df4bdadad27c1096c794f2ee5831db9f7cc9eb0ddd9560c08c")
    assert previous_owner["actual_stage_receipt"]["sha256"] == "ef969c47a3433fd160d2e70f48de30b0d14d0eb88b8ce916c3ba38c2e405f429"
    full_target_hashes = copy.deepcopy(previous_owner["core_source_sha256"])'''
assert text.count(old) == 1
text = text.replace(old, new)
old = 'environment = merge(group("environment_sources"), group("environment_header"), {"res://scripts/city/luoyang_environment_index_20261022ap.gd": nodes["ap_environment_index"]["sha256"]})'
assert text.count(old) == 1
text = text.replace(old, 'environment = merge(group("environment_sources"), group("environment_header"), group("unified_rect_shader"), {"res://scripts/city/luoyang_environment_index_20261022ap.gd": nodes["ap_environment_index"]["sha256"]})')
needle = '    # Independent source-table recipe evaluator;'
addition = '''    eol = read_pin(stage["eol_format_plan"]["path"], stage["eol_format_plan"]["sha256"])
    assert eol["root_authorization_sha256"] == "ff10fdd974793a6875c111f91183031f5587b370b5bdc4c23a4036f52bc93479"
    assert len(eol["rows"]) == 1 and eol["rows"][0]["path"] == "res://scripts/autoload/scene_router.gd"
    row = eol["rows"][0]
    target = targets[row["path"]]
    candidate = resource(target["candidate_path"]).read_bytes()
    assert sha(candidate) == target["candidate_sha256"] == row["final_candidate_sha256"] == "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb"
    normalized = candidate.replace(b"\\r\\n", b"\\n")
    assert b"\\r" not in normalized and sha(normalized) == row["normalized_complete_sha256"]
    rebuilt = b"".join(line[:-1]+b"\\r\\n" if i in row["crlf_line_indices_zero_based"] else line for i,line in enumerate(normalized.splitlines(keepends=True)))
    assert rebuilt == candidate

'''
assert text.count(needle) == 1
text = text.replace(needle, addition + needle)
needle = '    source_sha = write_new('
addition = '''    old_execution = read_pin("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified_finish_dependencies02/execution_successor_PROPOSAL.json", "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb")
    expected_six = set(approval["source_sha256"]) - set(old_execution["source_sha256"])
    assert len(expected_six) == 6
    for ident in ["ch4_s3_luoyang_market", "luoyang_artisan_residential_20261022ap"]:
        old_row = next(r for r in previous_owner["scenes"] if r["id"] == ident)
        for field in ["source_sha256", "receipt_source_sha256"]:
            before, after = old_row[field], scene_sources[ident][field]
            assert set(after)-set(before) == expected_six and not set(before)-set(after)
            assert {p for p in before if before[p] != after[p]} <= set(targets), ("UNDECLARED_E_SOURCE_VALUE_CHANGE", ident, field)
    out["remaining_runtime_validation_domains_only"] = ["ch4_s3_luoyang_market", "luoyang_artisan_residential_20261022ap"]
    out["prior_passed_A_B_C_D_and_two_visual_components_not_replayed"] = True
    out["fixed_previous_owner_sha256"] = "bdf3d09e33ce56df4bdadad27c1096c794f2ee5831db9f7cc9eb0ddd9560c08c"
'''
assert text.count(needle) == 1
text = text.replace(needle, addition + needle)
exec(compile(text, str(HERE / "prepare_repair_stage03_qa_sources_READY.py") + "#new-direct06-fixedBDF3", "exec"))
