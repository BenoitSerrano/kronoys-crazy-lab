extends SceneTree
## Simulates Retry while enemies are alive and checks the reloaded scene starts again at wave 1.

const TIME_SCALE := 8.0
const RETRY_AFTER := 5.0

var _failures: PackedStringArray = []


func _initialize() -> void:
	Engine.time_scale = TIME_SCALE
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("Player").max_health = 1_000_000
	root.add_child(main)
	current_scene = main

	await create_timer(RETRY_AFTER, false).timeout
	var alive: int = main.get_node("EnemySpawner")._alive
	_check(alive > 0, "enemies alive at Retry (got %d)" % alive)
	reload_current_scene()
	await process_frame
	await process_frame
	_check(current_scene != main, "scene was reloaded")

	var spawner: Node = current_scene.get_node("EnemySpawner")
	var first_wave: Array[int] = []
	spawner.wave_started.connect(func(n: int) -> void: first_wave.append(n), CONNECT_ONE_SHOT)
	await create_timer(10.0, false).timeout
	_check(first_wave == [1], "reloaded scene starts at wave 1 (got %s)" % [first_wave])
	_finish()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
