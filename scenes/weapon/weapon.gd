extends Node2D
## Orbits its parent (it sits at the parent's origin) and auto-fires at the closest enemy in range.
## When that enemy gets close, the staff is swung in an arc centred on it instead, hitting every enemy it sweeps within reach.

const BulletScene := preload("res://scenes/weapon/bullet.tscn")

## Bullets fired per second.
@export var fire_rate: float = 3.0
## Enemies further than this (px) from the player are not detected.
@export var detection_range: float = 400.0
## How fast the staff turns towards its target. Higher = snappier.
@export var turn_speed: float = 15.0
## Only fire when the staff is within this angle (degrees) of the target.
@export var aim_tolerance: float = 10.0
## How far (px) the staff is pushed back by a single shot.
@export var recoil_distance: float = 10.0
## Cap on the accumulated recoil when shots overlap.
@export var max_recoil: float = 16.0
## How fast the staff returns to rest. Higher = snappier.
@export var recoil_recovery: float = 25.0
## When off, the staff never swings and always fires, even at close enemies.
@export var melee_enabled: bool = true
## When off, the staff never fires; it only swings at close enemies.
@export var ranged_enabled: bool = true
## Enemies closer than this (px, centre to centre) trigger a swing, and are hit by it.
@export var melee_range: float = 130.0
## Angle (degrees) the staff sweeps, centred on the target.
@export var swing_arc: float = 60.0
## Seconds for the staff to sweep the whole arc.
@export var swing_duration: float = 0.3
## Seconds between the end of a swing and the start of the next.
@export var swing_cooldown: float = 0.4
@export var swing_damage: float = 0.5
## Multiplier on the enemy's usual knockback when hit by the staff.
@export var swing_knockback: float = 5.0

# Current backward offset of the staff; decays back to 0.
var _recoil: float = 0.0
var _target: Node2D
# Angle swept so far by the current swing; negative when not swinging.
var _swing_angle: float = -1.0
var _swing_start: float = 0.0
var _swing_cooldown_left: float = 0.0
# Enemies already hit by the current swing, so each is hit once per swing.
var _swing_hits: Array[Node2D] = []

@onready var _staff: Control = $Staff
@onready var _staff_rest_y: float = _staff.position.y
@onready var _detection_range: Area2D = $DetectionRange


func _ready() -> void:
	($DetectionRange/CollisionShape2D.shape as CircleShape2D).radius = detection_range
	$FireTimer.wait_time = 1.0 / fire_rate
	$FireTimer.timeout.connect(_shoot)
	$FireTimer.start()


func _process(delta: float) -> void:
	_target = _closest_enemy()
	_swing_cooldown_left -= delta
	if is_swinging():
		_continue_swing(delta)
	elif _target and _in_melee_range(_target) and _swing_cooldown_left <= 0.0:
		_start_swing()
	elif _target:
		# Exponential smoothing, like the player's movement: frame-rate independent steering.
		rotation = lerp_angle(rotation, _aim_angle(), 1.0 - exp(-turn_speed * delta))
	_recoil *= exp(-recoil_recovery * delta)
	# Local Y follows the staff, so recoil always pushes it back towards the player.
	_staff.position.y = _staff_rest_y + _recoil


## Rotation that points the staff at the target. The staff points along local -Y, hence the quarter turn.
func _aim_angle() -> float:
	return global_position.angle_to_point(_target.global_position) + PI / 2


func is_swinging() -> bool:
	return _swing_angle >= 0.0


func _in_melee_range(enemy: Node2D) -> bool:
	return melee_enabled and global_position.distance_to(enemy.global_position) <= melee_range


func _start_swing() -> void:
	# Start half an arc before the target so the sweep is centred on it.
	_swing_start = _aim_angle() - deg_to_rad(swing_arc) / 2
	rotation = _swing_start
	_swing_angle = 0.0
	_swing_hits.clear()
	_hit_swept_enemies()


func _continue_swing(delta: float) -> void:
	var arc := deg_to_rad(swing_arc)
	_swing_angle = minf(_swing_angle + arc * delta / swing_duration, arc)
	rotation = _swing_start + _swing_angle
	_hit_swept_enemies()
	if _swing_angle >= arc:
		_swing_angle = -1.0
		_swing_cooldown_left = swing_cooldown


## Hits every enemy within reach that the staff has swept past since the swing started.
func _hit_swept_enemies() -> void:
	for body in _detection_range.get_overlapping_bodies():
		if not body.has_method("take_damage") or body in _swing_hits or not _in_melee_range(body):
			continue
		var angle := global_position.angle_to_point(body.global_position) + PI / 2
		if fposmod(angle - _swing_start, TAU) > _swing_angle:
			continue
		_swing_hits.append(body)
		if body.has_method("knock_back"):
			body.knock_back(global_position.direction_to(body.global_position), swing_knockback)
		body.take_damage(swing_damage)


func _closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_distance := INF
	for body in _detection_range.get_overlapping_bodies():
		if not body.has_method("take_damage"):
			continue
		var distance := global_position.distance_squared_to(body.global_position)
		if distance < closest_distance:
			closest = body
			closest_distance = distance
	return closest


func _shoot() -> void:
	if not ranged_enabled or not is_instance_valid(_target) or is_swinging() or _in_melee_range(_target):
		return
	if absf(angle_difference(rotation, _aim_angle())) > deg_to_rad(aim_tolerance):
		return
	var bullet := BulletScene.instantiate()
	bullet.direction = Vector2.UP.rotated(global_rotation)
	# Add to the scene root so bullets don't move with the player.
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $Muzzle.global_position
	# Add to the current offset so a shot mid-recoil kicks from where the staff is.
	_recoil = minf(_recoil + recoil_distance, max_recoil)
