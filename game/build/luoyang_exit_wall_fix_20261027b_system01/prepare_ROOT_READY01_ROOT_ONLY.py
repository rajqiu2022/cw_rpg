"""Root-only three-file READY transport. No engine, import or canonical write."""
import hashlib,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
PREFIX="res://build/luoyang_exit_wall_fix_20261027b_system01/"
PINS={"publish_local_NOTREADY.gd":"fa877c127b54617d1d4fd0a1a4800ce590406ab4a20a2d05ceee0857f6747718","input_NOTREADY.json":"fd5069204b51595e7c0f5ca8f6a8459539e27dd85fac07ffe8bada45bf836848","project.godot":"66398af0750efcdc2661e0fdee29e3f079f5d459a461fe30ff11c5ce202057dd"}
def sha(data):return hashlib.sha256(data).hexdigest()
def enc(value):return (json.dumps(value,ensure_ascii=False,indent=2)+"\n").encode()
def main():
    old={name:(BASE/name).read_bytes() for name in PINS}
    assert all(sha(old[name])==pin for name,pin in PINS.items())
    original=json.loads(old["input_NOTREADY.json"]);spec=dict(original)
    assert spec["ready"] is False and spec["scope"]=="TWO_PORTALS_TWO_WALL_DOMAINS_ONLY"
    spec.update(ready=True,status="ROOT_REVIEWED_UNIQUE_LOCAL_CPU_NOT_FIELD_OR_ART_PASS")
    data=enc(spec);back=json.loads(data)
    for key in ["ready","status"]:back[key]=original[key]
    assert enc(back)==old["input_NOTREADY.json"]
    script=old["publish_local_NOTREADY.gd"]
    edits=[(b"const READY: bool=false",b"const READY: bool=true"),((PREFIX+"input_NOTREADY.json").encode(),(PREFIX+"ROOT_READY01/input_ROOT_READY.json").encode()),(b"PENDING_ROOT_REVIEW_INPUT",sha(data).encode())]
    for before,after in edits:
        assert script.count(before)==1
        script=script.replace(before,after)
    inverse=script
    for before,after in reversed(edits):
        assert inverse.count(after)==1
        inverse=inverse.replace(after,before)
    assert inverse==old["publish_local_NOTREADY.gd"]
    outputs={"input_ROOT_READY.json":data,"publish_ROOT_READY.gd":script,"project.godot":old["project.godot"]}
    proof={"status":"ROOT_ONLY_MECHANICAL_READY_NO_ENGINE","parent":PINS,"publisher_full_byte_inverse":True,"input_full_byte_inverse":True,"project_exact_copy":True,"functions_unchanged":True,"engine":False,"canonical_write":False,"outputs":{name:{"sha256":sha(raw),"bytes":len(raw)} for name,raw in outputs.items()}}
    dest=BASE/"ROOT_READY01";assert not dest.exists(),"NEW_DEST_ONLY";dest.mkdir()
    for name,raw in outputs.items():
        with (dest/name).open("xb") as file:file.write(raw)
    with (dest/"mechanical_whole_inverse.json").open("xb") as file:file.write(enc(proof))
    print(json.dumps(proof,ensure_ascii=False))
if __name__=="__main__":main()
