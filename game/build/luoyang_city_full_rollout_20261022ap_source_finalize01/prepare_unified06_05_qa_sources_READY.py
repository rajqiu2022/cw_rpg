"""NEW fixed05 owner recipe; run only with Root's actual05 receipt pin."""
from prepare_handoff10 import HERE, sha
raw = (HERE / "prepare_unified06_04_qa_sources_READY.py").read_bytes()
assert sha(raw) == "2573fb97ed7f34cd61ec921a7bdbf8769332a862f7648c2b5cc6949ab7acd3cc"
text = raw.decode("utf-8")
for old, new in [
    ("outputs/root_unified06_numeric_stage02/receipt.json", "outputs/root_unified06_numeric_stage03/receipt.json"),
    ("f2b48a5870837fd9d39a24d56bf8e4ea71f365adc8153722d1b47754e1185cf8", "5fe4b02960a4f23692f5d94c5fcaab7a193fc6be6bdda2bf5efb2ce0c7cb40e5"),
    ("unified06_input04_ROOT_LOCKED.json", "unified06_input05_ROOT_LOCKED.json"),
    ("unified06_04_independent_qa_owner_source_maps_READY.json", "unified06_05_independent_qa_owner_source_maps_READY.json"),
    ("unified06_04_independent_source_review_READY.json", "unified06_05_independent_source_review_READY.json"),
]:
    assert old in text, old
    text = text.replace(old, new)
exec(compile(text, str(HERE / "prepare_unified06_04_qa_sources_READY.py") + "#fixed05", "exec"))
