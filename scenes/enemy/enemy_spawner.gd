extends Node2D

signal wave_started(number: int)
signal wave_cleared(number: int)
signal all_waves_cleared
signal _last_enemy_removed

const EnemyScene := preload("res://scenes/enemy/enemy.tscn")

## Waves played in order. Each one starts once the previous one is fully killed.
@export var waves: Array[Wave] = []
## How far above the top edge of the screen enemies appear.
@export var spawn_margin: float = 40.0
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
		for n in wave.enemy_count:
			if n > 0:
				await _wait(wave.spawn_interval)
			_spawn(wave)
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


func _spawn(wave: Wave) -> void:
	var viewport := get_viewport()
	var screen := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var enemy := EnemyScene.instantiate()
	enemy.target = target
	enemy.speed = wave.enemy_speed
	enemy.max_health = wave.enemy_health
	enemy.position = Vector2(
		randf_range(screen.position.x, screen.end.x),
		screen.position.y - spawn_margin,
	)
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_removed)
	add_child(enemy)


func _on_enemy_removed() -> void:
	_alive -= 1
	# Enemies also leave when the whole scene is freed (e.g. Retry): don't treat that as a cleared wave.
	if _alive == 0 and is_inside_tree():
		_last_enemy_removed.emit()
