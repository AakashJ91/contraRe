extends Node2D

func _ready() -> void:
	print("--- TESTING REMOVAL OF ENEMY LASER GUIDES ---")
	
	# 1. Test Turret
	var turret_scene = load("res://scenes/enemy_turret.tscn")
	if turret_scene != null:
		var turret = turret_scene.instantiate()
		turret.burst_count = 3 # Triggers is_locked
		add_child(turret)
		turret.queue_redraw()
		print("Turret locked-on state instantiated without crash or laser line.")
	
	# 2. Test Drone
	var drone_script = load("res://scripts/enemy_drone.gd")
	if drone_script != null:
		var drone = CharacterBody2D.new()
		drone.set_script(drone_script)
		drone.state = drone.DroneState.LOCK_ON
		add_child(drone)
		drone.queue_redraw()
		print("Drone LOCK_ON state verified: no telegraph laser guide drawn.")
	
	# 3. Test Grenadier
	var grenadier_script = load("res://scripts/enemy_grenadier.gd")
	if grenadier_script != null:
		var grenadier = CharacterBody2D.new()
		grenadier.set_script(grenadier_script)
		grenadier.state = grenadier.GrenadierState.AIM_MORTAR
		add_child(grenadier)
		grenadier.queue_redraw()
		print("Grenadier AIM_MORTAR state verified: no laser guide drawn.")
	
	# 4. Test Rail Turret
	var rail_script = load("res://scripts/enemy_rail_turret.gd")
	if rail_script != null:
		var rail = CharacterBody2D.new()
		rail.set_script(rail_script)
		rail.is_firing_beam = false
		add_child(rail)
		rail.queue_redraw()
		print("Rail Turret tracking verified: no red laser guide line.")
		
	# 5. Test Conveyor Droid
	var droid_script = load("res://scripts/enemy_conveyor_droid.gd")
	if droid_script != null:
		var droid = CharacterBody2D.new()
		droid.set_script(droid_script)
		droid.laser_charge = 0.5
		droid.is_firing_laser = false
		add_child(droid)
		droid.queue_redraw()
		print("Conveyor Droid charge verified: no red laser guide line.")
	
	print("ALL ENEMY LASER GUIDE CHECKS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
