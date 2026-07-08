extends "BaseCharacter.gd"

const PushAniResourse = preload("res://Scenes/Animations/Push.tscn")
const PullAniResourse = preload("res://Scenes/Animations/Pull.tscn")
const PullLineAniResourse = preload("res://Scenes/Animations/PullLine.tscn")

enum {AUTO, PRESS, TOUCH}

var need_dir_animation = false

var walking_se_threshold = 0

var has_idle_time = 0
var section_playing_time = 0
var section_has_hinted = false

var is_pull_locking_event = false
var pulling_event
var pulling_event_facing




















func on_opacity_set(value):
	super.on_opacity_set(value)
	Global.player_status.opacity = value
	




	

	


func init():
	$Camera3D.init()
	
	set_physics_process(true)


func save_status():
	var status = {
		"name": name, 
		"parent": str(get_parent().get_path()), 
		"pos_x": now_pos.x, 
		"pos_y": now_pos.y, 
		"z_index": z_index, 
		"groups": get_groups(), 
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
		"opacity": opacity
	}
	
	return status


func load_status(status):

	transport_to(Vector2(status["pos_x"], status["pos_y"]))
	
	for group_name in status.groups:
		add_to_group(group_name)
	
	for i in status.keys():
		if i == "name":
			set_name(status[i])
		
		if i == "groups" or i == "parent" or i == "pos_x" or i == "pos_y" or i == "name":
			continue
		self.set(i, status[i])



func on_physics_process(delta):
	
	add_section_playing_time()
	if not section_has_hinted and section_playing_time > 2 * 60 * 60:
		section_has_hinted = true
		UI.show_esc_hint()

	idle_count()



	if has_idle_time == 0:
		UI.hide_esc_hint_after_a_while()
	
	var was_moving = is_moving()
	
	if is_stoping():
		update_stop()
		
	if is_cooldowning():
		cooldown()
		
	move_by_input()
	
	
	if not need_dir_animation:
		need_dir_animation = (InputSystem.input_direction == 0)

	if is_jumping():
		update_jump()
	elif is_moving() and not is_cooldowning():

		update_move()







		
		



	if not is_moving():
		update_not_moving(was_moving)
		
	update_walking_sound()


func _on_player_sprite_animation_finished(ani_name):
	if has_idle_time > 18.3 * 60:
		get_node("Sprite2D/AnimationPlayer").play("idle_B")
	elif has_idle_time > 13.2 * 60:
		get_node("Sprite2D/AnimationPlayer").play("default")
	elif has_idle_time > 10 * 60:
		get_node("Sprite2D/AnimationPlayer").play("idle_A")
	elif not is_moving() and ( not is_cooldowning() or not is_cooldown_by_moving):
		get_node("Sprite2D/AnimationPlayer").play("default")
	else:
		get_node("Sprite2D/AnimationPlayer").play(ani_name)

func move_by_input():
	if Global.player_status.has_push_power and not is_pull_locking_event and InputSystem.is_press_alt():
		check_front_pull_event()
		pass
	
	if is_pull_locking_event and not Input.is_action_pressed("ui_alt") and not Input.is_action_pressed("ui_joy_pull"):
		unlock_pulling_event()
	
			
	if Global.get_game_switch("落下中"):
		if InputSystem.input_direction > 0:
			set_direction(InputSystem.input_direction)
			cooldown_count = 6
		if not is_cooldowning():
			if InputSystem.is_press_backspace():
				backspace_fail_animation()
		return
	
	
	if not is_moving() and can_move():
		if Global.player_status.has_split_power and InputSystem.is_press_tab():
			split_front_event()
		
		if Global.player_status.has_backspace_power:
			if InputSystem.is_press_backspace():
				backspace_front()
				return
	
	if not is_moving() and not is_cooldowning() and can_move():
		if Global.player_status.has_ctrl_z_power:
			if InputSystem.is_press_ctrlz():
				Global.ctrl_z()
	







				
		if ( not InputSystem.is_lock and InputSystem.is_press_esc() and not EscMenu.is_open and not EscMenu.is_menu_animating()):
			open_esc_menu()

		var input_direction = InputSystem.input_direction
		if input_direction > 0:
			
			if Global.is_in_debug_mode and Input.is_action_pressed("ui_ctrl"):
				set_through(true)
			else:
				set_through(false)
			
			if input_direction == direction or InputSystem.is_direct_change_direction():
				if move_straight(input_direction):
					pulling_move(input_direction)
			else:
				set_direction(input_direction)
				cooldown_count = 6
				is_cooldown_by_moving = false








