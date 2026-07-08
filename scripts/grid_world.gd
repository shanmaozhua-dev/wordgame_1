extends RefCounted

const WordEntity = preload("res://scripts/word_entity.gd")

const ACTION_MOVE := "move"
const ACTION_INTERACT := "interact"
const ACTION_DELETE := "delete"
const ACTION_SPLIT := "split"
const ACTION_PULL := "pull"

var cell_size := 60
var screen_size := Vector2i(32, 18)
var player_pos := Vector2i.ZERO
var facing := Vector2i(1, 0)
var current_page_origin := Vector2i.ZERO
var entities: Dictionary = {}
var highlighted_cells: Array[Vector2i] = []
var last_message := ""
var rows: Array = []
var split_rules: Dictionary = {}
var merge_rules: Dictionary = {}
var sentence_rules: Dictionary = {}
var switches: Dictionary = {}
var state: Dictionary = {}

var _next_id := 1
var _map_caption_ids: Dictionary = {}

func load_level(level: Dictionary) -> void:
	clear()
	cell_size = level.get("cell_size", 60)
	screen_size = level.get("screen_size", screen_size)
	rows = level.get("rows", [])
	player_pos = level.get("player_start", player_pos)
	split_rules = level.get("split_rules", {})
	merge_rules = level.get("merge_rules", {})
	sentence_rules = level.get("sentence_rules", {})
	switches = level.get("switches", {}).duplicate()
	state = level.get("state", {}).duplicate()
	_parse_rows(rows, level.get("entities", {}))
	_parse_map_text_lines(level.get("map_text_lines", []), level.get("entities", {}))
	_parse_entity_spawns(level.get("entity_spawns", []), level.get("entities", {}))
	update_page()

func clear() -> void:
	entities.clear()
	highlighted_cells.clear()
	last_message = ""
	_next_id = 1
	_map_caption_ids.clear()
	switches.clear()
	state.clear()

func try_player_action(action: String, direction := Vector2i.ZERO) -> Dictionary:
	match action:
		ACTION_MOVE:
			return try_move_player(direction)
		ACTION_INTERACT:
			return interact_front()
		ACTION_DELETE:
			return delete_front()
		ACTION_SPLIT:
			return split_front()
		ACTION_PULL:
			return pull_front(direction)
		_:
			return {"success": false, "message": "unknown action"}

func try_move_player(direction: Vector2i) -> Dictionary:
	if direction == Vector2i.ZERO:
		return {"success": false, "message": "zero direction"}
	facing = direction
	var target := player_pos + direction
	var entity := get_entity_at(target)
	if entity:
		if not entity.pushable:
			return {"success": false, "message": "blocked"}
		var pushed := move_entity_by(entity.id, direction)
		if not pushed.success:
			return pushed
	player_pos = target
	update_page()
	check_sentence_rules()
	return {"success": true}

func interact_front() -> Dictionary:
	var entity := get_entity_at(player_pos + facing)
	if entity and entity.interact_text:
		last_message = entity.interact_text
		spawn_map_caption(entity.interact_text, entity.grid_pos + Vector2i(0, 1))
		return {"success": true, "message": entity.interact_text}
	return {"success": false, "message": ""}

func delete_front() -> Dictionary:
	var entity := get_entity_at(player_pos + facing)
	if not entity:
		return {"success": false, "message": "no word"}
	if not entity.deletable:
		return {"success": false, "message": "not deletable"}
	entities.erase(entity.id)
	check_sentence_rules()
	return {"success": true}

func split_front() -> Dictionary:
	var entity := get_entity_at(player_pos + facing)
	if not entity:
		return {"success": false, "message": "no word"}
	if not entity.splittable or not split_rules.has(entity.text):
		return {"success": false, "message": "not splittable"}
	var parts: Array = split_rules[entity.text]
	if parts.size() != 2:
		return {"success": false, "message": "split rule needs two parts"}
	var stay_pos := entity.grid_pos
	var move_pos := stay_pos + facing
	if get_entity_at(move_pos) and get_entity_at(move_pos).id != entity.id:
		return {"success": false, "message": "split target blocked"}
	entities.erase(entity.id)
	add_entity(str(parts[0]), stay_pos, {"solid": true, "pushable": true, "splittable": true})
	add_entity(str(parts[1]), move_pos, {"solid": true, "pushable": true, "splittable": true})
	check_sentence_rules()
	return {"success": true}

func pull_front(move_direction: Vector2i) -> Dictionary:
	if move_direction == Vector2i.ZERO:
		return {"success": false, "message": "zero direction"}
	var entity := get_entity_at(player_pos + facing)
	if not entity or not entity.pushable:
		return {"success": false, "message": "nothing pullable"}
	if move_direction != -facing:
		return {"success": false, "message": "pull direction locked"}
	var old_player_pos := player_pos
	var new_player_pos := player_pos + move_direction
	if get_entity_at(new_player_pos):
		return {"success": false, "message": "player target blocked"}
	player_pos = new_player_pos
	move_entity_to(entity.id, old_player_pos)
	facing = -move_direction
	update_page()
	check_sentence_rules()
	return {"success": true}

