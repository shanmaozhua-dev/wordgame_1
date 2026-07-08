extends Control

const TITLE_TEXTURES := [
	"res://Sprites/title/title_word_b_1.png",
	"res://Sprites/title/title_word_b_2.png",
	"res://Sprites/title/title_word_b_3.png",
	"res://Sprites/title/title_word_b_4.png",
]
const TITLE_FONT := preload("res://Fonts/Zpix.ttf")
const DEFAULT_START_SCENE := "res://Scenes/Maps/第一章/00_第一章字卡.tscn"
const BGM_PATH := "res://Sounds/bgm/ch1/BGM_title.ogg"
const CLICK_SE_PATH := "res://Sounds/se/menu_click.wav"
const SAVE_PATH := "user://save.wg"

const CHAPTERS := [
	{"name": "第一章", "entry": "字卡", "scene": "res://Scenes/Maps/第一章/00_第一章字卡.tscn"},
	{"name": "第二章", "entry": "字卡", "scene": "res://Scenes/Maps/第二章/00_第二章字卡.tscn"},
	{"name": "第三章", "entry": "字卡", "scene": "res://Scenes/Maps/第三章/00_第三章字卡.tscn"},
	{"name": "第四章", "entry": "字卡", "scene": "res://Scenes/Maps/第四章/00_第四章字卡.tscn"},
	{"name": "第五章", "entry": "字卡", "scene": "res://Scenes/Maps/第五章/00_第五章字卡.tscn"},
	{"name": "第六章", "entry": "假标题", "scene": "res://Scenes/Maps/第六章/01_1_偽結局_假標題.tscn"},
	{"name": "第七章", "entry": "字卡", "scene": "res://Scenes/Maps/第七章/00_第七章字卡.tscn"},
	{"name": "第八章", "entry": "心智打字机", "scene": "res://Scenes/Maps/第八章/心智打字機/MindTyper.tscn"},
]

var _continue_button: Button
var _status_label: Label
var _chapter_panel: PanelContainer
var _settings_panel: PanelContainer
var _quit_panel: PanelContainer
var _fade_panel: ColorRect
var _bgm_player: AudioStreamPlayer
var _se_player: AudioStreamPlayer
var _bgm_slider: HSlider
var _se_slider: HSlider
var _fullscreen_toggle: CheckButton
var _first_focus_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	focus_mode = Control.FOCUS_NONE
	Input.set_custom_mouse_cursor(null)
	_build_audio()
	_build_screen()
	_load_settings()
	_refresh_continue_button()
	_play_bgm()
	_fade_in()
	if _first_focus_button:
		_first_focus_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _chapter_panel.visible:
			_hide_panel(_chapter_panel)
		elif _settings_panel.visible:
			_hide_panel(_settings_panel)
		elif _quit_panel.visible:
			_hide_panel(_quit_panel)
		else:
			_show_panel(_quit_panel)


func _build_audio() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "MenuBGM"
	_bgm_player.bus = _bus_or_master("BGM")
	add_child(_bgm_player)

	_se_player = AudioStreamPlayer.new()
	_se_player.name = "MenuSE"
	_se_player.bus = _bus_or_master("SE")
	add_child(_se_player)


func _build_screen() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color("#070705")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_add_word_grid(background)

	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_bottom", 88)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.name = "Columns"
	columns.add_theme_constant_override("separation", 80)
	margin.add_child(columns)

	var left := VBoxContainer.new()
	left.name = "Primary"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 32)
	columns.add_child(left)

	left.add_child(_build_title())
	left.add_spacer(false)
	left.add_child(_build_menu())

	var right := VBoxContainer.new()
	right.name = "SideRail"
	right.custom_minimum_size = Vector2(430, 0)
	right.add_theme_constant_override("separation", 24)
	columns.add_child(right)
	right.add_child(_build_info_panel())

	_chapter_panel = _build_chapter_panel()
	add_child(_chapter_panel)

	_settings_panel = _build_settings_panel()
	add_child(_settings_panel)

	_quit_panel = _build_quit_panel()
	add_child(_quit_panel)

	_fade_panel = ColorRect.new()
	_fade_panel.name = "Fade"
	_fade_panel.color = Color.BLACK
	_fade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_panel)


