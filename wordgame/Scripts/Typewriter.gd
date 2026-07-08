extends Node

const EventResourse = preload("res://Scenes/Events/Event.tscn")





var tileMap

var type_speed = 1
var start_pos
var offset = Vector2(0, 0)
var text_list = ""
var tags = []
var wait_count = 0
var index = 0

var wait_for_accept = false
var has_accept = false

var has_released_accept = false

var has_animation = true
var need_accept = true

var has_se = true

var can_skip = true

var text_layer = null
var text_z_index = null
var text_color = null

var is_h = false

var char_type = null

var is_dialog_end = false

var now_labels = []
var label_settings = {}

var custom_path = ""

func set_animation(boolean):
	has_animation = boolean
	
func set_accept(boolean):
	need_accept = boolean


func type_writer(option = {}):
	
	
	if option.get("fixed", false):
		tileMap = get_tree().get_nodes_in_group("fixed_map")[0]
	else:
		tileMap = get_tree().get_nodes_in_group("map")[0]
	
	var org_texts = option.get("texts", "")
	text_list = str(Util.get_value_from_str(org_texts)).replace(" ", "").replace("\r\n", "").replace("\n", "").replace("\t", "")




	
	start_pos = option.get("pos", [0, 0])
	start_pos[0] = int(Util.get_value_from_str(start_pos[0]))
	start_pos[1] = int(Util.get_value_from_str(start_pos[1]))
	start_pos = Vector2(start_pos[0], start_pos[1])

	
	tags = option.get("tags", [])
	for i in range(tags.size()):
		tags[i] = str(Util.get_value_from_str(tags[i]))
	has_se = option.get("has_se", true)
	has_animation = option.get("has_animation", true)
	need_accept = option.get("need_accept", true)
	can_skip = option.get("can_skip", true)
	text_layer = option.get("layer", null)
	text_z_index = option.get("z_index", null)
	type_speed = option.get("type_speed", 1)
	text_color = option.get("text_color", null)
	is_h = option.get("is_h", true)
	custom_path = option.get("custom_path", "")
	char_type = option.get("char_type", null)
	is_dialog_end = option.get("is_dialog_end", false)

	if option.get("has_defalut_tag", true):
		tags.append("typed")
	var _offset = option.get("offset", [0, 0])
	offset = Vector2(_offset[0], _offset[1])
	
	if option.get("label_settings", null):
		label_settings = option.get("label_settings", null)
	
	index = 0
	has_released_accept = false
	
	

func type_writer_old(texts, s_pos, _tags = [], has_defalut_tag = true, _has_se = true):
	tileMap = get_tree().get_nodes_in_group("map")[0]
	
	text_list = texts.replace(" ", "").replace("\n", "").replace("\t", "")
	start_pos = s_pos
	tags = _tags
	if has_defalut_tag:
		tags.append("typed")
	offset = Vector2(0, 0)
	index = 0
	has_released_accept = false
	
	has_se = _has_se

func type_writer_fixed(texts, s_pos, _tags = [], has_defalut_tag = true, _has_se = true):
	tileMap = get_tree().get_nodes_in_group("fixed_map")[0]
	
	text_list = texts.replace(" ", "").replace("\n", "").replace("\t", "")
	start_pos = s_pos
	tags = _tags
	if has_defalut_tag:
		tags.append("typed")
	offset = Vector2(0, 0)
	index = 0
	has_released_accept = false
	
	has_se = _has_se


func _physics_process(delta):
	if Global.is_game_pause:
		return
	
	update()

func update():
	while is_running():
		
		if not is_instance_valid(tileMap):
			terminate()
			break
		if update_wait():
			break
		if not execute_command():
			break

func is_running():
	return not not text_list

func update_wait():
	
	if not has_animation:
		return false
		
	


	return update_wait_count()

func update_wait_count():
	if wait_count > 0:
		wait_count -= 1 * type_speed
		return true
	return false

func wait(duration):
	wait_count = duration
	
