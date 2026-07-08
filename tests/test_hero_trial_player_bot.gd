extends SceneTree

const GridWorld = preload("res://scripts/grid_world.gd")
const HeroTrialFlow = preload("res://scripts/hero_trial_flow.gd")

const SLOT := Vector2i(26, 17)
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const MIN_CELL := Vector2i(-2, 0)
const MAX_CELL := Vector2i(34, 21)
const MAX_PLAN_EXPANSIONS := 250000

var failures: Array[String] = []

func _init() -> void:
	test_player_bot_only_changes_gesture_when_word_enters_slot()

	if failures.is_empty():
		print("hero_trial_player_bot tests passed")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func test_player_bot_only_changes_gesture_when_word_enters_slot() -> void:
	var world := GridWorld.new()
	var flow := HeroTrialFlow.new()
	assert_true(flow.load_start_scene(world).success, "bot loads scene one")
	assert_true(flow.handle_space(world).success, "bot presses space into scene two")
	assert_equal(flow.stage, "scene_02", "bot starts in scene two")

	assert_true(drive_word_to(world, flow, char(0x597d), Vector2i(14, 14), "pull good out of life line to open passage"), "bot opens life-line passage with good")
	assert_equal(flow.stage, "life_line_without_good", "pulling good from life line opens passage state")

	assert_true(drive_word_to(world, flow, char(0x96f6), Vector2i(30, 18), "park zero away from gesture slot"), "bot removes zero from slot")
	assert_equal(world.get_entity_at(SLOT), null, "empty gesture slot does not immediately refill")
	assert_equal(flow.stage, "life_line_without_good", "removing zero does not change the current hand state")

	assert_true(drive_word_to(world, flow, char(0x96f6), SLOT, "push zero back into gesture slot"), "bot puts zero into slot")
	assert_slot_and_stage(world, flow, char(0x96f6), "zero_gesture", "zero entering slot changes hand state")

	assert_true(drive_word_to(world, flow, char(0x96f6), Vector2i(30, 18), "park zero after zero gesture"), "bot removes zero from zero gesture")
	assert_equal(world.get_entity_at(SLOT), null, "slot stays empty after zero is removed")
	assert_equal(flow.stage, "zero_gesture", "removing zero does not change zero hand state")

	assert_true(drive_word_to(world, flow, char(0x4e00), SLOT, "push one into gesture slot"), "bot puts one into slot")
	assert_slot_and_stage(world, flow, char(0x4e00), "one_gesture", "one entering slot changes hand state")

	assert_true(drive_word_to(world, flow, char(0x4e00), Vector2i(26, 18), "pull one out of gesture slot"), "bot removes one from slot")
	assert_equal(world.get_entity_at(SLOT), null, "slot stays empty after one is removed")
	assert_equal(flow.stage, "one_gesture", "removing one does not change hand state")

	assert_true(drive_word_to(world, flow, char(0x597d), SLOT, "push good into gesture slot"), "bot puts good into slot")
	assert_slot_and_stage(world, flow, char(0x597d), "good_gesture", "good entering slot changes hand state")

	assert_true(drive_word_to(world, flow, char(0x597d), Vector2i(26, 16), "pull good out of gesture slot"), "bot removes good from slot")
	assert_equal(world.get_entity_at(SLOT), null, "slot stays empty after good is removed")
	assert_equal(flow.stage, "good_gesture", "removing good does not change hand state")

func drive_word_to(world: RefCounted, flow: RefCounted, text: String, target: Vector2i, label: String) -> bool:
	var action_count := 0
	while action_count < 420:
		var entity = find_pushable_entity_by_text(world, text)
		if entity == null:
			failures.append("%s could not find pushable word %s" % [label, text])
			return false
		if entity.grid_pos == target:
			return true
		var plan := plan_next_actions(world, entity, target)
		if plan.is_empty():
			failures.append("%s no player-action route from %s to %s for %s at action %d; player=%s facing=%s stage=%s" % [label, entity.grid_pos, target, text, action_count, world.player_pos, world.facing, flow.stage])
			return false
		var stage_before: String = flow.stage
		for action in plan:
			var result := {}
			match str(action.get("type", "")):
				"move", "push":
					result = world.try_move_player(action.direction)
				"pull":
					result = world.pull_front(action.direction)
				_:
					failures.append("%s planner produced unknown action %s" % [label, action])
					return false
			if not bool(result.get("success", false)):
				failures.append("%s action failed at action %d: %s -> %s" % [label, action_count, action, result])
				return false
			action_count += 1
			flow.sync_after_player_action(world)
			entity = find_pushable_entity_by_text(world, text)
			if entity == null:
				failures.append("%s lost pushable word %s after action %d" % [label, text, action_count])
				return false
			if entity.grid_pos == target:
				return true
			if flow.stage != stage_before:
				break
	failures.append("%s exceeded bot step budget" % label)
	return false

