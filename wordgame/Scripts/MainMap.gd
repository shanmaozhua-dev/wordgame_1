@tool
extends "BaseMap.gd"

const SentenceLegalResourse = preload("res://Scenes/Animations/SentenceLegal.tscn")
const HighlightResourse = preload("res://Scenes/Animations/Light2.tscn")

@export var bound: Rect2: set = on_set_bound

@export var is_camera_grid_snapping: bool
@export var grid_snapping_bound: Rect2

@export var draw_debug_grid: bool

@export var has_bgm: bool
@export var bgm_path: String

@export_enum("fade", "crossfade", "sync") var bgm_transition_type: String = "fade"

@export var has_env: bool
@export var env_path: String

@export var bgm_layering_path: String
@export var is_bgm_layering_active: bool = false

@export var floor_type: String

@export var has_reverb: bool
@export var reverb_mix_rate = 0.01 # (float, 0, 1)

var interpreter

@onready var fixed_map = $"TopLayer/FixedMap"

func on_set_bound(v):
	if bound == v:
		return
	bound = v
	
	clear()
	for y in range(bound.position.y, bound.end.y):
		for x in range(bound.position.x, bound.end.x):
			set_cell_compat(x, y, 1)
	
	return
				
func is_in_bound(pos):
	if bound.position.x <= pos.x and pos.x < bound.end.x:
		if bound.position.y <= pos.y and pos.y < bound.end.y:
			return true
	return false

@export var player_spawn_pos: Vector2

var player

var is_inited = false
func _ready():
	if Engine.is_editor_hint():
		return
		
	if is_inside_tree():
		_on_tree_entered()
	else:
		connect("tree_entered", Callable(self, "_on_tree_entered"))
	
func _on_tree_entered():
	var pt1 = Time.get_ticks_msec()
	
	Global.game_map = self
	Global.update_self_game_condition()
		
	interpreter = $Interpreter
	

	
	if Global.all_map_status.has(Global.now_map_name):
		print("load_status")
		load_status(Global.all_map_status[Global.now_map_name])
	
	init_bgm()
	
	if has_reverb:
		Sound.set_reverb(true, reverb_mix_rate)
	else:
		Sound.set_reverb(false)
	
	init_events()
	init_player()
	
	refresh()
	
	is_inited = true
	

	




	var nt1 = Time.get_ticks_msec()
	print("map_init_time: ", nt1 - pt1)

	
	if Global.is_game_pause:
		Global.game_resume()

func init_bgm():
	if not has_bgm and Sound.current_bgm_path:
		Sound.fade_out_and_stop_bgm(1)
	elif bgm_path:
		if bgm_layering_path and is_bgm_layering_active:
			Sound.play_bgm(bgm_path, 0, 0, bgm_layering_path)
		else:
			match bgm_transition_type:
				"", "fade":
					Sound.play_bgm(bgm_path)
				"crossfade":
					Sound.crossfade_bgm(bgm_path)
				"sync":
					Sound.crossfade_bgm(bgm_path, 1, true)
	elif has_bgm:
		set_bgm(true, Sound.current_bgm_path, false)
	
	if not has_env and Sound.current_env_path:
		Sound.fade_out_and_stop_env(1)
	elif env_path:
		Sound.play_env(env_path)

func init_events():
	for event in get_tree().get_nodes_in_group("events"):
		event.init()


func init_player():
	
	
	if get_tree().get_nodes_in_group("player"):
		player = get_tree().get_nodes_in_group("player")[0]
	else:
		player = PlayerResourse.instantiate()
		add_child(player)
	
	
	var spawn_pos
	if Global.player_status_for_map_change["spawn_pos"]:
		spawn_pos = Global.player_status_for_map_change["spawn_pos"]
	elif player_spawn_pos:
		spawn_pos = player_spawn_pos
		
	if spawn_pos:
		player.transport_to(spawn_pos)
		
	if Global.player_status_for_map_change["opacity"] != null:
		player.opacity = Global.player_status_for_map_change["opacity"]
	elif Global.player_status.opacity != player.opacity:
		player.opacity = Global.player_status.opacity
		
	player.init()

func is_any_event_running():
	if interpreter.is_running():
		return true



	return false
	

















func is_event_in_fixed_map(e):
	return $TopLayer.is_ancestor_of(e)