func execute_command():
	if not is_instance_valid(tileMap):
		terminate()
		return
		
	if not is_h: offset = Vector2(offset.y, offset.x)
	
	var text = current_text()
	if text:
		match text:
			
			"&":
				if not is_h: offset = Vector2(offset.y, offset.x)
				offset.x = 0
				offset.y += 1
				index += 1
			
			"|":
				index += 1
				wait_count = 6
			
			"＿":
				if not is_h: offset = Vector2(offset.y, offset.x)
				offset.x += 1
				index += 1
				wait_count = 6
				play_typing_se()
			"<":
				var label = ""
				var is_label_end = false
				index += 1
				while text_list[index] != ">":
					if text_list[index] == "/":
						is_label_end = true
					else:
						label += text_list[index]
					index += 1
					
				if is_label_end and label in now_labels:
					now_labels.erase(label)
				else:
					now_labels.append(label)
				
				index += 1
				pass
			
			"[":
				
				
				var sp_option_str = ""
				var sp_option
				
				var event_name = ""
				index += 1
				while text_list[index] != "]":
					
					if text_list[index] == "{":
						sp_option_str += text_list[index]
						index += 1
						while text_list[index] != "}":
							if text_list[index] == "'":
								sp_option_str += "\""
							else:
								sp_option_str += text_list[index]
							index += 1
						sp_option_str += "}"
						index += 1
					else:
						event_name += text_list[index]
						index += 1

				
				if sp_option_str:
					var test_json_conv = JSON.new()
					if test_json_conv.parse(sp_option_str) == OK:
						sp_option = test_json_conv.get_data()
				

				var e = tileMap.get_event_by_name(event_name)
				
				if e:
					
					if not tileMap.is_in_bound(e.now_pos) and not (sp_option and sp_option.get("copy", false)):
						if sp_option:
							if sp_option.has("tags"):
								for tag in sp_option.tags:
									e.add_to_group(str(Util.get_value_from_str(tag)))
							if sp_option.get("has_defalut_tag", tags.has("typed")):
								e.add_to_group("typed")
						if tags and not (sp_option and sp_option.has("tags")):
							for tag in tags:
								e.add_to_group(str(Util.get_value_from_str(tag)))
						e.add_to_group("exist_event")
						e.transport_to(start_pos + offset)
						if text_layer != null:
							e.layer = text_layer
						if text_z_index != null:
							e.z_index = text_z_index

						if e.layer == 1:
							push_event_when_overlap("both")
					
					if sp_option and sp_option.get("copy", false):
						var clone = e.duplicate()
						Global.game_map.add_child(clone)

						if sp_option:
							for option in sp_option:
								if option == "name":
									clone.set_event_name(sp_option[option])
								elif option in clone:
									clone[option] = sp_option[option]
								else:
									
									pass
							if sp_option.has("tags"):
								for tag in sp_option.tags:
									clone.add_to_group(str(Util.get_value_from_str(tag)))
							if sp_option.get("has_defalut_tag", tags.has("typed")):
								clone.add_to_group("typed")
						if tags and not (sp_option and sp_option.has("tags")):
							for tag in tags:
								clone.add_to_group(str(Util.get_value_from_str(tag)))

						if clone.is_in_group("exist_event"):
							clone.remove_from_group("exist_event")
						clone.transport_to(start_pos + offset)
						if text_layer != null:
							clone.layer = text_layer
						if text_z_index != null:
							clone.z_index = text_z_index

						clone.init()
						if e.layer == 1:
							push_event_when_overlap("both")
				if not is_h: offset = Vector2(offset.y, offset.x)
				offset.x += 1
				index += 1
				wait_count = 6
				play_typing_se()
			
			"Ｍ":
				var player = get_tree().get_nodes_in_group("player")[0]
				player.transport_to(start_pos + offset)
				
				push_event_when_overlap("event")
				
				if not is_h: offset = Vector2(offset.y, offset.x)
				offset.x += 1
				index += 1
				wait_count = 6
				play_typing_se()
			
			_:
				var e = tileMap.type(text, start_pos + offset, tags, false, custom_path)

				if text_layer != null:
					e.layer = text_layer
				if text_z_index != null:
					e.z_index = text_z_index
				if text_color != null:
					e.text_color = Color(text_color)
					
				
				for label in now_labels:
					if label_settings.has(label):
						var label_setting = label_settings[label]
						for option in label_setting:
							if option == "text_color":
								e.text_color = Color(label_setting[option])
							elif option == "tags":
								for tag in label_setting[option]:
									e.add_to_group(str(Util.get_value_from_str(tag)))
							elif option in e:
								e[option] = label_setting[option]
							else:
								
								pass
				
				index += 1
				if index >= text_list.length():
					e.init()
					if e.layer == 1:
						push_event_when_overlap("both")
					if not is_h: offset = Vector2(offset.y, offset.x)
					offset.x += 1
					wait_count = 6
					play_typing_se()
				else:
					var sp_option_str = ""
					var sp_option
					
					if text_list[index] == "{":
						sp_option_str += text_list[index]
						index += 1
						while text_list[index] != "}":
							if text_list[index] == "'":
								sp_option_str += "\""
							else:
								sp_option_str += text_list[index]
							index += 1
						sp_option_str += "}"
						index += 1
						
						var test_json_conv = JSON.new()
						if test_json_conv.parse(sp_option_str) == OK:
							sp_option = test_json_conv.get_data()
					
					if sp_option:
						for option in sp_option:
							if option == "name":
								e.set_event_name(sp_option[option])
							elif option == "text_color":
								e.text_color = Color(sp_option[option])
							elif option in e:
								e[option] = sp_option[option]
							else:
								
								pass
						
						if sp_option.has("tags"):
							for tag in sp_option.tags:
								e.add_to_group(str(Util.get_value_from_str(tag)))
						if not sp_option.get("has_defalut_tag", tags.has("typed")) and e.is_in_group("typed"):
							e.remove_from_group("typed")
					e.init()
					if e.layer == 1:
						push_event_when_overlap("both")
						
					if not is_h: offset = Vector2(offset.y, offset.x)
					offset.x += 1
					wait_count = 6
					play_typing_se()
		
		

		if (Global.is_in_debug_mode or can_skip) and has_released_accept:
			if Input.is_action_pressed("ui_accept"):
				wait_count = 0
		else:
			if not Input.is_action_pressed("ui_accept"):
				has_released_accept = true
		


	else:
		if not has_animation or not need_accept:
			terminate()
			return
			
		if not wait_for_accept:
			wait_for_accept = true
			push_event_when_overlap("both")
			var accept = type_dialog_end_icon(start_pos + offset)

			if text_layer != null:
				accept.layer = text_layer
			if text_z_index != null:
				accept.z_index = text_z_index
		elif is_accept():
			Sound.play_se("res://Sounds/se/typerwriter_return.wav")

			terminate()
		
		return false
	
	return true

