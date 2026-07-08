@tool

extends "Event.gd"

@export var big_text = "": set = on_big_text_set

var sub_events = {}

func on_big_text_set(value):
	big_text = value
	if has_node("WordSprite"):
		get_node("WordSprite").text = value
	pass


func on_text_set(new_value):
	text = new_value


func add_self_pos_in_map():
	
	if tileMap:
		for p in sub_events:
			tileMap.add_event_in_table(now_pos + p, str(self.get_path()))


func update_self_pos_in_map(prev_pos):
	
	if tileMap:
		for p in sub_events:
			tileMap.remove_event_in_table(prev_pos + p, str(self.get_path()))
		for p in sub_events:
			tileMap.add_event_in_table(now_pos + p, str(self.get_path()))


func remove_self_pos_in_map():
	if tileMap:
		for p in sub_events:
			tileMap.remove_event_in_table(now_pos + p, str(self.get_path()))


func _ready():
	if Engine.is_editor_hint():
		return
	
	setup_tree_animation()
	setup_collision_shape()
	setup_sub_events()
	



func is_at_pos(pos):

	return sub_events.has(pos - now_pos)

var need_tree_animation = false
func setup_tree_animation():
	var cp = str($"/root/Node".scene_file_path)[19]
	if not (cp in ["一", "二", "三"]) and not is_in_group("tree_animation"):
		return
	
	var lines = Util.split_string_with_multiple_delimiters(big_text, ["\r\n", "\n"])

	for i in lines.size():
		for j in len(lines[i]):
			if lines[i][j] != "樹":
				continue
			
			need_tree_animation = true
			var treeSprite = load("res://Scenes/Animations/TreeSprite.tscn").instantiate()
			treeSprite.position = Vector2(j * 60, i * 60)
			
			delay_add_tree(treeSprite)

func delay_add_tree(tree):
	await get_tree().create_timer(randf() * 1.5).timeout
	if need_tree_animation:
		add_child(tree)
	
func clear_tree_animation():
	need_tree_animation = false
	for node in get_children():
		if node.is_in_group("tree_animation_sprite"):
			node.queue_free()
	pass


func setup_collision_shape():
	for cs in $Area2D.get_children():
		cs.queue_free()
	
	
	var lines = Util.split_string_with_multiple_delimiters(big_text, ["\r\n", "\n"])

	for i in lines.size():
		for j in len(lines[i]):
			if lines[i][j] == "＿":
				continue
			var cs = CollisionShape2D.new()
			$Area2D.add_child(cs)
			cs.shape = RectangleShape2D.new()
			cs.shape.extents = Vector2(30, 30)
			cs.scale = Vector2(0.99, 0.99)
			cs.position = Vector2(30 + 60 * j, 30 + 60 * i)


func setup_sub_events():
	
	var lines = Util.split_string_with_multiple_delimiters(big_text, ["\r\n", "\n"])
	
	sub_events = {}
	for i in lines.size():
		for j in len(lines[i]):
			if lines[i][j] == "＿":
				continue
			sub_events[Vector2(j, i)] = lines[i][j]



func can_pass(x, y, d):
	var x2 = x_with_direction(x, d)
	var y2 = y_with_direction(y, d)
	
	var result = true
	
	for p in sub_events:
		result = result and can_pass_here(x2 + p.x, y2 + p.y, d)
	
	return result




func start_event(action = "default", event_pos = null):
	
	if tileMap.is_interpreter_running_this_event(self): return false
	
	var start_commands
	match action:
		"default":
			start_commands = JSON.new().stringify(raw_code_to_json_command(commands))
		"backspace":
			
			start_commands = JSON.new().stringify(raw_code_to_json_command(commands, "backspace"))
		"split":
			
			start_commands = JSON.new().stringify(raw_code_to_json_command(commands, "split"))
	
	if not start_commands or not existing:
		return false
	
	
	
	
	

	var test_json_conv = JSON.new()
	var json_error = test_json_conv.parse(start_commands)
	if json_error == OK and test_json_conv.get_data():
		list = test_json_conv.get_data()
		
		if typeof(list) == TYPE_DICTIONARY:
			
			var sub_word
			if event_pos:
				sub_word = sub_events[event_pos - now_pos]
				
			for key in list:
				if sub_word in key:
					list = list[key]
					


	else:
		print("error:" + name)
		print(json_error)
		print(test_json_conv.get_data())
		return false

	if list:
		starting = true
		

		print(name, ": ready start")
		tileMap.setup_starting_event()
		print(name, " start success: ", not starting)

		if starting:
			lock()
			return true
	
	return false



