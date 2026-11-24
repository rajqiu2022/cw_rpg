"""Exact reviewed-floor install/rollback. No engine, no process or real-save access."""

import base64
import json
import re
import sys
from prepare_yihong_floors import (
    BASE, BIN, GATE, HELPER, MANIFEST, NEXT, ROUTER,
    SCENE, SNAP, audit_hashes, check, encoded, gate_baseline, gate_pins,
    media_sources, path, read, rel, sha, startup,
)


def load_plan(plan_arg, expected_sha):
    receipt_path = path(plan_arg, "game/build")
    check(receipt_path.parent.parent == BASE and re.fullmatch(r"yihong_floors_REVIEW\d+", receipt_path.parent.name) and receipt_path.name == "receipt.json", "PLAN_LOCATION")
    receipt = receipt_path.read_bytes()
    check(sha(receipt) == expected_sha, "ROOT_REVIEWED_RECEIPT_DRIFT")
    plan = json.loads(receipt)
    check(plan["status"] == "STAGED_29_EXISTING_5_NEW_NO_RUNTIME_WRITES" and len(plan["targets"]) == 34, "ROOT_REVIEW_DOMAIN")
    check(sha(read(plan["room_receipt"])) == plan["room_receipt_sha256"], "FROZEN_ROOM_RECEIPT_DRIFT")
    check(sha(read(plan["media_pin_file"])) == plan["media_pin_file_sha256"], "FROZEN_MEDIA_PINS_RECEIPT_DRIFT")
    media_sources(plan["media_pin_file"])
    rows = {}
    for row in plan["targets"]:
        target = row["target"]
        check(target not in rows, "DUPLICATE_TARGET", target)
        c = path(row["candidate"], "game/build")
        check(c.parent == receipt_path.parent and c.name == target.replace("/", "__"), "CANDIDATE_LOCATION", target)
        old = base64.b64decode(row["before_b64"], validate=True) if row["before_b64"] is not None else None
        new = c.read_bytes()
        check((sha(old) if old is not None else None) == row["before_sha256"], "BACKUP_HASH", target)
        check(sha(new) == row["after_sha256"] and old != new, "CANDIDATE_HASH", target)
        rows[target] = (path(target), old, new)
    new_targets = {p for p, (_, old, _) in rows.items() if old is None}
    check(new_targets == {HELPER, SCENE, *BIN.values(), rel(SNAP)}, "EXACT_FIVE_NEW_PATHS")
    check(rows[ROUTER][2] == rows[rel(SNAP)][2], "SNAPSHOT_ROUTER_BYTES")
    check(rows[MANIFEST][2] and sha(rows[MANIFEST][2]) == plan["manifest_sha256"], "REGION_MANIFEST_STAGE_SHA")
    return plan, rows, receipt_path.parent


def install_preflight(plan, rows):
    _, _, old, _ = startup()
    check({p: pre for p, (_, pre, _) in rows.items() if pre is not None} == old, "EXACT_REVIEWED_EXISTING_PREIMAGES")
    after = {p: new for p, (_, _, new) in rows.items()}
    baseline, dynamic = gate_baseline(old)
    expected = gate_pins(json.loads(after[GATE])) | {p: sha(after[rel(p)]) if rel(p) in after else baseline[p] for p in dynamic}
    check(len(expected) == 1759 and set(expected) == set(baseline) | {SNAP}, "GATE_PIN_KEYS")
    audit_hashes(expected, after)
    for p, (target, pre, _) in rows.items():
        check((not target.exists()) if pre is None else target.read_bytes() == pre, "INSTALL_TARGET_DRIFT", p)
    check(not path(NEXT[:-1]).exists(), "FRESH_TWO_FLOOR_RUNTIME_DIRECTORY")


def atomic_write(target, data, marker):
    tmp = target.with_name(target.name + ".staged-" + marker)
    with tmp.open("xb") as f:
        f.write(data)
    check(tmp.read_bytes() == data, "TEMP_OUTPUT_DRIFT", str(tmp))
    tmp.replace(target)


