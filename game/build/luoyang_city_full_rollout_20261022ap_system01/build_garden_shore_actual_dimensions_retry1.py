"""Root-authorized correction of original PNG size, NEW outputs only."""
from pathlib import Path
from PIL import Image
import hashlib
import json

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    previous = HERE / "quarter_native_geometry_shore_visual_READY.gd"
    candidate = HERE / "quarter_native_geometry_shore_actual_dimensions_retry1_READY.gd"
    receipt = HERE / "garden_shore_visual_actual_dimensions_retry1_READY.json"
    assert not candidate.exists() and not receipt.exists()
    before = previous.read_bytes()
    assert sha(before) == "6279cd6e4596e217b4c61830d69d92c672bf115be5a39a46b5046e728365c384"
    old_receipt = HERE / "garden_shore_visual_successor_READY.json"
    assert sha(old_receipt.read_bytes()) == "c96a7d28676af99c1a7c32fe3ad81c52a634f58afc2e4089c99d1ec99221aa31"
    original = json.loads(old_receipt.read_text(encoding="utf-8"))
    png = GAME / "art/modules/ground/road_stone_grass_edge.png"
    assert sha(png.read_bytes()) == original["fixed_texture_source_sha256"]["res://art/modules/ground/road_stone_grass_edge.png"]
    with Image.open(png) as image:
        assert image.size == (317, 109), "Actual source IHDR, never resize/crop"
    replacements = [
        {"old": "# Whole unchanged 320x100 texture at uniform .5: 37.5 land /12.5 water.", "new": "# Whole unchanged 317x109 texture at uniform .5: 37.5 land /17 water."},
        {"old": 'if texture==null or texture.get_size()!=Vector2(320,100): return fail("AP_SHORE_UNCHANGED_FULL_TEXTURE_320_100")', "new": 'if texture==null or texture.get_size()!=Vector2(317,109): return fail("AP_SHORE_UNCHANGED_FULL_TEXTURE_317_109")'},
        {"old": "sprite.offset=Vector2(-160,-75)", "new": "sprite.offset=Vector2(-158.5,-75)"},
        {"old": '"stone_water_side":12.5', "new": '"stone_water_side":17.0'},
    ]
    text = before.decode("utf-8")
    for row in replacements:
        assert text.count(row["old"]) == 1
        text = text.replace(row["old"], row["new"], 1)
    inverse = text
    for row in reversed(replacements):
        assert inverse.count(row["new"]) == 1
        inverse = inverse.replace(row["new"], row["old"], 1)
    assert inverse.encode("utf-8") == before
    # Reconstruct the original5644 completely after removing this visual layer.
    base_inverse = inverse[:inverse.index("\n# Strict visual-only successor:")]
    const_begin = base_inverse.index('const SHORE_TEXTURE=')
    const_end = base_inverse.index('static func fail(error: String)')
    base_inverse = base_inverse[:const_begin]+base_inverse[const_end:]
    inserted = '\tvar shore: Dictionary=attach_garden_shore_visual(node,raw.polygon)\n\tif shore.get("ok")!=true: node.free();return shore\n'
    assert base_inverse.count(inserted) == 1
    base_inverse = base_inverse.replace(inserted, "", 1)
    base = HERE / "quarter_native_geometry_garden_successor.gd"
    assert sha(base.read_bytes()) == original["parent_sha256"]
    assert base_inverse.encode("utf-8") == base.read_bytes()
    output = text.encode("utf-8")
    result = dict(original)
    result.update({
        "status": "SOURCE_READY_ACTUAL_DIMENSIONS_CORRECTED_PENDING_ROOT_SINGLE_IMAGE_NOT_FIELD",
        "candidate_path": "res://"+candidate.relative_to(GAME).as_posix(),
        "candidate_sha256": sha(output),
        "full_source_size": [317, 109],
        "full_world_size": [158.5, 54.5],
        "stone_side_into_closed_water": 17.0,
        "whole_source_inverse": True,
        "original5644_whole_source_inverse": True,
        "previous_visual_path": "res://"+previous.relative_to(GAME).as_posix(),
        "previous_visual_sha256": sha(before),
        "previous_visual_whole_source_inverse": True,
        "exact_replacements_from6279": replacements,
        "Root_authority": "Root explicitly confirms real317x109 original PNG dimensions, uniform.5, xoffset-158.5/sourcey75, stone17; no more general visual iteration.",
        "cause": "The real unchanged PNG is317x109; previous guard demanded320x100 and therefore returned AP_SHORE_UNCHANGED_FULL_TEXTURE_320_100. This changes only mistaken dimensional assertions/alignment; not pixels or the37poses.",
        "failed_actual_preserved": "res://build/luoyang_city_full_rollout_20261022ap_qa01/garden_shore_visual_overview/46196_2746/result.json",
        "fixed_poses_and_native19_unchanged_from6279": True,
        "renderer_scope": "37 whole317x109 Sprite2D at uniform.5/sourceoffset(-158.5,-75), same z/order/native19; no image operations",
        "unrun": ["Root corrected single image", "Formal Field/Physics/travel"],
    })
    candidate.write_bytes(output)
    receipt.write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"candidate_sha256": sha(output), "receipt_sha256": sha(receipt.read_bytes()), "exact_replacements": len(replacements), "previous6279_whole_inverse": True, "original5644_whole_inverse": True, "actual_unchanged_source_size": [317,109]}))


if __name__ == "__main__":
    main()