func raw_code_to_json_command(raw_code, action = "default"):
	


	
	var json_code = []
	var is_in_move_route = false
	
	var index = 0
	while index < len(raw_code):
		var now_index = index
		
		if raw_code[now_index] == "@":
			now_index += 1
			if raw_code[now_index] == "[":
				while true:
					now_index += 1
					if raw_code[now_index] == "]":
						break
				var header = raw_code.substr(index + 2, now_index - index - 2)
				var command = {"command": header}
				
				index = now_index
				while true:
					now_index += 1
					if now_index >= len(raw_code) or raw_code[now_index] == "@":
						now_index += 1
						if now_index >= len(raw_code) or raw_code[now_index] == "[":
							var raw_para = raw_code.substr(index + 2, now_index - index - 3).strip_edges()
							raw_para = remove_comment(raw_para)
							
							var para
							
							if raw_para:
								if is_str(raw_para):
									para = str_to_var(raw_para)
								else:
									if typeof(str_to_var(raw_para)) == TYPE_STRING:
										print("syntax error: ", raw_para)
									else:
										para = str_to_var(raw_para)
							
							if para != null:
								command.parameters = para
							break
						else:
							now_index -= 1
							

				
				if is_in_move_route:
					if header == "end_move_route":
						pass
					else:
						if not json_code[ - 1].has("parameters"):
							json_code[ - 1].parameters = {}
						if json_code[ - 1].parameters.has("route"):
							json_code[ - 1].parameters.route.append(command)
						else:
							json_code[ - 1].parameters.route = [command]
				else:
					json_code.append(command)
				
				if header == "move_route":
					is_in_move_route = true
				if header == "end_move_route":
					is_in_move_route = false
				
				index = now_index - 2
				continue
		index += 1
	
	
	var big_event_json_code = {}
	for i in range(json_code.size()):
		if json_code[i].command == "sub_event":
			var sub_event_text = json_code[i].parameters
			var sub_event_commands = []
			var now_i = i + 1
			while json_code[now_i].command != "end_sub_event":
				sub_event_commands.append(json_code[now_i])
				now_i += 1
			big_event_json_code[sub_event_text] = sub_event_commands
	if big_event_json_code:
		json_code = big_event_json_code
		match action:
			"default":
				return json_code
			_:
				return []
		
	
	
	var special_command_prefixs = ["backspace_command", "push_command", "split_command"]
	var end_special_command_prefixs = ["end_backspace_command", "end_push_command", "end_split_command"]
	match action:
		"default":
			var end_of_default_command = json_code.size()
			for i in range(json_code.size()):
				if special_command_prefixs.has(json_code[i].command):
					end_of_default_command = i - 1
					break
			if end_of_default_command == - 1:
				json_code = []
			else:
				json_code = json_code.slice(0, end_of_default_command)
		"backspace":
			var start_of_special_command
			var end_of_special_command
			for i in range(json_code.size()):
				if json_code[i].command == "backspace_command":
					start_of_special_command = i + 1
				if json_code[i].command == "end_backspace_command":
					end_of_special_command = i - 1
			if start_of_special_command != null and end_of_special_command != null and end_of_special_command > start_of_special_command:
				json_code = json_code.slice(start_of_special_command, end_of_special_command)
			else:
				json_code = []
		"split":
			var start_of_special_command
			var end_of_special_command
			for i in range(json_code.size()):
				if json_code[i].command == "split_command":
					start_of_special_command = i + 1
				if json_code[i].command == "end_split_command":
					end_of_special_command = i - 1
			if start_of_special_command != null and end_of_special_command != null and end_of_special_command > start_of_special_command:
				json_code = json_code.slice(start_of_special_command, end_of_special_command)
			else:
				json_code = []
	
	return json_code
	

