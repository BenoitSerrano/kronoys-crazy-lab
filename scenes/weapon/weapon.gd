extends Node2D

const BulletScene := preload("res://scenes/weapon/bullet.tscn")

## Bullets fired per second.
@export var fire_rate: float = 5.0
## How far (px) the staff is pushed down by a single shot.
@export var recoil_distance: float = 10.0
## Cap on the accumulated recoil when shots overlap.
@export var max_recoil: float = 16.0
## How fast the staff returns to rest. Higher = snappier.
@export var recoil_recovery: float = 25.0

# Current downward offset of the staff; decays back to 0.
var _recoil: float = 0.0

@onready var _staff: Control = $Staff
@onready var _staff_rest_y: float = _staff.position.y


func _ready() -> void:
	$FireTimer.wait_time = 1.0 / fire_rate
	$FireTimer.timeout.connect(_shoot)
	$FireTimer.start()


func _process(delta: float) -> void:
	_recoil *= exp(-recoil_recovery * delta)
	_staff.position.y = _staff_rest_y + _recoil


func _shoot() -> void:
	var bullet := BulletScene.instantiate()
	# Add to the scene root so bullets don't move with the player.
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $Muzzle.global_position
	# Add to the current offset so a shot mid-recoil kicks from where the staff is.
	_recoil = minf(_recoil + recoil_distance, max_recoil)
