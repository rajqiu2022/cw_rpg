"""Read-only real project renderer check. No environment load, API or file writes."""
from pathlib import Path
import hashlib
import importlib.util
import json
import sys

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[3]
module_spec = importlib.util.spec_from_file_location("project_image_renderer_readonly", root / "scripts/gen_assets.py")
renderer = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(renderer)
task_id = "luoyang_saloon_peony_rug_20261101b_v1"
tasks = renderer.load_yaml(root / "prompts/tasks.yaml")["tasks"]
rows = [task for task in tasks if task["id"] == task_id]
assert len(rows) == 1, "One exact registered task"
task = rows[0]
assert task["skip"] is True and task["execution_backend"] == "builtin_image_gen"
assert task["attempt_budget"] == 1 and task["cli_fallback_allowed"] is False
assert task["model"] is None and task["provider"] is None and task["cost"] is None
spec = renderer.render_template(task["template"], task["vars"], renderer.load_yaml(renderer.SHARED_FILE))
prompt = root / task["prompt_path"]
assert spec["prompt"] == prompt.read_text(encoding="utf-8").strip(), "Registered renderer prompt is exact standalone prompt"
assert spec["background"] == "transparent" and spec["size"] == "1536x1024"
assert len(spec["reference_images"]) == 1 and spec["reference_images"][0].is_file()
print(json.dumps({
    "passed": True, "task": task_id, "real_project_renderer": True,
    "prompt": str(prompt), "prompt_sha256": hashlib.sha256(prompt.read_bytes()).hexdigest(),
    "prompt_characters": len(spec["prompt"]), "reference_images": [str(path) for path in spec["reference_images"]],
    "requested_size_not_a_builtin_tool_parameter": spec["size"],
    "transparent_background": True, "network_calls": 0, "engine_calls": 0, "file_writes": 0,
    "root_builtin_generation_still_pending": True,
}, ensure_ascii=False, indent=2))
