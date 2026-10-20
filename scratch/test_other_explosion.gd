extends Node2D

func _ready() -> void:
	print("--- TESTING EXPLOSION.PNG & REMOVAL OF THEMED EXPLOSIONS ---")
	
	if not has_node("/root/VFX"):
		print("ERROR: VFXManager singleton missing")
		get_tree().quit(1)
		return
		
	# 1. Test default resource from explosion.png
	var def_res = VFX.get_explosion_resource("default")
	assert(def_res != null, "Default resource should exist")
	print("Default explosion frames count: ", def_res.explosion_frames.size())
	print("Default explosion frame size: ", def_res.frame_size)
	assert(def_res.explosion_frames.size() == 11, "explosion.png should have 11 frames")
	assert(def_res.frame_size == Vector2(64, 64), "explosion.png frames should be 64x64")
	
	# 2. Test removed themed explosions fall back to default explosion.png
	var removed_keys = ["alien", "cryo", "electric", "fiery", "magma", "nuclear", "mini", "arcade", "tesla", "bio", "mega", "frost", "volcanic"]
	for k in removed_keys:
		assert(!VFX.explosion_resources.has(k), "Resource map should not have key: " + k)
		var fb_res = VFX.get_explosion_resource(k)
		assert(fb_res == def_res, "Key '" + k + "' must fall back to default explosion.png")
		print("Verified fallback for removed key: ", k)
	
	# 3. Test skull smoke still works for enemy deaths
	var skull_res = VFX.get_explosion_resource("skullsmoke")
	assert(skull_res != null, "Skullsmoke resource should exist")
	assert(skull_res.explosion_frames.size() == 12, "Skullsmoke should have 12 frames")
	print("Skullsmoke (enemy death) intact: ", skull_res.explosion_frames.size(), " frames")
	
	# 4. Test big explosion still works for boss/mini-boss deaths
	var big_res = VFX.get_explosion_resource("big")
	assert(big_res != null, "Big explosion resource should exist")
	assert(big_res.explosion_frames.size() == 15, "Big explosion should have 15 frames")
	print("Big explosion (boss death) intact: ", big_res.explosion_frames.size(), " frames")
	
	# 5. Test spawning explosions
	VFX.spawn_explosion(Vector2(200, 200))
	print("Spawned explosion (explosion.png) successfully!")
	
	VFX.spawn_enemy_death_explosion(Vector2(400, 200))
	print("Spawned enemy death explosion (skullsmoke.png) successfully!")
	
	VFX.spawn_big_explosion(Vector2(600, 200))
	print("Spawned boss final death explosion (big_explosion.png) successfully!")
	
	print("ALL EXPLOSION.PNG AND REMOVAL CHECKS PASSED!")
	get_tree().quit(0)
