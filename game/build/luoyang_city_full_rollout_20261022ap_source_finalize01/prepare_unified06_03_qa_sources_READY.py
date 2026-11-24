"""NEW independent source recipe for actual06 stage only, not run yet."""
from prepare_handoff10 import HERE, sha

raw = (HERE / "prepare_unified_finish02_qa_sources_READY.py").read_bytes()
assert sha(raw) == "f5e86e38afd3d74f7557923c3cb78c8b344987b7f6c0b680e1069af9a2e24a12"
text = raw.decode("utf-8")
for old, new in [
    ("outputs/root_unified_visual_resident_stage01/receipt.json", "outputs/root_unified06_numeric_stage01/receipt.json"),
    ("37210069e96cb9f867cb902d00073a96ea5865bb44398ec798c7200e23a5a9ba", "0b4f5447f870133b23f18376c06bb0778893adc1f16dd6475a9431031ed8bfd1"),
    ("unified_finish_input02_ROOT_LOCKED.json", "unified06_input03_ROOT_LOCKED.json"),
    ('{"patch_count": 28, "copy_count": 1, "total": 29,', '{"patch_count": 22, "copy_count": 1, "total": 23,'),
    ("len(targets) == 29", "len(targets) == 23"),
    ('"candidate_hashes_verified": 29', '"candidate_hashes_verified": 23'),
    ('"target_count": 29', '"target_count": 23'),
    ("0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb", "a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75"),
    ("030922f31f42ee0bb281e2f5267923501300cf87f4ad9be0826b9d650c19c211", "1724624c6f85b9c8daa3593d259089ed1b9b8f1e60106f0dff67582d6686d840"),
    ("unified_finish02_independent_qa_owner_source_maps_READY.json", "unified06_03_independent_qa_owner_source_maps_READY.json"),
    ("unified_finish02_independent_source_review_READY.json", "unified06_03_independent_source_review_READY.json"),
    ("edfe36252b48b846ef017a4738f231e96471cc9475aad80adcbbee54b2c6a8f9", "ff10fdd974793a6875c111f91183031f5587b370b5bdc4c23a4036f52bc93479"),
    ("c670bb2a7bb7d1abd8d1aba26987454fda4ef7eed4de8da5728e41077911086d", "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb"),
]:
    assert old in text, old
    text = text.replace(old, new)
old = ', "res://scripts/ui/field_primary_hud.gd": "b673121841860c0d7ca501eed9a9c792fe2364f8714f04955b8036f8cdf5487c"'
assert text.count(old) == 1
text = text.replace(old, '')
exec(compile(text, str(HERE / "prepare_unified_finish02_qa_sources_READY.py") + "#unified06-03", "exec"))
