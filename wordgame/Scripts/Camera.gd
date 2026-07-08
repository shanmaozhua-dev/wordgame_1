extends Camera2D

var player
var tileMap

var is_snapping = false
var need_snapping_animation = true

var start_interpolate_pos = Vector2()
var moving_frame_count = 0

var is_ready = false

var is_follow_player = true
var pan_offset = Vector2(0, 0)
var follow_player_offset = Vector2(0, 0)

var is_lock_h = false
var is_lock_v = false





func init():
	set_as_top_level(true)
	
	tileMap = get_tree().get_nodes_in_group("map")[0]
	player = $".."
	
	check_camera_grid_snapping()
	is_snapping = false
	
	update_position()
	
	is_ready = true
	

func _physics_process(delta):
	if not is_ready:
		return
		
	if is_follow_player:
		check_camera_grid_snapping()
		update_position()
	
	if is_shaking:
		update_shake()
	

	Sound.se_center_follow_camera(global_position)
	
func update_position():
	var bound_center = get_follow_player_position()
	
	if is_lock_h:
		bound_center.x = position.x
	if is_lock_v:
		bound_center.y = position.y
	
	if is_snapping and need_snapping_animation:

		var total_moving_frame = 300
		var moved_percent = float(moving_frame_count) / total_moving_frame
		moved_percent = ease(moved_percent, 0.2)

		

		var moving_pos = start_interpolate_pos.lerp(bound_center, moved_percent)
		
		position = moving_pos
		
		moving_frame_count += 1
		
		if moving_frame_count > total_moving_frame:
			moving_frame_count = 0
			print("snapping end")
			is_snapping = false
	else:
		position = bound_center
		is_snapping = false
		
	position += pan_offset

func check_camera_grid_snapping():
	
	if tileMap.is_camera_grid_snapping and not tileMap.grid_snapping_bound.has_point(player.now_pos):

		
		
		
		
		
		
		
		

		
		
		
		
		
		



		var new_grid_snapping_bound = Rect2(tileMap.grid_snapping_bound.position, tileMap.grid_snapping_bound.size)

		while not new_grid_snapping_bound.has_point(Vector2(player.now_pos.x, new_grid_snapping_bound.position.y)):
			if new_grid_snapping_bound.end.x <= player.now_pos.x:
				new_grid_snapping_bound.position.x += tileMap.grid_snapping_bound.size.x
			else:
				new_grid_snapping_bound.position.x -= tileMap.grid_snapping_bound.size.x

		while not new_grid_snapping_bound.has_point(Vector2(new_grid_snapping_bound.position.x, player.now_pos.y)):
			if new_grid_snapping_bound.end.y <= player.now_pos.y:
				new_grid_snapping_bound.position.y += tileMap.grid_snapping_bound.size.y
			else:
				new_grid_snapping_bound.position.y -= tileMap.grid_snapping_bound.size.y



		
		
		
		
		
		
		
			
		



		
		if tileMap.grid_snapping_bound.position != new_grid_snapping_bound.position:
			if is_snapping:
				reset_snapping()
			is_snapping = true
			print("snapping start: ", new_grid_snapping_bound.position)
			tileMap.grid_snapping_bound.position = new_grid_snapping_bound.position
			

			start_interpolate_pos = position - pan_offset

func reset_snapping():
	moving_frame_count = 0

func adjust_camera_to_be_in_bound(camera_bound, map_bound):
	if camera_bound.position.x < map_bound.position.x:
		camera_bound.position.x = map_bound.position.x
	if camera_bound.end.x > map_bound.end.x:
		camera_bound.position.x -= camera_bound.end.x - map_bound.end.x
	if camera_bound.position.y < map_bound.position.y:
		camera_bound.position.y = map_bound.position.y
	if camera_bound.end.y > map_bound.end.y:
		camera_bound.position.y -= camera_bound.end.y - map_bound.end.y
		
	return camera_bound

var now_shake_frame = 0.0
var total_shake_frame = 0.0
var is_shaking = false
var shake_range = Vector2(50, 0)
func shake(tf, offset_x = 50, offset_y = 0):
	total_shake_frame = tf
	now_shake_frame = 0.0
	shake_range.x = offset_x
	shake_range.y = offset_y
	is_shaking = true

var is_constant_shake = false
var shake_freq = 1
var shake_depth = 5
func constant_shake(f = 1, d = 5):
	shake_freq = f
	shake_depth = d
	now_shake_frame = 0.0
	is_constant_shake = true
	is_shaking = true

func stop_constant_shake():
	is_shaking = false
	
func update_shake():
	if not is_constant_shake:
		var shake_offset = shake_range * sin(now_shake_frame) * (total_shake_frame - now_shake_frame) / total_shake_frame
		offset = shake_offset
		now_shake_frame += 1
		if now_shake_frame > total_shake_frame:
			is_shaking = false
	else:
		var shake_offset = shake_depth * sin(now_shake_frame * shake_freq)
		offset.x = shake_offset
		offset.y = shake_offset * 0.2
		now_shake_frame += 1
	

func lock_to_player(switch):
	if switch:
		var diff = position - player.position
		position = diff
		set_as_top_level(false)
		is_follow_player = false
	else:
		position = global_position
		set_as_top_level(true)
		is_follow_player = true

func get_top_left_position_of_map():
	var p = position - Vector2(1920 / 2, 1080 / 2)
	p.x = floor(p.x / 60)
	p.y = floor(p.y / 60)
	return p


func get_follow_player_position():
	var ww = 32 * tileMap.get_cell_size().x
	var wh = 18 * tileMap.get_cell_size().y
	
	var camera_bound = Rect2(player.position.x - ww / 2, player.position.y - wh / 2, ww, wh)
	camera_bound.position += follow_player_offset
	
	var map_bound
	if tileMap.is_camera_grid_snapping:
		var bound = tileMap.grid_snapping_bound
		
		if not tileMap.bound.encloses(bound):
			if tileMap.bound.position.x > bound.position.x:
				bound.position.x = tileMap.bound.position.x
			if tileMap.bound.end.x < bound.end.x:
				bound.size.x -= bound.end.x - tileMap.bound.end.x
			if tileMap.bound.position.y > bound.position.y:
				bound.position.y = tileMap.bound.position.y
			if tileMap.bound.end.y < bound.end.y:
				bound.position.y = tileMap.bound.end.y - bound.size.y
		
		map_bound = Rect2(bound.position.x * tileMap.get_cell_size().x, bound.position.y * tileMap.get_cell_size().y, bound.size.x * tileMap.get_cell_size().x, bound.size.y * tileMap.get_cell_size().y)
	else:
		map_bound = Rect2(tileMap.bound.position.x * tileMap.get_cell_size().x, tileMap.bound.position.y * tileMap.get_cell_size().y, tileMap.bound.size.x * tileMap.get_cell_size().x, tileMap.bound.size.y * tileMap.get_cell_size().y)
	
	var adjusted_camera_bound = adjust_camera_to_be_in_bound(camera_bound, map_bound)
	var bound_center = Vector2(adjusted_camera_bound.position.x + adjusted_camera_bound.size.x / 2, adjusted_camera_bound.position.y + adjusted_camera_bound.size.y / 2)
	
	return bound_center
