@tool

extends "BaseCharacter.gd"



@export var text = "": set = on_text_set
@export var text_color: Color = Color.WHITE: set = on_text_color_set

enum EVENT_TRIGGER_ACTION_TYPES{AUTO, PRESS, TOUCH, LOOP}
@export var event_trigger_action: EVENT_TRIGGER_ACTION_TYPES = EVENT_TRIGGER_ACTION_TYPES.PRESS

@export var loop_sprite_animation: Dictionary = {
	"path": "", 
	"frame_count": 0, 
	"time": 0.0, 
	"keyframes": ""
}


@export var exist_condition = "" # (String, MULTILINE)
@export var exist_fade_in: bool = false

enum LAYER_TYPES{BACK, MID, FRONT}
@export var layer: LAYER_TYPES = LAYER_TYPES.MID: set = on_layer_set

@export var center_rotation = "": set = on_center_rotation_set



@export var copy_from_event = ""

@export var is_high_priority = false

@export var need_be_saved = true

@export var bgs: String
@export var bgs_loop: bool
@export var bgs_max_dist = 800 # (int, 0, 2000)

@export_multiline var commands: String = ""

@export_multiline var loop_move_route: String = ""








var interpreter
var move_route_interpreter

var list = []
var starting = false



var org_pos
var existing = true
var was_exist_condition_valid = true


func _on_command_changed(new_text):
	commands = new_text

func _on_movement_changed(new_text):
	loop_move_route = new_text
	
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

	
	var special_command_prefixs = ["backspace_command", "push_command", "split_command"]
	var end_special_command_prefixs = ["end_backspace_command", "end_push_command", "end_split_command"]
	match action:
		"default":
			var end_of_default_command = json_code.size()
			for i in range(json_code.size()):
				if special_command_prefixs.has(json_code[i].command):
					end_of_default_command = i - 1
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
	

func is_str(s):
	return s[0] == "\"" and s[ - 1] == "\""
	
func remove_comment(raw):
	var new_raw = ""
	var index = 0
	var is_in_comment = false
	while index < len(raw):
		if is_in_comment:
			if raw[index] == "\n":
				is_in_comment = false
				new_raw += raw[index]
		else:
			if raw[index] == "#" and index + 1 < len(raw) and raw[index + 1] == "#":
				is_in_comment = true
				index += 1
			else:
				new_raw += raw[index]
		index += 1
	new_raw = new_raw.strip_edges()
	return new_raw
	
	
	
func json_command_to_raw_code(json):
	if not json:
		return ""


	
	var raw_code = ""
	var test_json_conv = JSON.new()
	test_json_conv.parse(json)
	var dic = test_json_conv.get_data()
	
	if typeof(dic) != TYPE_ARRAY:
		return json
	
	var now_nest_index = 0
	
	for command in dic:
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
	
	return raw_code





































func add_self_pos_in_map():
	if tileMap:

		if tileMap.is_event_in_fixed_map(self):
			tileMap.fixed_map.add_event_in_table(now_pos, str(self.get_path()))
		else:
			tileMap.add_event_in_table(now_pos, str(self.get_path()))

func update_self_pos_in_map(prev_pos):
	if tileMap:
		if tileMap.is_event_in_fixed_map(self):
			tileMap.fixed_map.update_event_in_table(prev_pos, now_pos, str(self.get_path()))
		else:
			tileMap.update_event_in_table(prev_pos, now_pos, str(self.get_path()))

func remove_self_pos_in_map():
	if tileMap:
		if tileMap.is_event_in_fixed_map(self):
			tileMap.fixed_map.remove_event_in_table(now_pos, str(self.get_path()))
		else:
			tileMap.remove_event_in_table(now_pos, str(self.get_path()))



var is_now_pos_first_init = true
func on_now_pos_set(value):
	var prev_pos = now_pos
	now_pos = value
	
	update_self_pos_in_map(prev_pos)
		



	


















func _exit_tree():
	remove_self_pos_in_map()