func _build_title() -> Control:
	var wrap := VBoxContainer.new()
	wrap.name = "Title"
	wrap.add_theme_constant_override("separation", 18)

	var row := HBoxContainer.new()
	row.name = "TitleWords"
	row.add_theme_constant_override("separation", 12)
	wrap.add_child(row)

	for texture_path in TITLE_TEXTURES:
		var tile := TextureRect.new()
		tile.custom_minimum_size = Vector2(126, 156)
		tile.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(texture_path):
			tile.texture = load(texture_path)
		row.add_child(tile)

	var subtitle := Label.new()
	subtitle.text = "这是一段闯入文字的故事"
	subtitle.add_theme_font_override("font", TITLE_FONT)
	subtitle.add_theme_font_size_override("font_size", 36)
	subtitle.add_theme_color_override("font_color", Color("#f4ead2"))
	wrap.add_child(subtitle)

	var prompt := Label.new()
	prompt.text = "Enter / Space 确认    Esc 返回"
	prompt.add_theme_font_override("font", TITLE_FONT)
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", Color("#8f8a80"))
	wrap.add_child(prompt)

	return wrap


func _build_menu() -> Control:
	var box := VBoxContainer.new()
	box.name = "Menu"
	box.custom_minimum_size = Vector2(470, 0)
	box.add_theme_constant_override("separation", 14)

	_continue_button = _make_button("继续冒险")
	_continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(_continue_button)

	var new_game := _make_button("开始新冒险")
	new_game.pressed.connect(_on_new_game_pressed)
	_first_focus_button = new_game
	box.add_child(new_game)

	var chapters := _make_button("选择章节")
	chapters.pressed.connect(func(): _show_panel(_chapter_panel))
	box.add_child(chapters)

	var settings := _make_button("调整设定")
	settings.pressed.connect(func(): _show_panel(_settings_panel))
	box.add_child(settings)

	var quit := _make_button("离开游戏")
	quit.pressed.connect(func(): _show_panel(_quit_panel))
	box.add_child(quit)

	return box


func _build_info_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "SavePanel"
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#11100d"), Color("#ded0aa"), 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)

	var title := Label.new()
	title.text = "主界面"
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#f4ead2"))
	box.add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_override("font", TITLE_FONT)
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_color_override("font_color", Color("#b9b09d"))
	box.add_child(_status_label)

	return panel


func _build_chapter_panel() -> PanelContainer:
	var panel := _overlay_panel("ChapterPanel", Vector2(940, 640))
	var box := _panel_body(panel, "选择章节")

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	box.add_child(grid)

	for chapter in CHAPTERS:
		var button := _make_button("%s  %s" % [chapter.name, chapter.entry])
		button.custom_minimum_size = Vector2(380, 72)
		button.pressed.connect(_change_scene.bind(String(chapter.scene)))
		grid.add_child(button)

	var back := _make_button("返回")
	back.pressed.connect(func(): _hide_panel(panel))
	box.add_child(back)
	return panel


func _build_settings_panel() -> PanelContainer:
	var panel := _overlay_panel("SettingsPanel", Vector2(780, 520))
	var box := _panel_body(panel, "调整设定")

	_bgm_slider = _make_slider("音乐", box)
	_se_slider = _make_slider("音效", box)

	_fullscreen_toggle = CheckButton.new()
	_fullscreen_toggle.text = "全屏"
	_style_text_control(_fullscreen_toggle, 26)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	box.add_child(_fullscreen_toggle)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)

	var apply := _make_button("套用")
	apply.pressed.connect(_save_settings)
	buttons.add_child(apply)

	var back := _make_button("返回")
	back.pressed.connect(func(): _hide_panel(panel))
	buttons.add_child(back)

	return panel


func _build_quit_panel() -> PanelContainer:
	var panel := _overlay_panel("QuitPanel", Vector2(680, 330))
	var box := _panel_body(panel, "离开游戏")

	var label := Label.new()
	label.text = "确定要离开吗？"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_text_control(label, 30)
	box.add_child(label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)

	var yes := _make_button("确定")
	yes.pressed.connect(func():
		_play_click()
		get_tree().quit()
	)
	buttons.add_child(yes)

	var no := _make_button("取消")
	no.pressed.connect(func(): _hide_panel(panel))
	buttons.add_child(no)

	return panel


