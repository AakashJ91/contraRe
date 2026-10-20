extends Node2D

func _ready() -> void:
	print("--- Running test_spread_scene ---")
	
	# Load player
	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(200, 200)
	
	# Set weapon to SPREAD
	Global.current_weapon = Global.WeaponType.SPREAD
	print("Current weapon set to: ", Global.current_weapon)
	
	# Shoot
	player._shoot()
	
	# Count bullets in parent
	var bullets = []
	for child in get_children():
		if child != player and child.get("direction") != null:
			bullets.append(child)
	
	print("Spawned bullets count: ", bullets.size())
	for i in range(bullets.size()):
		var b = bullets[i]
		print("  Bullet %d: pos=%s dir=%s speed=%f dmg=%f owner=%d type=%d layer=%d mask=%d is_in_bullet_group=%s" % [
			i, b.global_position, b.direction, b.speed, b.damage, b.bullet_owner, b.weapon_type, b.collision_layer, b.collision_mask, b.is_in_group("bullet")
		])
	
	# Test Soldier
	var soldier_scene = load("res://scenes/enemy_soldier.tscn")
	var soldier = soldier_scene.instantiate()
	add_child(soldier)
	soldier.global_position = Vector2(300, 200)
	print("Soldier initial health: ", soldier.health)
	if bullets.size() > 0:
		var b0 = bullets[2]
		b0._handle_hit(soldier)
		print("Soldier health after b0 hit: ", soldier.health)
	
	# Test MiniBoss
	var miniboss_scene = load("res://scenes/mini_boss.tscn")
	var miniboss = miniboss_scene.instantiate()
	add_child(miniboss)
	miniboss.global_position = Vector2(500, 200)
	miniboss.activate()
	print("MiniBoss initial health: ", miniboss.current_health)
	var hurtbox = miniboss.get_node_or_null("Hurtbox")
	print("MiniBoss hurtbox found: ", hurtbox != null)
	if hurtbox != null and bullets.size() > 0:
		var b1 = bullets[0]
		print("Testing b1._handle_hit(hurtbox)...")
		b1._handle_hit(hurtbox)
		print("MiniBoss health after b1._handle_hit(hurtbox): ", miniboss.current_health)
		
		print("Testing miniboss._on_hurtbox_entered(b1)...")
		miniboss._on_hurtbox_entered(b1)
		print("MiniBoss health after _on_hurtbox_entered(b1): ", miniboss.current_health)
	
	# Test Boss
	var boss_scene = load("res://scenes/boss.tscn")
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(800, 200)
	boss.activate()
	var core = boss.get_node_or_null("CoreArea")
	print("Boss initial health: ", boss.current_health)
	if core != null and bullets.size() > 1:
		var b2 = bullets[1]
		print("Testing b2._handle_hit(core)...")
		b2._handle_hit(core)
		print("Boss health after b2._handle_hit(core): ", boss.current_health)
		
	# Test PowerupSensor
	var sensor_scene = load("res://scenes/powerup_sensor.tscn")
	var sensor = sensor_scene.instantiate()
	add_child(sensor)
	sensor.global_position = Vector2(1000, 200)
	print("Sensor initialized. Health: ", sensor.health, ", Frames count: ", sensor.frames.size())
	if bullets.size() > 3:
		var b3 = bullets[3]
		print("Testing b3._handle_hit(sensor)...")
		b3._handle_hit(sensor)
		print("Sensor health after b3 hit: ", sensor.health)
	
	get_tree().quit(0)
