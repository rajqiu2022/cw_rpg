"""Mechanical two-view fixture from fixed Root actual Stage/deployment only."""
import argparse,hashlib,json,re
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PREFIX="res://build/luoyang_exit_wall_fix_20261027b_system01/"
PINS={"view_worker_NOTREADY.gd":"9b651d8813f25e5d32d81103b31dc97f0b4112043edd50c67a589aa0871b889c","view_fixture_NOTREADY.json":"f71ffbc6c36d423d3803cc93dfd4d5b84e3e324a3d2ee1babf119280b31fc9d6","view_bootstrap_NOTREADY.gd":"d01f708c0e1b7d06bfaac6624403fcaf3c4f755c2e9a9b3a229ff6f404918ed4"}
FIXED={"res://build/luoyang_seven_fields_layout_20261026c_system01/smoke_seven_worker_NOTREADY.gd":"8c20dcab4ac645ba4be40c59a3bc65aa797fefd7ea57a814e179b7acc71c8349","res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd":"3367c98096f8e3f66e629ca8de0c3fd589c79ebf6df02c3bee0e7206363c31ca","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","res://build/luoyang_city_finish_20261025i_art01/market_two_adult_wall_20261027a_FINAL01_BUILD_ONLY.json":"4976c8d14d5af9b6bc4c15c283950f014cbb869f2eb16fe23fed286c40a14f43",PREFIX+"ROOT_READY01/output/108580/result.json":"8f14b9bf11ce635fe037e3cb9689a59052bbc04653dc6861bd99740375d7fb2e"}
def sha(data):return hashlib.sha256(data).hexdigest()
def enc(value):return (json.dumps(value,ensure_ascii=False,indent=2)+"\n").encode()
def read(path,pin):
    assert path.startswith("res://") and ".." not in path
    data=(GAME/path[6:]).read_bytes();assert sha(data)==pin.lower(),path;return data
def main():
    cli=argparse.ArgumentParser()
    for key in ["stage","stage-sha","deployment","deployment-sha"]:cli.add_argument("--"+key,required=True)
    args=cli.parse_args();old={name:(BASE/name).read_bytes() for name in PINS}
    assert all(sha(old[name])==pin for name,pin in PINS.items())
    stage=json.loads(read(args.stage,args.stage_sha));deploy=json.loads(read(args.deployment,args.deployment_sha))
    assert stage["source_first"]==stage["source_final"] and deploy["passed"] is True
    assert deploy["stage"]=={"path":args.stage,"sha256":args.stage_sha.lower()}
    declared=dict(stage["source_final"]);declared.update({row["target"]:row["candidate_sha256"] for row in stage["targets"]})
    deps=dict(FIXED);spec=json.loads(old["view_fixture_NOTREADY.json"])
    assert spec["whole_ms"]==60000 and spec["entry_ms"]==20000 and spec["max_pictures"]==2
    assert [row["scene_id"] for row in spec["cases"]]==["ch4_s1_luoyang_yamen","ch4_s3_luoyang_market"]
    for row in spec["cases"]:
        node=stage["nodes"]["expected_"+row["scene_id"]+"_true"]
        assert json.loads(read(node["path"],node["sha256"]))==node["value"]
        assert node["value"]["scene_id"]==row["scene_id"]
        row["expected_sources"]=node["value"]["source_sha256"]
        deps[node["path"]]=node["sha256"].lower()
    cpath="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
    for path in [cpath,"res://scripts/field/field_walkable_controller.gd","res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_environment_layer_20261022ap.gd"]:
        for row in spec["cases"]:assert row["expected_sources"][path].lower()==declared[path].lower(),path
        deps[path]=declared[path].lower()
    ctext=read(cpath,deps[cpath]).decode()
    runtime=re.findall(r'^const FINISH25I_RUNTIME: String="([^"]+)"$',ctext,re.M)
    runtime_sha=re.findall(r'^const FINISH25I_RUNTIME_SHA: String="([0-9a-f]{64})"$',ctext,re.M)
    assert len(runtime)==len(runtime_sha)==1
    spec["finish_runtime"]={"path":runtime[0],"sha256":runtime_sha[0]};deps[runtime[0]]=runtime_sha[0]
    for row in spec["cases"]:assert row["expected_sources"][runtime[0]]==runtime_sha[0]
    for path,pin in deps.items():read(path,pin)
    deps.update({PREFIX+name:pin for name,pin in PINS.items()})
    deps.update({args.stage:args.stage_sha.lower(),args.deployment:args.deployment_sha.lower()})
    spec.update(ready=True,formal_deployed=True,status="ROOT_ACTUAL_LOCAL_FIX_TWO_VIEW_ONLY",dependencies=deps,formal_stage={"path":args.stage,"sha256":args.stage_sha.lower()},formal_deployment={"path":args.deployment,"sha256":args.deployment_sha.lower()})
    fixture=enc(spec);back=json.loads(fixture);original=json.loads(old["view_fixture_NOTREADY.json"])
    for key in ["formal_stage","formal_deployment"]:del back[key]
    for key in ["ready","formal_deployed","status","dependencies","finish_runtime"]:back[key]=original[key]
    for row in back["cases"]:row["expected_sources"]={}
    assert enc(back)==old["view_fixture_NOTREADY.json"]
    bootstrap=old["view_bootstrap_NOTREADY.gd"]
    edits=[(b"const READY := false",b"const READY := true"),((PREFIX+"view_fixture_NOTREADY.json").encode(),(PREFIX+"VIEW_ROOT_READY01/fixture_ROOT_READY.json").encode()),(b"PENDING_ROOT_FINAL_SOURCE_HEAD",sha(fixture).encode())]
    for before,after in edits:assert bootstrap.count(before)==1;bootstrap=bootstrap.replace(before,after)
    inverse=bootstrap
    for before,after in reversed(edits):assert inverse.count(after)==1;inverse=inverse.replace(after,before)
    assert inverse==old["view_bootstrap_NOTREADY.gd"]
    out={"fixture_ROOT_READY.json":fixture,"bootstrap_ROOT_READY.gd":bootstrap}
    proof={"status":"MECHANICAL_ROOT_ONLY_NO_ENGINE","whole_fixture_inverse":True,"whole_bootstrap_inverse":True,"worker_unchanged":PINS["view_worker_NOTREADY.gd"],"expected_sources_from_fixed_Stage_not_observed_gameplay":True,"outputs":{name:{"sha256":sha(data),"bytes":len(data)} for name,data in out.items()}}
    dest=BASE/"VIEW_ROOT_READY01";assert not dest.exists(),"NEW_DEST_ONLY";dest.mkdir()
    for name,data in out.items():
        with (dest/name).open("xb") as file:file.write(data)
    with (dest/"mechanical_whole_inverse.json").open("xb") as file:file.write(enc(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__":main()
