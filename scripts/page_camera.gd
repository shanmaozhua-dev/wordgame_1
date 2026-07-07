extends RefCounted

var cell_size := 60
var page_origin := Vector2i.ZERO

func sync_to_world(world: RefCounted) -> bool:
	if page_origin == world.current_page_origin:
		return false
	page_origin = world.current_page_origin
	return true

func offset_pixels() -> Vector2:
	return Vector2(-page_origin.x * cell_size, -page_origin.y * cell_size)
