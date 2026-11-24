"""Emit only NEW Root stager: deployed0D06→A388, 3owned, Router EOL only."""
import difflib
from prepare_handoff10 import HERE, resource, sha

raw = (HERE / "stage_unified_finish02_READY.py").read_bytes()
assert sha(raw) == "cbeca49b004d6d55f8edc9e5af1673b1de4319421c58596b82b2f96de6253ef5"
old = raw.decode("utf-8")
text = old
for before, after in [
    ("0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb", "a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75"),
    ("80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11", "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"),
    ("bdc90616977099ba87cbf763cf306873a6ed64bc7556acd2aa79216a640f13f7", "aca3ddda152c714887a54a9ccdfde5bcb0ceb11ea1670aabe28573ca3ffd9828"),
    ("acf3fd349454f6f25f98c0ed9de895f8a8b51c7b7a0e7732adf689b21b947b1c", "16b381c113ebfd0cb89f382eb99366bb703cda6baa40142cc1fbf97343ed74d8"),
    ("4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a", "acf3fd349454f6f25f98c0ed9de895f8a8b51c7b7a0e7732adf689b21b947b1c"),
    ("c670bb2a7bb7d1abd8d1aba26987454fda4ef7eed4de8da5728e41077911086d", "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb"),
]:
    assert before in text, before
    text = text.replace(before, after)
before = 'changed = {"res://scripts/autoload/scene_router.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd", "res://scripts/city/luoyang_temple_assembly_20261016.gd"}'
after = 'changed = {"res://scripts/autoload/scene_router.gd", "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd", "res://scripts/city/luoyang_temple_assembly_20261016.gd"}'
assert text.count(before) == 1
text = text.replace(before, after)
text = text.replace('len(prior["source_sha256"]) == 37', 'len(prior["source_sha256"]) == 44')
text = text.replace('len(self.authority["source_sha256"]) == 44', 'len(self.authority["source_sha256"]) == 50')
text = text.replace('UNCHANGED_OTHER6_OWNED_ROWS', 'UNCHANGED_OTHER7_OWNED_ROWS')
text = text.replace('OLD37_PINS_PRESERVED_EXACT7_ADDED', 'OLD44_PINS_PRESERVED_EXACT6_ADDED')
text = text.replace('WHOLE_TYPED_INVERSE_EXACT80A', 'WHOLE_TYPED_INVERSE_DEPLOYED0D06')
start = text.index('            elif row.get("system_offset_candidate") is True:')
end = text.index('            elif row["old_sha256"] != "ABSENT":', start)
text = text[:start] + text[end:]
before = '    "res://scripts/ui/field_primary_hud.gd": ("b673121841860c0d7ca501eed9a9c792fe2364f8714f04955b8036f8cdf5487c", 163),\n'
assert text.count(before) == 1
text = text.replace(before, '')
text = text.replace('len(eol_rows) == 2', 'len(eol_rows) == 1')
text = text.replace('"target_count": 2, "requires_apply_patch_first"', '"target_count": 1, "requires_apply_patch_first"')
text = text.replace('root_exact_two_eol_format', 'root_router06_numeric_and_eol')
before = '"edfe36252b48b846ef017a4738f231e96471cc9475aad80adcbb ee54b2c6a8f9".replace(" ", "")'
assert text.count(before) == 2
text = text.replace(before, '"ff10fdd974793a6875c111f91183031f5587b370b5bdc4c23a4036f52bc93479"')
text = text.replace('canonical_exact_two_eol_format_plan.json', 'canonical_exact_router06_eol_format_plan.json')
parent = resource("res://data/maps/luoyang_full_city_20261022ap/execution_successor.json").read_bytes()
assert sha(parent) == "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"
oldguard = next(line for line in text.splitlines() if 'FROZEN80A_PARENT_ORIGINAL_BYTES_EOL_DOMAIN' in line)
newguard = '                ' + f'need(len(before) == {len(parent)} and before.count(b"\\r\\n") == {parent.count(bytes([13,10]))} and before.count(b"\\r") == {parent.count(bytes([13]))} and before.count(b"\\n") == {parent.count(bytes([10]))} and before.endswith(b"\\n") is {parent.endswith(bytes([10]))!r}, "FROZEN0D06_PARENT_ORIGINAL_BYTES_EOL_DOMAIN")'
assert text.count(oldguard) == 1
text = text.replace(oldguard, newguard)
text = text.replace('EXACT_TWO', 'EXACT_ROUTER06').replace('exactly two', 'exactly one Router06')
compile(text, "stage_unified06_03_READY.py", "exec")
out = text.encode("utf-8")
with (HERE / "stage_unified06_03_READY.py").open("xb") as stream:
    stream.write(out)
diff = "".join(difflib.unified_diff(old.splitlines(keepends=True), text.splitlines(keepends=True), fromfile="stage_unified_finish02_READY.py", tofile="stage_unified06_03_READY.py"))
with (HERE / "unified06_tool03_vs_finish02.diff").open("xb") as stream:
    stream.write(diff.encode("utf-8"))
print({"tool_sha256": sha(out), "diff_sha256": sha(diff.encode("utf-8")), "stager_executed": False})
