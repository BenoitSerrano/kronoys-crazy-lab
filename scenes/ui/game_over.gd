extends CanvasLayer


func _ready() -> void:
	hide()
	%RetryButton.pressed.connect(_on_retry_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)


func open() -> void:
	get_tree().paused = true
	show()


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	get_tree().quit()
