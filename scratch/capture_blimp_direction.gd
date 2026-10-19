extends Node2D

var frames_waited = 0

func _ready():
	print("[BLIMP TEST] Loading Stage 2 main scene...")
	Global.current_stage = 2
	var main_scn = load("res://scenes/main.tscn")
	var main_inst = main_scn.instantiate()
	add_child(main_inst)

func _process(_delta):
	frames_waited += 1
	# Capture at frame 25 so background vehicle has spawned and moved
	if frames_waited == 25:
		var img = get_viewport().get_texture().get_image()
		img.save_png("scratch/blimp_forward_test.png")
		print("[BLIMP TEST] Saved scratch/blimp_forward_test.png")
		get_tree().quit(0)
