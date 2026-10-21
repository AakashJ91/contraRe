extends SceneTree

func _init() -> void:
	print("--- TESTING TECH PLATFORMS ---")
	var stage_script = load("res://scripts/stage1.gd")
	if stage_script == null:
		print("FAILED to load stage1.gd")
		quit(1)
		return
	var stage = Node2D.new()
	stage.set_script(stage_script)
	
	# Test loading textures
	stage._load_textures()
	print("platform_tech_texture:", stage.platform_tech_texture != null)
	print("platform_tech_catwalk_texture:", stage.platform_tech_catwalk_texture != null)
	assert(stage.platform_tech_texture != null, "platform_tech_texture is null!")
	assert(stage.platform_tech_catwalk_texture != null, "platform_tech_catwalk_texture is null!")
	
	# Test platform parsing
	print("parse tech:", stage._parse_platform_type("tech"))
	print("parse platform_tech:", stage._parse_platform_type("platform_tech"))
	print("parse catwalk:", stage._parse_platform_type("catwalk"))
	print("parse TECH_CATWALK int:", stage._parse_platform_type(7))
	assert(stage._parse_platform_type("tech") == 7)
	assert(stage._parse_platform_type("platform_tech") == 7)
	assert(stage._parse_platform_type("catwalk") == 7)
	assert(stage._parse_platform_type(7) == 7)
	
	# Test stage geometry init
	var global_script = load("res://scripts/global.gd")
	var g_inst = Node.new()
	g_inst.set_script(global_script)
	root.add_child(g_inst)
	stage._init_stage_geometry()
	print("Stage 1 platforms loaded count:", stage.platforms.size())
	
	var high_perch_count := 0
	for p in stage.platforms:
		if p["type"] == 3: # HIGH_PERCH
			high_perch_count += 1
	print("Stage 1 high perch platforms count:", high_perch_count)
	assert(high_perch_count >= 4, "High perch count should be at least 4 in Stage 1!")
	
	print("ALL TECH PLATFORM TESTS PASSED!")
	quit(0)
