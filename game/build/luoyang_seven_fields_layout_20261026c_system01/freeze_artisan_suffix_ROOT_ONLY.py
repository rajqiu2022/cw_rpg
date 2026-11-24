"""Root-only mechanical freeze of the unpassed Artisan suffix; same reviewed smoke worker."""
import argparse,hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PREFIX="res://build/luoyang_seven_fields_layout_20261026c_system01/"
PINS={"smoke_seven_worker_NOTREADY.gd":"8c20dcab4ac645ba4be40c59a3bc65aa797fefd7ea57a814e179b7acc71c8349","smoke_bootstrap_NOTREADY.gd":"2c9dd25d07d6fa2a99b1f2377de60c413a283bd501286a6155808216d50cb9e1","smoke_artisan_only_NOTREADY.json":"740ca11c43e35f20397e25dc5d919890213b6c485f5f27e02842717c3c234b2b"}
FIXED={"res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd":"3367c98096f8e3f66e629ca8de0c3fd589c79ebf6df02c3bee0e7206363c31ca","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","res://build/luoyang_city_finish_20261025i_source01/finish8_ROOT_TRIAL_PERMISSION05.json":"772cff2bc2c3199df2026427dd3f2bc7a022b9bb090a1bda7a9be46ed0d1b581",PREFIX+"author_two_routes_NOTREADY.json":"4ea72850b9dcee3ef5f446385f9381a8fe5f2a9eae5e319cfc4e4ca9a0ffdefa",PREFIX+"purpose_seven_fields_NOTREADY.json":"fca9653407812ff7c07ba19a9f60af8e16ef2e06ad6237d3f09bc4ef25701a93"}
def sha(data):return hashlib.sha256(data).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+"\n").encode()
def read(path,pin):
    assert path.startswith("res://")
    data=(GAME/path[6:]).read_bytes();assert sha(data)==pin.lower(),path;return data
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--stage",required=True);p.add_argument("--stage-sha",required=True)
    p.add_argument("--deployment",required=True);p.add_argument("--deployment-sha",required=True)
    args=p.parse_args()
    old={n:(BASE/n).read_bytes() for n in PINS};assert all(sha(old[n])==h for n,h in PINS.items())
    stage=json.loads(read(args.stage,args.stage_sha));deploy=json.loads(read(args.deployment,args.deployment_sha))
    assert stage["source_first"]==stage["source_final"] and deploy["passed"] is True
    assert deploy["stage"]=={"path":args.stage,"sha256":args.stage_sha.lower()}
    declared=dict(stage["source_final"])
    for row in stage["targets"]:declared[row["target"]]=row["candidate_sha256"]
    dependencies=dict(FIXED)
    for path in ["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/city/luoyang_environment_layer_20261022ap.gd","res://scripts/city/luoyang_assembled_interiors_20261016g.gd"]:
        assert path in declared,path
        dependencies[path]=declared[path]
    for path,h in dependencies.items():read(path,h)
    dependencies.update({PREFIX+n:h for n,h in PINS.items()})
    dependencies[args.stage]=args.stage_sha.lower();dependencies[args.deployment]=args.deployment_sha.lower()
    dest=BASE/"ARTISAN_SUFFIX_ROOT_READY";assert not dest.exists(),"NEW_ARTISAN_SUFFIX_DEST_ONLY"
    outputs={};proof={}
    for group in ["A"]:
        name="smoke_artisan_only_NOTREADY.json";spec=json.loads(old[name])
        assert spec["group"]==group and spec["whole_ms"]==60000 and spec["entry_ms"]==20000 and len(spec["cases"])==1 and spec["cases"][0]["scene_id"]=="luoyang_artisan_residential_20261022ap"
        spec.update(ready=True,formal_deployed=True,status="ROOT_ACTUAL_HEAD_ARTISAN_ONLY_UNPASSED_SUFFIX",dependencies=dependencies,formal_stage_actual={"path":args.stage,"sha256":args.stage_sha.lower()},Root_deployment_actual={"path":args.deployment,"sha256":args.deployment_sha.lower()})
        data=enc(spec);back=json.loads(data)
        del back["formal_stage_actual"];del back["Root_deployment_actual"]
        original=json.loads(old[name])
        for k in ["ready","formal_deployed","status","dependencies"]:back[k]=original[k]
        assert enc(back)==old[name]
        bootstrap=old["smoke_bootstrap_NOTREADY.gd"]
        edits=[(b"const READY := false",b"const READY := true"),((PREFIX+"smoke_group_NOTREADY.json").encode(),(PREFIX+"ARTISAN_SUFFIX_ROOT_READY/"+group+"/fixture_ROOT_READY.json").encode()),(b"PENDING_ROOT_FINAL_SOURCE_HEAD",sha(data).encode())]
        for a,b in edits:assert bootstrap.count(a)==1;bootstrap=bootstrap.replace(a,b)
        inverse=bootstrap
        for a,b in reversed(edits):assert inverse.count(b)==1;inverse=inverse.replace(b,a)
        assert inverse==old["smoke_bootstrap_NOTREADY.gd"]
        outputs[group+"/fixture_ROOT_READY.json"]=data;outputs[group+"/bootstrap_ROOT_READY.gd"]=bootstrap
        proof[group]={"whole_fixture_inverse":True,"whole_bootstrap_inverse":True,"cases":len(spec["cases"]),"worker_business_unchanged":PINS["smoke_seven_worker_NOTREADY.gd"]}
    proof.update(status="ARTISAN_ONLY_MECHANICAL_TRANSPORT_NO_ENGINE",source_expectations_from_fixed_stage_not_observed_gameplay=True,maximum_one_image=True,Root_only_engine=True,outputs={n:{"sha256":sha(b),"bytes":len(b)} for n,b in outputs.items()})
    dest.mkdir()
    for name,data in outputs.items():
        target=dest/name;target.parent.mkdir(exist_ok=True)
        with target.open("xb") as f:f.write(data)
    with (dest/"mechanical_whole_inverse.json").open("xb") as f:f.write(enc(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__":main()
