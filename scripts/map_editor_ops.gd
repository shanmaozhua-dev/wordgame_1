extends RefCounted

static func cells_in_rect(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var from := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var to := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	var cells: Array[Vector2i] = []
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			cells.append(Vector2i(x, y))
	return cells

static func fill_cells(world: RefCounted, cells: Array[Vector2i], text: String, config := {}) -> void:
	var clean := text.strip_edges()
	if clean.length() > 1:
		clean = clean.substr(0, 1)
	clear_cells(world, cells)
	if clean.is_empty():
		return
	var fill_config := _default_edit_config(config)
	for cell in cells:
		world.add_entity(clean, cell, fill_config)

static func clear_cells(world: RefCounted, cells: Array[Vector2i]) -> void:
	var ids := _entity_ids_touching_cells(world, cells, {})
	for id in ids.keys():
		world.entities.erase(id)

static func move_rect(world: RefCounted, from_a: Vector2i, from_b: Vector2i, target_origin: Vector2i) -> void:
	var source_cells := cells_in_rect(from_a, from_b)
	var source_min := Vector2i(mini(from_a.x, from_b.x), mini(from_a.y, from_b.y))
	var moved := []
	var moved_ids := {}
	for entity in world.entities.values():
		if source_cells.has(entity.grid_pos):
			moved.append({
				"text": entity.text,
				"offset": entity.grid_pos - source_min,
				"config": _config_from_entity(entity)
			})
			moved_ids[entity.id] = true
	for id in moved_ids.keys():
		world.entities.erase(id)
	var target_cells: Array[Vector2i] = []
	for cell in source_cells:
		target_cells.append(target_origin + (cell - source_min))
	var target_ids := _entity_ids_touching_cells(world, target_cells, moved_ids)
	for id in target_ids.keys():
		world.entities.erase(id)
	for item in moved:
		world.add_entity(str(item["text"]), target_origin + item["offset"], item["config"])

static func toggle_flag(world: RefCounted, cells: Array[Vector2i], flag: String) -> void:
	var ids := {}
	for cell in cells:
		var entity := _find_entity_at_any(world, cell)
		if entity and not ids.has(entity.id):
			ids[entity.id] = entity
	for entity in ids.values():
		match flag:
			"pushable":
				entity.pushable = not entity.pushable
			"deletable":
				entity.deletable = not entity.deletable
			"solid":
				entity.solid = not entity.solid

static func _entity_ids_touching_cells(world: RefCounted, cells: Array[Vector2i], except_ids: Dictionary) -> Dictionary:
	var ids := {}
	for cell in cells:
		var entity := _find_entity_at_any(world, cell)
		if entity and not except_ids.has(entity.id):
			ids[entity.id] = true
	return ids

static func _find_entity_at_any(world: RefCounted, pos: Vector2i) -> RefCounted:
	for entity in world.entities.values():
		if entity.cells.has(pos):
			return entity
	return null

static func _default_edit_config(overrides: Dictionary) -> Dictionary:
	var config := {"solid": true, "pushable": false, "deletable": false, "splittable": false, "interact_text": "", "tags": ["manual_edit"]}
	for key in overrides.keys():
		config[key] = overrides[key]
	return config

static func _config_from_entity(entity: RefCounted) -> Dictionary:
	return {
		"solid": entity.solid,
		"pushable": entity.pushable,
		"deletable": entity.deletable,
		"splittable": entity.splittable,
		"interact_text": entity.interact_text,
		"tags": entity.tags.duplicate()
	}
