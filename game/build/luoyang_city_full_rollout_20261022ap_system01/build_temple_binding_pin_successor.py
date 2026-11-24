"""NEW-only exact Temple binding-pin fix plus explicit provenance/authority.

Does not edit canonical files, change existing proofs, run Godot or recompute
native geometry. The original stage02 deployment remains a recorded fact.
"""
from pathlib import Path
import copy
import hashlib
import json

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
PREFIX = "res://build/luoyang_city_full_rollout_20261022ap_system01/"
TEMPLE = "res://scripts/city/luoyang_temple_assembly_20261016.gd"
OUT = HERE / "temple_binding_pin_successor"
PINS = {
 PREFIX+"Temple_candidate.gd":"bf65ef1ddb699c917b07b0499373320677299a7f14b01d8ece80b6e130158b93",
 PREFIX+"temple_binding_READY.json":"fde4be38e9fbfb72c588b9a408a0295269ae3d270a7b498b4d8eac20920893dc",
 PREFIX+"temple_binding_inverse.json":"7c9785c2510973ee6daec9955d2c138ccd8efc4e2a604179c0966c4b8d0bcb97",
 "res://build/luoyang_estate_courtyard_20261021an_system01/staged_retry2/temple_binding.json":"692780bf3ffc26f54d3ec7253ec2861b59470e7e78c3d71f0fd6709344ce13d9",
 PREFIX+"x_contract_inverse.json":"bd063c4e9ad2c2d2579cde26ae735f98d8a5d6f7df163ac324dd570acafa0cf6",
 PREFIX+"before/runtime_contract_AO_B564.json":"b56409417fec3cb9fb0a31600f09d72edd333de11cba0144c3407baec8b3fd8d",
 PREFIX+"runtime_contract_AP.json":"4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a",
 PREFIX+"execution_staged_root02_g/execution_successor.json":"9c3f9b5a35360ca2b488424ea0a3922759bf3b70d21452c7298dff51e7aac817",
}


def sha(data): return hashlib.sha256(data).hexdigest()
def local(key): return GAME/key.removeprefix("res://")
def load_bytes(key):
    data=local(key).read_bytes();assert sha(data)==PINS[key],key;return data
def load_json(key): return json.loads(load_bytes(key))
def resource(path): return "res://"+path.relative_to(GAME).as_posix()


def inverse_proof(proof, before_name="parent_path", before_sha="parent_sha256"):
    before=load_bytes(proof[before_name]);after=load_bytes(proof["candidate_path"])
    assert sha(before)==proof[before_sha] and sha(after)==proof["candidate_sha256"]
    inverse=after.decode("utf-8")
    for row in reversed(proof["replacements"]):
        assert inverse.count(row["new"])==1
        inverse=inverse.replace(row["new"],row["old"],1)
    assert inverse.encode("utf-8")==before, "Whole exact byte inverse"
    return json.loads(before),json.loads(after)