func move_entity_by(entity_id: String, direction: Vector2i) -> Dictionary:
	var entity: WordEntity = entities.get(entity_id)
	if not entity:
		return {"success": false, "message": "missing entity"}
	var own_cells := {}
	for cell in entity.cells:
		own_cells[cell] = true
	for cell in entity.cells:
		var target := cell + direction
		var blocker := get_entity_at(target)
		if blocker and blocker.id != entity.id:
			var merged := try_merge_entities(entity.grid_pos, blocker.grid_pos)
			if merged.success:
				return merged
			if blocker.pushable:
				var pushed_blocker := move_entity_by(blocker.id, direction)
				if not pushed_blocker.success:
					return pushed_blocker
				continue
			return {"success": false, "message": "blocked by word"}
		if target == player_pos and not own_cells.has(target):
			return {"success": false, "message": "blocked by player"}
	entity.move_by(direction)
	return {"success": true}

func move_entity_to(entity_id: String, pos: Vector2i) -> Dictionary:
	var entity: WordEntity = entities.get(entity_id)
	if not entity:
		return {"success": false, "message": "missing entity"}
	var delta := pos - entity.grid_pos
	entity.move_by(delta)
	return {"success": true}

func try_merge_entities(from_pos: Vector2i, to_pos: Vector2i) -> Dictionary:
	var first := get_entity_at(from_pos)
	var second := get_entity_at(to_pos)
	if not first or not second or first.id == second.id:
		return {"success": false, "message": "need two words"}
	var key := "%s+%s" % [first.text, second.text]
	if not merge_rules.has(key):
		return {"success": false, "message": "no merge rule"}
	var merged_text := str(merge_rules[key])
	entities.erase(first.id)
	entities.erase(second.id)
	add_entity(merged_text, to_pos, {"solid": true, "pushable": true, "splittable": split_rules.has(merged_text)})
	check_sentence_rules()
	return {"success": true}

func check_sentence_rules() -> Dictionary:
	highlighted_cells.clear()
	for entity in entities.values():
		entity.highlighted = false
	var result := {}
	for sentence in sentence_rules.keys():
		var found_cells := _find_horizontal_text(str(sentence))
		if not found_cells.is_empty():
			for cell in found_cells:
				highlighted_cells.append(cell)
				var entity := get_entity_at(cell)
				if entity:
					entity.highlighted = true
			var config: Dictionary = sentence_rules[sentence]
			last_message = config.get("message", "")
			_apply_sentence_effects(str(sentence), config)
			_spawn_sentence_caption(str(sentence), config, found_cells)
			result[sentence] = {"message": last_message, "cells": found_cells}
	return result

func _apply_sentence_effects(_sentence: String, config: Dictionary) -> void:
	if config.has("switch"):
		switches[str(config["switch"])] = true
	var configured_switches: Dictionary = config.get("switches", {})
	for key in configured_switches.keys():
		switches[str(key)] = configured_switches[key]
	var configured_state: Dictionary = config.get("state", {})
	for key in configured_state.keys():
		state[str(key)] = configured_state[key]
	var spawns: Array = config.get("spawn_entities", [])
	for spawn in spawns:
		var spawn_config: Dictionary = spawn.get("config", {})
		var text := str(spawn.get("text", ""))
		if text.is_empty():
			continue
		if find_first_entity_by_text(text):
			continue
		add_entity(text, spawn.get("pos", Vector2i.ZERO), _default_config_for(text, spawn_config))

func update_page() -> void:
	current_page_origin = Vector2i(
		floori(float(player_pos.x) / float(screen_size.x)) * screen_size.x,
		floori(float(player_pos.y) / float(screen_size.y)) * screen_size.y
	)

func get_entity_at(pos: Vector2i) -> WordEntity:
	for entity in entities.values():
		if entity.solid and entity.cells.has(pos):
			return entity
	return null

func find_first_entity_by_text(text: String) -> WordEntity:
	for entity in entities.values():
		if entity.text == text:
			return entity
	return null

func add_entity(text: String, pos: Vector2i, config := {}) -> WordEntity:
	var occupied_cells: Array[Vector2i] = []
	for i in range(text.length()):
		occupied_cells.append(pos + Vector2i(i, 0))
	var entity := WordEntity.new("word_%03d" % _next_id, text, pos, occupied_cells)
	_next_id += 1
	entity.set_from_config(config)
	entities[entity.id] = entity
	return entity

