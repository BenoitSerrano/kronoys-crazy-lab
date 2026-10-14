extends SceneTree
## Checks close enemies are hit by an arc-shaped staff swing (several at once, knocked back) instead of being shot.

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
	weapon.melee_enabled = true
	weapon.ranged_enabled = true
	var reach: float = weapon.melee_range - 10.0
	var half_arc: float = deg_to_rad(weapon.swing_arc) / 2

	# Target straight right; the others are no closer, so the swing stays centred on it.
	# Kept off the player so its hurtbox doesn't push them.
	var target := _spawn_enemy(world, player.position + Vector2(reach - 10.0, 0))
	var inside := _spawn_enemy(world, player.position + Vector2(reach, 0).rotated(half_arc * 0.8))
	var behind := _spawn_enemy(world, player.position + Vector2(-reach, 0))
	var outside := _spawn_enemy(world, player.position + Vector2(weapon.melee_range + 60.0, 0).rotated(-half_arc * 0.5))
	# Overlaps are only known after a physics step.
	for i in 10:
		if weapon.is_swinging():
			break
		await process_frame
	_check(weapon.is_swinging(), "weapon swings when an enemy is within melee range")
	# Relative to pointing at the target (straight right, i.e. a quarter turn from up).
	var lowest := INF
	var highest := -INF
	while weapon.is_swinging():
		var offset := angle_difference(PI / 2, weapon.rotation)
		lowest = minf(lowest, offset)
		highest = maxf(highest, offset)
		await process_frame

	_check(target.health < target.max_health and inside.health < inside.max_health, "one swing hits several enemies in the arc")
	_check(behind.health == behind.max_health, "enemies in reach but outside the arc are not hit")
	_check(outside.health == outside.max_health, "enemies beyond melee range are not hit by the staff")
	var centred := is_equal_approx(lowest, -half_arc) and absf(highest - half_arc) < 0.05
	_check(centred, "staff sweeps the arc centred on the target (%.2f to %.2f rad)" % [lowest, highest])
	# The last enemy is hit at the end of the sweep; give the knockback time to move it.
	await create_timer(0.2, false).timeout
	var pushed_target: float = player.position.distance_to(target.position)
	var pushed_inside: float = player.position.distance_to(inside.position)
	_check(pushed_target > reach + 10.0 and pushed_inside > reach + 20.0, "hit enemies are knocked away from the player (%.0f, %.0f px)" % [pushed_target, pushed_inside])
	_check(_bullets(world).is_empty(), "no bullet fired while an enemy is in melee range")
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
