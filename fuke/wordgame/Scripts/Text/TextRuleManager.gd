class_name TextRuleManager
extends Node

@export var grid_path: NodePath
@export var level_event_manager_path: NodePath
@export var status_label_path: NodePath

var grid: TextGrid
var level_event_manager: LevelEventManager
var status_label: Label

var split_rules: Dictionary = {
	"戏": ["又", "戈"],
}

var combine_rules: Dictionary = {
	"又+戈": "戏",
	"戈+又": "戏",
	"天+气很好": "天气很好",
	"天气+很好": "天气很好",
}

var sentence_rules: Dictionary = {
	"天气很好": "change_weather_good",
}

var _triggered_events: Dictionary = {}


func _ready() -> void:
	_resolve_paths()


func setup(grid_node: TextGrid, level_events: LevelEventManager, status: Label = null) -> void:
	grid = grid_node
	level_event_manager = level_events
	status_label = status
	if grid:
		grid.rule_manager = self


func get_split_result(text: String) -> Array:
	return split_rules.get(text, [])


func get_combine_result(left_text: String, right_text: String) -> String:
	return String(combine_rules.get("%s+%s" % [left_text, right_text], ""))


func check_rules() -> void:
	if grid == null:
		_resolve_paths()
	if grid == null:
		return

	for text_char: TextChar in grid.get_all_text_chars():
		if is_instance_valid(text_char):
			text_char.set_highlight(false)

	var matches: Array = _find_sentence_matches()
	for match_value in matches:
		var match_data: Dictionary = match_value
		var sentence: String = match_data["sentence"]
		var event_id: String = String(sentence_rules[sentence])
		for text_node_value in match_data["nodes"]:
			var text_node: TextChar = text_node_value as TextChar
			if is_instance_valid(text_node):
				text_node.set_highlight(true)
		if not _triggered_events.get(event_id, false):
			_triggered_events[event_id] = true
			trigger_event(event_id)


func trigger_event(event_id: String) -> void:
	if event_id == "change_weather_good":
		if status_label:
			status_label.text = "规则触发：天气很好。天气变好，门已打开。"
		if level_event_manager:
			if level_event_manager.has_method("change_weather"):
				level_event_manager.change_weather("good")
			if level_event_manager.has_method("open_door"):
				level_event_manager.open_door("artifact_door")
		return

	if status_label:
		status_label.text = "规则触发：%s" % event_id


func reset_triggers() -> void:
	_triggered_events.clear()


func _resolve_paths() -> void:
	if grid_path != NodePath() and has_node(grid_path):
		grid = get_node(grid_path) as TextGrid
	if level_event_manager_path != NodePath() and has_node(level_event_manager_path):
		level_event_manager = get_node(level_event_manager_path) as LevelEventManager
	if status_label_path != NodePath() and has_node(status_label_path):
		status_label = get_node(status_label_path)
	if grid:
		grid.rule_manager = self


func _find_sentence_matches() -> Array:
	var matches: Array = []
	for y in range(grid.bounds.position.y, grid.bounds.end.y):
		var line: String = ""
		var nodes_by_index: Array = []
		for x in range(grid.bounds.position.x, grid.bounds.end.x):
			var data: Dictionary = grid.get_cell_character(Vector2i(x, y))
			if data.is_empty():
				line += " "
				nodes_by_index.append(null)
			else:
				line += String(data["character"])
				nodes_by_index.append(data["node"])

		for sentence_value in sentence_rules.keys():
			var sentence: String = String(sentence_value)
			var index: int = line.find(sentence)
			if index == -1:
				continue
			var nodes: Array = []
			for offset in range(sentence.length()):
				var node: TextChar = nodes_by_index[index + offset] as TextChar
				if node != null and not nodes.has(node):
					nodes.append(node)
			matches.append({
				"sentence": sentence,
				"nodes": nodes,
			})
	return matches
