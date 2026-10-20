extends Node2D

var frames_waited: int = 0

func _ready() -> void:
	pass

func _draw() -> void:
	# Dark retro arcade backdrop
	draw_rect(Rect2(0, 0, 960, 540), Color(0.06, 0.09, 0.14), true)
	for x in range(0, 960, 40):
		draw_line(Vector2(x, 0), Vector2(x, 540), Color(0.10, 0.14, 0.20), 1.0)
	for y in range(0, 540, 40):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.10, 0.14, 0.20), 1.0)
	
	# Platform ground line
	draw_line(Vector2(40, 360), Vector2(920, 360), Color(0.25, 0.65, 0.35), 3.5)

func _process(_delta: float) -> void:
	frames_waited += 1
	
	# Spawn at frame 1 once scene is fully in tree
	if frames_waited == 1:
		# 1. Soldier dying with skull smoke burst
		var soldier_scene = load("res://scenes/enemy_soldier.tscn")
		if soldier_scene != null:
			var s = soldier_scene.instantiate()
			s.global_position = Vector2(220, 360)
			add_child(s)
			s._die()
		
		# 2. Prominent Skull Smoke burst (mid animation, laughing skull)
		VFX.spawn_enemy_death_explosion(Vector2(480, 260), 1.8)
		
		# 3. Bunker Turret exploding with Skull Smoke
		var turret_scene = load("res://scenes/enemy_turret.tscn")
		if turret_scene != null:
			var t = turret_scene.instantiate()
			t.global_position = Vector2(740, 360)
			add_child(t)
			t._die()
	
	# Advance animation a few frames to let the skull form and laugh
	if frames_waited == 6:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/skull_smoke_preview.png")
			print("Saved screenshot to res://scratch/skull_smoke_preview.png")
		get_tree().quit(0)
