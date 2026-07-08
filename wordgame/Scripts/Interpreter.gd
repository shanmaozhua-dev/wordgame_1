extends Node

var event
var target
var tween
var execute_type = "once"
var wait_mode = ""
var wait_count = 0
var index = 0
var params = []

signal finished_signal

const TWEEN_TRANSITIONS = {
	"TRANS_LINEAR": Tween.TRANS_LINEAR,
	"TRANS_SINE": Tween.TRANS_SINE,
	"TRANS_QUINT": Tween.TRANS_QUINT,
	"TRANS_QUART": Tween.TRANS_QUART,
	"TRANS_QUAD": Tween.TRANS_QUAD,
	"TRANS_EXPO": Tween.TRANS_EXPO,
	"TRANS_ELASTIC": Tween.TRANS_ELASTIC,
	"TRANS_CUBIC": Tween.TRANS_CUBIC,
	"TRANS_CIRC": Tween.TRANS_CIRC,
	"TRANS_BOUNCE": Tween.TRANS_BOUNCE,
	"TRANS_BACK": Tween.TRANS_BACK,
	"TRANS_SPRING": Tween.TRANS_SPRING,
}

const TWEEN_EASES = {
	"EASE_IN": Tween.EASE_IN,
	"EASE_OUT": Tween.EASE_OUT,
	"EASE_IN_OUT": Tween.EASE_IN_OUT,
	"EASE_OUT_IN": Tween.EASE_OUT_IN,
}

var list = []

var branch = {}
var indent = 0






func clear():
	list = []

	wait_mode = ""
	wait_count = 0
	index = 0
	params = []
	event = null

func setup(_list, _event):
	clear()
	event = _event



	list = add_indent_to_list(_list)
	
	print("now running: " + str(event.get_path()))


func add_indent_to_list(_list):
	var _indent = 0
	for command in _list:
		command.indent = _indent
		
		if command.command.substr(0, 2) == "if" or command.command == "else":
			_indent = _indent + 1
			
		if command.command == "end_if":
			_indent = _indent - 1
	
	return _list
	
	
func set_list(l):
	wait_mode = ""
	wait_count = 0
	index = 0
	list = l
	


func _physics_process(delta):
	
	if Global.is_game_pause:
		return
	
	update()

func update():
	
	while is_running():
		if update_wait():
			break
		if not execute_command():
			break

func is_running():
	return not not list

func update_wait():
	return update_wait_count() or update_wait_mode()

func update_wait_count():
	if wait_count > 0:
		wait_count -= 1
		return true
	return false

func wait(duration):
	wait_count = duration

func update_wait_mode():
	var waiting = false
	match wait_mode:
		"move":
			waiting = target and target.is_moving()
		"move_route":
			waiting = target and target.is_move_route_forcing
		"sprite_animation":
			waiting = target and target.get_node("WordSprite/AnimationPlayer").current_animation == "sprite_animation" and target.get_node("WordSprite/AnimationPlayer").is_playing()
		"type":
			waiting = Typewriter.is_running()
		"type_parallel":
			waiting = $"Typewriter_parallel".is_running()
		"fade_black_screen":
			waiting = UI.animation_player.is_playing()
		"fade_screen":
			waiting = UI.is_fading_screen
		"tween":
			if is_instance_valid(tween):
				waiting = tween.is_active()
			else:
				waiting = false
		"signal":
			waiting = true
	if not waiting:
		wait_mode = ""
	return waiting
	
func set_wait_mode(mode):
	wait_mode = mode

func get_tween_transition(name, fallback = Tween.TRANS_LINEAR):
	return TWEEN_TRANSITIONS.get(str(name), fallback)

func get_tween_ease(name, fallback = Tween.EASE_IN_OUT):
	return TWEEN_EASES.get(str(name), fallback)
	
func execute_command():
	var command = current_command()
	if command:
		params = command.get("parameters", null)
		indent = command.indent
		var method_name = "command_" + command["command"]


		call(method_name)
		
		index += 1
	else:
		terminate()
	return true

func current_command():
	if execute_type == "loop":
		index = index % list.size()
	if index >= list.size():
		return false
	return list[index]


