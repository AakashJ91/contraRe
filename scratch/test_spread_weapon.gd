extends SceneTree

func _init() -> void:
	print("--- Running test_spread_weapon ---")
	var root = Node2D.new()
	root.name = "TestRoot"
	get_root().add_child(root)
	
	# Load player
	var player_scene = load("res://scenes/player.gd")
	var player = CharacterBody2D.new()
	player.set_script(player_scene)
	root.add_child(player)
	player.global_position = Vector2(200, 200)
	
	# Set weapon to SPREAD
	Global.current_weapon = Global.WeaponType.SPREAD
	print("Current weapon set to: ", Global.current_weapon)
	
	# Shoot
	player._shoot()
	
	# Count bullets in root
	var bullets = []
	for child in root.get_children():
		if child != player:
			bullets.append(child)
	
	print("Spawned bullets count: ", bullets.size())
	for i in range(bullets.size()):
		var b = bullets[i]
		print("  Bullet %d: pos=%s dir=%s speed=%f dmg=%f owner=%d type=%d layer=%d mask=%d" % [
			i, b.global_position, b.direction, b.speed, b.damage, b.bullet_owner, b.weapon_type, b.collision_layer, b.collision_mask
		])
	
	# Now let's test collision with enemy soldier
	var soldier_scene = load("res://scenes/enemy_soldier.tscn")
	var soldier = soldier_scene.instantiate()
	root.add_child(soldier)
	soldier.global_position = Vector2(300, 200)
	print("Soldier initial health: ", soldier.health)
	
	# Test bullet hit on soldier directly
	if bullets.size() > 0:
		var b0 = bullets[2] # center bullet (dir = Vector2.RIGHT)
		b0._handle_hit(soldier)
		print("Soldier health after b0 hit: ", soldier.health)
	
	# Test MiniBoss
	var miniboss_scene = load("res://scenes/mini_boss.tscn")
	var miniboss = miniboss_scene.instantiate()
	root.add_child(miniboss)
	miniboss.global_position = Vector2(500, 200)
	miniboss.activate()
	print("MiniBoss initial health: ", miniboss.current_health)
	
	# Find hurtbox of miniboss
	var hurtbox = miniboss.get_node_or_null("Hurtbox")
	print("MiniBoss hurtbox found: ", hurtbox != null)
	if hurtbox != null and bullets.size() > 0:
		var b1 = bullets[0]
		print("Bullet hitting hurtbox directly...")
		b1._handle_hit(hurtbox)
		print("MiniBoss health after b1._handle_hit(hurtbox): ", miniboss.current_health)
		
		# Now test hurtbox._on_hurtbox_entered with bullet
		print("Hurtbox area_entered with bullet...")
		miniboss._on_hurtbox_entered(b1)
		print("MiniBoss health after _on_hurtbox_entered(b1): ", miniboss.current_health)
	
	# Test Boss
	var boss_scene = load("res://scenes/boss.tscn")
	var boss = boss_scene.instantiate()
	root.add_child(boss)
	boss.global_position = Vector2(800, 200)
	var core = boss.get_node_or_null("CoreArea")
	print("Boss initial health: ", boss.core_health)
	if core != null and bullets.size() > 1:
		var b2 = bullets[1]
		print("Bullet hitting CoreArea directly...")
		b2._handle_hit(core)
		print("Boss health after b2._handle_hit(core): ", boss.core_health)
		
		print("CoreArea hit with bullet...")
		boss._on_core_hit(b2)
		print("Boss health after _on_core_hit(b2): ", boss.core_health)
	
	quit()
