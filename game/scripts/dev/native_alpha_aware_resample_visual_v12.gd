extends RefCounted

# Spatial reconstruction of one immutable transparent sourcebody frame.
# This is not a temporal average, alpha cutout, tolerance, or colour tint.
# Opaque terrain/nav must continue using their existing export paths.
static func resample(raw: Image,logical_size: Vector2i) -> Image:
	if raw==null or raw.is_empty() or logical_size.x<=0 or logical_size.y<=0:
		return null
	var premultiplied: Image=raw.duplicate() as Image
	premultiplied.convert(Image.FORMAT_RGBAF)
	for y in premultiplied.get_height():
		for x in premultiplied.get_width():
			var value: Color=premultiplied.get_pixel(x,y)
			premultiplied.set_pixel(x,y,Color(value.r*value.a,value.g*value.a,value.b*value.a,value.a))
	premultiplied.resize(logical_size.x,logical_size.y,Image.INTERPOLATE_LANCZOS)
	for y in logical_size.y:
		for x in logical_size.x:
			var value: Color=premultiplied.get_pixel(x,y)
			# Lanczos lobes can leave values outside [0,1]. RGBA8 conversion
			# clamps those naturally; never introduce an alpha threshold.
			if value.a>0.:
				premultiplied.set_pixel(x,y,Color(value.r/value.a,value.g/value.a,value.b/value.a,value.a))
			else:
				premultiplied.set_pixel(x,y,Color(0,0,0,value.a))
	premultiplied.convert(Image.FORMAT_RGBA8)
	return premultiplied
