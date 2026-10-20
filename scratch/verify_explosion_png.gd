extends Node2D

var vfx_mgr: Node = null
var step: int = 0
var timer: float = 0.0

func _ready() -> void:
	print("VERIFY_EXPLOSION_PNG: Starting test...")
	RenderingServer.set_default_clear_color(Color(0.08, 0.09, 0.12, 1.0))
	var vfx_script = load("res://scripts/vfx_manager.gd")
	vfx_mgr = vfx_script.new()
	vfx_mgr.name = "VFX"
	add_child(vfx_mgr)

func _process(delta: float) -> void:
	timer += delta
	if step == 0 and timer > 0.1:
		step = 1
		print("VERIFY_EXPLOSION_PNG: Spawning standard explosion using explosion.png...")
		if vfx_mgr != null:
			vfx_mgr.spawn_explosion(Vector2(200.0, 160.0), 1.5)
			vfx_mgr.spawn_explosion(Vector2(320.0, 160.0), 1.0)
			vfx_mgr.spawn_explosion(Vector2(440.0, 160.0), 2.0)
	elif step == 1 and timer > 0.35:
		step = 2
		print("VERIFY_EXPLOSION_PNG: Capturing frame at peak explosion animation...")
		var img := get_viewport().get_texture().get_image()
		img.save_png("scratch/explosion_png_verified.png")
		print("VERIFY_EXPLOSION_PNG: Saved scratch/explosion_png_verified.png successfully!")
		get_tree().quit()
