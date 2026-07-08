extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const MapEditorIO = preload("res://scripts/map_editor_io.gd")
const MapEditorOps = preload("res://scripts/map_editor_ops.gd")
const PageCamera = preload("res://scripts/page_camera.gd")
const DemoRunner = preload("res://scripts/demo_runner.gd")
const HeroTrialFlow = preload("res://scripts/hero_trial_flow.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")

const FONT_SIZE_RATIO := 0.78
const EDITOR_SAVE_PATH := "res://levels/hero_trial_fist_edit.json"

var world := GridWorld.new()
var hero_trial_flow := HeroTrialFlow.new()
var page_camera := PageCamera.new()
var demo := DemoRunner.new()
var entity_labels: Dictionary = {}
var player_label: Label
var map_layer: Node2D
var demo_timer: Timer
var edit_mode := false
var grid_visible := true
var selected_cell := Vector2i.ZERO
var selection_anchor := Vector2i.ZERO
var selection_start := Vector2i.ZERO
var selection_end := Vector2i.ZERO
var selecting_rect := false
var dragging_selection := false
var drag_start_cell := Vector2i.ZERO
var drag_preview_origin := Vector2i.ZERO
var grid_layer: Node2D
var selection_rect: ColorRect
var editor_canvas: CanvasLayer
var editor_status: Label
var cell_input: LineEdit
var _syncing_input := false
var editor_dirty := false
var editor_notice := ""

func _ready() -> void:
	var result := hero_trial_flow.load_start_scene(world)
	if not result.success:
		world.load_level(LevelLoader.build_hero_trial_fist_level())
		editor_notice = str(result.get("message", "读取勇者试炼起始场景失败"))
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_F9:
			_toggle_edit_mode()
			get_viewport().set_input_as_handled()
			return
	if edit_mode and _handle_editor_input(event):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if edit_mode:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	var direction := _direction_from_key(key_event.keycode)
	if key_event.keycode == KEY_F5:
		demo.start()
		_run_demo_step()
		return
	if direction != Vector2i.ZERO:
		if key_event.alt_pressed:
			_apply_player_result(world.pull_front(direction))
		else:
			_apply_player_result(world.try_move_player(direction))
		return
	match key_event.keycode:
		KEY_SPACE:
			var flow_result := hero_trial_flow.handle_space(world)
			if flow_result.success:
				_apply_result(flow_result)
			else:
				_apply_result(world.interact_front())
		KEY_BACKSPACE:
			_apply_player_result(world.delete_front())
		KEY_TAB:
			_apply_player_result(world.split_front())

func _build_scene() -> void:
	map_layer = Node2D.new()
	map_layer.name = "MapLayer"
	add_child(map_layer)
	grid_layer = Node2D.new()
	grid_layer.name = "EditorGrid"
	grid_layer.z_index = 100
	grid_layer.visible = false
	map_layer.add_child(grid_layer)
	selection_rect = ColorRect.new()
	selection_rect.name = "EditorSelection"
	selection_rect.color = Color(0.2, 0.65, 1.0, 0.28)
	selection_rect.size = Vector2(world.cell_size, world.cell_size)
	selection_rect.z_index = 101
	selection_rect.visible = false
	map_layer.add_child(selection_rect)
	player_label = _make_word_label("我", Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	player_label.z_index = 10
	map_layer.add_child(player_label)
	demo_timer = Timer.new()
	demo_timer.wait_time = 0.55
	demo_timer.one_shot = true
	demo_timer.timeout.connect(_run_demo_step)
	add_child(demo_timer)
	_build_ui()
	_rebuild_editor_grid()

func _build_ui() -> void:
	editor_canvas = CanvasLayer.new()
	editor_canvas.name = "EditorCanvas"
	add_child(editor_canvas)
	editor_canvas.visible = false
	editor_status = Label.new()
	editor_status.name = "EditorStatus"
	editor_status.position = Vector2(8, 8)
	editor_status.size = Vector2(950, 30)
	editor_status.add_theme_font_override("font", OriginalFont)
	editor_status.add_theme_font_size_override("font_size", 16)
	editor_status.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	editor_canvas.add_child(editor_status)
	cell_input = LineEdit.new()
	cell_input.name = "CellInput"
	cell_input.size = Vector2(56, 30)
	cell_input.max_length = 1
	cell_input.add_theme_font_override("font", OriginalFont)
	cell_input.add_theme_font_size_override("font_size", 20)
	cell_input.text_changed.connect(_on_editor_text_changed)
	editor_canvas.add_child(cell_input)

func _refresh_view(_message := "") -> void:
	_sync_entity_labels()
	player_label.position = _grid_to_pixels(world.player_pos)
	page_camera.sync_to_world(world)
	map_layer.position = page_camera.offset_pixels()
	_sync_editor_overlay()

func _sync_entity_labels() -> void:
	var alive := {}
	for entity in world.entities.values():
		alive[entity.id] = true
		var label: Label = entity_labels.get(entity.id)
		if not label:
			label = _make_word_label(entity.text)
			entity_labels[entity.id] = label
			map_layer.add_child(label)
		label.text = entity.text
		label.position = _grid_to_pixels(entity.grid_pos)
		label.size = Vector2(max(1, entity.text.length()) * world.cell_size, world.cell_size)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.32) if entity.highlighted else Color.WHITE)
	for id in entity_labels.keys():
		if not alive.has(id):
			entity_labels[id].queue_free()
			entity_labels.erase(id)

