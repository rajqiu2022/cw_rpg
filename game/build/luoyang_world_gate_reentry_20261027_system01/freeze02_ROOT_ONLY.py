"""Root-only exact transport, no engine/canonical writes or source collector."""
import argparse, hashlib, json
from pathlib import Path

BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PREFIX="res://build/luoyang_world_gate_reentry_20261027_system01/"
PINS={
    "world_gate_worker_NOTREADY.gd":"7aaf029b033b783bdbfaf0d4237769cb03eb9507a683b307327786a6a070c39b",
    "bootstrap_NOTREADY.gd":"c16e44f3b3a3cf3ca2efd73cd0780d3796a58504ce5cc94f81022163417f356f",
    "fixture_NOTREADY.json":"e0ed98013f5e04c450bde80541cf652300eee4a3f428839102c6044706100050",
}
FIXED={
    "res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd":"3367c98096f8e3f66e629ca8de0c3fd589c79ebf6df02c3bee0e7206363c31ca",
    "res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
    "res://data/scenes/world_map_jianghu.tres":"685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046",
    "res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
    "res://scripts/field/world_v15_exit_zone.gd":"689a200292091c384e533455db82c81463eac198a9fc89bb48cc409311d042e0",
    "res://scripts/field/exit_zone.gd":"bf0ee27eacdb592dc977e378e9e4b7fbe1c6e695f9101cd9415a303747e22bc5",
}
def sha(data): return hashlib.sha256(data).hexdigest()
def enc(value): return (json.dumps(value,ensure_ascii=False,indent=2)+"\n").encode()
def read(path,pin):
    assert path.startswith("res://") and ".." not in path
    data=(GAME/path[6:]).read_bytes()
    assert sha(data)==pin.lower(),path
    return data

def main():
    cli=argparse.ArgumentParser()
    for name in ["stage","stage-sha","deployment","deployment-sha"]: cli.add_argument("--"+name,required=True)
    args=cli.parse_args()
    old={name:(BASE/name).read_bytes() for name in PINS}
    assert all(sha(old[name])==pin for name,pin in PINS.items())
    stage=json.loads(read(args.stage,args.stage_sha))
    deploy=json.loads(read(args.deployment,args.deployment_sha))
    assert stage["source_first"]==stage["source_final"] and deploy["passed"] is True
    assert deploy["stage"]=={"path":args.stage,"sha256":args.stage_sha.lower()}
    node=stage["nodes"]["expected_ch4_s0_luoyang_gate_true"]
    assert json.loads(read(node["path"],node["sha256"]))==node["value"]
    expected=node["value"]["source_sha256"]
    assert node["value"]["scene_id"]=="ch4_s0_luoyang_gate" and expected
    declared=dict(stage["source_final"])
    declared.update({row["target"]:row["candidate_sha256"] for row in stage["targets"]})
    deps=dict(FIXED)
    for path in ["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_environment_layer_20261022ap.gd"]:
        assert declared[path].lower()==expected[path].lower(),path
        deps[path]=declared[path].lower()
    # G is authority-indirect, not a direct Gate source-map leaf. Its exact
    # formal value comes from this fixed Stage, never from observed gameplay.
    gpath="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
    assert stage["source_final"][gpath].lower()=="f8b46e3b3673d32c0d5bbe764cc903d6e102aa11067c99c64ecdb3e248dc5dd3"
    deps[gpath]=stage["source_final"][gpath].lower()
    for path,pin in deps.items(): read(path,pin)
    deps.update({PREFIX+name:pin for name,pin in PINS.items()})
    deps.update({args.stage:args.stage_sha.lower(),args.deployment:args.deployment_sha.lower(),node["path"]:node["sha256"].lower()})
    spec=json.loads(old["fixture_NOTREADY.json"])
    assert spec["whole_ms"]==60000 and spec["entry_ms"]==20000 and spec["max_pictures"]==1
    spec.update(ready=True,formal_deployed=True,status="ROOT_ACTUAL_EXACT_EOF_SOURCE_SUCCESSOR_NORMAL_WORLD_GATE",dependencies=deps,expected_gate_sources=expected,formal_stage={"path":args.stage,"sha256":args.stage_sha.lower()},formal_deployment={"path":args.deployment,"sha256":args.deployment_sha.lower()})
    data=enc(spec)
    inverse=json.loads(data)
    original=json.loads(old["fixture_NOTREADY.json"])
    for name in ["formal_stage","formal_deployment"]: del inverse[name]
    for name in ["ready","formal_deployed","status","dependencies","expected_gate_sources"]: inverse[name]=original[name]
    assert enc(inverse)==old["fixture_NOTREADY.json"]
    bootstrap=old["bootstrap_NOTREADY.gd"]
    edits=[(b"const READY := false",b"const READY := true"),(b"PENDING_REVIEWED_WORKER",PINS["world_gate_worker_NOTREADY.gd"].encode()),((PREFIX+"fixture_NOTREADY.json").encode(),(PREFIX+"ROOT_READY01/fixture_ROOT_READY.json").encode()),(b"PENDING_ROOT_FORMAL_SOURCE_HEAD",sha(data).encode())]
    for before,after in edits:
        assert bootstrap.count(before)==1
        bootstrap=bootstrap.replace(before,after)
    back=bootstrap
    for before,after in reversed(edits):
        assert back.count(after)==1
        back=back.replace(after,before)
    assert back==old["bootstrap_NOTREADY.gd"]
    outputs={"fixture_ROOT_READY.json":data,"bootstrap_ROOT_READY.gd":bootstrap}
    proof={"status":"ROOT_ONLY_MECHANICAL_TRANSPORT_NO_ENGINE","whole_fixture_inverse":True,"whole_bootstrap_inverse":True,"worker_unchanged":PINS["world_gate_worker_NOTREADY.gd"],"expected_source_map_from_fixed_stage_node_not_observed_gameplay":True,"whole_ms":60000,"entry_ms":20000,"one_real_world_Space":True,"maximum_one_image":True,"outputs":{name:{"sha256":sha(value),"bytes":len(value)} for name,value in outputs.items()}}
    destination=BASE/"ROOT_READY01"
    assert not destination.exists(),"NEW_DEST_ONLY"
    destination.mkdir()
    for name,value in outputs.items():
        with (destination/name).open("xb") as file: file.write(value)
    with (destination/"mechanical_whole_inverse.json").open("xb") as file: file.write(enc(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__": main()
