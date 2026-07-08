extends Node2D

signal finished

func set_animation(player: AnimationPlayer, animation_name: String, animation: Animation):
	var library: AnimationLibrary
	if player.has_animation_library(""):
		library = player.get_animation_library("")
	else:
		library = AnimationLibrary.new()
		player.add_animation_library("", library)
	if library.has_animation(animation_name):
		library.remove_animation(animation_name)
	library.add_animation(animation_name, animation)

func play(text_count, is_h = true, sentence_width = null, progress = 0, level = 5):
	if sentence_width == null:
		sentence_width = text_count
	
	var thickness = ceil(float(text_count) / sentence_width)
	
	if is_h:
		$"t".position = Vector2(sentence_width * 30, 0)
		$"t".scale.x = sentence_width * 60 / 1920.0
		$"b".position = Vector2(sentence_width * 30, thickness * 60)
		$"b".scale.x = sentence_width * 60 / 1920.0
		$"l".position = Vector2(0, thickness * 30)
		$"l".scale.x = thickness * 60 / 1920.0
		$"r".position = Vector2(sentence_width * 60, thickness * 30)
		$"r".scale.x = thickness * 60 / 1920.0
		$"c".position = Vector2(sentence_width * 30, thickness * 30)
		$"c".scale.x = sentence_width * 60 / 1920.0
		$"c".scale.y = thickness * 15
	else:
		$"t".position = Vector2(thickness * 30, 0)
		$"t".scale.x = thickness * 60 / 1920.0
		$"b".position = Vector2(thickness * 30, sentence_width * 60)
		$"b".scale.x = thickness * 60 / 1920.0
		$"l".position = Vector2(0, sentence_width * 30)
		$"l".scale.x = sentence_width * 60 / 1920.0
		$"r".position = Vector2(thickness * 60, sentence_width * 30)
		$"r".scale.x = sentence_width * 60 / 1920.0
		
		$"c".rotation_degrees = 90
		$"c".position = Vector2(thickness * 30, sentence_width * 30)
		$"c".scale.x = sentence_width * 60 / 1920.0
		$"c".scale.y = thickness * 15
	
	
	set_animation($"AnimationPlayer", "legal_d", $"AnimationPlayer".get_animation("legal").duplicate())
	
	for i in range(text_count):
		var light = load("res://Scenes/Animations/Light.tscn").instantiate()
		add_child(light)
		
		var col = i % int(sentence_width)
		var row = floor(i / sentence_width)
		
		if is_h:
			light.position.x += 60 * col
			light.position.y += 60 * row
		else:
			light.position.y += 60 * col
			light.position.x += 60 * row
		
		var track_index = $"AnimationPlayer".get_animation("legal_d").add_track(Animation.TYPE_ANIMATION)
		$"AnimationPlayer".get_animation("legal_d").track_set_path(track_index, light.name + "/AnimationPlayer")
		$"AnimationPlayer".get_animation("legal_d").animation_track_insert_key(track_index, 0.0, "light_up")
	
	if level == 5:
		var track_index = $"AnimationPlayer".get_animation("legal_d").add_track(Animation.TYPE_ANIMATION)
		$"AnimationPlayer".get_animation("legal_d").track_set_path(track_index, "CanvasLayer/ColorRect/AnimationPlayer")
		$"AnimationPlayer".get_animation("legal_d").animation_track_insert_key(track_index, 0.3, "light_up")
	
	if progress != - 1:
		Sound.fade_bgm(1, - 15)
	
	$"AnimationPlayer".play("legal_d")
	
	if progress == 0:
		Sound.play_se("res://Sounds/se/complete.wav")
	elif progress != - 1:
		Sound.play_se("res://Sounds/se/progress_" + str(progress) + ".wav")
	
	await $"AnimationPlayer".animation_finished
	
	if progress != - 1:
		Sound.fade_bgm(2, 0)
	
	emit_signal("finished")