func update_not_moving(was_moving):
	super.update_not_moving(was_moving)
	
	if was_moving:
		if is_pull_locking_event:
			cooldown_count += 10
			is_cooldown_by_moving = false
		trigger_touch_action()
		
	trigger_action()

func trigger_touch_action():
	if through:
		return
	var event = tileMap.get_event_by_pos(now_pos)
	if event:
		if event.event_trigger_action == TOUCH:
			print("touch ground:", event.name)
			event.start_event("default", now_pos)

signal trigger_event
func trigger_action():
	if can_move() and not Typewriter.is_just_finish():
		if Input.is_action_just_pressed("ui_accept"):
			var x = x_with_direction(now_pos.x, direction)
			var y = y_with_direction(now_pos.y, direction)
			var event = tileMap.get_event_by_pos(Vector2(x, y))
			
			if event and (event.event_trigger_action == PRESS or event.event_trigger_action == TOUCH):
				print("press front:", event.name)
				
				emit_signal("trigger_event", event)
				
				if GA.section_data.has("interactive_count"):
					GA.section_data.interactive_count += 1
					
				event.start_event("default", Vector2(x, y))
		

func set_direction(d):
	play_dir_animation(d)
	direction = d
	
func play_dir_animation(d):
	var dirs = ["down", "left", "right", "up"]
	if need_dir_animation:
		$DirectionArrow/AnimationPlayer.stop(true)
		$DirectionArrow/AnimationPlayer.play(dirs[d / 2 - 1])
		need_dir_animation = false
	elif direction != d:
		$DirectionArrow/AnimationPlayer.stop(true)
		$DirectionArrow/AnimationPlayer.play(dirs[d / 2 - 1])

func can_move():
	if tileMap.is_any_event_running():
		return false
	if is_move_route_forcing:
		return false
	if locked:
		return false
	return true
	

func check_event_trigger_touch(x, y):
	if through:
		return
	
	var event = tileMap.get_event_by_pos(Vector2(x, y))
	if event and event.layer == 1 and event.event_trigger_action == TOUCH:
		print("touch front:", event.name)
		event.start_event("default", Vector2(x, y))


	merge_front_event()
	
	var events = tileMap.get_events_by_pos(Vector2(x, y))
	for e in events:
		if Global.player_status.has_push_power and e.layer == 1 and e.can_push and not is_pull_locking_event:
			
			if e.be_push(direction):
				push_animation()
				
				cooldown_count += 10
				is_cooldown_by_moving = false
				
				if GA.section_data.has("push_attempt_count"):
					GA.section_data.push_attempt_count += 1



func is_dashing():
	return (Input.is_action_pressed("ui_shift") or Input.is_action_pressed("ui_joy_run")) and not is_move_route_forcing


func update_walking_sound():
	if is_moving():
		if walking_se_threshold >= 14:

			walking_se_threshold = 0
	walking_se_threshold += 1

