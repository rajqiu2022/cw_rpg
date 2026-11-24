"""NEW minimal scope successor: omit unchanged ENV index, preserve24 history."""
from prepare_handoff10 import HERE

raw = (HERE / "prepare_unified06_scope24.py").read_bytes()
text = raw.decode("utf-8")
old = 'drop = {"res://scripts/city/luoyang_resident_field_20261016.gd",'
new = 'drop = {"res://scripts/city/luoyang_environment_index_20261022ap.gd", "res://scripts/city/luoyang_resident_field_20261016.gd",'
assert text.count(old) == 1
text = text.replace(old, new)
text = text.replace('len(targets) == 24', 'len(targets) == 23')
text = text.replace('"target_count": 24', '"target_count": 23')
text = text.replace('EXACT24_SCOPE', 'EXACT23_SCOPE')
text = text.replace('"unchanged_five_targets_excluded"', '"unchanged_six_targets_excluded"')
text = text.replace('unified06_exact24_scope_request_READY.json', 'unified06_exact23_scope_request_READY.json')
text = text.replace('"targets": 24', '"targets": 23')
exec(compile(text, str(HERE / "prepare_unified06_scope24.py") + "#minimal23", "exec"))
