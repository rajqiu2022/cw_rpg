"""NEW exact-schema authorization checks; every other03 byte preserved."""
import difflib
from prepare_handoff10 import HERE, sha

raw = (HERE / "stage_unified06_03_READY.py").read_bytes()
assert sha(raw) == "68902a20a896bb3ae0e56c509e3e275f9b47bb7f6a9696d7a871ac372803a5de"
old = raw.decode("utf-8")
text = old
before = 'self.read_json_input("root_router06_numeric_and_eol").get("approved_by_root") is True'
after = '''self.read_json_input("root_router06_numeric_and_eol").get("status") == "ROOT_FINITE_APPROVAL_ROUTER06_FOUR_AUTHOR_FOOT_NUMERIC_COMPARISONS_AND_SINGLE_EOL_FORMAT_NOT_DEPLOYMENT" and self.read_json_input("root_router06_numeric_and_eol").get("candidate_sha256") == "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb" and self.read_json_input("root_router06_numeric_and_eol").get("single_router_eol_format", {}).get("final_entire_sha256_required") == "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb"'''
assert text.count(before) == 1
text = text.replace(before, after)
before = 'self.read_json_input("root_unified_execution_approval").get("approved_by_root") is True'
after = '''self.read_json_input("root_unified_execution_approval").get("status") == "ROOT_EXACT_0D06_TO_A388_EXECUTION_SOURCE_SUCCESSOR_APPROVAL_NOT_CANONICAL_DEPLOYMENT" and self.read_json_input("root_unified_execution_approval").get("approved_execution_sha256") == "a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75" and self.read_json_input("root_unified_execution_approval").get("parent_execution_sha256") == "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"'''
assert text.count(before) == 1
text = text.replace(before, after)
compile(text, "stage_unified06_04_READY.py", "exec")
out = text.encode("utf-8")
with (HERE / "stage_unified06_04_READY.py").open("xb") as stream:
    stream.write(out)
diff = "".join(difflib.unified_diff(old.splitlines(keepends=True), text.splitlines(keepends=True), fromfile="stage_unified06_03_READY.py", tofile="stage_unified06_04_READY.py"))
with (HERE / "unified06_tool04_vs03.diff").open("xb") as stream:
    stream.write(diff.encode("utf-8"))
print({"tool_sha256": sha(out), "diff_sha256": sha(diff.encode("utf-8")), "stager_executed": False})
