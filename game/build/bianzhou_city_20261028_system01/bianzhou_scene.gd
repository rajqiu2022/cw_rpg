extends SceneScript
const Author = preload("res://build/bianzhou_city_20261028_system01/city_author.gd")

func _init() -> void:
	var source: SceneScript=Author.scene()
	for property: Dictionary in source.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_STORAGE and String(property.name)!="script": set(property.name,source.get(property.name))
