extends SceneTree
## Plays every wave (player invincible, enemies auto-killed shortly after spawning)
## and checks waves run in order and the "Wave X" banner shows then hides.

const TIME_SCALE := 8.0
const ENEMY_LIFETIME := 1.0
const BANNER_CHECK_DELAY := 2.2

var _failures: PackedStringArray = []
var _started: Array[int] = []
var _cleared: Array[int] = []


func _initialize() -> void:
	Engine.time_scale = TIME_SCALE
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	var player: Node = main.get_node("Player")
	player.max_health = 1_000_000
	root.add_child(main)
	current_scene = main

	var spawner: Node = main.get_node("EnemySpawner")
	var banner: CanvasLayer = main.get_node("WaveBanner")
	var wave_count: int = spawner.waves.size()
	spawner.child_entered_tree.connect(_kill_later)
	spawner.wave_cleared.connect(func(n: int) -> void: _cleared.append(n))
	spawner.wave_started.connect(func(n: int) -> void:
		_started.append(n)
		await process_frame
		_check(banner.visible, "banner visible when wave %d starts" % n)
		_check(banner.get_node("%Label").text == "Wave %d" % n, "banner text is 'Wave %d'" % n)
		await create_timer(BANNER_CHECK_DELAY, false).timeout
		_check(not banner.visible, "banner hidden %.1fs after wave %d starts" % [BANNER_CHECK_DELAY, n]))

	var timeout := create_timer(300.0, false)
	var done: bool = await _first_of(spawner.all_waves_cleared, timeout.timeout)
	_check(done, "all waves cleared before timeout")
	var expected: Array[int] = []
	for i in wave_count:
		expected.append(i + 1)
	_check(_started == expected, "waves started in order %s (got %s)" % [expected, _started])
	_check(_cleared == expected, "waves cleared in order %s (got %s)" % [expected, _cleared])
	_finish()


func _kill_later(node: Node) -> void:
	if not node.has_method("take_damage"):
		return
	var ref: WeakRef = weakref(node)
	await create_timer(ENEMY_LIFETIME, false).timeout
	var enemy: Node = ref.get_ref()
	if enemy:
		enemy.take_damage(1_000_000)


## Resolves to true if `a` fires first, false if `b` does.
func _first_of(a: Signal, b: Signal) -> bool:
	var state := {"result": null}
	a.connect(func() -> void: if state.result == null: state.result = true, CONNECT_ONE_SHOT)
	b.connect(func() -> void: if state.result == null: state.result = false, CONNECT_ONE_SHOT)
	while state.result == null:
		await process_frame
	return state.result


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
