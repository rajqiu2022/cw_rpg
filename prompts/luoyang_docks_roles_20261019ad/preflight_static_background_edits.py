from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

import yaml


ROWS = [
    {
        "name": "store_attendant",
        "source_task": "luoyang_docks_roles_20261019ad_store_attendant_idle_down_1f_v1",
        "edit_task": "luoyang_docks_roles_20261019ad_store_attendant_idle_down_1f_v2_background_extraction_edit",
        "source": "assets/raw/luoyang_docks_roles_20261019ad/npc_docks_store_attendant_idle_down_1f_v1.png",
        "sha256": "9619304F9C51A2B9231567D18AEED5C0916DF5BD5BD2D75F8A3726591C88EFFD",
        "bytes": 1545623,
        "prompt": "prompts/luoyang_docks_roles_20261019ad/npc_docks_store_attendant_idle_down_1f_v2_background_extraction_edit.txt",
        "spec": "prompts/luoyang_docks_roles_20261019ad/npc_docks_store_attendant_idle_down_1f_v2_background_extraction_edit.spec.json",
    },
    {
        "name": "rope_seller",
        "source_task": "luoyang_docks_roles_20261019ad_rope_seller_idle_down_1f_v1",
        "edit_task": "luoyang_docks_roles_20261019ad_rope_seller_idle_down_1f_v2_background_extraction_edit",
        "source": "assets/raw/luoyang_docks_roles_20261019ad/npc_docks_rope_seller_idle_down_1f_v1.png",
        "sha256": "9092CF7CF2B2DD58359A1B66EB8578F7A65615C829258EBC59392AB28D487A9F",
        "bytes": 1795774,
        "prompt": "prompts/luoyang_docks_roles_20261019ad/npc_docks_rope_seller_idle_down_1f_v2_background_extraction_edit.txt",
        "spec": "prompts/luoyang_docks_roles_20261019ad/npc_docks_rope_seller_idle_down_1f_v2_background_extraction_edit.spec.json",
    },
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    script = Path(__file__).resolve()
    repo = script.parents[2]
    tasks_path = repo / "prompts/tasks.yaml"
    manifest_path = script.with_name("manifest.json")
    review_path = repo / "game/build/luoyang_docks_roles_20261019ad_art01/static_v1_actual_art_review.json"
    report_path = script.with_name("preflight_static_background_edits.actual.json")
    required = [script, tasks_path, manifest_path, review_path]
    for row in ROWS:
        required.extend([repo / row["source"], repo / row["prompt"], repo / row["spec"]])
    checks: list[dict[str, object]] = []

    def check(name: str, condition: bool, actual: object) -> None:
        checks.append({"name": name, "passed": bool(condition), "actual": actual})

    check("required_sources_exist", all(path.is_file() for path in required), [path.as_posix() for path in required if not path.is_file()])
    if not all(path.is_file() for path in required):
        payload = {"schema_version": 1, "passed": False, "checks": checks}
        report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 1

    tasks = yaml.safe_load(tasks_path.read_text(encoding="utf-8"))["tasks"]
    by_id: dict[str, list[dict[str, object]]] = {}
    for task in tasks:
        by_id.setdefault(str(task.get("id")), []).append(task)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    review = json.loads(review_path.read_text(encoding="utf-8"))
    review_by_sha = {row["sha256"]: row for row in review["sources"]}

    for row in ROWS:
        source_path = repo / row["source"]
        prompt_path = repo / row["prompt"]
        spec_path = repo / row["spec"]
        prompt = prompt_path.read_text(encoding="utf-8").strip()
        spec = json.loads(spec_path.read_text(encoding="utf-8"))
        source_rows = by_id.get(row["source_task"], [])
        edit_rows = by_id.get(row["edit_task"], [])
        source_task = source_rows[0] if len(source_rows) == 1 else {}
        edit_task = edit_rows[0] if len(edit_rows) == 1 else {}
        check(f"{row['name']}_source_exact", sha256(source_path) == row["sha256"] and source_path.stat().st_size == row["bytes"], {"sha256": sha256(source_path), "bytes": source_path.stat().st_size})
        check(f"{row['name']}_source_failure_preserved", len(source_rows) == 1 and source_task.get("attempts_used") == 1 and "CUTOUT_FAILED_BACKGROUND_HALO" in str(source_task.get("status")) and review_by_sha[row["sha256"]]["cutout_review"].startswith("FAIL"), source_task.get("status"))
        check(f"{row['name']}_one_edit_registered", len(edit_rows) == 1 and spec.get("id") == edit_task.get("id") == row["edit_task"], len(edit_rows))
        check(f"{row['name']}_edit_reference_exact", edit_task.get("execution_backend") == spec.get("execution_backend") == "builtin_image_gen" and edit_task.get("execution_mode") == spec.get("execution_mode") == "edit" and edit_task.get("reference_image_path") == spec.get("reference_image_path") == row["source"] and spec.get("reference_image_sha256") == row["sha256"], True)
        check(f"{row['name']}_unknown_metadata", all(value is None for value in [edit_task.get("model"), edit_task.get("provider"), spec.get("model"), spec.get("provider"), spec.get("cost")]), True)
        check(f"{row['name']}_one_unused_call_no_fallback", edit_task.get("attempts_used") == spec.get("attempts_used") == 0 and edit_task.get("attempt_budget") == spec.get("attempt_budget") == 1 and edit_task.get("retries_allowed") is False and spec.get("retries_allowed") is False and edit_task.get("cli_fallback_allowed") is False and spec.get("cli_fallback_allowed") is False and edit_task.get("skip") is True, edit_task.get("attempts_used"))
        check(f"{row['name']}_output_absent", not (repo / spec["output_path"]).exists() and not (repo / spec["metadata_path"]).exists(), {"output": (repo / spec["output_path"]).exists(), "metadata": (repo / spec["metadata_path"]).exists()})
        phrases = ["Preserve the exact same", "Do not redesign", "Remove the entire warm-grey vignette", "genuine transparent RGBA", "do not leave a grey, brown, black or coloured halo", "Keep the original 1024 by 1536 canvas", "Output one transparent image only"]
        check(f"{row['name']}_narrow_prompt", all(phrase in prompt for phrase in phrases), [phrase for phrase in phrases if phrase not in prompt])
        check(f"{row['name']}_source_only_transparent", edit_task.get("transparent_background") is True and spec.get("transparent_background") is True and spec.get("runtime_authorization") == "NONE_SOURCE_ART_ONLY", True)

    check("review_boundary_exact", review.get("status") == "IDENTITIES_LIMITED_ACCEPT_CUTOUTS_FAILED_BACKGROUND_EXTRACTION_REQUIRED" and "Do not threshold-delete alpha 1-7" in review.get("alpha_policy", ""), review.get("status"))
    check("manifest_two_background_edits", manifest["generation"]["background_extraction_edit_calls_max"] == 2 and manifest["generation"]["background_extraction_edit_calls_used"] == 0 and set(manifest["background_extraction_edit_task_ids"]) == {row["edit_task"] for row in ROWS} and manifest["generation"]["automatic_retry"] is False and manifest["generation"]["cli_network_or_paid_fallback"] is False, manifest["generation"])

    passed = all(item["passed"] for item in checks)
    payload = {
        "schema_version": 1,
        "batch_id": "luoyang_docks_roles_20261019ad_static_background_extraction_edits",
        "passed": passed,
        "scope": "offline registration preflight for exactly two targeted background-extraction edits",
        "calls_made": {"generation": 0, "network": 0, "engine": 0, "sdk": 0},
        "checks": checks,
        "sources": [
            {"path": path.relative_to(repo).as_posix(), "sha256": sha256(path), "bytes": path.stat().st_size}
            for path in required
        ],
        "credit_boundary": "A pass authorizes one Root-owned background-extraction edit for each named source only. It grants no cutout, identity, derivative, portrait, import, runtime or Field acceptance.",
    }
    report_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
