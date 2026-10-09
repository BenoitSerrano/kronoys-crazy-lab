extends Node2D

const EnemyScene := preload("res://enemy.tscn")

## Seconds between two spawns.
@export var spawn_interval: float = 1.5
## How far above the top edge of the screen enemies appear.
@export var spawn_margin: float = 40.0
@export var target: Node2D


func _ready() -> void:
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.timeout.connect(_spawn)
	$SpawnTimer.start()


func _spawn() -> void:
	var viewport := get_viewport()
	var screen := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var enemy := EnemyScene.instantiate()
	enemy.target = target
	enemy.position = Vector2(
		randf_range(screen.position.x, screen.end.x),
		screen.position.y - spawn_margin,
	)
	add_child(enemy)
