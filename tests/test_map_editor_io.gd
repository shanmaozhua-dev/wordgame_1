extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")
const MapEditorIO = preload("res://scripts/map_editor_io.gd")

var failures: Array[String] = []

func _init() -> void:
	test_world_round_trips_through_editor_json()
	test_saved_editor_json_overrides_default_level()
	test_missing_editor_json_falls_back_to_default_level()

	if failures.is_empty():
		print("map_editor_io tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_world_round_trips_through_editor_json() -> void:
	var world := GridWorld.new()
	world.load_level(LevelLoader.build_hero_trial_fist_level())
	var data := MapEditorIO.world_to_editor_data(world)
	assert_equal(data.get("screen_size", []), [32, 18], "screen size is exported")
	assert_cell(data, "贏", 1, 2, true, true, false, "win word export")
	assert_cell(data, "掌", 15, 2, true, false, false, "top palm export preserves leading blank rows")

	var path := "user://map_editor_io_test.json"
	assert_true(MapEditorIO.save_editor_data(path, data).success, "save editor json")
	var loaded := MapEditorIO.load_editor_data(path)
	assert_true(loaded.success, "load editor json")
	var level := MapEditorIO.editor_data_to_level(loaded.data)
	var reloaded_world := GridWorld.new()
	reloaded_world.load_level(level)
	assert_equal(reloaded_world.screen_size, Vector2i(32, 18), "screen size reloads")
	assert_equal(reloaded_world.cell_size, 24, "cell size reloads")
	assert_equal(reloaded_world.player_pos, Vector2i(21, 16), "player start reloads")
	assert_equal(reloaded_world.get_entity_at(Vector2i(1, 2)).text, "贏", "win word reloads")
	assert_equal(reloaded_world.get_entity_at(Vector2i(15, 2)).text, "掌", "top palm reloads")

func test_saved_editor_json_overrides_default_level() -> void:
	var default_level := LevelLoader.build_hero_trial_fist_level()
	var world := GridWorld.new()
	world.load_level(default_level)
	var data := MapEditorIO.world_to_editor_data(world)
	for cell in data["cells"]:
		if cell.get("x") == 1 and cell.get("y") == 5:
			cell["text"] = "三"
			cell["tags"] = ["manual_edit"]
	var path := "user://map_editor_startup_override.json"
	assert_true(MapEditorIO.save_editor_data(path, data).success, "save startup override json")

	var loaded_level := MapEditorIO.load_level_or_default(path, default_level)
	var loaded_world := GridWorld.new()
	loaded_world.load_level(loaded_level)
	assert_equal(loaded_world.get_entity_at(Vector2i(1, 5)).text, "三", "saved editor json overrides default level")

func test_missing_editor_json_falls_back_to_default_level() -> void:
	var default_level := LevelLoader.build_hero_trial_fist_level()
	var loaded_level := MapEditorIO.load_level_or_default("user://missing_editor_level.json", default_level)
	var loaded_world := GridWorld.new()
	loaded_world.load_level(loaded_level)
	assert_equal(loaded_world.get_entity_at(Vector2i(1, 5)).text, "二", "missing editor json uses default level")

func assert_cell(data: Dictionary, text: String, x: int, y: int, solid: bool, pushable: bool, deletable: bool, label: String) -> void:
	for cell in data.get("cells", []):
		if cell.get("x") == x and cell.get("y") == y and cell.get("text") == text:
			assert_equal(cell.get("solid"), solid, "%s solid" % label)
			assert_equal(cell.get("pushable"), pushable, "%s pushable" % label)
			assert_equal(cell.get("deletable"), deletable, "%s deletable" % label)
			return
	failures.append("%s missing cell %s at (%s, %s)" % [label, text, x, y])

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