func _ready():
	if Engine.is_editor_hint():
		return
		
		
func init():
	if Engine.is_editor_hint():
		return
	
	adjust_by_group()
	
	org_pos = now_pos
	
	
	if existing:
		refresh()
	else:
		exist(false)
	

func adjust_by_group():
	if "hide_word_sprite" in get_groups():
		$WordSprite.visible = false

func exist(to_exist):
	if to_exist:
		existing = true
		visible = true
		if has_node("Area2D/CollisionShape2D"):
			$Area2D/CollisionShape2D.disabled = false
		if exist_fade_in:

			fade_from_to(0, 1, 1)
		if bgs:
			Sound.play_se_with_position(bgs, self, bgs_loop, bgs_max_dist)
			

		add_self_pos_in_map()
	else:
		existing = false
		visible = false
		if has_node("Area2D/CollisionShape2D"):
			$Area2D/CollisionShape2D.disabled = true
		if move_route:
			move_route = []
		if interpreter:
			interpreter.terminate()
			

		remove_self_pos_in_map()

func refresh_if_need():
	if was_exist_condition_valid != is_exist_condition_valid():
		refresh()
		
func refresh():
	if is_exist_condition_valid():
		exist(true)
		transport_to(org_pos)
		



		
		if text == "樹" and not is_in_group("generated_in_runtime"):
			var cp = str($"/root/Node".scene_file_path)[19]
			if cp in ["一", "二", "三"]:
				var delay = randf()
				loop_sprite_animation = {
					"path": "res://Sprites/tree/tree.png", 
					"frame_count": 20, 
					"time": 3.0, 
					"keyframes": "[    {\"t\": 0.0, \"f\": 0},    {\"t\": 0.66, \"f\": 19}]", 
					"delay": delay
				}
		
		if loop_sprite_animation.path:
			if loop_sprite_animation.keyframes:
				loop_sprite_animation.keyframes = loop_sprite_animation.keyframes.replace("\r\n", "").replace("\n", "")
				var test_json_conv = JSON.new()
				var json_error = test_json_conv.parse(loop_sprite_animation.keyframes)
				var k = test_json_conv.get_data()
				if json_error == OK and k:
					set_loop_sprite_animation(loop_sprite_animation.path, loop_sprite_animation.frame_count, loop_sprite_animation.time, k, loop_sprite_animation.get("delay", null))
			else:
				set_loop_sprite_animation(loop_sprite_animation.path, loop_sprite_animation.frame_count, loop_sprite_animation.time, null, loop_sprite_animation.get("delay", null))
		




		
		if copy_from_event.length() > 0:
			var e = tileMap.get_event_by_name(copy_from_event)
			if e != null:
				commands = e.commands
				
		
		if commands and event_trigger_action == EVENT_TRIGGER_ACTION_TYPES.LOOP:
			if not interpreter:
				create_interpreter()
			interpreter.setup(raw_code_to_json_command(commands), self)
		
		
		if not move_route:
			if loop_move_route:
				var route_list = raw_code_to_json_command(loop_move_route)

				
				if route_list and route_list.size() > 0:
					set_move_route(route_list)
		
		if commands and event_trigger_action == EVENT_TRIGGER_ACTION_TYPES.AUTO:
			print("auto")
			start_event()
	else:
		exist(false)

	
	was_exist_condition_valid = is_exist_condition_valid()



func set_event_name(value):

	if name == value:
		return
		

	remove_self_pos_in_map()
	name = value


func create_interpreter():
	interpreter = Node2D.new()
	interpreter.name = "Interpreter"
	interpreter.set_script(load("res://Scripts/Interpreter.gd"))
	add_child(interpreter)
	interpreter.execute_type = "loop"

