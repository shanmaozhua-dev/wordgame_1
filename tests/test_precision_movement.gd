extends SceneTree

const PrecisionMovement = preload("res://scripts/precision_movement.gd")

var failures: Array[String] = []

func _init() -> void:
	assert_equal(PrecisionMovement.START_POSITION, Vector2(320, 180), "start position")
	assert_equal(PrecisionMovement.move(PrecisionMovement.START_POSITION, Vector2.RIGHT), Vector2(336, 180), "move right")
	assert_equal(PrecisionMovement.move(Vector2(336, 180), Vector2.DOWN), Vector2(336, 196), "move down")
	assert_equal(PrecisionMovement.move(Vector2(336, 196), Vector2.ZERO), Vector2(336, 196), "zero direction")

	if failures.is_empty():
		print("precision_movement tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])
