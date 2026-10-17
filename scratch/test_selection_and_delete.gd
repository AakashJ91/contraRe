extends Node

func _ready() -> void:
	print("--- BEGIN TEST: SELECTION AND DELETE IN CONTRA MAKER ---")
	
	# Instantiate ContraMaker scene
	var scn: PackedScene = load("res://scenes/contra_maker.tscn")
	assert(scn != null, "ContraMaker scene must load")
	var maker: ContraMaker = scn.instantiate()
	add_child(maker)
	
	# Create a dummy stage with camera
	var stage := Node2D.new()
	stage.name = "DummyStage"
	add_child(stage)
	
	var cam := Camera2D.new()
	stage.add_child(cam)
	
	maker.setup(stage, cam)
	maker.open_editor()
	assert(maker.is_active, "Editor must be active")
	
	# Setup test data:
	# Add a platform at (500, 280, 200, 16)
	maker.editor_platforms.clear()
	maker.editor_platforms.append({
		"rect": Rect2(500.0, 280.0, 200.0, 16.0),
		"type": 0 # TURF
	})
	
	# Add a background prop right behind/overlapping the platform
	maker.editor_bg_props.clear()
	maker.editor_bg_props.append({
		"type": "radar_dish",
		"pos": Vector2(550.0, 280.0)
	})
	
	# TEST 1: Platform Selection over background prop
	# Click directly on the platform where the prop also overlaps (550, 280)
	maker._select_item_at(Vector2(550.0, 280.0))
	assert(maker.selected_item_type == "platform", "Platform must take priority over background prop! Got: %s" % maker.selected_item_type)
	assert(maker.selected_item_idx == 0, "Selected platform index must be 0")
	print("✔ Test 1 Passed: Platform selected over background prop at overlapping coordinate.")
	
	# TEST 2: Platform Selection with vertical offsets
	# Click 20px above platform walking surface (550, 260)
	maker.selected_item_idx = -1
	maker.selected_item_type = ""
	maker._select_item_at(Vector2(550.0, 260.0))
	assert(maker.selected_item_type == "platform", "Platform must be selected 20px above surface! Got: %s" % maker.selected_item_type)
	print("✔ Test 2A Passed: Platform selected 20px above surface.")
	
	# Click 30px below platform walking surface (550, 310)
	maker.selected_item_idx = -1
	maker.selected_item_type = ""
	maker._select_item_at(Vector2(550.0, 310.0))
	assert(maker.selected_item_type == "platform", "Platform must be selected 30px below surface! Got: %s" % maker.selected_item_type)
	print("✔ Test 2B Passed: Platform selected 30px below surface.")
	
	# TEST 3: Multiple overlapping/adjacent platforms - reverse iteration & distance scoring
	# Add a second platform right above at (500, 200, 200, 16)
	maker.editor_platforms.append({
		"rect": Rect2(500.0, 200.0, 200.0, 16.0),
		"type": 2 # BRIDGE
	})
	# Clicking at (550, 205) should select the top platform (index 1)
	maker._select_item_at(Vector2(550.0, 205.0))
	assert(maker.selected_item_type == "platform" and maker.selected_item_idx == 1, "Expected top platform index 1, got: %d" % maker.selected_item_idx)
	print("✔ Test 3 Passed: Upper platform accurately selected.")
	
	# TEST 4: Delete Selected Item directly
	# Currently index 1 is selected. Call _delete_selected_item()
	maker._delete_selected_item()
	assert(maker.editor_platforms.size() == 1, "Platform count must be 1 after deletion")
	assert(maker.selected_item_idx == -1, "Selection must be reset after deletion")
	assert(maker.has_unsaved_changes, "Deleting item must mark has_unsaved_changes")
	print("✔ Test 4 Passed: Direct deletion deleted selected platform.")
	
	# TEST 5: Top Toolbar Delete Button click simulation
	# Select remaining platform (index 0)
	maker._select_item_at(Vector2(550.0, 280.0))
	assert(maker.selected_item_idx == 0, "Platform must be selected")
	# Click top toolbar delete button at (750, 20)
	maker._handle_toolbar_click(Vector2(750.0, 20.0))
	assert(maker.editor_platforms.size() == 0, "Platform must be deleted via top toolbar delete button")
	assert(maker.selected_item_idx == -1, "Selection must be reset")
	print("✔ Test 5 Passed: Top toolbar delete button deleted selected platform.")
	
	# TEST 6: Bottom Shelf Delete Button click simulation
	# Clear elements and add an enemy
	maker.editor_enemies.clear()
	maker.editor_platforms.clear()
	maker.editor_ground.clear()
	maker.editor_enemies.append({"type": "sniper", "pos": Vector2(600.0, 300.0)})
	maker._select_item_at(Vector2(600.0, 300.0))
	assert(maker.selected_item_type == "enemy" and maker.selected_item_idx == 0, "Enemy must be selected")
	# Click bottom shelf delete button at (800, 500)
	maker._handle_bottom_shelf_click(Vector2(800.0, 500.0))
	assert(maker.editor_enemies.size() == 0, "Enemy must be deleted via bottom shelf delete button")
	assert(maker.selected_item_idx == -1, "Selection must be reset")
	print("✔ Test 6 Passed: Bottom shelf delete button deleted selected enemy.")
	
	# TEST 7: Floating Delete Button simulation
	# Add a platform, select it, trigger draw to calculate floating delete button rect
	maker.editor_platforms.append({"rect": Rect2(400.0, 300.0, 160.0, 16.0), "type": 1})
	maker._select_item_at(Vector2(450.0, 300.0))
	assert(maker.selected_item_idx == 0, "Platform must be selected")
	var font = ThemeDB.fallback_font
	maker._draw_selection_and_cursor(font)
	assert(maker.selection_floating_del_rect.size.x > 0, "Floating delete button rect must be generated")
	print("Floating delete button rect: ", maker.selection_floating_del_rect)
	
	# Simulate mouse click on floating delete button
	var fake_click := InputEventMouseButton.new()
	fake_click.button_index = MOUSE_BUTTON_LEFT
	fake_click.pressed = true
	fake_click.position = maker.selection_floating_del_rect.get_center()
	maker._on_gui_input(fake_click)
	assert(maker.editor_platforms.size() == 0, "Platform must be deleted via floating delete button click")
	assert(maker.selected_item_idx == -1, "Selection must be reset")
	print("✔ Test 7 Passed: Floating delete button click deleted selected platform.")
	
	# Clean up
	maker.queue_free()
	stage.queue_free()
	
	print("--- ALL TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
