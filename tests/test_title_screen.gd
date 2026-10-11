extends SceneTree
## Checks the project boots on the title screen and "Start a new game" opens the game.

const MainScene := "res://scenes/main/main.tscn"

var _failures: PackedStringArray = []


func _initialize() -> void:
	var boot_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_check(ResourceUID.ensure_path(boot_scene) == "res://scenes/ui/title_screen.tscn", "project boots on the title screen (got %s)" % boot_scene)

	var title: Node = load(boot_scene).instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	var start: Button = title.get_node("%StartButton")
	var exit: Button = title.get_node("%ExitButton")
	_check(start.text == "Start a new game", "start button label")
	_check(exit.text == "Exit", "exit button label")

	start.pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == MainScene, "start opens the game scene (got %s)" % [current_scene.scene_file_path if current_scene else "null"])
	_finish()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
