class_name BaseMap
extends Node2D


func get_cell_size() -> Vector2i:
	var tile_map := _find_tile_map(self)
	if tile_map and tile_map.tile_set:
		return tile_map.tile_set.tile_size
	return GameConfigRules.CELL_SIZE


func cell_to_screen(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Vector2(get_cell_size())


func screen_to_cell(screen_position: Vector2) -> Vector2i:
	var size := get_cell_size()
	return Vector2i(floori(screen_position.x / size.x), floori(screen_position.y / size.y))


func _find_tile_map(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node

	for child in node.get_children():
		var result := _find_tile_map(child)
		if result:
			return result

	return null
