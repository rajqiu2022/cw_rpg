"""Local prompt-only rendering through the established renderer; no API invocation."""
import importlib.util
import json
from pathlib import Path

root = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("project_asset_renderer", root / "scripts/gen_assets.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
base = root / "assets/staging/world_bridges_20261030m/production"
module.TEMPLATES_DIR = base / "templates"
tasks = module.load_yaml(base / "prompts/tasks.yaml")["tasks"]
out = Path(__file__).resolve().parent / "rendered_prompts"
out.mkdir(parents=True, exist_ok=True)
for task in tasks:
    rendered = module.render_template(task["template"], task["vars"], {})
    assert len(rendered["reference_images"]) == {"short_stone_bridge": 1, "short_broad_stone_bridge": 0, "short_bridge_transparency": 1}.get(task["template"], 3)
    assert "{" not in rendered["prompt"]
    (out / (task["id"] + ".txt")).write_text(rendered["prompt"], encoding="utf-8")
    rendered["reference_images"] = [str(p) for p in rendered["reference_images"]]
    (out / (task["id"] + ".json")).write_text(json.dumps(rendered, indent=2), encoding="utf-8")
print(json.dumps({"dry_run": True, "tasks": len(tasks), "api_calls": 0, "backend": "builtin_image_gen"}))