func _apply_result(result: Dictionary) -> void:
	_refresh_view(str(result.get("message", "")))

func _apply_player_result(result: Dictionary) -> void:
	if result.success:
		var flow_result := hero_trial_flow.sync_after_player_action(world)
		if flow_result.success:
			result = flow_result
	_refresh_view(str(result.get("message", "")))

func _run_demo_step() -> void:
	var result := demo.step(world)
	_apply_result(result)
	if demo.running:
		demo_timer.start()

func _direction_from_key(keycode: Key) -> Vector2i:
	match keycode:
		KEY_RIGHT:
			return Vector2i(1, 0)
		KEY_LEFT:
			return Vector2i(-1, 0)
		KEY_DOWN:
			return Vector2i(0, 1)
		KEY_UP:
			return Vector2i(0, -1)
	return Vector2i.ZERO

func _grid_to_pixels(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * world.cell_size, pos.y * world.cell_size)

func _toggle_edit_mode() -> void:
	edit_mode = not edit_mode
	selected_cell = world.player_pos
	editor_canvas.visible = edit_mode
	grid_layer.visible = edit_mode and grid_visible
	selection_rect.visible = edit_mode
	if edit_mode:
		_set_selected_cell(selected_cell)
	else:
		cell_input.release_focus()
	_refresh_view()

func _handle_editor_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _mouse_to_cell(mouse_event.position)
			if mouse_event.pressed:
				if _selection_cells().has(cell):
					dragging_selection = true
					drag_start_cell = cell
					drag_preview_origin = _selection_min()
				else:
					selecting_rect = true
					selection_anchor = cell
					_set_selection(cell, cell)
			else:
				if dragging_selection:
					var target_origin := _selection_min() + (cell - drag_start_cell)
					_move_selection_to(target_origin)
				selecting_rect = false
				dragging_selection = false
			return true
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		var cell := _mouse_to_cell(motion_event.position)
		if selecting_rect:
			_set_selection(selection_anchor, cell)
			return true
		if dragging_selection:
			drag_preview_origin = _selection_min() + (cell - drag_start_cell)
			_sync_editor_overlay()
			return true
	if not event is InputEventKey or not event.pressed or event.echo:
		return false
	var key_event := event as InputEventKey
	if key_event.ctrl_pressed and key_event.keycode == KEY_S:
		_save_editor_level()
		return true
	if key_event.ctrl_pressed and key_event.keycode == KEY_R:
		_load_editor_level()
		return true
	if key_event.keycode == KEY_F10:
		grid_visible = not grid_visible
		_sync_editor_overlay()
		return true
	if key_event.alt_pressed:
		match key_event.keycode:
			KEY_P:
				_toggle_selection_flag("pushable")
				return true
			KEY_D:
				_toggle_selection_flag("deletable")
				return true
			KEY_S:
				_toggle_selection_flag("solid")
				return true
	var direction := _direction_from_key(key_event.keycode)
	if direction != Vector2i.ZERO:
		_set_selection(selection_start + direction, selection_end + direction)
		return true
	if key_event.keycode == KEY_BACKSPACE or key_event.keycode == KEY_DELETE:
		_set_selection_text("")
		return true
	return false