def main():
    assert not OUT.exists(), "Preserve prior failed/deployed sources; NEW output folder only"
    binding_proof=load_json(PREFIX+"temple_binding_inverse.json")
    before_binding,binding=inverse_proof(binding_proof)
    typed=copy.deepcopy(binding)
    old_delta=before_binding["source_delta"];new_delta=binding["source_delta"]
    assert old_delta.keys()==new_delta.keys()
    changed={k:{"old_sha256":old_delta[k],"new_sha256":new_delta[k]} for k in old_delta if old_delta[k]!=new_delta[k]}
    expected_owned={
     "res://scripts/field/field_walkable_controller.gd",
     "res://scripts/autoload/scene_router.gd",
     "res://scripts/city/luoyang_city_tasks_20261016.gd",
     "res://scripts/city/luoyang_harbour_life_runtime_20261016.gd",
     "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd",
    }
    contract="res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
    assert changed.keys()==expected_owned|{contract} and len(changed)==6
    for key in changed: typed["source_delta"][key]=old_delta[key]
    assert typed==before_binding,"Only the6 source_delta scalar values, no task/native/history fields"
    xproof=load_json(PREFIX+"x_contract_inverse.json")
    xbefore,xafter=inverse_proof(xproof,"before_path","before_sha256")
    original=load_bytes(PREFIX+"Temple_candidate.gd")
    old='const BIND_SHA="d581c06833d535155cb135d19d0130f675df85d2e5f23e7e5f225a59fffa4c7c"'
    new='const BIND_SHA="fde4be38e9fbfb72c588b9a408a0295269ae3d270a7b498b4d8eac20920893dc"'
    source=original.decode("utf-8");assert source.count(old)==1
    candidate=source.replace(old,new,1).encode("utf-8")
    assert candidate.decode("utf-8").replace(new,old,1).encode("utf-8")==original
    authority=load_json(PREFIX+"execution_staged_root02_g/execution_successor.json")
    for key in expected_owned:
        assert authority["owned"][key]["current_sha256"]==new_delta[key]
        assert any(edge["old_sha256"]==old_delta[key] for edge in authority["owned"][key]["edges"])
    assert sha(load_bytes(PREFIX+"runtime_contract_AP.json"))==new_delta[contract]
    assert sha(load_bytes(PREFIX+"before/runtime_contract_AO_B564.json"))==old_delta[contract]
    # Full binding consumption audit compares against declared immutable SHA,
    # never copies an observed disk hash into expected source data.
    native_parent=binding["parent_binding_path"]
    native_parent_bytes=local(native_parent).read_bytes()
    assert sha(native_parent_bytes)==binding["parent_binding_sha256"]
    parent_data=json.loads(native_parent_bytes)
    merged=dict(parent_data["source_sha256"]);merged.update(new_delta)
    audit=[]
    for key,expected in merged.items():
        p=local(key);actual=sha(p.read_bytes()) if p.is_file() else "ABSENT"
        audit.append({"path":key,"expected_sha256":expected,"actual_sha256":actual,"matches":actual==expected})
    problems=[row for row in audit if not row["matches"]]
    # This diagnostic does not silently authorize any mismatch.
    out_temple=OUT/"Temple_binding_pin_READY.gd"
    out_authority=OUT/"execution_successor_READY.json"
    out_receipt=OUT/"binding_pin_source_proof_READY.json"
    next_authority=copy.deepcopy(authority)
    tr=next_authority["owned"][TEMPLE]
    assert tr["current_sha256"]==PINS[PREFIX+"Temple_candidate.gd"]
    tr["current_sha256"]=sha(candidate)
    edge={"path":TEMPLE,"old_sha256":sha(original),"new_sha256":sha(candidate),"old_snapshot":PREFIX+"Temple_candidate.gd","new_snapshot":resource(out_temple),"whole_inverse":True,"replacements":[{"old":old,"new":new}]}
    tr["edges"].append(edge)
    # The previous proof stays immutable. Add the legitimate exact binding,
    # its inverse/parent and the nested culture-source inverse to the proof
    # closure explicitly; do not add the proof itself or external indices.
    add_sources={k:v for k,v in PINS.items() if k!=PREFIX+"execution_staged_root02_g/execution_successor.json"}
    add_sources[resource(out_temple)]=sha(candidate)
    add_sources[native_parent]=binding["parent_binding_sha256"]
    for key,value in add_sources.items():
        if key in next_authority["source_sha256"]: assert next_authority["source_sha256"][key]==value
        next_authority["source_sha256"][key]=value
    # Exact typed inverse: remove only explicit added sources, undo only the
    # single Temple current hash and added edge, then compare entire old proof.
    inverse=copy.deepcopy(next_authority)
    inverse["owned"][TEMPLE]["current_sha256"]=authority["owned"][TEMPLE]["current_sha256"]
    inverse["owned"][TEMPLE]["edges"].pop()
    for key in next_authority["source_sha256"]:
        if key not in authority["source_sha256"]: inverse["source_sha256"].pop(key)
    assert inverse==authority
    result={"schema_version":1,"status":"NEW_EXACT_TEMPLE_BINDING_PIN_SUCCESSOR_PENDING_ROOT_DEPLOY_AND_ENGINE","canonical_target":TEMPLE,"original_deployed_stage02_sha256":sha(original),"new_candidate_path":resource(out_temple),"new_candidate_sha256":sha(candidate),"sole_source_delta":{"old":old,"new":new},"whole_byte_inverse_to_BF65":True,"logic_NATIVE_geometry_tasks_rewards_not_changed":True,"binding_parent":binding_proof["parent_path"],"binding_parent_sha256":binding_proof["parent_sha256"],"binding_candidate":binding_proof["candidate_path"],"binding_candidate_sha256":binding_proof["candidate_sha256"],"binding_whole_byte_and_typed_inverse":True,"binding_exact_six_delta":changed,"binding_parent_v14_unchanged":{native_parent:binding["parent_binding_sha256"]},"culture_contract_whole_byte_inverse":True,"new_authority_path":resource(out_authority),"old_authority_path":PREFIX+"execution_staged_root02_g/execution_successor.json","old_authority_sha256":PINS[PREFIX+"execution_staged_root02_g/execution_successor.json"],"authority_sole_owned_change":TEMPLE,"authority_whole_typed_inverse":True,"added_authority_sources":{k:v for k,v in add_sources.items() if k not in authority["source_sha256"]},"binding_merged_source_audit":{"count":len(audit),"passed":not problems,"mismatches":problems},"no_current_sha_backfill":True,"necessary_source_finalization":["Update every exact owned Temple code leaf BF65 to this new candidate only, preserving all old source/artifact maps as history.","Use new execution proof/header/index exact source successor; include its explicit added proof closure, no self/index backpin.","All four city maps, Quarter and Market transitive closure, unchanged Estate owned-source map and Temple actual source map must receive only the newly consumed leaves/explicit executable source succession.","Temple binding itself remains original FDE4 bytes and parent692780; do not rewrite it to match D581.","Root must back up and authorize this successor from the actual stage02 deployed snapshot, not roll back/pretend stage02 never happened."],"all_binding_merged_source_audit":audit,"unrun":["Godot","Actual source_paths/binding load","Field/input/travel"]}
    OUT.mkdir()
    out_temple.write_bytes(candidate)
    out_authority.write_text(json.dumps(next_authority,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    result["new_authority_sha256"]=sha(out_authority.read_bytes())
    out_receipt.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"Temple_sha256":sha(candidate),"authority_sha256":sha(out_authority.read_bytes()),"receipt_sha256":sha(out_receipt.read_bytes()),"binding_merged_leaves":len(audit),"binding_mismatches":problems,"binding_six_values_inverse":True,"source_sha256_count":len(next_authority["source_sha256"])}))


if __name__=="__main__": main()
