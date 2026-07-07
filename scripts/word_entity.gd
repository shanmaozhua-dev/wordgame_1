extends RefCounted

var id: String
var text: String
var grid_pos := Vector2i.ZERO
var cells: Array[Vector2i] = []
var solid := true
var pushable := false
var deletable := false
var splittable := false
var interact_text := ""
var highlighted := false
var tags: Array[String] = []

func _init(entity_id := "", entity_text := "", pos := Vector2i.ZERO, occupied_cells: Array[Vector2i] = []) -> void:
	id = entity_id
	text = entity_text
	grid_pos = pos
	if occupied_cells.is_empty():
		cells = [pos]
	else:
		cells = occupied_cells.duplicate()

func set_from_config(config: Dictionary) -> void:
	solid = config.get("solid", solid)
	pushable = config.get("pushable", pushable)
	deletable = config.get("deletable", deletable)
	splittable = config.get("splittable", splittable)
	interact_text = config.get("interact_text", interact_text)
	tags.assign(config.get("tags", tags))

func move_by(delta: Vector2i) -> void:
	grid_pos += delta
	for i in range(cells.size()):
		cells[i] += delta

func move_to(pos: Vector2i) -> void:
	var delta := pos - grid_pos
	move_by(delta)
