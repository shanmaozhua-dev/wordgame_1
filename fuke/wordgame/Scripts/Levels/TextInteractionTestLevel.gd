extends Node2D

const CELL_SIZE = 72
const GLYPH_FONT = preload("res://Fonts/Zpix.ttf")
const PLAYER_SCENE = preload("res://Scenes/Player/TestPlayer.tscn")

var grid: TextGrid
var rule_manager: TextRuleManager
var level_events: LevelEventManager
var player: TestGridPlayer
var status_label: Label
var weather_overlay: ColorRect


func _ready() -> void:
	_build_background()
	_build_grid()
	_build_ui()
	_build_level_events()
	_build_player()
	_spawn_text_objects()
	grid.notify_text_changed()


func _build_background() -> void:
	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.position = Vector2.ZERO
	background.size = Vector2(1920, 1080)
	background.color = Color("#080908")
	add_child(background)

	weather_overlay = ColorRect.new()
	weather_overlay.name = "WeatherOverlay"
	weather_overlay.position = Vector2.ZERO
	weather_overlay.size = Vector2(1920, 1080)
	weather_overlay.color = Color(0.06, 0.06, 0.08, 0.0)
	add_child(weather_overlay)

	var line_color: Color = Color(1, 1, 1, 0.055)
	for x in range(0, 25):
		var line: ColorRect = ColorRect.new()
		line.position = Vector2(x * CELL_SIZE, 0)
		line.size = Vector2(1, CELL_SIZE * 14)
		line.color = line_color
		add_child(line)
	for y in range(0, 15):
		var line: ColorRect = ColorRect.new()
		line.position = Vector2(0, y * CELL_SIZE)
		line.size = Vector2(CELL_SIZE * 24, 1)
		line.color = line_color
		add_child(line)


func _build_grid() -> void:
	grid = TextGrid.new()
	grid.name = "TextGrid"
	grid.cell_size = CELL_SIZE
	grid.bounds = Rect2i(0, 0, 24, 14)
	add_child(grid)


func _build_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "InfoPanel"
	panel.position = Vector2(1240, 36)
	panel.size = Vector2(620, 470)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#11100ded"), Color("#bfa96b"), 2))
	canvas.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = _make_label("文字对象 / 字体交互测试", 30, Color("#ffeeb8"))
	box.add_child(title)

	var guide: Label = _make_label(
		"WASD / 方向键：移动、面向文字\n" +
		"Backspace / Delete：删除面前的“删”\n" +
		"方向键撞字：推动“推”或“天”\n" +
		"Alt + 反方向：拉动面前的“推”\n" +
		"Tab：拆开面前的“戏”，再推动“又”撞“戈”合成\n" +
		"把“天”推向“气很好”：触发天气很好，开门后走到“器”",
		22,
		Color("#d8ceb5")
	)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(guide)

	status_label = _make_label("先删除路上的“删”，再测试推、拉、拆、合和造句。", 24, Color("#93d7ff"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)


func _build_level_events() -> void:
	var door: Node2D = _make_world_tile("门", Vector2i(13, 3), Color("#433225"), Color("#ffeeb8"))
	door.name = "ArtifactDoor"
	add_child(door)

	var artifact: Node2D = _make_world_tile("器", Vector2i(15, 3), Color("#2a2844"), Color("#e7ddff"))
	artifact.name = "Artifact"
	add_child(artifact)

	level_events = LevelEventManager.new()
	level_events.name = "LevelEventManager"
	level_events.door_cell = Vector2i(13, 3)
	level_events.artifact_cell = Vector2i(15, 3)
	add_child(level_events)
	level_events.setup(grid, status_label, door, artifact, weather_overlay)

	rule_manager = TextRuleManager.new()
	rule_manager.name = "TextRuleManager"
	add_child(rule_manager)
	rule_manager.setup(grid, level_events, status_label)


func _build_player() -> void:
	player = PLAYER_SCENE.instantiate() as TestGridPlayer
	if player == null:
		return
	player.name = "Player"
	player.grid_pos = Vector2i(3, 3)
	add_child(player)
	player.setup(grid, level_events, status_label)


func _spawn_text_objects() -> void:
	grid.create_text_char("删", Vector2i(5, 3), {
		"can_push": false,
		"can_pull": false,
		"can_delete": true,
		"can_split": false,
		"can_combine": false,
	})

	grid.create_text_char("推", Vector2i(5, 5), {
		"can_push": true,
		"can_pull": true,
		"can_delete": false,
		"can_split": false,
		"can_combine": false,
	})

	grid.create_text_char("戏", Vector2i(5, 8), {
		"can_push": true,
		"can_pull": true,
		"can_delete": true,
		"can_split": true,
		"can_combine": true,
	})

	grid.create_text_char("天", Vector2i(7, 3), {
		"can_push": true,
		"can_pull": true,
		"can_delete": false,
		"can_split": false,
		"can_combine": true,
	})

	grid.create_text_char("气很好", Vector2i(8, 3), {
		"can_push": false,
		"can_pull": false,
		"can_delete": false,
		"can_split": false,
		"can_combine": true,
	})


func _make_world_tile(text: String, cell: Vector2i, bg_color: Color, text_color: Color) -> Node2D:
	var node: Node2D = Node2D.new()
	node.position = Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(CELL_SIZE, CELL_SIZE)
	bg.color = bg_color
	node.add_child(bg)

	var label: Label = _make_label(text, 48, text_color)
	label.size = Vector2(CELL_SIZE, CELL_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_child(label)

	return node


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", GLYPH_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