func spawn_map_caption(text: String, near_pos: Vector2i, config := {}) -> WordEntity:
	if text.is_empty():
		return null
	if _map_caption_ids.has(text) and entities.has(_map_caption_ids[text]):
		return entities[_map_caption_ids[text]]
	var pos := near_pos
	if config.has("caption_pos"):
		pos = config.caption_pos
	else:
		pos = _find_free_caption_pos(near_pos, text.length())
	var caption := add_entity(text, pos, {
		"solid": config.get("caption_solid", true),
		"pushable": config.get("caption_pushable", false),
		"deletable": config.get("caption_deletable", false),
		"splittable": config.get("caption_splittable", false),
		"interact_text": config.get("caption_interact_text", "")
	})
	_map_caption_ids[text] = caption.id
	return caption

func _spawn_sentence_caption(sentence: String, config: Dictionary, cells: Array[Vector2i]) -> void:
	var caption_text := str(config.get("message", ""))
	if caption_text.is_empty():
		return
	spawn_map_caption(caption_text, cells[0] + Vector2i(0, 1), config)

func _find_free_caption_pos(start: Vector2i, text_length: int) -> Vector2i:
	for distance in range(0, 8):
		for offset in [Vector2i(0, distance), Vector2i(0, -distance), Vector2i(distance, 0), Vector2i(-distance, 0)]:
			var candidate: Vector2i = start + offset
			if _can_place_text(candidate, text_length):
				return candidate
	return start

func _can_place_text(pos: Vector2i, text_length: int) -> bool:
	for i in range(text_length):
		var cell := pos + Vector2i(i, 0)
		if cell == player_pos or get_entity_at(cell):
			return false
	return true

func _parse_rows(level_rows: Array, entity_configs: Dictionary) -> void:
	var multi_texts := _get_multi_texts(entity_configs)
	var covered := {}
	for y in range(level_rows.size()):
		var line := str(level_rows[y])
		var x := 0
		while x < line.length():
			var pos := Vector2i(x, y)
			if covered.has(pos):
				x += 1
				continue
			var matched := _match_multi_text(line, x, multi_texts)
			if matched:
				var config: Dictionary = entity_configs.get(matched, {})
				add_entity(matched, pos, _default_config_for(matched, config))
				for offset in range(matched.length()):
					covered[pos + Vector2i(offset, 0)] = true
				x += matched.length()
				continue
			var ch := line.substr(x, 1)
			if ch != " " and ch != "我":
				var config: Dictionary = entity_configs.get(ch, {})
				add_entity(ch, pos, _default_config_for(ch, config))
			x += 1

func _parse_map_text_lines(text_lines: Array, entity_configs: Dictionary) -> void:
	for line_config in text_lines:
		var text := str(line_config.get("text", ""))
		var origin: Vector2i = line_config.get("pos", Vector2i.ZERO)
		var config: Dictionary = line_config.get("config", {})
		for i in range(text.length()):
			var ch := text.substr(i, 1)
			if ch == " " or ch == "＿" or ch == "我":
				continue
			var merged_config := _default_config_for(ch, entity_configs.get(ch, {}))
			for key in config.keys():
				merged_config[key] = config[key]
			add_entity(ch, origin + Vector2i(i, 0), merged_config)

func _parse_entity_spawns(spawns: Array, entity_configs: Dictionary) -> void:
	for spawn in spawns:
		var text := str(spawn.get("text", ""))
		if text.is_empty():
			continue
		var config: Dictionary = _default_config_for(text, entity_configs.get(text, {}))
		var spawn_config: Dictionary = spawn.get("config", {})
		for key in spawn_config.keys():
			config[key] = spawn_config[key]
		add_entity(text, spawn.get("pos", Vector2i.ZERO), config)

func _default_config_for(text: String, overrides: Dictionary) -> Dictionary:
	var config := {"solid": true}
	for key in overrides.keys():
		config[key] = overrides[key]
	return config

func _get_multi_texts(entity_configs: Dictionary) -> Array[String]:
	var texts: Array[String] = []
	for text in entity_configs.keys():
		var s := str(text)
		if s.length() > 1:
			texts.append(s)
	texts.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	return texts

func _match_multi_text(line: String, start: int, multi_texts: Array[String]) -> String:
	for text in multi_texts:
		if start + text.length() <= line.length() and line.substr(start, text.length()) == text:
			return text
	return ""

func _find_horizontal_text(text: String) -> Array[Vector2i]:
	for entity in entities.values():
		if entity.text != text.substr(0, 1):
			continue
		var cells: Array[Vector2i] = []
		var matched := true
		for i in range(text.length()):
			var pos: Vector2i = entity.grid_pos + Vector2i(i, 0)
			var next_entity := get_entity_at(pos)
			if not next_entity or next_entity.text.substr(0, 1) != text.substr(i, 1):
				matched = false
				break
			cells.append(pos)
		if matched:
			return cells
	return []
