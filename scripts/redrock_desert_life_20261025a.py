"""Isolated, one-call-per-asset desert life production ledger. No API runner."""
import argparse
import hashlib
import json
import os
import re
import shutil
import sys
from pathlib import Path

import yaml
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/raw/redrock_desert_life_20261025a"
STAGE = ROOT / "assets/staging/redrock_desert_life_20261025a"
QUEUE = STAGE / "production/prompts"
REFS = ["assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png",
        "assets/raw/redrock_joint_trial_20261023e/building/redrock_joint_20261023e_core_v1.png"]
COMMON = """Use case: stylized-concept
Asset type: ONE independent transparent 2.5D wuxia RPG map component, a scene/world object, NOT a backpack icon, NOT a whole scene or collage.
References: Image 1 is the approved Redrock canyon-town masterplan, used ONLY for dry red-sandstone town life and subdued palette. Image 2 is an existing native gate module, used for consistent elevated orthographic CAMERA, painterly detail, small masonry scale, warm upper-left daylight and restrained right-side depth. Generate a NEW subject, do not copy the gate or crop the plan. Horizontal front facade/baseline with a short right depth face and visible top. No vanishing point, horizon or dramatic low camera. Matte dusty red sandstone, faded ochre plaster, weathered dark timber and coarse tan cloth; hand-painted historical game art with readable volumes at map scale. No orange gloss, photo noise or outlines like a sticker. Redrock uses FLAT rooftops/parapets and straight flat timber shelters, never Chinese curved tiled eaves, domes, European roofs or lush oasis gardens.
ONE subject only; complete geometry, all feet, roof ends, branches and attached shade visible. Genuine RGBA transparent background. No terrain rectangle, floor island, canyon backdrop, detached rocks/dust, mist, halo or floating shadow. Keep the entire object and ALL positive-alpha pixels within the CENTRAL 60% of BOTH image dimensions: leave at least 20% completely alpha-zero margin on ALL FOUR SIDES. Small attached contact shade only, zero-alpha beyond. Do not zoom to fill the image. No people, animals, lettering, sign text, symbols, arrows, numbers, UI, labels, watermark or extra variants.
"""
ITEMS = {
    "inn": ("building", "赤岩·平顶商旅驿舍", "驿舍马院 / 沿街接待建筑", """ONE modest two-level roadside caravan INN building, not a walled compound. Broad low rectangular red sandstone lower floor, faded dusty ochre plaster patches, flat earth roof with low solid parapet, small upper lodging room set back toward the rear. Plain dark wooden beams project just a little from the walls. Main FRONT entrance center-left is a single clearly readable dark timber door, adult door height roughly one third of full building height; door threshold at the same ground baseline as the two outer front corners. Two narrow shuttered windows, one small flat tan-cloth shade above entrance, held by two thin posts without blocking the door approach. A short simple stone step only. No enclosure, courtyard paving, stairs blocking the entrance, crenellations, tower, flag, hanging sign or decorative tiled roof. Building silhouette about 1.6 times wider than high. Landscape canvas, subject centered and modestly sized with huge transparent margins."""),
    "repair_shed": ("building", "赤岩·商队修车棚", "石作修坊 / 开敞作业棚", """ONE open-front caravan cart REPAIR SHED. Low red-sandstone back wall and short right return wall, four plain dark timber posts on individual small stone footings, a simple FLAT dark rough-plank roof with timber crossbeams and no tiles. Clearly open front work bay, large enough for an adult and cart axle, front passage unblocked and transparent down to ground between posts. A single worn wagon wheel leans INSIDE the back wall, two planks stacked along rear wall only; no freestanding furniture outside. Believable roof/post load path, all roof corners and footings complete. Broad low silhouette about twice as wide as high. No building enclosing the front, no foreground fence, no tower, no rubble or scenery around the base. Landscape canvas and generous transparent margins."""),
    "cistern": ("building", "赤岩·蓄水井棚", "蓄水小院 / 独立取水小建筑", """ONE compact covered water cistern/well structure for a dry desert town. A low circular RED SANDSTONE well curb with a dark water opening, two sturdy timber uprights and a simple rope-and-wood spindle directly over the well, one modest bucket tied to the rope inside the curb. A small FLAT rectangular reed-and-plank shade roof on four thin posts with stone footings, no tiled sloping roof. No long drinking trough (already exists), no garden, no pond, no water spilling, no courtyard walls or broad paving base. Well top and crank clearly readable, entrance between front posts left empty for a player to approach. Whole compact module roughly square, 20% transparent border on every side including bucket and contact shade."""),
    "water_jars": ("scene_prop", "赤岩·封口储水罐组", "蓄水小院与驿舍 / 放置物件", """ONE compact usable scene prop cluster: three large dull earthenware WATER STORAGE JARS on a very low dark wooden slatted support, not a treasure chest or bag icon. One tall reddish-brown amphora-shaped jar with two short handles and a rope-secured cloth lid, a squat ochre lidded jar beside it, and a smaller unglazed cup-shaped vessel tucked behind. Simple believable pottery; no ornament, glow, gilding, green plants, spilt liquid or loose particles. Object height about adult waist, cluster width about an adult's outstretched arms. Elevated map camera with visible jar tops and restrained right side. All jars grounded to one compact footprint; no floor patch. Square canvas; object small in center, fully transparent wide margins."""),
    "wheelbench": ("scene_prop", "赤岩·车轮轴木工作台", "石作修坊 / 可调查场景实体", """ONE low wheelwright WORKBENCH made from heavy weathered dark timber, with a half-repaired wooden wagon wheel clamped upright at the BACK of the table, a short axle laid lengthwise on the tabletop, a small mallet and two neatly arranged wedges. Legs and braces visible, believable joinery, no free-floating tools, no loose separate kit layout. Standing wheel integrated into a single workstation footprint. Work surface roughly adult waist high; readable silhouette at small map scale. Worn dust and dark iron straps, restrained detail. No anvil, forge, sparks, fire, person, canopy, roof or ground patch. Landscape canvas, whole workstation including wheel and legs within central60% and transparent margins."""),
    "dry_tree": ("vegetation", "赤岩·风蚀旱树", "阶街边缘与峡壁层台 / 植被", """ONE complete small desert TREE with a gnarled gray-brown trunk and sparse dusty olive-brown narrow leaves at the branch tips, irregular wind-shaped crown, visibly dry open branching structure. Mature tree height about twice an adult, short sturdy trunk, restrained natural silhouette and muted foliage; not a giant baobab, not a palm, cactus, pine or lush broad green tree. Roots meet a single small compact base with no turf, soil island or scattered pebbles. See elevated crown top consistently with map reference. All thin branches, roots and leaves comfortably enclosed inside20% transparent margins; no detached drifting leaves or atmosphere. Portrait or square canvas, tree small and centered, no scenery."""),
    "dry_shrub": ("vegetation", "赤岩·荒漠枯黄灌木", "道路侧肩与岩缝 / 低矮植被", """ONE low compact desert SHRUB clump, several fine woody branches from a shared center with sparse dusty straw-yellow and gray-olive leaves and a few short dried stalks. Height knee-to-thigh high for an adult. Distinct open irregular low silhouette, no thick tree trunk, no flowers, berries, lush grass, cactus or trailing vines. Entire root contact region tiny and attached, no ground island, scattered stones or flying seeds. Restrained hand-painted game texture matching the gate's detail and lighting. Square transparent canvas with shrub in central50% of width and height, completely empty transparent border including smallest twig."""),
    "ore_cluster": ("scene_prop", "赤岩·岩矿调查点", "石作修坊外与野外岩肩 / 采集实体候选", """ONE small grounded RED SANDSTONE ROCK OUTCROP with a few dull gray ironlike mineral seams embedded in its broken front face. One main waist-high angular rock and two tightly attached smaller chunks, compact naturally joined footprint. Layered red ochre sandstone matching the canyon architecture, weathered edges, mineral veins subdued dark gray; no large bright crystal spikes, gold, magic light or loot particles. Scene/world mining investigation point, NOT inventory icon or prize illustration. Camera top and front visible like existing module; no surrounding landscape, broad soil base, shrubs or tools. Landscape or square canvas, object occupies central55% at most, all geometry/shade surrounded by20% alpha0 on every side."""),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def prepare():
    assert not (BASE / "manifest.json").exists(), "Do not replace a registered batch"
    (QUEUE / "templates").mkdir(parents=True)
    sys.path.insert(0, str(ROOT / "scripts"))
    import gen_assets as renderer
    renderer.TEMPLATES_DIR = QUEUE / "templates"
    template = "redrock_desert_placeable_20261025a"
    refs = [str(ROOT / p) for p in REFS]
    (QUEUE / "templates" / (template + ".yaml")).write_text(yaml.safe_dump({"name": template, "prompt_template": "{asset_prompt}", "size": "1536x1024", "quality": "high", "background": "transparent", "reference_images": refs, "require_reference_images": True}, allow_unicode=True, sort_keys=False), encoding="utf-8")
    rows, tasks = [], []
    for key, (kind, label, use, detail) in ITEMS.items():
        ident = f"redrock_desert_20261025a_{key}_v1"
        prompt = COMMON + "\nRequested subject:\n" + detail
        path = QUEUE / (ident + ".txt")
        path.write_text(prompt, encoding="utf-8")
        spec = renderer.render_template(template, {"asset_prompt": prompt}, {})
        assert spec["prompt"] == prompt.strip()
        rows.append({"key": key, "id": ident, "kind": kind, "label": label, "intended_use": use, "prompt": path.relative_to(ROOT).as_posix(), "prompt_sha256": sha(path), "references": REFS, "reference_sha256": {p: sha(ROOT / p) for p in REFS}, "status": "REGISTERED", "calls": 0})
        tasks.append({"id": ident, "template": template, "skip": True, "execution_backend": "builtin_image_gen", "attempt_budget": 1, "retries_allowed": False, "cli_fallback_allowed": False, "transparent_background": True, "reference_images": refs, "vars": {"asset_prompt": prompt}})
    (QUEUE / "tasks.yaml").write_text(yaml.safe_dump({"tasks": tasks}, allow_unicode=True, sort_keys=False), encoding="utf-8")
    protected = [ROOT / "prompts/tasks.yaml", ROOT / "scripts/gen_assets.py", ROOT / "game/project.godot"] + [ROOT / p for p in REFS]
    for rel in ("game/art/modules/redrock_joint_editor_20261023f", "game/scenes/drafts/redrock_joint_editor_20261023f", "game/scripts/drafts/redrock_joint_editor_20261023f"):
        protected.extend(p for p in (ROOT / rel).rglob("*") if p.is_file())
    saves = Path(os.environ["APPDATA"]) / "Godot/app_userdata/云影侠传"
    protected += [p for p in saves.rglob("save*") if p.is_file()]
    save(STAGE / "protected-before.json", [{"path": str(p), "sha256": sha(p), "bytes": p.stat().st_size, "mtime_ns": p.stat().st_mtime_ns} for p in sorted(set(protected))])
    html = (ROOT / "docs/equipment-skill-catalog.html").read_text("utf-8")
    catalog = json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', html, re.S).group(1))
    save(STAGE / "catalog-before.json", catalog)
    save(BASE / "manifest.json", {"batch": "redrock_desert_life_20261025a", "status": "REGISTERED", "assets": rows, "backend": "builtin_image_gen", "model": None, "provider": None, "cost": None, "formal_enabled": False})
    save(STAGE / "preflight.json", {"passed": True, "rendered_prompts": len(rows), "queue_isolated": True, "root_queue_written": False, "fallback_allowed": False, "references": {p: sha(ROOT / p) for p in REFS}})
    print(json.dumps({"registered": len(rows), "queue": str(QUEUE)}, ensure_ascii=False))


def start(key):
    m = json.loads((BASE / "manifest.json").read_text("utf-8"))
    row = next(r for r in m["assets"] if r["key"] == key)
    assert row["status"] == "REGISTERED" and row["calls"] == 0
    assert sha(ROOT / row["prompt"]) == row["prompt_sha256"]
    assert all(sha(ROOT / p) == digest for p, digest in row["reference_sha256"].items())
    row.update(status="BUILTIN_CALL_DISPATCHED", calls=1)
    save(BASE / "manifest.json", m)
    print((ROOT / row["prompt"]).read_text("utf-8"))


def record(key, source):
    m = json.loads((BASE / "manifest.json").read_text("utf-8"))
    row = next(r for r in m["assets"] if r["key"] == key)
    assert row["status"] == "BUILTIN_CALL_DISPATCHED" and row["calls"] == 1
    out = BASE / row["kind"] / (row["id"] + ".png")
    assert not out.exists()
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, out)
    assert sha(out) == sha(Path(source))
    with Image.open(out) as im:
        assert im.mode == "RGBA"
        bbox = im.getchannel("A").getbbox()
        margins = [bbox[0] / im.width, bbox[1] / im.height, (im.width - bbox[2]) / im.width, (im.height - bbox[3]) / im.height]
        row.update(size=list(im.size), mode=im.mode, metrics={"full_alpha_bbox": list(bbox), "margins": margins, "margin_10_percent_pass": min(margins) >= .1, "corners_alpha": [im.getpixel(xy)[3] for xy in ((0, 0), (im.width-1, 0), (0, im.height-1), (im.width-1, im.height-1))]})
    row.update(status="NATIVE_CANDIDATE_NOT_ADMITTED", output=out.relative_to(ROOT).as_posix(), sha256=sha(out), source_path=str(source), transparent=True, fallback_used=False, review_note=row["intended_use"] + "。内置原生独立透明组件；未绑定交互、碰撞或正式场景，实际比例与遮挡待装配核验。")
    save(BASE / "manifest.json", m)
    save(out.with_suffix(".meta.json"), {**row, "backend": "builtin_image_gen", "model": None, "provider": None, "cost": None, "formal_enabled": False, "local_pixel_processing": False})
    save(BASE / "resource-pack.json", {"status": "DESERT_LIFE_RAW_CANDIDATES_NOT_FORMAL", "assets": [r for r in m["assets"] if r.get("output")]})
    print(json.dumps({k: row[k] for k in ("key", "size", "metrics", "output")}, ensure_ascii=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("prepare", "start", "record"))
    parser.add_argument("--key")
    parser.add_argument("--source")
    args = parser.parse_args()
    if args.action == "prepare": prepare()
    elif args.action == "start": start(args.key)
    else: record(args.key, args.source)
