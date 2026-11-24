"""Mechanical NEW-only derivation of the Root-approved unchanged shore texture.

No image generation, crop, pixel processing, native publication or engine work.
"""
from pathlib import Path
import hashlib
import json
import math

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
PARENT = HERE / "quarter_native_geometry_garden_successor.gd"
AUTHOR = HERE / "garden_revision4/shore_landing_retry2/author_READY.json"
OUTPUT = HERE / "quarter_native_geometry_shore_visual_READY.gd"
RECEIPT = HERE / "garden_shore_visual_successor_READY.json"
PARENT_SHA = "5644d3bea2795d5d0ca8e244d7d970856cbed24511676e69c8c5a078742d8781"
AUTHOR_SHA = "937320f2e24d159e0dc5b023d72222be4118fb4e6d90e9558fa3cfba4ae55dfe"
SOURCES = {
    "res://art/modules/ground/road_stone_grass_edge.png": "527d8babc86461c7f37c49bbed9f6d7c348df827b483bfedd1f1e1b8117cacd3",
    "res://art/modules/ground/road_stone_grass_edge.png.import": "294459d47ab301dea317c12a5c07692b758a2673819dbd2e0fb507e30150ea33",
    "res://.godot/imported/road_stone_grass_edge.png-f8db63f60ecff0d9b90b7a21c86f93c4.ctex": "ebc846a88af85527c64ac0b82f58457f7ca32237f30e217d1f66e59b72d31838",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    assert not OUTPUT.exists() and not RECEIPT.exists(), "NEW-only outputs"
    original = PARENT.read_bytes()
    assert sha(original) == PARENT_SHA
    assert sha(AUTHOR.read_bytes()) == AUTHOR_SHA
    for path, expected in SOURCES.items():
        assert sha((GAME / path.removeprefix("res://")).read_bytes()) == expected, path
    poly = json.loads(AUTHOR.read_text(encoding="utf-8"))["scenes"][0]["water_polygons"][0]
    area2 = sum(a[0]*b[1]-b[0]*a[1] for a, b in zip(poly, poly[1:]+poly[:1]))
    assert len(poly) == 19 and area2 > 0, "screen-clockwise interior on tangent +y"
    poses = []
    for segment, (a, b) in enumerate(zip(poly, poly[1:]+poly[:1])):
        dx, dy = b[0]-a[0], b[1]-a[1]
        length = math.hypot(dx, dy)
        count = math.ceil(length/160)
        for tile in range(count):
            t = (tile+.5)/count
            poses.append({"segment": segment, "tile": tile, "position": [a[0]+dx*t, a[1]+dy*t], "rotation": math.atan2(dy, dx)})
    assert len(poses) == 37
    code = original.decode("utf-8")
    constants = "const SHORE_TEXTURE=\"res://art/modules/ground/road_stone_grass_edge.png\"\n"
    constants += "const SHORE_SOURCE_SHA=" + json.dumps(SOURCES, ensure_ascii=False) + "\n"
    constants += "const SHORE_WATER_POLYGON=" + json.dumps(poly, separators=(",", ":")) + "\n"
    constants += "# Fixed source y75 follows the real water boundary; source +y is inward.\n"
    constants += "# Whole unchanged 320x100 texture at uniform .5: 37.5 land /12.5 water.\n"
    constants += "const SHORE_POSES=[\n"
    for pose in poses:
        x, y = pose["position"]
        constants += f'\t[Vector2({x:.12f},{y:.12f}),{pose["rotation"]:.15f},{pose["segment"]},{pose["tile"]}],\n'
    constants += "]\n"
    code = code.replace('static func fail(error: String)', constants+'static func fail(error: String)', 1)
    old = '\treturn {"ok":true,"node":node}\n'
    assert code.count(old) == 1
    new = '\tvar shore: Dictionary=attach_garden_shore_visual(node,raw.polygon)\n\tif shore.get("ok")!=true: node.free();return shore\n'+old
    code = code.replace(old, new, 1)
    appended = '''
# Strict visual-only successor: never changes native Scene, mask, water polygon,
# entries, bodies, walk support, navigation, NPCs, portals or authored routes.
static func shore_source_paths() -> Array[String]:
	var paths: Array[String]=[]
	for path: String in SHORE_SOURCE_SHA: paths.append(path)
	return paths

static func attach_garden_shore_visual(water: Polygon2D,polygon: PackedVector2Array) -> Dictionary:
	if water==null or water.name!="APGardenSameCaptureWater" or polygon.size()!=SHORE_WATER_POLYGON.size(): return fail("AP_SHORE_REAL_WATER_OWNER")
	for i: int in range(polygon.size()):
		if polygon[i]!=Vector2(SHORE_WATER_POLYGON[i][0],SHORE_WATER_POLYGON[i][1]): return fail("AP_SHORE_EXACT_NATIVE_19_SEGMENTS")
	for path: String in SHORE_SOURCE_SHA:
		if FileAccess.get_sha256(path)!=SHORE_SOURCE_SHA[path]: return fail("AP_SHORE_EXACT_THREE_MEDIA_LEAVES "+path)
	var texture: Texture2D=ResourceLoader.load(SHORE_TEXTURE) as Texture2D
	if texture==null or texture.get_size()!=Vector2(320,100): return fail("AP_SHORE_UNCHANGED_FULL_TEXTURE_320_100")
	var group:=Node2D.new();group.name="APGardenShoreVisualOnly"
	for pose: Array in SHORE_POSES:
		var sprite:=Sprite2D.new();sprite.name="Shore_%02d_%02d"%[pose[2],pose[3]]
		sprite.texture=texture;sprite.centered=false;sprite.offset=Vector2(-160,-75)
		sprite.scale=Vector2(.5,.5);sprite.position=pose[0];sprite.rotation=pose[1]
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.z_index=1
		sprite.set_meta("ap_visual_only",true);sprite.set_meta("native_water_segment",pose[2])
		group.add_child(sprite)
	group.set_meta("ap_shore_receipt",{"tiles":37,"native_segments":19,"uniform_scale":.5,"source_boundary_y":75,"stone_water_side":12.5,"grass_land_side":37.5,"no_geometry_delta":true,"no_positive_support":true,"no_image_edit_or_crop":true})
	water.add_child(group)
	return {"ok":true,"visual_shore_tiles":37}
'''
    code += appended
    output = code.encode("utf-8")
    # Invert the precise two insertions and final append, not an approximate diff.
    inverse = code.removesuffix(appended).replace(new, old, 1).replace(constants, "", 1).encode("utf-8")
    assert inverse == original
    receipt = {
        "schema_version": 1,
        "status": "SOURCE_READY_PENDING_ROOT_SINGLE_IMAGE_NOT_FORMAL_FIELD",
        "parent_path": "res://"+PARENT.relative_to(GAME).as_posix(),
        "parent_sha256": PARENT_SHA,
        "candidate_path": "res://"+OUTPUT.relative_to(GAME).as_posix(),
        "candidate_sha256": sha(output),
        "whole_source_inverse": True,
        "fixed_texture_source_sha256": SOURCES,
        "native_author_sha256": AUTHOR_SHA,
        "native_water_polygon": poly,
        "fixed_poses": poses,
        "tile_count": len(poses),
        "full_source_size": [320, 100],
        "uniform_scale": 0.5,
        "full_world_size": [160, 50],
        "source_y75_on_native_water_line": True,
        "stone_side_into_closed_water": 12.5,
        "grass_side_on_land": 37.5,
        "original_54_native_11_solid_2299_routes_4_npcs_unchanged": True,
        "no_crop_no_pixel_edit_no_Line2D_no_AE_film_no_geometry_replay": True,
        "renderer_scope": "37 child Sprite2D of existing z-18 water Polygon at relative z1; below all original foot-sorted bridge/pavilion/actors",
        "old_actual_11440_technical_pass_ART_reject_preserved": True,
        "unrun": ["Godot parse", "Root same overview picture", "Formal Field/Physics/travel"],
    }
    OUTPUT.write_bytes(output)
    RECEIPT.write_text(json.dumps(receipt, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"helper_sha256": sha(output), "receipt_sha256": sha(RECEIPT.read_bytes()), "tiles": len(poses), "source_inverse": True}))


if __name__ == "__main__":
    main()
