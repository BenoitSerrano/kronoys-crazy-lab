extends Node2D

@export var speed: float = 600.0
@export var radius: float = 6.0
@export var color: Color = Color(1, 0.15, 0.15)


func _ready() -> void:
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)


func _process(delta: float) -> void:
	position.y -= speed * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