func _set_selected_cell(cell: Vector2i) -> void:
	var clamped := Vector2i(
		clampi(cell.x, 0, world.screen_size.x - 1),
		clampi(cell.y, 0, world.screen_size.y - 1)
	)
	_set_selection(clamped, clamped)

func _set_selection(a: Vector2i, b: Vector2i) -> void:
	selection_start = _clamp_cell(a)
	selection_end = _clamp_cell(b)
	selected_cell = selection_end
	_syncing_input = true
	cell_input.text = _selection_text_for_input()
	cell_input.position = map_layer.position + _grid_to_pixels(_selection_min()) + Vector2(0, _selection_size().y * world.cell_size + 2)
	_syncing_input = false
	cell_input.grab_focus()
	cell_input.select_all()
	_sync_editor_overlay()

func _clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, world.screen_size.x - 1),
		clampi(cell.y, 0, world.screen_size.y - 1)
	)

func _mouse_to_cell(mouse_pos: Vector2) -> Vector2i:
	var local := mouse_pos - map_layer.position
	return _clamp_cell(Vector2i(floori(local.x / world.cell_size), floori(local.y / world.cell_size)))

func _on_editor_text_changed(new_text: String) -> void:
	if _syncing_input:
		return
	_set_selection_text(new_text)

func _set_selection_text(text: String) -> void:
	var clean := text.strip_edges()
	if clean.length() > 1:
		clean = clean.substr(0, 1)
	if clean.is_empty():
		MapEditorOps.clear_cells(world, _selection_cells())
	else:
		MapEditorOps.fill_cells(world, _selection_cells(), clean)
	_mark_editor_dirty()
	_refresh_view()
	_syncing_input = true
	cell_input.text = clean
	_syncing_input = false
	cell_input.grab_focus()
	cell_input.select_all()

func _selection_text_for_input() -> String:
	if _selection_cells().size() != 1:
		return ""
	var entity := _find_entity_at_any(selected_cell)
	if entity:
		return entity.text
	return ""

func _find_entity_at_any(pos: Vector2i) -> RefCounted:
	for entity in world.entities.values():
		if entity.cells.has(pos):
			return entity
	return null

func _toggle_selection_flag(flag: String) -> void:
	MapEditorOps.toggle_flag(world, _selection_cells(), flag)
	_mark_editor_dirty()
	_refresh_view()

func _move_selection_to(target_origin: Vector2i) -> void:
	var clamped_origin := _clamp_move_origin(target_origin)
	if clamped_origin == _selection_min():
		_set_selection(selection_start, selection_end)
		return
	MapEditorOps.move_rect(world, selection_start, selection_end, clamped_origin)
	var size := _selection_size()
	_set_selection(clamped_origin, clamped_origin + size - Vector2i.ONE)
	_mark_editor_dirty()
	_refresh_view()

func _clamp_move_origin(origin: Vector2i) -> Vector2i:
	var size := _selection_size()
	return Vector2i(
		clampi(origin.x, 0, world.screen_size.x - size.x),
		clampi(origin.y, 0, world.screen_size.y - size.y)
	)

func _selection_min() -> Vector2i:
	return Vector2i(mini(selection_start.x, selection_end.x), mini(selection_start.y, selection_end.y))

func _selection_max() -> Vector2i:
	return Vector2i(maxi(selection_start.x, selection_end.x), maxi(selection_start.y, selection_end.y))

func _selection_size() -> Vector2i:
	var from := _selection_min()
	var to := _selection_max()
	return to - from + Vector2i.ONE

func _selection_cells() -> Array[Vector2i]:
	return MapEditorOps.cells_in_rect(selection_start, selection_end)

