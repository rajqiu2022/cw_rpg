"""NEW final v3 recipe with Root exact29 and exact2 formatting gates."""
from prepare_handoff10 import HERE, sha

raw = (HERE / "prepare_unified_finish_input01.py").read_bytes()
assert sha(raw) == "de9a1c8433f594d7adef54739e97a7818cb3aa70cd3ff4e32863f2732cd02bb4"
text = raw.decode("utf-8")
for old, new in [
    ("unified_finish_dependencies01/", "unified_finish_dependencies02/"),
    ("unified_runtime_visual_finish_candidates_v2_READY.json", "unified_runtime_visual_finish_candidates_v3_READY.json"),
    ("84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee", "065a7ec03cceb6ee9cef5a32f9d3d3d2bdd3ed7cd9d06e21cb25b69e400e1341"),
    ("6760847d3c58fad92fed3024f30c16360df894b24602cccfefda05c4ad487b58", "1536df7a75f29e47998af7b56486e370fb1747cc127a7d2012165d8ddc01ae3e"),
    ("execution_unified_visual_resident_successor_authorization_READY.json", "execution_unified_visual_resident_successor02_authorization_READY.json"),
    ("318ce82bd6d59dfa3203d365a1d67a45ea5b19d5750535c36fa2224e300c8c15", "bdc90616977099ba87cbf763cf306873a6ed64bc7556acd2aa79216a640f13f7"),
    ("stage_unified_finish01_READY.py", "stage_unified_finish02_READY.py"),
    ("530314b0e22db531072e477d24171c5882dd37567ee660bdb26117172bda8125", "cbeca49b004d6d55f8edc9e5af1673b1de4319421c58596b82b2f96de6253ef5"),
    ("unified_finish_input01_PENDING.json", "unified_finish_input02_ROOT_LOCKED.json"),
    ("PENDING_ROOT_EXACT29_SCOPE_NOT_EXECUTABLE", "ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT"),
]:
    assert old in text
    text = text.replace(old, new)
needle = 'authority = pinned(dep["execution_proposal"]["path"], dep["execution_proposal"]["sha256"])'
addition = '''
for target, row in systemtargets.items():
    assert current[target]["old_sha256"] == row["parent_sha256"]
    current[target]["candidate"] = row["candidate"]
for row in dep["additional_canonical_targets"]:
    assert current[row["target"]]["old_sha256"] == row["old_sha256"]
    current[row["target"]]["candidate"] = row["candidate"]
current[dep["execution_parent"]["path"]]["candidate"] = dep["execution_proposal"]
'''
assert text.count(needle) == 1
text = text.replace(needle, needle + addition)
needle = 'pin("docks22_lineage",'
index = text.index(needle)
text = text[:index] + '''pin("root_exact29_scope", "res://build/luoyang_city_full_rollout_20261022ap_root01/integration10/scope_READY.json", "8db9f310c476bfea21b2f547c89a610fa17d8f65f34ebda85ab6f4452683f776")
pin("root_exact_two_eol_format", "res://build/luoyang_city_full_rollout_20261022ap_root01/exact_two_eol_format_authorization_READY.json", "edfe36252b48b846ef017a4738f231e96471cc9475aad80adcbbee54b2c6a8f9")
pin("temple_real_binding", dep["build_only_dependency"]["path"], dep["build_only_dependency"]["sha256"])
''' + text[index:]
needle = '# Exact source-only two-value contract with original raw candidate output.'
addition = '''# Explicit nonowned old/new baseline edges. These fixed four AO maps
# already contain Resident F173, so common additions alone cannot update it.
for node in plan["nodes"]:
    if node["kind"] != "map":
        continue
    basepin = pins[node["base_input"]]
    base = pinned(basepin["path"], basepin["sha256"])
    for path, oldvalue in base["source_sha256"].items():
        if path not in changed_refs or path in authority["owned"]:
            continue
        pointer = ["source_sha256", path]
        matches = [op for op in node["operations"] if op["pointer"] == pointer]
        assert len(matches) <= 1
        if matches:
            assert matches[0]["old"] == oldvalue
            matches[0]["new"] = changed_refs[path]
        else:
            node["operations"].append({"op": "set", "pointer": pointer, "existed": True, "old": oldvalue, "new": changed_refs[path]})
'''
assert text.count(needle) == 1
text = text.replace(needle, addition + needle)
needle = 'plan["status"] = "ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT"'
assert text.count(needle) == 1
text = text.replace(needle, 'plan["required_gates"].append({"id": "root_target_preauthorization", "input": "root_exact29_scope", "pointer": ["approved_by_root"], "equals": True})\n' + needle)
old = 'plan["blockers"] = ["Await Root exact29 scope/backups pin; then add fifth gate and external input lock. No engine or stager executed."]'
assert text.count(old) == 1
text = text.replace(old, 'plan["blockers"] = []')
exec(compile(text, str(HERE / "prepare_unified_finish_input01.py") + "#final-v3-02", "exec"))