func skip_branch():
	while index < list.size() - 1 and list[index + 1].indent > indent:
		index = index + 1


func terminate():
	list = []
	
	if event and not event.is_in_group("was_lock_before_start_event"):
		event.unlock()
	
	if event and event.is_in_group("was_lock_before_start_event"):
		event.remove_from_group("was_lock_before_start_event")
	
	event = null
	
	ask_map_for_next_start_event()

func ask_map_for_next_start_event():
	Global.game_map.setup_starting_event()

func get_target():
	if params and typeof(params) == TYPE_STRING:
		return get_target_from_str(params)
	if params and params.has("target"):
		if params.get("target_type", "name") == "name":
			return get_target_from_str(params.target)
		if params.get("target_type", "name") == "path":
			return get_target_from_str(params.target, params.target_type)
		if params.get("target_type", "name") == "child":
			return get_target_from_str(params.target, params.target_type)
	
	return event

func get_target_from_str(target_name, target_type = "name"):
	var event_name
	if Util.str_to_var(target_name).type == "variable":
		var var_name = Util.str_to_var(target_name).value
		event_name = Global.get_game_variable(var_name)
	else:
		event_name = target_name
	
	if target_type == "name":
		if event_name == "self":
			return event
		if event_name.to_lower() == "player":
			return Global.game_map.player
		
		var e = Global.game_map.get_event_by_name(event_name)
		if e:
			return e
		
		return get_tree().get_root().find_child(event_name, true, false)
	if target_type == "path":
		return get_tree().get_root().get_node(event_name)
	if target_type == "child":
		return event.get_node(event_name)

func command_break():
	index = list.size() - 1

func command_set_switch():
	Global.set_game_switch(params[0], params[1])
	
func command_toggle_switch():
	Global.set_game_switch(params[0], not Global.get_game_switch(params[0]))


func command_set_variable():
	Global.set_game_variable(params[0], params[1])
func command_add_variable():
	Global.set_game_variable(params[0], Global.get_game_variable(params[0]) + params[1])

func command_set_self_switch():
	
	Global.set_game_self_switch(event.name, params[0], params[1])

func command_set_other_self_switch():
	
	target = get_target()
	Global.set_game_self_switch(target.name, params.switch, params.value)

func command_toggle_self_switch():
	
	Global.set_game_self_switch(event.name, params[0], not Global.get_game_self_switch(event.name, params[0]))




func command_if_variable():
	var result = false
	
	var variable = Global.get_game_variable(params[0])
	var compare = params[2]
	
	match params[1]:
		"==":
			result = variable == compare
		"!=":
			result = variable != compare
		"<":
			result = variable < compare
		"<=":
			result = variable <= compare
		">":
			result = variable > compare
		">=":
			result = variable >= compare
	
	branch[indent] = result
	if branch[indent] == false:
		skip_branch()
	return true
	


func command_if_switch():
	var result = false
	
	var reverse = false
	
	var condition = params[0]
	if condition.substr(0, 1) == "!":
		reverse = true
		condition.erase(0, 1)
		
	if condition.find("self:") != - 1:
		condition.erase(0, condition.find("self:") + 5)
		
		if reverse:
			result = not Global.get_game_self_switch(event.name, condition)
		else:
			result = Global.get_game_self_switch(event.name, condition)
	else:
		if reverse:
			result = not Global.get_game_switch(condition)
		else:
			result = Global.get_game_switch(condition)
	
	branch[indent] = result
	if branch[indent] == false:
		skip_branch()
	return true


func command_if():
	
	
	
	

	var result = false
	var str_condition = params
	result = Util.is_str_condition_vaild(str_condition, event.name)

	branch[indent] = result
	if branch[indent] == false:
		skip_branch()
	return true



func command_else():
	if branch[indent] != false:
		skip_branch()
	return true

func command_end_if():
	pass

func command_if_random():
	var result = [false, true][randi() % 1]
	
	branch[indent] = result
	if branch[indent] == false:
		skip_branch()
	return true

func command_print():
	
	print(Util.get_value_from_str(params))



func command_set_type_animation():
	
	Typewriter.set_animation(params)

func command_set_type_accept():
	
	Typewriter.set_accept(params)

