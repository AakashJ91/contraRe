extends Node2D

var frames: int = 0
var boss: Node2D = null

func _ready() -> void:
	Global.current_stage = 2
	var boss_scene = load("res://scenes/boss.tscn")
	boss = boss_scene.instantiate()
	boss.global_position = Vector2(350.0, 320.0)
	add_child(boss)
	
	# Destroy both side cannons on Hydro Mech
	boss.left_part_hp = 0.0
	boss.right_part_hp = 0.0
	boss.current_health = boss.max_health * 0.35
	
	# Also spawn a bursting fire effect from VFX manager directly beside the boss
	if has_node("/root/VFX"):
		VFX.spawn_boss_fire(Vector2(550.0, 320.0), 1.0, 3.0)
		VFX.spawn_boss_fire(Vector2(550.0, 420.0), 0.75, 3.0)

func _process(_delta: float) -> void:
	frames += 1
	if frames == 25:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/boss_fire_preview.png")
			print("SUCCESS: Saved boss fire preview screenshot to res://scratch/boss_fire_preview.png")
		get_tree().quit(0)
