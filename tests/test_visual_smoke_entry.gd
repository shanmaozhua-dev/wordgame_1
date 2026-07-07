extends SceneTree

func _init() -> void:
	if not FileAccess.file_exists("res://tools/capture_visual_smoke.ps1"):
		printerr("visual smoke capture tool is missing")
		quit(1)
		return
	print("visual smoke capture tool found")
	quit(0)
