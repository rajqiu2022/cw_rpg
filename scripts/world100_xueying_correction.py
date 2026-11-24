"""One separately registered bounded correction; never mutate active main ledger."""
import argparse,json,hashlib,shutil,yaml
from pathlib import Path
from PIL import Image
import world_expansion_100_20261022 as b
ID="world100_20261022_boss_xueying_unarmed_v2"
PROMPT="""Use case: precise-object-edit, identity-preserve.
Edit target: the supplied existing Xueying full-body battle image. Correct ONLY the erroneous long sword: REMOVE the entire long sword and hilt from his hand, and make that hand an empty relaxed unarmed ready hand. There must be NO carried sword, saber, staff or visible hand weapon. Xueying is an unarmed assassin.
Preserve the same young lean male face, short cropped black hair, black layered clothes, belt and small needle cases, gloves, boots, body proportions, stance, camera, lighting and painting style. Do not redesign, age, unmask, replace clothes or add gear. Keep complete head, both hands and feet in frame; retain generous empty transparent padding.
One single static ready character, facing screen-left, on genuinely transparent RGBA. No background scenery, floor, fog, shadow disk, glow, text, border, extra limbs or objects. Preserve existing transparency. Original file remains unchanged; output a new sibling version."""
BASE=b.BASE
OUT=BASE/"story_bosses/story_boss"/(ID+".png")
PLAN=BASE/"xueying_correction_plan.json"

def prepare():
    assert not PLAN.exists()
    m=json.loads(b.LEDGER.read_text("utf-8"));parent=next(r for r in m["assets"] if r["id"]==b.PREFIX+"boss_ch8_xueying_last_guard_v1")
    assert b.digest(b.ROOT/parent["output"])==parent["sha256"]
    prompt=b.PROMPTS/(ID+".txt");prompt.write_text(PROMPT+"\n","utf-8")
    task={"id":ID,"template":"world_expansion_100_20261022","category":"world_expansion_100_20261022/story_boss_correction","execution_backend":"builtin_image_gen","execution_mode":"identity_preserving_edit","skip":True,"attempt_budget":1,"retries_allowed":False,"cli_fallback_allowed":False,"transparent_background":True,"model":None,"provider":None,"cost":None,"prompt_path":prompt.relative_to(b.ROOT).as_posix(),"vars":{"asset_prompt":PROMPT}}
    path=b.ROOT/"prompts/tasks.yaml";old=path.read_bytes()
    backup=b.ROOT/"tmp/world_expansion_100_20261022/before_xueying_correction_tasks.yaml";assert not backup.exists();shutil.copyfile(path,backup)
    body=yaml.safe_dump({"tasks":[task]},allow_unicode=True,sort_keys=False,width=140).split("tasks:\n",1)[1]
    suffix=("\n  # Bounded correction for rejected Xueying sword; extra version, not an extra subject.\n"+"\n".join("  "+x if x else "" for x in body.splitlines())+"\n").encode()
    path.write_bytes(old+suffix);assert path.read_bytes()[:len(old)]==old
    data={"id":ID,"parent_id":parent["id"],"reference":parent["output"],"reference_sha256":parent["sha256"],"prompt_path":task["prompt_path"],"output":OUT.relative_to(b.ROOT).as_posix(),"reason":"Remove hallucinated long sword; existing canonical ready reference is unarmed.","status":"REGISTERED_PENDING_ONE_EDIT","main_manifest_not_mutated":True,"old_tasks_prefix_exact":True}
    PLAN.write_text(json.dumps(data,indent=2)+"\n","utf-8")
    print(json.dumps(data))

def record(source):
    plan=json.loads(PLAN.read_text("utf-8"));assert not OUT.exists()
    assert b.digest(b.ROOT/plan["reference"])==plan["reference_sha256"]
    shutil.copyfile(source,OUT)
    with Image.open(OUT) as im:
        a=im.getchannel("A");box=a.getbbox();w,h=im.size;margins=[box[0]/w,box[1]/h,(w-box[2])/w,(h-box[3])/h]
        metrics={"size":[w,h],"has_real_alpha":im.mode=="RGBA" and a.getextrema()[0]==0,"full_alpha_bbox":list(box),"margin_fractions":margins,"margin_10_percent_pass":min(margins)>=.1}
    receipt={**plan,"kind":"story_bosses","tier":"story_boss","city":"shared","species":"","label":"薛影剧情Boss·空手修正版","sources":["game/data/enemies/ch8_xueying_last_guard.tres"],"attempts":1,"source_path":str(source),"sha256":b.digest(OUT),"bytes":OUT.stat().st_size,"prompt_sha256":b.digest(b.ROOT/plan["prompt_path"]),"metrics":metrics,"model":None,"provider":None,"cost":None,"reference_input":{"path":plan["reference"],"sha256":plan["reference_sha256"],"role":"edit_target"},"status":"GENERATED_PENDING_VISUAL_REVIEW_NOT_RUNTIME"}
    OUT.with_suffix(".meta.json").write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n","utf-8")
    (BASE/"corrections.json").write_text(json.dumps({"assets":[receipt]},ensure_ascii=False,indent=2)+"\n","utf-8")
    print(json.dumps({"id":ID,"output":receipt["output"],"metrics":metrics}))

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["prepare","record"]);p.add_argument("--source");args=p.parse_args()
    prepare() if args.action=="prepare" else record(Path(args.source))
