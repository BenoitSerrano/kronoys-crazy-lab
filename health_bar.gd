extends Node2D

@export var size := Vector2(40, 5)
@export var background_color := Color(0.15, 0.15, 0.15)
@export var fill_color := Color(0.2, 0.9, 0.3)

var max_value: float = 1.0:
	set(v):
		max_value = v
		queue_redraw()
var value: float = 1.0:
	set(v):
		value = v
		queue_redraw()


func _draw() -> void:
	var bar := Rect2(-size / 2, size)
	draw_rect(bar, background_color)
	var fill := bar
	fill.size.x *= clampf(value / max_value, 0.0, 1.0)
	draw_rect(fill, fill_color)
