extends Node

var frames: int = 0
var stage = null

func _ready() -> void:
	var stage_scene = load("res://scenes/stage1.tscn")
	stage = stage_scene.instantiate()
	add_child(stage)

func _process(_delta: float) -> void:
	frames += 1
	if frames == 20:
		# Trigger standard explosions (explosion.png)
		VFX.spawn_explosion(Vector2(460.0, 310.0), 1.5)
		VFX.spawn_explosion(Vector2(620.0, 260.0), 1.2)
	
	if frames == 35:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/stage1_new_explosion_live.png")
			print("Saved live gameplay screenshot to res://scratch/stage1_new_explosion_live.png")
		get_tree().quit(0)
