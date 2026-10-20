extends Node2D

var player: CharacterBody2D
var sensors: Array[Node2D] = []
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
	player.global_position = Vector2(180, 270)
	add_child(player)
	
	# Set weapon to SPREAD
	Global.current_weapon = Global.WeaponType.SPREAD
	
	# Spawn 4 themed hover sensors (Stage 1 Military, Stage 2 Aqua, Stage 3 Alien, Stage 6 Tesla)
	var theme_stages = [1, 2, 3, 6]
	var sensor_scene = load("res://scenes/powerup_sensor.tscn")
	for i in range(theme_stages.size()):
		var st_idx = theme_stages[i]
		var s = sensor_scene.instantiate()
		var res_path = "res://resources/enemies/powerup_sensor_stage%d.tres" % st_idx
		if ResourceLoader.exists(res_path):
			s.sensor_data = load(res_path)
		s.global_position = Vector2(420.0 + float(i) * 120.0, 260.0)
		add_child(s)
		sensors.append(s)

func _physics_process(_delta: float) -> void:
	frame_count += 1
	
	# Fire spread gun at frame 3 and frame 12
	if frame_count == 3 or frame_count == 12:
		player.aim_dir = Vector2.RIGHT
		player._shoot()
	
	if frame_count == 20:
		var img = get_viewport().get_texture().get_image()
		img.save_png("scratch/spread_and_hover_sensor_preview.png")
		print("[TEST] Saved scratch/spread_and_hover_sensor_preview.png")
		get_tree().quit(0)
