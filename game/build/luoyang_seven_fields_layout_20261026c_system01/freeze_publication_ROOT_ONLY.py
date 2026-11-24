"""Root-only mechanical transport of the reviewed seven-field publisher. No engine."""
import hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
PREFIX="res://build/luoyang_seven_fields_layout_20261026c_system01/"
PINS={"publish_seven_fields_NOTREADY.gd":"09b7fe30da7ccb990c04781e6f5d5dd4bee527aede90117a3e14987beab1de4c","input_NOTREADY.json":"4d2ce2a63909152bb2b2c2866bf5dc3422fc7c3c5ce61913495e38eb1d13dd17","project.godot":"1968e50e894e2ca074725b9b305afd12bf2af6211971593e72d2f15e7a45ec89"}
PERMISSION="res://build/luoyang_city_finish_20261025i_source01/finish8_ROOT_TRIAL_PERMISSION05.json"
PERMISSION_SHA="772cff2bc2c3199df2026427dd3f2bc7a022b9bb090a1bda7a9be46ed0d1b581"
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+"\n").encode()
def main():
    raw={n:(BASE/n).read_bytes() for n in PINS}
    assert all(sha(raw[n])==h for n,h in PINS.items())
    permit=(GAME/PERMISSION[6:]).read_bytes();assert sha(permit)==PERMISSION_SHA
    grant=json.loads(permit);assert grant["admitted"] is True and grant["permission_kind"]=="TRIAL_PERMISSION_NOT_RESULT"
    old=json.loads(raw["input_NOTREADY.json"]);new=json.loads(raw["input_NOTREADY.json"])
    new.update(ready=True,status="ROOT_READY_ONE_SEVEN_FIELD_PUBLICATION",output_root=PREFIX+"ROOT_READY01/output/",permission={"path":PERMISSION,"sha256":PERMISSION_SHA})
    new["sources"][PERMISSION]=PERMISSION_SHA
    data=enc(new);back=json.loads(data)
    for k in ["ready","status","output_root","permission"]:back[k]=old[k]
    del back["sources"][PERMISSION]
    assert enc(back)==raw["input_NOTREADY.json"]
    key=raw["publish_seven_fields_NOTREADY.gd"]
    changes=[(b"const READY: bool=false",b"const READY: bool=true"),((PREFIX+"input_NOTREADY.json").encode(),(PREFIX+"ROOT_READY01/input_ROOT_READY.json").encode()),(b"PENDING_FINAL_ART_AUTHOR",sha(data).encode())]
    for a,b in changes:assert key.count(a)==1;key=key.replace(a,b)
    inverse=key
    for a,b in reversed(changes):assert inverse.count(b)==1;inverse=inverse.replace(b,a)
    assert inverse==raw["publish_seven_fields_NOTREADY.gd"]
    dest=BASE/"ROOT_READY01";assert not dest.exists()
    outputs={"input_ROOT_READY.json":data,"publish_ROOT_READY.gd":key,"project.godot":raw["project.godot"]}
    proof={"status":"MECHANICAL_ROOT_READY_TRANSPORT_ONLY_NO_ENGINE","parent_pins":PINS,"permission":{"path":PERMISSION,"sha256":PERMISSION_SHA},"whole_input_inverse":True,"whole_key_inverse":True,"all_business_functions_unchanged":True,"outputs":{n:{"sha256":sha(b),"bytes":len(b)} for n,b in outputs.items()}}
    dest.mkdir()
    for n,b in outputs.items():
        with (dest/n).open("xb") as f:f.write(b)
    with (dest/"mechanical_whole_inverse.json").open("xb") as f:f.write(enc(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__":main()
