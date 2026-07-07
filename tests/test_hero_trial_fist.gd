extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const LevelLoader = preload("res://scripts/level_loader.gd")

var failures: Array[String] = []

func _init() -> void:
	test_screen_metrics_match_original_grid()
	test_initial_hero_trial_layout()
	test_gesture_sentence_updates_state_and_keeps_collision_caption()
	test_release_sentence_completes_trial_after_deleting_not()

	if failures.is_empty():
		print("hero_trial_fist tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func make_world() -> RefCounted:
	var world = GridWorld.new()
	world.load_level(LevelLoader.build_hero_trial_fist_level())
	return world

func test_screen_metrics_match_original_grid() -> void:
	var world = make_world()
	assert_equal(world.screen_size, Vector2i(32, 18), "one screen uses the original 32 by 18 text grid")
	assert_equal(world.cell_size, 24, "render cell size keeps the 32 by 18 screen visible in the test window")
	assert_no_occupied_cell_overlap(world)
	assert_entities_inside_first_screen(world)

func test_initial_hero_trial_layout() -> void:
	var world = make_world()
	assert_equal(world.player_pos, Vector2i(21, 16), "player starts near the lower hand passage")
	assert_entity(world, "贏", Vector2i(1, 2), true, true, "win word is pushable at the source position")
	assert_entity(world, "不", Vector2i(6, 3), true, true, "not word is pushable and deletable")
	assert_true(world.find_first_entity_by_text("不").deletable, "not word can be deleted")
	assert_entity(world, "二", Vector2i(1, 5), true, true, "two word is pushable")
	assert_entity(world, "讚", Vector2i(10, 5), true, true, "praise word is pushable")
	assert_entity_at(world, "劍", Vector2i(16, 7), true, false, "sword is part of the map collision")
	assert_entity(world, "好", Vector2i(14, 13), true, true, "good word starts beside the life-line sentence")
	assert_true(world.get_entity_at(Vector2i(7, 2)) != null, "upper narration text has collision")
	assert_true(world.get_entity_at(Vector2i(25, 17)) != null, "lower hand-gesture sentence has collision")

func test_gesture_sentence_updates_state_and_keeps_collision_caption() -> void:
	var world = make_world()
	var good = world.find_first_entity_by_text("好")
	var zero = world.find_first_entity_by_text("零")
	world.move_entity_to(zero.id, Vector2i(30, 16))
	world.move_entity_to(good.id, Vector2i(26, 17))
	var result = world.check_sentence_rules()
	assert_true(result.has("巨大手掌，是好的手勢"), "good hand-gesture sentence is recognized")
	assert_equal(world.switches.get("ch3_好的手勢成立", false), true, "good gesture switch is set")
	assert_equal(world.state.get("current_gesture", ""), "好", "current gesture state records the recognized gesture")
	var caption = world.find_first_entity_by_text("已識別：好的手勢")
	assert_true(caption != null, "gesture recognition creates persistent map text")
	if caption:
		assert_true(caption.solid, "gesture caption has collision")
	var thumb = world.find_first_entity_by_text("好手勢")
	assert_true(thumb != null, "hand layout adds a visible state marker for the good gesture")
	if thumb:
		assert_true(thumb.solid, "hand state marker has collision")

func test_release_sentence_completes_trial_after_deleting_not() -> void:
	var world = make_world()
	world.player_pos = Vector2i(5, 3)
	world.facing = Vector2i(1, 0)
	assert_true(world.delete_front().success, "delete removes the not word from release sentence")
	var result = world.check_sentence_rules()
	assert_true(result.has("會輕易放開"), "release sentence is recognized after deleting not")
	assert_equal(world.switches.get("ch3_會輕易放開成立", false), true, "release switch is set")
	assert_equal(world.switches.get("hero_trial_complete", false), true, "trial completion flag is set")
	var tail = world.find_first_entity_by_text("尾聲：巨掌鬆開，勇者試煉完成")
	assert_true(tail != null, "tail message is spawned into the map")
	if tail:
		world.player_pos = tail.grid_pos - Vector2i(1, 0)
		assert_false(world.try_move_player(Vector2i(1, 0)).success, "tail message blocks movement as map text")

func assert_entity(world: RefCounted, text: String, pos: Vector2i, solid: bool, pushable: bool, label: String) -> void:
	var entity = world.find_first_entity_by_text(text)
	assert_true(entity != null, label)
	if entity:
		assert_equal(entity.grid_pos, pos, "%s position" % label)
		assert_equal(entity.solid, solid, "%s solid flag" % label)
		assert_equal(entity.pushable, pushable, "%s pushable flag" % label)

func assert_entity_at(world: RefCounted, text: String, pos: Vector2i, solid: bool, pushable: bool, label: String) -> void:
	var entity = world.get_entity_at(pos)
	assert_true(entity != null, label)
	if entity:
		assert_equal(entity.text, text, "%s text" % label)
		assert_equal(entity.solid, solid, "%s solid flag" % label)
		assert_equal(entity.pushable, pushable, "%s pushable flag" % label)

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)

func assert_false(actual: bool, label: String) -> void:
	if actual:
		failures.append("%s expected false but got true" % label)

func assert_no_occupied_cell_overlap(world: RefCounted) -> void:
	var occupied := {}
	for entity in world.entities.values():
		for cell in entity.cells:
			if occupied.has(cell):
				failures.append("cell %s is occupied by both %s and %s" % [cell, occupied[cell], entity.text])
			else:
				occupied[cell] = entity.text

func assert_entities_inside_first_screen(world: RefCounted) -> void:
	for entity in world.entities.values():
		for cell in entity.cells:
			if cell.x < 0 or cell.x >= world.screen_size.x or cell.y < 0 or cell.y >= world.screen_size.y:
				failures.append("word %s at %s is outside the first 32 by 18 screen" % [entity.text, cell])