func _overlay_panel(node_name: String, min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.visible = false
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -min_size.x / 2.0
	panel.offset_top = -min_size.y / 2.0
	panel.offset_right = min_size.x / 2.0
	panel.offset_bottom = min_size.y / 2.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#11100df2"), Color("#f4ead2"), 2))
	return panel


func _panel_body(panel: PanelContainer, title_text: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	margin.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#f4ead2"))
	box.add_child(title)
	return box


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 64)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_text_control(button, 28)
	button.add_theme_stylebox_override("normal", _panel_style(Color("#14120f"), Color("#81775f"), 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#272016"), Color("#d7c58d"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#3a2b17"), Color("#f4ead2"), 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color("#201914"), Color("#f4ead2"), 3))
	button.add_theme_color_override("font_disabled_color", Color("#5d574b"))
	return button


func _make_slider(label_text: String, parent: VBoxContainer) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 42)
	_style_text_control(label, 26)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 0.7
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return slider


func _style_text_control(control: Control, size: int) -> void:
	control.add_theme_font_override("font", TITLE_FONT)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", Color("#f4ead2"))


func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _add_word_grid(parent: Control) -> void:
	for i in range(0, 18):
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.035)
		line.anchor_left = 0.0
		line.anchor_right = 1.0
		line.offset_left = 0
		line.offset_right = 0
		line.offset_top = 84 + i * 60
		line.offset_bottom = line.offset_top + 1
		parent.add_child(line)


func _refresh_continue_button() -> void:
	var has_save := FileAccess.file_exists(SAVE_PATH)
	_continue_button.disabled = not has_save
	_status_label.text = "检测到存档，可以继续冒险。" if has_save else "还没有检测到存档，可以从新冒险开始。"


func _on_continue_pressed() -> void:
	_play_click()
	if has_node("/root/Global") and get_node("/root/Global").has_method("load_game"):
		get_node("/root/Global").load_game()
	else:
		_status_label.text = "找到存档，但读取逻辑还没有接入。"


func _on_new_game_pressed() -> void:
	_play_click()
	_change_scene(DEFAULT_START_SCENE)


func _change_scene(scene_path: String) -> void:
	_play_click()
	if not ResourceLoader.exists(scene_path):
		_status_label.text = "场景不存在：%s" % scene_path
		return

	_fade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_panel, "modulate:a", 1.0, 0.35).from(_fade_panel.modulate.a)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)


func _show_panel(panel: PanelContainer) -> void:
	_play_click()
	_chapter_panel.visible = false
	_settings_panel.visible = false
	_quit_panel.visible = false
	panel.visible = true
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.12)


func _hide_panel(panel: PanelContainer) -> void:
	_play_click()
	panel.visible = false


func _fade_in() -> void:
	_fade_panel.modulate.a = 1.0
	create_tween().tween_property(_fade_panel, "modulate:a", 0.0, 0.5)


func _play_bgm() -> void:
	if ResourceLoader.exists(BGM_PATH):
		_bgm_player.stream = load(BGM_PATH)
		_bgm_player.play()


func _play_click() -> void:
	if ResourceLoader.exists(CLICK_SE_PATH):
		_se_player.stream = load(CLICK_SE_PATH)
		_se_player.play()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://main_menu.cfg") == OK:
		_bgm_slider.value = float(cfg.get_value("audio", "bgm", 0.7))
		_se_slider.value = float(cfg.get_value("audio", "se", 0.8))
		_fullscreen_toggle.button_pressed = bool(cfg.get_value("video", "fullscreen", false))
	_apply_audio_settings()


func _save_settings() -> void:
	_play_click()
	_apply_audio_settings()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "bgm", _bgm_slider.value)
	cfg.set_value("audio", "se", _se_slider.value)
	cfg.set_value("video", "fullscreen", _fullscreen_toggle.button_pressed)
	cfg.save("user://main_menu.cfg")
	_status_label.text = "设定已保存。"
	_hide_panel(_settings_panel)


func _apply_audio_settings() -> void:
	_set_bus_volume(_bus_or_master("BGM"), float(_bgm_slider.value))
	_set_bus_volume(_bus_or_master("SE"), float(_se_slider.value))


func _set_bus_volume(bus: StringName, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(value, 0.001)))
	AudioServer.set_bus_mute(idx, value <= 0.001)


func _on_fullscreen_toggled(enabled: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _bus_or_master(bus_name: String) -> StringName:
	return StringName(bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Master")
