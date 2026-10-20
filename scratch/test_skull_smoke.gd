extends Node2D

func _ready() -> void:
	print("--- TESTING SKULL SMOKE EXPLOSION EFFECT ---")
	
	# 1. Check VFXManager resource lookup
	if not has_node("/root/VFX"):
		print("ERROR: VFXManager singleton missing")
		get_tree().quit(1)
		return
		
	var skull_res = VFX.get_explosion_resource("skullsmoke")
	if skull_res == null:
		print("ERROR: Skull smoke resource could not be loaded!")
		get_tree().quit(1)
		return
		
	print("Loaded skull smoke resource: ", skull_res.explosion_name)
	print("Frame count: ", skull_res.explosion_frames.size())
	print("Frame size: ", skull_res.frame_size)
	assert(skull_res.explosion_frames.size() == 12, "Should have 12 frames")
	assert(skull_res.frame_size == Vector2(64, 64), "Should be 64x64")
	
	# 2. Test spawning skull smoke explosion effect
	VFX.spawn_enemy_death_explosion(Vector2(200, 200))
	print("Successfully spawned enemy death skull smoke explosion!")
	
	# 3. Test enemy death trigger
	var soldier_scene = load("res://scenes/enemy_soldier.tscn")
	if soldier_scene != null:
		var soldier = soldier_scene.instantiate()
		add_child(soldier)
		soldier.global_position = Vector2(300, 200)
		soldier.take_damage(100.0) # Lethal damage
		print("Soldier killed and triggered death explosion successfully!")
	
	var turret_scene = load("res://scenes/enemy_turret.tscn")
	if turret_scene != null:
		var turret = turret_scene.instantiate()
		add_child(turret)
		turret.global_position = Vector2(400, 200)
		turret.take_damage(100.0) # Lethal damage
		print("Turret killed and triggered death explosion successfully!")
		
	var drone_scene = load("res://scenes/enemy_drone.tscn")
	if drone_scene != null:
		var drone = drone_scene.instantiate()
		add_child(drone)
		drone.global_position = Vector2(500, 200)
		drone.take_damage(100.0) # Lethal damage
		print("Drone killed and triggered death explosion successfully!")
	
	print("ALL SKULL SMOKE CHECKS PASSED!")
	get_tree().quit(0)
