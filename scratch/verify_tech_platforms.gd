extends Node2D

var stage: Node2D = null
var timer: float = 0.0

func _ready() -> void:
	print("VERIFY_TECH_PLATFORMS: Initializing test...")
	RenderingServer.set_default_clear_color(Color(0.08, 0.10, 0.14, 1.0))
	var stage_scene = load("res://scenes/stage1.tscn")
	stage = stage_scene.instantiate()
	add_child(stage)

func _process(delta: float) -> void:
	timer += delta
	if timer > 0.2:
		print("VERIFY_TECH_PLATFORMS: Verifying textures...")
		print("  platform_tech_texture:", stage.platform_tech_texture != null)
		print("  platform_tech_catwalk_texture:", stage.platform_tech_catwalk_texture != null)
		var img := get_viewport().get_texture().get_image()
		img.save_png("scratch/tech_platforms_verified.png")
		print("VERIFY_TECH_PLATFORMS: Saved scratch/tech_platforms_verified.png")
		get_tree().quit(0)
