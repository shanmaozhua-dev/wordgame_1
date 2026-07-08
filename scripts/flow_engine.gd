extends RefCounted

const MapEditorIO = preload("res://scripts/map_editor_io.gd")

var stage := ""
var maps: Dictionary = {}
var rules: Array = []
var on_load: Dictionary = {}
var _observed_rule_cells: Dictionary = {}

func load_config(path: String) -> Dictionary:
	var parsed := _load_json(path)
	if not parsed.success:
		return parsed
	maps = parsed.data.get("maps", {}).duplicate(true)
	rules = parsed.data.get("rules", []).duplicate(true)
	on_load = parsed.data.get("on_load", {}).duplicate(true)
	stage = str(parsed.data.get("start_map", ""))
	if stage.is_empty():
		return {"success": false, "message": "flow config missing start_map"}
	return {"success": true}

func has_map(map_id: String) -> bool:
	return maps.has(map_id)

func rule_count() -> int:
	return rules.size()

func load_start_map(world: RefCounted) -> Dictionary:
	if stage.is_empty():
		return {"success": false, "message": "flow config is not loaded"}
	return load_map(world, stage)

func handle_trigger(world: RefCounted, trigger_type: String) -> Dictionary:
	for rule in rules:
		if _rule_matches_stage(rule) and str(rule.get("trigger", {}).get("type", "")) == trigger_type:
			return _apply_rule(world, rule)
	return {"success": false, "message": ""}

func sync_after_player_action(world: RefCounted) -> Dictionary:
	for rule in rules:
		if _rule_matches_stage(rule) and _trigger_matches_world(world, rule.get("trigger", {})):
			return _apply_rule(world, rule)
	_remember_rule_cells(world)
	return {"success": false, "message": ""}

func load_map(world: RefCounted, map_id: String) -> Dictionary:
	if not maps.has(map_id):
		return {"success": false, "message": "unknown flow map: %s" % map_id}
	var loaded := MapEditorIO.load_editor_data(str(maps[map_id]))
	if not loaded.success:
		return loaded
	world.load_level(MapEditorIO.editor_data_to_level(loaded.data))
	stage = map_id
	_apply_on_load(world, map_id)
	_remember_rule_cells(world)
	return {"success": true, "message": map_id}

func _apply_rule(world: RefCounted, rule: Dictionary) -> Dictionary:
	var preserved := _snapshot_preserved_words(world, rule.get("preserve", []))
	var player_pos = world.player_pos
	var facing = world.facing
	var result := load_map(world, str(rule.get("to", "")))
	if not result.success:
		return result
	world.player_pos = player_pos
	world.facing = facing
	for snapshot in preserved:
		if _can_restore_snapshot(world, snapshot):
			world.add_entity(str(snapshot.text), snapshot.pos, snapshot.config)
	world.update_page()
	_remember_rule_cells(world)
	return {"success": true, "message": str(rule.get("to", ""))}

func _rule_matches_stage(rule: Dictionary) -> bool:
	var from: Array = rule.get("from", [])
	return from.has(stage)

func _trigger_matches_world(world: RefCounted, trigger: Dictionary) -> bool:
	var pos := _array_to_vector2i(trigger.get("pos", []))
	var target_text := str(trigger.get("text", ""))
	var current_text := _cell_text_at(world, pos)
	var previous_text := str(_observed_rule_cells.get(_cell_key(pos), ""))
	match str(trigger.get("type", "")):
		"cell_text":
			return current_text == target_text and previous_text != target_text
		"cell_not_text":
			return current_text != target_text and previous_text == target_text
	return false

func _remember_rule_cells(world: RefCounted) -> void:
	for rule in rules:
		var trigger: Dictionary = rule.get("trigger", {})
		var trigger_type := str(trigger.get("type", ""))
		if trigger_type != "cell_text" and trigger_type != "cell_not_text":
			continue
		var pos := _array_to_vector2i(trigger.get("pos", []))
		_observed_rule_cells[_cell_key(pos)] = _cell_text_at(world, pos)

func _cell_text_at(world: RefCounted, pos: Vector2i) -> String:
	var entity = world.get_entity_at(pos)
	if entity == null:
		return ""
	return entity.text

func _cell_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]

func _snapshot_preserved_words(world: RefCounted, words: Array) -> Array:
	var snapshots: Array = []
	for word in words:
		var entity = _find_dynamic_entity(world, str(word))
		if entity != null:
			snapshots.append(_snapshot_entity(entity))
	return snapshots

func _find_dynamic_entity(world: RefCounted, text: String) -> RefCounted:
	var first = null
	for entity in world.entities.values():
		if entity.text != text:
			continue
		if entity.pushable:
			return entity
		if first == null:
			first = entity
	return first

func _snapshot_entity(entity: RefCounted) -> Dictionary:
	return {
		"text": entity.text,
		"pos": entity.grid_pos,
		"config": {
			"solid": entity.solid,
			"pushable": entity.pushable,
			"deletable": entity.deletable,
			"splittable": entity.splittable,
			"interact_text": entity.interact_text,
			"tags": entity.tags.duplicate()
		}
	}

func _can_restore_snapshot(world: RefCounted, snapshot: Dictionary) -> bool:
	var text := str(snapshot.get("text", ""))
	var pos: Vector2i = snapshot.get("pos", Vector2i.ZERO)
	for i in range(text.length()):
		var entity = world.get_entity_at(pos + Vector2i(i, 0))
		if entity != null and entity.text == text:
			return false
		if entity != null:
			return false
	return true

func _apply_on_load(world: RefCounted, map_id: String) -> void:
	var effects: Array = []
	effects.append_array(on_load.get("*", []))
	effects.append_array(on_load.get(map_id, []))
	for effect in effects:
		if str(effect.get("type", "")) == "set_cell_flags":
			var entity = world.get_entity_at(_array_to_vector2i(effect.get("pos", [])))
			if entity:
				if effect.has("solid"):
					entity.solid = bool(effect["solid"])
				if effect.has("pushable"):
					entity.pushable = bool(effect["pushable"])
				if effect.has("deletable"):
					entity.deletable = bool(effect["deletable"])
				if effect.has("splittable"):
					entity.splittable = bool(effect["splittable"])

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"success": false, "message": "file not found: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "message": "cannot open %s: %s" % [path, error_string(FileAccess.get_open_error())]}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"success": false, "message": "invalid json: %s" % path}
	return {"success": true, "data": parsed}

func _array_to_vector2i(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
