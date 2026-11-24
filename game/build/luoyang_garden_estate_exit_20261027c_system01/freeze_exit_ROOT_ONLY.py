"""Root-only transport from actual fixed Stage/deployment; no engine or source discovery."""
import argparse,hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PREFIX="res://build/luoyang_garden_estate_exit_20261027c_system01/"
PINS={"exit_worker_NOTREADY.gd":"3a864a635b85d92540ef2af5c2b7075b6e91621c8dc3f476e234b9ffda95baed","exit_fixture_NOTREADY.json":"60576b2149a41c998315ef2382d67c7cd7f826edc744671667ce12312611c66b","exit_bootstrap_NOTREADY.gd":"419f2ac965701699c6735553112aa238fbf8961e41b64b4e13b342932f5aabf4"}
FIXED={"res://build/luoyang_seven_fields_layout_20261026c_system01/smoke_seven_worker_NOTREADY.gd":"8c20dcab4ac645ba4be40c59a3bc65aa797fefd7ea57a814e179b7acc71c8349","res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd":"3367c98096f8e3f66e629ca8de0c3fd589c79ebf6df02c3bee0e7206363c31ca","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",PREFIX+"ROOT_READY01/output/109852/result.json":"332d92f1006bbea55fd10c95bd7ae0cf1c61ca5cc6815d9da53b42d423cbf5cd"}
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
    deps=dict(FIXED);spec=json.loads(old["exit_fixture_NOTREADY.json"])
    assert spec["whole_ms"]==60000 and spec["entry_ms"]==20000 and spec["max_pictures"]==2
    for key in ["expected_Family_sources","expected_Estate_sources"]:
        node=stage["nodes"][key];value=json.loads(read(node["path"],node["sha256"]))
        assert value==node["value"] and isinstance(value["source_sha256"],dict) and value["source_sha256"]
        spec[key]=value["source_sha256"];deps[node["path"]]=node["sha256"].lower()
    for path in ["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/city/luoyang_quarters_family_20261022ap.gd","res://scripts/city/luoyang_estate_family_20261021am.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/autoload/scene_router.gd"]:
        deps[path]=declared[path].lower()
        for key in ["expected_Family_sources","expected_Estate_sources"]:
            if path in spec[key]:assert spec[key][path].lower()==deps[path]
    for path,pin in deps.items():read(path,pin)
    deps.update({PREFIX+name:pin for name,pin in PINS.items()})
    deps.update({args.stage:args.stage_sha.lower(),args.deployment:args.deployment_sha.lower()})
    spec.update(ready=True,formal_deployed=True,status="ROOT_ACTUAL_ONE_COLD_GARDEN_ESTATE_SPACE",dependencies=deps,formal_stage={"path":args.stage,"sha256":args.stage_sha.lower()},formal_deployment={"path":args.deployment,"sha256":args.deployment_sha.lower()})
    fixture=enc(spec);back=json.loads(fixture);original=json.loads(old["exit_fixture_NOTREADY.json"])
    for key in ["formal_stage","formal_deployment"]:del back[key]
    for key in ["ready","formal_deployed","status","dependencies","expected_Family_sources","expected_Estate_sources"]:back[key]=original[key]
    assert enc(back)==old["exit_fixture_NOTREADY.json"]
    bootstrap=old["exit_bootstrap_NOTREADY.gd"]
    edits=[(b"const READY := false",b"const READY := true"),((PREFIX+"exit_fixture_NOTREADY.json").encode(),(PREFIX+"EXIT_ROOT_READY01/fixture_ROOT_READY.json").encode()),(b"PENDING_ROOT_FINAL_SOURCE_HEAD",sha(fixture).encode())]
    for before,after in edits:assert bootstrap.count(before)==1;bootstrap=bootstrap.replace(before,after)
    inverse=bootstrap
    for before,after in reversed(edits):assert inverse.count(after)==1;inverse=inverse.replace(after,before)
    assert inverse==old["exit_bootstrap_NOTREADY.gd"]
    out={"fixture_ROOT_READY.json":fixture,"bootstrap_ROOT_READY.gd":bootstrap}
    proof={"status":"MECHANICAL_ROOT_ONLY_NO_ENGINE","whole_fixture_inverse":True,"whole_bootstrap_inverse":True,"worker_unchanged":PINS["exit_worker_NOTREADY.gd"],"expected_sources_from_fixed_Stage_not_observed_gameplay":True,"outputs":{name:{"sha256":sha(data),"bytes":len(data)} for name,data in out.items()}}
    dest=BASE/"EXIT_ROOT_READY01";assert not dest.exists(),"NEW_DEST_ONLY";dest.mkdir()
    for name,data in out.items():
        with (dest/name).open("xb") as stream:stream.write(data)
    with (dest/"mechanical_whole_inverse.json").open("xb") as stream:stream.write(enc(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__":main()
