extends Node2D

var frames: int = 0
var p1: Player = null
var p2: Player = null
var p3: Player = null

func _ready() -> void:
	var p_scene = load("res://scenes/player.tscn")
	
	# P1: Respawning / dropping
	p1 = p_scene.instantiate()
	p1.global_position = Vector2(250.0, 260.0)
	add_child(p1)
	p1.state = Player.PlayerState.RESPAWNING
	p1.respawn_timer = 2.0
	
	# P2: Standing Idle with Invulnerable / Invisible state active
	p2 = p_scene.instantiate()
	p2.global_position = Vector2(480.0, 300.0)
	add_child(p2)
	p2.state = Player.PlayerState.IDLE
	p2.is_invulnerable = true
	p2.invulnerable_timer = 2.0
	
	# P3: Running with Invulnerable / Invisible state active
	p3 = p_scene.instantiate()
	p3.global_position = Vector2(710.0, 300.0)
	add_child(p3)
	p3.state = Player.PlayerState.RUN
	p3.is_invulnerable = true
	p3.invulnerable_timer = 2.0
	p3.run_frame = 2.0

func _process(_delta: float) -> void:
	frames += 1
	if frames == 16:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/player_invisible_preview.png")
			print("SUCCESS: Saved player invisible state preview to res://scratch/player_invisible_preview.png")
		get_tree().quit(0)
