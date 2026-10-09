extends Node2D

## How fast the character catches up with the pointer. Higher = less delay.
@export var speed: float = 5.0

var _target: Vector2


func _ready() -> void:
	_target = global_position


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_target = get_global_mouse_position()
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_target = get_canvas_transform().affine_inverse() * event.position


func _process(delta: float) -> void:
	# Exponential smoothing: frame-rate independent delay controlled by `speed`.
	global_position = global_position.lerp(_target, 1.0 - exp(-speed * delta))
