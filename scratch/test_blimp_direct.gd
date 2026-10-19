extends Node2D

func _ready():
	var fleet = BackgroundSkyFleet.new()
	add_child(fleet)
	
	# Spawn 1 blimp flying right (dir = 1.0) and 1 blimp flying left (dir = -1.0)
	fleet.flyers.clear()
	fleet.flyers.append({
		"type": "blimp",
		"x": 300.0,
		"y": 150.0,
		"base_y": 150.0,
		"speed": 0.0,
		"direction": 1.0, # Flying right
		"anim_timer": 0.0,
		"anim_fps": 6.0,
		"is_gliding": false,
		"glide_timer": 0.0,
		"bob_freq": 1.0,
		"bob_amp": 0.0,
		"bob_phase": 0.0,
		"scale": Vector2(1.5, 1.5),
		"tint": Color.WHITE,
		"time_alive": 0.0,
		"trail": [],
		"trail_timer": 0.0
	})
	
	fleet.flyers.append({
		"type": "blimp",
		"x": 600.0,
		"y": 150.0,
		"base_y": 150.0,
		"speed": 0.0,
		"direction": -1.0, # Flying left
		"anim_timer": 0.0,
		"anim_fps": 6.0,
		"is_gliding": false,
		"glide_timer": 0.0,
		"bob_freq": 1.0,
		"bob_amp": 0.0,
		"bob_phase": 0.0,
		"scale": Vector2(1.5, 1.5),
		"tint": Color.WHITE,
		"time_alive": 0.0,
		"trail": [],
		"trail_timer": 0.0
	})

func _process(_delta):
	if Engine.get_process_frames() == 10:
		var img = get_viewport().get_texture().get_image()
		img.save_png("scratch/blimps_both_directions.png")
		print("[TEST] Saved scratch/blimps_both_directions.png")
		get_tree().quit(0)
