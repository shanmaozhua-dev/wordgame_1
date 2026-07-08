extends Node2D

var distance = 7
var speed = 2
var interval = 0.3

var follow_duration = 0.8

var seg_x = [0, 0, 0, 0, 0, 0, 0, 0, 0]

var time = 0;

var target_x = 0

var is_ready = false
var is_showing_up = false
var showing_offset = 640
var is_chasing = false
var is_following_target = false

var is_pause = false
func _ready():
	for i in range(1, 9):
		seg_x[i] = position.x
		get_node("CollisionShape2D" + str(i)).disabled = true
	
	if Global.get_game_switch("ch2_蛇妖出現"):
		quick_show()
	
	return

func show_snake():
	visible = true
	is_showing_up = true
	self.monitoring = true
	for i in range(1, 9):
		get_node("CollisionShape2D" + str(i)).disabled = false
	
	var tween = create_tween()
	tween.tween_property(self, "showing_offset", 0, 4).from(640).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
func quick_show():
	visible = true
	is_showing_up = true
	self.monitoring = true
	is_ready = true
	for i in range(1, 9):
		get_node("CollisionShape2D" + str(i)).disabled = false
	
	showing_offset = 0
	
	await get_tree().create_timer(2).timeout
	
	is_following_target = true
	is_chasing = true

func start_chase():
	is_following_target = true
	is_ready = true
	is_chasing = true
	Global.game_map.player.get_node("Camera3D").is_follow_player = false

func _process(delta):
	
	if EscMenu.is_open: return
	
	if not is_showing_up:
		if Global.get_game_switch("ch2_蛇妖出現"):
			show_snake()
	
	if not is_ready:
		if Global.get_game_switch("ch2_蛇妖開追"):
			start_chase()

	if is_pause: return
	
	time += delta
	
	var chase_speed = 120
	
	var limit = - (26 + 32 * 4 + 21 - 9) * 60
	
	if is_chasing:
		Global.game_map.player.get_node("Camera3D").position.y -= delta * chase_speed
		if Global.game_map.player.get_node("Camera3D").position.y <= limit:
			var diff = Global.game_map.player.get_node("Camera3D").position.y - limit
			Global.game_map.player.get_node("Camera3D").position.y -= diff
	
	position.y = Global.game_map.player.get_node("Camera3D").position.y + 120 + showing_offset
	

	




	
	
	
	target_x = get_viewport().get_mouse_position().x
	
	if Global.game_map != null and Global.game_map.player != null:
		target_x = Global.game_map.player.global_position.x

	follow_target(delta)

	
func follow_target(delta):
	if Global.game_map.player.global_position.y > global_position.y:
		follow_duration = 0.4
	else:
		follow_duration = 0.8
	
	var moved_percent = (delta / follow_duration)
	var moving_pos = Vector2(global_position.x, 0).lerp(Vector2(target_x, 0), moved_percent)
	global_position.x = moving_pos.x
	
	for i in range(1, 9):
		if is_following_target:
			moved_percent = (delta / follow_duration) * ((101.0 - float(i)) / 100.0)
			moving_pos = Vector2(seg_x[i], 0).lerp(Vector2(target_x, 0), moved_percent)
			get_node("body/" + str(i)).global_position.x = moving_pos.x
			seg_x[i] = moving_pos.x
		else:
			get_node("body/" + str(i)).global_position.x = 960
		
		if i > 4:
			get_node("body/" + str(i)).global_position.x += cos(time * speed + interval * i) * distance * (i - 4) * 2
		
		get_node("CollisionShape2D" + str(i)).global_position = get_node("body/" + str(i)).global_position
		





func _on__area_entered(area):
	if area.get_parent().is_in_group("ch2_山丘") or area.get_parent().is_in_group("trigger_event"):
		return
	if area.get_parent().is_in_group("player"):
		
		play_kill_se()
		is_pause = true
		Global.kill_player("被咬死了。")
		return
	if not is_instance_valid(area.get_parent()):
		return
	if "time" in area.get_parent():
		if area.get_parent().time == 0:
			play_crash_se()
			area.get_parent().been_snake_crash()
	else:
		play_crash_se()
		area.get_parent().been_snake_crash()

func play_crash_se():
	var r = "ABCD"[randi() % 4]
	Sound.play_se("res://Sounds/se/第二章 音效/SE_2_12_word_crash_" + r + ".wav", 0)

func play_kill_se():
	Sound.play_se("res://Sounds/se/第二章 音效/SE_2_6_slime_dead_B.wav", 10)
