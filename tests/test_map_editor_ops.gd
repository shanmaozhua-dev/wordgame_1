extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const MapEditorOps = preload("res://scripts/map_editor_ops.gd")

var failures: Array[String] = []

func _init() -> void:
	test_cells_in_rect_is_inclusive_and_normalized()
	test_fill_cells_writes_same_word_to_whole_selection()
	test_clear_cells_removes_whole_selection()
	test_move_rect_preserves_shape_and_overwrites_destination()
	test_toggle_flag_applies_to_whole_selection()

	if failures.is_empty():
		print("map_editor_ops tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func make_world() -> RefCounted:
	var world := GridWorld.new()
	world.load_level({
		"player_start": Vector2i(0, 0),
		"screen_size": Vector2i(32, 18),
		"cell_size": 24
	})
	return world

func test_cells_in_rect_is_inclusive_and_normalized() -> void:
	var cells := MapEditorOps.cells_in_rect(Vector2i(3, 2), Vector2i(1, 1))
	assert_equal(cells.size(), 6, "rect includes both corners")
	assert_true(cells.has(Vector2i(1, 1)), "rect includes top-left")
	assert_true(cells.has(Vector2i(3, 2)), "rect includes bottom-right")

func test_fill_cells_writes_same_word_to_whole_selection() -> void:
	var world := make_world()
	world.add_entity("二", Vector2i(1, 1), {"solid": true, "pushable": true})
	MapEditorOps.fill_cells(world, MapEditorOps.cells_in_rect(Vector2i(1, 1), Vector2i(2, 2)), "掌")
	assert_equal(world.get_entity_at(Vector2i(1, 1)).text, "掌", "fill overwrites old word")
	assert_equal(world.get_entity_at(Vector2i(2, 1)).text, "掌", "fill writes top-right")
	assert_equal(world.get_entity_at(Vector2i(1, 2)).text, "掌", "fill writes bottom-left")
	assert_equal(world.get_entity_at(Vector2i(2, 2)).text, "掌", "fill writes bottom-right")
	assert_equal(world.get_entity_at(Vector2i(1, 1)).pushable, false, "filled words default to not pushable")

func test_clear_cells_removes_whole_selection() -> void:
	var world := make_world()
	MapEditorOps.fill_cells(world, MapEditorOps.cells_in_rect(Vector2i(4, 4), Vector2i(5, 5)), "掌")
	MapEditorOps.clear_cells(world, MapEditorOps.cells_in_rect(Vector2i(4, 4), Vector2i(5, 5)))
	assert_equal(world.get_entity_at(Vector2i(4, 4)), null, "clear removes top-left")
	assert_equal(world.get_entity_at(Vector2i(5, 5)), null, "clear removes bottom-right")

func test_move_rect_preserves_shape_and_overwrites_destination() -> void:
	var world := make_world()
	world.add_entity("甲", Vector2i(1, 1), {"solid": true, "pushable": true})
	world.add_entity("乙", Vector2i(2, 1), {"solid": true, "deletable": true})
	world.add_entity("丙", Vector2i(1, 2), {"solid": true})
	world.add_entity("旧", Vector2i(5, 5), {"solid": true})
	MapEditorOps.move_rect(world, Vector2i(1, 1), Vector2i(2, 2), Vector2i(5, 5))
	assert_equal(world.get_entity_at(Vector2i(1, 1)), null, "move clears source")
	assert_equal(world.get_entity_at(Vector2i(2, 1)), null, "move clears source row")
	assert_equal(world.get_entity_at(Vector2i(5, 5)).text, "甲", "move places top-left")
	assert_equal(world.get_entity_at(Vector2i(6, 5)).text, "乙", "move preserves x offset")
	assert_equal(world.get_entity_at(Vector2i(5, 6)).text, "丙", "move preserves y offset")
	assert_equal(world.get_entity_at(Vector2i(5, 5)).pushable, true, "move preserves pushable flag")
	assert_equal(world.get_entity_at(Vector2i(6, 5)).deletable, true, "move preserves deletable flag")

func test_toggle_flag_applies_to_whole_selection() -> void:
	var world := make_world()
	MapEditorOps.fill_cells(world, MapEditorOps.cells_in_rect(Vector2i(7, 7), Vector2i(8, 7)), "石")
	MapEditorOps.toggle_flag(world, MapEditorOps.cells_in_rect(Vector2i(7, 7), Vector2i(8, 7)), "pushable")
	assert_equal(world.get_entity_at(Vector2i(7, 7)).pushable, true, "toggle flag applies to first cell")
	assert_equal(world.get_entity_at(Vector2i(8, 7)).pushable, true, "toggle flag applies to second cell")

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
