extends Control

const TITLE_SCENE := preload("res://Scenes/Animations/game_title.tscn")
const TITLE_FONT := preload("res://Fonts/Zpix.ttf")

const DEFAULT_START_SCENE := "res://Scenes/Maps/第一章/00_第一章字卡.tscn"
const BGM_PATH := "res://Sounds/bgm/ch1/BGM_title.ogg"
const CLICK_SE_PATH := "res://Sounds/se/menu_click.wav"
const SETTINGS_PATH := "user://main_menu.cfg"

const TITLE_TEXT := "這是一段關於　的故事"
const START_TEXT := "我開始冒險"
const SETTINGS_TEXT := "調整設定"

const TITLE_POSITION := Vector2(0, -60)
const CAPTION_RECT := Rect2(0, 780, 1920, 84)
const MESSAGE_RECT := Rect2(0, 1050, 1920, 44)
const OPTIONS_POSITION := Vector2(0, 900)
const OPTIONS_SIZE := Vector2(1920, 96)

var _title_logo: Node2D
var _start_button: Button
var _settings_button: Button
var _settings_panel: Control
var _fade_panel: ColorRect
var _message_label: Label
var _bgm_player: AudioStreamPlayer
var _se_player: AudioStreamPlayer
var _bgm_slider: HSlider
var _se_slider: HSlider
var _fullscreen_toggle: CheckButton


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.set_custom_mouse_cursor(null)

	_build_audio()
	_build_screen()
	_load_settings()
	_play_bgm()
	_fade_in()
	_play_title_animation()
	_start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings_panel.visible:
			_hide_settings()
		else:
			get_tree().quit()


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
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_title_logo = TITLE_SCENE.instantiate()
	_title_logo.name = "Logo"
	_title_logo.position = TITLE_POSITION
	add_child(_title_logo)

	var caption := _make_label(TITLE_TEXT, 54, Color(0.78, 0.78, 0.78, 1.0))
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = CAPTION_RECT.position
	caption.size = CAPTION_RECT.size
	add_child(caption)

	_build_menu()
	_build_settings_panel()

	_message_label = _make_label("", 24, Color(0.55, 0.55, 0.55, 1.0))
	_message_label.name = "Message"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.position = MESSAGE_RECT.position
	_message_label.size = MESSAGE_RECT.size
	add_child(_message_label)

	_fade_panel = ColorRect.new()
	_fade_panel.name = "Fade"
	_fade_panel.color = Color.BLACK
	_fade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_panel)


func _build_menu() -> void:
	var options := HBoxContainer.new()
	options.name = "Options"
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 170)
	options.position = OPTIONS_POSITION
	options.size = OPTIONS_SIZE
	add_child(options)

	_start_button = _make_menu_button(START_TEXT)
	_start_button.pressed.connect(_on_start_pressed)
	options.add_child(_start_button)

	_settings_button = _make_menu_button(SETTINGS_TEXT)
	_settings_button.pressed.connect(_show_settings)
	options.add_child(_settings_button)


func _play_title_animation() -> void:
	var player := _title_logo.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not player:
		return

	player.play("Start")
	await player.animation_finished
	player.play("Loop")


func _build_settings_panel() -> void:
	_settings_panel = Control.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.visible = false
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_settings_panel)

	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_panel.add_child(background)

	var title := _make_label(SETTINGS_TEXT, 64, Color(0.82, 0.82, 0.82, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 180)
	title.size = Vector2(1920, 90)
	_settings_panel.add_child(title)

	var panel := VBoxContainer.new()
	panel.position = Vector2(540, 376)
	panel.size = Vector2(840, 440)
	panel.add_theme_constant_override("separation", 38)
	_settings_panel.add_child(panel)

	_bgm_slider = _make_slider_row(panel, "背景音樂")
	_se_slider = _make_slider_row(panel, "系統音效")

	_fullscreen_toggle = CheckButton.new()
	_fullscreen_toggle.text = "全螢幕"
	_fullscreen_toggle.toggle_mode = true
	_style_text_control(_fullscreen_toggle, 42, Color(0.78, 0.78, 0.78, 1.0))
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	panel.add_child(_fullscreen_toggle)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 120)
	panel.add_child(actions)

	var apply := _make_menu_button("套用")
	apply.custom_minimum_size = Vector2(220, 78)
	apply.pressed.connect(_save_settings)
	actions.add_child(apply)

	var back := _make_menu_button("返回畫面")
	back.custom_minimum_size = Vector2(300, 78)
	back.pressed.connect(_hide_settings)
	actions.add_child(back)


func _make_slider_row(parent: VBoxContainer, label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	parent.add_child(row)

	var label := _make_label(label_text, 42, Color(0.78, 0.78, 0.78, 1.0))
	label.custom_minimum_size = Vector2(360, 62)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 0.7
	slider.custom_minimum_size = Vector2(420, 62)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	return slider


func _make_menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.custom_minimum_size = Vector2(360, 86)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_text_control(button, 58, Color(0.78, 0.78, 0.78, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.92, 0.92, 0.92, 1.0))
	button.add_theme_stylebox_override("normal", _empty_style())
	button.add_theme_stylebox_override("hover", _empty_style())
	button.add_theme_stylebox_override("pressed", _empty_style())
	button.add_theme_stylebox_override("focus", _focus_style())
	return button


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	_style_text_control(label, size, color)
	label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.20))
	label.add_theme_constant_override("shadow_outline_size", 6)
	return label


func _style_text_control(control: Control, size: int, color: Color) -> void:
	control.add_theme_font_override("font", TITLE_FONT)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)


func _empty_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _focus_style() -> StyleBoxFlat:
	var style := _empty_style()
	style.border_color = Color(1, 1, 1, 0.45)
	style.set_border_width_all(2)
	return style


func _on_start_pressed() -> void:
	_play_click()
	if has_node("/root/Global") and get_node("/root/Global").has_method("start_game"):
		get_node("/root/Global").start_game()
		return
	if ResourceLoader.exists(DEFAULT_START_SCENE):
		_change_scene(DEFAULT_START_SCENE)
	else:
		_message_label.text = "冒險入口尚未接入。"


func _change_scene(scene_path: String) -> void:
	_fade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_panel, "modulate:a", 1.0, 0.35).from(_fade_panel.modulate.a)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)


func _show_settings() -> void:
	_play_click()
	_message_label.text = ""
	_settings_panel.visible = true
	_settings_panel.modulate.a = 0.0
	create_tween().tween_property(_settings_panel, "modulate:a", 1.0, 0.15)
	_bgm_slider.grab_focus()


func _hide_settings() -> void:
	_play_click()
	_settings_panel.visible = false
	_start_button.grab_focus()


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
	if cfg.load(SETTINGS_PATH) == OK:
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
	cfg.save(SETTINGS_PATH)
	_hide_settings()


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
