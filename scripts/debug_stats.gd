extends Node

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("print_stats"):
		var owners := get_tree().get_nodes_in_group("stats_owner")
		if owners.is_empty():
			print("[DebugStats] no nodes in 'stats_owner' group")
			return
		for n in owners:
			var label := String(n.name)
			var p: Personality = n.get("personality")
			if p == null:
				print("[%s] no personality assigned" % label)
				continue
			print("[%s] %s" % [label, p.describe()])
