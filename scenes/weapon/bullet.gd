extends Area2D

@export var speed: float = 600.0
@export var radius: float = 6.0
@export var color: Color = Color(1, 0.15, 0.15)
@export var damage: int = 1
## Unit vector the bullet travels along; set by the weapon.
var direction := Vector2.UP

# Guards against hitting two enemies in the same frame.
var _spent := false


func _ready() -> void:
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)


func _on_body_entered(body: Node2D) -> void:
	if _spent or not body.has_method("take_damage"):
		return
	_spent = true
	body.take_damage(damage)
	queue_free()