func command_type():
	
	
	print("type: ", params.texts)

	Typewriter.type_writer(params)

	
	
	
	
	
	
	
	if params.get("wait", true):
		set_wait_mode("type")
	
	return false
	
func command_type_parallel():
	

	
	
	
	
	
	
	var tw
	
	if not params.get("wait", true):
		tw = Node.new()
		tw.set_script(load("res://Scripts/Typewriter.gd"))
		tw.set_accept(false)
		add_child(tw)
	elif not has_node("Typewriter_parallel"):
		tw = Node.new()
		tw.name = "Typewriter_parallel"
		tw.set_script(load("res://Scripts/Typewriter.gd"))
		tw.set_accept(false)
		add_child(tw)
	else:
		tw = $"Typewriter_parallel"
	
	tw.type_writer(params)
	
	
	
	if params.get("wait", true):
		set_wait_mode("type_parallel")
	
	return false


func command_type_fixed():
	
	print("type_fixed: ", params.texts)
	
	var texts = params.texts
	var pos = Vector2(params.pos[0], params.pos[1])
	var tags = params.get("tags", [])
	var has_defalut_tag = params.get("has_defalut_tag", true)
	
	Typewriter.type_writer_fixed(texts, pos, tags, has_defalut_tag)
	
	set_wait_mode("type")
	
	return false
	
func command_clear_typed():
	
	var tag = params

	Typewriter.delete_text_by_tag(tag)

func command_move_route():
	


	target = get_target()
	target.force_move_route(params.route)
	
	if params.get("wait", true):
		set_wait_mode("move_route")
	
	return false

func command_wait():
	
	wait(params)
	
	return true

func command_wait_random_in_range():
	
	var wait_time = randi() % int(params[1] - params[0]) + params[0]
	
	wait(wait_time)
	
	return true

	
func command_map_transport():
	
	print("map transport: ", params)
	
	var map_name = params.map
	var pos = params.get("pos", null)
	if pos:
		pos[0] = int(Util.get_value_from_str(pos[0]))
		pos[1] = int(Util.get_value_from_str(pos[1]))
		pos = Vector2(pos[0], pos[1])
	var need_to_save_map_status = params.get("need_to_save_map_status", true)
	var transition_type = params.get("transition_type", "fade")
	var opacity = params.get("opacity", null)
	if pos:
		pos = Vector2(pos[0], pos[1])
		
	Global.map_transport(map_name, pos, need_to_save_map_status, transition_type, opacity)
		
func command_transport_event():
	
	target = get_target()
	
	var pos = params.get("pos", null)
	if pos:
		pos[0] = int(Util.get_value_from_str(pos[0]))
		pos[1] = int(Util.get_value_from_str(pos[1]))
		pos = Vector2(pos[0], pos[1])
	target.transport_to(pos)
	
func command_set_event_params():
	
	target = get_target()
	if not target: return null
	
	for key in params:
		if key != "target" and target.get(key) != null:
			target[key] = params[key]


func command_set_event_loop_move_route():
	
	target = get_target()
	var loop_move_route = params.get("loop_move_route", null)
	if loop_move_route:
		target.loop_move_route = loop_move_route
		var test_json_conv = JSON.new()
		test_json_conv.parse(loop_move_route)
		var route_list = test_json_conv.get_data()
		if route_list and route_list.size() > 0:
			target.set_move_route(route_list)
	else:
		target.set_move_route([])

func command_refresh_event():
	
	target = get_target()
	target.refresh()

func command_remove_event():
	
	target = get_target()
	Global.game_map.delete_event_by_id(target.get_instance_id())
	Global.game_map.check_rule()

func command_play_sprite_animation():
	
	target = get_target()
	var is_reverse = params.get("reverse", false)
	target.play_sprite_animation(params.path, params.frame_count, params.time_sec, is_reverse, params.get("width", 10))
	
	if params.get("wait", true):
		set_wait_mode("sprite_animation")

func command_set_loop_sprite_animation():
	
	target = get_target()
	
	var keyframes = params.get("keyframes", null)
	target.set_loop_sprite_animation(params.path, params.frame_count, params.time_sec, keyframes)

func command_clear_sprite_animation():
	
	target = get_target()
	target.clear_sprite_animation()