func json_command_to_raw_code(json):
	if not json:
		return ""


	
	var raw_code = ""
	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	var dic = test_json_conv.get_data()
	
	
	if typeof(dic) == TYPE_ARRAY:
		return super.json_command_to_raw_code(json)
		
	if typeof(dic) != TYPE_DICTIONARY:
		return json
	
	var now_nest_index = 0
	
	for event_text in dic:
		var event_dic = dic[event_text]
		raw_code += "@[sub_event] \"" + event_text + "\"\n"
		for command in event_dic:
			var line = ""
			var header = ""
			var para = ""
			
			if ["end_if"].has(command.get("command")):
				now_nest_index -= 1
			
			header = "@[" + command.get("command") + "]"
			
			if command.get("command") == "move_route":
				if command.has("parameters"):
					var route = JSON.new().stringify(command.get("parameters").get("route"))
					var route_code = json_command_to_raw_code(route)
					command.get("parameters").erase("route")
					para = JSON.new().stringify(command.get("parameters"))
					if para.is_empty():
						para = ""
					line = header + " " + para
					
					var tab = "\t"
					for i in range(now_nest_index):
						tab += "\t"
					route_code = tab + route_code.replace("\n", "\n" + tab)
	
					route_code.erase(route_code.length() - 2, 2)
	
					line += "\n" + route_code
					
					tab = ""
					for i in range(now_nest_index):
						tab += "\t"
					line += "\n" + tab + "@[end_move_route]"
			else:
				if command.has("parameters"):
					para = JSON.new().stringify(command.get("parameters"))
				line = header + " " + para
			
			for i in range(now_nest_index):
				raw_code += "\t"
			raw_code += line + "\n"
			
			if ["if", "else"].has(command.get("command")):
				now_nest_index += 1
		raw_code += "@[end_sub_event]\n"
	
	return raw_code


func change_text_animation(new_text, x_delay = 0.1, y_delay = 0.3, x_reverse = false, y_reverse = false, new_color = null):
	super.change_text_animation(new_text, x_delay, y_delay, x_reverse, y_reverse, new_color)
	await $WordSprite.change_all_text_animation_complete
	change_big_text(new_text)
	if new_color:
		self.text_color = new_color
	
	
func vanish_text_animation(x_delay = 0.1, y_delay = 0.3, x_reverse = false, y_reverse = false):
	clear_tree_animation()
	$WordSprite.vanish_text_animation(x_delay, y_delay, x_reverse, y_reverse)
	await $WordSprite.change_all_text_animation_complete
	big_text = ""



func been_pull_lock(target, facing):
	var pos = target.now_pos + direction_to_vector(10 - facing)
	var offset = (pos - now_pos) * 60
	pull_lock_animation(target, facing, offset)


func get_pull_distence(target, facing):
	var pos = target.now_pos - direction_to_vector(target.direction) + direction_to_vector(10 - facing)
	
	return pos - target.now_pos


func change_big_text(new_value):
	self.big_text = new_value
	clear_tree_animation()
	setup_tree_animation()
	remove_self_pos_in_map()
	setup_sub_events()
	setup_collision_shape()
	add_self_pos_in_map()


func is_in_screen():
	var c = tileMap.player.get_node("Camera3D")
	var ww = 32 * 60
	var wh = 18 * 60
	
	var screen_bound = Rect2(0, 0, ww, wh)
	screen_bound.position.x = c.position.x - ww / 2
	screen_bound.position.y = c.position.y - wh / 2
	
	var result = false
	for p in sub_events:
		result = result or screen_bound.has_point(tileMap.map_to_local(p + now_pos))
	
	return result
