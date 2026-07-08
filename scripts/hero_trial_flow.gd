extends RefCounted

const FlowEngine = preload("res://scripts/flow_engine.gd")
const FLOW_CONFIG_PATH := "res://levels/hero_trial_flow.json"

var engine := FlowEngine.new()
var stage := ""

func _init() -> void:
	var result := engine.load_config(FLOW_CONFIG_PATH)
	if result.success:
		stage = engine.stage

func load_start_scene(world: RefCounted) -> Dictionary:
	var result := _ensure_config_loaded()
	if not result.success:
		return result
	result = engine.load_start_map(world)
	stage = engine.stage
	return result

func handle_space(world: RefCounted) -> Dictionary:
	var result := _ensure_config_loaded()
	if not result.success:
		return result
	result = engine.handle_trigger(world, "space")
	stage = engine.stage
	return result

func sync_after_player_action(world: RefCounted) -> Dictionary:
	var result := _ensure_config_loaded()
	if not result.success:
		return result
	result = engine.sync_after_player_action(world)
	stage = engine.stage
	return result

func _ensure_config_loaded() -> Dictionary:
	if not engine.stage.is_empty():
		return {"success": true}
	var result := engine.load_config(FLOW_CONFIG_PATH)
	if result.success:
		stage = engine.stage
	return result
