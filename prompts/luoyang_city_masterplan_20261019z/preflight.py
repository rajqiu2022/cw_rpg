from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

import yaml


TASK_ID = "luoyang_city_masterplan_20261019z_overview_v1"
DISTRICTS = [
    "01 南门瓮城",
    "02 南北主街",
    "03 府衙官署",
    "04 南市商街",
    "05 西市百工",
    "06 民居坊巷",
    "07 世家宅园",
    "08 漕运码头",
    "09 洛水园林",
    "10 城外古寺",
]
BUILDING_TERMS = [
    "gatehouse",
    "watchtower",
    "wall walk",
    "yamen hall",
    "office wing",
    "barracks",
    "archive",
    "inn",
    "pharmacy",
    "cloth shop",
    "granary",
    "teahouse",
    "smithy",
    "artisan workshop",
    "common house",
    "courtyard house",
    "ancestral hall",
    "elite mansion gate",
    "mansion hall",
    "garden pavilion",
    "warehouse",
    "customs office",
    "wharf shed",
    "bridge",
    "temple gate",
    "temple hall",
    "pagoda",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    script_path = Path(__file__).resolve()
    repo = script_path.parents[2]
    prompt_path = script_path.with_name("luoyang_city_masterplan_overview_v1.txt")
    spec_path = script_path.with_name("luoyang_city_masterplan_overview_v1.spec.json")
    manifest_path = script_path.with_name("manifest.json")
    tasks_path = repo / "prompts" / "tasks.yaml"
    proposal_path = repo / "docs" / "luoyang-city-masterplan-20261019z_art_proposal.md"
    report_path = script_path.with_name("preflight.actual.json")

    checks: list[dict[str, object]] = []

    def check(name: str, condition: bool, actual: object) -> None:
        checks.append({"name": name, "passed": bool(condition), "actual": actual})

    required = [prompt_path, spec_path, manifest_path, tasks_path, proposal_path]
    check("required_sources_exist", all(path.is_file() for path in required), [str(path) for path in required])
    if not all(path.is_file() for path in required):
        payload = {"schema_version": 1, "passed": False, "checks": checks}
        report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 1

    prompt = prompt_path.read_text(encoding="utf-8")
    proposal = proposal_path.read_text(encoding="utf-8")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    tasks_doc = yaml.safe_load(tasks_path.read_text(encoding="utf-8"))
    matching = [task for task in tasks_doc.get("tasks", []) if task.get("id") == TASK_ID]
    check("one_registered_task", len(matching) == 1, len(matching))
    task = matching[0] if len(matching) == 1 else {}

    check("task_and_spec_id_match", task.get("id") == spec.get("id") == TASK_ID, [task.get("id"), spec.get("id")])
    check("builtin_generate_only", task.get("execution_backend") == spec.get("execution_backend") == "builtin_image_gen" and task.get("execution_mode") == spec.get("execution_mode") == "generate", [task.get("execution_backend"), task.get("execution_mode")])
    check("unknown_execution_metadata_is_honest", all(value is None for value in [task.get("model"), task.get("provider"), spec.get("model"), spec.get("provider"), spec.get("cost"), manifest.get("generation", {}).get("model"), manifest.get("generation", {}).get("provider"), manifest.get("generation", {}).get("cost")]), "all model/provider/cost fields null")
    check("one_initial_call_only", task.get("attempt_budget") == spec.get("attempt_budget") == manifest.get("generation", {}).get("initial_generate_calls_max") == 1 and task.get("attempts_used") == spec.get("attempts_used") == manifest.get("generation", {}).get("initial_generate_calls_used") == 0, {"task_budget": task.get("attempt_budget"), "task_used": task.get("attempts_used")})
    check("optional_edit_is_bounded", task.get("optional_targeted_edit_budget") == spec.get("optional_targeted_edit_budget") == manifest.get("generation", {}).get("optional_targeted_edit_calls_max") == 1 and manifest.get("generation", {}).get("optional_targeted_edit_calls_used") == 0, manifest.get("generation", {}))
    check("no_retry_or_cli_fallback", task.get("retries_allowed") is False and task.get("cli_fallback_allowed") is False and spec.get("retries_allowed") is False and spec.get("cli_fallback_allowed") is False and manifest.get("generation", {}).get("automatic_retry") is False and manifest.get("generation", {}).get("cli_or_paid_fallback") is False, True)
    check("no_input_images", spec.get("input_images") == [] and manifest.get("input_images") == [] and "Input images: none." in prompt, {"spec": spec.get("input_images"), "manifest": manifest.get("input_images")})
    check("screenshots_are_negative_evidence_only", "must not be used as an edit target, layout template, or visual collage" in prompt and "not edit targets, reference templates, or compositing inputs" in manifest.get("screenshots_boundary", ""), True)
    check("ten_district_order_exact", spec.get("district_order") == DISTRICTS and all(label in prompt for label in DISTRICTS), spec.get("district_order"))
    check("proposal_has_all_districts", all(label.split(" ", 1)[1] in proposal for label in DISTRICTS), [label for label in DISTRICTS if label.split(" ", 1)[1] not in proposal])
    check("proposal_is_authoritative_for_labels", "本表是名称权威" in proposal and "remains authoritative" in manifest.get("authority", ""), True)
    check("large_city_routes_present", all(term in prompt for term in ["north-south ceremonial main street", "two connected loop streets", "narrower walkable lanes", "short return routes"]), True)
    check("required_spatial_relationships_present", all(term in prompt for term in ["south gate and barbican", "north-central yamen", "southeastern canal/river port", "northeastern elite mansion", "east of the walls", "east-gate road"]), True)
    check("building_diversity_over_15", sum(term in prompt for term in BUILDING_TERMS) >= 16, {"matched": sum(term in prompt for term in BUILDING_TERMS), "required": 16})
    check("separate_building_identity_rule", "A single building with three repeated doors must never impersonate three destinations" in prompt and "own readable building mass and courtyard boundary" in prompt, True)
    check("fictional_not_reconstruction", "invented Da-Qian" in prompt and "not an archaeological reconstruction" in prompt and "不宣称历史洛阳复原" in proposal, True)
    check("concept_only_no_runtime_credit", spec.get("runtime_authorization") == "NONE_CONCEPT_PLANNING_ONLY" and manifest.get("runtime_credit") is False and "总览也不是正式游戏背景图" in proposal, True)
    check("output_not_precreated", not (repo / spec["output_path"]).exists() and not (repo / spec["metadata_path"]).exists(), {"output": spec["output_path"], "metadata": spec["metadata_path"]})

    source_paths = [prompt_path, spec_path, manifest_path, tasks_path, proposal_path, script_path]
    passed = all(item["passed"] for item in checks)
    payload = {
        "schema_version": 1,
        "task_id": TASK_ID,
        "passed": passed,
        "scope": "offline registration and prompt contract only",
        "calls_made": {"generation": 0, "network": 0, "engine": 0, "sdk": 0},
        "checks": checks,
        "sources": [
            {"path": path.relative_to(repo).as_posix(), "sha256": sha256(path), "bytes": path.stat().st_size}
            for path in source_paths
        ],
        "credit_boundary": "Ready for one Root-owned builtin generation call only; no image, runtime, historical, or gameplay acceptance is granted.",
    }
    report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
