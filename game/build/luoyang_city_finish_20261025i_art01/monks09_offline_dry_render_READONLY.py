"""Offline public-template render and exact append-only registration preflight.

No API, no image generation, no file writes, no Godot. Output is JSON to stdout.
Root owns actual prompts/tasks.yaml application and all generation.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
EXPECTED_TASKS = "1d337a0c8f9b220f0d36cf7ff87e50159d59f468bc0f39c4a3f6927f3de976b7"

def sha(blob):
    return hashlib.sha256(blob).hexdigest()

renderer_path = ROOT / "scripts/gen_assets.py"
spec = importlib.util.spec_from_file_location("monks09_existing_public_renderer", renderer_path)
module = importlib.util.module_from_spec(spec)
sys.path.insert(0, str(ROOT / "scripts"))
spec.loader.exec_module(module)
import yaml

old_bytes = (ROOT / "prompts/tasks.yaml").read_bytes()
assert sha(old_bytes) == EXPECTED_TASKS, "Fixed parent tasks changed; stop, do not rebase silently"
old = yaml.safe_load(old_bytes)
candidate_path = ROOT / "prompts/luoyang_city_finish_20261025i/monks_three_tasks09_CANDIDATE.yaml"
candidate_bytes = candidate_path.read_bytes()
candidate = yaml.safe_load(candidate_bytes)
new_tasks = candidate["tasks"]
assert len(new_tasks) == 3
old_ids = {t["id"] for t in old["tasks"]}
assert not any(t["id"] in old_ids for t in new_tasks)
legacy_i = [t for t in old["tasks"] if t["id"].startswith("luoyang_20261025i_")]
assert len(legacy_i) == 11
suffix = "\n" + candidate_bytes.decode("utf-8").split("\n", 1)[1]
after_bytes = old_bytes + suffix.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8")
after = yaml.safe_load(after_bytes)
assert after_bytes[:len(old_bytes)] == old_bytes
assert after["tasks"] == old["tasks"] + new_tasks
assert [t for t in after["tasks"] if t["id"] in {x["id"] for x in legacy_i}] == legacy_i

shared = module.load_yaml(module.SHARED_FILE)
renders = []
for task in new_tasks:
    prompt_path = ROOT / task["prompt_path"]
    prompt_bytes = prompt_path.read_bytes()
    if not task["generation_ready"]:
        assert task["bound_edit_input"] is None and task["reference_images"] == []
        renders.append({"id":task["id"], "status":"BLOCKED_NOT_RENDERED_OR_CALLED_WAIT_ACTUAL_SPRITE", "prompt_sha256":sha(prompt_bytes), "builtin_args":None})
        continue
    rendered = module.render_template(task["template"], {"asset_prompt":prompt_bytes.decode("utf-8")}, shared)
    assert rendered["prompt"] == prompt_bytes.decode("utf-8").strip()
    args = {"prompt":rendered["prompt"], "transparent_background":task["transparent_background"]}
    refs = []
    if task["reference_images"]:
        for name in task["reference_images"]:
            path = ROOT / name
            assert path.is_file()
            digest = sha(path.read_bytes())
            assert digest == "6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad"
            refs.append({"path":str(path), "sha256":digest})
        args["referenced_image_paths"] = [row["path"] for row in refs]
    assert "num_last_images_to_include" not in args
    renders.append({"id":task["id"], "status":"ACTUAL_OFFLINE_PUBLIC_RENDER_TEMPLATE_PASS_NO_GENERATION", "prompt_path":task["prompt_path"], "prompt_sha256":sha(prompt_bytes), "rendered_prompt_sha256":sha(rendered["prompt"].encode("utf-8")), "template":task["template"], "template_sha256":sha((module.TEMPLATES_DIR / (task["template"]+".yaml")).read_bytes()), "size_intent_not_builtin_argument":rendered["size"], "background_intent":rendered["background"], "task_level_inputs":refs, "builtin_arg_keys":list(args), "builtin_args":args})
assert sha((ROOT / "prompts/tasks.yaml").read_bytes()) == EXPECTED_TASKS
print(json.dumps({"status":"OFFLINE_RENDER_AND_APPEND_ONLY_PREFLIGHT_PASS_NOT_REGISTERED", "parent_tasks_sha256":EXPECTED_TASKS, "parent_bytes":len(old_bytes), "root_tasks_changed":False, "legacy25i_tasks_retained":11, "new_task_count":3, "all_other_old_tasks_byte_prefix_and_semantics_unchanged":True, "candidate_tasks_sha256":sha(candidate_bytes), "predicted_exact_CRLF_append_sha256":sha(after_bytes), "candidate_after_bytes":len(after_bytes), "renderer_sha256":sha(renderer_path.read_bytes()), "shared_sha256":sha(module.SHARED_FILE.read_bytes()), "renders":renders, "model":None, "provider":None, "cost":None, "network_calls":0, "generation_calls":0, "engine_calls":0, "PNG_writes":0}, ensure_ascii=False, indent=2))
