extends Node2D

var frames_waited: int = 0

func _draw() -> void:
	# Dark retro arcade backdrop
	draw_rect(Rect2(0, 0, 960, 540), Color(0.06, 0.08, 0.12), true)
	for x in range(0, 960, 40):
		draw_line(Vector2(x, 0), Vector2(x, 540), Color(0.10, 0.13, 0.18), 1.0)
	for y in range(0, 540, 40):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.10, 0.13, 0.18), 1.0)
	
	# Ground line
	draw_line(Vector2(40, 380), Vector2(920, 380), Color(0.20, 0.55, 0.30), 3.5)

func _process(_delta: float) -> void:
	frames_waited += 1
	
	if frames_waited == 1:
		# LEFT SIDE: Enemy Deaths showing Skull Smoke (skullsmoke.png 64x64)
		var soldier_scene = load("res://scenes/enemy_soldier.tscn")
		if soldier_scene != null:
			var s = soldier_scene.instantiate()
			s.global_position = Vector2(160, 380)
			add_child(s)
			s._die()
			
		VFX.spawn_enemy_death_explosion(Vector2(320, 260), 1.6)
		
		# RIGHT SIDE: Other Explosions (explosion.png 64x64) - weapon blast, grenade, hazard
		VFX.spawn_explosion(Vector2(580, 260), 1.6)
		VFX.spawn_explosion(Vector2(800, 360), 1.4)
		
	if frames_waited == 6:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/explosions_dual_showcase.png")
			print("Saved screenshot to res://scratch/explosions_dual_showcase.png")
		get_tree().quit(0)