var walking_foot_cycle = false
func play_walking_se():
	var r = randi() % 7 + 1
	var db = - 5
	var pan
	if walking_foot_cycle:
		pan = - 0.3
	else:
		pan = 0.3
	walking_foot_cycle = not walking_foot_cycle
	
	var floor_type = tileMap.floor_type
	
	if get_tree().get_nodes_in_group("walk_se_map"):
		var walk_se_map = get_tree().get_nodes_in_group("walk_se_map")[0]
		var se_index = walk_se_map.get_cellv(now_pos)
		if se_index != - 1:
			floor_type = walk_se_map.walk_se[se_index]
	
	for e in Global.game_map.get_events_by_pos(now_pos):
		for g in e.get_groups():
			if g.find("walk_se:") != - 1:
				floor_type = g.split("walk_se:")[1]
	
	match floor_type:
		"wood":
			r = ["A", "B", "C"][randi() % 3]
			Sound.play_se("res://Sounds/se/walk/WALK_1_2_wood_" + r + ".wav", db, pan)
		"dirt":
			r = ["A", "B", "C"][randi() % 3]
			Sound.play_se("res://Sounds/se/walk/WALK_1_11_dirt_" + r + ".wav", db, pan)
		"pavement":
			r = ["A", "B", "C"][randi() % 3]
			Sound.play_se("res://Sounds/se/walk/WALK_1_14_pavement_" + r + ".wav", db, pan)
		"cave":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_2_19_cave_" + r + ".wav", db, pan)
		"grass":
			r = ["A", "B", "C"][randi() % 3]
			Sound.play_se("res://Sounds/se/walk/WALK_2_2_grass_" + r + ".wav", db, pan)
		"pavement2":
			r = ["A", "B", "C", "D", "E"][randi() % 5]
			Sound.play_se("res://Sounds/se/walk/WALK_2_8_pavement_" + r + ".wav", db, pan)
		"ruin":
			r = ["A", "B", "C"][randi() % 3]
			Sound.play_se("res://Sounds/se/walk/WALK_3_22_ruin_" + r + ".wav", db, pan)
		"marble":
			r = ["A", "B"][randi() % 2]
			Sound.play_se("res://Sounds/se/walk/WALK_3_33_marble_" + r + ".wav", db, pan)
		"snow":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_4_1_snow_little_" + r + ".wav", db, pan)
		"stone":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_4_24_walk_Stone_" + r + ".wav", db, pan)
		"riverside":
			r = ["A", "B", "C", "D", "E", "F", "G", "H"][randi() % 8]
			Sound.play_se("res://Sounds/se/walk/WALK_4_39_riverside_" + r + ".wav", db, pan)
		"goose":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_4_45_goose_" + r + ".wav", db, pan)
		"swim":
			r = ["A", "B", "C", "D", "E"][randi() % 5]
			Sound.play_se("res://Sounds/se/walk/WALK_4_46_goose_swim_" + r + ".wav", db, pan)
		"ruin2":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_4_4_ruin_" + r + ".wav", db, pan)
		"abstract":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_4_9.1_abstract_" + r + ".wav", db, pan)
		"snow_thick":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_5_2_snow_thick_" + r + ".wav", db, pan)
		"stone_stair":
			r = ["A", "B", "C", "D", "E", "F", "G", "H"][randi() % 8]
			Sound.play_se("res://Sounds/se/walk/WALK_5_75_stone_stair_1_" + r + ".wav", db, pan)
		"stone_stair2":
			r = ["A", "B", "C", "D", "E", "F", "G", "H"][randi() % 8]
			Sound.play_se("res://Sounds/se/walk/WALK_5_75_stone_stair_2_" + r + ".wav", db, pan)
		"carpet":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_5_84_carpet_" + r + ".wav", db, pan)
		"garden":
			r = ["A", "B", "C", "D"][randi() % 4]
			Sound.play_se("res://Sounds/se/walk/WALK_5_93_garden_" + r + ".wav", db, pan)
		"dragon_back":
			r = ["A", "B", "C", "D", "E", "F", "G", "H"][randi() % 8]
			Sound.play_se("res://Sounds/se/walk/WALK_4_12_dragon_back_" + r + ".wav", db, pan)
		"no_word":
			r = ["A", "B", "C", "D", "E"][randi() % 5]
			Sound.play_se("res://Sounds/se/typewriter/SE_S_15_type_可能適合princess_輕柔" + r + ".wav", db, pan)
		"default", _:
			r = randi() % 6 + 2
			Sound.play_se("res://Sounds/se/footstep_" + str(r) + ".wav", db, pan)
	
	
func backspace_front():
	var x2 = x_with_direction(now_pos.x, direction)
	var y2 = y_with_direction(now_pos.y, direction)
	
	var event = tileMap.get_event_by_pos(Vector2(x2, y2))
	if event:
		if event.start_event("backspace", Vector2(x2, y2)):
			pass
		elif event.can_delete:
			print("backspace: ", event.name)
			event.been_backspace()
			

			cooldown_count = 90
			is_cooldown_by_moving = false
		else:
			backspace_fail_animation()
		
		if GA.section_data.has("backspace_attempt_count"):
			GA.section_data.backspace_attempt_count += 1
	
