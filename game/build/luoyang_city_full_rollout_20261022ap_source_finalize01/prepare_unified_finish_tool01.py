"""Emit NEW narrowly amended Root-only staging tool, never execute it."""
import difflib
from prepare_handoff10 import HERE, sha, resource

raw = (HERE / "stage_sources_repair_retry5.py").read_bytes()
assert sha(raw) == "23f21249602117ae9a3e638c94d5b1a17725d3bc1e9464912115a7ba3da776b4"
old = raw.decode("utf-8")
text = old

def replace_once(a, b):
    global text
    assert text.count(a) == 1, a[:100]
    text = text.replace(a, b)

replace_once("import argparse", "import argparse\nimport base64")
start = text.index('            elif row.get("target") == "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"')
end = text.index('            elif row["old_sha256"] != "ABSENT":', start)
prior_branch = text[start:end]
next_branch = '''            elif row.get("target") == "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json" and row.get("old_sha256") == "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11" and row.get("candidate_sha256") == "fef4cba7be47faf14b72598b7a2f3f8867f792e3fb6c9c006fb9bda8dd2b589c":
                root_pin = self.inputs.get("root_unified_execution_approval", {})
                need(root_pin.get("sha256") == "318ce82bd6d59dfa3203d365a1d67a45ea5b19d5750535c36fa2224e300c8c15" and self.read_json_input("root_unified_execution_approval").get("approved_by_root") is True, "EXACT318C_ROOT_80A_FEF4_APPROVAL_REQUIRED")
                need(self.inputs[self.spec["authority_input"]]["sha256"] == row["candidate_sha256"] and self.inputs[self.spec["authority_input"]]["path"] == row["candidate_path"], "EXACT_FEF4_VALIDATED_AUTHORITY_INPUT")
                prior = json.loads(self.read(row["target"], row["old_sha256"]))
                changed = {"res://scripts/autoload/scene_router.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd", "res://scripts/city/luoyang_temple_assembly_20261016.gd"}
                need(set(prior["owned"]) == set(self.authority["owned"]) and len(prior["owned"]) == 10, "UNCHANGED_OWNED10_DOMAIN")
                restored = copy.deepcopy(self.authority)
                for p, previous in prior["owned"].items():
                    current = self.authority["owned"][p]
                    if p not in changed:
                        need(same(previous, current), "UNCHANGED_OTHER6_OWNED_ROWS")
                    else:
                        need(len(current["edges"]) == len(previous["edges"]) + 1 and same(current["edges"][:-1], previous["edges"]), "EXACT_ONE_APPENDED_EDGE_OLD_GRAPH_PRESERVED")
                        edge = current["edges"][-1]
                        need(edge["old_sha256"] == previous["current_sha256"] and edge["new_sha256"] == current["current_sha256"], "PREDECESSOR_CURRENT_TO_NEW_CURRENT_EDGE")
                        restored["owned"][p] = copy.deepcopy(previous)
                need(len(prior["source_sha256"]) == 37 and len(self.authority["source_sha256"]) == 44 and all(self.authority["source_sha256"].get(p) == v for p, v in prior["source_sha256"].items()), "OLD37_PINS_PRESERVED_EXACT7_ADDED")
                restored["source_sha256"] = copy.deepcopy(prior["source_sha256"])
                need(same(restored, prior), "WHOLE_TYPED_INVERSE_EXACT80A")
            elif row.get("system_offset_candidate") is True:
                need(self.inputs["unified_system_candidates"]["sha256"] == "84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee", "EXACT84CEE_SYSTEM_SET")
                system = self.read_json_input("unified_system_candidates")
                matches = [r for r in system["targets"] if r["canonical"] == row["target"]]
                need(len(matches) == 1 and row["target"] not in OWNED, "FIXED_NONOWNED_SYSTEM_TARGET")
                proof = matches[0]
                need(proof["parent_sha256"] == row["old_sha256"] and proof["candidate"]["path"] == row["candidate_path"] and proof["candidate"]["sha256"] == row["candidate_sha256"], "FIXED_SYSTEM_TARGET_PARENT_CANDIDATE")
                before = self.read(row["target"], row["old_sha256"])
                after = self.read(row["candidate_path"], row["candidate_sha256"])
                oc = nc = 0
                for h in proof["offset_byte_hunks"]:
                    o, n = h["old_offset"], h["new_offset"]
                    a, b = base64.b64decode(h["old_b64"]), base64.b64decode(h["new_b64"])
                    need(before[oc:o] == after[nc:n] and before[o:o+len(a)] == a and after[n:n+len(b)] == b, "SYSTEM_EXACT_OFFSET_BYTE_HUNK")
                    oc, nc = o+len(a), n+len(b)
                need(before[oc:] == after[nc:], "SYSTEM_EXACT_OFFSET_BYTE_TAIL")
                inverse = after
                for h in reversed(proof["offset_byte_hunks"]):
                    n = h["new_offset"]
                    a, b = base64.b64decode(h["old_b64"]), base64.b64decode(h["new_b64"])
                    need(inverse[n:n+len(b)] == b, "SYSTEM_INVERSE_EXACT_COORDINATE")
                    inverse = inverse[:n] + a + inverse[n+len(b):]
                need(inverse == before, "SYSTEM_NONOWNED_WHOLE_BYTE_INVERSE")
'''
replace_once(prior_branch, next_branch)
replace_once('row.get("old_sha256") == "b56409417fec3cb9fb0a31600f09d72edd333de11cba0144c3407baec8b3fd8d"', 'row.get("old_sha256") == "4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a"')
replace_once('self.inputs[literal]["sha256"] == "4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a"', 'self.inputs[literal]["sha256"] == "a4ac5f34715033bb59986cb152eb45413f4ccdaee591710f4e7db3136e16155d"')
replace_once('copy_parent_sha = "9c3f9b5a35360ca2b488424ea0a3922759bf3b70d21452c7298dff51e7aac817"', 'copy_parent_sha = "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11"')
parent = resource("res://data/maps/luoyang_full_city_20261022ap/execution_successor.json").read_bytes()
assert sha(parent) == "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11"
guard = 'need(len(before) == 156164 and before.count(b"\\r\\n") == before.count(b"\\r") == before.count(b"\\n") == 591 and not before.endswith(b"\\n") and not before.startswith(b"\\xef\\xbb\\xbf"), "FROZEN_9C3F_PARENT_ORIGINAL_BYTES_EOL_DOMAIN")'
replacement = f'need(len(before) == {len(parent)} and before.count(b"\\r\\n") == {parent.count(bytes([13,10]))} and before.count(b"\\r") == {parent.count(bytes([13]))} and before.count(b"\\n") == {parent.count(bytes([10]))} and before.endswith(b"\\n") is {parent.endswith(bytes([10]))!r}, "FROZEN80A_PARENT_ORIGINAL_BYTES_EOL_DOMAIN")'
replace_once(guard, replacement)
assert 'SOURCE_KEY' not in next_branch  # no source-domain or merge guard relaxation
compile(text, "stage_unified_finish01_READY.py", "exec")
out = text.encode("utf-8")
with (HERE / "stage_unified_finish01_READY.py").open("xb") as stream:
    stream.write(out)
diff = "".join(difflib.unified_diff(old.splitlines(keepends=True), text.splitlines(keepends=True), fromfile="stage_sources_repair_retry5.py", tofile="stage_unified_finish01_READY.py"))
with (HERE / "unified_finish_tool01_vs_retry5.diff").open("xb") as stream:
    stream.write(diff.encode("utf-8"))
print({"tool_sha256": sha(out), "diff_sha256": sha(diff.encode("utf-8")), "stager_executed": False})
