extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HeroTrialFlow = preload("res://scripts/hero_trial_flow.gd")
const FlowEngine = preload("res://scripts/flow_engine.gd")

var failures: Array[String] = []

func _init() -> void:
	test_flow_config_loads_all_maps_and_rules()
	test_space_advances_from_scene_one_to_scene_two()
	test_push_good_out_of_life_line_switches_state_and_keeps_good()
	test_pull_good_out_of_life_line_switches_state_and_keeps_good()
	test_one_gesture_state_keeps_displaced_words()
	test_pushing_one_into_zero_slot_displaces_zero_and_switches_state()
	test_zero_returning_to_sentence_restores_zero_gesture()
	test_good_two_and_win_gesture_states_are_registered_and_triggered()
	test_deleting_not_opens_release_state()

	if failures.is_empty():
		print("hero_trial_flow tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_flow_config_loads_all_maps_and_rules() -> void:
	var engine := FlowEngine.new()
	assert_true(engine.load_config("res://levels/hero_trial_flow.json").success, "flow config loads")
	assert_equal(engine.stage, "scene_01", "flow config declares scene one start")
	for map_id in ["scene_01", "scene_02", "life_line_without_good", "one_gesture", "zero_gesture", "good_gesture", "two_gesture", "win_gesture", "release_opened"]:
		assert_true(engine.has_map(map_id), "flow config registers map %s" % map_id)
	assert_true(engine.rule_count() >= 8, "flow config registers current hero trial transitions")

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
	assert_life_line_middle_palm_open(world)
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
	assert_life_line_middle_palm_open(world)
	var moved_good := world.get_entity_at(Vector2i(14, 12))
	assert_true(moved_good != null, "pulled good is still on the map")
	if moved_good:
		assert_equal(moved_good.text, good_word, "pulled word remains good")
		assert_true(moved_good.pushable, "pulled good remains movable")

func test_one_gesture_state_keeps_displaced_words() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var one_word := char(0x4e00)
	var zero_word := char(0x96f6)
	var good_word := char(0x597d)
	flow.load_start_scene(world)
	flow.handle_space(world)

	var one = find_pushable_entity_by_text(world, one_word)
	var zero = world.find_first_entity_by_text(zero_word)
	var good = world.get_entity_at(Vector2i(14, 13))
	assert_true(one != null, "scene two has movable one")
	assert_true(zero != null, "scene two has movable zero")
	assert_true(good != null, "scene two has life-line good")
	if not one or not zero or not good:
		return
	world.move_entity_to(zero.id, Vector2i(28, 15))
	world.move_entity_to(good.id, Vector2i(28, 16))
	world.move_entity_to(one.id, Vector2i(26, 17))

	assert_true(flow.sync_after_player_action(world).success, "one gesture state switch succeeds")
	assert_equal(flow.stage, "one_gesture", "flow reaches one gesture state")
	assert_equal(world.get_entity_at(Vector2i(26, 17)).text, one_word, "one stays in the gesture sentence")
	assert_equal(world.get_entity_at(Vector2i(28, 15)).text, zero_word, "displaced zero stays at its actual position")
	assert_equal(world.get_entity_at(Vector2i(28, 16)).text, good_word, "displaced good stays at its actual position")
	assert_true(world.get_entity_at(Vector2i(28, 15)).pushable, "displaced zero remains movable")

func test_pushing_one_into_zero_slot_displaces_zero_and_switches_state() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var one_word := char(0x4e00)
	var zero_word := char(0x96f6)
	flow.load_start_scene(world)
	flow.handle_space(world)

	var one = find_pushable_entity_by_text(world, one_word)
	assert_true(one != null, "scene two has movable one")
	if not one:
		return
	world.move_entity_to(one.id, Vector2i(26, 16))
	world.player_pos = Vector2i(26, 15)
	world.facing = Vector2i(0, 1)

	assert_true(world.try_move_player(Vector2i(0, 1)).success, "pushing one into zero slot displaces zero")
	assert_equal(world.get_entity_at(Vector2i(26, 17)).text, one_word, "one enters gesture word slot")
	assert_equal(world.get_entity_at(Vector2i(26, 18)).text, zero_word, "zero is pushed to the next cell")
	assert_true(flow.sync_after_player_action(world).success, "flow switches after pushed one enters the sentence")
	assert_equal(flow.stage, "one_gesture", "flow reaches one gesture state after chained push")
	assert_equal(world.get_entity_at(Vector2i(26, 18)).text, zero_word, "displaced zero remains after state switch")

func test_zero_returning_to_sentence_restores_zero_gesture() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var one_word := char(0x4e00)
	var zero_word := char(0x96f6)
	var good_word := char(0x597d)
	flow.load_start_scene(world)
	flow.handle_space(world)

	var one = find_pushable_entity_by_text(world, one_word)
	var zero = world.find_first_entity_by_text(zero_word)
	var good = world.get_entity_at(Vector2i(14, 13))
	assert_true(one != null, "scene two has movable one for zero restore")
	assert_true(zero != null, "scene two has movable zero for zero restore")
	assert_true(good != null, "scene two has good for zero restore")
	if not one or not zero or not good:
		return
	world.move_entity_to(zero.id, Vector2i(28, 15))
	world.move_entity_to(good.id, Vector2i(28, 16))
	world.move_entity_to(one.id, Vector2i(26, 17))
	assert_true(flow.sync_after_player_action(world).success, "one gesture setup succeeds")

	var moved_one = find_pushable_entity_by_text(world, one_word)
	var moved_zero = find_pushable_entity_by_text(world, zero_word)
	assert_true(moved_one != null, "one exists before restoring zero gesture")
	assert_true(moved_zero != null, "zero exists before restoring zero gesture")
	if not moved_one or not moved_zero:
		return
	world.move_entity_to(moved_one.id, Vector2i(26, 18))
	world.move_entity_to(moved_zero.id, Vector2i(26, 17))

	assert_true(flow.sync_after_player_action(world).success, "zero gesture state switch succeeds")
	assert_equal(flow.stage, "zero_gesture", "flow returns to zero gesture state")
	assert_equal(world.get_entity_at(Vector2i(26, 17)).text, zero_word, "zero stays in the gesture sentence")
	assert_equal(world.get_entity_at(Vector2i(26, 18)).text, one_word, "displaced one stays at its actual position")
	assert_equal(world.get_entity_at(Vector2i(28, 16)).text, good_word, "moved good remains after zero gesture restore")

func test_good_two_and_win_gesture_states_are_registered_and_triggered() -> void:
	var cases := [
		{"text": char(0x597d), "stage": "good_gesture"},
		{"text": char(0x4e8c), "stage": "two_gesture"},
		{"text": char(0x8d0f), "stage": "win_gesture"}
	]
	for test_case in cases:
		var world := GridWorld.new()
		var flow := HeroTrialFlow.new()
		flow.load_start_scene(world)
		flow.handle_space(world)
		var trigger_text := str(test_case.text)
		var trigger_entity = find_pushable_entity_by_text(world, trigger_text)
		if trigger_entity == null:
			trigger_entity = world.add_entity(trigger_text, Vector2i(2, 15), {"solid": true, "pushable": true})
		var slot_entity = world.get_entity_at(Vector2i(26, 17))
		if slot_entity != null and slot_entity.id != trigger_entity.id:
			world.move_entity_to(slot_entity.id, Vector2i(28, 15))
		world.move_entity_to(trigger_entity.id, Vector2i(26, 17))
		assert_true(flow.sync_after_player_action(world).success, "%s gesture state switch succeeds" % trigger_text)
		assert_equal(flow.stage, str(test_case.stage), "%s reaches expected gesture state" % trigger_text)
		assert_equal(world.get_entity_at(Vector2i(26, 17)).text, trigger_text, "%s remains in gesture sentence" % trigger_text)

func test_deleting_not_opens_release_state() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	var not_word := char(0x4e0d)
	flow.load_start_scene(world)
	flow.handle_space(world)
	world.player_pos = Vector2i(5, 3)
	world.facing = Vector2i(1, 0)
	assert_true(world.delete_front().success, "deleting not word succeeds")
	assert_true(flow.sync_after_player_action(world).success, "release state switch succeeds")
	assert_equal(flow.stage, "release_opened", "flow reaches release opened state")
	assert_equal(world.get_entity_at(Vector2i(6, 3)), null, "not word remains absent after release state switch")

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func find_pushable_entity_by_text(world: RefCounted, text: String) -> RefCounted:
	for entity in world.entities.values():
		if entity.text == text and entity.pushable:
			return entity
	return null

func assert_life_line_middle_palm_open(world: RefCounted) -> void:
	for cell in [
		Vector2i(19, 10),
		Vector2i(20, 10),
		Vector2i(21, 10),
		Vector2i(20, 11),
		Vector2i(20, 12)
	]:
		assert_equal(world.get_entity_at(cell), null, "life-line middle palm cell %s is open" % cell)
