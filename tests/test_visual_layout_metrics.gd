extends SceneTree

const MainScene = preload("res://scripts/main.gd")

var failures: Array[String] = []

func _init() -> void:
	var font_size := MainScene.font_size_for_cell(24)
	if font_size < 18 or font_size > 20:
		failures.append("font size should stay close to the original grid ratio, got %s" % font_size)
	var font: FontFile = load("res://Fonts/Zpix.tres")
	if font.fixed_size != 0:
		failures.append("Zpix font resource must not force a fixed size, got %s" % font.fixed_size)

	if failures.is_empty():
		print("visual_layout_metrics tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
