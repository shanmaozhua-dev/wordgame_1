extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")

var failures: Array[String] = []

func _init() -> void:
	test_movement_collision_and_page_shift()
	test_interact_delete_push_pull()
	test_split_merge_and_sentence_rule()
	test_pull_direction_is_locked_to_player_side()
	test_push_into_merge_target_auto_merges()
	test_sentence_caption_is_map_collision_text()
	test_interaction_prompt_stays_as_map_collision_text()

	if failures.is_empty():
		print("gameplay_core tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func make_world() -> RefCounted:
	var world = GridWorld.new()
	world.load_level({
		"rows": [
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙",
			"墙我 手表  石 墙          天 气很好        墙",
			"墙    删  戏  又 戈                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙"
		],
		"player_start": Vector2i(1, 1),
		"screen_size": Vector2i(32, 18),
		"entities": {
			"手表": {"interact_text": "手表可以查看人类世界的时间", "solid": true},
			"石": {"pushable": true, "solid": true},
			"删": {"deletable": true, "solid": true},
			"戏": {"splittable": true, "pushable": true, "solid": true},
			"又": {"pushable": true, "solid": true},
			"戈": {"pushable": true, "solid": true},
			"天": {"pushable": true, "solid": true},
			"气": {"solid": true},
			"很": {"solid": true},
			"好": {"solid": true}
		},
		"split_rules": {"戏": ["又", "戈"]},
		"merge_rules": {"又+戈": "戏", "戈+又": "戏"},
		"sentence_rules": {"天气": {"message": "已识别"}}
	})
	return world

func test_movement_collision_and_page_shift() -> void:
	var world = make_world()
	assert_equal(world.player_pos, Vector2i(1, 1), "player starts at configured grid position")
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "player can move into empty grid cell")
	assert_equal(world.player_pos, Vector2i(2, 1), "player moved right")
	world.player_pos = Vector2i(1, 1)
	assert_false(world.try_move_player(Vector2i(-1, 0)).success, "player cannot move into wall")

	world.player_pos = Vector2i(31, 1)
	world.update_page()
	assert_equal(world.current_page_origin, Vector2i(0, 0), "page before crossing right edge")
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "player can cross page boundary")
	assert_equal(world.current_page_origin, Vector2i(32, 0), "page shifts by one screen after crossing right edge")
	assert_no_overlap(world)

func test_interact_delete_push_pull() -> void:
	var world = make_world()
	world.player_pos = Vector2i(3, 1)
	world.facing = Vector2i(1, 0)
	assert_equal(world.interact_front().message, "手表可以查看人类世界的时间", "space interaction reports watch text")

	world.player_pos = Vector2i(4, 2)
	world.facing = Vector2i(1, 0)
	assert_true(world.delete_front().success, "backspace deletes deletable word")
	assert_equal(world.get_entity_at(Vector2i(5, 2)), null, "deleted word frees its grid cell")

	world.player_pos = Vector2i(6, 1)
	assert_true(world.try_move_player(Vector2i(1, 0)).success, "pushing stone succeeds")
	assert_equal(world.get_entity_at(Vector2i(8, 1)).text, "石", "stone moves one grid right")
	assert_equal(world.player_pos, Vector2i(7, 1), "player also advances when pushing")

	world.player_pos = Vector2i(9, 1)
	world.facing = Vector2i(-1, 0)
	assert_true(world.pull_front(Vector2i(1, 0)).success, "alt pull moves target toward player movement")
	assert_equal(world.get_entity_at(Vector2i(9, 1)).text, "石", "stone is pulled into player's old cell")
	assert_equal(world.player_pos, Vector2i(10, 1), "player moves while pulling")
	assert_no_overlap(world)

func test_split_merge_and_sentence_rule() -> void:
	var world = make_world()
	world.player_pos = Vector2i(7, 2)
	world.facing = Vector2i(1, 0)
	assert_true(world.split_front().success, "tab splits configured word")
	assert_equal(world.get_entity_at(Vector2i(8, 2)).text, "又", "split leaves first part in source cell")
	assert_equal(world.get_entity_at(Vector2i(9, 2)).text, "戈", "split places second part in facing cell")

	var merged = world.try_merge_entities(Vector2i(8, 2), Vector2i(9, 2))
	assert_true(merged.success, "configured parts merge")
	assert_equal(world.get_entity_at(Vector2i(9, 2)).text, "戏", "merged word appears at destination")

	var sky = world.find_first_entity_by_text("天")
	var air = world.find_first_entity_by_text("气")
	var sentence_start: Vector2i = air.grid_pos - Vector2i(1, 0)
	world.move_entity_to(sky.id, sentence_start)
	var result = world.check_sentence_rules()
	assert_true(result.has("天气"), "sentence rule recognizes word")
	assert_equal(result["天气"].message, "已识别", "sentence rule emits configured caption")
	assert_true(world.highlighted_cells.has(sentence_start), "sentence start cell highlighted")
	assert_true(world.highlighted_cells.has(air.grid_pos), "sentence second cell highlighted")

