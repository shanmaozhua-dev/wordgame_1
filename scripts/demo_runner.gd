extends RefCounted

var steps: Array[Dictionary] = []
var index := 0
var running := false

func start() -> void:
	index = 0
	running = true
	steps = [
		{"type": "set_player", "pos": Vector2i(3, 1), "facing": Vector2i(1, 0), "caption": "走近手表，按空格查看说明"},
		{"type": "action", "action": "interact", "direction": Vector2i.ZERO},
		{"type": "set_player", "pos": Vector2i(4, 2), "facing": Vector2i(1, 0), "caption": "面向可删除文字，按退格"},
		{"type": "action", "action": "delete", "direction": Vector2i.ZERO},
		{"type": "set_player", "pos": Vector2i(6, 1), "facing": Vector2i(1, 0), "caption": "推动“石”"},
		{"type": "action", "action": "move", "direction": Vector2i(1, 0)},
		{"type": "set_player", "pos": Vector2i(9, 1), "facing": Vector2i(-1, 0), "caption": "按 Alt 拉动“石”"},
		{"type": "action", "action": "pull", "direction": Vector2i(1, 0)},
		{"type": "set_player", "pos": Vector2i(7, 2), "facing": Vector2i(1, 0), "caption": "按 Tab 拆“戏”"},
		{"type": "action", "action": "split", "direction": Vector2i.ZERO},
		{"type": "merge", "from": Vector2i(8, 2), "to": Vector2i(9, 2), "caption": "推动偏旁合成“戏”"},
		{"type": "sentence", "caption": "把“天”接到“气很好”前，识别“天气”"},
		{"type": "set_player", "pos": Vector2i(31, 1), "facing": Vector2i(1, 0), "caption": "走到屏幕页边缘，切到下一页"},
		{"type": "action", "action": "move", "direction": Vector2i(1, 0)}
	]

func step(world: RefCounted) -> Dictionary:
	if not running or index >= steps.size():
		running = false
		return {"success": false, "message": "演示结束"}
	var item := steps[index]
	index += 1
	match item.type:
		"set_player":
			world.player_pos = item.pos
			world.facing = item.facing
			world.update_page()
			return {"success": true, "message": item.caption}
		"action":
			var result: Dictionary = world.try_player_action(item.action, item.direction)
			if not result.get("message", ""):
				result.message = item.get("caption", "")
			return result
		"merge":
			var merged: Dictionary = world.try_merge_entities(item.from, item.to)
			merged.message = item.caption
			return merged
		"sentence":
			var sky = world.find_first_entity_by_text("天")
			var air = world.find_first_entity_by_text("气")
			if sky and air:
				world.move_entity_to(sky.id, air.grid_pos - Vector2i(1, 0))
			var result: Dictionary = world.check_sentence_rules()
			return {"success": result.has("天气"), "message": item.caption}
		_:
			return {"success": false, "message": "未知演示步骤"}
