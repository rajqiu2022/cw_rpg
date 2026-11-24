"""Register one connected-gate redesign in an independent art queue."""
import argparse
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/raw/redrock_gate_redesign_20261023d"
QUEUE = ROOT / "assets/staging/redrock_gate_redesign_20261023d/production/prompts"
REF = ROOT / "assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png"
IDENT = "redrock_gate_connected_design_20261023d_v1"
PROMPT = """Use case: stylized-concept
Asset type: ONE coherent environment DESIGN illustration for the FIRST GATE DISTRICT of a 2.5D wuxia red-sandstone canyon pass-town. This is a new architectural redesign, not a tile atlas or collage of separate objects. Landscape 3:2 frame.
Input image 1 is reference for the USER-SELECTED town's red sandstone, dry frontier climate, thick masonry, layered terrain and grounded painterly game art. Refer only to the LOWER GATE DISTRICT of that image. Do not reproduce its entire town; do not copy its Chinese tiled lookout roofs.
PRIMARY CORRECTION: Show an actually CONNECTED fortification built across a narrow canyon. Every wall ends in masonry or rock, and every junction is physically legible. From left to right: layered canyon rock shoulder, short curtain wall embedded into the rock, a square flat-roof watch bastion bonded directly to the LEFT gate pier, the broad open gate, a lower RIGHT gate bastion, a connected curtain wall returning at a real solid corner, and the other canyon shoulder. The tower must belong to this one complex, NOT stand loose behind the wall. Use real straight masonry abutments, bonded corner stones, consistent wall thickness and visible continuous wall-walk levels. No intersecting freestanding wall panels, impossible T overlaps, cut wall ends, hairline gaps, or isolated tower. Gate, curtain walls and bastions share the SAME masonry block scale, stone palette, foundations and coping system. Taller tower can rise above the curtain, but its lower wall connection and accessible wall-walk must remain intelligible. No ornamental arch city gate: plain dark timber lintel and robust thick red-stone piers, open wooden leaves folded to the sides.
Composition/camera: fixed elevated orthographic 2.5D GAME camera, approximately35 degrees above ground, see front and RIGHT depth faces consistently. Keep the front gate/curtain line nearly horizontal, depth edges recede consistently towards upper-right. No fish-eye, panorama, tilted horizon, perspective zoom, floating isometric island, or cutaway cross section. Frame the WHOLE first gate district with actual canyon edges, main approach and one short inner road. All building foundations rest on their respective same ground terrace; no wide featureless ground plane.
Circulation: broad quiet LIGHT DUSTY OCHRE compacted-earth caravan road approaches from lower center/right, passes straight through the visibly open gate, then turns behind the wall into one broad gently rising switchback ramp toward screen upper-right, connecting to the next terrace beyond this district. No stairs across the caravan route. Gate opening about3 adult heights tall and spacious enough for a small pack caravan/two-way foot traffic. Gate opening and approach remain completely unobstructed. Canyon shoulders and retaining walls explain narrowness and elevation; avoid unexplained rectangular texture boundaries. Fine-grain dust/soil on the road contrasts clearly with rough DARKER RED cliffs; small scattered pebbles, no blanket of giant ground stones.
Two secondary service recesses: a modest WATER TROUGH is integrated against the sheltered left approach-side wall, with a small standing space; a compact INSPECTION/CARGO BAY is tucked against the right approach-side retaining wall, holding a few strapped cloth bales and one plain small handcart. Both recesses join the road but do not occupy its middle or feel like loose props on an empty field. No market or new buildings crowding the checkpoint. Two or three anonymous practical guards/travellers in muted dusty tunics and round soft caps establish adult scale; no hero portrait, named NPC, enemy, or boss.
Visual hierarchy: connected gate complex is the focal point, clear route second, understated service recesses third. Pale dusty road, muted rust/red masonry and cliffs, dark brown timber, sparse dry scrub in rock crevices. Daylight from upper-left, all shadows to lower-right, detailed matte painterly game art matching reference quality. Flat crenellated roofs and simple dark timber only: NO tiled/upturned Chinese pavilion roof, no European castle cones, no domes or fantasy glow.
Labels: at most five small cream Chinese callout tags with thin unobtrusive leader lines, exact text: “关楼连墙”, “峡壁咬合”, “穿门主路”, “内侧折返”, “路侧作业位”. Put labels in open margins, never across a junction, gate opening, road or architecture. No title, legend, HUD, control help, numbers, mock game UI, or large captions. The image itself must make the continuous joins clear even with labels ignored.
This is a design proposal only. Do not present a technical test pass, numerical clearance guarantee, modular sprite sheet, or final playable map.
"""


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def save(p, value):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def prepare():
    assert not (BASE / "manifest.json").exists()
    BASE.mkdir(parents=True)
    (QUEUE / "templates").mkdir(parents=True)
    template = "redrock_gate_connected_design_20261023d"
    (QUEUE / "templates" / (template + ".yaml")).write_text(yaml.safe_dump({"name": template, "prompt_template": "{asset_prompt}", "size": "1536x1024", "quality": "high", "background": "opaque", "reference_images": [str(REF)], "require_reference_images": True}, allow_unicode=True, sort_keys=False), encoding="utf-8")
    (QUEUE / (IDENT + ".txt")).write_text(PROMPT, encoding="utf-8")
    task = {"id": IDENT, "template": template, "skip": True, "execution_backend": "builtin_image_gen", "attempt_budget": 1, "retries_allowed": False, "cli_fallback_allowed": False, "transparent_background": False, "reference_images": [str(REF)], "vars": {"asset_prompt": PROMPT}}
    (QUEUE / "tasks.yaml").write_text(yaml.safe_dump({"tasks": [task]}, allow_unicode=True, sort_keys=False), encoding="utf-8")
    sys.path.insert(0, str(ROOT / "scripts"))
    import gen_assets as renderer
    renderer.TEMPLATES_DIR = QUEUE / "templates"
    spec = renderer.render_template(template, {"asset_prompt": PROMPT}, {})
    assert spec["prompt"] == PROMPT.strip() and len(spec["reference_images"]) == 1
    save(BASE / "manifest.json", {"id": IDENT, "status": "REGISTERED", "calls": 0, "reference": REF.relative_to(ROOT).as_posix(), "reference_sha256": sha(REF), "prompt": (QUEUE / (IDENT + ".txt")).relative_to(ROOT).as_posix(), "prompt_sha256": sha(QUEUE / (IDENT + ".txt")), "model": None, "provider": None, "cost": None, "formal_enabled": False, "production_queue_sha256": sha(ROOT / "prompts/tasks.yaml")})
    save(BASE / "preflight.json", {"passed": True, "tasks": 1, "references": 1, "root_queue_written": False, "no_automatic_retry": True})


