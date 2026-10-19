extends SceneTree

var current_st := 1
var frames_waited := 0
var stage_node: Node2D = null

func _init() -> void:
	print("Starting screenshot capture of stages...")
	_load_stage(1)

func _load_stage(stage_id: int) -> void:
	current_st = stage_id
	frames_waited = 0
	Global.current_stage = stage_id
	Global.player_lives = 3
	
	if stage_node != null:
		root.remove_child(stage_node)
		stage_node.queue_free()
		stage_node = null
	
	var stage_scene := load("res://scenes/stage1.tscn") as PackedScene
	if stage_scene == null:
		print("ERROR: could not load stage1.tscn")
		quit()
		return
	
	stage_node = stage_scene.instantiate() as Node2D
	root.add_child(stage_node)
	print("Loaded Stage %d" % stage_id)

func _process(_delta: float) -> bool:
	frames_waited += 1
	# Wait 10 frames for rendering and textures to settle
	if frames_waited == 10:
		var img := root.get_viewport().get_texture().get_image()
		var save_path := "scratch/stage_%d_ingame.png" % current_st
		img.save_png(save_path)
		print("Saved screenshot: %s" % save_path)
		
		if current_st < 8:
			_load_stage(current_st + 1)
		else:
			print("All stage screenshots captured!")
			quit()
	return false
