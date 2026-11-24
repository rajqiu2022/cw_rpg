"""Read only the failed07 report and narrow culture40 proposal; no runtime tools."""
from pathlib import Path
import copy
import hashlib
import json
import re

QA = Path(__file__).resolve().parent
GAME = QA.parents[1]
BUILD = GAME / "build"
SRC = BUILD / "luoyang_city_full_rollout_20261022ap_source_finalize01"
ROOT = BUILD / "luoyang_city_full_rollout_20261022ap_root01"
D = SRC / "performance40_culture_C_source_repair"
checks = []

def check(value, label):
    assert value, label
    checks.append(label)

def path(ref):
    return GAME / ref[6:] if str(ref).startswith("res://") else Path(ref)

def sha(p):
    return hashlib.sha256(path(p).read_bytes()).hexdigest()

def load(p):
    return json.loads(path(p).read_text(encoding="utf-8-sig"))

def typed(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return list(a) == list(b) and all(typed(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(typed(x, y) for x, y in zip(a, b))
    return a == b

def emit(name, data):
    p = QA / name
    check(not p.exists(), "NEW output absent: " + name)
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {"path": str(p), "sha256": sha(p)}

def evidence(p):
    return {"path": str(p), "sha256": sha(p)}

# Actual: report facts only, no replay of source or geometry collectors.
rp = QA / "yamen_performance07_ROOT30_READY/output/120460_2690/result.json"
r = load(rp)
check(sha(rp) == "09c768372a8afa6f0efcd86a8c75f7139b3f3b9b5a84c5946008b27d3547e87e", "actual07 exact report pin")
check((r["checks"], r["complete"], r["failures"], r["elapsed_ms"]) == (2501, False, 2, 67276), "failed07 whole preserved")
check(typed(r["source_before"], r["source_after"]) and len(r["source_before"]) == 1259, "1259 reported source identities first/final exact")
check(typed(r["players_before"], r["players_after"]) and len(r["players_before"]) == 15, "15 reported save identities first/final exact")
savebase = Path("C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传")
for key, row in r["players_after"].items():
    p = savebase / key.removeprefix("user://")
    check(p.exists() == row["exists"], "current save existence " + key)
    if row["exists"]:
        check(p.stat().st_size == row["bytes"] and sha(p) == row["sha256"], "current save SHA/bytes " + key)
clocks = [v for v in r["records"] if v["kind"] == "PERF07_PHASE_CLOCK"]
t = r["records"][-1]
check(len(clocks) == 8 and len(r["records"]) == 9 and t["kind"] == "PERF07_TIMEOUT", "eight phase samples then timeout only")
check(t["ready"] == {} and t["draw"] == {}, "no successful ready/draw")
c = t["last_matching_C"]["C"]
check(c["active"] and c["token"] == 1 and c["source_count"] == 1234 and not c["sources_finalized"], "partial FIRST1234 not finalized receipt")
check(c["live_phase_msec"] == {"precomputed_packet_and_materialize": 2027, "resolve_total": 4036, "source_start_worker": 1969}, "partial C timings exact; nested resolve not summed")
check(t["Field_profile"]["status"] == "COLLECTING" and not t["Field_profile"]["fresh_source_validation_credit"], "partial setup profile not warm/fresh completion")
check(t["Field_profile"]["phases"]["district_prepare_and_projection"]["wall_usec"] == 2008102, "partial district outer only")
check(not any("DT" in x["kind"] for x in r["records"]), "no postdraw DT getter record")
pr = ROOT / "integration30/yamen_performance07_once_process_receipt.json"
proc = load(pr)
check(proc["actual_natural_console_exit_code"] == -1073741819 and proc["exit_code_from_retained_process_WaitForExit"] and not proc["process_stopped_by_tool"], "true C0000005 retained; no tool termination")
check(proc["script_sha256"] == proc["script_after_sha256"] == "85e3d80b8c97d156a0db71764cb8010a85b0149b6949b0e8f6c3d9065caf3f7e", "actual key first/final unchanged")
errp = ROOT / "integration30/yamen_performance07_once_stderr.log"
outp = ROOT / "integration30/yamen_performance07_once_stdout.log"
check(sha(errp) == proc["stderr_sha256"] and sha(outp) == proc["stdout_sha256"], "process log hashes exact")
err = errp.read_text(encoding="utf-8-sig")
error_counts = {"ERROR": len(re.findall(r"^ERROR:", err, re.M)), "WARNING": len(re.findall(r"^WARNING:", err, re.M)), "SCRIPT_ERROR": len(re.findall(r"^SCRIPT ERROR:", err, re.M))}
check(error_counts == {"ERROR": 9, "WARNING": 1, "SCRIPT_ERROR": 0}, "stderr exact counts")
check("Cultural resident projection refused: CULTURE_X_SOURCE_CHANGED:res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd" in err, "exact cultural refusal")
gp = ROOT / "integration30/final_guard.json"
g = load(gp)
check(sha(gp) == "91de757d3dcd1ac860f72242fbbc555a4c0a5c3c44713cc5e8aaf3994bae87c1", "Root30 finalguard pin")
# Root's exact-tick guard is inherited, not rerun here.
print("guard scalar keys", {k:v for k,v in g.items() if isinstance(v,(str,int,bool)) and k != "status"})

C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
CO = "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
CON = "res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
TE = "res://scripts/city/luoyang_temple_assembly_20261016.gd"
contract = load(CON)
check(len(contract["source_sha256"]) == 26, "culture contract has26 leaves")
check(sha(CON) == "7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e", "formal contract unchanged7EE")
check(contract["source_sha256"][C] == "8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b", "contract retained obsolete C8C")
check(sha(C) == "b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be", "formal C is AP15 B14A")
code = {k:v for k,v in contract["source_sha256"].items() if k.endswith(".gd")}
badcode = [k for k,v in code.items() if sha(k) != v]
check(len(code) == 12 and badcode == [C], "only C mismatch among12 small code leaves;14 media/data not rehashed")
co = path(CO).read_text(encoding="utf-8")
check('FileAccess.get_sha256(path) != raw.source_sha256[path]' in co and 'CULTURE_X_SOURCE_CHANGED:' in co, "culture hard leaf check retained")
field = path("res://scripts/field/field_walkable_controller.gd").read_text(encoding="utf-8")
check('CULTURE_X.project_rows(scene.scene_id, runtime_npcs' in field and '_field_loading_failed = true' in field, "Field refusal before remaining setup")

actual = emit("actual07_120460_culture_C_edge_independent_readonly_review_READY.json", {
    "status": "FAILED07_INDEPENDENT_READONLY_AUDIT_NO_RERUN_AUTHORITY",
    "report": evidence(rp), "process": evidence(pr), "stderr": evidence(errp), "stdout": evidence(outp), "root_final_guard": evidence(gp),
    "whole": {"complete":False,"checks":2501,"failures":2,"elapsed_ms":67276,"process_wall_ms":proc["elapsed_wall_ms"],"true_console_exit":-1073741819,"nonclean":True},
    "protection": {"report_source_first_final_exact_count":1259,"report_save_first_final_exact_count":15,"current_save_SHA_bytes_existence_exact_count":15,"root_guard_exact_ticks_credit_not_replayed":True,"full_source_rehash":False},
    "scope": {"ready_draw":None,"natural_final_receipt":False,"DT_getter_records":0,"DT_six_child_runtime_credit":False,"INPUT_images_geometry_collectors":0},
    "partial_timings_only": {"C_live_phase_msec":c["live_phase_msec"],"Field_status":"COLLECTING","district_outer_usec":2008102,"LM":t["LM"]["metrics"],"max_observe_gap_usec":1905451,"nested_not_additive":True,"no_entry_performance_pass":True},
    "failure_chain": ["C FIRST1234 passed; sourceFINAL never reached", "Field culture project_rows -> readiness validates unchanged7EE contract26-leaf contents", "contract C8C mismatches formal AP15 C B14A; Field fails before remaining setup", "public already HANDED_OFF, existing harness early-exits only public FAILED, so existing60s deadline expires", "no ready/draw/naturalfinal/DTgetter; post-timeout SHA work is not loading latency"],
    "missing_dependency": {"contract":CON,"declared_C":contract["source_sha256"][C],"formal_C":sha(C),"code_leaves_checked":12,"code_mismatches":[C],"noncode14_not_rehashed":True,"contract_and_Coordinator_frozen_assumption_missed_semantic_content_edge":True,"complete_hash_set_does_not_prove_embedded_pins_current":True},
    "logs":error_counts,
    "limits":["C0000005 is real; no crash root cause inferred", "do not rerun07 or widen60s", "do not disableculture/sourcechecks or changeField/gameplay", "no six-child runtime measurements were reached"]
})
print("ACTUAL", actual)

# Candidate40: independently reconstruct exact bytes and ordered typed trees.
h = load(D / "handoff_EXECUTION_AND_SCOPE_PROPOSAL.json")
proof = load(D / "whole_culture_code_data_inverse_READY.json")
check(sha(D / "handoff_EXECUTION_AND_SCOPE_PROPOSAL.json") == "7b42c338f2f33e08b9d38b27cc4318ef4be0add9e72b2ae40e9d055c7154cda8", "candidate handoff pin")
check(sha(D / "whole_culture_code_data_inverse_READY.json") == "50e3bcd6af59b0dd02e14a382a6834ab3a2055d3489fe84225080fca78f72634", "candidate inverse proof pin")
for label, rec in proof["records"].items():
    old = path(rec["parent"]["path"]).read_bytes()
    new = path(rec["candidate"]["path"]).read_bytes()
    check(hashlib.sha256(old).hexdigest() == rec["parent"]["sha256"] and hashlib.sha256(new).hexdigest() == rec["candidate"]["sha256"], label + " parent/candidate exact SHA")
    forward = old
    for q in rec["hunks"]:
        a,b=q["old"].encode(),q["new"].encode()
        check(forward.count(a)==1,label+" unique forward hunk")
        forward=forward.replace(a,b,1)
    check(forward==new,label+" whole forward bytes exact")
    inverse=new
    for q in reversed(rec["hunks"]):
        a,b=q["old"].encode(),q["new"].encode()
        check(inverse.count(b)==1,label+" unique inverse hunk")
        inverse=inverse.replace(b,a,1)
    check(inverse==old,label+" whole inverse bytes exact")

newcon=load(proof["records"]["runtime_contract"]["candidate"]["path"])
inverse=copy.deepcopy(newcon)
inverse["source_sha256"][C]=contract["source_sha256"][C]
check(typed(inverse,contract),"contract only C value; remaining25/full gameplay typed same")
oldbind=load(proof["records"]["temple_binding"]["parent"]["path"])
newbind=load(proof["records"]["temple_binding"]["candidate"]["path"])
changes=[]
def diff(a,b,p=()):
    if type(a) is not type(b): return [p]
    if isinstance(a,dict):
        check(list(a)==list(b),"typed dictionary keys same at "+str(p))
        return sum((diff(a[k],b[k],p+(k,)) for k in a),[])
    if isinstance(a,list):
        check(len(a)==len(b),"typed list size same at "+str(p))
        return sum((diff(x,y,p+(i,)) for i,(x,y) in enumerate(zip(a,b))),[])
    return [] if a==b else [p]
binddiff=diff(oldbind,newbind)
check(set(binddiff)=={("source_delta",CO),("source_delta",CON)},"binding exact two source_delta leaves only")
check(len(oldbind["source_delta"])==len(newbind["source_delta"])==189,"binding189 total;187 untouched")
parent=load(h["execution_parent"]["path"])
new=load(h["execution_proposal"]["path"])
check(sha(h["execution_parent"]["path"])==h["execution_parent"]["sha256"] and sha(h["execution_proposal"]["path"])==h["execution_proposal"]["sha256"],"execution parent/new exact pins")
check(list(parent["owned"])==list(new["owned"]) and len(new["owned"])==10,"same10owned membership/order")
back=copy.deepcopy(new)
for row in h["owned_changed_exactly2"]:
    k=row["path"]
    check(new["owned"][k]["edges"][:-1]==parent["owned"][k]["edges"],"old owned edge prefix retained "+k)
    edge=new["owned"][k]["edges"][-1]
    check(edge=={x:y for x,y in row.items()},"new edge exact handoff row "+k)
    check(new["owned"][k]["current_sha256"]==row["new_sha256"],"new current owned SHA "+k)
    back["owned"][k]=copy.deepcopy(parent["owned"][k])
check(len(parent["source_sha256"])==80 and len(new["source_sha256"])==85,"80 historical plus5 proof pins")
for k,v in h["new_exact5_proof_pins"].items():
    check(k not in parent["source_sha256"] and new["source_sha256"][k]==v and sha(k)==v,"new proof exact "+k)
    del back["source_sha256"][k]
check(typed(back,parent),"full execution orderedtyped inverse exact; other8owned whole same")
check(json.dumps(back,ensure_ascii=False,indent=2)+"\n"==path(h["execution_parent"]["path"]).read_text(encoding="utf-8"),"execution whole UTF8 serialized inverse")
scope=load(h["scope_request"]["path"])
stage=load(h["actual_parent_stage"]["path"])
prior={x["target"]:x for x in stage["targets"]}
expected=(set(prior)-set(scope["excluded_unchanged_exact7"]))|{CO,CON}
actualtargets={x["target"] for x in scope["targets"]}
check(actualtargets==expected and len(actualtargets)==24,"scope29 minus7 plus2 equals exact24")
check(sum(x["kind"]=="GD" for x in scope["targets"])==10 and sum(x["kind"]=="JSON" for x in scope["targets"])==14,"partition10GD14JSON")
for row in scope["targets"]:
    check(sha(row["old_snapshot"])==row["old_sha256"] and sha(row["target"])==row["old_sha256"],"scope current/old snapshot exact "+row["target"])
    if row["target"] in prior:
        check(prior[row["target"]]["candidate_sha256"]==row["old_sha256"],"scope old SHA from EB875 actual "+row["target"])
for k in scope["excluded_unchanged_exact7"]:
    check(k not in actualtargets and sha(k)==prior[k]["candidate_sha256"],"seven explicitly unchanged current "+k)
result=emit("culture40_24scope_BF043_independent_static_dependency_review_READY.json",{
    "status":"CULTURE40_CODE_EXECUTION_SCOPE_STATIC_NO_BLOCKER_FOR_PREPARATION_ONLY",
    "handoff":evidence(D/"handoff_EXECUTION_AND_SCOPE_PROPOSAL.json"),"scope":evidence(D/"exact24_existing_scope_PROPOSAL_NOT_APPROVED.json"),"inverse":evidence(D/"whole_culture_code_data_inverse_READY.json"),"execution":evidence(D/"execution_successor_PROPOSAL.json"),
    "checks":len(checks),"wholebyte_reconstruction_records":list(proof["records"]),"contract":{"changed_leaves":1,"other25_same":True,"no_flags_rewards_quests_logic_change":True},
    "Temple":{"binding189_changed2_other187same":True,"code_only2literals_wholebyte_inverse":True},
    "execution":{"owned10_same_members":True,"changed_edges_exact2":[CO,TE],"other8_whole_same":True,"historical80_same":True,"new5_exact":True,"total85":True,"orderedtyped_and_UTF8_inverse":True},
    "scope":{"existing24":True,"GD":10,"JSON":14,"parent_EB875_minus7_plusCoordinator_contract":True,"all24current_old_snapshots_exact":True,"excluded7_current_unchanged":True},
    "limits":["not final driver/input DAG approval or Stage/deployment permission", "no engine/collector/native/PNG decode or large media hashing", "no runtime readiness/firstdraw/six-child success claim", "retain failed07 and true C0000005", "future source closure must independently carry the contract->C edge and both Temple source values"]
})
print("STATIC",result)
