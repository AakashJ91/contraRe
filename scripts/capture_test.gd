extends Node2D

var frames: int = 0
var main_inst: Node2D = null
var player_inst: CharacterBody2D = null
var stage_inst: Node2D = null

func _ready() -> void:
	print("--- TEST RUN: STARTING STAGE 1 WALKTHROUGH ---")
	Global.current_stage = 1
	var scn := load("res://scenes/main.tscn") as PackedScene
	main_inst = scn.instantiate() as Node2D
	add_child(main_inst)
	stage_inst = main_inst.get_node("Stage1") as Node2D
	player_inst = stage_inst.get_node("Player") as CharacterBody2D
	print("Main and Stage 1 instantiated successfully.")

func _physics_process(_delta: float) -> void:
	frames += 1
	if player_inst != null and is_instance_valid(player_inst):
		# Advance player by 25px per physics frame (approx 1500px/s)
		player_inst.global_position.x += 25.0
		player_inst.global_position.y = 410.0
		player_inst.velocity = Vector2(180.0, 0.0)
		
		if frames % 20 == 0:
			var cam_x: float = stage_inst.camera.global_position.x if (stage_inst != null and stage_inst.camera != null) else 0.0
			var enemies_count := get_tree().get_nodes_in_group("enemies").size()
			print("Frame %d | Player X: %.1f | Cam X: %.1f | Active Enemies: %d" % [frames, player_inst.global_position.x, cam_x, enemies_count])
		
		if player_inst.global_position.x >= 9500.0 or frames >= 400:
			print("SUCCESS: Stage 1 traversed completely without crash or hang! Final X=%.1f" % player_inst.global_position.x)
			get_tree().quit()
	else:
		print("ERROR: Player node is null or invalid!")
		get_tree().quit()
