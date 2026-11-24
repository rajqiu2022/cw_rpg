"""Three-piece connected fortification trial, isolated art queue and source receipts."""
import argparse
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/raw/redrock_joint_trial_20261023e"
STAGE = ROOT / "assets/staging/redrock_joint_trial_20261023e"
QUEUE = STAGE / "production/prompts"
DESIGN = ROOT / "assets/raw/redrock_gate_redesign_20261023d/design/redrock_gate_connected_design_20261023d_v1.png"

COMMON = """Use case: stylized-concept
Asset type: ONE genuine transparent 2.5D wuxia game MAP STRUCTURE MODULE, not a scene/background and not an atlas. Image 1 is the USER-APPROVED connected redrock pass-gate DESIGN: reproduce its coherent red-sandstone thick masonry, pale dust, plain dark timber, flat crenellated architecture, material and upper-left daylight. This is a newly drawn module, NOT a crop from that concept picture.
Fixed orthographic elevated 2.5D map camera: FRONT wall faces and their base/top edges run HORIZONTALLY left to right; see TOP and a restrained RIGHT depth face consistently. No vanishing-point lens distortion, horizon, tilted camera, curved front wall, or rotated photo. All stone block courses have matching scale, wall thickness, front ground plane and coping across connected elements. Dry matte muted red sandstone, restrained game-painted detail, not noisy photoreal speckles or orange glossy plastic. Main rectangular masonry blocks roughly 5% of an adult height; a door opening is about2.6 adult heights. No Chinese curved/eaved tiled roof, canopy, domes, cones, fancy carving, chains, banners, vegetation painted over wall seams, people, animals, UI, labels, numbers, text, measurement arrows or extra unrelated props.
TRUE transparent background. No black/grey/white baked background, broad dust floor island, flat ground rectangle, cloud, halo, glow or detached shadow particles. The WHOLE component including any tiny shadow MUST fit inside the central60% of BOTH canvas width and canvas height: at least20% of image width/height genuinely alpha0 margin on ALL four sides. Detached weak-alpha dust is forbidden. Preserve the complete geometry and all ends. Very small attached contact shading is allowed. No cropping at canvas borders. Use a landscape canvas, with the component comfortably centered and empty transparent surroundings.
"""
CORE = COMMON + """
Requested module: ONE INTEGRATED GATEHOUSE CORE. A tall square FLAT-ROOF WATCH BASTION on the LEFT is structurally BONDED to the left gate pier, a broad plain timber lintel and wall-walk bridge above the opening lead into a LOWER square RIGHT pier/bastion. The watch bastion, piers, gate lintel and two short outer wall stubs are ONE continuous masonry complex, with physical bonded corners and readable continuous lower wall-walk level. No floating/independent tower. The left taller upper platform has its own plain stone parapet, no roof structure. Its lower connector joins the curtain-wall walk, with a small believable stair/landing behind the bastion if visible.
Broad rectangular gate opening in the lower CENTER-RIGHT, completely transparent through the opening from the underside of the lintel down to and BELOW the ground baseline; both massive dark timber gate leaves swung fully inward and tightly folded to the side piers, not blocking the opening. Clear opening width around36% of the core's masonry width, height around28% of total masonry height, large enough for pack traffic. No threshold stair or solid paving panel across the aperture, no black empty doorway. Make the opening and adult scale legible.
Both outside ends extend into SHORT STRAIGHT CURTAIN-WALL STUBS with IDENTICAL front base line, thickness, wall-walk height, coping/parapet, small block size and end cross-section. The LEFT stub projects a short distance LEFT of the tall bastion, the RIGHT stub projects RIGHT of the low pier. Both stubs end in clean vertical masonry cross-sections, intended to receive matching separate wall wings. Their FRONT BASES on the SAME y baseline. The seam is an ordinary short wall section: no giant decorative end pillars. The core should be roughly TWICE as wide as its full visible height. Do not add canyon rocks or outer yard walls in this core module.
"""
WING = """
Image 2 is the ALREADY DRAWN CORE MODULE and is the strict reference for CAMERA, stone blocks, colour, wall thickness, wall-walk level, parapet, light and shared front base. Create only the specified SEPARATE wing, do not repeat the core or any gate/tower.
"""
LEFT = COMMON + WING + """
Requested module: ONE LEFT OUTER CURTAIN WALL WITH A CONNECTED RED CANYON SHOULDER. The RIGHTMOST end is a short straight clean mating wall section aimed toward the core's LEFT wall stub. It must match the core stub's profile exactly in height, thickness, block scale, coping and horizontal FRONT ground baseline; front facade runs horizontally. This right seam has no closing end cap, freestanding buttress, jutting rock or shadow extending into the matching area. The central wall continues LEFT continuously, then terminates naturally EMBEDDED INTO a tall irregular RED SANDSTONE CLIFF SHOULDER at the FAR LEFT. The wall is structurally continuous from the exposed right mating face all the way into rock, not loose in front of it. Weathered stratified cliff with a complete silhouette, narrow grounded base, no backdrop or large ground island. The cliff rises about1.4 times wall height. Cliff texture rougher and darker than neat squared wall masonry. All rock and masonry kept inside20% transparent margins. The wall's visible span is around1.6 times the wall height; the whole wing is around1.6 times as wide as high. No tower, gate, trough, cargo, service shelter, road or vegetation at the seam.
"""
RIGHT = COMMON + WING + """
Requested module: ONE RIGHT OUTER CURTAIN WALL WITH ITS OWN BONDED CORNER AND CANYON SHOULDER. The LEFTMOST end is a short straight clean mating wall section aimed toward the core's RIGHT wall stub. Match that stub's profile exactly in height, thickness, block scale, coping and horizontal FRONT ground baseline; front facade runs horizontally. This left seam has no closing end cap, freestanding buttress, jutting rock or detached shadow. The straight curtain continues RIGHT, then makes ONE believable masonry corner and short shallow return toward SCREEN UPPER RIGHT, finally embedding into an irregular RED SANDSTONE ROCK SHOULDER at far right. The corner is an actual bonded wall volume with continuous coping and walk, not two intersecting freestanding panels. The rock rises about1.3 times wall height, rougher/darker than the squared masonry; complete rock silhouette, narrow base, no broad floor island. Keep ALL positive-alpha geometry and shade inside20% transparent margins. The whole wing is around1.7 times as wide as high. No new tower/gate, roof, cargo/props, yard, road or vegetation at the mating seam.
"""
ITEMS = {"core": ("building", "赤岩·连体关楼核心", CORE), "left": ("landform", "赤岩·左墙翼接岩肩", LEFT), "right": ("landform", "赤岩·右转墙翼接岩肩", RIGHT)}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def save(p, v):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(v, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def prepare():
    assert not (BASE / "manifest.json").exists()
    (QUEUE / "templates").mkdir(parents=True)
    refs = [str(DESIGN)]
    rows, tasks = [], []
    sys.path.insert(0, str(ROOT / "scripts"))
    import gen_assets as renderer
    renderer.TEMPLATES_DIR = QUEUE / "templates"
    for key, (kind, label, prompt) in ITEMS.items():
        ident = f"redrock_joint_20261023e_{key}_v1"
        template = f"redrock_joint_{key}_20261023e"
        (QUEUE / "templates" / (template + ".yaml")).write_text(yaml.safe_dump({"name": template, "prompt_template": "{asset_prompt}", "size": "1536x1024", "quality": "high", "background": "transparent", "reference_images": refs, "require_reference_images": True}, allow_unicode=True, sort_keys=False), encoding="utf-8")
        path = QUEUE / (ident + ".txt")
        path.write_text(prompt, encoding="utf-8")
        spec = renderer.render_template(template, {"asset_prompt": prompt}, {})
        assert spec["prompt"] == prompt.strip()
        tasks.append({"id": ident, "template": template, "skip": True, "execution_backend": "builtin_image_gen", "attempt_budget": 1, "retries_allowed": False, "cli_fallback_allowed": False, "transparent_background": True, "reference_images": refs, "vars": {"asset_prompt": prompt}})
        rows.append({"key": key, "id": ident, "kind": kind, "label": label, "prompt": path.relative_to(ROOT).as_posix(), "prompt_sha256": sha(path), "references": [DESIGN.relative_to(ROOT).as_posix()], "status": "REGISTERED", "calls": 0})
    (QUEUE / "tasks.yaml").write_text(yaml.safe_dump({"tasks": tasks}, allow_unicode=True, sort_keys=False), encoding="utf-8")
    protected = [ROOT / "game/project.godot", ROOT / "prompts/tasks.yaml", DESIGN]
    protected += list((ROOT / "game/scripts/autoload").glob("*.gd"))
    protected += list((ROOT / "game/scripts/field").glob("*.gd"))
    protected += [p for p in (Path(os.environ["APPDATA"]) / "Godot/app_userdata/云影侠传").rglob("save*") if p.is_file()]
    save(STAGE / "protected-before.json", [{"path": str(p), "sha256": sha(p), "bytes": p.stat().st_size, "mtime_ns": p.stat().st_mtime_ns} for p in sorted(set(protected))])
    save(BASE / "manifest.json", {"status": "REGISTERED_THREE_COMPONENT_TRIAL", "assets": rows, "model": None, "provider": None, "cost": None, "formal_enabled": False})
    save(BASE / "preflight.json", {"passed": True, "rendered_prompts": 3, "queue_isolated": True, "root_queue_written": False})
    save(BASE / "selected-design-authorization.json", {"date": "2026-10-23", "user_message": "这个设计图可以，但是要拼接起来不容易，你试试看", "design": DESIGN.relative_to(ROOT).as_posix(), "sha256": sha(DESIGN), "scope": "采用新设计方向进行实际模块试拼；不恢复旧c版布局，不扩大旧像素处理许可"})


def start(key):
    p = BASE / "manifest.json"
    m = json.loads(p.read_text(encoding="utf-8"))
    r = next(r for r in m["assets"] if r["key"] == key)
    assert r["status"] == "REGISTERED" and r["calls"] == 0
    if key != "core":
        core = next(r for r in m["assets"] if r["key"] == "core")
        assert core.get("output")
        r["references"].append(core["output"])
        q = yaml.safe_load((QUEUE / "tasks.yaml").read_text(encoding="utf-8"))
        task = next(t for t in q["tasks"] if t["id"] == r["id"])
        task["reference_images"] = [str(ROOT / ref) for ref in r["references"]]
        (QUEUE / "tasks.yaml").write_text(yaml.safe_dump(q, allow_unicode=True, sort_keys=False), encoding="utf-8")
        template = QUEUE / "templates" / (task["template"] + ".yaml")
        data = yaml.safe_load(template.read_text(encoding="utf-8"))
        data["reference_images"] = task["reference_images"]
        template.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False), encoding="utf-8")
    r.update(status="BUILTIN_CALL_DISPATCHED", calls=1, reference_sha256={ref: sha(ROOT / ref) for ref in r["references"]})
    save(p, m)


