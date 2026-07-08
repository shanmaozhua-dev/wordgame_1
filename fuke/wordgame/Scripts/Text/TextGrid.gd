class_name TextGrid
extends Node2D

@export var cell_size: int = 72
@export var bounds: Rect2i = Rect2i(0, 0, 24, 14)
@export var text_char_scene: PackedScene = preload("res://Scenes/Text/TextChar.tscn")

var rule_manager: TextRuleManager
var level_event_manager: LevelEventManager

var _occupancy: Dictionary = {}
var _text_chars: Array[TextChar] = []
var _blockers: Dictionary = {}


func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)


func is_in_bounds(cell: Vector2i) -> bool:
	return bounds.has_point(cell)


func cells_for_text(text: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var width: int = maxi(text.length(), 1)
	for x in range(width):
		result.append(origin + Vector2i(x, 0))
	return result


func register_text_char(text_char: TextChar) -> void:
	if text_char == null:
		return
	if not _text_chars.has(text_char):
		_text_chars.append(text_char)
		var exit_callable: Callable = Callable(self, "_on_text_char_exiting").bind(text_char)
		if not text_char.tree_exiting.is_connected(exit_callable):
			text_char.tree_exiting.connect(exit_callable, CONNECT_ONE_SHOT)

	text_char.grid = self
	_register_occupancy(text_char)
	text_char.apply_grid_position(false)


func unregister_text_char(text_char: TextChar) -> void:
	_unregister_occupancy(text_char)
	_text_chars.erase(text_char)


func has_text_char(text_char: TextChar) -> bool:
	return _text_chars.has(text_char)


func refresh_text_char(text_char: TextChar) -> void:
	_unregister_occupancy(text_char)
	_register_occupancy(text_char)


func get_all_text_chars() -> Array[TextChar]:
	var living: Array[TextChar] = []
	for text_char in _text_chars:
		if is_instance_valid(text_char):
			living.append(text_char)
	return living


func get_text_at(cell: Vector2i) -> TextChar:
	return _occupancy.get(cell) as TextChar


func get_cell_character(cell: Vector2i) -> Dictionary:
	var text_char: TextChar = get_text_at(cell)
	if text_char == null:
		return {}

	var index: int = cell.x - text_char.grid_pos.x
	if index < 0 or index >= text_char.char_text.length():
		return {}

	return {
		"node": text_char,
		"character": text_char.char_text.substr(index, 1),
	}


func get_blocking_text_for_move(text_char: TextChar, dir: Vector2i) -> TextChar:
	var next_pos: Vector2i = text_char.grid_pos + dir
	for cell in cells_for_text(text_char.char_text, next_pos):
		var other: TextChar = get_text_at(cell)
		if other != null and other != text_char:
			return other
	return null


func can_place_text(text: String, origin: Vector2i, ignore: Array = []) -> bool:
	for cell in cells_for_text(text, origin):
		if not is_in_bounds(cell):
			return false
		if _blockers.has(cell):
			return false
		var occupying: TextChar = get_text_at(cell)
		if occupying != null and not ignore.has(occupying):
			return false
	return true


func move_text_char(text_char: TextChar, new_pos: Vector2i, smooth: bool = true) -> bool:
	if not can_place_text(text_char.char_text, new_pos, [text_char]):
		return false

	_unregister_occupancy(text_char)
	text_char.grid_pos = new_pos
	_register_occupancy(text_char)
	text_char.apply_grid_position(smooth)
	return true


func replace_text_char(text_char: TextChar, new_text: String, new_pos: Vector2i, ignore: Array = []) -> bool:
	if not ignore.has(text_char):
		ignore.append(text_char)
	if not can_place_text(new_text, new_pos, ignore):
		return false

	for ignored in ignore:
		var ignored_text_char: TextChar = ignored as TextChar
		if ignored_text_char != text_char and ignored_text_char != null and is_instance_valid(ignored_text_char):
			unregister_text_char(ignored_text_char)

	_unregister_occupancy(text_char)
	text_char.grid_pos = new_pos
	text_char.set_char_text(new_text)
	_register_occupancy(text_char)
	text_char.apply_grid_position(true)
	return true


func create_text_char(text: String, origin: Vector2i, options: Dictionary = {}) -> TextChar:
	var text_char: TextChar = text_char_scene.instantiate() as TextChar
	if text_char == null:
		return null
	text_char.grid = self
	text_char.grid_pos = origin
	text_char.char_text = text

	for key in options.keys():
		if _is_supported_text_option(key):
			text_char.set(key, options[key])

	add_child(text_char)
	register_text_char(text_char)
	text_char.update_visual()
	return text_char


func add_blocker(cell: Vector2i, blocker_id: String = "blocker") -> void:
	if not _blockers.has(cell):
		_blockers[cell] = []
	if not _blockers[cell].has(blocker_id):
		_blockers[cell].append(blocker_id)


func remove_blocker(cell: Vector2i, blocker_id: String = "blocker") -> void:
	if not _blockers.has(cell):
		return
	_blockers[cell].erase(blocker_id)
	if _blockers[cell].is_empty():
		_blockers.erase(cell)


func can_player_enter(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	if _blockers.has(cell):
		return false
	return get_text_at(cell) == null


func notify_text_changed() -> void:
	if rule_manager and rule_manager.has_method("check_rules"):
		rule_manager.check_rules()


func _register_occupancy(text_char: TextChar) -> void:
	for cell in cells_for_text(text_char.char_text, text_char.grid_pos):
		_occupancy[cell] = text_char


func _unregister_occupancy(text_char: TextChar) -> void:
	for cell in _occupancy.keys():
		if _occupancy[cell] == text_char:
			_occupancy.erase(cell)


func _on_text_char_exiting(text_char: TextChar) -> void:
	unregister_text_char(text_char)


func _is_supported_text_option(key: Variant) -> bool:
	return [
		"can_push",
		"can_pull",
		"can_delete",
		"can_split",
		"can_combine",
	].has(key)
