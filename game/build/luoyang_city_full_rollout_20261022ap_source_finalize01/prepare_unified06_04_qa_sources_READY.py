"""NEW fixed04 owner recipe; wait for Root actual receipt before running."""
from prepare_handoff10 import HERE, sha
raw = (HERE / "prepare_unified06_03_qa_sources_READY.py").read_bytes()
assert sha(raw) == "bf479c01b637e1f4dbcb2536c925c4099893a988ebc9c5e9b868d5c1402d1acd"
text = raw.decode("utf-8")
for old, new in [
    ("outputs/root_unified06_numeric_stage01/receipt.json", "outputs/root_unified06_numeric_stage02/receipt.json"),
    ("0b4f5447f870133b23f18376c06bb0778893adc1f16dd6475a9431031ed8bfd1", "f2b48a5870837fd9d39a24d56bf8e4ea71f365adc8153722d1b47754e1185cf8"),
    ("unified06_input03_ROOT_LOCKED.json", "unified06_input04_ROOT_LOCKED.json"),
    ("unified06_03_independent_qa_owner_source_maps_READY.json", "unified06_04_independent_qa_owner_source_maps_READY.json"),
    ("unified06_03_independent_source_review_READY.json", "unified06_04_independent_source_review_READY.json"),
]:
    assert old in text, old
    text = text.replace(old, new)
exec(compile(text, str(HERE / "prepare_unified06_03_qa_sources_READY.py") + "#fixed04", "exec"))
