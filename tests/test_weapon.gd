extends SceneTree
## Checks the weapon holds fire with no enemy in range, then aims and fires at the closest one.

const PlayerScene := preload("res://scenes/player/player.tscn")
const EnemyScene := preload("res://scenes/enemy/enemy.tscn")

var _failures: PackedStringArray = []


func _initialize() -> void:
	var world := Node2D.new()
	root.add_child(world)
	current_scene = world
	var player: Node2D = PlayerScene.instantiate()
	player.speed = 0.0
	player.position = Vector2(500, 500)
	world.add_child(player)
	var weapon: Node2D = player.get_node("Weapon")
	var detection_range: float = weapon.detection_range

	var far := _spawn_enemy(world, player.position + Vector2(detection_range + 100, 0))
	await create_timer(0.5, false).timeout
	_check(_bullets(world).is_empty(), "no shot while the only enemy is out of range")

	var near := _spawn_enemy(world, player.position + Vector2(-150, 150))
	_spawn_enemy(world, player.position + Vector2(0, -250))
	var expected := player.global_position.direction_to(near.global_position)
	# Starts pointing up (dot ~ -0.7); a snap would jump straight to ~1 in one frame.
	var steps := 0
	for i in 60:
		await process_frame
		var dot := Vector2.UP.rotated(weapon.global_rotation).dot(expected)
		if dot > -0.6 and dot < 0.95:
			steps += 1
	_check(steps >= 3, "weapon steers towards the target over several frames (got %d)" % steps)
	await create_timer(0.5, false).timeout
	var aim := Vector2.UP.rotated(weapon.global_rotation)
	_check(aim.dot(expected) > 0.99, "weapon points at the closest enemy (aim %s, expected %s)" % [aim, expected])
	var bullets := _bullets(world)
	_check(not bullets.is_empty(), "weapon fires once an enemy is in range")
	var tolerance: float = cos(deg_to_rad(weapon.aim_tolerance))
	var all_towards_near := bullets.all(func(b: Node) -> bool: return b.direction.dot(expected) >= tolerance - 0.001)
	_check(all_towards_near, "bullets only fire once aimed at the closest enemy")
	var muzzle_distance: float = weapon.get_node("Muzzle").position.length()
	var orbiting: bool = is_equal_approx(player.global_position.distance_to(weapon.get_node("Muzzle").global_position), muzzle_distance)
	_check(orbiting, "muzzle orbits the player's centre")
	_check(is_instance_valid(far), "out-of-range enemy is never targeted")
	_finish()


func _spawn_enemy(world: Node, at: Vector2) -> Node2D:
	var enemy: Node2D = EnemyScene.instantiate()
	enemy.speed = 0.0
	enemy.max_health = 1_000_000
	enemy.position = at
	world.add_child(enemy)
	return enemy


func _bullets(world: Node) -> Array[Node]:
	return world.get_children().filter(func(n: Node) -> bool: return "direction" in n)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