func get_event_by_pos(pos):
	var events = [];

	if event_table.has(pos) and event_table[pos].size() > 0:
		for event_path in event_table[pos]:
			var e = get_node(event_path)
			if e and e.existing:
				events.append(e)

	if events.size() == 0:
		return null
	if events.size() == 1:
		return events[0]
	else:
		var now_rank = - 9999
		var now_rank_event
		for event in events:
			var rank_score = event.z_index
			if event.is_high_priority:
				rank_score += 1000
			if rank_score > now_rank:
				now_rank = rank_score
				now_rank_event = event

		return now_rank_event

func get_events_by_pos(pos):
	var events = [];

	if event_table.has(pos) and event_table[pos].size() > 0:
		for event_path in event_table[pos]:
			var e = get_node(event_path)
			if e and e.existing:
				events.append(e)
	return events

func get_event_by_name(_name):
	if has_node(_name):
		return get_node(_name)
	
	for event in get_tree().get_nodes_in_group("events"):
		if event.get_name() == _name and not $TopLayer.is_ancestor_of(event) and event.existing:
			return event
	return null

func get_events_by_text(text):
	var events = [];
	for event in get_tree().get_nodes_in_group("events"):
		if event.text == text and not $TopLayer.is_ancestor_of(event) and event.existing:
			events.append(event)
	if events.size() == 0:
		return null
	else:
		return events

func setup_starting_event():
	if interpreter.is_running():
		return false
	
	for event in get_tree().get_nodes_in_group("events"):
		if event.existing and event.is_starting():
			print("catch")
			event.clear_starting_flag()
			interpreter.setup(event.list, event)
			return true
	return false

func is_interpreter_running_this_event(event):
	return interpreter.event and event.get_path() == interpreter.event.get_path()


func get_map_text_array_both_dir():
	var h_array = get_map_text_array();
	var v_array = get_rotate_text_array(h_array);
	return [h_array, v_array]



func get_map_text_array(mode = "horizontal"):
	var pt = Time.get_ticks_msec()
	
	var map_text_array = []
	var map_z_index_array = []
	
	for y in range(bound.position.y, bound.end.y):

		var arr = ""
		for i in range(bound.size.x):

			arr += "＿"
		map_text_array.append(arr)
		
		var z_arr = []
		for i in range(bound.size.x):
			z_arr.append( - 1)
		map_z_index_array.append(z_arr)
	
	for event in get_tree().get_nodes_in_group("events"):
		if event.text and not $TopLayer.is_ancestor_of(event) and event.existing:
			var pos = event.now_pos
			if bound.has_point(pos):
				
				if map_text_array[pos.y][pos.x] == "＿" or map_z_index_array[pos.y][pos.x] <= event.z_index:
					map_text_array[pos.y][pos.x] = event.text
					map_z_index_array[pos.y][pos.x] = event.z_index
				
				


		elif event.is_in_group("big_event") and not $TopLayer.is_ancestor_of(event) and event.existing:
			for sub_pos in event.sub_events:
				var pos = sub_pos + event.now_pos
				if bound.has_point(pos):
					
					if map_text_array[pos.y][pos.x] == "＿" or map_z_index_array[pos.y][pos.x] <= event.z_index:
						map_text_array[pos.y][pos.x] = event.sub_events[sub_pos]
						map_z_index_array[pos.y][pos.x] = event.z_index
					

	if bound.has_point(player.now_pos):
		var pos = player.now_pos
		if map_text_array[pos.y][pos.x] == "＿" or map_z_index_array[pos.y][pos.x] <= player.z_index:
			if not ("is_in_word" in player and player.is_in_word):
				map_text_array[pos.y][pos.x] = "Ｍ"
				map_z_index_array[pos.y][pos.x] = player.z_index
	
	if mode == "horizontal":
		return map_text_array
	if mode == "vertical":
		return get_rotate_text_array(map_text_array)
	





























































	










	

	


	

	

func get_rotate_text_array(org):
	var new = []

	var org_w = org[0].length()
	var org_h = org.size()

	for x in range(org_w):
		var line = ""
		for y in range(org_h):
			line += org[y][x]
		new.append(line)
	return new

@export_multiline var sentence_rules: String = ""
var sentence_rule_status = {}

