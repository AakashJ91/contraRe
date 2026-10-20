extends Node2D

var frames_waited: int = 0

func _ready() -> void:
	print("--- TESTING HIT EXPLOSION AT PEAK BLOOM ---")
	if not has_node("/root/VFX"):
		get_tree().quit(1)
		return
	
	# Spawn a row of hit explosions at different scales
	VFX.spawn_hit_explosion(Vector2(200.0, 200.0), 1.0)
	VFX.spawn_hit_explosion(Vector2(320.0, 200.0), 1.25)
	VFX.spawn_hit_explosion(Vector2(460.0, 200.0), 1.6)

func _process(_delta: float) -> void:
	frames_waited += 1
	# Capture at frame 3 (peak bright blast bloom)
	if frames_waited == 3:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/hit_explosion_bloom_verified.png")
			print("Saved scratch/hit_explosion_bloom_verified.png successfully!")
		get_tree().quit(0)
