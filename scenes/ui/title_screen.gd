extends Control

const GameScene := "res://scenes/main/main.tscn"


func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)
	%StartButton.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GameScene)


func _on_exit_pressed() -> void:
	get_tree().quit()
