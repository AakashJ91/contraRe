extends Node2D

var frames: int = 0
var mini_boss: Node2D = null
var boss: Node2D = null

func _ready() -> void:
	Global.current_stage = 1
	
	# Spawn mini-boss
	var mb_scene = load("res://scenes/mini_boss.tscn")
	mini_boss = mb_scene.instantiate()
	mini_boss.global_position = Vector2(300.0, 360.0)
	add_child(mini_boss)
	mini_boss.is_active = true
	# Trigger death with only 1 chain explosion left so the final big explosion fires immediately
	mini_boss._trigger_death()
	mini_boss.death_explosions_left = 1
	mini_boss.death_chain_timer = 0.02
	
	# Spawn main boss
	var b_scene = load("res://scenes/boss.tscn")
	boss = b_scene.instantiate()
	boss.global_position = Vector2(720.0, 340.0)
	add_child(boss)
	boss.is_active = true
	boss._trigger_death()
	boss.death_explosions_left = 1
	boss.death_chain_timer = 0.02

func _process(_delta: float) -> void:
	frames += 1
	if frames == 14:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/boss_and_miniboss_death_preview.png")
			print("SUCCESS: Saved live boss and mini-boss final death explosion screenshot to res://scratch/boss_and_miniboss_death_preview.png")
		get_tree().quit(0)
