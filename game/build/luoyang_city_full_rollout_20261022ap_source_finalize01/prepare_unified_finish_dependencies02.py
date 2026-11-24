"""NEW pre-stage semantic successor: final Router paired-memory line only.

Rebuilds dependency candidates from unchanged canonical80A, not prior proposal.
Preserves all previous proposal/candidates and runs no stager or engine.
"""
import ast
from pathlib import Path
import hashlib

here = Path(__file__).resolve().parent
source = (here / "prepare_unified_finish_dependencies01.py").read_bytes()
assert hashlib.sha256(source).hexdigest() == "2a0715a9d4f17b4ea636f17d629b18ec14b01aa51568504dfeb6f94e53fe8ae5"
retry = ast.parse((here / "prepare_unified_finish_dependencies_retry1.py").read_bytes())
replacements = {}
for node in retry.body:
    if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name) and node.targets[0].id in ["old", "new"]:
        replacements[node.targets[0].id] = ast.literal_eval(node.value)
text = source.decode("utf-8")
assert text.count(replacements["old"]) == 1
text = text.replace(replacements["old"], replacements["new"])
for old, new in [
    ("unified_finish_dependencies01/", "unified_finish_dependencies02/"),
    ("unified_runtime_visual_finish_candidates_v2_READY.json", "unified_runtime_visual_finish_candidates_v3_READY.json"),
    ("84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee", "065a7ec03cceb6ee9cef5a32f9d3d3d2bdd3ed7cd9d06e21cb25b69e400e1341"),
    ("7c65d2d1e7eee99b9f0d2f9418428382545ed49c9fc13f883ae0beb376acab2d", "c670bb2a7bb7d1abd8d1aba26987454fda4ef7eed4de8da5728e41077911086d"),
]:
    assert text.count(old) == 1
    text = text.replace(old, new)
exec(compile(text, str(here / "prepare_unified_finish_dependencies01.py") + "#v3-memory-successor02", "exec"))
