extends Node2D

signal wave_started(number: int)
signal wave_cleared(number: int)
signal all_waves_cleared
signal _last_enemy_removed

const EnemyScene := preload("res://scenes/enemy/enemy.tscn")

## Waves played in order. Each one starts once the previous one is fully killed.
@export var waves: Array[Wave] = []
## How far outside the screen edges enemies appear.
@export var spawn_margin: float = 40.0
## How far (px) the enemies of a group are scattered around their spawn point.
@export var group_spread: float = 60.0
@export var target: Node2D

var _alive := 0


func _ready() -> void:
	$SpawnTimer.one_shot = true
	# Deferred so listeners can connect in their _ready before wave 1 starts.
	_run_waves.call_deferred()


func _run_waves() -> void:
	for i in waves.size():
		var wave := waves[i]
		await _wait(wave.start_delay)
		wave_started.emit(i + 1)
		var group_size := maxi(wave.group_size, 1)
		for n in range(0, wave.enemy_count, group_size):
			if n > 0:
				await _wait(wave.spawn_interval)
			_spawn_group(wave, mini(group_size, wave.enemy_count - n))
		if _alive > 0:
			await _last_enemy_removed
		wave_cleared.emit(i + 1)
	all_waves_cleared.emit()


## Uses the scene's own timer so waves pause with the game and stop on reload.
func _wait(seconds: float) -> void:
	if seconds <= 0.0:
		return
	$SpawnTimer.start(seconds)
	await $SpawnTimer.timeout


func _spawn_group(wave: Wave, count: int) -> void:
	var viewport := get_viewport()
	var screen := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var perimeter := 2.0 * (screen.size.x + screen.size.y)
	var origin := randf() * perimeter
	for i in count:
		# Scatter along the border and further out, never towards the screen.
		var along := fposmod(origin + randf_range(-group_spread, group_spread), perimeter)
		var border := screen.grow(spawn_margin + randf() * group_spread)
		var position_on_border := _point_on_border(border, along / perimeter)
		_spawn(wave, position_on_border)


func _spawn(wave: Wave, at: Vector2) -> void:
	var enemy := EnemyScene.instantiate()
	enemy.target = target
	enemy.speed = wave.enemy_speed
	enemy.max_health = wave.enemy_health
	enemy.position = at
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_removed)
	add_child(enemy)


## Uniform over the rectangle's perimeter, so every side gets spawns in proportion to its length.
func _random_point_on_border(rect: Rect2) -> Vector2:
	return _point_on_border(rect, randf())


## Point at `fraction` (0..1) of the way round the rectangle's perimeter, clockwise from the top-left corner.
func _point_on_border(rect: Rect2, fraction: float) -> Vector2:
	var d := fraction * 2.0 * (rect.size.x + rect.size.y)
	if d < rect.size.x:
		return rect.position + Vector2(d, 0)
	d -= rect.size.x
	if d < rect.size.y:
		return Vector2(rect.end.x, rect.position.y + d)
	d -= rect.size.y
	if d < rect.size.x:
		return Vector2(rect.end.x - d, rect.end.y)
	d -= rect.size.x
	return Vector2(rect.position.x, rect.end.y - d)


func _on_enemy_removed() -> void:
	_alive -= 1
	# Enemies also leave when the whole scene is freed (e.g. Retry): don't treat that as a cleared wave.
	if _alive == 0 and is_inside_tree():
		_last_enemy_removed.emit()
