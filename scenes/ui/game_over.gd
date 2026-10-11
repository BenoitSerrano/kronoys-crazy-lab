extends CanvasLayer

const TitleScene := "res://scenes/ui/title_screen.tscn"


func _ready() -> void:
	hide()
	%RetryButton.pressed.connect(_on_retry_pressed)
	%MainScreenButton.pressed.connect(_on_main_screen_pressed)


func open() -> void:
	get_tree().paused = true
	show()


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_screen_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TitleScene)
