extends SceneTree
## Checks "Return to main screen" on the Game Over menu unpauses and goes back to the title screen.

const MainScene := "res://scenes/main/main.tscn"
const TitleScene := "res://scenes/ui/title_screen.tscn"

var _failures: PackedStringArray = []


func _initialize() -> void:
	var main: Node = load(MainScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame

	main.get_node("Player").died.emit()
	await process_frame
	var game_over: CanvasLayer = main.get_node("GameOver")
	_check(game_over.visible and paused, "player death opens the Game Over menu and pauses")

	var button: Button = game_over.get_node("%MainScreenButton")
	_check(button.text == "Return to main screen", "button label (got '%s')" % button.text)
	button.pressed.emit()
	await process_frame
	await process_frame
	_check(not paused, "game is unpaused")
	_check(current_scene != null and current_scene.scene_file_path == TitleScene, "returns to the title screen (got %s)" % [current_scene.scene_file_path if current_scene else "null"])
	_finish()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print(("  ok   " if condition else "  FAIL ") + description)


func _finish() -> void:
	print("%s: %d failure(s)" % [get_script().resource_path.get_file(), _failures.size()])
	quit(1 if _failures.size() > 0 else 0)
