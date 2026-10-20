extends Node2D

var frames_waited: int = 0

func _ready() -> void:
	# Spawn all 7 themed explosions at staggered offsets to showcase their multi-frame blooms
	var items = [
		{"key": "fiery", "pos": Vector2(160.0, 140.0), "name": "FIERY INFERNO"},
		{"key": "electric", "pos": Vector2(480.0, 140.0), "name": "TESLA EMP"},
		{"key": "alien", "pos": Vector2(800.0, 140.0), "name": "BIO-ACID ALIEN"},
		{"key": "cryo", "pos": Vector2(160.0, 380.0), "name": "CRYO FROST"},
		{"key": "magma", "pos": Vector2(480.0, 380.0), "name": "MAGMA VOLCANIC"},
		{"key": "nuclear", "pos": Vector2(780.0, 380.0), "name": "NUCLEAR MEGA"},
		{"key": "mini", "pos": Vector2(480.0, 260.0), "name": "MINI IMPACT"}
	]
	
	for it in items:
		VFX.spawn_explosion_by_name(it["pos"], it["key"])
	
	# Advance 8 frames so the explosion reaches full bloom
	var vfx_parent = VFX._get_vfx_parent()
	for child in vfx_parent.get_children():
		if child is VFX.AnimatedExplosionEffect:
			for s in range(8):
				child._process(0.016)

func _draw() -> void:
	# Dark retro sci-fi grid backdrop
	draw_rect(Rect2(0, 0, 960, 540), Color(0.04, 0.05, 0.08), true)
	for x in range(0, 960, 48):
		draw_line(Vector2(x, 0), Vector2(x, 540), Color(0.09, 0.12, 0.18), 1.0)
	for y in range(0, 540, 48):
		draw_line(Vector2(0, y), Vector2(960, y), Color(0.09, 0.12, 0.18), 1.0)
	
	# Header title banner
	draw_rect(Rect2(0, 0, 960, 36), Color(0.08, 0.10, 0.16), true)
	draw_line(Vector2(0, 36), Vector2(960, 36), Color(0.3, 0.5, 0.8), 2.0)
	
	# Display title
	draw_string(ThemeDB.fallback_font, Vector2(300, 24), "CONTRA RE - NEW EXPLOSION VFX RESOURCES", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1.0, 0.9, 0.4))
	
	# Labels for each explosion
	var labels = [
		{"pos": Vector2(160, 205), "txt": "ARCADE FIERY"},
		{"pos": Vector2(480, 205), "txt": "ELECTRIC TESLA"},
		{"pos": Vector2(800, 205), "txt": "BIO-ACID ALIEN"},
		{"pos": Vector2(160, 455), "txt": "CRYO FROST"},
		{"pos": Vector2(480, 455), "txt": "MAGMA VOLCANIC"},
		{"pos": Vector2(780, 470), "txt": "NUCLEAR MEGA"},
		{"pos": Vector2(480, 295), "txt": "MINI IMPACT"}
	]
	for l in labels:
		draw_string(ThemeDB.fallback_font, l["pos"] + Vector2(-60, 0), l["txt"], HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.8, 0.9, 1.0))

func _process(_delta: float) -> void:
	frames_waited += 1
	if frames_waited == 4:
		var img = get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://scratch/explosion_vfx_resources_showcase.png")
			print("Saved showcase screenshot to res://scratch/explosion_vfx_resources_showcase.png")
		get_tree().quit(0)
