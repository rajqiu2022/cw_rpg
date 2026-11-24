extends RefCounted
## Candidate: fresh full reads on EVERY invocation, no cross-phase or metadata cache.
## Workers receive private path arrays and return private dictionaries; no scene/resource access.
static func _slice(paths: Array[String]) -> Dictionary:
	var values: Dictionary = {}
	for path: String in paths:
		values[path] = FileAccess.get_sha256(path)
	return values

static func fresh(paths: Array[String], workers: int = 4) -> Dictionary:
	var count := clampi(workers, 1, 4)
	var buckets: Array = []
	var threads: Array[Thread] = []
	var results: Array = []
	for index: int in range(count):
		var bucket: Array[String] = []
		buckets.append(bucket)
		results.append({})
	for index: int in range(paths.size()):
		buckets[index % count].append(paths[index])
	for index: int in range(count):
		var thread := Thread.new()
		threads.append(thread)
		if thread.start(_slice.bind(buckets[index])) != OK:
			results[index] = _slice(buckets[index])
	for index: int in range(count):
		if threads[index].is_started():
			results[index] = threads[index].wait_to_finish()
	var merged: Dictionary = {}
	# Restore original insertion/check order, including empty hashes for missing files.
	for index: int in range(paths.size()):
		merged[paths[index]] = results[index % count].get(paths[index], "")
	return merged
