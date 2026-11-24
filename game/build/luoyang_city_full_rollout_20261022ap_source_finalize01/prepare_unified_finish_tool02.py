"""NEW v3 Root tool with exactly two approved EOL-format domains, not run."""
import difflib
from prepare_handoff10 import HERE, sha

raw = (HERE / "stage_unified_finish01_READY.py").read_bytes()
assert sha(raw) == "530314b0e22db531072e477d24171c5882dd37567ee660bdb26117172bda8125"
original = raw.decode("utf-8")
text = original
for old, new in [
    ("fef4cba7be47faf14b72598b7a2f3f8867f792e3fb6c9c006fb9bda8dd2b589c", "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"),
    ("318ce82bd6d59dfa3203d365a1d67a45ea5b19d5750535c36fa2224e300c8c15", "bdc90616977099ba87cbf763cf306873a6ed64bc7556acd2aa79216a640f13f7"),
    ("84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee", "065a7ec03cceb6ee9cef5a32f9d3d3d2bdd3ed7cd9d06e21cb25b69e400e1341"),
    ("a4ac5f34715033bb59986cb152eb45413f4ccdaee591710f4e7db3136e16155d", "acf3fd349454f6f25f98c0ed9de895f8a8b51c7b7a0e7732adf689b21b947b1c"),
]:
    assert text.count(old) == 1
    text = text.replace(old, new)

extra = '''
# Sole finite formatting domains, already independently Root-authorized. The
# original strict LF generator remains unchanged for every other file.
_strict_lf_build_file_patch = build_file_patch
EXACT_EOL_CANDIDATES = {
    "res://scripts/autoload/scene_router.gd": ("c670bb2a7bb7d1abd8d1aba26987454fda4ef7eed4de8da5728e41077911086d", 13),
    "res://scripts/ui/field_primary_hud.gd": ("b673121841860c0d7ca501eed9a9c792fe2364f8714f04955b8036f8cdf5487c", 163),
}
def build_file_patch(target, before, after):
    matches = [(p, pin) for p, pin in EXACT_EOL_CANDIDATES.items() if res(p).as_posix() == target]
    if not matches:
        return _strict_lf_build_file_patch(target, before, after)
    path, (expected, cr_count) = matches[0]
    need(digest(after) == expected and after.count(b"\\r") == after.count(b"\\r\\n") == cr_count, "EXACT_TWO_FIXED_EOL_CANDIDATE_ONLY")
    normalized = after.replace(b"\\r\\n", b"\\n")
    need(b"\\r" not in normalized and normalized.endswith(b"\\n"), "NO_OTHER_CR_CONTENT_DOMAIN")
    piece, proof = _strict_lf_build_file_patch(target, before, normalized)
    bitmap = [i for i, line in enumerate(after.splitlines(keepends=True)) if line.endswith(b"\\r\\n")]
    rebuilt = b"".join(line[:-1] + b"\\r\\n" if i in bitmap else line for i, line in enumerate(normalized.splitlines(keepends=True)))
    need(rebuilt == after and len(bitmap) == cr_count, "FORMAT_ONLY_LINE_END_BITMAP_EXACT_CANDIDATE_RECONSTRUCTION")
    proof.update(candidate_sha256=expected, forward_exact_bytes=False, forward_exact_intermediate_bytes=True,
                 patch_intermediate_sha256=digest(normalized), final_requires_exact_root_authorized_eol_formatting=True,
                 eol_format={"path": path, "final_candidate_sha256": expected, "normalized_complete_sha256": digest(normalized),
                             "crlf_line_indices_zero_based": bitmap, "crlf_count": cr_count,
                             "must_first_apply_patch_then_compare_all_normalized_bytes": True,
                             "only_restore_cr_using_deployed_characters_never_copy_gd_candidate": True})
    return piece, proof

'''
assert text.count("class Stage:") == 1
text = text.replace("class Stage:", extra + "class Stage:")
needle = '        for row in self.spec.get("pass_through_targets", []):'
assert text.count(needle) == 1
text = text.replace(needle, '''        need(self.inputs["root_exact_two_eol_format"]["sha256"] == "edfe36252b48b846ef017a4738f231e96471cc9475aad80adcbb ee54b2c6a8f9".replace(" ", "") and self.read_json_input("root_exact_two_eol_format").get("approved_by_root") is True, "EXACT_TWO_ROOT_EOL_FORMAT_AUTHORIZATION_REQUIRED")
''' + needle)
needle = '        pp, ps = self.output("canonical_deployment.apply_patch", "".join(patch).encode("utf-8"))'
assert text.count(needle) == 1
text = text.replace(needle, '''        eol_rows = [r["eol_format"] for r in patch_reconstruction.values() if "eol_format" in r]
        need({r["path"] for r in eol_rows} == set(EXACT_EOL_CANDIDATES) and len(eol_rows) == 2, "EXACT_TWO_EOL_FORMAT_PLAN_NO_OTHER_FILES")
        eol_path, eol_sha = self.output("canonical_exact_two_eol_format_plan.json", encode({"status": "ROOT_ONLY_AFTER_APPLY_PATCH_FORMAT_ONLY_NOT_EXECUTED", "root_authorization_sha256": "edfe36252b48b846ef017a4738f231e96471cc9475aad80adcbb ee54b2c6a8f9".replace(" ", ""), "rows": eol_rows, "no_candidate_gd_copy": True, "requires_normalized_complete_byte_equality_before_any_formatting": True}))
''' + needle)
needle = '        receipt["byte_copy_plan"] ='
assert text.count(needle) == 1
text = text.replace(needle, '        receipt["eol_format_plan"] = {"path": eol_path, "sha256": eol_sha, "target_count": 2, "requires_apply_patch_first": True, "not_candidate_code_copy": True}\n' + needle)
text = text.replace("sole fixed existing execution_successor9C3F JSON", "sole fixed existing execution_successor80A JSON")
text = text.replace("ROOT_ONLY_EXISTING_9C3F_APPROVAL_SUCCESSOR_BYTE_COPY_NOT_EXECUTED", "ROOT_ONLY_EXISTING_80A_APPROVAL_SUCCESSOR_BYTE_COPY_NOT_EXECUTED")
compile(text, "stage_unified_finish02_READY.py", "exec")
out = text.encode("utf-8")
with (HERE / "stage_unified_finish02_READY.py").open("xb") as stream:
    stream.write(out)
diff = "".join(difflib.unified_diff(original.splitlines(keepends=True), text.splitlines(keepends=True), fromfile="stage_unified_finish01_READY.py", tofile="stage_unified_finish02_READY.py"))
with (HERE / "unified_finish_tool02_vs01.diff").open("xb") as stream:
    stream.write(diff.encode("utf-8"))
print({"tool_sha256": sha(out), "diff_sha256": sha(diff.encode("utf-8")), "stager_executed": False})
