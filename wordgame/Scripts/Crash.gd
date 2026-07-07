@tool

extends Node2D

@export var texture: Texture2D: get = get_texture, set = set_texture
@export var resolution = 4: get = get_resolution, set = set_resolution
@export var period = 1: set = set_period
@export var debug_draw = false: set = set_debug_draw
@export var time = 0.0: set = set_time
@export var rotate = 0: set = set_rotates
@export var active = true: set = set_active



var noise = FastNoiseLite.new()

var order = []

func _ready():
	set_rand()

func get_texture():
	return texture

func set_texture(tex):
	texture = tex
	queue_redraw()
	
func set_active(v):
	active = v
	
	set_rand()
	queue_redraw()

func set_rand():





	
	randomize()
	noise.seed = randi()
	noise.fractal_octaves = 1
	noise.fractal_gain = 0.5

func set_period(v):
	period = v
	noise.frequency = 1.0 / max(float(v), 0.001)
	queue_redraw()

func set_time(v):
	time = v
	queue_redraw()

func get_resolution():
	return resolution

func set_resolution(res):
	if res < 1 or res > 64:
		return
	resolution = res
	set_rand()
	queue_redraw()


func set_debug_draw(dd):
	debug_draw = dd
	queue_redraw()
	
func set_rotates(v):
	rotate = v
	queue_redraw()


func _draw():
	if texture == null:
		return
	var tex_size = texture.get_size()
	var div_size = tex_size / Vector2(resolution, resolution)

	draw_set_transform( - tex_size / 2.0, 0.0, Vector2(1, 1))

	for y in range(resolution - 1, - 1, - 1):
		for x in range(0, resolution):
			var pos = Vector2(x, y)
			var r = Rect2(pos * div_size, div_size)
			var dist_to_bottom = (resolution - 1 - y) * - div_size.y;
			
			var p_t = float(resolution - 1 - y) / (resolution - 1)
			
			var noise_x = noise.get_noise_1d(x) * resolution + resolution / 2.0
			var noise_y = noise.get_noise_1d(y) * resolution + resolution / 2.0
			var noise_rotation = noise.get_noise_2d(x, y) * 360 + 180
			

			var seed_sign = 1.0 if int(hash(str(x) + ":" + str(y))) % 2 == 0 else -1.0
			var move_x = seed_sign * div_size.x * 1.0 * p_t * noise_y / 10.0
			
			var diff = Vector2(move_x, dist_to_bottom)
			

			var start_time = noise_x / (resolution - 1) * 0.1
			

			
			
			
			
			var end_time = start_time * 3 + 0.5

			
			var percent = (max(0.0, time - start_time)) / float(end_time - start_time)
			percent = ease(percent, 2)
			

			percent = min(percent, 1.0 - (noise_x / resolution / 8.0))

			var s_r = Rect2(pos * div_size - diff * percent, div_size)
			

			
			var length = pow(pow(30, 2) + pow(30, 2), 0.5)

			var v = Vector2(30, 30) + div_size / 2
			var delta = (rotate) * (PI / 180)
			var ro_x = v.x * cos(delta) - v.y * sin(delta)
			var ro_y = v.x * sin(delta) + v.y * cos(delta)
			var ro = Vector2(ro_x, ro_y) + div_size / 2



			noise_rotation = rotate


















				
				
				
			draw_texture_rect_region(texture, s_r, r)
			
			if debug_draw and Engine.is_editor_hint():
				stroke_rect(s_r, Color(1, 1, 0, 0.5))


func stroke_rect(r, c):
	draw_line(r.position, Vector2(r.end.x, r.position.y), c)
	draw_line(r.position, Vector2(r.position.x, r.end.y), c)
	draw_line(r.end, Vector2(r.end.x, r.position.y), c)
	draw_line(r.end, Vector2(r.position.x, r.end.y), c)


func _on_AnimationPlayer_animation_started(anim_name):
	set_rand()
	pass
