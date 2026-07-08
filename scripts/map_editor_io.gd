extends RefCounted

static func world_to_editor_data(world: RefCounted) -> Dictionary:
	var cells: Array = []
	for entity in world.entities.values():
		cells.append({
			"x": entity.grid_pos.x,
			"y": entity.grid_pos.y,
			"text": entity.text,
			"solid": entity.solid,
			"pushable": entity.pushable,
			"deletable": entity.deletable,
			"splittable": entity.splittable,
			"interact_text": entity.interact_text,
			"tags": entity.tags.duplicate()
		})
	cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["y"]) == int(b["y"]):
			return int(a["x"]) < int(b["x"])
		return int(a["y"]) < int(b["y"])
	)
	return {
		"screen_size": [world.screen_size.x, world.screen_size.y],
		"cell_size": world.cell_size,
		"player_start": [world.player_pos.x, world.player_pos.y],
		"cells": cells,
		"split_rules": world.split_rules.duplicate(true),
		"merge_rules": world.merge_rules.duplicate(true),
		"sentence_rules": world.sentence_rules.duplicate(true)
	}

static func editor_data_to_level(data: Dictionary) -> Dictionary:
	var spawns: Array = []
	for cell in data.get("cells", []):
		var text := str(cell.get("text", ""))
		if text.is_empty():
			continue
		spawns.append({
			"text": text,
			"pos": Vector2i(int(cell.get("x", 0)), int(cell.get("y", 0))),
			"config": {
				"solid": bool(cell.get("solid", true)),
				"pushable": bool(cell.get("pushable", false)),
				"deletable": bool(cell.get("deletable", false)),
				"splittable": bool(cell.get("splittable", false)),
				"interact_text": str(cell.get("interact_text", "")),
				"tags": cell.get("tags", [])
			}
		})
	return {
		"rows": [],
		"map_text_lines": [],
		"entity_spawns": spawns,
		"entities": {},
		"screen_size": _array_to_vector2i(data.get("screen_size", [32, 18]), Vector2i(32, 18)),
		"cell_size": int(data.get("cell_size", 24)),
		"player_start": _array_to_vector2i(data.get("player_start", [0, 0]), Vector2i.ZERO),
		"split_rules": data.get("split_rules", {}),
		"merge_rules": data.get("merge_rules", {}),
		"sentence_rules": data.get("sentence_rules", {})
	}

static func save_editor_data(path: String, data: Dictionary) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "message": "cannot open %s: %s" % [path, error_string(FileAccess.get_open_error())]}
	file.store_string(JSON.stringify(data, "\t", false))
	return {"success": true, "path": path}

static func load_editor_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "message": "file not found: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "message": "cannot open %s: %s" % [path, error_string(FileAccess.get_open_error())]}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"success": false, "message": "invalid editor json: %s" % path}
	return {"success": true, "data": parsed}

static func _array_to_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return fallback
	return Vector2i(int(value[0]), int(value[1]))
