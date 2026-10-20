extends Node2D

var frames_waited: int = 0
var player: Node2D = null

func _ready() -> void:
	Global.current_weapon = Global.WeaponType.FIRE
	var player_scene = load("res://scenes/player.tscn")
	player = player_scene.instantiate()
	player.global_position = Vector2(180.0, 320.0)
	add_child(player)
	
	# Spawn multiple waves of twisting bullets to show the beautiful corkscrew pattern in full flight
	# First wave (advanced down range)
	player._spawn_twisting_bullets(Vector2(200.0, 310.0), Vector2.RIGHT)
	# Advance them
	for child in get_children():
		if child.is_in_group("bullet"):
			for s in range(22):
				child._physics_process(0.016)
	
	# Second wave (mid range)
	player._spawn_twisting_bullets(Vector2(200.0, 310.0), Vector2.RIGHT)
	var count = 0
	for child in get_children():
		if child.is_in_group("bullet"):
			count += 1
			if count > 2:
				for s in range(11):
					child._physics_process(0.016)
	
	# Third wave (freshly emerging from gun muzzle)
	player._spawn_twisting_bullets(Vector2(200.0, 310.0), Vector2.RIGHT)
	VFX.spawn_muzzle_flash(Vector2(200.0, 310.0), Vector2.RIGHT, 4)

func _draw() -> void:
	# Dark retro background grid to make the fiery incandescent corkscrew pop
	draw_rect(Rect2(0, 0, 960, 540), Color(0.05, 0.07, 0.12), true)
	for x in range(0, 960, 40):
		draw_line(Vector2(x, 0), Vector2(x, 540), Color(0.12, 0.16, 0.22), 1.0)
	for y in range(0, 540, 40):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.12, 0.16, 0.22), 1.0)
	
	# Ground line
	draw_line(Vector2(0, 340), Vector2(960, 340), Color(0.2, 0.6, 0.3), 3.0)

func _process(_delta: float) -> void:
	frames_waited += 1
	if frames_waited == 5:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/twisting_bullet_preview.png")
			print("Saved screenshot to res://scratch/twisting_bullet_preview.png")
		else:
			print("Viewport image is null")
		get_tree().quit(0)
