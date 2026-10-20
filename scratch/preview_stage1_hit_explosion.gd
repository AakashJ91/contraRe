extends Node

var frames: int = 0
var stage = null

func _ready() -> void:
	var stage_scene = load("res://scenes/stage1.tscn")
	stage = stage_scene.instantiate()
	add_child(stage)

func _process(_delta: float) -> void:
	frames += 1
	if frames == 15:
		# Trigger hit explosions directly on enemies and sensors across the frontline
		VFX.spawn_hit_explosion(Vector2(480.0, 310.0), 1.0) # On crawling enemy
		VFX.spawn_hit_explosion(Vector2(640.0, 260.0), 1.0) # On platform soldier
		VFX.spawn_hit_explosion(Vector2(380.0, 290.0), 1.0) # On powerup sensor
	
	if frames == 20:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/stage1_hit_explosion_live.png")
			print("Saved live gameplay screenshot to res://scratch/stage1_hit_explosion_live.png")
		get_tree().quit(0)