var is_layer_first_init = true
func on_layer_set(new_value):
	if layer == new_value: return
	
	var old_value = layer
	layer = new_value
		
	is_layer_first_init = false
	
	if old_value == LAYER_TYPES.BACK and z_index != 0: return
	if old_value == LAYER_TYPES.MID and z_index != 10: return
	if old_value == LAYER_TYPES.FRONT and z_index != 20: return
	
	match layer:
		LAYER_TYPES.BACK:
			z_index = 0
		LAYER_TYPES.MID:
			z_index = 10
		LAYER_TYPES.FRONT:
			z_index = 20
	
	

func on_center_rotation_set(new_value):
	center_rotation = int(new_value)
	$WordSprite.rotation_degrees = center_rotation

func on_text_set(new_value):
	text = new_value
	$WordSprite.text = new_value

func on_text_color_set(new_value):
	text_color = new_value
	$WordSprite.text_color = new_value

	
func start_event(action = "default", event_pos = null):
	
	if tileMap.is_interpreter_running_this_event(self): return false
	
	if copy_from_event.length() > 0:
		var e = tileMap.get_event_by_name(copy_from_event)
		if e != null:
			commands = e.commands
			
	
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

		set_physics_process(true)

		if not starting:
			if locked and not is_in_group("was_lock_before_start_event"):
				add_to_group("was_lock_before_start_event")
			
			lock()
			return true
	
	return false
	
		
func is_starting():
	return starting

func clear_starting_flag():
	starting = false









func check_event_trigger_touch(x, y):
	if event_trigger_action == EVENT_TRIGGER_ACTION_TYPES.TOUCH:
		var p = tileMap.player
		if p.is_at_pos(Vector2(x, y)):
			start_event()
	super.check_event_trigger_touch(x, y)




func update_stop():
	if existing:
		super.update_stop()
		if not is_move_route_forcing:
			update_self_movement()
		
		if is_starting():
			print(name, " try to start")
			start_event()
		
		
		if not is_move_route_forcing and not loop_move_route and not is_starting() and not is_shaking:
			set_physics_process(false)

func update_self_movement():
	if loop_move_route and not locked and is_in_screen():
		update_routine_move()
		
func is_in_screen():
	var c = tileMap.player.get_node("Camera3D")
	var ww = 32 * 60
	var wh = 18 * 60
	
	var screen_bound = Rect2(0, 0, ww, wh)
	screen_bound.position.x = c.get_camera_position().x - ww / 2
	screen_bound.position.y = c.get_camera_position().y - wh / 2
	
	return screen_bound.has_point(tileMap.map_to_local(now_pos))
	
func is_exist_condition_valid():
	if not exist_condition:
		return true
		
	
	return Util.is_str_condition_vaild(exist_condition, name)
	
	var conditions
	var test_json_conv = JSON.new()
	var json_error = test_json_conv.parse(exist_condition)
	if json_error == OK and test_json_conv.get_data():
		conditions = test_json_conv.get_data()
	if not conditions:
		
		return Util.is_str_condition_vaild(exist_condition, name)
	
	var is_vaild = true
	for condition in conditions:
		condition = Util.str_to_condition(condition)
		if condition[0].type == "switch":
			condition[0].value = Global.get_game_switch(condition[0].value)
		if condition[0].type == "self_switch":
			condition[0].value = Global.get_game_self_switch(name, condition[0].value)
		if condition[0].type == "variable":
			condition[0].value = Global.get_game_variable(condition[0].value)
			
		if condition[2].type == "switch":
			condition[2].value = Global.get_game_switch(condition[2].value)
		if condition[2].type == "self_switch":
			condition[2].value = Global.get_game_self_switch(name, condition[2].value)
		if condition[2].type == "variable":
			condition[2].value = Global.get_game_variable(condition[2].value)
		is_vaild = is_vaild and Util.compare(condition[0].value, condition[1], condition[2].value)

	
	return is_vaild

func been_backspace():
	if has_node("Backspace"):
		return
	
	if Global.game_map.has_method("event_just_been_backspace"):
		Global.game_map.event_just_been_backspace(self)
	
	lock()
	can_push = false
	var org_z_index = z_index
	z_index = 50
	
	var bs = load("res://Scenes/Animations/Backspace.tscn").instantiate()
	add_child(bs)
	
	await bs.get_node("AnimationPlayer").animation_finished

	exist(false)
	z_index = org_z_index
	tileMap.check_rule()

