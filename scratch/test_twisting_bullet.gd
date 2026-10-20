extends Node2D

func _ready() -> void:
	print("--- TESTING TWISTING BULLET POWER ---")
	
	# Set current weapon to FIRE
	Global.current_weapon = Global.WeaponType.FIRE
	print("Global weapon set to FIRE (", Global.current_weapon, ")")
	
	# Instantiate player
	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.global_position = Vector2(100.0, 300.0)
	add_child(player)
	
	# Fire twisting bullets
	var spawn_pos = Vector2(120.0, 300.0)
	var aim_dir = Vector2.RIGHT
	player._spawn_twisting_bullets(spawn_pos, aim_dir)
	
	# Find spawned bullets
	var bullets = []
	for child in get_children():
		if child.is_in_group("bullet"):
			bullets.append(child)
	
	print("Spawned bullets count: ", bullets.size())
	assert(bullets.size() == 2, "Expected 2 twisting bullets spawned")
	
	var b1 = bullets[0]
	var b2 = bullets[1]
	
	assert(b1.is_twisting and b2.is_twisting, "Both bullets must have is_twisting = true")
	assert(abs(b1.twist_phase - 0.0) < 0.001, "Bullet 1 phase must be 0")
	assert(abs(b2.twist_phase - PI) < 0.001, "Bullet 2 phase must be PI")
	assert(b1.weapon_type == Global.WeaponType.FIRE, "Weapon type must be FIRE")
	assert(b2.weapon_type == Global.WeaponType.FIRE, "Weapon type must be FIRE")
	
	print("Initial check passed: twin bullets with phase 0 and PI.")
	
	# Step through physics process and check corkscrew motion
	var dt = 0.016
	for step in range(30):
		b1._physics_process(dt)
		b2._physics_process(dt)
		
		# Offset check
		var offset1 = b1.global_position.y - b1.base_fwd_pos.y
		var offset2 = b2.global_position.y - b2.base_fwd_pos.y
		
		# In a double helix with phase difference PI: sin(theta) + sin(theta + PI) == 0
		var sum_offset = offset1 + offset2
		assert(abs(sum_offset) < 0.001, "Twisting bullets must be diametrically opposite on helical corkscrew! Step " + str(step) + " sum=" + str(sum_offset))
	
	print("Helical double-corkscrew symmetry verified across 30 physics steps!")
	print("Tail positions recorded: b1=", b1.tail_positions.size(), ", b2=", b2.tail_positions.size())
	assert(b1.tail_positions.size() > 0, "Tail positions must be recorded")
	
	# Test dummy enemy taking damage
	var enemy = Area2D.new()
	enemy.name = "DummyEnemy"
	var enemy_hp = 10.0
	var enemy_script = GDScript.new()
	enemy_script.source_code = """
extends Area2D
var hp: float = 10.0
func take_damage(amount: float) -> void:
	hp -= amount
"""
	enemy_script.reload()
	enemy.set_script(enemy_script)
	add_child(enemy)
	
	b1._handle_hit(enemy)
	print("Enemy HP after hit from Fire bullet (damage 2.4): ", enemy.hp)
	assert(abs(enemy.hp - 7.6) < 0.01, "Enemy should have taken 2.4 damage from Fire bullet")
	assert(b1.pierce_count == 1, "Fire bullet pierce count should decrement from 2 to 1")
	
	print("ALL TWISTING BULLET UNIT TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
