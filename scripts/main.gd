extends Node2D

func _ready() -> void:
	pass

func get_landing_surface(pos_x: float, from_y: float) -> Dictionary:
	var st = get_node_or_null("Stage1")
	if st != null and st.has_method("get_landing_surface"):
		return st.get_landing_surface(pos_x, from_y)
	return {"found": false, "surface_y": 0.0, "landing_y": 0.0, "is_platform": false, "platform": {}}

func get_safe_respawn_position(target_x: float) -> Vector2:
	var st = get_node_or_null("Stage1")
	if st != null and st.has_method("get_safe_respawn_position"):
		return st.get_safe_respawn_position(target_x)
	return Vector2(target_x, 380.0)

func is_position_over_ground(pos_x: float) -> bool:
	var st = get_node_or_null("Stage1")
	if st != null and st.has_method("is_position_over_ground"):
		return st.is_position_over_ground(pos_x)
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			Global.reset_game()
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			Global.go_to_level_select()
