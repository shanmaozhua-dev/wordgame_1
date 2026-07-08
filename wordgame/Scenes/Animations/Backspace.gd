extends Sprite2D






func _ready():
	pass

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






func _on_Backspace_tree_entered():

	
	
	var degree = randi() % 50 + 20
	
	var word = get_parent().get_node("WordSprite")
	
	word.draw_text_to_sprite()
	await word.draw_text_to_sprite_complete
	
	var mat = ShaderMaterial.new()
	mat.set_shader(load("res://Shader/cut2.gdshader"))
	word.set_material(mat)
	
	word.material.set_shader_parameter("degree", degree)
	rotation_degrees = degree
	
	var animation = Animation.new()
	animation.length = 1.15
	
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	
	animation.track_set_path(track_index, ".:frame")
	
	animation.track_insert_key(track_index, 0, 0)
	animation.track_insert_key(track_index, 0.5, 17)
	
	track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, "../WordSprite:material:shader_parameter/time")
	
	animation.track_insert_key(track_index, 0, 0.0)
	animation.track_insert_key(track_index, 0.44, 0, 0.23)
	animation.track_insert_key(track_index, 1.15, 1.0)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)

	set_animation($AnimationPlayer, "backspace_animation", animation)
	$AnimationPlayer.current_animation = "backspace_animation"
	
	$AnimationPlayer.play()
	play_backspace_se()
	
	await $AnimationPlayer.animation_finished
	
	queue_free()

	pass
	
func play_backspace_se():
	var r = randi() % 3 + 1
	Sound.play_se("res://Sounds/se/sword_swing_" + str(r) + ".wav")
