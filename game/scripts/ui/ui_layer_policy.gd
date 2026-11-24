extends RefCounted

## UI canvas policy shared by field and battle scenes.
##
## World actors use dynamic z-index bands for foot-based depth sorting.  A
## CanvasLayer is therefore required for HUD and modal UI; increasing a
## Control's z_index alone can still leave it behind an actor or foreground
## object that belongs to the same canvas.

const HUD_LAYER := 40
const SYSTEM_LAYER := 80
const CINEMATIC_LAYER := 100
const DIALOG_LAYER := 120


static func ensure_canvas_layer(
		host: Node,
		node_name: StringName,
		layer_value: int
) -> CanvasLayer:
	var existing := host.get_node_or_null(NodePath(String(node_name)))
	if existing is CanvasLayer:
		var existing_layer := existing as CanvasLayer
		existing_layer.layer = layer_value
		return existing_layer
	if existing != null:
		push_error("[UILayerPolicy] %s already exists but is not a CanvasLayer" % String(node_name))
		return null
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = String(node_name)
	canvas_layer.layer = layer_value
	host.add_child(canvas_layer)
	return canvas_layer


static func move_to_canvas(node: Node, canvas_layer: CanvasLayer) -> void:
	if node == null or canvas_layer == null or node.get_parent() == canvas_layer:
		return
	node.reparent(canvas_layer)
