extends Node2D

func _ready() -> void:
	print("--- TESTING OTHER EXPLOSION (explosion.png 64x64) ---")
	
	if not has_node("/root/VFX"):
		print("ERROR: VFXManager singleton missing")
		get_tree().quit(1)
		return
		
	# 1. Test resource loading
	var fiery_res = VFX.get_explosion_resource("fiery")
	assert(fiery_res != null, "Fiery resource should exist")
	print("Fiery explosion frames: ", fiery_res.explosion_frames.size())
	print("Fiery frame size: ", fiery_res.frame_size)
	assert(fiery_res.explosion_frames.size() == 11, "Should have 11 frames")
	assert(fiery_res.frame_size == Vector2(64, 64), "Should be 64x64")
	
	var def_res = VFX.get_explosion_resource("default")
	assert(def_res != null, "Default resource should exist")
	assert(def_res.explosion_frames.size() == 11, "Should have 11 frames")
	assert(def_res.frame_size == Vector2(64, 64), "Should be 64x64")
	
	# 2. Test skull smoke still works for enemy deaths
	var skull_res = VFX.get_explosion_resource("skullsmoke")
	assert(skull_res != null, "Skullsmoke resource should exist")
	assert(skull_res.explosion_frames.size() == 12, "Should have 12 frames")
	
	# 3. Test spawning both effects
	VFX.spawn_explosion(Vector2(200, 200))
	print("Spawned other explosion (explosion.png) successfully!")
	
	VFX.spawn_enemy_death_explosion(Vector2(400, 200))
	print("Spawned enemy death explosion (skullsmoke.png) successfully!")
	
	print("ALL OTHER EXPLOSION CHECKS PASSED!")
	get_tree().quit(0)