func push_animation(has_se = true):
	if has_se:
		play_push_se()
	var push_ani = PushAniResourse.instantiate()
	add_child(push_ani)
	push_ani.get_node("AnimationPlayer").play(str(direction))
	await push_ani.get_node("AnimationPlayer").animation_finished
	push_ani.queue_free()


func play_push_se():
	var r = randi() % 4 + 1
	Sound.play_se("res://Sounds/se/push_low_" + str(r) + ".wav", - 6, 0)

func backspace_fail_animation():
	play_backspace_fail_se()
	cooldown_count = 40
	is_cooldown_by_moving = false

	var fail_ani = load("res://Scenes/Animations/Backspace_fail.tscn").instantiate()
	add_child(fail_ani)
	fail_ani.position = direction_to_vector(direction) * 60 + Vector2(30, 30)
	fail_ani.get_node("AnimationPlayer").play("fail")
	await fail_ani.get_node("AnimationPlayer").animation_finished
	fail_ani.queue_free()

func play_backspace_fail_se():
	var r = randi() % 3 + 1
	Sound.play_se("res://Sounds/se/sword_swing_fail_" + str(r) + ".wav")

func fake_tab():
	Global.set_game_switch("頭盔他分裂", true)
	
func is_idle():
	return can_move() and is_stoping()
	
func idle_count():
	if is_idle():
		has_idle_time += 1

	else:
		has_idle_time = 0

func clear_idle_count():
	has_idle_time = 0

func add_section_playing_time():
	if tileMap.interpreter.is_running():
		return
	if EscMenu.murmur_data.has(Global.now_game_section):
		if EscMenu.murmur_data[Global.now_game_section].get("is_puzzle", false):
			section_playing_time += 1

func clear_section_playing_time():
	section_playing_time = 0
	section_has_hinted = false
	
	
func check_front_pull_event():
	var x2 = x_with_direction(now_pos.x, direction)
	var y2 = y_with_direction(now_pos.y, direction)
	var events = tileMap.get_events_by_pos(Vector2(x2, y2))
	for event in events:
		if event and event.layer == 1 and event.can_push:
			print("lock")
			is_pull_locking_event = true
			pulling_event = event
			pulling_event_facing = 10 - direction
			
			event.been_pull_lock(self, pulling_event_facing)

			return true
	
	Sound.play_se("res://Sounds/se/pull_grab_fail.wav")
		
func unlock_pulling_event():
	is_pull_locking_event = false
	if pulling_event:

		pulling_event.been_pull_unlock(self, pulling_event_facing)
		pulling_event = null
		print("unlock")

func pull_lock_animation():
	var pull_ani
	var big_event_offset = Vector2(0, 0)
	if pulling_event.has_node("Pull"):
		pull_ani = pulling_event.get_node("Pull")
	else:
		pull_ani = PullAniResourse.instantiate()
		pulling_event.add_child(pull_ani)
		pull_ani.position += big_event_offset
		
	var pull_line
	if has_node("PullLine"):
		pull_line = get_node("PullLine")
	else:
		pull_line = PullLineAniResourse.instantiate()
		add_child(pull_line)
	match direction:
		2:
			pull_line.rotation_degrees = 0
			pull_line.position.x = 30
			pull_line.position.y = 60
		4:
			pull_line.rotation_degrees = 90
			pull_line.position.x = 0
			pull_line.position.y = 30
		6:
			pull_line.rotation_degrees = 90
			pull_line.position.x = 60
			pull_line.position.y = 30
		8:
			pull_line.rotation_degrees = 0
			pull_line.position.x = 30
			pull_line.position.y = 0
	
	Sound.play_se("res://Sounds/se/pull_grab.wav")
	pull_ani.get_node("AnimationPlayer").play("lock_" + str(10 - direction))
	pulling_event_facing = 10 - direction
	await pull_ani.get_node("AnimationPlayer").animation_finished
	pull_ani.get_node("AnimationPlayer").play("locking_" + str(pulling_event_facing))
	
func pull_unlock_animation():
	if has_node("PullLine"):
		get_node("PullLine").queue_free()

	Sound.play_se("res://Sounds/se/pull_ungrab.wav", - 10)
	var pull_ani = pulling_event.get_node("Pull")
	if pull_ani:
		pull_ani.get_node("AnimationPlayer").play("unlock_" + str(pulling_event_facing))
		await pull_ani.get_node("AnimationPlayer").animation_finished
		pull_ani.queue_free()


