from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

import yaml


BASE_NAME = "luoyang_docks_roles_20261019ad"
TASK_SUFFIXES = [
    "strong_carrier_posepack_idle1_right4_v1",
    "store_attendant_idle_down_1f_v1",
    "rope_seller_idle_down_1f_v1",
]
TASK_IDS = [f"{BASE_NAME}_{suffix}" for suffix in TASK_SUFFIXES]
PROMPT_BASENAMES = [
    "npc_docks_strong_carrier_posepack_idle1_right4_v1",
    "npc_docks_store_attendant_idle_down_1f_v1",
    "npc_docks_rope_seller_idle_down_1f_v1",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    script_path = Path(__file__).resolve()
    repo = script_path.parents[2]
    base = script_path.parent
    tasks_path = repo / "prompts/tasks.yaml"
    manifest_path = base / "manifest.json"
    processor_path = base / "process_carrier_posepack.py"
    carrier_contract_path = repo / "game/build/luoyang_docks_roles_20261019ad_art01/generation_contract_priority_carrier_v2.json"
    static_contract_path = repo / "game/build/luoyang_docks_roles_20261019ad_art01/generation_contract.json"
    report_path = base / "preflight.actual.json"
    checks: list[dict[str, object]] = []

    def check(name: str, condition: bool, actual: object) -> None:
        checks.append({"name": name, "passed": bool(condition), "actual": actual})

    required = [tasks_path, manifest_path, processor_path, carrier_contract_path, static_contract_path, script_path]
    for name in PROMPT_BASENAMES:
        required.extend([base / f"{name}.txt", base / f"{name}.spec.json"])
    check("required_sources_exist", all(path.is_file() for path in required), [path.as_posix() for path in required if not path.is_file()])
    if not all(path.is_file() for path in required):
        payload = {"schema_version": 1, "passed": False, "checks": checks}
        report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 1

    tasks = yaml.safe_load(tasks_path.read_text(encoding="utf-8"))["tasks"]
    matching = [row for row in tasks if row.get("id") in TASK_IDS]
    by_id = {row.get("id"): row for row in matching}
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    carrier_contract = json.loads(carrier_contract_path.read_text(encoding="utf-8"))
    static_contract = json.loads(static_contract_path.read_text(encoding="utf-8"))
    specs = []
    prompts = []
    source_paths = required.copy()

    check("exactly_three_registered_tasks", len(matching) == len(by_id) == 3 and set(by_id) == set(TASK_IDS), [row.get("id") for row in matching])
    check("task_order_exact", [row.get("id") for row in matching] == TASK_IDS, [row.get("id") for row in matching])
    for task_id, basename in zip(TASK_IDS, PROMPT_BASENAMES):
        prompt_path = base / f"{basename}.txt"
        spec_path = base / f"{basename}.spec.json"
        prompt = prompt_path.read_text(encoding="utf-8").strip()
        spec = json.loads(spec_path.read_text(encoding="utf-8"))
        row = by_id.get(task_id, {})
        specs.append(spec)
        prompts.append(prompt)
        check(f"{basename}_id_and_paths", row.get("id") == spec.get("id") == task_id and row.get("prompt_path") == prompt_path.relative_to(repo).as_posix() and row.get("spec_path") == spec_path.relative_to(repo).as_posix(), {"row": row.get("id"), "spec": spec.get("id")})
        check(f"{basename}_builtin_unknown_metadata", row.get("execution_backend") == spec.get("execution_backend") == "builtin_image_gen" and row.get("execution_mode") == spec.get("execution_mode") == "generate" and all(value is None for value in [row.get("model"), row.get("provider"), spec.get("model"), spec.get("provider"), spec.get("cost")]), True)
        check(f"{basename}_transparent_no_fallback", row.get("transparent_background") is True and spec.get("transparent_background") is True and row.get("retries_allowed") is False and spec.get("retries_allowed") is False and row.get("cli_fallback_allowed") is False and spec.get("cli_fallback_allowed") is False and row.get("skip") is True, True)
        check(f"{basename}_runtime_not_authorized", spec.get("runtime_authorization") == "NONE_SOURCE_ART_ONLY", spec.get("runtime_authorization"))
        check(f"{basename}_prompt_has_transparent_fullbody", "transparent-background" in prompt and "full-body" in prompt and "no text" in prompt and "no floor" in prompt, True)

    carrier_row = by_id.get(TASK_IDS[0], {})
    carrier_spec = specs[0]
    check("carrier_started_before_preflight_honestly_recorded", carrier_row.get("attempts_used") == carrier_spec.get("attempts_used") == manifest["generation"]["calls_used"] == 1 and "BEFORE_REGISTRY_PREFLIGHT" in carrier_spec.get("status", "") and "already started" in manifest["generation"]["call_order_fact"], {"task_attempts": carrier_row.get("attempts_used"), "status": carrier_spec.get("status")})
    for index in (1, 2):
        row = by_id.get(TASK_IDS[index], {})
        spec = specs[index]
        check(f"{PROMPT_BASENAMES[index]}_unused_before_preflight", row.get("attempts_used") == spec.get("attempts_used") == 0 and not (repo / spec["output_path"]).exists() and not (repo / spec["metadata_path"]).exists(), {"attempts": row.get("attempts_used"), "output_exists": (repo / spec["output_path"]).exists()})

    expected_prompts = {
        TASK_IDS[0]: carrier_contract["generation"]["exact_prompt"],
        TASK_IDS[1]: next(item["exact_prompt"] for item in static_contract["identities"] if item["npc_id"] == "harbour_life_docks_store_attendant"),
        TASK_IDS[2]: next(item["exact_prompt"] for item in static_contract["identities"] if item["npc_id"] == "harbour_life_docks_rope_seller").replace("unique face distinct from the chief and warehouse attendant", "unique face distinct from the dock carrier and warehouse attendant").replace("He wears a dark blue headband", "He has slightly greying temples and wears a dark blue headband"),
    }
    for task_id, prompt in zip(TASK_IDS, prompts):
        check(f"{task_id}_exact_prompt_matches_frozen_contract", prompt == expected_prompts[task_id], {"prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest().upper()})

    check("only_carrier_has_walk_credit", specs[0]["source_layout_request"]["poses"] == ["idle_down_front", "walk_right_left_contact", "walk_right_right_passing", "walk_right_right_contact", "walk_right_left_passing"] and all(spec["source_layout_request"]["frames"] == 1 for spec in specs[1:]), True)
    check("carrier_targets_exact_three_carriers", carrier_spec["authorized_npc_ids_after_separate_runtime_admission"] == ["harbour_life_docks_rope_carrier", "harbour_life_docks_southern_carrier", "harbour_life_docks_west_carrier"], carrier_spec["authorized_npc_ids_after_separate_runtime_admission"])
    check("portrait_same_raw_rule", all((spec.get("portrait_target") or spec["runtime_targets_after_actual_measurement_and_art_admission"]["portrait"])["source"].startswith("same") for spec in specs), True)
    check("batch_budget_exact", manifest["generation"]["maximum_calls"] == 3 and manifest["generation"]["calls_used"] == 1 and manifest["generation"]["calls_per_identity"] == 1 and manifest["generation"]["automatic_retry"] is False and manifest["generation"]["cli_network_or_paid_fallback"] is False, manifest["generation"])
    check("chief_explicitly_excluded", manifest["chief_excluded"] is True and all("chief" not in task_id for task_id in TASK_IDS), True)

    passed = all(item["passed"] for item in checks)
    payload = {
        "schema_version": 1,
        "batch_id": BASE_NAME,
        "passed": passed,
        "scope": "offline prompt, registry and processing-source preflight only",
        "calls_made_by_this_preflight": {"generation": 0, "network": 0, "engine": 0, "sdk": 0},
        "historical_call_order": "Carrier builtin was already started by Root before this preflight; this pass is post-call reconciliation for carrier and a mandatory pre-call gate for store attendant and rope seller.",
        "checks": checks,
        "sources": [
            {"path": path.relative_to(repo).as_posix(), "sha256": sha256(path), "bytes": path.stat().st_size}
            for path in source_paths
        ],
        "credit_boundary": "A pass permits only the two still-unused Root builtin calls. It gives no carrier result, pose, portrait, import, runtime, Field or formal credit.",
    }
    report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