func command_play_se():
	
	var db = params.get("db", 0)
	var pan = params.get("pan", 0)
	Sound.play_se(params.path, db, pan)

func command_play_se_with_position():
	
	target = get_target()
	var is_loop = params.get("loop", false)
	var max_dist = params.get("max_dist", 800)


	Sound.play_se_with_position(params.path, target, is_loop, max_dist)


	
func command_play_bgm():
	
	var db = params.get("db", 0)
	var pan = params.get("pan", 0)
	Sound.play_bgm(params.path, db, pan)
	
func command_change_bgm():
	
	var has_bgm = params.get("has_bgm", true)
	var path = params.get("path", null)
	Global.game_map.set_bgm(has_bgm, path)

func command_fade_in_bgm():
	
	Sound.fade_in_bgm(params)

func command_fade_out_bgm():
	
	Sound.fade_out_bgm(params)

func command_stop_bgm():
	Sound.stop_bgm()
	
func command_play_env():
	
	var db = params.get("db", 0)
	var pan = params.get("pan", 0)
	Sound.play_env(params.path, db, pan)
	
func command_change_env():
	
	var has_env = params.get("has_env", true)
	var path = params.get("path", null)
	Global.game_map.set_env(has_env, path)

func command_fade_in_env():
	
	Sound.fade_in_env(params)

func command_fade_out_env():
	
	Sound.fade_out_env(params)

func command_stop_env():
	Sound.stop_env()
	
func command_shake_camera():
	
	var p = Global.game_map.player
	
	if typeof(params) == TYPE_DICTIONARY:
		p.get_node("Camera3D").shake(
			params.get("frame"), 
			params.get("offset_x", 50), 
			params.get("offset_y", 0)
		)
	else:
		p.get_node("Camera3D").shake(params)
	
	

func command_add_text_event():
	
	if params.size() > 3:
		Global.game_map.type(params[0], Vector2(params[1][0], params[1][1]), params[2])
	else:
		Global.game_map.type(params[0], Vector2(params[1][0], params[1][1]))

	
func command_screen_shot():
	Global.screen_shot()
	
func command_screen_shot_event():
	
	target = get_target().get_node("WordSprite")
	
	var file_name = "res://screenshot_event"
	while FileAccess.file_exists(file_name + ".png"):
		file_name += "0"
	
	var img = target.texture.get_image()
	await get_tree().process_frame
	await get_tree().process_frame
	
	img.save_png(file_name + ".png")
	
	print("screen shot event.")
	
func command_tween_word_sprite():
	
	target = get_target().get_node("WordSprite")
	
	tween = target.create_tween()
	tween.set_parallel(true)
	
	if params.has("position"):
		tween.tween_property(target, "position:x", params.position[0], params.time_sec).from(target.position.x).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(target, "position:y", params.position[1], params.time_sec).from(target.position.y).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if params.has("rotation"):
		tween.tween_property(target, "rotation_degrees", params.rotation, params.time_sec).from(target.rotation_degrees).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
func command_save():
	
	var has_animation = (params == null) or params.get("has_animation", true)
	Global.save_game(has_animation)
	






func command_load():
	
	var trans_ani = params.get("trans_ani", "fade")
	Global.load_game(trans_ani)
	
	
func command_enter_section():
	
	if typeof(params) == TYPE_STRING:
		Global.enter_section(params)
	else:
		var section_name = params.get("section_name", "")
		var need_save = params.get("need_save", true)
		var has_animation = params.get("has_animation", true)
		
		if Global.now_game_section == null or Global.now_game_section == section_name:
			
			need_save = false
		
		Global.enter_section(section_name, need_save, has_animation)
		
		print("need_save: ", need_save)
		
		if need_save and has_animation:
			set_wait_mode("signal")
			await Global.save_completed
			set_wait_mode("")
	
func command_set_ctrl_z_power():
	
	Global.player_status.has_ctrl_z_power = params
func command_set_backspace_power():
	
	Global.player_status.has_backspace_power = params
func command_set_push_power():
	
	Global.player_status.has_push_power = params
func command_set_split_power():
	
	Global.player_status.has_split_power = params
	
