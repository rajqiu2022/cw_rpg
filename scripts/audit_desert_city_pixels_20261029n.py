"""Read-only native-pixel audit. Never changes artwork, scenes, or imports.

Counts source texels against logical pixels, then against the documented 0.9
follow camera at a 1920x1080 viewport. Alpha bounds describe visible coverage,
not physical footprints. Instanced scenes, shaders and animated frames are not
silently counted as audited sprites. This is not an art acceptance test.
"""
import hashlib
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/staging/desert_city_pixel_audit_20261029n"
SCENES = {
    "redrock": "game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn",
    "desert": "game/scenes/drafts/desert_town_20261029d/desert_town.tscn",
}
SEEN = {}


def read(path):
    path = Path(path)
    data = path.read_bytes()
    SEEN[path.relative_to(ROOT).as_posix()] = {
        "sha256": hashlib.sha256(data).hexdigest(),
        "size": len(data), "mtime_ns": path.stat().st_mtime_ns,
    }
    return data


def props(text):
    return dict(re.findall(r"^([^\n=]+?)\s*=\s*(.+)$", text, re.M))


def nums(text):
    return [float(x) for x in re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", text.split("(", 1)[-1])]


def media(path):
    local = ROOT / "game" / path.removeprefix("res://")
    read(local)
    with Image.open(local) as im:
        size = list(im.size)
        alpha = im.convert("RGBA").getchannel("A")
        # A128 is coverage only. It does not imply permission to erase A1..127.
        box = alpha.point(lambda x: 255 if x >= 128 else 0).getbbox()
    return {"texture": path, "png_size": size, "alpha128_bbox": box,
            "source_sha256": SEEN[local.relative_to(ROOT).as_posix()]["sha256"]}


def audit_scene(rel):
    source = read(ROOT / rel).decode("utf-8-sig").replace("\r\n", "\n")
    ext = {}
    for header in re.findall(r"^\[ext_resource ([^\n]+)\]", source, re.M):
        a = dict(re.findall(r'(\w+)="([^"]+)"', header))
        ext[a["id"]] = a
    nodes, rows, exclusions = {}, [], []
    for match in re.finditer(r"^\[node ([^\n]+)\]\n(.*?)(?=^\[|\Z)", source, re.M | re.S):
        head, body = match.groups()
        a = dict(re.findall(r'(\w+)="([^"]+)"', head))
        p = props(body)
        parent = a.get("parent", "")
        key = "." if not parent else (a["name"] if parent == "." else parent + "/" + a["name"])
        parent_scale = nodes.get(parent, {}).get("scale", [1, 1])
        local_scale = nums(p.get("scale", "Vector2(1, 1)"))
        scale = [abs(x*y) for x, y in zip(parent_scale, local_scale)]
        assert len(scale) == 2
        assert "transform" not in p and float(p.get("rotation", "0")) == 0, key
        nodes[key] = {"scale": scale}
        line = source[:match.start()].count("\n") + 1
        if a.get("type") != "Sprite2D":
            if "instance=" in head or ("texture" in p and a.get("type") != "Sprite2D"):
                exclusions.append({"node": key, "line": line, "reason": "instance_or_non_sprite_not_measured"})
            continue
        texture = re.fullmatch(r'ExtResource\("([^"]+)"\)', p.get("texture", ""))
        if not texture or texture[1] not in ext or ext[texture[1]]["type"] != "Texture2D":
            exclusions.append({"node": key, "line": line, "reason": "no_direct_texture"})
            continue
        data = media(ext[texture[1]]["path"])
        box = data["alpha128_bbox"]
        region = nums(p["region_rect"]) if p.get("region_enabled") == "true" and "region_rect" in p else None
        if region and region[2] > 0 and region[3] > 0 and box:
            x, y, w, h = region
            box = [max(box[0], x), max(box[1], y), min(box[2], x+w), min(box[3], y+h)]
        coverage = [max(0, box[2]-box[0]), max(0, box[3]-box[1])] if box else [0, 0]
        rows.append({**data, "node": key, "line": line, "global_scale": scale,
                     "region": region, "visible_source_span": coverage,
                     "visible_logical_span": [round(x*y, 3) for x, y in zip(coverage, scale)],
                     "screen_px_per_texel_at_1080p_follow": [round(x*.9, 6) for x in scale],
                     "logical_upscale": max(scale) > 1.00001,
                     "screen_upscale_at_1080p_follow": max(scale)*.9 > 1.00001})
    assert rows, "No sprites parsed: audit incomplete, not a passing result."
    return {"scene": rel, "scene_sha256": SEEN[rel]["sha256"], "follow_zoom": .9,
            "sprite_rows": rows, "exclusions": exclusions,
            "summary": {"sprites_measured": len(rows),
                        "logical_upscale_instances": sum(r["logical_upscale"] for r in rows),
                        "screen_upscale_instances": sum(r["screen_upscale_at_1080p_follow"] for r in rows)}}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    target = OUT / "audit.json"
    assert not target.exists(), "Preserve the original audit; do not overwrite it."
    scenes = {name: audit_scene(rel) for name, rel in SCENES.items()}
    spec_path = ROOT / "game/build/three_towns_world_20261029j_system01/world_spec.json"
    spec = json.loads(read(spec_path))
    landmarks = []
    for row in spec["landmarks"]:
        if row["id"] not in ["redrock_town", "desert_town"]:
            continue
        landmarks.append({"id": row["id"], "door_foot_px": row["door_foot_px"],
                          "sprites": [{**s, **media(s["texture"])} for s in row["sprites"]]})
    layout = read(ROOT / "game/data/maps/world_map_jianghu_layout_v15.tres").decode("utf-8")
    sample = re.search(r'"id": "compound_luoyang",(.*?)(?=\n},)', layout, re.S).group(1)
    texture = re.search(r'"texture": "([^"]+)"', sample)[1]
    render_size = nums(re.search(r'"render_size_px": (Vector2\([^\n]+\))', sample)[1])
    reference = {**media(texture), "render_size_px": render_size,
                 "source": "game/data/maps/world_map_jianghu_layout_v15.tres", "role": "independent_generated_compound"}
    for rel, prior in SEEN.items():
        p = ROOT / rel
        assert hashlib.sha256(p.read_bytes()).hexdigest() == prior["sha256"] and p.stat().st_mtime_ns == prior["mtime_ns"], rel
    result = {"status": "ART_REJECTED_REBUILD_REQUIRED", "scope": "direct static sprites in two scenes + two world additions; excludes inherited/animated sprites and shader UV density",
              "method": "static measured PNG/ancestor scale; 1920x1080 stretch factor 1, follow zoom 0.9; no new runtime capture", "scenes": scenes,
              "world_landmarks": landmarks, "luoyang_world_reference": reference, "read_only_sources_unchanged": SEEN}
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n", "utf-8")
    print(json.dumps({"report": str(target), "sources_unchanged": len(SEEN), "scenes": {k:v["summary"] for k,v in scenes.items()}}, ensure_ascii=False))
    for name, scene in scenes.items():
        for row in scene["sprite_rows"]:
            if row["logical_upscale"]:
                print(name, row["node"], row["png_size"], row["visible_source_span"], row["global_scale"], row["visible_logical_span"])


if __name__ == "__main__":
    main()
