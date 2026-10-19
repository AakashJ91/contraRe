extends SceneTree

func _init() -> void:
	print("--- Running test_level_maps ---")
	for s in range(1, 9):
		var data = LevelMaps.get_default_map_data(s)
		print("Stage %d: '%s', grounds=%d, platforms=%d" % [s, data["name"], data["ground_segments"].size(), data["platforms"].size()])
	print("--- All stages loaded successfully! ---")
	quit()
