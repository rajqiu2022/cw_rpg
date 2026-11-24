"""Explicit Family/Temple adapter derived from the fixed civic source reader.
No legacy preparation, current observation, image decoding or production write.
"""
from pathlib import Path
import hashlib
N=Path(__file__).resolve().parent
sha=lambda raw:hashlib.sha256(raw).hexdigest()
parent=(N/'terminal_adapter03_market.gd').read_bytes()
assert sha(parent)=='301f040b7909ba78cad8b20324fd2834c2dee747e0b5017b400fc4d35c29c02d'
text=parent.decode().replace('pure_portal_projection.gd','pure_family_portal_projection.gd')
text=text.replace('var dimensions: Vector2 = png_size(texture)','var dimensions: Vector2 = family_texture_size(texture, declared_sources)')
text=text.replace('var all_polygons: Array = []','''var all_polygons: Array = []
	if logical not in ["luoyang_estate_riverside_20261021ai", "ch4_s4_ancient_temple"]: return fail("FAMILY_LOGICAL_ID")
	if var_to_bytes(source.map_layout.blockers) != var_to_bytes(payload.parent_blockers): return fail("FAMILY_ORIGINAL_BLOCKERS")
	var native: Dictionary = family_parent_solids(payload, terminal)
	if native.get("ok") != true: return native
	all_polygons.append_array(native.polygons)''')
text+='''
static func family_texture_size(path: String, pins: Dictionary) -> Vector2:
	if path.ends_with(".png"): return png_size(path)
	# The existing hall dark-backdrop is an AtlasTexture, not a PNG. Its source
	# is independently pinned; query the declared region without get_image().
	if not path.ends_with(".tres") or not pins.has(path): return Vector2.ZERO
	var atlas: AtlasTexture = load(path) as AtlasTexture
	if atlas == null or atlas.atlas == null or not atlas.filter_clip or atlas.margin != Rect2(): return Vector2.ZERO
	if not pins.has(atlas.atlas.resource_path) or atlas.region.size.x <= 0 or atlas.region.size.y <= 0: return Vector2.ZERO
	return atlas.region.size

static func family_parent_solids(payload: Dictionary, terminal: Dictionary) -> Dictionary:
	var blockers: Array = payload.parent_blockers
	var polygons: Array = payload.parent_solids
	if blockers.size() != polygons.size(): return fail("FAMILY_PARENT_BODY_SEQUENCE_COUNT")
	var owners: Dictionary = {}
	for row: Dictionary in payload.parent_navigation:
		var id: String = String(row.get("id", ""))
		if id.is_empty() or owners.has(id): return fail("FAMILY_PARENT_OWNER_ID")
		owners[id] = true
	var ordered: Array = []
	for index: int in blockers.size():
		var id: String = String(blockers[index].get("id", ""))
		var owner: String = id
		if id in ["estate_gate_jamb_0", "estate_gate_jamb_1"]: owner = "estate_mansion_courtyard_gate"
		elif "_solid_" in id: owner = id.get_slice("_solid_", 0)
		if not owners.has(owner): return fail("FAMILY_PARENT_BODY_OWNER", id)
		if not polygons[index] is PackedVector2Array or polygons[index].size() < 3: return fail("FAMILY_PARENT_POLYGON_TYPE", id)
		# These are the already-published complete native polygons, paired by the
		# exact immutable blocker ordinal. No rectangle recomputation/ULP drift.
		terminal.solids.append({"id": id, "owner_id": owner, "points_px": polygons[index].duplicate()})
		ordered.append(polygons[index].duplicate())
	return {"ok": true, "polygons": ordered}
'''
# Parent bodies are already the full original sequence. Only owner inline new
# polygons follow; these source rows deliberately have zero collision_size_px.
text=text.replace('## Cold source compiler adapter. No legacy owner preparation and no live Field.','## Exact Family/Temple cold source adapter. No old owner and no live Field.')
out=N/'terminal_adapter04_family.gd';assert not out.exists();out.write_text(text,encoding='utf8',newline='\n')
print(sha(out.read_bytes()))
