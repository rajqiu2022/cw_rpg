"""Before generation, bind the planned vendor to the actual existing male portrait."""
import json,shutil,yaml
import world_expansion_100_20261022 as b

ledger=json.loads(b.LEDGER.read_text("utf-8"))
before=b.ROOT/"tmp/world_expansion_100_20261022/vendor_identity_before"
assert not before.exists();before.mkdir()
shutil.copyfile(b.LEDGER,before/"manifest.json")
shutil.copyfile(b.ROOT/"prompts/tasks.yaml",before/"tasks.yaml")
new_defs={r["id"]:r for r in b.definitions()}
affected=[]
for r in ledger["assets"]:
    if r["id"] not in [b.PREFIX+"npc_linxi_vendor_idle_1f_v1",b.PREFIX+"npc_linxi_vendor_portrait_v1"]:continue
    assert r["attempts"]==0 and not (b.ROOT/r["output"]).exists()
    shutil.copyfile(b.ROOT/r["prompt_path"],before/(r["id"]+".txt"))
    r["detail"]=new_defs[r["id"]]["detail"];r["reference"]=new_defs[r["id"]]["reference"]
    (b.ROOT/r["prompt_path"]).write_text(b.prompt(r)+"\n","utf-8");affected.append(r["id"])
ref="game/art/characters/npc_vendor_neutral.png"
ledger["source_sha256"][ref]=b.digest(b.ROOT/ref)
raw=(b.ROOT/"prompts/tasks.yaml").read_bytes();prefix=raw[:ledger["old_tasks_bytes"]]
alltasks=yaml.safe_load(raw)["tasks"];tasks=[r for r in alltasks if r["id"].startswith(b.PREFIX)]
assert len(tasks)==100
for task in tasks:
    if task["id"] in affected:task["vars"]["asset_prompt"]=b.prompt(next(r for r in ledger["assets"] if r["id"]==task["id"]))
fragment=yaml.safe_dump({"tasks":tasks},allow_unicode=True,sort_keys=False,width=140).split("tasks:\n",1)[1]
suffix=("\n  # User-authorized 100 asset expansion; builtin-only, protected from CLI re-execution.\n"+"\n".join("  "+line if line else "" for line in fragment.splitlines())+"\n").encode()
(b.ROOT/"prompts/tasks.yaml").write_bytes(prefix+suffix)
assert (b.ROOT/"prompts/tasks.yaml").read_bytes()[:len(prefix)]==(before/"tasks.yaml").read_bytes()[:len(prefix)]
b.LEDGER.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+"\n","utf-8")
report={"status":"PRE_GENERATION_VENDOR_IDENTITY_SUCCESSOR_PASS","affected":affected,"reason":"Existing vendor portrait was inspected and depicts an adult male. Corrected planned female draft before any vendor image call; bind original male identity and clothing.","reference":ref,"reference_sha256":ledger["source_sha256"][ref],"source_files_now":len(ledger["source_sha256"]),"original_preflight_retained":True,"vendor_generation_calls_before_change":0,"old_tasks_prefix_exact":True}
(b.BASE/"preflight_vendor_identity_successor.json").write_text(json.dumps(report,indent=2)+"\n","utf-8")
print(json.dumps(report))
