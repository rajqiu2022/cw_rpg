extends Control
## Runtime-only face crop of the live hero portrait. Never edits an image.
const HUD_PORTRAIT := "res://art/characters/protagonist_neutral.png"
var _requested_path := ""
var _portrait_path := ""
var _texture: Texture2D
var _source_rect := Rect2()
var _initial := "人"
var _fallback_kind := "INITIAL"
var _loads := 0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;focus_mode=Control.FOCUS_NONE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR

func sync_marker(point: Vector2) -> void:
	var side: float=clampf(22.0*get_viewport_rect().size.y/1080.0,18.0,24.0)
	size=Vector2.ONE*side;position=point-size*.5
	var requested: String=GameState.player.portrait_path if GameState.player!=null else ""
	var initial: String=GameState.player.display_name.left(1) if GameState.player!=null and not GameState.player.display_name.is_empty() else "人"
	if requested!=_requested_path or _loads==0:
		_requested_path=requested;_texture=null;_portrait_path="";_source_rect=Rect2()
		if not requested.is_empty() and ResourceLoader.exists(requested):
			_texture=load(requested) as Texture2D
			if _texture!=null:_portrait_path=requested;_fallback_kind="NONE"
		if _texture==null and ResourceLoader.exists(HUD_PORTRAIT):
			_texture=load(HUD_PORTRAIT) as Texture2D
			if _texture!=null:_portrait_path=HUD_PORTRAIT;_fallback_kind="HUD_PROTAGONIST"
		if _texture!=null:
			var dimensions: Vector2=_texture.get_size()
			var crop: float=minf(dimensions.x,dimensions.y)*.62
			_source_rect=Rect2((dimensions.x-crop)*.5,dimensions.y*.02,crop,crop)
		else:_fallback_kind="INITIAL"
		_loads+=1
	_initial=initial;queue_redraw()

func _draw() -> void:
	var rect:=Rect2(Vector2.ZERO,size)
	draw_rect(rect.grow(1.0),Color(0.035,0.07,0.085,1.0))
	draw_rect(rect,Color(0.035,0.07,0.085,1.0))
	if _texture!=null:draw_texture_rect_region(_texture,rect.grow(-1.0),_source_rect)
	else:
		var font: Font=ThemeDB.fallback_font
		var text_size: int=14
		var extent: Vector2=font.get_string_size(_initial,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size)
		draw_string(font,Vector2((size.x-extent.x)*.5,(size.y-extent.y)*.5+font.get_ascent(text_size)),_initial,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,Color(0.82,0.94,0.95))
	draw_rect(rect,Color(0.63,0.81,0.82,0.9),false,1.0)

func get_debug_state() -> Dictionary:
	return {"kind":"PLAYER_PORTRAIT","requested_portrait_path":_requested_path,"portrait_path":_portrait_path,"source_rect":_source_rect,"fallback_kind":_fallback_kind,"fallback_initial":_initial,"screen_rect":get_global_rect(),"marker_size":size,"portrait_loads":_loads,"mouse_filter":mouse_filter,"arrow_visible":false,"image_writes":0}