func test_pull_direction_is_locked_to_player_side() -> void:
	var sideways_world = make_pull_fixture()
	assert_false(sideways_world.pull_front(Vector2i(1, 0)).success, "alt pull rejects sideways movement")
	var toward_world = make_pull_fixture()
	assert_false(toward_world.pull_front(Vector2i(0, 1)).success, "alt pull rejects movement toward the pulled word")
	var valid_world = make_pull_fixture()
	assert_true(valid_world.pull_front(Vector2i(0, -1)).success, "alt pull allows moving away from the pulled word")
	assert_equal(valid_world.get_entity_at(Vector2i(7, 3)).text, "石", "pulled word moves into player's old cell")
	assert_equal(valid_world.player_pos, Vector2i(7, 2), "player moves away while pulling")

func make_pull_fixture() -> RefCounted:
	var world = make_world()
	world.player_pos = Vector2i(7, 3)
	world.facing = Vector2i(0, 1)
	var stone = world.find_first_entity_by_text("石")
	world.move_entity_to(stone.id, Vector2i(7, 4))
	return world

func test_push_into_merge_target_auto_merges() -> void:
	var world = make_world()
	var part_left = world.find_first_entity_by_text("又")
	var part_right = world.find_first_entity_by_text("戈")
	world.move_entity_to(part_left.id, Vector2i(8, 4))
	world.move_entity_to(part_right.id, Vector2i(9, 4))
	world.player_pos = Vector2i(7, 4)
	var pushed = world.try_move_player(Vector2i(1, 0))
	assert_true(pushed.success, "pushing a mergeable part into another part succeeds")
	assert_equal(world.get_entity_at(Vector2i(9, 4)).text, "戏", "pushed parts automatically merge at target cell")
	assert_equal(world.player_pos, Vector2i(8, 4), "player moves into pushed word's old cell")
	assert_equal(world.get_entity_at(Vector2i(8, 4)), null, "source part cell is freed after merge")

func test_sentence_caption_is_map_collision_text() -> void:
	var world = make_world()
	var sky = world.find_first_entity_by_text("天")
	var air = world.find_first_entity_by_text("气")
	var sentence_start: Vector2i = air.grid_pos - Vector2i(1, 0)
	world.move_entity_to(sky.id, sentence_start)
	world.check_sentence_rules()
	var caption = world.find_first_entity_by_text("已识别")
	assert_true(caption != null, "recognized caption becomes a word entity")
	if caption:
		assert_true(caption.solid, "recognized caption has collision")
		world.player_pos = caption.grid_pos - Vector2i(1, 0)
		assert_false(world.try_move_player(Vector2i(1, 0)).success, "player cannot walk through recognized caption")

func test_interaction_prompt_stays_as_map_collision_text() -> void:
	var world = make_world()
	world.player_pos = Vector2i(3, 1)
	world.facing = Vector2i(1, 0)
	var result = world.interact_front()
	assert_true(result.success, "watch interaction succeeds")
	var prompt = world.find_first_entity_by_text("手表可以查看人类世界的时间")
	assert_true(prompt != null, "interaction prompt becomes a word entity")
	if prompt:
		var prompt_id = prompt.id
		assert_true(prompt.solid, "interaction prompt has collision")
		world.player_pos = prompt.grid_pos - Vector2i(1, 0)
		assert_false(world.try_move_player(Vector2i(1, 0)).success, "player cannot walk through interaction prompt")
		world.interact_front()
		assert_equal(world.find_first_entity_by_text("手表可以查看人类世界的时间").id, prompt_id, "same prompt is not respawned or replaced")

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func assert_false(actual: bool, label: String) -> void:
	if actual:
		failures.append("%s expected false but got true" % label)

func assert_no_overlap(world: RefCounted) -> void:
	for entity in world.entities.values():
		if entity.grid_pos == world.player_pos:
			failures.append("player overlaps word %s at %s" % [entity.text, entity.grid_pos])