func command_lock_event():
	
	target = get_target()
	
	var is_lock
	if params and typeof(params) == TYPE_DICTIONARY:
		is_lock = params.get("lock", null)
	else:
		is_lock = null
	
	if is_lock == null:
		if target.locked:
			target.unlock()
		else:
			target.lock()
	else:
		if is_lock:
			target.lock()
		else:
			target.unlock()
	
	
func command_event_fade_to():
	target = get_target()
	var op = params.get("opacity", 0)
	var time = params.get("time_sec", 1)
	target.fade_to(op, time)
	
	
func command_backspace_event():
	
	target = get_target()
	target.been_backspace()

func command_play_backspace_fail_animation():
	Global.game_map.player.backspace_fail_animation()

func command_dissolve_event():
	
	target = get_target()
	target.been_dissolve(params.get("option", null))

func command_crash_event():
	
	target = get_target()
	target.been_crash()
	
func command_unexist_event():
	
	target = get_target()
	target.exist(false)
	Global.game_map.check_rule()
	













			
func command_append_sentence_rule():
	
	var _sentence_rules
	
	if Global.game_map.sentence_rules:
		var test_json_conv = JSON.new()
		var json_error = test_json_conv.parse(Global.game_map.sentence_rules)
		if json_error == OK and test_json_conv.get_data():
			_sentence_rules = test_json_conv.get_data()
		else:
			print("error:", Global.game_map.sentence_rules)
	else:
		_sentence_rules = []
		
	var text = params.get("text", null)
	var switch = params.get("switch", null)
	var has_hint = params.get("has_hint", false)
	var has_animation = params.get("has_animation", true)
	var memory = params.get("memory", null)
	var progress = params.get("progress", 0)
	var level = params.get("level", 5)
	var except = params.get("except", null)
	
	
	for rule in _sentence_rules:
		if rule.text == text:
			return
	
	_sentence_rules.append({
		"text": text, 
		"switch": switch, 
		"has_hint": has_hint, 
		"has_animation": has_animation, 
		"memory": memory, 
		"progress": progress, 
		"level": level, 
		"except": except
	})
		
	Global.game_map.sentence_rules = JSON.stringify(_sentence_rules)
	
	Global.game_map.check_rule()

func command_change_sentence_rule():
	
	var _sentence_rules
	
	if Global.game_map.sentence_rules:
		var test_json_conv = JSON.new()
		var json_error = test_json_conv.parse(Global.game_map.sentence_rules)
		if json_error == OK and test_json_conv.get_data():
			_sentence_rules = test_json_conv.get_data()
		else:
			print("error:", Global.game_map.sentence_rules)
	else:
		_sentence_rules = []
		
	var text = params.get("text", null)
	
	for rule in _sentence_rules:
		if rule.text == text:
			rule.switch = params.get("switch", null)
			rule.has_hint = params.get("has_hint", false)
			rule.has_animation = params.get("has_animation", true)
			rule.memory = params.get("memory", null)
			rule.progress = params.get("progress", 0)
			rule.level = params.get("level", 5)
			rule.except = params.get("except", null)
	
	Global.game_map.sentence_rules = JSON.stringify(_sentence_rules)
	
	Global.game_map.check_rule()
	
func command_delete_sentence_rule():
	
	var _sentence_rules
	
	if Global.game_map.sentence_rules:
		var test_json_conv = JSON.new()
		var json_error = test_json_conv.parse(Global.game_map.sentence_rules)
		if json_error == OK and test_json_conv.get_data():
			_sentence_rules = test_json_conv.get_data()
		else:
			print("error:", Global.game_map.sentence_rules)
	else:
		_sentence_rules = []
		
	var text = params.get("text", null)
	
	for rule in _sentence_rules:
		if rule.text == text:
			_sentence_rules.remove_at(_sentence_rules.find(rule))
	
	Global.game_map.sentence_rules = JSON.stringify(_sentence_rules)
	
	Global.game_map.check_rule()
	
func command_clear_sentence_rule():
	Global.game_map.sentence_rules = ""
	Global.game_map.sentence_rule_status = {}
	Global.game_map.clear_sentence_legal_animation()
	Global.game_map.check_rule()
	
func command_start_constant_shake():
	
	var f = params.get("f", 0)
	var d = params.get("d", 0)
	UI.start_shake(f, d)
	
