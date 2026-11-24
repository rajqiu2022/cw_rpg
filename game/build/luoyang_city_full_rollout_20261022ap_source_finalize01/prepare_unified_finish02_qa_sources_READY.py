"""NEW independent source-domain recipe; run only after Root actual receipt."""
from prepare_handoff10 import HERE, sha

raw = (HERE / "prepare_repair_stage03_qa_sources_READY.py").read_bytes()
assert sha(raw) == "d17f4738e2937f64812be4be74f6f3148e2400a92f9de10ed171dea1490d9109"
text = raw.decode("utf-8")
for old, new in [
    ("outputs/root_integration3_repair_stage03/receipt.json", "outputs/root_unified_visual_resident_stage01/receipt.json"),
    ("6c8c26972186df5dac249f3fac467fc5fbe01751017ff44b30031931a55d4723", "37210069e96cb9f867cb902d00073a96ea5865bb44398ec798c7200e23a5a9ba"),
    ("source_finalization_input_handoff17_repair_ROOT_LOCKED.json", "unified_finish_input02_ROOT_LOCKED.json"),
    ('{"patch_count": 19, "copy_count": 1, "total": 20,', '{"patch_count": 28, "copy_count": 1, "total": 29,'),
    ("len(targets) == 20", "len(targets) == 29"),
    ('"candidate_hashes_verified": 20', '"candidate_hashes_verified": 29'),
    ('"target_count": 20', '"target_count": 29'),
    ("80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11", "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"),
    ("cc9dec2b08cb58e6a192a41e3e1bdc508f42f4a81317e0eb074ca6b13752414c", "030922f31f42ee0bb281e2f5267923501300cf87f4ad9be0826b9d650c19c211"),
    ("repair_stage03_independent_qa_owner_source_maps_READY.json", "unified_finish02_independent_qa_owner_source_maps_READY.json"),
    ("repair_stage03_independent_source_review.json", "unified_finish02_independent_source_review_READY.json"),
]:
    assert old in text, old
    text = text.replace(old, new)
old = 'environment = merge(group("environment_sources"), group("environment_header"), {"res://scripts/city/luoyang_environment_index_20261022ap.gd": nodes["ap_environment_index"]["sha256"]})'
new = 'environment = merge(group("environment_sources"), group("environment_header"), group("unified_rect_shader"), {"res://scripts/city/luoyang_environment_index_20261022ap.gd": nodes["ap_environment_index"]["sha256"]})'
assert text.count(old) == 1
text = text.replace(old, new)
needle = '    # Independent source-table recipe evaluator;'
assert text.count(needle) == 1
addition = '''    eol = read_pin(stage["eol_format_plan"]["path"], stage["eol_format_plan"]["sha256"])
    assert eol["root_authorization_sha256"] == "edfe36252b48b846ef017a4738f231e96471cc9475aad80adcbbee54b2c6a8f9"
    wanted_eol = {"res://scripts/autoload/scene_router.gd": "c670bb2a7bb7d1abd8d1aba26987454fda4ef7eed4de8da5728e41077911086d", "res://scripts/ui/field_primary_hud.gd": "b673121841860c0d7ca501eed9a9c792fe2364f8714f04955b8036f8cdf5487c"}
    assert {r["path"] for r in eol["rows"]} == set(wanted_eol)
    for row in eol["rows"]:
        target = targets[row["path"]]
        raw_candidate = resource(target["candidate_path"]).read_bytes()
        assert sha(raw_candidate) == target["candidate_sha256"] == wanted_eol[row["path"]] == row["final_candidate_sha256"]
        normalized = raw_candidate.replace(b"\\r\\n", b"\\n")
        assert b"\\r" not in normalized and sha(normalized) == row["normalized_complete_sha256"]
        rebuilt = b"".join(line[:-1]+b"\\r\\n" if i in row["crlf_line_indices_zero_based"] else line for i,line in enumerate(normalized.splitlines(keepends=True)))
        assert rebuilt == raw_candidate

'''
text = text.replace(needle, addition + needle)
exec(compile(text, str(HERE / "prepare_repair_stage03_qa_sources_READY.py") + "#unified-finish02", "exec"))
