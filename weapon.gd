extends Node2D

const BulletScene := preload("res://bullet.tscn")

## Bullets fired per second.
@export var fire_rate: float = 5.0


func _ready() -> void:
	$FireTimer.wait_time = 1.0 / fire_rate
	$FireTimer.timeout.connect(_shoot)
	$FireTimer.start()


func _shoot() -> void:
	var bullet := BulletScene.instantiate()
	# Add to the scene root so bullets don't move with the player.
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $Muzzle.global_position
