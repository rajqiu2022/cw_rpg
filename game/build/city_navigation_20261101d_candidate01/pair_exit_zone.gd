extends ExitZone
## Exact mouth contact, not a larger radius around a displaced legacy arrow.
var _owner: WeakRef
var _contact: Rect2
var _check: Callable
var _armed := true

func configure(owner: Node, mouth: Dictionary, checker: Callable) -> void:
 _owner = weakref(owner)
 _contact = Rect2(mouth.mouth - mouth.activation_size * 0.5, mouth.activation_size)
 _check = checker
 position = mouth.mouth
 target_scene_id = String(mouth.target.logical_id)
 target_spawn_pos = Vector2.ZERO
 exit_label = "空格 · 前往" + load("res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd").destination_name(String(mouth.target.logical_id))
 destination_name = exit_label
 auto_trigger = false
 always_show_destination = false
 marker_rotation_degrees = rad_to_deg(mouth.outward.angle() - PI * 0.5)
 set_meta("citynav_endpoint", mouth.duplicate(true))

func _ready() -> void:
 super._ready()
 var shape: RectangleShape2D = RectangleShape2D.new()
 shape.size = _contact.size
 ($CollisionShape2D as CollisionShape2D).shape = shape
 input_pickable = false
 # No edge clamp. This same local point owns the contact rectangle and glyph.
 _marker_anchor_offset = Vector2(0,-20)
 if marker_visual != null:
  marker_visual.rotation_degrees = marker_rotation_degrees
 if prompt != null:
  prompt.position = Vector2(28,-32)
  prompt.size = Vector2(260,42)
  prompt.text = exit_label
  prompt.add_theme_font_size_override("font_size",18)
  prompt.visible = false

func set_armed(value: bool) -> void:
 _armed = value

func _can_enter() -> bool:
 if not _armed or not _check.is_valid() or _owner == null: return false
 var field: Node = _owner.get_ref() as Node
 if not is_instance_valid(field): return false
 var actor: Player = field.get("_player") as Player
 return is_instance_valid(actor) and actor.can_move and _contact.has_point(actor.position) and bool(_check.call(actor.position))

func try_interact() -> bool:
 return _activate() if _can_enter() else false

func _activate() -> bool:
 return super._activate() if _can_enter() else false