func check_rule():
	if not is_inited:
		return
	
	$EffectLayer.clear_effect()
	if not sentence_rules:
		return
		





	var _sentence_rules
		
	var test_json_conv = JSON.new()
	var json_error = test_json_conv.parse(sentence_rules)
	if json_error == OK and test_json_conv.get_data():
		_sentence_rules = test_json_conv.get_data()
	else:
		print("error:", sentence_rules)
		print(json_error)
		print(test_json_conv.get_data())
	

	
	var map_text_arrays = get_map_text_array_both_dir()
	


	var regex = RegEx.new()

	for sentence_rule in _sentence_rules:
		
		if not sentence_rule_status.has(sentence_rule.text):
			sentence_rule_status[sentence_rule.text] = false
		
		var sentence_text = sentence_rule.text
		
		if sentence_rule.get("except", ""):
			sentence_text = sentence_text.replace("＊", "[^" + sentence_rule.except + "]")
		else:
			sentence_text = sentence_text.replace("＊", ".")
		
		regex.compile(sentence_text)
		
		var is_get_valid_result = false
		for i in range(2):
			if is_get_valid_result:
				break
			
			var map_text_array = map_text_arrays[i]
			for row_index in range(map_text_array.size()):
				if is_get_valid_result:
					break
					
				



					

				

					






				var result = regex.search(map_text_array[row_index])


				
				
				if result:

					is_get_valid_result = true
					
					if not sentence_rule_status[sentence_rule.text]:

						Global.set_game_switch(sentence_rule.switch, true)
						sentence_rule_status[sentence_rule.text] = true
						if sentence_rule.get("memory", null):
							for memory in sentence_rule.memory:
								var memory_event_variable = memory[0]
								var memory_event_index = memory[1]
								var event_pos
								if i == 0:
									event_pos = Vector2(result.get_start() + memory_event_index, row_index)
								else:
									event_pos = Vector2(row_index, result.get_start() + memory_event_index)
								event_pos += bound.position
								
								var memory_event = get_event_by_pos(event_pos)
								if memory_event:
									Global.set_game_variable(memory_event_variable, memory_event.name)
									
								else:
									if player.now_pos == event_pos:
										Global.set_game_variable(memory_event_variable, "player")
						if sentence_rule.get("has_animation", true):
							if i == 0:
								var start_pos = Vector2(result.get_start() * 60, row_index * 60)
								start_pos += bound.position * 60
								play_sentence_legal_animation(start_pos, sentence_text.length(), true, null, sentence_rule.get("progress", 0), sentence_rule.get("level", 5))
							else:
								var start_pos = Vector2(row_index * 60, result.get_start() * 60)
								start_pos += bound.position * 60
								play_sentence_legal_animation(start_pos, sentence_text.length(), false, null, sentence_rule.get("progress", 0), sentence_rule.get("level", 5))
				
		
		if not is_get_valid_result:
			if sentence_rule_status[sentence_rule.text]:

				if sentence_rule.get("has_animation", true):
					clear_sentence_legal_animation()
				Global.set_game_switch(sentence_rule.switch, false)
				sentence_rule_status[sentence_rule.text] = false
		



	
signal sentence_legal_animation_started
signal sentence_legal_animation_finished
func play_sentence_legal_animation(pos, text_count, is_h = true, sentence_width = null, progress = 0, level = 5, start_offset = 0, is_last = true):
	emit_signal("sentence_legal_animation_started")




	
	if is_last:
		Global.game_pause()
	
	progress = int(Util.get_value_from_str(progress))
	level = int(Util.get_value_from_str(level))
	is_h = bool(Util.get_value_from_str(is_h))
	
	var legal_ani = load("res://Scenes/Animations/SentenceLegal_new.tscn").instantiate()
	add_child(legal_ani)
	legal_ani.position = pos
	legal_ani.play(text_count, is_h, sentence_width, progress, level, start_offset)
	await legal_ani.finished
	
	if is_last:
		while not Input.is_action_just_pressed("ui_accept"):
			await get_tree().process_frame
		over_sentence_legal_animation()
		Global.game_resume()
	
	emit_signal("sentence_legal_animation_finished")

func play_sentence_legal_animation_old(pos, text_count, is_h = true, sentence_width = null, progress = 0, level = 5, start_offset = 0):
	var legal_ani = SentenceLegalResourse.instantiate()
	add_child(legal_ani)
	legal_ani.position = pos
	legal_ani.play(text_count, is_h, sentence_width, progress, level)
	await legal_ani.finished
	legal_ani.queue_free()
	emit_signal("sentence_legal_animation_finished")