func command_stop_constant_shake():
	UI.stop_shake()
	
func command_sentence_legal_animation():
	

	var pos = params.get("pos", [0, 0])
	if pos:
		pos[0] = int(Util.get_value_from_str(pos[0]))
		pos[1] = int(Util.get_value_from_str(pos[1]))
		pos = Vector2(pos[0], pos[1])
	pos = Vector2(pos[0] * 60, pos[1] * 60)
	var text_count = params.get("text_count", 0)
	var is_h = params.get("is_h", true)
	var sectence_width = params.get("sectence_width", null)
	var progress = params.get("progress", 0)
	var level = params.get("level", 5)
	var start_offset = params.get("start_offset", 0)
	var is_last = params.get("is_last", true)
	
	Global.game_map.play_sentence_legal_animation(pos, text_count, is_h, sectence_width, progress, level, start_offset, is_last)


func command_highlight():
	
	var pos = params.get("pos", [0, 0])
	if pos:
		pos[0] = int(Util.get_value_from_str(pos[0]))
		pos[1] = int(Util.get_value_from_str(pos[1]))
		pos = Vector2(pos[0], pos[1])
	pos = Vector2(pos[0] * 60, pos[1] * 60)
	var text_count = params.get("text_count", 0)
	var is_h = params.get("is_h", true)
	Global.game_map.play_text_highlight_animation(pos, text_count, is_h)
		
func command_unzip_animation():
	target = get_target()
	var h = load("res://Scenes/Animations/Helmet.tscn").instantiate()
	target.add_child(h)
	h.position = Vector2(30, 30)
	h.get_node("AnimationPlayer").play("unzip")

func command_zip_animation():
	target = get_target()
	var h = load("res://Scenes/Animations/Helmet.tscn").instantiate()
	target.add_child(h)
	h.position = Vector2(30, 30)
	h.get_node("AnimationPlayer").play("zip")

		
func command_return_to_title_screen():
	
	if params:
		Global.return_to_title_screen(params)
	else:
		Global.return_to_title_screen()
	
func command_kill_player():
	
	target = get_target()
	target.lock()
	
	var death_sentence = ""
	var death_sentence_pos = [0, 0]
	if params:
		death_sentence = params.get("death_sentence", "")
		death_sentence_pos = params.get("death_sentence_pos", [0, 0])
	
	Global.kill_player(death_sentence, death_sentence_pos)
	
	
func command_death_scene_sentence():
	var death_sentence = Global.get_game_variable("死亡句子")
	if death_sentence:
		
		var option = {
			"texts": death_sentence[0], 
			"pos": death_sentence[1], 
			"tags": ["death_sentence"], 
			"has_defalut_tag": false, 
			"fixed": true, 
			"has_animation": false
		}
		Typewriter.type_writer(option)
		set_wait_mode("type")

func command_death_scene_text():

	var dead_pos = Global.game_map.player.now_pos
	print(dead_pos)
	if dead_pos.y < 15 and not (dead_pos.x == 17 and (dead_pos.y > 9 and dead_pos.y < 13)):
		var option = {
			"texts": "死&|了&|。", 
			"pos": [dead_pos.x, dead_pos.y + 1], 
			"has_defalut_tag": false, 
			"need_accept": false
		}
		Typewriter.type_writer(option)
		
	else:
		var option = {
			"texts": "死|了|。", 
			"pos": [dead_pos.x + 1, dead_pos.y], 
			"has_defalut_tag": false, 
			"need_accept": false
		}
		Typewriter.type_writer(option)
		
	set_wait_mode("type")
	
func command_ending():
	Global.game_map.player.lock()
	var vp = Global.game_map.get_node("VideoStreamPlayer")
	if Global.is_simplified:
		var ending_movie_path = "res://Sprites/ending_movie/00_ending_0819_sc.webm"
		if ResourceLoader.exists(ending_movie_path):
			vp.stream = load(ending_movie_path)
	vp.visible = true
	vp.play()

	await get_tree().process_frame
	await get_tree().process_frame

	Typewriter.delete_text_by_tag("typed")



	while vp.stream_position < 7.05:
		await get_tree().process_frame

	Global.game_map.player.get_node("Sprite2D").visible = false
	Global.set_game_switch("被巨人抓住中", true)

	while vp.stream_position < 26:
		await get_tree().process_frame

	Global.set_game_switch("被巨人抓住中", false)

	await vp.finished
	Global.map_transport("end_credit_scene")

