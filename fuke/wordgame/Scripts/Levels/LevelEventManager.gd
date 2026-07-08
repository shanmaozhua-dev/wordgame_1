class_name LevelEventManager
extends Node

@export var grid_path: NodePath
@export var status_label_path: NodePath
@export var door_cell: Vector2i = Vector2i(13, 3)
@export var artifact_cell: Vector2i = Vector2i(15, 3)

var grid: TextGrid
var status_label: Label
var weather_overlay: ColorRect
var door_node: Node2D
var artifact_node: Node2D

var weather_type: String = "normal"
var door_open: bool = false
var artifact_given: bool = false


func _ready() -> void:
	_resolve_paths()
	if grid:
		grid.level_event_manager = self
		grid.add_blocker(door_cell, "artifact_door")


func setup(grid_node: TextGrid, status: Label, door: Node2D, artifact: Node2D, weather: ColorRect) -> void:
	grid = grid_node
	status_label = status
	door_node = door
	artifact_node = artifact
	weather_overlay = weather
	if grid:
		grid.level_event_manager = self
		grid.add_blocker(door_cell, "artifact_door")


func open_door(id: String = "artifact_door") -> void:
	if door_open:
		return
	door_open = true
	if grid:
		grid.remove_blocker(door_cell, id)

	if door_node:
		var tween: Tween = door_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(door_node, "modulate:a", 0.2, 0.24)
		tween.tween_property(door_node, "scale:y", 0.15, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	if status_label:
		status_label.text = "门打开了。走到右侧的“器”上获得神器。"


func change_weather(type: String) -> void:
	weather_type = type
	if weather_overlay == null:
		return

	var target: Color = Color(0.45, 0.72, 1.0, 0.18) if type == "good" else Color(0.06, 0.06, 0.08, 0.0)
	weather_overlay.create_tween().tween_property(weather_overlay, "color", target, 0.35)


func give_artifact(id: String = "trial_artifact") -> void:
	if artifact_given:
		return
	artifact_given = true

	if artifact_node:
		var tween: Tween = artifact_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(artifact_node, "scale", Vector2(1.65, 1.65), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(artifact_node, "rotation_degrees", 360.0, 0.5).from(0.0)
		tween.tween_property(artifact_node, "modulate", Color("#ffe86b"), 0.18)

	if status_label:
		status_label.text = "获得神器：%s。测试闭环完成。" % id


func check_player_position(cell: Vector2i) -> void:
	if door_open and cell == artifact_cell:
		give_artifact()


func _resolve_paths() -> void:
	if grid_path != NodePath() and has_node(grid_path):
		grid = get_node(grid_path) as TextGrid
	if status_label_path != NodePath() and has_node(status_label_path):
		status_label = get_node(status_label_path)
