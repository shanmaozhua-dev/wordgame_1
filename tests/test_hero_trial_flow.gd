extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HeroTrialFlow = preload("res://scripts/hero_trial_flow.gd")

var failures: Array[String] = []

func _init() -> void:
	test_space_advances_from_scene_one_to_scene_two()
	test_push_good_out_of_life_line_switches_state_and_keeps_good()
	test_pull_good_out_of_life_line_switches_state_and_keeps_good()

	if failures.is_empty():
		print("hero_trial_flow tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_space_advances_from_scene_one_to_scene_two() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var good_word := char(0x597d)
	assert_true(flow.load_start_scene(world).success, "scene one loads")
	assert_equal(flow.stage, "scene_01", "flow starts at scene one")
	assert_true(world.find_first_entity_by_text(good_word) == null, "scene one has no movable good word")

	assert_true(flow.handle_space(world).success, "space advances to scene two")
	assert_equal(flow.stage, "scene_02", "flow reaches scene two")
	var good := world.get_entity_at(Vector2i(14, 13))
	assert_true(good != null, "scene two has good in life-line sentence")
	if good:
		assert_equal(good.text, good_word, "life-line word is good")
		assert_true(good.pushable, "life-line good can be moved")

func test_push_good_out_of_life_line_switches_state_and_keeps_good() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var good_word := char(0x597d)
	flow.load_start_scene(world)
	flow.handle_space(world)
	world.player_pos = Vector2i(14, 12)
	world.facing = Vector2i(0, 1)

	assert_true(world.try_move_player(Vector2i(0, 1)).success, "push good down out of life-line sentence")
	assert_true(flow.sync_after_player_action(world).success, "flow switches after pushed good leaves sentence")
	assert_equal(flow.stage, "life_line_without_good", "flow reaches life-line state")
	assert_equal(world.player_pos, Vector2i(14, 13), "player position survives state switch")
	assert_equal(world.get_entity_at(Vector2i(14, 13)), null, "old good cell stays empty")
	var moved_good := world.get_entity_at(Vector2i(14, 14))
	assert_true(moved_good != null, "moved good is still on the map")
	if moved_good:
		assert_equal(moved_good.text, good_word, "moved word remains good")
		assert_true(moved_good.pushable, "moved good remains movable")

func test_pull_good_out_of_life_line_switches_state_and_keeps_good() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var good_word := char(0x597d)
	flow.load_start_scene(world)
	flow.handle_space(world)
	world.player_pos = Vector2i(14, 12)
	world.facing = Vector2i(0, 1)

	assert_true(world.pull_front(Vector2i(0, -1)).success, "pull good up out of life-line sentence")
	assert_true(flow.sync_after_player_action(world).success, "flow switches after pulled good leaves sentence")
	assert_equal(flow.stage, "life_line_without_good", "flow reaches life-line state after pull")
	assert_equal(world.player_pos, Vector2i(14, 11), "player position survives pull state switch")
	var moved_good := world.get_entity_at(Vector2i(14, 12))
	assert_true(moved_good != null, "pulled good is still on the map")
	if moved_good:
		assert_equal(moved_good.text, good_word, "pulled word remains good")
		assert_true(moved_good.pushable, "pulled good remains movable")

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
