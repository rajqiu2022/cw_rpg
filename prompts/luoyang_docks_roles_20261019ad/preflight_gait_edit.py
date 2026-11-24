from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

import yaml


EDIT_TASK_ID = "luoyang_docks_roles_20261019ad_strong_carrier_posepack_idle1_right4_v2_gait_edit"
V1_TASK_ID = "luoyang_docks_roles_20261019ad_strong_carrier_posepack_idle1_right4_v1"
STATIC_IDS = [
    "luoyang_docks_roles_20261019ad_store_attendant_idle_down_1f_v1",
    "luoyang_docks_roles_20261019ad_rope_seller_idle_down_1f_v1",
]
V1_SHA = "13A645BB16F5D9D41BABE2F1D45B0BF433BC878D14D26CF470CACFECD5BBD4B6"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    script = Path(__file__).resolve()
    repo = script.parents[2]
    base = script.parent
    tasks_path = repo / "prompts/tasks.yaml"
    manifest_path = base / "manifest.json"
    prompt_path = base / "npc_docks_strong_carrier_posepack_idle1_right4_v2_gait_edit.txt"
    spec_path = base / "npc_docks_strong_carrier_posepack_idle1_right4_v2_gait_edit.spec.json"
    v1_path = repo / "assets/raw/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_posepack_idle1_right4_v1.png"
    review_path = repo / "game/build/luoyang_docks_roles_20261019ad_art01/carrier_v1_actual_art_review.json"
    original_preflight_path = base / "preflight.actual.json"
    report_path = base / "preflight_gait_edit.actual.json"
    required = [tasks_path, manifest_path, prompt_path, spec_path, v1_path, review_path, original_preflight_path, script]
    checks: list[dict[str, object]] = []

    def check(name: str, condition: bool, actual: object) -> None:
        checks.append({"name": name, "passed": bool(condition), "actual": actual})

    check("required_sources_exist", all(path.is_file() for path in required), [path.as_posix() for path in required if not path.is_file()])
    if not all(path.is_file() for path in required):
        payload = {"schema_version": 1, "passed": False, "checks": checks}
        report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 1

    tasks = yaml.safe_load(tasks_path.read_text(encoding="utf-8"))["tasks"]
    edit_rows = [row for row in tasks if row.get("id") == EDIT_TASK_ID]
    v1_rows = [row for row in tasks if row.get("id") == V1_TASK_ID]
    static_rows = [row for row in tasks if row.get("id") in STATIC_IDS]
    edit_row = edit_rows[0] if len(edit_rows) == 1 else {}
    v1_row = v1_rows[0] if len(v1_rows) == 1 else {}
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    review = json.loads(review_path.read_text(encoding="utf-8"))
    original_preflight = json.loads(original_preflight_path.read_text(encoding="utf-8"))
    prompt = prompt_path.read_text(encoding="utf-8").strip()

    check("one_edit_task_registered", len(edit_rows) == 1 and spec.get("id") == edit_row.get("id") == EDIT_TASK_ID, len(edit_rows))
    check("v1_source_exact", sha256(v1_path) == V1_SHA and v1_path.stat().st_size == 1328848, {"sha256": sha256(v1_path), "bytes": v1_path.stat().st_size})
    check("v1_failure_preserved", len(v1_rows) == 1 and "WALK_CYCLE_FAILED" in v1_row.get("status", "") and review.get("status") == "IDENTITY_LIMITED_ACCEPT_WALK_CYCLE_FAIL_NO_DERIVATIVES" and review["source"]["sha256"] == V1_SHA, {"task_status": v1_row.get("status"), "review_status": review.get("status")})
    check("edit_mode_and_reference_exact", edit_row.get("execution_backend") == spec.get("execution_backend") == "builtin_image_gen" and edit_row.get("execution_mode") == spec.get("execution_mode") == "edit" and edit_row.get("reference_image_path") == spec.get("reference_image_path") and spec.get("reference_image_sha256") == V1_SHA, True)
    check("unknown_execution_metadata", all(value is None for value in [edit_row.get("model"), edit_row.get("provider"), spec.get("model"), spec.get("provider"), spec.get("cost")]), True)
    check("single_unused_edit_no_fallback", edit_row.get("attempts_used") == spec.get("attempts_used") == 0 and edit_row.get("attempt_budget") == spec.get("attempt_budget") == 1 and edit_row.get("retries_allowed") is False and spec.get("retries_allowed") is False and edit_row.get("cli_fallback_allowed") is False and spec.get("cli_fallback_allowed") is False and edit_row.get("skip") is True, edit_row.get("attempts_used"))
    check("edit_output_absent", not (repo / spec["output_path"]).exists() and not (repo / spec["metadata_path"]).exists(), {"output": (repo / spec["output_path"]).exists(), "metadata": (repo / spec["metadata_path"]).exists()})
    check("transparent_source_only", edit_row.get("transparent_background") is True and spec.get("transparent_background") is True and spec.get("runtime_authorization") == "NONE_SOURCE_ART_ONLY", True)
    required_phrases = [
        "Preserve the exact same man",
        "preserve them as source detail",
        "Change only poses 4 and 5",
        "near-to-camera leg must extend backward",
        "far leg must reach forward",
        "body weight clearly rests on the far leg",
        "near leg is visibly lifted",
        "do not alter pose 1, pose 2 or pose 3",
        "Do not add cargo",
        "Output one transparent image only",
    ]
    check("prompt_is_narrow_and_exact", all(phrase in prompt for phrase in required_phrases), [phrase for phrase in required_phrases if phrase not in prompt])
    check("spec_scope_matches_prompt", spec["edit_scope"]["unchanged_poses"] == [1, 2, 3] and spec["edit_scope"]["changed_poses"] == [4, 5] and spec["edit_scope"]["no_programmatic_alpha_cleanup"] is True, spec["edit_scope"])
    check("manifest_one_edit_budget", manifest["generation"]["targeted_edit_calls_max"] == 1 and manifest["generation"]["targeted_edit_calls_used"] == 0 and manifest["targeted_edit_task_id"] == EDIT_TASK_ID and manifest["generation"]["automatic_retry"] is False and manifest["generation"]["cli_network_or_paid_fallback"] is False, manifest["generation"])
    check("static_preflight_historical_pass_preserved", original_preflight.get("passed") is True and original_preflight.get("calls_made_by_this_preflight") == {"generation": 0, "network": 0, "engine": 0, "sdk": 0}, sha256(original_preflight_path))
    check("two_static_calls_still_unused", len(static_rows) == 2 and {row.get("id") for row in static_rows} == set(STATIC_IDS) and all(row.get("attempts_used") == 0 and row.get("status") == "PREFLIGHT_SOURCE_READY_NOT_GENERATED" for row in static_rows), [{"id": row.get("id"), "attempts": row.get("attempts_used"), "status": row.get("status")} for row in static_rows])

    passed = all(item["passed"] for item in checks)
    source_paths = required
    payload = {
        "schema_version": 1,
        "task_id": EDIT_TASK_ID,
        "passed": passed,
        "scope": "offline targeted-edit registration preflight only",
        "calls_made": {"generation": 0, "network": 0, "engine": 0, "sdk": 0},
        "checks": checks,
        "sources": [
            {"path": path.relative_to(repo).as_posix(), "sha256": sha256(path), "bytes": path.stat().st_size}
            for path in source_paths
        ],
        "credit_boundary": "A pass authorizes at most one Root-owned targeted builtin edit. It does not approve v1 gait, v2 gait, alpha cleanup, derivatives, portrait, import, runtime or Field use.",
    }
    report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
