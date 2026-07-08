class_name TextChar
extends Area2D

signal moved(text_char: TextChar, new_pos: Vector2i)
signal deleted(text_char: TextChar)
signal split(text_char: TextChar, parts: Array)
signal combined(text_char: TextChar, result_text: String)

const GLYPH_FONT = preload("res://Fonts/Zpix.ttf")
const INVALID_GRID_POS = Vector2i(-999999, -999999)

var _char_text: String = "字"

@export var char_text: String = "字":
	set(value):
		set_char_text(value)
	get:
		return _char_text
@export var grid_pos: Vector2i = Vector2i.ZERO
@export var can_push: bool = true
@export var can_pull: bool = true
@export var can_delete: bool = true
@export var can_split: bool = false
@export var can_combine: bool = true

var grid: TextGrid
var _is_highlighted: bool = false
var _move_tween: Tween

@onready var _background: ColorRect = $Background
@onready var _label: Label = $Label
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("text_chars")
	update_visual()
	call_deferred("_register_with_parent_grid")


func set_char_text(value: String) -> void:
	_char_text = value
	if is_inside_tree():
		update_visual()
		if grid:
			grid.refresh_text_char(self)


func push(dir: Vector2i) -> bool:
	if not can_push or grid == null:
		_shake()
		return false

	var blocking_text: TextChar = grid.get_blocking_text_for_move(self, dir)
	if blocking_text:
		return try_combine(blocking_text, dir)

	if grid.move_text_char(self, grid_pos + dir):
		emit_signal("moved", self, grid_pos)
		grid.notify_text_changed()
		return true

	_shake()
	return false


func pull(dir: Vector2i) -> bool:
	if not can_pull or grid == null:
		_shake()
		return false

	if grid.move_text_char(self, grid_pos + dir):
		emit_signal("moved", self, grid_pos)
		grid.notify_text_changed()
		return true

	_shake()
	return false


func delete_char() -> void:
	if not can_delete:
		_shake()
		return

	if grid:
		grid.unregister_text_char(self)

	emit_signal("deleted", self)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.65, 0.65), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	await tween.finished
	queue_free()
	if grid:
		grid.notify_text_changed()


func split_char() -> Array:
	if not can_split or grid == null or grid.rule_manager == null:
		_shake()
		return []

	var parts: Array = grid.rule_manager.get_split_result(char_text)
	if parts.size() < 2:
		_shake()
		return []

	var second_pos: Vector2i = _find_split_position(String(parts[1]))
	if second_pos == INVALID_GRID_POS:
		_shake()
		return []

	var options: Dictionary = {
		"can_push": can_push,
		"can_pull": can_pull,
		"can_delete": can_delete,
		"can_split": true,
		"can_combine": can_combine,
	}

	grid.unregister_text_char(self)
	char_text = String(parts[0])
	update_visual()
	grid.register_text_char(self)

	var second: TextChar = grid.create_text_char(String(parts[1]), second_pos, options)
	_play_split_feedback(second)

	var result: Array = [self, second]
	emit_signal("split", self, result)
	grid.notify_text_changed()
	return result


func try_combine(other: Node, dir: Vector2i = Vector2i.ZERO) -> bool:
	if other == null or grid == null or grid.rule_manager == null:
		return false

	var other_text_char: TextChar = other as TextChar
	if other_text_char == null:
		return false
	if not can_combine or not other_text_char.can_combine:
		_shake()
		return false

	var left_text: String = char_text
	var right_text: String = other_text_char.char_text
	var result_pos: Vector2i = grid_pos
	if dir == Vector2i.LEFT or dir == Vector2i.UP:
		left_text = other_text_char.char_text
		right_text = char_text
		result_pos = other_text_char.grid_pos

	var result_text: String = grid.rule_manager.get_combine_result(left_text, right_text)
	if result_text.is_empty():
		_shake()
		return false

	if not grid.replace_text_char(self, result_text, result_pos, [self, other_text_char]):
		_shake()
		return false

	if is_instance_valid(other_text_char):
		other_text_char.queue_free()

	_play_combine_feedback()
	emit_signal("combined", self, result_text)
	grid.notify_text_changed()
	return true


func apply_grid_position(smooth: bool = true) -> void:
	if grid == null:
		return

	var target_position: Vector2 = grid.grid_to_world(grid_pos)
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()

	if smooth and is_inside_tree():
		_move_tween = create_tween()
		_move_tween.tween_property(self, "position", target_position, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		position = target_position


func update_visual() -> void:
	var size: int = _cell_size()
	var width: int = size * maxi(char_text.length(), 1)
	var rect: Vector2 = Vector2(width, size)

	if _background:
		_background.position = Vector2.ZERO
		_background.size = rect
		_background.color = Color("#3c3314") if _is_highlighted else Color("#101010")

	if _label:
		_label.position = Vector2.ZERO
		_label.size = rect
		_label.text = char_text
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_override("font", GLYPH_FONT)
		_label.add_theme_font_size_override("font_size", int(size * 0.72))
		_label.add_theme_color_override("font_color", Color("#ffeeb8") if _is_highlighted else Color.WHITE)

	if _collision:
		var shape: RectangleShape2D = _collision.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			_collision.shape = shape
		shape.size = rect
		_collision.position = rect * 0.5


func set_highlight(enabled: bool) -> void:
	_is_highlighted = enabled
	if _background:
		_background.color = Color("#3c3314") if enabled else Color("#101010")
	if _label:
		_label.add_theme_color_override("font_color", Color("#ffe36b") if enabled else Color.WHITE)
	if enabled:
		var tween: Tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.09)
		tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _register_with_parent_grid() -> void:
	if grid == null and get_parent() is TextGrid:
		grid = get_parent() as TextGrid
	if grid and not grid.has_text_char(self):
		grid.register_text_char(self)


func _find_split_position(text: String) -> Vector2i:
	for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var candidate: Vector2i = grid_pos + dir
		if grid.can_place_text(text, candidate, [self]):
			return candidate
	return INVALID_GRID_POS


func _cell_size() -> int:
	return grid.cell_size if grid else 72


func _play_split_feedback(second: TextChar) -> void:
	scale = Vector2(0.9, 0.9)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if second:
		second.scale = Vector2(0.9, 0.9)
		second.create_tween().tween_property(second, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_combine_feedback() -> void:
	scale = Vector2(1.18, 1.18)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake() -> void:
	var start: Vector2 = position
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", start + Vector2(6, 0), 0.035)
	tween.tween_property(self, "position", start + Vector2(-6, 0), 0.05)
	tween.tween_property(self, "position", start, 0.035)
