class_name GameConfigRules
extends Node

const CELL_SIZE := Vector2i(60, 60)
const CELL_SIZE_FLOAT := Vector2(60.0, 60.0)

const VIEWPORT_SIZE := Vector2i(1920, 1200)
const GAME_AREA_SIZE := Vector2i(1920, 1080)
const GRID_SIZE := Vector2i(32, 20)
const GAME_AREA_GRID_SIZE := Vector2i(32, 18)

const DEFAULT_MOVE_SPEED := 1.0
const DEFAULT_STEP_PER_PHYSICS_FRAME := 0.125


static func get_cell_size() -> Vector2i:
	return CELL_SIZE


static func get_cell_size_float() -> Vector2:
	return CELL_SIZE_FLOAT


static func cell_to_screen(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE_FLOAT


static func screen_to_cell(screen_position: Vector2) -> Vector2i:
	return Vector2i(floori(screen_position.x / CELL_SIZE.x), floori(screen_position.y / CELL_SIZE.y))


static func direction_to_cell_vector(direction: int) -> Vector2i:
	match direction:
		2:
			return Vector2i.DOWN
		4:
			return Vector2i.LEFT
		6:
			return Vector2i.RIGHT
		8:
			return Vector2i.UP
		_:
			return Vector2i.ZERO


static func cells_to_pixels(cells: Vector2) -> Vector2:
	return cells * CELL_SIZE_FLOAT


static func pixels_to_cells(pixels: Vector2) -> Vector2:
	return pixels / CELL_SIZE_FLOAT
