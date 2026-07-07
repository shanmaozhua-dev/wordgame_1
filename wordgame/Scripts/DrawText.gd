@tool
extends Sprite2D

const CELL_SIZE := 60.0
const FONT_SIZE := 54
const FONT_SCALE := 1.12

var font := preload("res://Fonts/Zpix.tres")

@export_multiline var text := "":
	set(value):
		text = value
		update_draw()

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		update_draw()

@export var has_background := true:
	set(value):
		has_background = value
		update_draw()

@export var render_type := "canvas_draw":
	set(value):
		render_type = value
		update_draw()

@export var is_tofu := false:
	set(value):
		is_tofu = value
		update_draw()

var text_wh := Vector2.ZERO
var tag := "default"
var is_dissolving := false
var is_crashing := false

signal text_drawn
signal dissolve_tween_completed
signal crash_tween_completed
signal draw_text_to_sprite_complete


func _ready() -> void:
	if not Engine.is_editor_hint() and texture == null and ResourceLoader.exists("res://Sprites/base_transparent.png"):
		texture = load("res://Sprites/base_transparent.png")
	queue_redraw()


func _on_WordSprite_tree_entered() -> void:
	update_draw()


func update_draw() -> void:
	queue_redraw()


func _draw() -> void:
	draw_text()


func draw_text() -> void:
	var glyph_size := FONT_SIZE * FONT_SCALE
	var lines := text.replace("\r\n", "\n").split("\n")
	text_wh = Vector2.ZERO
	text_wh.y = lines.size()

	for y in lines.size():
		var line := String(lines[y])
		text_wh.x = max(text_wh.x, line.length())
		for x in line.length():
			var character := line[x]
			if character == "":
				continue

			var origin := Vector2(CELL_SIZE * x, CELL_SIZE * y)
			if has_background:
				draw_rect(Rect2(origin - Vector2(glyph_size, glyph_size) / 2.0, Vector2(glyph_size, glyph_size)), Color.BLACK)

			draw_string(
				font,
				origin + Vector2(FONT_SIZE * (FONT_SCALE - 1.1) / 2.0 - FONT_SIZE * FONT_SCALE / 2.0, FONT_SIZE * (FONT_SCALE / 2.0 + 0.26) - FONT_SIZE * FONT_SCALE / 2.0),
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				FONT_SIZE,
				text_color
			)

	text_drawn.emit()


func draw_text_to_sprite() -> void:
	update_draw()
	draw_text_to_sprite_complete.emit()


func dissolve(_time := 1.0) -> void:
	is_dissolving = false
	dissolve_tween_completed.emit()


func crash(_time := 1.0) -> void:
	is_crashing = false
	crash_tween_completed.emit()


func is_in_tofu_white_list(_text: String) -> bool:
	return true
