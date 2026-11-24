"""Exact NEW Temple/source-authority successor from real formal D581 bytes.

Preserves the failed original builder and old FDE4/692 declaration. Never
normalizes the mixed CRLF/LF predecessor. Does not run Godot or write canonical.
"""
from pathlib import Path
import copy
import hashlib
import json

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
ROOT="res://build/luoyang_city_full_rollout_20261022ap_system01/"
OUT=HERE/"temple_binding_pin_successor_retry1"
TARGET="res://scripts/city/luoyang_temple_assembly_20261016.gd"
OLD_BIND="res://build/luoyang_estate_courtyard_20261021an_system01/staged_retry2/temple_binding.json"
PINS={
 OLD_BIND:"d581c06833d535155cb135d19d0130f675df85d2e5f23e7e5f225a59fffa4c7c",
 ROOT+"Temple_candidate.gd":"bf65ef1ddb699c917b07b0499373320677299a7f14b01d8ece80b6e130158b93",
 ROOT+"temple_binding_READY.json":"fde4be38e9fbfb72c588b9a408a0295269ae3d270a7b498b4d8eac20920893dc",
 ROOT+"temple_binding_inverse.json":"7c9785c2510973ee6daec9955d2c138ccd8efc4e2a604179c0966c4b8d0bcb97",
 ROOT+"x_contract_inverse.json":"bd063c4e9ad2c2d2579cde26ae735f98d8a5d6f7df163ac324dd570acafa0cf6",
 ROOT+"before/runtime_contract_AO_B564.json":"b56409417fec3cb9fb0a31600f09d72edd333de11cba0144c3407baec8b3fd8d",
 ROOT+"runtime_contract_AP.json":"4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a",
 ROOT+"execution_staged_root02_g/execution_successor.json":"9c3f9b5a35360ca2b488424ea0a3922759bf3b70d21452c7298dff51e7aac817",
}
def sha(data):return hashlib.sha256(data).hexdigest()
def path(key):return GAME/key.removeprefix("res://")
def key(p):return "res://"+p.relative_to(GAME).as_posix()
def read(k):
    b=path(k).read_bytes();assert sha(b)==PINS[k],k;return b
def js(k):return json.loads(read(k))