func plan_next_actions(world: RefCounted, selected: RefCounted, target: Vector2i) -> Array:
	var blockers := solid_blockers_except(world, selected.id)
	var start := {"player": world.player_pos, "word": selected.grid_pos}
	var queue: Array = [start]
	var seen := {push_state_key(start.player, start.word): true}
	var parents := {}
	var start_key := push_state_key(start.player, start.word)
	var expansions := 0

	while not queue.is_empty():
		expansions += 1
		if expansions > MAX_PLAN_EXPANSIONS:
			return []
		var state: Dictionary = queue.pop_front()
		if state.word == target:
			return build_action_path(parents, start_key, push_state_key(state.player, state.word))
		var directions := DIRS.duplicate()
		directions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return manhattan(state.word + a, target) < manhattan(state.word + b, target)
		)
		for direction in directions:
			var next_word: Vector2i = state.word + direction
			var push_stand: Vector2i = state.word - direction
			if not is_free_for_word(next_word, blockers):
				continue
			if not is_free_for_player(push_stand, state.word, blockers):
				pass
			else:
				var player_path := plan_player_path(state.player, push_stand, state.word, blockers)
				if not player_path.is_empty() or state.player == push_stand:
					var actions := player_path.duplicate()
					actions.append({"type": "push", "direction": direction})
					var next_state := {"player": state.word, "word": next_word}
					_enqueue_push_state(queue, seen, parents, state, next_state, actions)
			var pull_edge := plan_pull_edge(state, direction, blockers)
			if pull_edge.success:
				_enqueue_push_state(queue, seen, parents, state, pull_edge.next_state, pull_edge.actions)
	return []

func _enqueue_push_state(queue: Array, seen: Dictionary, parents: Dictionary, state: Dictionary, next_state: Dictionary, actions: Array) -> void:
	var key := push_state_key(next_state.player, next_state.word)
	if seen.has(key):
		return
	seen[key] = true
	parents[key] = {"prev": push_state_key(state.player, state.word), "actions": actions}
	queue.append(next_state)

func plan_pull_edge(state: Dictionary, direction: Vector2i, blockers: Dictionary) -> Dictionary:
	var next_word: Vector2i = state.word + direction
	var pre_stand: Vector2i = state.word + direction * 2
	if not is_free_for_word(next_word, blockers):
		return {"success": false}
	if not is_free_for_player(next_word, state.word, blockers):
		return {"success": false}
	if not is_free_for_player(pre_stand, state.word, blockers):
		return {"success": false}
	var player_path := plan_player_path(state.player, pre_stand, state.word, blockers)
	if player_path.is_empty() and state.player != pre_stand:
		return {"success": false}
	var actions := player_path.duplicate()
	actions.append({"type": "move", "direction": -direction})
	actions.append({"type": "pull", "direction": direction})
	return {
		"success": true,
		"next_state": {"player": pre_stand, "word": next_word},
		"actions": actions
	}

func plan_player_path(start: Vector2i, target: Vector2i, selected_word: Vector2i, blockers: Dictionary) -> Array:
	if start == target:
		return []
	var queue: Array = [start]
	var seen := {cell_key(start): true}
	var parents := {}
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction in DIRS:
			var next: Vector2i = cell + direction
			if not is_free_for_player(next, selected_word, blockers):
				continue
			var key := cell_key(next)
			if seen.has(key):
				continue
			seen[key] = true
			parents[key] = {"prev": cell_key(cell), "action": {"type": "move", "direction": direction}}
			if next == target:
				return build_path(parents, cell_key(start), key)
			queue.append(next)
	return []

func build_path(parents: Dictionary, start_key: String, found_key: String) -> Array:
	var actions: Array = []
	var cursor := found_key
	while cursor != start_key:
		var entry: Dictionary = parents[cursor]
		actions.push_front(entry.action)
		cursor = str(entry.prev)
	return actions

func build_action_path(parents: Dictionary, start_key: String, found_key: String) -> Array:
	var actions: Array = []
	var cursor := found_key
	while cursor != start_key:
		var entry: Dictionary = parents[cursor]
		var segment: Array = entry.actions
		for i in range(segment.size() - 1, -1, -1):
			actions.push_front(segment[i])
		cursor = str(entry.prev)
	return actions

func solid_blockers_except(world: RefCounted, selected_id: String) -> Dictionary:
	var blockers := {}
	for entity in world.entities.values():
		if entity.id == selected_id or not entity.solid:
			continue
		for cell in entity.cells:
			blockers[cell] = true
	return blockers

func is_free_for_player(cell: Vector2i, selected_word: Vector2i, blockers: Dictionary) -> bool:
	return in_bounds(cell) and cell != selected_word and not blockers.has(cell)

func is_free_for_word(cell: Vector2i, blockers: Dictionary) -> bool:
	return in_bounds(cell) and not blockers.has(cell)

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= MIN_CELL.x and cell.x <= MAX_CELL.x and cell.y >= MIN_CELL.y and cell.y <= MAX_CELL.y

func push_state_key(player: Vector2i, word: Vector2i) -> String:
	return "%d,%d|%d,%d" % [player.x, player.y, word.x, word.y]

func cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func assert_slot_and_stage(world: RefCounted, flow: RefCounted, text: String, stage: String, label: String) -> void:
	var entity = world.get_entity_at(SLOT)
	assert_true(entity != null, "%s has a word in slot" % label)
	if entity:
		assert_equal(entity.text, text, "%s slot text" % label)
	assert_equal(flow.stage, stage, "%s stage" % label)

func find_pushable_entity_by_text(world: RefCounted, text: String) -> RefCounted:
	for entity in world.entities.values():
		if entity.text == text and entity.pushable:
			return entity
	return null

func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s but got %s" % [label, expected, actual])

func assert_true(actual: bool, label: String) -> void:
	if not actual:
		failures.append("%s expected true but got false" % label)