def start():
    p = BASE / "manifest.json"
    m = json.loads(p.read_text(encoding="utf-8"))
    assert m["status"] == "REGISTERED" and m["calls"] == 0
    assert sha(REF) == m["reference_sha256"]
    m.update(status="BUILTIN_CALL_DISPATCHED", calls=1)
    save(p, m)


def record(source):
    p = BASE / "manifest.json"
    m = json.loads(p.read_text(encoding="utf-8"))
    assert m["calls"] == 1 and m["status"] == "BUILTIN_CALL_DISPATCHED"
    output = BASE / "design" / (IDENT + ".png")
    assert not output.exists()
    output.parent.mkdir()
    shutil.copyfile(source, output)
    assert sha(Path(source)) == sha(output)
    with Image.open(output) as im:
        size, mode = list(im.size), im.mode
    m.update(status="DESIGN_PROPOSAL_AWAITING_REVIEW", output=output.relative_to(ROOT).as_posix(), sha256=sha(output), size=size, mode=mode, source_path=str(source), fallback_used=False, production_queue_unchanged=sha(ROOT / "prompts/tasks.yaml") == m["production_queue_sha256"])
    save(p, m)
    save(output.with_suffix(".meta.json"), m)
    save(BASE / "resource-pack.json", {"status": "DESIGN_PROPOSAL_NOT_ADOPTED", "assets": [{"id": IDENT, "kind": "design", "label": "赤岩·峡口连体关防重设计", "output": m["output"], "sha256": m["sha256"], "transparent": False, "review_note": "用户否定旧松散拼装后重新设计的整体关防提案；先审连接/围合/地形和拆件接口，未获用户确认、未拆件或覆盖工程。", "formal_enabled": False}]})
    print(json.dumps({"output": m["output"], "size": size, "mode": mode, "root_queue_unchanged": m["production_queue_unchanged"]}, ensure_ascii=False))


