extends RefCounted

const START_POSITION := Vector2(320, 180)
const STEP_SIZE := 16

static func move(current_position: Vector2, direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return current_position

	return current_position + direction.normalized() * STEP_SIZE