def record(key, source):
    p = BASE / "manifest.json"
    m = json.loads(p.read_text(encoding="utf-8"))
    r = next(r for r in m["assets"] if r["key"] == key)
    assert r["calls"] == 1 and r["status"] == "BUILTIN_CALL_DISPATCHED"
    out = BASE / r["kind"] / (r["id"] + ".png")
    assert not out.exists()
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, out)
    assert sha(out) == sha(Path(source))
    with Image.open(out) as im:
        bbox = im.getchannel("A").getbbox() if "A" in im.getbands() else None
        margins = [bbox[0] / im.width, bbox[1] / im.height, (im.width - bbox[2]) / im.width, (im.height - bbox[3]) / im.height] if bbox else []
        r.update(size=list(im.size), mode=im.mode, metrics={"full_alpha_bbox": list(bbox) if bbox else None, "margins": margins, "margin_10_percent_pass": bool(margins and min(margins) >= .1)})
    r.update(status="NATIVE_CANDIDATE_NOT_ADMITTED", output=out.relative_to(ROOT).as_posix(), sha256=sha(out), source_path=str(source), transparent=True, fallback_used=False, review_note="连体结构试拼候选，接缝/留白/尺度和实际画面待核，不等正式接入。")
    save(p, m)
    save(out.with_suffix(".meta.json"), {**r, "model": None, "provider": None, "cost": None, "formal_enabled": False})
    save(BASE / "resource-pack.json", {"status": "STRUCTURE_TRIAL_NOT_FORMAL", "assets": [r for r in m["assets"] if r.get("output")]})
    print(json.dumps({"key": key, "size": r["size"], "mode": r["mode"], "metrics": r["metrics"], "output": r["output"]}, ensure_ascii=False))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("action", choices=("prepare", "start", "record"))
    p.add_argument("--key")
    p.add_argument("--source")
    args = p.parse_args()
    if args.action == "prepare":
        prepare()
    elif args.action == "start":
        start(args.key)
    else:
        record(args.key, args.source)
