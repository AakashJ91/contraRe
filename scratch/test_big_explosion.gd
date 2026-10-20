extends Node2D

var frames: int = 0

func _ready() -> void:
	Global.current_stage = 1
	# Spawn a big explosion centered for inspection
	if has_node("/root/VFX"):
		VFX.spawn_big_explosion(Vector2(320.0, 300.0), 1.0)
		VFX.spawn_big_explosion(Vector2(640.0, 300.0), 1.35)

func _process(_delta: float) -> void:
	frames += 1
	if frames == 18:
		# Frame 18 is around the peak fireball / expanding shrapnel phase
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/big_explosion_preview.png")
			print("SUCCESS: Saved big explosion preview to res://scratch/big_explosion_preview.png")
		get_tree().quit(0)
