extends Node2D


func _ready() -> void:
	$Player.died.connect($GameOver.open)
