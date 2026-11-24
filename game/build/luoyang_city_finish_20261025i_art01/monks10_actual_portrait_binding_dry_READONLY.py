"""One actual identity input; offline render only, no file writes or APIs."""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sha = lambda b: hashlib.sha256(b).hexdigest()
taskfile = ROOT / "prompts/tasks.yaml"
parent = taskfile.read_bytes()
assert sha(parent) == "7e01b7bb96f7d7ea10176724e3762a3e2087281c873810e53b6238bf24578833"
raw = ROOT / "assets/raw/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1.png"
assert sha(raw.read_bytes()) == "86cbb758e08e52c851abdd2714a5f7d7dddba88c9b07b74fa01c344de7b034d0"
path = ROOT / "scripts/gen_assets.py"
spec = importlib.util.spec_from_file_location("monks10_existing_renderer", path)
mod = importlib.util.module_from_spec(spec)
sys.path.insert(0, str(ROOT / "scripts"))
spec.loader.exec_module(mod)
import yaml
tasks = yaml.safe_load(parent)["tasks"]
task = next(t for t in tasks if t["id"] == "luoyang_20261025i_cave_keeper_elder_portrait_v1_edit")
assert task["generation_ready"] is False and task["bound_edit_input"] is None
assert task["reference_images"] == []
prompt_file = ROOT / task["prompt_path"]
prompt = prompt_file.read_text(encoding="utf-8")
assert sha(prompt_file.read_bytes()) == "94bb66d2790a6c9d6c32043002645e9ccf28635ce07ae109ee68e1e7af3cbff0"
render = mod.render_template(task["template"], {"asset_prompt":prompt}, mod.load_yaml(mod.SHARED_FILE))
assert render["prompt"] == prompt.strip()
args = {"prompt":render["prompt"], "referenced_image_paths":[str(raw)], "transparent_background":False}
assert "num_last_images_to_include" not in args
assert sha(taskfile.read_bytes()) == sha(parent)
print(json.dumps({"status":"ACTUAL_INPUT_PUBLIC_OFFLINE_RENDER_PASS_ROOT_TASK_PATCH_NOT_APPLIED", "parent_tasks_sha256":sha(parent), "prompt_sha256":sha(prompt_file.read_bytes()), "rendered_prompt_sha256":sha(render["prompt"].encode()), "input_path":str(raw), "input_sha256":sha(raw.read_bytes()), "builtin_args":args, "network_calls":0, "generation_calls":0, "file_writes":0, "model":None, "provider":None, "cost":None}, indent=2))
