extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: int = 3
## Damage dealt to the player on contact.
@export var contact_damage: int = 1
## Initial speed (px/s) of the push away from the player on contact.
@export var knockback_strength: float = 450.0
## How fast the knockback fades. Higher = shorter recoil.
@export var knockback_decay: float = 8.0
## Walk animation speed in frames per second (sheet has 36 frames).
@export var walk_fps: float = 30.0

## Node the enemy walks towards; set by the spawner.
var target: Node2D

var _knockback := Vector2.ZERO
var _anim_time := 0.0

@onready var health: int = max_health
@onready var _health_bar := $HealthBar
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_health_bar.max_value = max_health
	_health_bar.value = health


func _physics_process(delta: float) -> void:
	_knockback *= exp(-knockback_decay * delta)
	var chase := Vector2.ZERO
	if is_instance_valid(target):
		chase = global_position.direction_to(target.global_position) * speed
	velocity = chase + _knockback
	move_and_slide()
	_animate(delta, chase)


func _animate(delta: float, chase: Vector2) -> void:
	var frame_count := _sprite.hframes * _sprite.vframes
	_anim_time += delta
	_sprite.frame = int(_anim_time * walk_fps) % frame_count
	# The sheet faces left; mirror (offset included) when heading right.
	if chase.x != 0.0:
		_sprite.scale.x = absf(_sprite.scale.x) * (1.0 if chase.x < 0.0 else -1.0)


func knock_back(direction: Vector2) -> void:
	_knockback = direction * knockback_strength


func take_damage(amount: int) -> void:
	health -= amount
	_health_bar.value = health
	if health <= 0:
		queue_free()