func current_text():
	if index >= text_list.length():
		return false
	return text_list[index]

signal finished
func terminate():
	text_list = ""
	wait_for_accept = false
	if need_accept:
		delete_text_by_tag("dialog-end-icon")
		
	
	Global.game_map.check_rule()

	
	if need_accept and Input.is_action_just_pressed("ui_down"):
		Global.game_map.player.cooldown_count += 10
	
	emit_signal("finished")

func is_accept():
	if wait_for_accept:
		return Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_down")
	return false


func is_just_finish():
	if text_list == "" and index > 0:
		index = 0
		return true
	return false


func play_typing_se():
	if not has_se or not has_animation or (can_skip and has_released_accept and Input.is_action_pressed("ui_accept")) or Input.is_action_pressed("ui_skip"):
		return
		


	var _char_type = char_type
	
	for label in now_labels:
		if label_settings.has(label):
			_char_type = label_settings[label].get("char_type", _char_type)
	
	Sound.play_typing_se(_char_type)


func push_event_when_overlap(type = "both"):
	if not tileMap.is_in_group("fixed_map"):
		var targets = []
		if type == "both":

			var overlap_events = tileMap.get_events_by_pos(start_pos + offset)
			
			
			overlap_events.pop_back()
			
			for overlap_event in overlap_events:
				if overlap_event and overlap_event.can_push:
					targets.append(overlap_event)
			if tileMap.player.is_at_pos(start_pos + offset):
				targets.append(tileMap.player)

		if type == "event":
			var overlap_event = tileMap.get_event_by_pos(start_pos + offset)
			if overlap_event and overlap_event.can_push:
				targets.append(overlap_event)
		if type == "player":
			if tileMap.player.is_at_pos(start_pos + offset):
				targets.append(tileMap.player)
		
		for p in targets:
			p.been_squeezed_when_overlap()
			








	



















		
	












	
















	
	
func delete_text_by_tag(tag = "typed"):
	if not tag:
		tag = "typed"
		
	tag = str(Util.get_value_from_str(tag))
	
	for text in get_tree().get_nodes_in_group(tag):
		var condition = true
		
		for text_tag in text.get_groups():
			if text_tag.find("is_in_sentence:") != - 1:
				var condition_text = text_tag.split("is_in_sentence:")[1].strip_edges()
				condition = Global.get_game_switch(condition_text)
		if condition:
			if text.can_push and Global.game_map.player.is_pull_locking_event:
				if Global.game_map.player.pulling_event.get_instance_id() == text.get_instance_id():
					Global.game_map.player.unlock_pulling_event()
			text.find_parent("*Map").delete_event_by_id(text.get_instance_id())
		else:
			print(text.text, " isn't in sentence, can't erase it.")

	await get_tree().process_frame
	
	if is_instance_valid(Global.game_map):
		Global.game_map.check_rule()
	
func type_dialog_end_icon(pos):
	var event
	if is_dialog_end:
		event = load("res://Scenes/Events/DialogEndIcon.tscn").instantiate()
		event.text = "▼"
	else:
		event = load("res://Scenes/Events/DialogContinueIcon.tscn").instantiate()
		event.text = "▽"
	
	event.position = tileMap.map_to_local(pos)
	event.add_to_group("generated_in_runtime")
	tileMap.add_child(event)
	event.init()
	return event
