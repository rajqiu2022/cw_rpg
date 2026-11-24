extends "res://tests/helpers/v15_raw_world_oracle.gd"
## NEW SOURCE-ONLY v9c sibling of joint_v15_v8_world_raw_oracle.gd (1f45b8c3e84b936b89cb7faf5327c194b4364ec71f5f67b222cad2d3b39c625b).
## Original source is immutable; PENDING pins are not capture/Field/approval credit.
## New sibling binds inherited independent global-pixel/17-shoe implementation
## to ONLY the complete-v9c runtime root, never its disclosed baseline GPU inputs.
const ROOT: String = "res://art/maps/world_map_v15_complete_v9c/"

func configure(layout: Resource) -> bool:
	var configured: bool = super.configure(layout)
	for cell: Vector2i in tiles:
		var expected: String = ROOT + "chunks/r%d_c%d_walk.png" % [cell.y,cell.x]
		if tiles[cell].path != expected:
			errors.append("joint runtime cannot substitute old/local navigation: " + String(tiles[cell].path))
	valid = configured and errors.is_empty()
	return valid

func pixel_evidence(point: Vector2) -> Dictionary:
	# Explicit NEW source-contract sampler. The frozen legacy parent retains its
	# normalized*(size-1) rule and is NOT the oracle for this capture protocol.
	# No clamping: literal domain and nearest rounded pixel must both be valid.
	if not valid or not point.is_finite() or point.x<0 or point.y<0 or point.x>=WORLD_SIZE.x or point.y>=WORLD_SIZE.y:
		return {"clear":false,"kind":"invalid_or_outside","point":[point.x,point.y],"pixel_sampling":"round_world_pixel"}
	var pixel:=Vector2i(roundi(point.x),roundi(point.y))
	if pixel.x<0 or pixel.y<0 or pixel.x>=int(WORLD_SIZE.x) or pixel.y>=int(WORLD_SIZE.y):
		return {"clear":false,"kind":"rounded_pixel_outside","point":[point.x,point.y],"pixel":[pixel.x,pixel.y],"pixel_sampling":"round_world_pixel"}
	var cell:=Vector2i(pixel.x/CHUNK_SIZE.x,pixel.y/CHUNK_SIZE.y)
	var image: Image=_raw_tile(cell)
	if image==null: return {"clear":false,"kind":"missing_raw_tile","pixel":[pixel.x,pixel.y],"pixel_sampling":"round_world_pixel"}
	var local:=pixel-cell*CHUNK_SIZE
	var color: Color=image.get_pixelv(local)
	return {"clear":color.a>=.5 and maxf(color.r,maxf(color.g,color.b))>=.5,"kind":"raw_nav","point":[point.x,point.y],"pixel":[pixel.x,pixel.y],"chunk":[cell.x,cell.y],"rgba":[color.r,color.g,color.b,color.a],"path":tiles[cell].path,"sha256":tiles[cell].sha256,"pixel_sampling":"round_world_pixel"}

func verify_sources() -> bool:
	for tile: Dictionary in tiles.values():
		if not FileAccess.file_exists(tile.path) or FileAccess.get_sha256(tile.path) != tile.sha256:
			errors.append("joint current navigation mutated during phase: " + String(tile.path))
			valid = false
	return valid


