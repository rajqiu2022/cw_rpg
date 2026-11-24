"""Root-only final Stage/deployment transport for one entry/32px/one-image smoke."""
import argparse, hashlib, json
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PREFIX="res://build/luoyang_market_workcourts_20261026b_system01/"
PINS={"smoke_worker_NOTREADY.gd":"2155c27936f9c04b49fd58d1d7a60fa454cc756f886cce1f3dbf61f049924c9f", "smoke_bootstrap_NOTREADY.gd":"437cfc8a272fe3cfd19ee4f891c3252668580bc45fb81f2a1f8eb5bde7b3b83b", "smoke_fixture_NOTREADY.json":"2ee9ef1755a6203c7d50844473654a0eebad34643e2afe93b4fc07660ef6f918"}
def sha(data): return hashlib.sha256(data).hexdigest()
def physical(path): return GAME/path.removeprefix("res://")
def encoded(value): return (json.dumps(value,ensure_ascii=False,indent=2)+"\n").encode()
def read(path,pin):
    data=physical(path).read_bytes();assert sha(data)==pin.lower(),path;return data
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--stage",required=True);parser.add_argument("--stage-sha",required=True)
    parser.add_argument("--deployment",required=True);parser.add_argument("--deployment-sha",required=True)
    args=parser.parse_args()
    old={name:(BASE/name).read_bytes() for name in PINS}
    assert all(sha(old[name])==pin for name,pin in PINS.items())
    stage=json.loads(read(args.stage,args.stage_sha));deploy=json.loads(read(args.deployment,args.deployment_sha))
    assert stage["source_first"]==stage["source_final"] and deploy["passed"] is True
    assert deploy["stage"]=={"path":args.stage,"sha256":args.stage_sha.lower()}
    declared=dict(stage["source_final"])
    for row in stage["targets"]: declared[row["target"]]=row["candidate_sha256"]
    # Only three actual consumers and this batch's immutable data, not a collector.
    dependencies={}
    for path in ["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/city/luoyang_environment_layer_20261022ap.gd", PREFIX+"market_five_use_spec_street02_NOTREADY.json", PREFIX+"market_purpose_layer_street02_CANDIDATE.gd", PREFIX+"author_living_street01_NOTREADY.json"]:
        assert path in declared,path
        read(path,declared[path]);dependencies[path]=declared[path]
    for name,pin in PINS.items(): dependencies[PREFIX+name]=pin
    dependencies[args.stage]=args.stage_sha.lower();dependencies[args.deployment]=args.deployment_sha.lower()
    dest=BASE/"SMOKE_ROOT_READY";assert not dest.exists(),"NEW_SMOKE_DESTINATION_ONLY"
    fixture=json.loads(old["smoke_fixture_NOTREADY.json"])
    fixture.update(ready=True,formal_deployed=True,status="ROOT_ACTUAL_DECLARED_HEAD_SINGLE_MARKET_SMOKE",dependencies=dependencies,formal_stage_actual={"path":args.stage,"sha256":args.stage_sha.lower()},Root_deployment_actual={"path":args.deployment,"sha256":args.deployment_sha.lower()})
    new_input=encoded(fixture)
    back=dict(fixture)
    for key in ["formal_stage_actual","Root_deployment_actual"]: back.pop(key)
    original=json.loads(old["smoke_fixture_NOTREADY.json"])
    for key in ["ready","formal_deployed","status","dependencies"]: back[key]=original[key]
    assert encoded(back)==old["smoke_fixture_NOTREADY.json"]
    key=old["smoke_bootstrap_NOTREADY.gd"]
    edits=[(b"const READY := false",b"const READY := true"),((PREFIX+"smoke_fixture_NOTREADY.json").encode(),(PREFIX+"SMOKE_ROOT_READY/fixture_ROOT_READY.json").encode()),(b"PENDING_ROOT_FINAL_SOURCE_HEAD",sha(new_input).encode())]
    for a,b in edits: assert key.count(a)==1;key=key.replace(a,b)
    inverse=key
    for a,b in reversed(edits): assert inverse.count(b)==1;inverse=inverse.replace(b,a)
    assert inverse==old["smoke_bootstrap_NOTREADY.gd"]
    outputs={"fixture_ROOT_READY.json":new_input,"bootstrap_ROOT_READY.gd":key}
    proof={"status":"ROOT_SOURCE_TRANSPORT_ONLY_NO_ENGINE", "worker_business_unchanged":PINS["smoke_worker_NOTREADY.gd"], "whole_input_inverse":True,"whole_bootstrap_inverse":True,"dependencies_from_Stage_not_observed_gameplay":True,"written":{name:{"sha256":sha(data),"bytes":len(data)} for name,data in outputs.items()}}
    dest.mkdir()
    for name,data in outputs.items():
        with (dest/name).open("xb") as stream: stream.write(data)
    with (dest/"transport_whole_inverse.json").open("xb") as stream: stream.write(encoded(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__": main()
