extends RefCounted

const MapEditorIO = preload("res://scripts/map_editor_io.gd")

const SCENE_01_PATH := "res://levels/hero_trial_fist_scene_01.json"
const SCENE_02_PATH := "res://levels/hero_trial_fist_scene_02.json"
const LIFE_LINE_WITHOUT_GOOD_PATH := "res://levels/hero_trial_fist_state_life_line_without_good.json"
const LIFE_LINE_GOOD_POS := Vector2i(14, 13)

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

func _good_word() -> String:
	return char(0x597d)
