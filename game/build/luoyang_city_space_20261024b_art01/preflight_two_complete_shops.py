"""Offline prompt renderer only: no client, network, generation, or pixel processing."""
import hashlib
import importlib.util
import json
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("project_asset_prompt_renderer", ROOT / "scripts/gen_assets.py")
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)
doc = yaml.safe_load((ROOT / "prompts/tasks.yaml").read_text(encoding="utf-8"))
ids = ["luoyang_20261024b_complete_apothecary_v1", "luoyang_20261024b_complete_bookshop_v1"]
results = []
for task_id in ids:
    matches = [row for row in doc["tasks"] if row["id"] == task_id]
    assert len(matches) == 1
    row = matches[0]
    prompt_path = ROOT / row["prompt_path"]
    prompt = prompt_path.read_text(encoding="utf-8").strip()
    assert row["skip"] and row["attempt_budget"] == 1 and row["reference_images"] == []
    assert row["execution_backend"] == "builtin_image_gen" and not row["cli_fallback_allowed"]
    rendered = renderer.render_template(row["template"], {**row["vars"], "asset_prompt": prompt}, {})
    assert rendered["prompt"] == prompt and rendered["reference_images"] == []
    assert rendered["background"] == "transparent"
    results.append({"id": task_id, "prompt_path": str(prompt_path), "prompt_sha256": hashlib.sha256(prompt_path.read_bytes()).hexdigest(), "references": 0, "transparent": True, "skip": True, "attempt_budget": 1, "exact_prompt_file_rendered": True})
print(json.dumps({"status": "OFFLINE_RENDER_DRY_RUN_PASS", "network_calls": 0, "engine_runs": 0, "results": results}, indent=2))