func been_dissolve(option = {}):
	if $WordSprite.is_dissolving:
		return
	
	lock()
	can_push = false

	await $WordSprite.dissolve(option)
	
	await $WordSprite.dissolve_tween_completed

	exist(false)
	
	$WordSprite.clear_dissolve_tween()
	
	tileMap.check_rule()

func been_crash():
	if $WordSprite.is_crashing:
		return
	
	lock()
	can_push = false

	await $WordSprite.crash()
	
	await $WordSprite.crash_tween_completed

	exist(false)

	$WordSprite.clear_crash_tween()

	tileMap.check_rule()


func save_status():
	var status = {
		"name": name, 
		"parent": str(get_parent().get_path()), 
		"pos_x": now_pos.x, 
		"pos_y": now_pos.y, 
		"groups": get_groups(), 
		"layer": layer, 
		"z_index": z_index, 
		"center_rotation": center_rotation, 
		"text": text, 
		"is_high_priority": is_high_priority, 
		"loop_move_route": loop_move_route, 
		"starting": starting, 
		"locked": locked, 
		"can_move": can_move_enabled, 
		"org_pos": org_pos, 
		"existing": existing, 
		"was_exist_condition_valid": was_exist_condition_valid, 
		"move_speed": move_speed, 
		"direction": direction, 
		"through": through, 
		"can_push": can_push, 
		"can_delete": can_delete, 
		"can_split": can_split, 
		"move_route": move_route, 
		"move_route_index": move_route_index, 
		"wait_count": wait_count, 
		"is_move_route_forcing": is_move_route_forcing, 
		"original_move_route": original_move_route, 
		"original_move_route_index": original_move_route_index, 
		"has_sprite_animation": has_sprite_animation, 
		"jump_peak": jump_peak, 
		"jump_count": jump_count, 
		"opacity": opacity, 
		"text_color": text_color, 
		"modulate": modulate, 
		"can_pass_group": can_pass_group
	}
	
	if is_in_group("generated_in_runtime"):
		status.commands = commands
		status.exist_condition = exist_condition
	
	return status


func load_status(status):

	transport_to(Vector2(status["pos_x"], status["pos_y"]))
	
	for group_name in status.groups:
		add_to_group(group_name)
	
	for i in status.keys():
		if i == "name":
			set_event_name(status[i])
		if i == "can_move":
			set_can_move(status[i])
			continue
		
		if i == "groups" or i == "parent" or i == "pos_x" or i == "pos_y" or i == "name":
			continue
		self.set(i, status[i])
		
		







func been_snake_crash():
	var rand_adjust = randf()
	
	var time = 0.0
	
	while time < 1.0:
		var curve = pow(time * 15 - 5, 2) / 3.0 - 25.0 / 3.0
		var diff_point = Vector2(time * 15, curve) * 10
	
		var rand = sin(rand_adjust) * 43758.5453123
		rand -= floor(rand)
		rand = rand * 2.0 - 1.0
		
		var adjust = Vector2(1, 1) * (0.5 + rand / 2)
		
		var end_rotation = rand * 360
		var now_rotation = Vector2(0, 0).lerp(Vector2(end_rotation, 0), time).x
		
		get_node("WordSprite").position = diff_point * adjust + Vector2(30, 30)
		get_node("WordSprite").rotation_degrees = now_rotation
		
		var opacity = ease(1 - time, 0.2)
		get_node("WordSprite").modulate = Color(1, 1, 1, opacity)
		await get_tree().process_frame
		time += 1.0 / 30.0
	
	exist(false)



func change_text_animation(new_text, x_delay = 0.3, y_delay = 0.1, x_reverse = false, y_reverse = false, new_color = null):
	$WordSprite.change_text_animation(new_text, x_delay, y_delay, x_reverse, y_reverse, new_color)

	






