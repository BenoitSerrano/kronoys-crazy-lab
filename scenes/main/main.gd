extends Node2D


func _ready() -> void:
	$Player.died.connect($GameOver.open)
	$EnemySpawner.wave_started.connect($WaveBanner.show_wave)