func _save_editor_level() -> void:
	_ensure_editor_save_dir()
	var result := MapEditorIO.save_editor_data(EDITOR_SAVE_PATH, MapEditorIO.world_to_editor_data(world))
	if result.success:
		editor_dirty = false
		editor_notice = "已保存：%s" % EDITOR_SAVE_PATH
		_update_editor_status()
	else:
		editor_notice = str(result.get("message", "保存失败"))
		_update_editor_status()

func _load_editor_level() -> void:
	var loaded := MapEditorIO.load_editor_data(EDITOR_SAVE_PATH)
	if not loaded.success:
		editor_notice = str(loaded.get("message", "读取失败"))
		_update_editor_status()
		return
	world.load_level(MapEditorIO.editor_data_to_level(loaded.data))
	editor_dirty = false
	editor_notice = "已读取：%s" % EDITOR_SAVE_PATH
	_rebuild_editor_grid()
	_set_selected_cell(selected_cell)
	_refresh_view()

func _ensure_editor_save_dir() -> void:
	var absolute_dir := ProjectSettings.globalize_path(EDITOR_SAVE_PATH.get_base_dir())
	DirAccess.make_dir_recursive_absolute(absolute_dir)

func _rebuild_editor_grid() -> void:
	for child in grid_layer.get_children():
		child.queue_free()
	var color := Color(0.35, 0.55, 0.75, 0.38)
	var width := world.screen_size.x * world.cell_size
	var height := world.screen_size.y * world.cell_size
	for x in range(world.screen_size.x + 1):
		_add_grid_line(Vector2(x * world.cell_size, 0), Vector2(x * world.cell_size, height), color)
	for y in range(world.screen_size.y + 1):
		_add_grid_line(Vector2(0, y * world.cell_size), Vector2(width, y * world.cell_size), color)

func _add_grid_line(from: Vector2, to: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	grid_layer.add_child(line)

func _sync_editor_overlay() -> void:
	if not grid_layer:
		return
	grid_layer.visible = edit_mode and grid_visible
	selection_rect.visible = edit_mode
	var rect_origin := drag_preview_origin if dragging_selection else _selection_min()
	var rect_size := _selection_size()
	selection_rect.position = _grid_to_pixels(rect_origin)
	selection_rect.size = Vector2(rect_size.x * world.cell_size, rect_size.y * world.cell_size)
	if edit_mode and cell_input:
		cell_input.position = map_layer.position + _grid_to_pixels(_selection_min()) + Vector2(0, rect_size.y * world.cell_size + 2)
	_update_editor_status()

func _mark_editor_dirty() -> void:
	editor_dirty = true
	editor_notice = "未保存"

func _update_editor_status() -> void:
	if not editor_status:
		return
	var entity := _find_entity_at_any(selected_cell)
	var flags := "空"
	if _selection_cells().size() > 1:
		flags = "选区=%s格" % _selection_cells().size()
	elif entity:
		flags = "字=%s solid=%s push=%s del=%s tags=%s" % [entity.text, entity.solid, entity.pushable, entity.deletable, ",".join(entity.tags)]
	var save_state := "未保存" if editor_dirty else "已保存"
	var suffix := " | %s" % editor_notice if not editor_notice.is_empty() else ""
	var from := _selection_min()
	var to := _selection_max()
	editor_status.text = "编辑模式 F9退出 F10网格 Ctrl+S保存 Ctrl+R读取 Alt+P/D/S属性 | %s | 选区=(%s,%s)-(%s,%s) %s%s" % [save_state, from.x, from.y, to.x, to.y, flags, suffix]

func _make_word_label(text: String, font_color := Color.WHITE, bg_color := Color.BLACK) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(max(1, text.length()) * world.cell_size, world.cell_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size_for_cell(world.cell_size))
	label.add_theme_font_override("font", OriginalFont)
	label.add_theme_color_override("font_color", font_color)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	label.add_theme_stylebox_override("normal", style)
	return label

static func font_size_for_cell(render_cell_size: int) -> int:
	return roundi(render_cell_size * FONT_SIZE_RATIO)
