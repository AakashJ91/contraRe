extends Node2D

var stage_scene: Node2D
var timer: float = 0.0

func _ready() -> void:
	Global.current_stage = 1
	Global.current_weapon = Global.WeaponType.SPREAD
	var s_scene = load("res://scenes/stage1.tscn")
	stage_scene = s_scene.instantiate()
	add_child(stage_scene)

func _physics_process(delta: float) -> void:
	timer += delta
	
	# After 0.5s, simulate player shooting spread bullets
	if stage_scene != null and "player" in stage_scene and stage_scene.player != null:
		var p = stage_scene.player
		if timer > 0.4 and timer < 1.2:
			p.aim_dir = Vector2.RIGHT
			if p.shoot_cooldown <= 0.0:
				p._shoot()
	
	if timer >= 1.5:
		var img = get_viewport().get_texture().get_image()
		img.save_png("scratch/stage1_hover_sensor_live.png")
		print("[TEST] Saved scratch/stage1_hover_sensor_live.png")
		get_tree().quit(0)
