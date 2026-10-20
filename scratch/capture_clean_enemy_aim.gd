extends Node2D

var player: CharacterBody2D
var turret: Node2D
var drone: CharacterBody2D
var rail_turret: CharacterBody2D
var frame_count: int = 0

func _ready() -> void:
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(960, 540)
	bg.color = Color(0.08, 0.12, 0.16)
	add_child(bg)
	
	# Spawn player
	var player_scene = load("res://scenes/player.tscn")
	player = player_scene.instantiate()
	player.global_position = Vector2(180, 360)
	player.add_to_group("player")
	add_child(player)
	
	# Spawn enemy turret
	var turret_scene = load("res://scenes/enemy_turret.tscn")
	turret = turret_scene.instantiate()
	turret.global_position = Vector2(650, 360)
	turret.state = turret.TurretState.ACTIVE
	turret.deploy_progress = 1.0
	turret.burst_count = 3
	add_child(turret)
	
	# Spawn enemy drone
	var drone_scene = load("res://scenes/enemy_drone.tscn")
	drone = drone_scene.instantiate()
	drone.global_position = Vector2(480, 200)
	drone.target = player
	drone.state = drone.DroneState.LOCK_ON
	add_child(drone)
	
	# Spawn rail turret
	var rail_scene = load("res://scenes/enemy_rail_turret.tscn")
	rail_turret = rail_scene.instantiate()
	rail_turret.global_position = Vector2(800, 240)
	rail_turret.target = player
	add_child(rail_turret)

func _physics_process(_delta: float) -> void:
	frame_count += 1
	
	# Capture image after a few frames
	if frame_count == 15:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/clean_enemy_aim_preview.png")
			print("Clean enemy aim preview saved successfully!")
		get_tree().quit(0)
