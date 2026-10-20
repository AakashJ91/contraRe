extends Node

var frames: int = 0
var stage = null

func _ready() -> void:
	var stage_scene = load("res://scenes/stage1.tscn")
	stage = stage_scene.instantiate()
	add_child(stage)

func _process(_delta: float) -> void:
	frames += 1
	# On tick 20-30, player is on the ground in Stage 1 with respawn invulnerability / invisible sparkle state active
	if frames == 25:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/stage1_live_invisible_respawn.png")
			print("SUCCESS: Saved live Stage 1 respawn invisible screenshot to res://scratch/stage1_live_invisible_respawn.png")
		get_tree().quit(0)