func command_open_url():
	
	print(params)
	OS.shell_open(params)
	
func command_get_platform():
	print(OS.get_name())
	Global.set_game_variable(params, OS.get_name())
	
func command_change_floor_type():
	
	Global.game_map.floor_type = params.type
	
func command_add_loop_light():
	
	target = get_target()
	target.add_loop_light()

func command_remove_loop_light():
	
	target = get_target()
	target.remove_loop_light()

func command_set_opacity():
	
	target = get_target()
	target.opacity = params.get("opacity", 1)
	
func command_set_reverb():
	Sound.set_reverb(params)
	
func command_event_end_hint():
	
	target = Global.game_map.player
	target.force_move_route([
		{"command": "wait", "parameters": 10}, 
		{"command": "play_se", "parameters": {
			"path": "res://Sounds/se/typewriter/Bell中音.wav"
		}}, 
		{"command": "event_end_hint_jump"}, 
		{"command": "wait", "parameters": 10}
	])
	set_wait_mode("move_route")
	







	
	

func command_unlock_pulling_event():
	if Global.game_map.player.pulling_event and Global.game_map.player.pulling_event.name == "左囚不":
		Global.game_map.player.unlock_pulling_event()


func command_shake_event():
	
	target = get_target()
	var f = params.get("frame", 120)
	var d = params.get("distance", 10)

	target.shake(f, d)
	pass

func command_fade_black_screen():
	UI.fade_black_screen(params)
	set_wait_mode("fade_black_screen")

func command_fade_screen():
	
	if typeof(params) == TYPE_STRING:
		UI.fade_screen(params)
	else:
		UI.fade_screen(
			params.get("color"), 
			params.get("time_sec", 1)
		)
	
	set_wait_mode("fade_screen")

func command_tween_parameter():
	
	target = get_target()


	if params.has("add"):
		params.value = target.get_indexed(params.parameter) + params.add;
	
	tween = target.create_tween()
	
	var transition_type = get_tween_transition(params.get("transition_type", "TRANS_LINEAR"))
	var ease_type = get_tween_ease(params.get("ease_type", "EASE_IN_OUT"))
	

	
	tween.tween_property(target, params.parameter, params.value, params.time_sec).from(target.get_indexed(params.parameter)).set_trans(transition_type).set_ease(ease_type)

	if params.get("wait", true):
		set_wait_mode("tween")

	await tween.finished
	print("tween_all_completed")

func command_tween_shader_parameter():
	
	target = get_target()

	if params.has("add"):
		params.value = target.get_material().get_shader_parameter(params.parameter) + params.add;
	
	tween = target.create_tween()

	var material = target.get_material()
	var from_value = material.get_shader_parameter(params.parameter)
	tween.tween_method(
		func(value): material.set_shader_parameter(params.parameter, value),
		from_value,
		params.value,
		params.time_sec
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)


	if params.get("wait", true):
		set_wait_mode("tween")

	await tween.finished

func command_stop_tween_parameter():
	
	target = get_target()
	if is_instance_valid(tween):
		tween.kill()


func command_set_camera_follow_player():
	var camera = Global.game_map.player.get_node("Camera3D")
	camera.is_follow_player = params
	
func command_clone_event():
	
	target = get_target()
	
	var clone = target.duplicate()

	Global.game_map.add_child(clone)
	
	clone.add_to_group("generated_in_runtime")

	
	clone.init()
	
	if params.has("position"):
		clone.transport_to(Vector2(params.position[0], params.position[1]))
	
	if params.has("text"):
		clone.text = params.text