def payload():
    text = (ROOT / "docs/equipment-skill-catalog.html").read_text(encoding="utf-8")
    return json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', text, re.S)[1])


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def gallery_before():
    p = payload()
    save(BASE / "catalog-before.json", {"non_resources": digest({k: v for k, v in p.items() if k != "resources"}), "records": {r["diskPath"]: digest(r) for r in p["resources"]["records"]}})


def verify():
    m = json.loads((BASE / "manifest.json").read_text(encoding="utf-8"))
    p = payload()
    before = json.loads((BASE / "catalog-before.json").read_text(encoding="utf-8"))
    records = {r["diskPath"]: r for r in p["resources"]["records"]}
    editor = json.loads((ROOT / "game/art/modules/redrock_gate_20261023c/resource-pack.json").read_text(encoding="utf-8"))
    old_outputs = {r["output"] for r in editor["assets"]}
    old_sources = {r["source"] for r in editor["assets"]}
    changed = {path for path, old in before["records"].items() if digest(records.get(path)) != old}
    design = records[m["output"]]
    publication = json.loads((ROOT / "assets/staging/redrock_editor_gate_20261023c/publication.json").read_text(encoding="utf-8"))
    checks = {
        "one_native_call": m["calls"] == 1,
        "native_source_saved_exact": sha(ROOT / m["output"]) == sha(Path(m["source_path"])) == m["sha256"],
        "selected_masterplan_unchanged": sha(REF) == m["reference_sha256"],
        "root_queue_unchanged": sha(ROOT / "prompts/tasks.yaml") == m["production_queue_sha256"],
        "old_41_scene_media_import_leaves_unchanged": all(sha(ROOT / r["path"]) == r["sha256"] for r in publication["files"]),
        "non_resources_unchanged": before["non_resources"] == digest({k: v for k, v in p.items() if k != "resources"}),
        "one_new_design_record": set(records) - set(before["records"]) == {m["output"]},
        "only_old_18_usage_states_updated": changed == old_outputs | old_sources,
        "old_9_copies_marked_rejected_layout": all("用户否定" in records[path]["statusLabel"] for path in old_outputs),
        "design_category": design["category"] == "design",
        "design_proposal_status": design["status"] == "candidate" and design["statusLabel"] == "重设计提案 · 待审阅",
        "design_thumbnail": (ROOT / "docs" / design["thumbnail"]).is_file(),
        "design_full_image": (ROOT / "docs" / design["url"]).is_file(),
    }
    save(BASE / "verification.json", {"passed": all(checks.values()), "checks": checks, "gallery_summary": p["resources"]["summary"], "browser_click_acceptance": False, "engine_runs_this_batch": 0, "user_confirmed_design": False})
    print(json.dumps({"passed": all(checks.values()), "failed": [k for k, v in checks.items() if not v], "summary": p["resources"]["summary"]}, ensure_ascii=False))
    assert all(checks.values())


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("action", choices=("prepare", "start", "record", "gallery-before", "verify"))
    p.add_argument("--source")
    args = p.parse_args()
    if args.action == "prepare":
        prepare()
    elif args.action == "start":
        start()
    elif args.action == "record":
        record(args.source)
    elif args.action == "gallery-before":
        gallery_before()
    else:
        verify()