def main(argv):
    check(len(argv) == 3 and re.fullmatch(r"[0-9a-f]{64}", argv[1]) and argv[2] in {"--preflight", "--install", "--rollback"}, "USAGE: REVIEW/receipt.json ROOT_REVIEWED_SHA --preflight|--install|--rollback")
    plan, rows, review = load_plan(argv[0], argv[1])
    installed = review / "installed.json"
    rollback = review / "rolled_back.json"
    journal = review / "install_order.json"
    mode = argv[2]
    if mode == "--rollback":
        check(journal.is_file() and not rollback.exists(), "NO_EXACT_INSTALL_JOURNAL")
        intent = json.loads(journal.read_bytes())
        check(intent["approved_review_sha"] == argv[1] and len(intent["targets"]) == len(rows) and set(intent["targets"]) == set(rows), "EXACT_INSTALL_JOURNAL_SCOPE")
        complete = installed.is_file()
        if complete:
            check(json.loads(installed.read_bytes())["approved_review_sha"] == argv[1], "EXACT_INSTALLED_RECEIPT_DRIFT")
        applied = set()
        saw_unwritten = False
        for p in intent["targets"]:
            target, pre, new = rows[p]
            current = target.read_bytes() if target.is_file() else None
            if current == new:
                check(not saw_unwritten, "ROLLBACK_INSTALL_PREFIX_GAP", p)
                applied.add(p)
            else:
                check(not complete and current == pre, "ROLLBACK_DRIFT_STOP", p)
                saw_unwritten = True
        # Restore Router first on exact inverse; immutable new leaves remain inert.
        for p in [ROUTER, *[x for x in reversed(rows) if x != ROUTER]]:
            target, pre, new = rows[p]
            if pre is not None and p in applied:
                check(target.read_bytes() == new, "ROLLBACK_CONCURRENT_DRIFT", p)
                atomic_write(target, pre, "inverse-" + argv[1][:8])
                check(target.read_bytes() == pre, "ROLLBACK_READBACK", p)
        result = {"status": "EXACT_APPLIED_PREIMAGES_RESTORED_NEW_LEAVES_RETAINED", "approved_review_sha": argv[1], "preimages_restored": sum(p in applied and pre is not None for p, (_, pre, _) in rows.items()), "inert_new_retained": sum(p in applied and pre is None for p, (_, pre, _) in rows.items()), "engine_runs": 0, "real_save_access": 0}
        with rollback.open("xb") as f:
            f.write(encoded(result))
    else:
        check(not journal.exists() and not installed.exists() and not rollback.exists(), "IMMUTABLE_DEPLOY_HISTORY_EXISTS")
        install_preflight(plan, rows)
        result = {"status": "PREFLIGHT_ONLY_NO_WRITES", "approved_review_sha": argv[1], "existing": 29, "new": 5, "gate_expected": 1759, "engine_runs": 0, "real_save_access": 0}
        if mode == "--install":
            # Materialize new immutable leaves before publishing the guarded Router head.
            order = [p for p, (_, old, _) in rows.items() if old is None]
            order += [p for p, (_, old, _) in rows.items() if old is not None and p != ROUTER]
            order.append(ROUTER)
            with journal.open("xb") as f:
                f.write(encoded({"approved_review_sha": argv[1], "targets": order}))
            for p in order:
                target, pre, new = rows[p]
                if pre is None:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with target.open("xb") as f:
                        f.write(new)
                else:
                    check(target.read_bytes() == pre, "INSTALL_CONCURRENT_DRIFT", p)
                    atomic_write(target, new, "forward-" + argv[1][:8])
                check(target.read_bytes() == new, "INSTALL_READBACK", p)
            result["status"] = "INSTALLED_29_EXISTING_5_NEW_NO_ENGINE_RUN"
            with installed.open("xb") as f:
                f.write(encoded(result))
    print(json.dumps(result))


if __name__ == "__main__":
    main(sys.argv[1:])
