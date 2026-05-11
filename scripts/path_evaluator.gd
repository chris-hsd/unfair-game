extends RefCounted
class_name PathEvaluator

const PATH_IDS: Array[String] = ["anpassung", "beziehung", "wirkung", "selbstbehauptung"]

static func evaluate_paths_from_stats(stats: Dictionary) -> Dictionary:
	var results := {}
	for path_id in PATH_IDS:
		results[path_id] = false
	return results
