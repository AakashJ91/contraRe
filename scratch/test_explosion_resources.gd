extends Node2D

func _ready() -> void:
	print("--- TESTING EXPLOSION VFX RESOURCES ---")
	
	var resource_keys = [
		"fiery", "electric", "alien", "nuclear", "cryo", "magma", "mini", "default"
	]
	
	var res_paths = [
		"res://resources/vfx/explosion_arcade_fiery.tres",
		"res://resources/vfx/explosion_electric_tesla.tres",
		"res://resources/vfx/explosion_alien_bio.tres",
		"res://resources/vfx/explosion_nuclear_mega.tres",
		"res://resources/vfx/explosion_cryo_frost.tres",
		"res://resources/vfx/explosion_magma_volcanic.tres",
		"res://resources/vfx/explosion_mini_impact.tres",
		"res://resources/vfx/explosion_default.tres"
	]
	
	for path in res_paths:
		assert(ResourceLoader.exists(path), "Resource file must exist: " + path)
		var res = load(path)
		assert(res != null, "Resource must load successfully: " + path)
		assert(res is ExplosionVFXData, "Resource must be ExplosionVFXData: " + path)
		print("Loaded resource: ", res.explosion_name, " [Category: ", res.category, "] frames=", res.explosion_frames.size())
		assert(res.explosion_frames.size() > 0, "Resource must have frames: " + path)
		for f in res.explosion_frames:
			assert(f != null, "Frame texture must not be null in: " + path)
	
	print("All 8 explosion resources verified on disk!")
	
	# Verify VFX lookup
	for key in resource_keys:
		var r = VFX.get_explosion_resource(key)
		assert(r != null, "VFX.get_explosion_resource must find key: " + key)
		print("VFX lookup '", key, "' -> ", r.explosion_name)
	
	# Test spawning all 7 themed explosions in the scene
	var positions = [
		Vector2(100.0, 150.0), # fiery
		Vector2(250.0, 150.0), # electric
		Vector2(400.0, 150.0), # alien
		Vector2(550.0, 150.0), # nuclear
		Vector2(100.0, 350.0), # cryo
		Vector2(250.0, 350.0), # magma
		Vector2(400.0, 350.0)  # mini
	]
	
	var themes = ["fiery", "electric", "alien", "nuclear", "cryo", "magma", "mini"]
	for i in range(themes.size()):
		var t_name = themes[i]
		var pos = positions[i]
		VFX.spawn_explosion_by_name(pos, t_name)
		print("Spawned explosion: ", t_name, " at ", pos)
	
	# Check spawned nodes in VFX parent
	var vfx_parent = VFX._get_vfx_parent()
	var explosion_nodes = []
	for child in vfx_parent.get_children():
		if child is VFX.AnimatedExplosionEffect:
			explosion_nodes.append(child)
	
	print("Total explosion nodes spawned: ", explosion_nodes.size())
	assert(explosion_nodes.size() == 7, "Expected 7 explosion effect nodes")
	
	# Advance physics and verify animation / particle progress
	var dt = 0.016
	for step in range(15):
		for exp_node in explosion_nodes:
			if is_instance_valid(exp_node):
				exp_node._process(dt)
	
	print("Simulation progressed 15 steps without errors.")
	for exp_node in explosion_nodes:
		if is_instance_valid(exp_node):
			assert(exp_node.debris_particles.size() > 0, "Must have active debris particles")
			assert(exp_node.spark_particles.size() > 0, "Must have active spark particles")
			assert(exp_node.smoke_particles.size() > 0, "Must have active smoke particles")
	
	print("ALL EXPLOSION VFX RESOURCE UNIT TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
