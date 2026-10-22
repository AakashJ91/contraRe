extends SceneTree

func _init() -> void:
	var stage_scene = load("res://scenes/stage1.tscn")
	var stage = stage_scene.instantiate()
	root.add_child(stage)
	
	# Wait one frame for physics and ready
	await process_frame
	
	var player = stage.get_node("Player")
	var camera = stage.get_node("Camera2D")
	
	# Scroll camera ahead to x = 1200
	camera.global_position.x = 1200.0
	var half_w: float = (960.0 / camera.zoom.x) * 0.5
	var expected_screen_left := 1200.0 - half_w
	
	# Simulate player trying to run back past left edge
	player.global_position.x = 100.0 # Way behind the screen!
	stage._physics_process(0.016)
	
	print("Expected screen left: ", expected_screen_left)
	print("Player clamped position x: ", player.global_position.x)
	
	if player.global_position.x >= expected_screen_left + 15.0:
		print("TEST PASSED: Player is successfully clamped to the visible screen!")
	else:
		printerr("TEST FAILED: Player position is behind visible screen!")
		quit(1)
		return
	
	quit(0)