func pulling_move(input_direction):
	if is_pull_locking_event and pulling_event:





		var success = false
		var pull_distence = pulling_event.get_pull_distence(self, pulling_event_facing)
		success = success or (input_direction == 2 and pull_distence.y == - 2)
		success = success or (input_direction == 4 and pull_distence.x == 2)
		success = success or (input_direction == 6 and pull_distence.x == - 2)
		success = success or (input_direction == 8 and pull_distence.y == 2)
		
		success = success and pulling_event.can_pass(pulling_event.now_pos.x, pulling_event.now_pos.y, input_direction)
		
		if success:
			play_pull_se()
			pulling_event.move_straight(input_direction)
			if GA.section_data.has("pull_attempt_count"):
				GA.section_data.pull_attempt_count += 1
		else:
			unlock_pulling_event()
		
		return false
		
func play_pull_se():
	var r = randi() % 4 + 1
	Sound.play_se("res://Sounds/se/pull_" + str(r) + ".wav", - 10, 0)

func _on_Area2D_area_shape_entered(area_id, area, area_shape, self_shape):

	pass


func split_front_event():
	print("split_front_event")
	var pos = now_pos + Util.direction_to_vector(direction)
	var e = Global.game_map.get_event_by_pos(pos)

	if e and e.start_event("split", pos):
		print("split command!")
		return
	
	if e and Global.game_map.can_event_split(e) and e.can_split and e.can_be_split():
		var split_events = Global.game_map.get_splitted_events(e, pos)
		e.been_split(direction, split_events)
		
		
		if not is_moving():
			lock_input_a_while(0.5)

		else:
			print("player been push")
			lock_input_a_while(0.5)
	elif e:
		split_fail_animation()
	pass

func merge_front_event():

	var front_pos = now_pos + Util.direction_to_vector(direction)
	var next_pos = front_pos + Util.direction_to_vector(direction)
	var front_event = Global.game_map.get_event_by_pos(front_pos)
	var next_event = Global.game_map.get_event_by_pos(next_pos)
	
	if not front_event or not next_event: return
	
	if Global.game_map.can_event_merge(front_event, next_event):
		var merged_event = Global.game_map.get_merged_events(front_event, next_event, next_pos)




		merge_push_animation()
		front_event.been_merge(direction, next_event, merged_event)

		lock_input_a_while(1.5)
		return true

func lock_input_a_while(time):
	InputSystem.lock()
	await get_tree().create_timer(time).timeout
	InputSystem.unlock()

func merge_push_animation():
	await get_tree().create_timer(0.2).timeout
	push_animation(false)

func split_fail_animation():
	Sound.play_se("res://Sounds/se/power/SE_S_19.3_pull_fail.wav")
	cooldown_count = 40
	is_cooldown_by_moving = false

	var fail_ani = load("res://Scenes/Animations/Unzip_fail.tscn").instantiate()
	add_child(fail_ani)
	fail_ani.position = direction_to_vector(direction) * 60
	fail_ani.get_node("AnimationPlayer").play("fail")
	await fail_ani.get_node("AnimationPlayer").animation_finished
	fail_ani.queue_free()


func open_esc_menu():
	EscMenu.open_menu()





func move_straight(d):
	var walk_ani = get_node("Sprite2D/AnimationPlayer")
	if is_dashing():
		match int(Global.settings.skin):
			0:
				if walk_ani.current_animation != "walk":
					walk_ani.play("walk")
			1:
				if d in [2, 4]:
					if walk_ani.current_animation != "cartoon_run_24":
						walk_ani.play("cartoon_run_24")
				else:
					if walk_ani.current_animation != "cartoon_run_68":
						walk_ani.play("cartoon_run_68")
			2:
				if d in [2, 4]:
					if walk_ani.current_animation != "longleg_run_24":
						walk_ani.play("longleg_run_24")
				else:
					if walk_ani.current_animation != "longleg_run_68":
						walk_ani.play("longleg_run_68")
	else:
		if walk_ani.current_animation != "walk":
			walk_ani.play("walk")

	var is_success = super.move_straight(d)
	return is_success
