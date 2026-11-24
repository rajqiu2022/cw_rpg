"""Record editor-only consumers and verify the gallery's bounded change."""
import argparse
import hashlib
import json
import re
from build_redrock_editor_gate_20261023c import ART, ROOT, SCENE, STAGE, sha, save

LABELS = {"gate_opening": ("building", "石砌关门"), "tower": ("building", "平顶岗楼"), "front_wall": ("building", "正面厚墙"), "side_wall": ("building", "纵深侧墙"), "cargo": ("scene_prop", "候检货包"), "trough": ("scene_prop", "饮水槽"), "guard_idle": ("npc_sprite", "匿名关卒待机"), "earth": ("ground", "夯土地表"), "rock": ("ground", "裸岩地表")}


def catalog():
    text = (ROOT / "docs/equipment-skill-catalog.html").read_text(encoding="utf-8")
    return json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', text, re.S)[1])


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def prepare():
    pub = json.loads((STAGE / "publication.json").read_text(encoding="utf-8"))
    manifest = json.loads((STAGE / "manifest.json").read_text(encoding="utf-8"))
    assert all(sha(ROOT / r["path"]) == r["sha256"] for r in pub["files"])
    rows = []
    for r in manifest["media"]:
        kind, label = LABELS[r["key"]]
        rows.append({"key": r["key"], "kind": kind, "label": "赤岩·" + label + "·编辑器草案", "output": "game/" + r["destination"], "source": r["source"], "sha256": r["sha256"], "scene": "res://" + SCENE, "formal_enabled": False})
    save(ROOT / "game" / ART / "resource-pack.json", {"status": "EDITOR_DRAFT_NOT_FORMAL_WORLD_ENTRY", "scene": "res://" + SCENE, "assets": rows})
    payload = catalog()
    save(STAGE / "catalog-before.json", {"non_resources": digest({k: v for k, v in payload.items() if k != "resources"}), "records": {r["diskPath"]: digest(r) for r in payload["resources"]["records"]}})


def verify():
    before = json.loads((STAGE / "catalog-before.json").read_text(encoding="utf-8"))
    payload = catalog()
    records = {r["diskPath"]: r for r in payload["resources"]["records"]}
    rows = json.loads((ROOT / "game" / ART / "resource-pack.json").read_text(encoding="utf-8"))["assets"]
    changed = [p for p, old in before["records"].items() if digest(records.get(p)) != old]
    checks = {"non_resources_unchanged": before["non_resources"] == digest({k: v for k, v in payload.items() if k != "resources"}), "old_records_preserved": all(p in records for p in before["records"]), "only_nine_source_rows_changed": set(changed) == {r["source"] for r in rows}, "nine_new_copies": len(set(records) - set(before["records"])) == 9}
    for row in rows:
        r = records[row["output"]]
        checks[row["key"] + "_status"] = r["status"] == "candidate" and "编辑草案" in r["statusLabel"]
        checks[row["key"] + "_category"] = r["category"] == ("npc" if row["kind"] == "npc_sprite" else "map")
        checks[row["key"] + "_thumb"] = (ROOT / "docs" / r["thumbnail"]).is_file()
        checks[row["key"] + "_full"] = (ROOT / "docs" / r["url"]).is_file()
        checks[row["key"] + "_consumer"] = any(x["label"] == row["scene"] for x in r["usage"])
        checks[row["key"] + "_copy"] = sha(ROOT / row["output"]) == sha(ROOT / row["source"])
    save(STAGE / "catalog-verification.json", {"passed": all(checks.values()), "checks": checks, "changed_source_rows": changed, "summary": payload["resources"]["summary"], "browser_click_acceptance": False})
    print(json.dumps({"passed": all(checks.values()), "checks": len(checks), "failed": [k for k, v in checks.items() if not v], "summary": payload["resources"]["summary"]}, ensure_ascii=False))
    assert all(checks.values())


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("prepare", "verify"))
    prepare() if parser.parse_args().action == "prepare" else verify()
