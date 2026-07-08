extends "BaseMap.gd"

func is_in_bound(pos):
	return true
	
func can_pass(pos):
	return true

func get_events_by_pos(map_pos):

	
	var camera = Global.game_map.player.get_node("Camera3D")
	var pos = map_pos - camera.get_top_left_position_of_map()
	
	var events = []

	if event_table.has(pos) and event_table[pos].size() > 0:
		for event_path in event_table[pos]:
			var e = get_node(event_path)
			if e and e.existing:
				events.append(e)
	return events