func vanish_text_animation(x_delay = 0.3, y_delay = 0.1, x_reverse = false, y_reverse = false):
	$WordSprite.vanish_text_animation(x_delay, y_delay, x_reverse, y_reverse)
	await $WordSprite.change_all_text_animation_complete
	text = ""


func been_pull_lock(target, facing):
	pull_lock_animation(target, facing)
	pass

func been_pull_unlock(target, facing):
	pull_unlock_animation(target, facing)
	pass
	
func pull_lock_animation(target, facing, offset = Vector2(0, 0)):
	var pull_ani
	if has_node("Pull"):
		pull_ani = get_node("Pull")
	else:
		pull_ani = load("res://Scenes/Animations/Pull.tscn").instantiate()
		add_child(pull_ani)
	
	pull_ani.position += offset
	
	var pull_line
	if target.has_node("PullLine"):
		pull_line = target.get_node("PullLine")
	else:
		pull_line = load("res://Scenes/Animations/PullLine.tscn").instantiate()
		target.add_child(pull_line)
	
	var pos_adjust = {
		8: [0, 30, 60], 
		6: [90, 0, 30], 
		4: [90, 60, 30], 
		2: [0, 30, 0]
	}
	pull_line.rotation_degrees = pos_adjust[facing][0]
	pull_line.position.x = pos_adjust[facing][1]
	pull_line.position.y = pos_adjust[facing][2]
	
	Sound.play_se("res://Sounds/se/pull_grab.wav")
	pull_ani.get_node("AnimationPlayer").play("lock_" + str(facing))
	await pull_ani.get_node("AnimationPlayer").animation_finished
	pull_ani.get_node("AnimationPlayer").play("locking_" + str(facing))
	
func pull_unlock_animation(target, facing):
	if target.has_node("PullLine"):
		target.get_node("PullLine").queue_free()
	
	Sound.play_se("res://Sounds/se/pull_ungrab.wav", - 10)
	var pull_ani = get_node("Pull")
	if pull_ani:
		pull_ani.get_node("AnimationPlayer").play("unlock_" + str(facing))
		await pull_ani.get_node("AnimationPlayer").animation_finished
		pull_ani.queue_free()

func get_pull_distence(target, facing):
	return now_pos - target.now_pos


func lock_rotate(d, is_clockwise):
	var type = ["B", "A"][int(is_clockwise)]
	if not has_node("lock_rotate"):
		add_child(load("res://Scenes/Animations/lock_rotate.tscn").instantiate())
	get_node("lock_rotate").play(str(d) + type)

func after_lock_rotate(type):
	var offset = {
		"2A": Vector2( - 1, - 1), 
		"2B": Vector2(1, - 1), 
		"4A": Vector2(1, - 1), 
		"4B": Vector2(1, 1), 
		"6A": Vector2( - 1, 1), 
		"6B": Vector2( - 1, - 1), 
		"8A": Vector2(1, 1), 
		"8B": Vector2( - 1, 1)
	}
	transport_to(now_pos + offset[type])
	get_node("WordSprite").position = Vector2(30, 30)
	tileMap.check_rule()



func update_real_position_to_map():

	var x = round(global_position.x / 60.0)
	var y = round(global_position.y / 60.0)
	self.now_pos = Vector2(x, y)
	
	moving_pos = now_pos


func can_be_split():
	var pos = now_pos
	var dir = get_direction_been_squeezed_when_overlap(pos)
	if dir == 0:
		return false
	print("can_be_split")
	return true

var force_split_dir = null
func been_split(desire_dir = 2, split_events = []):
	var pos = now_pos
	var dir = 0
	if force_split_dir:
		dir = get_force_direction_been_squeezed_when_overlap(pos, force_split_dir)
	if dir == 0:
		dir = get_direction_been_squeezed_when_overlap(pos, desire_dir)
	if dir == 0:
		print("stuck!")
		return
	
	var stay_event = split_events[0]
	var move_event = split_events[1]
	
	stay_event.add_to_group("new_splited_event")
	move_event.add_to_group("new_splited_event")
	
	self.transport_to(Vector2( - 10, - 10))
	stay_event.transport_to(pos)
	move_event.transport_to(pos)
	
	stay_event.play_stay_split_ani()
	move_event.play_move_split_ani(dir)
	
	Sound.play_se("res://Sounds/se/unzip_1.wav")
	
	await get_tree().create_timer(0.5).timeout
	tileMap.check_rule()
	pass

