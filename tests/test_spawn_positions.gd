extends SceneTree
## Checks enemies spawn just outside the screen, on every side rather than only the top,
## and that a wave's groups spawn bunched together.

const SAMPLES := 400

var _failures: PackedStringArray = []


func _initialize() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	var spawner: Node2D = main.get_node("EnemySpawner")
	var viewport := spawner.get_viewport()
	var screen := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var border: Rect2 = screen.grow(spawner.spawn_margin)
	var sides := {"top": 0, "bottom": 0, "left": 0, "right": 0}
	var all_on_border := true
	for i in SAMPLES:
		var p: Vector2 = spawner._random_point_on_border(border)
		if is_equal_approx(p.y, border.position.y):
			sides.top += 1
		elif is_equal_approx(p.y, border.end.y):
			sides.bottom += 1
		elif is_equal_approx(p.x, border.position.x):
			sides.left += 1
		elif is_equal_approx(p.x, border.end.x):
			sides.right += 1
		else:
			all_on_border = false
		if screen.has_point(p):
			all_on_border = false
	_check(all_on_border, "every spawn point lies on the border outside the screen")
	for side: String in sides:
		_check(sides[side] > SAMPLES / 10, "enemies spawn on the %s side (got %d/%d)" % [side, sides[side], SAMPLES])

	var wave := Wave.new()
	var group_off_screen := true
	var widest := 0.0
	for i in 20:
		var before := spawner.get_child_count()
		spawner._spawn_group(wave, 10)
		var group := spawner.get_children().slice(before)
		for enemy: Node2D in group:
			group_off_screen = group_off_screen and not screen.has_point(enemy.position)
			for other: Node2D in group:
				widest = maxf(widest, enemy.position.distance_to(other.position))
		for enemy: Node in group:
			enemy.free()
	_check(group_off_screen, "every enemy of a group spawns outside the screen")
	var max_width: float = 3.0 * spawner.group_spread
	_check(widest <= max_width, "a group spawns bunched together (widest %.0f px, max %.0f)" % [widest, max_width])
	_finish()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
