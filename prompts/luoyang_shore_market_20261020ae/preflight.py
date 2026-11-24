from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROMPT_DIR = Path(__file__).resolve().parent
MANIFEST_PATH = PROMPT_DIR / "proposed_generation_manifest.json"
TASKS_PATH = ROOT / "prompts" / "tasks.yaml"
OUTPUT_PATH = PROMPT_DIR / "preflight.actual.json"

TASK_IDS = [
    "luoyang_shore_market_20261020ae_wet_stone_shore_vertical_v1",
    "luoyang_shore_market_20261020ae_cart_ruts_horizontal_v1",
    "luoyang_shore_market_20261020ae_mooring_bollard_rope_right_v1",
]

SOURCE_PINS = {
    "game/build/luoyang_docks08_formal_field_20261019ab/113316/ordinary_docks08_default_after32px.png":
        "F85A85E460256E7F48E4A59059EBA4123C4745F6ABBA4E8E6BCBACC782822B67",
    "game/art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/entities/dry_loading_wharf.png":
        "14838181D1C59E0545D919876E2A01603E32B559320BEB6876DF8E7726C3AD4E",
    "game/art/maps/luoyang_harbour_life_20261016/cargo_ship_v1.png":
        "D3CFD7F962D6F28EBAB88CE1CB69D757E3ED7D4E491C34704B804C655B6A7EE8",
    "game/art/maps/luoyang_harbour_life_20261016/covered_ferry_v1.png":
        "D67140A7AFA0FDFFFFF97DE9E34A0680B0069FC9DBD05BBCF85FB7E4EF989357",
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def task_block(tasks_text: str, task_id: str) -> str:
    marker = f"  - id: {task_id}"
    start = tasks_text.find(marker)
    if start < 0:
        return ""
    next_start = tasks_text.find("\n  - id: ", start + len(marker))
    return tasks_text[start:] if next_start < 0 else tasks_text[start:next_start]


checks: list[dict[str, object]] = []


def check(name: str, ok: bool, detail: object) -> None:
    checks.append({"name": name, "passed": bool(ok), "detail": detail})


manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
tasks_text = TASKS_PATH.read_text(encoding="utf-8")

check("manifest_exact_three_tasks", len(manifest.get("tasks", [])) == 3, len(manifest.get("tasks", [])))
check("manifest_task_ids_exact", [row.get("id") for row in manifest["tasks"]] == TASK_IDS,
      [row.get("id") for row in manifest["tasks"]])
check("manifest_budget_and_no_fallback",
      manifest.get("maximum_calls") == 3
      and manifest.get("currently_callable_calls") == 2
      and manifest.get("calls_used") == 0
      and manifest.get("calls_per_asset") == 1
      and manifest.get("automatic_retry") is False
      and manifest.get("cli_network_or_paid_fallback") is False,
      {key: manifest.get(key) for key in (
          "maximum_calls", "currently_callable_calls", "calls_used", "calls_per_asset", "automatic_retry",
          "cli_network_or_paid_fallback")})
check("manifest_registered_ready",
      manifest.get("tasks_yaml_registered") is True
      and manifest.get("status") == "PREFLIGHT_TWO_CALLABLE_ONE_GEOMETRY_PENDING_NOT_GENERATED",
      {"tasks_yaml_registered": manifest.get("tasks_yaml_registered"), "status": manifest.get("status")})

task_rows: list[dict[str, object]] = []
for row in manifest["tasks"]:
    task_id = row["id"]
    block = task_block(tasks_text, task_id)
    prompt_path = ROOT / row["prompt"]
    spec_path = ROOT / row["spec"]
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    prompt_hash = sha256(prompt_path)
    spec_hash = sha256(spec_path)
    is_mooring = task_id.endswith("mooring_bollard_rope_right_v1")
    expected_status = (
        "PREFLIGHT_SOURCE_READY_GEOMETRY_PENDING_NOT_CALLABLE_NOT_GENERATED"
        if is_mooring else "PREFLIGHT_SOURCE_READY_NOT_GENERATED"
    )
    output_path = ROOT / spec["proposed_output_path"]
    metadata_path = output_path.with_suffix(".meta.json")

    check(f"{task_id}:unique_tasks_yaml_id", tasks_text.count(f"id: {task_id}") == 1,
          tasks_text.count(f"id: {task_id}"))
    required_lines = [
        "execution_backend: builtin_image_gen",
        "execution_mode: generate",
        "model: null",
        "provider: null",
        "cost: null",
        "transparent_background: true",
        f"status: {expected_status}",
        "attempts_used: 0",
        "attempt_budget: 1",
        "retries_allowed: false",
        "cli_fallback_allowed: false",
        f"prompt_path: {row['prompt']}",
        f"spec_path: {row['spec']}",
        "skip: true",
    ]
    missing_lines = [line for line in required_lines if line not in block]
    check(f"{task_id}:tasks_yaml_contract", bool(block) and not missing_lines, missing_lines)
    check(f"{task_id}:spec_ready_not_called",
          spec.get("status") == expected_status
          and spec.get("execution_backend") == "builtin_image_gen"
          and spec.get("execution_mode") == "generate"
          and spec.get("model") is None
          and spec.get("provider") is None
          and spec.get("cost") is None
          and spec.get("transparent_background") is True
          and spec.get("attempt_budget") == 1
          and spec.get("attempts_used") == 0
          and spec.get("automatic_retry") is False
          and spec.get("cli_network_or_paid_fallback") is False,
          {key: spec.get(key) for key in (
              "status", "execution_backend", "execution_mode", "model", "provider", "cost",
              "transparent_background", "attempt_budget", "attempts_used", "automatic_retry",
              "cli_network_or_paid_fallback")})
    check(f"{task_id}:prompt_sha", prompt_hash == row["prompt_sha256"], prompt_hash)
    check(f"{task_id}:spec_sha", spec_hash == row["spec_sha256"], spec_hash)
    check(f"{task_id}:output_absent", not output_path.exists() and not metadata_path.exists(),
          {"png_exists": output_path.exists(), "metadata_exists": metadata_path.exists()})
    check(f"{task_id}:callability_matches_manifest",
          row.get("callable_now") is (not is_mooring), row.get("callable_now"))
    if is_mooring:
        check(f"{task_id}:geometry_gate_present",
              "actual existing rail/mask aabb" in spec.get("call_gate", "").lower()
              and "no new or widened solid/nav" in row.get("blocked_by", "").lower(),
              {"call_gate": spec.get("call_gate"), "blocked_by": row.get("blocked_by")})
    task_rows.append({
        "id": task_id,
        "prompt": row["prompt"],
        "prompt_sha256": prompt_hash,
        "spec": row["spec"],
        "spec_sha256": spec_hash,
        "proposed_output": spec["proposed_output_path"],
        "output_exists": output_path.exists(),
        "metadata_exists": metadata_path.exists(),
    })

wet = (PROMPT_DIR / "decal_docks_wet_stone_shore_vertical_v1.txt").read_text(encoding="utf-8").lower()
ruts = (PROMPT_DIR / "decal_docks_cart_ruts_horizontal_v1.txt").read_text(encoding="utf-8").lower()
moor = (PROMPT_DIR / "prop_docks_mooring_bollard_rope_right_v1.txt").read_text(encoding="utf-8").lower()
check("wet_prompt_direction_and_slim_shape",
      all(token in wet for token in ("long right edge", "wettest", "leftward", "1:10", "no broad stone floor rectangle")),
      "right edge wettest; leftward dry fade; 1:10; no broad floor rectangle")
check("wet_prompt_preserves_weak_alpha_margin", "weak-alpha moisture fringe" in wet,
      "weak-alpha moisture fringe retained inside margin")
check("ruts_prompt_pair_and_no_plaza_slab",
      all(token in ruts for token in ("two long parallel wheel paths", "no cart", "road slab", "full paving rectangle")),
      "paired parallel ruts only; no cart or road/plaza slab")
check("mooring_prompt_horizontal_low_rightward",
      all(token in moor for token in (
          "low horizontal timber mooring block", "rope coil", "extends to the right", "boat is to the right",
          "65-80 pixels high", "already blocked quay-rail band")),
      "horizontal timber block, coil, rightward long rope, boat right, 65-80px, blocked rail band")
check("mooring_prompt_excludes_wrong_forms",
      all(token in moor for token in ("no boat", "tall modern harbour post", "complete dock structure")),
      "no whole boat/dock or modern tall post")

source_rows: list[dict[str, object]] = []
for relative, expected_hash in SOURCE_PINS.items():
    path = ROOT / relative
    actual_hash = sha256(path) if path.is_file() else None
    check(f"source_pin:{relative}", actual_hash == expected_hash, actual_hash)
    source_rows.append({"path": relative, "sha256": actual_hash, "expected_sha256": expected_hash})

passed = all(bool(row["passed"]) for row in checks)
report = {
    "schema": "luoyang_shore_market_20261020ae_offline_generation_preflight_v1",
    "passed": passed,
    "scope": "exactly three registered Root-only builtin candidates; wet shore and ruts callable, mooring geometry-blocked; no calls",
    "manifest": str(MANIFEST_PATH.relative_to(ROOT)).replace("\\", "/"),
    "manifest_sha256": sha256(MANIFEST_PATH),
    "tasks_yaml": str(TASKS_PATH.relative_to(ROOT)).replace("\\", "/"),
    "tasks_yaml_sha256": sha256(TASKS_PATH),
    "calls_made": {"generation": 0, "network": 0, "engine": 0, "sdk": 0},
    "tasks": task_rows,
    "source_pins": source_rows,
    "checks": checks,
    "credit_boundary": "Offline registration/preflight only. No output asset, import, placement, Field proof or formal admission.",
}
OUTPUT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"passed": passed, "checks": len(checks), "failed": [row["name"] for row in checks if not row["passed"]]}, ensure_ascii=False))
raise SystemExit(0 if passed else 1)
