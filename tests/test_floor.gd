extends SceneTree
## Checks the wooden floor covers the whole screen with the plain planks block, drawn beneath everything else.

var _failures: PackedStringArray = []


func _initialize() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var floor_layer: TileMapLayer = main.get_node("Floor")
	_check(floor_layer.get_index() == 0, "floor is drawn beneath the rest of the scene")
	var size := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	_check(size == Vector2i(1920, 1080), "project viewport is 1920x1080 (got %s)" % size)

	_check(floor_layer.tile_set.tile_size == Vector2i(32, 32), "floor tiles are 32 px, like the sheet's grid")
	var viewport := floor_layer.get_viewport()
	var screen := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var first := floor_layer.local_to_map(floor_layer.to_local(screen.position))
	var last := floor_layer.local_to_map(floor_layer.to_local(screen.end))
	var planks: Vector2i = floor_layer.PLANKS
	var covered := true
	var only_planks := true
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			var cell := Vector2i(x, y)
			if floor_layer.get_cell_source_id(cell) == -1:
				covered = false
				continue
			var offset := floor_layer.get_cell_atlas_coords(cell) - planks
			if offset.x < 0 or offset.x > 1 or offset.y < 0 or offset.y > 1:
				only_planks = false
	_check(covered, "every cell on screen is paved (%d x %d cells)" % [last.x - first.x + 1, last.y - first.y + 1])
	_check(only_planks, "the floor only uses the plain planks tiles")
	_finish()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
