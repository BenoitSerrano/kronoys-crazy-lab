class_name Wave
extends Resource

## Number of enemies spawned during this wave.
@export var enemy_count: int = 5
## Enemies spawned together, bunched up at the same spot on the border.
@export var group_size: int = 1
## Seconds between two groups within the wave.
@export var spawn_interval: float = 1.5
## Pause before the first spawn of the wave.
@export var start_delay: float = 2.0
@export var enemy_speed: float = 80.0
@export var enemy_health: int = 3