func over_sentence_legal_animation():
	for s in get_tree().get_nodes_in_group("sentence_legal"):
		over_sentence_legal_animation_single(s)

func over_sentence_legal_animation_single(s):
	s.over()
	await s.finished
	s.queue_free()

func has_played_sentence_legal_animation():
	if has_node("SentenceLegal"):
		return true
	return false

func clear_sentence_legal_animation():
	if has_node("SentenceLegal"):
		get_node("SentenceLegal").queue_free()

func play_text_highlight_animation(pos, text_count, is_h = true):
	var lights = []
	for i in range(text_count):
		var light = HighlightResourse.instantiate()
		lights.append(light)
		add_child(light)
		if is_h:
			light.position = pos + Vector2(i * 60 + 30, 30)
		else:
			light.position = pos + Vector2(30, i * 60 + 30)
		light.get_node("AnimationPlayer").play("light_up")
	await lights[0].get_node("AnimationPlayer").animation_finished
	
	for light in lights:
		light.queue_free()



func set_bgm(_has_bgm = true, _bgm_path = null, need_refresh = true):
	has_bgm = _has_bgm
	if _bgm_path:
		bgm_path = _bgm_path
	
	if need_refresh:
		init_bgm()

func set_env(_has_env = true, _env_path = null, need_refresh = true):
	has_env = _has_env
	if _env_path:
		env_path = _env_path
	
	if need_refresh:
		init_bgm()
	
func set_bgm_layering(_bgm_layering_path = null, is_active = false):
	is_bgm_layering_active = is_active
	if _bgm_layering_path:
		bgm_layering_path = _bgm_layering_path
	init_bgm()

func set_bgm_layering_active(is_active):
	is_bgm_layering_active = is_active
	init_bgm()

func save_status():
	var status = {}
	
	status.map_status = {
		"sentence_rules": sentence_rules, 
		"has_bgm": has_bgm, 
		"bgm_path": bgm_path, 
		"floor_type": floor_type, 
		"has_env": has_env, 
		"env_path": env_path, 
		"bgm_layering_path": bgm_layering_path, 
		"is_bgm_layering_active": is_bgm_layering_active, 
		"bgm_transition_type": bgm_transition_type
	}
	
	status[player.get_path()] = player.save_status()
	
	for event in get_tree().get_nodes_in_group("events"):

		if event.need_be_saved:

			status[event.get_path()] = event.save_status()
		
	return status

func load_status(status):
	sentence_rules = status.map_status.get("sentence_rules", sentence_rules)
	has_bgm = status.map_status.get("has_bgm", has_bgm)
	bgm_path = status.map_status.get("bgm_path", bgm_path)
	floor_type = status.map_status.get("floor_type", floor_type)
	has_env = status.map_status.get("has_env", has_env)
	env_path = status.map_status.get("env_path", env_path)
	bgm_layering_path = status.map_status.get("bgm_layering_path", bgm_layering_path)
	is_bgm_layering_active = status.map_status.get("is_bgm_layering_active", is_bgm_layering_active)
	bgm_transition_type = status.map_status.get("bgm_transition_type", bgm_transition_type)
	
	for event_name in status.keys():
		if event_name == "map_status":
			continue
		

		var event




		

		
		if get_tree().get_root().has_node(event_name):
			event = get_tree().get_root().get_node(event_name)
			event.load_status(status[event_name])
		else:
			if not ("generated_in_runtime" in status[event_name].groups):
				
				continue











			
			var pos = Vector2(status[event_name].pos_x, status[event_name].pos_y)
			var new_event
			if status[event_name].parent.find("FixedMap") == - 1:
				new_event = add_new_event(pos)
			else:
				new_event = $TopLayer/FixedMap.add_new_event(pos)
			new_event.load_status(status[event_name])
			






class MyAStar:
	extends AStar3D
	func _compute_cost(u, v):
		return abs(u - v)
	func _estimate_cost(u, v):
		return min(0, abs(u - v) - 1)


@onready var astar_node = MyAStar.new()





var path_start_position = Vector2(): set = _set_path_start_position
var path_end_position = Vector2(): set = _set_path_end_position

var _point_path = []



var obstacles
@onready var _half_cell_size = get_cell_size() / 2