func command_call_method():
	target = get_target()
	if not target: return
	
	var method
	if params and typeof(params) == TYPE_DICTIONARY:
		method = params.get("method")
	else:
		method = params
	if not method: return
	
	var arg_array = params.get("arg_array", [])
	
	
	for i in arg_array.size():
		if typeof(arg_array[i]) == TYPE_STRING and arg_array[i] == "self":
			arg_array[i] = event
		if typeof(arg_array[i]) == TYPE_STRING and arg_array[i].begins_with("$"):
			var path = arg_array[i].substr(1)
			var e = Global.game_map.get_node(path)
			arg_array[i] = e
	
	target.callv(method, arg_array)
	
func command_fade_group():
	
	var op = params.get("opacity", 0)
	var time = params.get("time_sec", 1)
	for e in get_tree().get_nodes_in_group(params.get("group")):
		e.fade_to(op, time)

func command_dissolve_group():
	
	for e in get_tree().get_nodes_in_group(params.get("group")):
		e.been_dissolve(params.get("option", null))

func command_save_event_pos():
	
	target = get_target()
	
	var x = params.get("x", null)
	var y = params.get("y", null)
	
	if x:
		Global.set_game_variable(x, target.now_pos.x)
	if y:
		Global.set_game_variable(y, target.now_pos.y)

func command_wait_signal():
	
	target = get_target()
	
	set_wait_mode("signal")
	await target.params.get("signal", null)
	set_wait_mode("")
		
func command_wait_condition_vaild():
	
	if not Util.is_str_condition_vaild(params, null):
		index -= 1
		wait(1)

func command_add_to_group():
	
	target = get_target()
	
	if params.get("group", null):
		target.add_to_group(params.group)
		
func command_remove_from_group():
	
	target = get_target()
	
	if params.get("group", null) and target.is_in_group(params.group):
		target.remove_from_group(params.group)

func command_set_target():
	target = get_target()

func command_set_wait_mode():
	wait_mode = params


func command_create_event():

	var text = params.get("text")
	var pos = Vector2(params.get("pos")[0], params.get("pos")[1])
	var tags = params.get("tags", [])
	var e = Global.game_map.type(text, pos, tags)


	
	for key in params:
		if key != "target" and e.get(key) != null:
			e[key] = params[key]

func command_pan_camera_to_point():
	tween = create_tween()
	
	var transition_type = get_tween_transition(params.get("transition_type", "TRANS_SINE"), Tween.TRANS_SINE)
	var ease_type = get_tween_ease(params.get("ease_type", "EASE_IN_OUT"))
	
	var cam = Global.game_map.player.get_node("Camera3D")
	cam.is_follow_player = false
	
	var pos = Vector2(params.get("pos")[0], params.get("pos")[1]) * 60

	
	tween.tween_property(cam, "position", pos, params.time_sec).set_trans(transition_type).set_ease(ease_type)

	if params.get("wait", true):
		set_wait_mode("tween")

	await tween.finished

func command_quit_game():
	Global.quit_game()


func command_set_achievement():
	if typeof(params) == TYPE_STRING:
		Global.set_achievement(params)
	
func command_clear_achievement():
	if typeof(params) == TYPE_STRING:
		Global.clear_achievement(params)


func command_set_map_bgm():
	var map_name = params.get("map")
	var has_bgm = params.get("has_bgm", true)
	var bgm_path = params.get("bgm_path", "")
	var bgm_transition_type = params.get("bgm_transition_type", "fade")
	
	if Global.all_map_status.has(map_name):
		Global.all_map_status[map_name]["map_status"]["has_bgm"] = has_bgm
		Global.all_map_status[map_name]["map_status"]["bgm_path"] = bgm_path
		Global.all_map_status[map_name]["map_status"]["bgm_transition_type"] = bgm_transition_type
	else:
		Global.all_map_status[map_name] = {
			"map_status": {
				"has_bgm": has_bgm, 
				"bgm_path": bgm_path, 
				"bgm_transition_type": bgm_transition_type
			}
		}


func command_set_map_env():
	var map_name = params.get("map")
	var has_env = params.get("has_env", true)
	var env_path = params.get("env_path", "")
	
	if Global.all_map_status.has(map_name):
		Global.all_map_status[map_name]["map_status"]["has_env"] = has_env
		Global.all_map_status[map_name]["map_status"]["env_path"] = env_path
	else:
		Global.all_map_status[map_name] = {
			"map_status": {
				"has_env": has_env, 
				"env_path": env_path
			}
		}
