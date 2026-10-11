extends Node2D

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			Global.reset_game()
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