def main():
    assert not OUT.exists(),"NEW-only retry"
    legacy=js(ROOT+"temple_binding_inverse.json")
    old_bytes=read(OLD_BIND);old=json.loads(old_bytes)
    fixed_text=old_bytes.decode("utf-8")
    for row in legacy["replacements"]:
        assert fixed_text.count(row["old"])==1
        fixed_text=fixed_text.replace(row["old"],row["new"],1)
    binding_bytes=fixed_text.encode("utf-8");binding=json.loads(binding_bytes)
    assert binding==js(ROOT+"temple_binding_READY.json"),"Reuse legitimate6 source-only semantics, not its wrong byte predecessor claim"
    inverse=fixed_text
    for row in reversed(legacy["replacements"]):
        assert inverse.count(row["new"])==1
        inverse=inverse.replace(row["new"],row["old"],1)
    assert inverse.encode("utf-8")==old_bytes
    assert binding_bytes.count(b"\r\n")==old_bytes.count(b"\r\n")==163
    typed=copy.deepcopy(binding);old_delta=old["source_delta"];new_delta=binding["source_delta"]
    assert old_delta.keys()==new_delta.keys()
    changed={p:{"old_sha256":old_delta[p],"new_sha256":new_delta[p]} for p in old_delta if old_delta[p]!=new_delta[p]}
    assert len(changed)==6
    for p in changed:typed["source_delta"][p]=old_delta[p]
    assert typed==old,"Exact six values, no geometry/art/text/task/schema/history change"
    # Independently verify nested x-contract provenance, not just its current SHA.
    xp=js(ROOT+"x_contract_inverse.json");xb=read(xp["before_path"]);xn=read(xp["candidate_path"])
    xt=xn.decode("utf-8")
    for row in reversed(xp["replacements"]):
        assert xt.count(row["new"])==1;xt=xt.replace(row["new"],row["old"],1)
    assert xt.encode("utf-8")==xb
    authority=js(ROOT+"execution_staged_root02_g/execution_successor.json")
    contract="res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
    for p,row in changed.items():
        if p==contract:
            assert row["old_sha256"]==sha(xb) and row["new_sha256"]==sha(xn)
        else:
            ar=authority["owned"][p]
            assert ar["current_sha256"]==row["new_sha256"]
            assert any(e["old_sha256"]==row["old_sha256"] for e in ar["edges"])
    parent_path=binding["parent_binding_path"];parent_sha=binding["parent_binding_sha256"]
    parent_bytes=path(parent_path).read_bytes();assert sha(parent_bytes)==parent_sha
    parent=json.loads(parent_bytes);merged=dict(parent["source_sha256"]);merged.update(new_delta)
    audit=[]
    for p,expected in merged.items():
        actual=sha(path(p).read_bytes()) if path(p).is_file() else "ABSENT"
        audit.append({"path":p,"expected_sha256":expected,"actual_sha256":actual,"matches":expected==actual})
    assert all(r["matches"] for r in audit),[r for r in audit if not r["matches"]]
    # Every actually consumed owned leaf is fixed by9C; no missing parent-owned
    # pin can hide behind dynamic execution approval in Temple.prepare.
    owned_refs={p:merged[p] for p in merged if p in authority["owned"]}
    assert all(authority["owned"][p]["current_sha256"]==v for p,v in owned_refs.items())
    bind_out=OUT/"binding_READY.json";temple_out=OUT/"Temple_binding_pin_READY.gd"
    proof_out=OUT/"binding_successor_proof_READY.json";authority_out=OUT/"execution_successor_READY.json";handoff_out=OUT/"handoff_READY.json"
    before_temple=read(ROOT+"Temple_candidate.gd");source=before_temple.decode("utf-8")
    old_pin='const BIND_PATH="'+ROOT+'temple_binding_READY.json"\nconst BIND_SHA="'+PINS[OLD_BIND]+'"'
    new_pin='const BIND_PATH="'+key(bind_out)+'"\nconst BIND_SHA="'+sha(binding_bytes)+'"'
    assert source.count(old_pin)==1
    candidate=source.replace(old_pin,new_pin,1).encode("utf-8")
    assert candidate.decode("utf-8").replace(new_pin,old_pin,1).encode("utf-8")==before_temple
    proof={"schema_version":1,"status":"EXACT_FORMAL_D581_TO_AP_SIX_SOURCE_VALUES_NO_NATIVE_CHANGE","binding_parent_path":OLD_BIND,"binding_parent_sha256":PINS[OLD_BIND],"binding_candidate_path":key(bind_out),"binding_candidate_sha256":sha(binding_bytes),"binding_exact_replacements":legacy["replacements"],"whole_byte_inverse":True,"whole_typed_inverse_exact6":True,"CRLF_count_preserved":163,"old_LF_count":old_bytes.count(b"\n"),"new_LF_count":binding_bytes.count(b"\n"),"source_delta_changes":changed,"nested_x_contract_byte_inverse":True,"x_proof_path":ROOT+"x_contract_inverse.json","x_proof_sha256":PINS[ROOT+"x_contract_inverse.json"],"native_parent_v14":{parent_path:parent_sha},"consumed_merged_source_sha256":merged,"all189_declared_leaf_actual_comparison":audit,"owned_consumed_fixed9C_values":owned_refs,"Temple_before":{ROOT+"Temple_candidate.gd":sha(before_temple)},"Temple_candidate":{key(temple_out):sha(candidate)},"Temple_exact_replacement":{"old":old_pin,"new":new_pin},"Temple_whole_byte_inverse":True,"old_bad_proof_preserved_not_used_as_actual_byte_parent":{ROOT+"temple_binding_inverse.json":PINS[ROOT+"temple_binding_inverse.json"]},"earlier_FDE4_same_typed_content_only":{ROOT+"temple_binding_READY.json":PINS[ROOT+"temple_binding_READY.json"]},"no_current_sha_backfill":True,"no_engine_or_native_republish":True}
    proof_bytes=(json.dumps(proof,ensure_ascii=False,indent=2)+"\n").encode("utf-8")
    nxt=copy.deepcopy(authority);tr=nxt["owned"][TARGET]
    assert tr["current_sha256"]==sha(before_temple)
    tr["current_sha256"]=sha(candidate)
    tr["edges"].append({"path":TARGET,"old_sha256":sha(before_temple),"new_sha256":sha(candidate),"old_snapshot":ROOT+"Temple_candidate.gd","new_snapshot":key(temple_out),"whole_inverse":True,"replacements":[{"old":old_pin,"new":new_pin}]})
    added={OLD_BIND:PINS[OLD_BIND],key(bind_out):sha(binding_bytes),key(temple_out):sha(candidate),key(proof_out):sha(proof_bytes),parent_path:parent_sha,ROOT+"x_contract_inverse.json":PINS[ROOT+"x_contract_inverse.json"],ROOT+"before/runtime_contract_AO_B564.json":PINS[ROOT+"before/runtime_contract_AO_B564.json"],ROOT+"runtime_contract_AP.json":PINS[ROOT+"runtime_contract_AP.json"]}
    for p,v in added.items():
        assert p not in nxt["source_sha256"] or nxt["source_sha256"][p]==v
        nxt["source_sha256"][p]=v
    inverse=copy.deepcopy(nxt);inverse["owned"][TARGET]=copy.deepcopy(authority["owned"][TARGET])
    for p in added:
        if p not in authority["source_sha256"]:del inverse["source_sha256"][p]
    assert inverse==authority
    authority_bytes=(json.dumps(nxt,ensure_ascii=False,indent=2)+"\n").encode("utf-8")
    handoff={"schema_version":1,"status":"NEW_TEMPLE_SOURCE_PIN_SUCCESSOR_PENDING_ROOT_AUTHORIZED_DEPLOY_AND_ACTUAL","canonical_target":TARGET,"old_deployed_BF65_sha256":sha(before_temple),"new_candidate_path":key(temple_out),"new_candidate_sha256":sha(candidate),"binding_path":key(bind_out),"binding_sha256":sha(binding_bytes),"binding_proof_path":key(proof_out),"binding_proof_sha256":sha(proof_bytes),"authority_path":key(authority_out),"authority_sha256":sha(authority_bytes),"authority_parent_9C3F_sha256":PINS[ROOT+"execution_staged_root02_g/execution_successor.json"],"only_owned_current_and_edge_change":TARGET,"unchanged_other_owned_rows":len(authority["owned"])-1,"all_189_binding_consumed_pins_exact":True,"binding_consumed_owned_count":len(owned_refs),"binding_derived_from_real_D581_exact_bytes":True,"not_historical692_byte_claim":True,"added_authority_source_sha256":added,"source_finalizer_required":["New Root-approved snapshot after original37 stage02 deployed; preserve original37 and all historical failed proofs.","Replace actual Temple code leaf BF65→new candidate wherever actually consumed. No no-op edge for unchanged9.","Update execution approval/header+index and dependent closed owner manifests using only explicit new Temple edge/proof closure. No self/backpin or current SHA fallback.","Temple.source_paths now consumes NEW binding_READY bytes, parentv14 unchanged; historical FDE4 no longer runtime BIND_PATH.","Keep all source/native map histories; no geometry, rooms, assets, navigation or task tests replay."],"unrun":["Godot compile/source_paths","Field/Physics/travel"]}
    OUT.mkdir()
    bind_out.write_bytes(binding_bytes);temple_out.write_bytes(candidate);proof_out.write_bytes(proof_bytes);authority_out.write_bytes(authority_bytes)
    handoff_out.write_text(json.dumps(handoff,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"Temple_sha256":sha(candidate),"binding_sha256":sha(binding_bytes),"binding_proof_sha256":sha(proof_bytes),"authority_sha256":sha(authority_bytes),"handoff_sha256":sha(handoff_out.read_bytes()),"binding_consumed":len(merged),"owned_consumed":len(owned_refs),"authority_sources":len(nxt["source_sha256"])}))


if __name__=="__main__":main()
