extends RefCounted

## Isolated QA draft: never call the asset pipeline's resampling helper.
## Active production QA remains frozen until producer explicitly adopts this.
const ALPHA_ID := "RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
const OPAQUE_ID := "RGBA8_STRAIGHT_LANCZOS_V1"
const OLD_WHOLE_METHOD := "native Image.resize INTERPOLATE_LANCZOS on one raw RGBA8 frame; no temporal averaging/tolerance"
const OLD_BODY_METHOD := "Image.resize INTERPOLATE_LANCZOS spatial reconstruction per individual native RGBA8 frame; no temporal averaging or tolerance"
const OPAQUE_METHOD := "native opaque Image.resize INTERPOLATE_LANCZOS on one raw RGBA8 frame; no temporal averaging/tolerance"
const ALPHA_WHOLE_METHOD := "RGBAF premultiply RGB*alpha -> Lanczos -> unpremultiply alpha>0 -> RGBA8; one immutable native frame"
const ALPHA_BODY_METHOD := "RGBAF premultiply RGB*alpha -> native Lanczos -> unpremultiply alpha>0 -> RGBA8; no alpha clipping or temporal averaging/tolerance"

static func method_kind(record: Dictionary, manifest_recipe: Dictionary = {}) -> String:
	if not record.get("resampling_method") is String: return "REJECT"
	var method := String(record.resampling_method)
	var identity := String(record.get("algorithm_identity", ""))
	if not identity.is_empty() and identity not in [ALPHA_ID, OPAQUE_ID]: return "REJECT"
	if manifest_recipe.has("algorithm_identity") and (not manifest_recipe.algorithm_identity is String or manifest_recipe.algorithm_identity != identity): return "REJECT"
	if method == OLD_BODY_METHOD or method == OLD_WHOLE_METHOD:
		return "STRAIGHT" if identity.is_empty() and not record.has("alpha_aware_transparent_body") else "REJECT"
	if method == OPAQUE_METHOD:
		return "OPAQUE_STRAIGHT" if identity == OPAQUE_ID and typeof(record.get("alpha_aware_transparent_body")) == TYPE_BOOL and record.alpha_aware_transparent_body == false else "REJECT"
	if method == ALPHA_BODY_METHOD:
		var body_flag_matches: bool = not record.has("alpha_aware_transparent_body") or (typeof(record.alpha_aware_transparent_body) == TYPE_BOOL and record.alpha_aware_transparent_body == true)
		return "ALPHA_AWARE" if identity == ALPHA_ID and body_flag_matches else "REJECT"
	if method == ALPHA_WHOLE_METHOD:
		# Every new actual record carries its own explicit identity. A manifest
		# cannot fill in a missing identity or override a contradictory one.
		return "ALPHA_AWARE" if identity == ALPHA_ID and typeof(record.get("alpha_aware_transparent_body")) == TYPE_BOOL and record.alpha_aware_transparent_body == true else "REJECT"
	return "REJECT"

static func rebuild(raw: Image, logical_size: Vector2i, record: Dictionary, manifest_recipe: Dictionary = {}) -> Image:
	if raw == null or raw.is_empty() or raw.is_compressed() or raw.get_format() != Image.FORMAT_RGBA8 or logical_size.x <= 0 or logical_size.y <= 0 or raw.get_size() != logical_size * 2: return null
	var kind := method_kind(record, manifest_recipe)
	if kind == "REJECT": return null
	if kind == "OPAQUE_STRAIGHT":
		var original := raw.get_data()
		for index in range(3, original.size(), 4):
			if original[index] != 255: return null
	if kind != "ALPHA_AWARE":
		var straight := raw.duplicate() as Image
		straight.resize(logical_size.x, logical_size.y, Image.INTERPOLATE_LANCZOS)
		return straight
	# Separate scalar packed-float reconstruction, rather than reproducing the
	# pipeline's Color get/set loop or invoking its helper as its own oracle.
	var native_float := raw.duplicate() as Image
	native_float.convert(Image.FORMAT_RGBAF)
	var channels := native_float.get_data().to_float32_array()
	if channels.size() != raw.get_width() * raw.get_height() * 4: return null
	for index in range(0, channels.size(), 4):
		var alpha := float(channels[index + 3])
		channels[index] = float(channels[index]) * alpha
		channels[index + 1] = float(channels[index + 1]) * alpha
		channels[index + 2] = float(channels[index + 2]) * alpha
	var filtered := Image.create_from_data(raw.get_width(), raw.get_height(), false, Image.FORMAT_RGBAF, channels.to_byte_array())
	filtered.resize(logical_size.x, logical_size.y, Image.INTERPOLATE_LANCZOS)
	channels = filtered.get_data().to_float32_array()
	if channels.size() != logical_size.x * logical_size.y * 4: return null
	for index in range(0, channels.size(), 4):
		var alpha := float(channels[index + 3])
		if alpha > 0:
			channels[index] = float(channels[index]) / alpha
			channels[index + 1] = float(channels[index + 1]) / alpha
			channels[index + 2] = float(channels[index + 2]) / alpha
		else:
			channels[index] = 0
			channels[index + 1] = 0
			channels[index + 2] = 0
	var rebuilt := Image.create_from_data(logical_size.x, logical_size.y, false, Image.FORMAT_RGBAF, channels.to_byte_array())
	rebuilt.convert(Image.FORMAT_RGBA8)
	return rebuilt
