@tool
extends "res://Scripts/Event.gd"

@export var is_tofu = false: set = on_is_tofu_set


var char_type = 0

func _ready():
	$erase_tofu.material = $erase_tofu.material.duplicate()
	char_type = randi() % 3
	user_data.org_pos = now_pos

func on_is_tofu_set(new_value):
	is_tofu = new_value
	$WordSprite.is_tofu = is_tofu



func on_player_enter_reveal_area(area):
	if not existing: return
	if area.get_parent().name != "Player": return
	if not Global.get_game_self_switch(name, "is_unfreeze"): return
	if Global.get_game_self_switch(name, "ready"): return
	print("on_player_enter_reveal_area:", name)
	Global.set_game_self_switch(name, "ready", true)
	await notice()
	transform_to_text()


signal transform_to_text_finished
func transform_to_text():
	Sound.play_se("res://Sounds/se/第七章 音效/SE_4_20_word_reveal.wav", - 6)
	$erase_tofu.modulate = text_color
	$transform.play("transform")
	await $transform.animation_finished
	emit_signal("transform_to_text_finished")


signal notice_finished
func notice():
	var target_pos
	for d in [8, 6, 4, 2]:
		target_pos = now_pos + Util.direction_to_vector(d)
		if not Global.game_map.player.is_at_pos(target_pos) and not Global.game_map.get_event_by_pos(target_pos) and Global.game_map.is_in_bound(target_pos):
			break
	
	var pos = (target_pos - now_pos) * 60
		
	$notice.position = pos
	$notice/WordSprite.text_color = text_color
	
	$WordSprite/movement.play("Setup")
	$notice/AnimationPlayer.play("Hop")
	
	await $notice/AnimationPlayer.animation_finished
	emit_signal("notice_finished")


func start_shake():
	$shake.play("shake")

func stop_shake():
	$shake.play("stop")


signal escape_finished
func escape(location):
	cooldown_count = 0
	notice()
	var route = [
		{"command": "jump"}, 
		{"command": "wait", "parameters": 30}, 
		{"command": "move_to_point", "parameters": [location.x, location.y]}
	]
	force_move_route(route)
	print("force_move_route")
	await self.force_move_route_finished
	start_shake()
	Global.set_game_self_switch(name, "shaking", true)
	
	emit_signal("escape_finished")









func process_move_command(command):
	super.process_move_command(command)
	

	
	if command["command"] == "idle":
		var ani_name = ["Furie", "Hoppie", "Sloppie"][char_type]
		$WordSprite/movement.play(ani_name)

func before_follow():
	var ani_name = ["Furie", "Hoppie", "Sloppie"][char_type] + "Join"
	$WordSprite/movement.play(ani_name)



func update_self_movement():
	if is_in_group("tofu_guard_event"):
		if loop_move_route and not locked:
			update_routine_move()
	else:
		if loop_move_route and not locked and is_in_screen():
			update_routine_move()

func check_event_trigger_touch(x, y):
	if event_trigger_action == EVENT_TRIGGER_ACTION_TYPES.TOUCH:
		var p = tileMap.player
		if p.is_at_pos(Vector2(x, y)):
			start_event()
		elif is_in_group("tofu_guard_event"):
			var event = tileMap.get_event_by_pos(Vector2(x, y))
			if event and event.is_in_group("tofu_text_event") and event in p.followers:
				start_event()
	
	super.check_event_trigger_touch(x, y)

func move_straight(d):
	super.move_straight(d)
	
	if is_in_group("tofu_guard_event"):
		move_speed = - 1
		step(0.5)


func step(t = 0.3):
	var tw = create_tween()
	tw.set_parallel(true)
	var offsety = get_node("WordSprite")
	
	tw.tween_property(offsety, "position:y", 15, t * 0.75).from(30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(offsety, "position:y", 30, t * 0.25).from(15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).set_delay(t * 0.75)
	
	await tw.finished

func unfreeze(color = Color(1, 1, 1, 1)):
	var ice_parent = get_node("ice")
	var ice = ice_parent.get_child(0)
	ice_parent.visible = true
	
	ice.material = ice.material.duplicate()
	var tw = create_tween()
	tw.set_parallel(true)
	
	tw.tween_property(self, "text_color", color, 1).from(Color(1, 1, 1, 1)).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tw.tween_method(
		func(value): ice.get_material().set_shader_parameter("t", value),
		1,
		0,
		1
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	
	await tw.finished
	ice_parent.visible = false


func refresh_status():
	var is_unfreeze = Global.get_game_self_switch(self.name, "is_unfreeze")
	var is_ready = Global.get_game_self_switch(self.name, "ready")
	var is_done = Global.get_game_self_switch(self.name, "done")
	var is_shaking = Global.get_game_self_switch(self.name, "shaking")
	
	if is_unfreeze:
		text_color = Color(1, 1, 1, 1)
	
	if is_ready:
		is_tofu = false
		
	if is_done:
		Global.set_game_self_switch(self.name, "done", false)
	
	if is_shaking:
		Global.set_game_self_switch(self.name, "shaking", false)
		stop_shake()
		
	if user_data.get("org_loop_move_route"):
		loop_move_route = user_data.org_loop_move_route
	if user_data.get("org_move_zone"):
		move_zone = user_data.org_move_zone
		
	if loop_move_route:
		var route_list = raw_code_to_json_command(loop_move_route)
		if route_list and route_list.size() > 0:
			set_move_route(route_list)
	
	self.opacity = 1
	
	transport_to(org_pos)
	
	pass
