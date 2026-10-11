extends CanvasLayer

## Seconds the banner stays on screen.
@export var display_duration: float = 2.0


func _ready() -> void:
	hide()
	$HideTimer.one_shot = true
	$HideTimer.timeout.connect(hide)


func show_wave(number: int) -> void:
	%Label.text = "Wave %d" % number
	show()
	$HideTimer.start(display_duration)
