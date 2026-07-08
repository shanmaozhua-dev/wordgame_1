class_name TestGridPlayer
extends Node2D

const GLYPH_FONT = preload("res://Fonts/Zpix.ttf")

@export var grid_path: NodePath
@export var level_event_manager_path: NodePath
@export var grid_pos: Vector2i = Vector2i(3, 3)

var grid: TextGrid
var level_event_manager: LevelEventManager
var facing: Vector2i = Vector2i.RIGHT
var status_label: Label
var _move_tween: Tween

@onready var _background: ColorRect = $Background
@onready var _label: Label = $Label
@onready var _arrow: Line2D = $FacingArrow


func _ready() -> void:
	_resolve_paths()
	update_visual()
	_apply_grid_position(false)


func setup(grid_node: TextGrid, level_events: LevelEventManager, status: Label = null) -> void:
	grid = grid_node
	level_event_manager = level_events
	status_label = status
	_apply_grid_position(false)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var dir: Vector2i = _direction_from_key(key_event.keycode)
	if dir != Vector2i.ZERO:
		_handle_direction(dir, key_event.alt_pressed)
		get_viewport().set_input_as_handled()
		return

	match key_event.keycode:
		KEY_BACKSPACE, KEY_DELETE:
			_delete_front()
			get_viewport().set_input_as_handled()
		KEY_TAB:
			_split_front()
			get_viewport().set_input_as_handled()


func update_visual() -> void:
	var size: int = _cell_size()
	if _background:
		_background.size = Vector2(size, size)
		_background.color = Color("#243447")
	if _label:
		_label.size = Vector2(size, size)
		_label.text = "我"
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_override("font", GLYPH_FONT)
		_label.add_theme_font_size_override("font_size", int(size * 0.72))
		_label.add_theme_color_override("font_color", Color.WHITE)
	_update_arrow()


func _handle_direction(dir: Vector2i, is_pull_input: bool) -> void:
	if grid == null:
		return

	if is_pull_input and _try_pull(dir):
		return

	facing = dir
	_update_arrow()

	var target_cell: Vector2i = grid_pos + dir
	var text_char: TextChar = grid.get_text_at(target_cell)
	if text_char:
		if text_char.push(dir):
			_set_status("推动：%s" % text_char.char_text)
		else:
			_set_status("这个字推不动。")
		return

	if grid.can_player_enter(target_cell):
		grid_pos = target_cell
		_apply_grid_position(true)
		_check_level_position()
	else:
		_bump()


func _try_pull(move_dir: Vector2i) -> bool:
	var opposite_facing: Vector2i = Vector2i(-facing.x, -facing.y)
	if move_dir != opposite_facing:
		_set_status("拉字：先面对字，再按 Alt + 反方向。")
		return false

	var text_char: TextChar = grid.get_text_at(grid_pos + facing)
	if text_char == null:
		return false
	if not text_char.can_pull:
		_set_status("这个字不能拉。")
		return false
	if not grid.can_player_enter(grid_pos + move_dir):
		_set_status("身后没有空位，拉不动。")
		return false

	var old_player_cell: Vector2i = grid_pos
	grid_pos += move_dir
	_apply_grid_position(true)
	if text_char.pull(move_dir):
		_set_status("拉动：%s" % text_char.char_text)
		_check_level_position()
		return true

	grid_pos = old_player_cell
	_apply_grid_position(true)
	return false


func _delete_front() -> void:
	if grid == null:
		return
	var text_char: TextChar = grid.get_text_at(grid_pos + facing)
	if text_char == null:
		_set_status("面前没有可删除文字。")
		return
	if not text_char.can_delete:
		_set_status("这个字不能删除。")
		text_char.call("_shake")
		return
	_set_status("删除：%s" % text_char.char_text)
	text_char.delete_char()


func _split_front() -> void:
	if grid == null:
		return
	var text_char: TextChar = grid.get_text_at(grid_pos + facing)
	if text_char == null:
		_set_status("面前没有可拆文字。")
		return
	var parts: Array = text_char.split_char()
	if parts.is_empty():
		_set_status("这个字没有拆字规则。")
	else:
		_set_status("拆字完成：戏 -> 又 + 戈")


func _direction_from_key(keycode: int) -> Vector2i:
	match keycode:
		KEY_UP, KEY_W:
			return Vector2i.UP
		KEY_DOWN, KEY_S:
			return Vector2i.DOWN
		KEY_LEFT, KEY_A:
			return Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			return Vector2i.RIGHT
	return Vector2i.ZERO


func _apply_grid_position(smooth: bool) -> void:
	if grid == null:
		return
	var target: Vector2 = grid.grid_to_world(grid_pos)
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	if smooth and is_inside_tree():
		_move_tween = create_tween()
		_move_tween.tween_property(self, "position", target, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		position = target


func _check_level_position() -> void:
	if level_event_manager and level_event_manager.has_method("check_player_position"):
		level_event_manager.check_player_position(grid_pos)


func _update_arrow() -> void:
	if _arrow == null:
		return
	var size: int = _cell_size()
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	var end: Vector2 = center + Vector2(facing.x, facing.y) * size * 0.42
	_arrow.clear_points()
	_arrow.add_point(center)
	_arrow.add_point(end)


func _cell_size() -> int:
	return grid.cell_size if grid else 72


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _bump() -> void:
	_set_status("前方被挡住。")
	var start: Vector2 = position
	var offset: Vector2 = Vector2(facing.x, facing.y) * 6.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", start + offset, 0.04)
	tween.tween_property(self, "position", start, 0.06)


func _resolve_paths() -> void:
	if grid_path != NodePath() and has_node(grid_path):
		grid = get_node(grid_path) as TextGrid
	if level_event_manager_path != NodePath() and has_node(level_event_manager_path):
		level_event_manager = get_node(level_event_manager_path) as LevelEventManager
