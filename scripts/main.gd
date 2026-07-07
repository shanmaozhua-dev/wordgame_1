extends Node2D

const GridWorld = preload("res://scripts/grid_world.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const PageCamera = preload("res://scripts/page_camera.gd")
const DemoRunner = preload("res://scripts/demo_runner.gd")
const OriginalFont = preload("res://Fonts/Zpix.tres")

var world := GridWorld.new()
var page_camera := PageCamera.new()
var demo := DemoRunner.new()
var entity_labels: Dictionary = {}
var player_label: Label
var map_layer: Node2D
var demo_timer: Timer

func _ready() -> void:
	world.load_level(LevelLoader.build_hero_trial_fist_level())
	page_camera.sync_to_world(world)
	_build_scene()
	_refresh_view()

func _unhandled_input(event: InputEvent) -> void:
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
			_apply_result(world.pull_front(direction))
		else:
			_apply_result(world.try_move_player(direction))
		return
	match key_event.keycode:
		KEY_SPACE:
			_apply_result(world.interact_front())
		KEY_BACKSPACE:
			_apply_result(world.delete_front())
		KEY_TAB:
			_apply_result(world.split_front())

func _build_scene() -> void:
	map_layer = Node2D.new()
	map_layer.name = "MapLayer"
	add_child(map_layer)
	player_label = _make_word_label("我", Color(0.92, 0.92, 0.92), Color(0.05, 0.05, 0.05))
	player_label.name = "Player"
	map_layer.add_child(player_label)
	demo_timer = Timer.new()
	demo_timer.wait_time = 0.55
	demo_timer.one_shot = true
	demo_timer.timeout.connect(_run_demo_step)
	add_child(demo_timer)
	_build_ui()

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	add_child(canvas)
	canvas.visible = false

func _refresh_view(_message := "") -> void:
	_sync_entity_labels()
	player_label.position = _grid_to_pixels(world.player_pos)
	page_camera.sync_to_world(world)
	map_layer.position = page_camera.offset_pixels()

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

func _make_word_label(text: String, font_color := Color.WHITE, bg_color := Color.BLACK) -> Label:
	var label := Label.new()
	label.text = text
	label.size = Vector2(max(1, text.length()) * world.cell_size, world.cell_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", roundi(world.cell_size * 0.74))
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
