
extends Node2D

@export var opacity: float = 0.1


func _draw():
	if get_tree().get_nodes_in_group("map")[0].draw_debug_grid:
		for x in range(19200 / 60):
			draw_line(Vector2(x * 60, - 5400), Vector2(x * 60, 5400), Color(1, 1, 1, opacity), 2)
		for y in range(10800 / 60):
			draw_line(Vector2( - 9600, y * 60), Vector2(9600, y * 60), Color(1, 1, 1, opacity), 2)
		
