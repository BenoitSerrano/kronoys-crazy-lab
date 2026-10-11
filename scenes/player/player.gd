extends CharacterBody2D

signal died

## How fast the character catches up with the pointer. Higher = less delay.
@export var speed: float = 5.0
@export var max_health: int = 5
## Seconds of invulnerability after being hit, so touching enemies don't drain health every frame.
@export var hit_cooldown: float = 0.6

var health: int
var _target: Vector2
var _hit_timer: float = 0.0

@onready var _health_bar := $HealthBar
# Slightly larger than the body's collision shape: bodies never overlap, so this detects touching.
@onready var _hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	_target = global_position
	health = max_health
	_health_bar.max_value = max_health
	_health_bar.value = health


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_target = get_global_mouse_position()
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_target = get_canvas_transform().affine_inverse() * event.position


func _physics_process(delta: float) -> void:
	# Exponential smoothing: frame-rate independent delay controlled by `speed`.
	# Moving through move_and_slide keeps the player from entering enemies.
	var next := global_position.lerp(_target, 1.0 - exp(-speed * delta))
	velocity = (next - global_position) / delta
	move_and_slide()

	_hit_timer -= delta
	for body in _hurtbox.get_overlapping_bodies():
		if not "contact_damage" in body:
			continue
		if _hit_timer <= 0.0:
			take_damage(body.contact_damage)
		body.knock_back(global_position.direction_to(body.global_position))


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_health_bar.value = health
	_hit_timer = hit_cooldown
	if health <= 0:
		died.emit()
