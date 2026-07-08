@tool
extends Control

const CELL_SIZE := float(GameConfigRules.CELL_SIZE.x)
const FONT_SIZE := 54
const FONT_SCALE := 1.12

var font := preload("res://Fonts/Zpix.tres")

@export_multiline var text := "":
	set(value):
		text = value
		queue_redraw()

@export var text_color: Color = Color.WHITE:
	set(value):
		text_color = value
		queue_redraw()

@export var has_background := true:
	set(value):
		has_background = value
		queue_redraw()

signal text_drawn


func _draw() -> void:
	_draw_grid_text()
	text_drawn.emit()


func _draw_grid_text() -> void:
	var cell_size := Vector2(CELL_SIZE, CELL_SIZE)
	var lines := text.replace("\r\n", "\n").split("\n")

	for y in lines.size():
		var line := String(lines[y])
		for x in line.length():
			var character := line[x]
			var cell_origin := Vector2(CELL_SIZE * x, CELL_SIZE * y)
			var glyph_origin := cell_origin + cell_size / 2.0
			if has_background:
				draw_rect(Rect2(cell_origin, cell_size), Color.BLACK)

			if _is_blank_placeholder(character):
				continue

			draw_string(
				font,
				glyph_origin + Vector2(FONT_SIZE * (FONT_SCALE - 1.1) / 2.0 - FONT_SIZE * FONT_SCALE / 2.0, FONT_SIZE * (FONT_SCALE / 2.0 + 0.26) - FONT_SIZE * FONT_SCALE / 2.0),
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				FONT_SIZE,
				text_color
			)


func _is_blank_placeholder(character: String) -> bool:
	return character in ["", "＿", "_", "　", " "]