func astar_add_walkable_cells():
	var points_array = []
	for y in range(bound.size.y):
		for x in range(bound.size.x):
			var point = Vector2(x, y)
			if point != path_start_position and point != path_end_position:
				if event_table.has(point):
					continue
				if player.now_pos == point:
					continue

			points_array.append(point)
			var point_index = calculate_point_index(point)
			astar_node.add_point(point_index, Vector3(point.x, point.y, 0.0))
	return points_array

func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		var points_relative = PackedVector2Array([
			Vector2(point.x + 1, point.y), 
			Vector2(point.x - 1, point.y), 
			Vector2(point.x, point.y + 1), 
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)
			if is_outside_map_bounds(point_relative):
				continue
			if not astar_node.has_point(point_relative_index):
				continue
			astar_node.connect_points(point_index, point_relative_index, false)

func is_outside_map_bounds(point):
	return not is_in_bound(point)
	
func calculate_point_index(point):
	return point.x + bound.size.x * point.y

func find_path(start, end):
	astar_node = MyAStar.new()
	
	print(start, end)
	var walkable_cells_list = astar_add_walkable_cells()
	astar_connect_walkable_cells(walkable_cells_list)
	
	self.path_start_position = start
	self.path_end_position = end
	_recalculate_path()
	var path_2d = []
	for point in _point_path:
		var point_2d = Vector2(point.x, point.y)
		path_2d.append(point_2d)
	

	


	return path_2d

func _recalculate_path():
	var start_point_index = calculate_point_index(path_start_position)
	var end_point_index = calculate_point_index(path_end_position)
	_point_path = astar_node.get_point_path(start_point_index, end_point_index)


func _set_path_start_position(value):







	path_start_position = value
	if path_end_position and path_end_position != path_start_position:
		_recalculate_path()


func _set_path_end_position(value):







	path_end_position = value
	if path_start_position != value:
		_recalculate_path()


func _on_GamePlayTimer_timeout():
	if GA.section_data.has("spend_time"):
		GA.section_data.spend_time += 1






@export_multiline var split_list: String = ""
@export_multiline var merge_list: String = ""

var split = {
	"他": ["人", "也", {
		"event_name": ["人", "也"]
	}], 
}

var merge = {
	["人", "也"]: ["他", {
		"event_name": "他", 
	}]
}

func can_event_split(e):
	if not split_list: return null
	var _split_list = str_to_var(split_list)
	
	if _split_list.has(e.text):
		print("can_event_split")
		return true
	return false

func get_splitted_events(e, pos):
	if not split_list: return null
	var _split_list = str_to_var(split_list)
	
	if not _split_list.has(e.text):
		return null
	
	var split_events = []
	var e1
	var e2
	
	var option = {}
	if _split_list[e.text].size() == 3:
		option = _split_list[e.text][2]
	if option.has("event_name"):
		e1 = Global.game_map.get_event_by_name(option["event_name"][0])
		e2 = Global.game_map.get_event_by_name(option["event_name"][1])
		e1.transport_to(pos)
		e2.transport_to(pos)
	else:
		e1 = Global.game_map.type(_split_list[e.text][0], pos)
		e2 = Global.game_map.type(_split_list[e.text][1], pos)
		e1.can_push = true
		e2.can_push = true
		e1.can_split = true
		e2.can_split = true
	
	split_events.append(e1)
	split_events.append(e2)
	return split_events

func can_event_merge(e1, e2):
	if not merge_list: return null
	var _merge_list = str_to_var(merge_list)
	
	var t = [e1.text, e2.text]
	var t_reverse = [e2.text, e1.text]
	if _merge_list.has(t) or _merge_list.has(t_reverse):
		print("can_event_merge")
		return true
	return false

func get_merged_events(e1, e2, pos):
	var _merge_list = str_to_var(merge_list)
	
	var text = [e1.text, e2.text]
	if not _merge_list.has(text):
		text = [e2.text, e1.text]
		if not _merge_list.has(text):
			return null
	
	var merge_event
	
	var option = {}
	if _merge_list[text].size() == 2:
		option = _merge_list[text][1]
	if option.has("event_name"):
		merge_event = Global.game_map.get_event_by_name(option["event_name"])
		merge_event.transport_to(pos)
		print("merge_event: ", merge_event.name)
	else:
		merge_event = Global.game_map.type(_merge_list[text][0], pos)
		merge_event.can_push = true
		merge_event.can_split = true
	return merge_event
	pass
