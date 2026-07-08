extends Node2D


var effects_to_draw = []


func _physics_process(delta):
	queue_redraw()

func clear_effect():
	effects_to_draw = []

func _draw():
	for effect in effects_to_draw:
		match effect.name:
			"hint":
				var lt = effect.range.position
				var lb = lt + Vector2(0, effect.range.size.y)
				var rt = lt + Vector2(effect.range.size.x, 0)
				var rb = effect.range.end
				draw_line(lt, rt, Color.WHITE, 4)
				draw_line(lt, lb, Color.WHITE, 4)
				draw_line(lb, rb, Color.WHITE, 4)
				draw_line(rt, rb, Color.WHITE, 4)
			"done":
				var lt = effect.range.position
				var lb = lt + Vector2(0, effect.range.size.y)
				var rt = lt + Vector2(effect.range.size.x, 0)
				var rb = effect.range.end
				draw_line(lt, rt, Color.YELLOW, 4)
				draw_line(lt, lb, Color.YELLOW, 4)
				draw_line(lb, rb, Color.YELLOW, 4)
				draw_line(rt, rb, Color.YELLOW, 4)
				
				
				
	pass