func play_stay_split_ani():
	var split = load("res://Scenes/Animations/split_animation.tscn").instantiate()
	var split_particle = load("res://Scenes/Animations/split_particle.tscn").instantiate()
	get_node("WordSprite").add_child(split)
	add_child(split_particle)
	
	var ani = get_node("WordSprite/split/AnimationPlayer")
	var ani2 = get_node("WordSprite/split/AnimationPlayer2")
	var org_z_index = z_index
	z_index = 21
	ani.play("5")
	ani2.play("5")
	await ani.animation_finished
	z_index = org_z_index
	await ani2.animation_finished
	split.queue_free()
	split_particle.queue_free()
	
func play_move_split_ani(d):
	var split = load("res://Scenes/Animations/split_animation.tscn").instantiate()
	get_node("WordSprite").add_child(split)
	
	var ani = get_node("WordSprite/split/AnimationPlayer")
	var ani2 = get_node("WordSprite/split/AnimationPlayer2")
	ani.play(str(d))
	ani2.play(str(d))
	var org_can_push = can_push
	can_push = false
	await ani.animation_finished
	can_push = org_can_push
	self.transport_add(Util.direction_to_vector(d))
	get_node("WordSprite").position = Vector2(30, 30)
	
	await ani2.animation_finished
	split.queue_free()

func been_merge(d, next_event, new_event):
	var pos = now_pos + Util.direction_to_vector(d)
	
	self.play_front_merge_ani(d)
	next_event.play_next_merge_ani(d)
	
	new_event.transport_to(pos)
	new_event.play_new_merge_ani()
	
	new_event.add_to_group("new_merged_event")
	
	Sound.play_se("res://Sounds/se/zip_1.wav")
	pass

func play_new_merge_ani():
	var merge = load("res://Scenes/Animations/merge_new_event_animation.tscn").instantiate()
	var merge_particle = load("res://Scenes/Animations/split_particle.tscn").instantiate()
	get_node("WordSprite").add_child(merge)
	merge_particle.name = "particles"
	add_child(merge_particle)
	
	var ani = get_node("WordSprite/merge_new_event_animation/AnimationPlayer")
	ani.play("5")
	await ani.animation_finished
	merge.queue_free()
	merge_particle.queue_free()
	tileMap.check_rule()

func play_front_merge_ani(d):
	var merge = load("res://Scenes/Animations/merge_front_event_animation.tscn").instantiate()
	get_node("WordSprite").add_child(merge)
	
	var ani = get_node("WordSprite/merge_front_event_animation/AnimationPlayer")
	ani.play(str(d))
	await ani.animation_finished
	get_node("WordSprite").position = Vector2(30, 30)
	get_node("WordSprite").scale = Vector2(1, 1)
	get_node("WordSprite").modulate = Color(1, 1, 1, 1)
	merge.queue_free()
	self.transport_to(Vector2( - 10, - 10))
	
func play_next_merge_ani(d):
	var merge = load("res://Scenes/Animations/merge_next_event_animation.tscn").instantiate()
	get_node("WordSprite").add_child(merge)
	
	var ani = get_node("WordSprite/merge_next_event_animation/AnimationPlayer")
	ani.play(str(d))
	await ani.animation_finished
	get_node("WordSprite").position = Vector2(30, 30)
	get_node("WordSprite").scale = Vector2(1, 1)
	get_node("WordSprite").modulate = Color(1, 1, 1, 1)
	merge.queue_free()
	self.transport_to(Vector2( - 10, - 10))
