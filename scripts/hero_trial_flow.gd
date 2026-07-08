extends RefCounted

const MapEditorIO = preload("res://scripts/map_editor_io.gd")

const SCENE_01_PATH := "res://levels/hero_trial_fist_scene_01.json"
const SCENE_02_PATH := "res://levels/hero_trial_fist_scene_02.json"
const LIFE_LINE_WITHOUT_GOOD_PATH := "res://levels/hero_trial_fist_state_life_line_without_good.json"
const ONE_GESTURE_PATH := "res://levels/hero_trial_fist_state_one_gesture.json"
const LIFE_LINE_GOOD_POS := Vector2i(14, 13)
const GESTURE_WORD_POS := Vector2i(26, 17)

var stage := ""

func load_start_scene(world: RefCounted) -> Dictionary:
	return _load_scene(world, SCENE_01_PATH, "scene_01")

func handle_space(world: RefCounted) -> Dictionary:
	if stage != "scene_01":
		return {"success": false, "message": ""}
	var result := _load_scene(world, SCENE_02_PATH, "scene_02")
	if result.success:
		_make_life_line_good_movable(world)
	return result

func sync_after_player_action(world: RefCounted) -> Dictionary:
	if _is_one_gesture_ready(world):
		return _switch_to_one_gesture(world)
	if stage != "scene_02":
		return {"success": false, "message": ""}
	var good = world.find_first_entity_by_text(_good_word())
	if good == null or good.grid_pos == LIFE_LINE_GOOD_POS:
		return {"success": false, "message": ""}
	var preserved := {
		"pos": good.grid_pos,
		"config": {
			"solid": good.solid,
			"pushable": true,
			"deletable": good.deletable,
			"splittable": good.splittable,
			"interact_text": good.interact_text,
			"tags": good.tags.duplicate()
		}
	}
	var player_pos = world.player_pos
	var facing = world.facing
	var result := _load_scene(world, LIFE_LINE_WITHOUT_GOOD_PATH, "life_line_without_good")
	if not result.success:
		return result
	world.player_pos = player_pos
	world.facing = facing
	world.add_entity(_good_word(), preserved.pos, preserved.config)
	world.update_page()
	return {"success": true, "message": "life line state changed"}

func _switch_to_one_gesture(world: RefCounted) -> Dictionary:
	var preserved: Array = []
	var zero_snapshot := _snapshot_first_entity(world, _zero_word())
	if not zero_snapshot.is_empty():
		preserved.append(zero_snapshot)
	var good_snapshot := _snapshot_first_entity(world, _good_word())
	if not good_snapshot.is_empty():
		preserved.append(good_snapshot)
	var player_pos = world.player_pos
	var facing = world.facing
	var result := _load_scene(world, ONE_GESTURE_PATH, "one_gesture")
	if not result.success:
		return result
	world.player_pos = player_pos
	world.facing = facing
	for snapshot in preserved:
		world.add_entity(str(snapshot.text), snapshot.pos, snapshot.config)
	world.update_page()
	return {"success": true, "message": "one gesture state changed"}

func _load_scene(world: RefCounted, path: String, next_stage: String) -> Dictionary:
	var loaded := MapEditorIO.load_editor_data(path)
	if not loaded.success:
		return loaded
	world.load_level(MapEditorIO.editor_data_to_level(loaded.data))
	stage = next_stage
	return {"success": true, "message": next_stage}

func _make_life_line_good_movable(world: RefCounted) -> void:
	var good = world.get_entity_at(LIFE_LINE_GOOD_POS)
	if good and good.text == _good_word():
		good.solid = true
		good.pushable = true

func _is_one_gesture_ready(world: RefCounted) -> bool:
	if stage == "one_gesture" or stage.is_empty():
		return false
	var entity = world.get_entity_at(GESTURE_WORD_POS)
	return entity != null and entity.text == _one_word()

func _snapshot_first_entity(world: RefCounted, text: String) -> Dictionary:
	var entity = world.find_first_entity_by_text(text)
	if entity == null:
		return {}
	return {
		"text": entity.text,
		"pos": entity.grid_pos,
		"config": {
			"solid": entity.solid,
			"pushable": entity.pushable,
			"deletable": entity.deletable,
			"splittable": entity.splittable,
			"interact_text": entity.interact_text,
			"tags": entity.tags.duplicate()
		}
	}

func _one_word() -> String:
	return char(0x4e00)

func _zero_word() -> String:
	return char(0x96f6)

func _good_word() -> String:
	return char(0x597d)
