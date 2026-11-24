extends SceneTree

const DATA_DIRS: Array[String] = [
	"res://data/dialogs",
	"res://data/quests",
	"res://data/scenes",
]


func _initialize() -> void:
	var failures: Array[String] = []
	var checked: int = 0

	for directory in DATA_DIRS:
		var dir := DirAccess.open(directory)
		if dir == null:
			failures.append("cannot open %s" % directory)
			continue
		for filename in dir.get_files():
			if not filename.ends_with(".tres"):
				continue
			if not _is_chapter_one_to_four(filename):
				continue
			checked += 1
			var path := "%s/%s" % [directory, filename]
			if ResourceLoader.load(path) == null:
				failures.append(path)

	print("[ChapterResourceCheck] checked=%d failed=%d" % [checked, failures.size()])
	for path in failures:
		push_error("[ChapterResourceCheck] failed to load: %s" % path)
	quit(1 if not failures.is_empty() else 0)


func _is_chapter_one_to_four(filename: String) -> bool:
	return (
		filename.begins_with("ch1_")
		or filename.begins_with("ch2_")
		or filename.begins_with("ch3_")
		or filename.begins_with("ch4_")
		or filename.begins_with("q_ch1_")
		or filename.begins_with("q_ch2_")
		or filename.begins_with("q_ch3_")
		or filename.begins_with("q_ch4_")
	)
