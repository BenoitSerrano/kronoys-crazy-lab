extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: int = 3

const HEALTH_BAR_SIZE := Vector2(40, 5)
const HEALTH_BAR_OFFSET := Vector2(0, -34)

## Node the enemy walks towards; set by the spawner.
var target: Node2D

@onready var health: int = max_health


func _physics_process(_delta: float) -> void:
	if target:
		velocity = global_position.direction_to(target.global_position) * speed
		move_and_slide()


func take_damage(amount: int) -> void:
	health -= amount
	queue_redraw()
	if health <= 0:
		queue_free()


func _draw() -> void:
	var bar := Rect2(HEALTH_BAR_OFFSET - HEALTH_BAR_SIZE / 2, HEALTH_BAR_SIZE)
	draw_rect(bar, Color(0.15, 0.15, 0.15))
	var fill := bar
	fill.size.x *= float(health) / max_health
	draw_rect(fill, Color(0.2, 0.9, 0.3))
