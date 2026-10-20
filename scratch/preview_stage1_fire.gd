extends Node

var frames: int = 0
var stage = null

func _ready() -> void:
	Global.current_weapon = Global.WeaponType.FIRE
	var stage_scene = load("res://scenes/stage1.tscn")
	stage = stage_scene.instantiate()
	add_child(stage)

func _process(_delta: float) -> void:
	frames += 1
	if stage != null and "player" in stage and stage.player != null and is_instance_valid(stage.player):
		stage.player.aim_dir = Vector2.RIGHT
		if frames % 8 == 0:
			stage.player._shoot()
	
	if frames == 70:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/stage1_twisting_fire_live.png")
			print("Saved live gameplay screenshot to res://scratch/stage1_twisting_fire_live.png")
		get_tree().quit(0)
