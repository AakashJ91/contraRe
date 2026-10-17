class_name ContraMaker
extends CanvasLayer

# =============================================================================
# CONTRA MAKER - IN-GAME TACTICAL LEVEL EDITOR
# =============================================================================

signal test_play_requested(player_spawn_pos: Vector2)
signal test_stop_requested()
signal level_data_modified()

enum ToolType {
	SELECT_MOVE,
	PLATFORM,
	GROUND,
	ENEMY,
	POWERUP,
	BG_PROP,
	ERASE
}

var stage: Node2D = null
var camera: Camera2D = null

var is_active: bool = false
var is_test_playing: bool = false

# Current active tool selection
var current_tool: ToolType = ToolType.SELECT_MOVE
var selected_platform_type: int = 0
var selected_enemy_type: String = "soldier"
var selected_powerup_type: int = 1 # 1: SPREAD, 2: MACHINE, 3: LASER
var selected_prop_type: String = "radar_dish"
var grid_snap: int = 32 # 32, 16, 0

# Camera navigation in editor
var cam_x: float = 480.0
var cam_pan_speed: float = 650.0
var is_panning_cam: bool = false
var pan_drag_start: Vector2 = Vector2.ZERO
var pan_cam_start_x: float = 480.0

# Mouse interaction in world space
var is_drawing_rect: bool = false
var draw_rect_start: Vector2 = Vector2.ZERO
var draw_rect_current: Vector2 = Vector2.ZERO

var mouse_screen_pos: Vector2 = Vector2(-1000.0, -1000.0)
var mouse_world_pos: Vector2 = Vector2(-1000.0, -1000.0)
var snapped_world_pos: Vector2 = Vector2(-1000.0, -1000.0)
var is_mouse_in_viewport: bool = false

var hovered_item_type: String = ""
var hovered_item_idx: int = -1
var selected_item_type: String = ""
var selected_item_idx: int = -1
var is_moving_item: bool = false
var move_start_mouse: Vector2 = Vector2.ZERO
var move_original_rect: Rect2 = Rect2()
var move_original_pos: Vector2 = Vector2.ZERO

# Notification toast
var toast_message: String = ""
var toast_timer: float = 0.0

# Level elements editable in memory
var editor_ground: Array[Rect2] = []
var editor_platforms: Array[Dictionary] = []
var editor_enemies: Array[Dictionary] = []
var editor_powerups: Array[Dictionary] = []
var editor_bg_props: Array[Dictionary] = []

const PLATFORM_NAMES: Array[String] = [
	"TURF", "GIRDER", "BRIDGE", "PERCH", "ICE", "LAVA", "ENERGY", "TECH", "BIO"
]

const ENEMY_TYPES: Array[String] = [
	"soldier", "sniper", "turret", "grenadier", "crawler", "drone"
]

const ENEMY_LABELS: Array[String] = [
	"SOLDIER", "SNIPER", "TURRET", "GRENADIER", "CRAWLER", "DRONE"
]

const POWERUP_NAMES: Array[String] = [
	"SPREAD GUN", "MACHINE GUN", "LASER BEAM"
]

const PROP_TYPES: Array[String] = [
	"radar_dish", "industrial_fan", "warning_beacon", "steam_vent", "flickering_terminal", "alien_core", "electric_arc",
	"bird_flock", "alien_bat", "stealth_jet", "recon_blimp", "sky_vtol",
	"water_surface", "waterfall_cascade", "water_ripple"
]

const PROP_LABELS: Array[String] = [
	"RADAR", "FAN", "BEACON", "STEAM", "TERMINAL", "CORE", "E-ARC",
	"BIRDS", "BIO-BAT", "JET", "BLIMP", "VTOL",
	"W-WAVE", "W-FALL", "RIPPLE"
]

const PROP_RESOURCES: Dictionary = {
	"radar_dish": "res://resources/bg_props/radar_dish.tres",
	"industrial_fan": "res://resources/bg_props/industrial_fan.tres",
	"warning_beacon": "res://resources/bg_props/warning_beacon.tres",
	"steam_vent": "res://resources/bg_props/steam_vent.tres",
	"flickering_terminal": "res://resources/bg_props/flickering_terminal.tres",
	"alien_core": "res://resources/bg_props/alien_core.tres",
	"electric_arc": "res://resources/bg_props/electric_arc.tres",
	"bird_flock": "res://resources/bg_props/bird_flock.tres",
	"alien_bat": "res://resources/bg_props/alien_bat.tres",
	"stealth_jet": "res://resources/bg_props/stealth_jet.tres",
	"recon_blimp": "res://resources/bg_props/recon_blimp.tres",
	"sky_vtol": "res://resources/bg_props/sky_vtol.tres",
	"water_surface": "res://resources/bg_props/water_surface.tres",
	"waterfall_cascade": "res://resources/bg_props/waterfall_cascade.tres",
	"water_ripple": "res://resources/bg_props/water_ripple.tres"
}

# Control node for drawing editor overlay
var overlay_control: Control = null

func _init() -> void:
	layer = 20

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	overlay_control = Control.new()
	overlay_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_control.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay_control.draw.connect(_on_overlay_draw)
	overlay_control.gui_input.connect(_on_gui_input)
	add_child(overlay_control)
	
	visible = is_active
	set_process_unhandled_input(true)

func setup(stage_node: Node2D, camera_node: Camera2D) -> void:
	stage = stage_node
	camera = camera_node
	if camera != null:
		cam_x = camera.global_position.x

func open_editor() -> void:
	is_active = true
	is_test_playing = false
	visible = true
	Global.is_maker_mode = true
	
	# Silence and remove touch controls in edit mode
	var tc = get_tree().root.find_child("TouchControls", true, false)
	if tc != null:
		tc.visible = false
		if tc.has_method("_reset_all_inputs"):
			tc._reset_all_inputs()
	
	if camera != null:
		cam_x = camera.global_position.x
	
	# Clear active enemy bullets when entering editor
	if stage != null:
		for child in stage.get_children():
			if child.is_in_group("bullet") or child.name.to_lower().contains("bullet"):
				child.queue_free()
	
	if editor_ground.is_empty() and editor_platforms.is_empty():
		_load_current_stage_geometry()
	
	show_toast("CONTRA MAKER ACTIVATED - SELECTOR READY")
	overlay_control.queue_redraw()

func close_editor() -> void:
	is_active = false
	is_test_playing = false
	visible = false
	Global.is_maker_mode = false
	
	# Restore touch controls for normal gameplay
	var tc = get_tree().root.find_child("TouchControls", true, false)
	if tc != null:
		tc.visible = true
	
	# If stage has no active combat enemies, spawn from editor_enemies so edited level is immediately active
	if stage != null:
		var enemy_count := 0
		for child in stage.get_children():
			if _is_enemy_node(child):
				enemy_count += 1
		if enemy_count == 0:
			_spawn_editor_enemies_for_test()
	
	overlay_control.queue_redraw()

func _load_current_stage_geometry() -> void:
	editor_ground.clear()
	editor_platforms.clear()
	editor_enemies.clear()
	editor_powerups.clear()
	
	if stage != null and "ground_segments" in stage and "platforms" in stage:
		for g in stage.ground_segments:
			editor_ground.append(g)
		for p in stage.platforms:
			editor_platforms.append(p.duplicate(true))
	
	# Load default stage enemies if not already customized
	var map_info := LevelMaps.get_map_data(Global.current_stage)
	for i in range(8):
		var g_list: Array = map_info.get("ground_segments", [])
		if not g_list.is_empty():
			var seg_idx := mini(i, g_list.size() - 1)
			var g: Rect2 = g_list[seg_idx]
			# Add turret
			editor_enemies.append({"type": "turret", "pos": Vector2(g.position.x + g.size.x * 0.65, 435.0)})
			if i % 2 == 1:
				editor_enemies.append({"type": "grenadier", "pos": Vector2(g.position.x + g.size.x * 0.35, 420.0)})
				editor_enemies.append({"type": "crawler", "pos": Vector2(g.position.x + g.size.x * 0.20, 425.0)})
		
		var p_list: Array = map_info.get("platforms", [])
		if i < p_list.size():
			var p: Rect2 = p_list[i * 2 % p_list.size()]["rect"]
			editor_enemies.append({"type": "sniper", "pos": Vector2(p.position.x + p.size.x * 0.5, p.position.y - 12.0)})
		
		if i % 3 == 0:
			editor_enemies.append({"type": "drone", "pos": Vector2(float(i) * 750.0 + 400.0, 160.0)})
	
	for k in range(4):
		editor_powerups.append({
			"type": (k % 3) + 1,
			"pos": Vector2(float(k) * 1400.0 + 600.0, 290.0)
		})
	
	_apply_to_stage()

func _apply_to_stage() -> void:
	if stage == null:
		return
	
	stage.ground_segments.clear()
	for g in editor_ground:
		stage.ground_segments.append(g)
	
	stage.platforms.clear()
	for p in editor_platforms:
		stage.platforms.append(p.duplicate(true))
	
	if stage.has_method("_setup_colliders"):
		stage._setup_colliders()
	
	_sync_editor_bg_props_to_stage()
	
	stage.queue_redraw()
	level_data_modified.emit()

func _sync_editor_bg_props_to_stage() -> void:
	if stage == null:
		return
	
	for child in stage.get_children():
		if child.is_in_group("custom_editor_props"):
			child.queue_free()
	
	var prop_scene: PackedScene = load("res://scenes/animated_bg_prop.tscn")
	if prop_scene == null:
		return
	
	for bp in editor_bg_props:
		var ptype: String = bp.get("type", "radar_dish")
		var ppos: Vector2 = bp.get("pos", Vector2.ZERO)
		var res_path: String = PROP_RESOURCES.get(ptype, "res://resources/bg_props/radar_dish.tres")
		var pdata: BgItemData = load(res_path) if ResourceLoader.exists(res_path) else null
		if pdata != null:
			var inst: AnimatedBgProp = prop_scene.instantiate() as AnimatedBgProp
			inst.prop_data = pdata
			inst.global_position = ppos
			inst.add_to_group("custom_editor_props")
			stage.add_child(inst)

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_message = ""
	
	if not is_active or is_test_playing:
		return
	
	# Camera horizontal keyboard navigation
	var move_cam: float = 0.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		move_cam += 1.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		move_cam -= 1.0
	
	if move_cam != 0.0:
		cam_x = clampf(cam_x + move_cam * cam_pan_speed * delta, 480.0, 6200.0)
		if camera != null:
			camera.global_position.x = cam_x
		if stage != null:
			stage.queue_redraw()
	
	overlay_control.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# F1 toggles maker mode anytime
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if is_test_playing:
			stop_test_play()
		elif is_active:
			close_editor()
		else:
			open_editor()
		get_viewport().set_input_as_handled()
		return
	
	if not is_active:
		return
	
	# In test play, ESC returns to editor
	if is_test_playing and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		stop_test_play()
		get_viewport().set_input_as_handled()
		return
	
	if is_test_playing:
		return
	
	# Shortcut keys in editor: 1..7 select tools
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_tool = ToolType.SELECT_MOVE
				show_toast("TOOL: 1. SELECTOR")
			KEY_2:
				current_tool = ToolType.PLATFORM
				show_toast("TOOL: 2. PLATFORMS")
			KEY_3:
				current_tool = ToolType.GROUND
				show_toast("TOOL: 3. GROUND")
			KEY_4:
				current_tool = ToolType.ENEMY
				show_toast("TOOL: 4. ENEMIES")
			KEY_5:
				current_tool = ToolType.POWERUP
				show_toast("TOOL: 5. POWERUPS")
			KEY_6:
				current_tool = ToolType.BG_PROP
				show_toast("TOOL: 6. PROPS")
			KEY_7:
				current_tool = ToolType.ERASE
				show_toast("TOOL: 7. ERASE")
			KEY_DELETE, KEY_BACKSPACE:
				_delete_selected_item()
			KEY_ESCAPE:
				selected_item_idx = -1
				selected_item_type = ""
				is_drawing_rect = false
				show_toast("DESELECTED")
			KEY_G:
				_cycle_grid()
			KEY_T:
				_cycle_theme()
			KEY_P:
				start_test_play()

func _delete_selected_item() -> void:
	if selected_item_idx < 0:
		return
	if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
		editor_platforms.remove_at(selected_item_idx)
		show_toast("✖ DELETED PLATFORM")
	elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
		editor_ground.remove_at(selected_item_idx)
		show_toast("✖ DELETED GROUND")
	elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
		var ep: Vector2 = editor_enemies[selected_item_idx]["pos"]
		editor_enemies.remove_at(selected_item_idx)
		if stage != null:
			for child in stage.get_children():
				if _is_enemy_node(child) and child.global_position.distance_to(ep) < 55.0:
					child.queue_free()
		show_toast("✖ DELETED ENEMY")
	elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
		var pp: Vector2 = editor_powerups[selected_item_idx]["pos"]
		editor_powerups.remove_at(selected_item_idx)
		if stage != null:
			for child in stage.get_children():
				if _is_powerup_node(child) and child.global_position.distance_to(pp) < 50.0:
					child.queue_free()
		show_toast("✖ DELETED POWERUP")
	elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
		var bp: Vector2 = editor_bg_props[selected_item_idx]["pos"]
		editor_bg_props.remove_at(selected_item_idx)
		if stage != null:
			for child in stage.get_children():
				if _is_prop_node(child) and child.global_position.distance_to(bp) < 45.0:
					child.queue_free()
		show_toast("✖ DELETED BACKGROUND PROP")
	selected_item_idx = -1
	selected_item_type = ""
	_apply_to_stage()
	overlay_control.queue_redraw()

func _is_prop_node(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	return node is AnimatedBgProp or node.is_in_group("bg_props") or node.is_in_group("custom_editor_props")

func _is_enemy_node(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node == stage or node.name == "Player" or node.name == "Camera2D" or node.name == "WorldColliders" or node.name == "ContraMaker" or node.name == "TouchControls" or node.name == "HUD":
		return false
	if node.is_in_group("enemies") or node.is_in_group("enemy"):
		return true
	var n_name := node.name.to_lower()
	if n_name.contains("enemy") or n_name.contains("turret") or n_name.contains("sniper") or n_name.contains("grenadier") or n_name.contains("crawler") or n_name.contains("drone") or n_name.contains("soldier") or n_name.contains("boss"):
		return true
	if node is CollisionObject2D and (node.collision_layer & (1 << 2)) != 0:
		return true
	return false

func _is_powerup_node(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.is_in_group("powerup") or node.is_in_group("powerups") or node.is_in_group("items"):
		return true
	var n_name := node.name.to_lower()
	if n_name.contains("powerup") or n_name.contains("sensor") or n_name.contains("blimp"):
		return true
	return false

func _is_pos_hitting_enemy(world_pos: Vector2, enemy_pos: Vector2) -> bool:
	var box := Rect2(enemy_pos.x - 34.0, enemy_pos.y - 48.0, 68.0, 62.0)
	if box.has_point(world_pos):
		return true
	if world_pos.distance_to(enemy_pos) < 38.0:
		return true
	return false

func _is_node_at_world_pos(node: Node2D, world_pos: Vector2) -> bool:
	if not is_instance_valid(node):
		return false
	if _is_pos_hitting_enemy(world_pos, node.global_position):
		return true
	if node is CollisionObject2D:
		for owner_id in node.get_shape_owners():
			for s_idx in range(node.shape_owner_get_shape_count(owner_id)):
				var s = node.shape_owner_get_shape(owner_id, s_idx)
				var xf: Transform2D = node.global_transform * node.shape_owner_get_transform(owner_id)
				var local_p: Vector2 = xf.affine_inverse() * world_pos
				if s is RectangleShape2D:
					if Rect2(-s.size * 0.5 - Vector2(10, 10), s.size + Vector2(20, 20)).has_point(local_p):
						return true
				elif s is CircleShape2D:
					if local_p.length() <= s.radius + 12.0:
						return true
				elif s is CapsuleShape2D:
					if local_p.length() <= s.height + 12.0:
						return true
	return false

func _update_hover(world_pos: Vector2) -> void:
	hovered_item_type = ""
	hovered_item_idx = -1
	
	# Enemies
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and _is_node_at_world_pos(child, world_pos):
				hovered_item_type = "enemy"
				for j in range(editor_enemies.size()):
					if editor_enemies[j]["pos"].distance_to(child.global_position) < 50.0:
						hovered_item_idx = j
						return
	for i in range(editor_enemies.size()):
		if _is_pos_hitting_enemy(world_pos, editor_enemies[i]["pos"]):
			hovered_item_type = "enemy"
			hovered_item_idx = i
			return
	
	# Powerups
	if stage != null:
		for child in stage.get_children():
			if _is_powerup_node(child) and (world_pos.distance_to(child.global_position) < 36.0 or Rect2(child.global_position.x - 22.0, child.global_position.y - 22.0, 44.0, 44.0).has_point(world_pos)):
				hovered_item_type = "powerup"
				for j in range(editor_powerups.size()):
					if editor_powerups[j]["pos"].distance_to(child.global_position) < 45.0:
						hovered_item_idx = j
						return
	for i in range(editor_powerups.size()):
		if world_pos.distance_to(editor_powerups[i]["pos"]) < 32.0 or Rect2(editor_powerups[i]["pos"].x - 22.0, editor_powerups[i]["pos"].y - 22.0, 44.0, 44.0).has_point(world_pos):
			hovered_item_type = "powerup"
			hovered_item_idx = i
			return
	
	# Background Props
	if stage != null:
		for child in stage.get_children():
			if _is_prop_node(child) and world_pos.distance_to(child.global_position) < 32.0:
				hovered_item_type = "bg_prop"
				for j in range(editor_bg_props.size()):
					if editor_bg_props[j]["pos"].distance_to(child.global_position) < 40.0:
						hovered_item_idx = j
						return
	for i in range(editor_bg_props.size()):
		if world_pos.distance_to(editor_bg_props[i]["pos"]) < 32.0:
			hovered_item_type = "bg_prop"
			hovered_item_idx = i
			return
	
	# Platforms
	for i in range(editor_platforms.size()):
		if editor_platforms[i]["rect"].grow(8.0).has_point(world_pos):
			hovered_item_type = "platform"
			hovered_item_idx = i
			return
	
	# Ground
	for i in range(editor_ground.size()):
		if editor_ground[i].has_point(world_pos):
			hovered_item_type = "ground"
			hovered_item_idx = i
			return

func _cycle_grid() -> void:
	if grid_snap == 32:
		grid_snap = 16
	elif grid_snap == 16:
		grid_snap = 0
	else:
		grid_snap = 32
	show_toast("GRID SNAP: " + ("OFF" if grid_snap == 0 else "%d PX" % grid_snap))

func _cycle_theme() -> void:
	var next_theme := (Global.current_stage % 8) + 1
	Global.current_stage = next_theme
	if stage != null and stage.has_method("_setup_background"):
		stage._setup_background()
		stage.queue_redraw()
	show_toast("STAGE THEME: %d - %s" % [next_theme, Global.STAGE_NAMES[next_theme - 1]])

func start_test_play() -> void:
	if stage == null or camera == null:
		return
	is_test_playing = true
	visible = true # Still visible to show "STOP TEST" button
	
	# Spawn player safely
	var spawn_pos := Vector2(camera.global_position.x - 120.0, 360.0)
	if stage.has_method("get_safe_respawn_position"):
		spawn_pos = stage.get_safe_respawn_position(camera.global_position.x)
	
	var player_node: CharacterBody2D = stage.get_node_or_null("Player") as CharacterBody2D
	if player_node != null:
		player_node.global_position = spawn_pos
		player_node.velocity = Vector2.ZERO
		if "state" in player_node:
			player_node.state = 0 # IDLE
	
	# Spawn placed custom enemies
	_spawn_editor_enemies_for_test()
	
	show_toast("★ LIVE TEST • PLAYER IS INVINCIBLE (GOD MODE) • PRESS F1 TO STOP")
	test_play_requested.emit(spawn_pos)
	overlay_control.queue_redraw()

func stop_test_play() -> void:
	is_test_playing = false
	visible = true
	
	# Clear active combat entities
	if stage != null:
		for child in stage.get_children():
			if child.is_in_group("enemies") or child.is_in_group("bullet"):
				child.queue_free()
	
	_apply_to_stage()
	show_toast("■ EDIT MODE RESTORED")
	test_stop_requested.emit()
	overlay_control.queue_redraw()

func _spawn_editor_enemies_for_test() -> void:
	if stage == null:
		return
	
	for e in editor_enemies:
		var etype: String = e.get("type", "soldier")
		var pos: Vector2 = e.get("pos", Vector2.ZERO)
		var scn: PackedScene = null
		
		match etype:
			"soldier": scn = stage.get("soldier_scene")
			"sniper": scn = stage.get("sniper_scene")
			"turret": scn = stage.get("turret_scene")
			"grenadier": scn = stage.get("grenadier_scene")
			"crawler": scn = stage.get("crawler_scene")
			"drone": scn = stage.get("drone_scene")
		
		if scn != null:
			var inst = scn.instantiate()
			inst.global_position = pos
			inst.add_to_group("enemies")
			stage.add_child(inst)
	
	for p in editor_powerups:
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var ptype: int = p.get("type", 1)
		var sensor_scn: PackedScene = stage.get("sensor_scene")
		if sensor_scn != null:
			var pod = sensor_scn.instantiate()
			pod.global_position = pos
			pod.weapon_type = ptype
			pod.add_to_group("enemies")
			stage.add_child(pod)

func show_toast(msg: String) -> void:
	toast_message = msg
	toast_timer = 2.4

# Save / Load to JSON
func save_level_to_file(slot_id: int = 1) -> void:
	var dir_path := "user://custom_levels"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var file_path := "%s/level_slot_%d.json" % [dir_path, slot_id]
	
	var data: Dictionary = {
		"stage_theme": Global.current_stage,
		"ground_segments": [],
		"platforms": [],
		"enemies": [],
		"powerups": [],
		"bg_props": []
	}
	
	for g in editor_ground:
		data["ground_segments"].append({"x": g.position.x, "y": g.position.y, "w": g.size.x, "h": g.size.y})
	for p in editor_platforms:
		var r: Rect2 = p["rect"]
		data["platforms"].append({"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y, "type": p["type"]})
	for e in editor_enemies:
		data["enemies"].append({"type": e["type"], "x": e["pos"].x, "y": e["pos"].y})
	for pw in editor_powerups:
		data["powerups"].append({"type": pw["type"], "x": pw["pos"].x, "y": pw["pos"].y})
	for bp in editor_bg_props:
		data["bg_props"].append({"type": bp["type"], "x": bp["pos"].x, "y": bp["pos"].y})
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		show_toast("✔ LEVEL SAVED TO SLOT %d" % slot_id)
	else:
		show_toast("✖ FAILED TO SAVE LEVEL")

func load_level_from_file(slot_id: int = 1) -> void:
	var file_path := "user://custom_levels/level_slot_%d.json" % slot_id
	if not FileAccess.file_exists(file_path):
		show_toast("NO SAVED FILE IN SLOT %d" % slot_id)
		return
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(text) != OK:
		show_toast("ERROR PARSING LEVEL JSON")
		return
	
	var data: Dictionary = json.data
	Global.current_stage = data.get("stage_theme", 1)
	if stage != null and stage.has_method("_setup_background"):
		stage._setup_background()
	
	editor_ground.clear()
	for g_dict in data.get("ground_segments", []):
		editor_ground.append(Rect2(g_dict["x"], g_dict["y"], g_dict["w"], g_dict["h"]))
	
	editor_platforms.clear()
	for p_dict in data.get("platforms", []):
		editor_platforms.append({
			"rect": Rect2(p_dict["x"], p_dict["y"], p_dict["w"], p_dict["h"]),
			"type": p_dict.get("type", 0)
		})
	
	editor_enemies.clear()
	for e_dict in data.get("enemies", []):
		editor_enemies.append({"type": e_dict["type"], "pos": Vector2(e_dict["x"], e_dict["y"])})
	
	editor_powerups.clear()
	for pw_dict in data.get("powerups", []):
		editor_powerups.append({"type": pw_dict["type"], "pos": Vector2(pw_dict["x"], pw_dict["y"])})
	
	editor_bg_props.clear()
	for bp_dict in data.get("bg_props", []):
		editor_bg_props.append({"type": bp_dict["type"], "pos": Vector2(bp_dict["x"], bp_dict["y"])})
	
	_apply_to_stage()
	show_toast("✔ LOADED CUSTOM LEVEL SLOT %d" % slot_id)

func _snap_val(val: float) -> float:
	if grid_snap <= 0:
		return val
	return roundf(val / float(grid_snap)) * float(grid_snap)

func _snap_vec(vec: Vector2) -> Vector2:
	return Vector2(_snap_val(vec.x), _snap_val(vec.y))

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if camera == null:
		return screen_pos
	return screen_pos + Vector2(camera.global_position.x - 480.0, 0.0)

func _world_to_screen(world_pos: Vector2) -> Vector2:
	if camera == null:
		return world_pos
	return world_pos - Vector2(camera.global_position.x - 480.0, 0.0)

# GUI interaction
func _on_gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if is_test_playing:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var stop_rect := Rect2(800.0, 8.0, 150.0, 32.0)
			if stop_rect.has_point(event.position):
				stop_test_play()
		return
	
	# Top toolbar interaction
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y < 42.0:
			_handle_toolbar_click(event.position)
			return
		elif event.position.y > 450.0:
			_handle_bottom_shelf_click(event.position)
			return
	
	# Middle/Right mouse drag camera pan
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				is_panning_cam = true
				pan_drag_start = mb.position
				pan_cam_start_x = cam_x
			else:
				is_panning_cam = false
	
	if event is InputEventMouseMotion and is_panning_cam:
		var mm := event as InputEventMouseMotion
		var dx: float = pan_drag_start.x - mm.position.x
		cam_x = clampf(pan_cam_start_x + dx, 480.0, 6200.0)
		if camera != null:
			camera.global_position.x = cam_x
		if stage != null:
			stage.queue_redraw()
		return
	
	# Canvas tool drawing
	var world_mouse := _screen_to_world(event.position)
	var snapped_world := _snap_vec(world_mouse)
	
	if event is InputEventMouseMotion:
		mouse_screen_pos = event.position
		mouse_world_pos = world_mouse
		snapped_world_pos = snapped_world
		is_mouse_in_viewport = (event.position.y >= 42.0 and event.position.y <= 448.0)
		_update_hover(world_mouse)
		_handle_canvas_motion(world_mouse, snapped_world)
		overlay_control.queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_canvas_press(world_mouse, snapped_world)
		else:
			_handle_canvas_release(world_mouse, snapped_world)
		overlay_control.queue_redraw()

func _handle_canvas_press(world_pos: Vector2, snapped_pos: Vector2) -> void:
	match current_tool:
		ToolType.PLATFORM, ToolType.GROUND:
			is_drawing_rect = true
			draw_rect_start = snapped_pos
			draw_rect_current = snapped_pos
		
		ToolType.ENEMY:
			editor_enemies.append({
				"type": selected_enemy_type,
				"pos": snapped_pos
			})
			show_toast("+ ADDED %s" % selected_enemy_type.to_upper())
			_apply_to_stage()
		
		ToolType.POWERUP:
			editor_powerups.append({
				"type": selected_powerup_type,
				"pos": snapped_pos
			})
			show_toast("+ ADDED POWERUP POD")
			_apply_to_stage()
		
		ToolType.BG_PROP:
			editor_bg_props.append({
				"type": selected_prop_type,
				"pos": snapped_pos
			})
			show_toast("+ ADDED %s" % selected_prop_type.to_upper().replace("_", " "))
			_apply_to_stage()
		
		ToolType.ERASE:
			_erase_at(world_pos)
		
		ToolType.SELECT_MOVE:
			_select_item_at(world_pos)

func _handle_canvas_motion(world_pos: Vector2, snapped_pos: Vector2) -> void:
	if is_drawing_rect:
		draw_rect_current = snapped_pos
	elif is_moving_item and selected_item_idx >= 0:
		var d_vec := snapped_pos - move_start_mouse
		if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
			var r: Rect2 = move_original_rect
			r.position += d_vec
			editor_platforms[selected_item_idx]["rect"] = r
			_apply_to_stage()
		elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
			var r: Rect2 = move_original_rect
			r.position += d_vec
			editor_ground[selected_item_idx] = r
			_apply_to_stage()
		elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
			var new_p: Vector2 = move_original_pos + d_vec
			editor_enemies[selected_item_idx]["pos"] = new_p
			if stage != null:
				for child in stage.get_children():
					if _is_enemy_node(child) and child.global_position.distance_to(move_original_pos) < 55.0:
						child.global_position = new_p
		elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
			var new_p: Vector2 = move_original_pos + d_vec
			editor_powerups[selected_item_idx]["pos"] = new_p
			if stage != null:
				for child in stage.get_children():
					if _is_powerup_node(child) and child.global_position.distance_to(move_original_pos) < 50.0:
						child.global_position = new_p
		elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
			var new_p: Vector2 = move_original_pos + d_vec
			editor_bg_props[selected_item_idx]["pos"] = new_p
			if stage != null:
				for child in stage.get_children():
					if _is_prop_node(child) and child.global_position.distance_to(move_original_pos) < 45.0:
						child.global_position = new_p
	elif current_tool == ToolType.ERASE and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_erase_at(world_pos)

func _handle_canvas_release(_world_pos: Vector2, snapped_pos: Vector2) -> void:
	if is_drawing_rect:
		is_drawing_rect = false
		var min_x := minf(draw_rect_start.x, snapped_pos.x)
		var max_x := maxf(draw_rect_start.x, snapped_pos.x)
		var min_y := minf(draw_rect_start.y, snapped_pos.y)
		var max_y := maxf(draw_rect_start.y, snapped_pos.y)
		var w := maxf(32.0, max_x - min_x)
		var h := maxf(16.0, max_y - min_y)
		
		if current_tool == ToolType.PLATFORM:
			editor_platforms.append({
				"rect": Rect2(min_x, min_y, w, 16.0),
				"type": selected_platform_type
			})
			show_toast("+ PLATFORM (%s)" % PLATFORM_NAMES[selected_platform_type])
		elif current_tool == ToolType.GROUND:
			editor_ground.append(Rect2(min_x, 440.0, w, 200.0))
			show_toast("+ GROUND SEGMENT")
		
		_apply_to_stage()
	
	if is_moving_item:
		is_moving_item = false

func _select_item_at(world_pos: Vector2) -> void:
	# Search enemies in stage first
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and _is_node_at_world_pos(child, world_pos):
				var c_pos: Vector2 = child.global_position
				var found_idx := -1
				for j in range(editor_enemies.size()):
					if editor_enemies[j]["pos"].distance_to(c_pos) < 50.0:
						found_idx = j
						break
				if found_idx == -1:
					var e_type_str := "soldier"
					var n_name := child.name.to_lower()
					if n_name.contains("turret"): e_type_str = "turret"
					elif n_name.contains("sniper"): e_type_str = "sniper"
					elif n_name.contains("grenadier"): e_type_str = "grenadier"
					elif n_name.contains("crawler"): e_type_str = "crawler"
					elif n_name.contains("drone"): e_type_str = "drone"
					editor_enemies.append({"type": e_type_str, "pos": c_pos})
					found_idx = editor_enemies.size() - 1
				
				selected_item_type = "enemy"
				selected_item_idx = found_idx
				is_moving_item = true
				move_start_mouse = _snap_vec(world_pos)
				move_original_pos = editor_enemies[found_idx]["pos"]
				show_toast("★ SELECTED ENEMY: " + editor_enemies[found_idx]["type"].to_upper())
				overlay_control.queue_redraw()
				return
	
	# Search editor_enemies
	for i in range(editor_enemies.size()):
		var ep: Vector2 = editor_enemies[i]["pos"]
		if _is_pos_hitting_enemy(world_pos, ep):
			selected_item_type = "enemy"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_pos = ep
			show_toast("★ SELECTED ENEMY: " + editor_enemies[i]["type"].to_upper())
			overlay_control.queue_redraw()
			return
	
	# Search powerups in stage
	if stage != null:
		for child in stage.get_children():
			if _is_powerup_node(child) and (world_pos.distance_to(child.global_position) < 38.0 or Rect2(child.global_position.x - 24.0, child.global_position.y - 24.0, 48.0, 48.0).has_point(world_pos)):
				var c_pos: Vector2 = child.global_position
				var found_idx := -1
				for j in range(editor_powerups.size()):
					if editor_powerups[j]["pos"].distance_to(c_pos) < 50.0:
						found_idx = j
						break
				if found_idx == -1:
					editor_powerups.append({"type": 1, "pos": c_pos})
					found_idx = editor_powerups.size() - 1
				selected_item_type = "powerup"
				selected_item_idx = found_idx
				is_moving_item = true
				move_start_mouse = _snap_vec(world_pos)
				move_original_pos = editor_powerups[found_idx]["pos"]
				show_toast("★ SELECTED POWERUP")
				overlay_control.queue_redraw()
				return
	
	# Search editor_powerups
	for i in range(editor_powerups.size()):
		var pp: Vector2 = editor_powerups[i]["pos"]
		if world_pos.distance_to(pp) < 38.0 or Rect2(pp.x - 24.0, pp.y - 24.0, 48.0, 48.0).has_point(world_pos):
			selected_item_type = "powerup"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_pos = pp
			var pw_name: String = POWERUP_NAMES[clampi(editor_powerups[i]["type"] - 1, 0, POWERUP_NAMES.size() - 1)]
			show_toast("★ SELECTED POWERUP: " + pw_name)
			overlay_control.queue_redraw()
			return
	
	# Search bg_props in stage
	if stage != null:
		for child in stage.get_children():
			if _is_prop_node(child) and world_pos.distance_to(child.global_position) < 36.0:
				var c_pos: Vector2 = child.global_position
				var found_idx := -1
				for j in range(editor_bg_props.size()):
					if editor_bg_props[j]["pos"].distance_to(c_pos) < 45.0:
						found_idx = j
						break
				if found_idx == -1:
					var p_type_str := "radar_dish"
					if child is AnimatedBgProp and child.prop_data != null:
						p_type_str = child.prop_data.item_id
					editor_bg_props.append({"type": p_type_str, "pos": c_pos})
					found_idx = editor_bg_props.size() - 1
				selected_item_type = "bg_prop"
				selected_item_idx = found_idx
				is_moving_item = true
				move_start_mouse = _snap_vec(world_pos)
				move_original_pos = editor_bg_props[found_idx]["pos"]
				show_toast("★ SELECTED PROP: " + editor_bg_props[found_idx]["type"].to_upper().replace("_", " "))
				overlay_control.queue_redraw()
				return

	# Search editor_bg_props
	for i in range(editor_bg_props.size()):
		var bp: Vector2 = editor_bg_props[i]["pos"]
		if world_pos.distance_to(bp) < 36.0:
			selected_item_type = "bg_prop"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_pos = bp
			show_toast("★ SELECTED PROP: " + editor_bg_props[i]["type"].to_upper().replace("_", " "))
			overlay_control.queue_redraw()
			return

	# Search platforms
	for i in range(editor_platforms.size()):
		var pr: Rect2 = editor_platforms[i]["rect"]
		if pr.grow(10.0).has_point(world_pos):
			selected_item_type = "platform"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_rect = pr
			var p_name: String = PLATFORM_NAMES[editor_platforms[i]["type"]]
			show_toast("★ SELECTED PLATFORM (" + p_name + ")")
			overlay_control.queue_redraw()
			return
	
	# Search ground
	for i in range(editor_ground.size()):
		var gr: Rect2 = editor_ground[i]
		if gr.grow(6.0).has_point(world_pos):
			selected_item_type = "ground"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_rect = gr
			show_toast("★ SELECTED GROUND SEGMENT")
			overlay_control.queue_redraw()
			return
	
	selected_item_idx = -1
	selected_item_type = ""
	show_toast("DESELECTED")
	overlay_control.queue_redraw()

func _erase_at(world_pos: Vector2) -> void:
	# 1. Search and erase active enemy nodes in stage
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and _is_node_at_world_pos(child, world_pos):
				var c_pos: Vector2 = child.global_position
				# Remove from editor_enemies if close
				for j in range(editor_enemies.size() - 1, -1, -1):
					if editor_enemies[j]["pos"].distance_to(c_pos) < 55.0:
						editor_enemies.remove_at(j)
				child.queue_free()
				show_toast("✖ ERASED ENEMY")
				_apply_to_stage()
				overlay_control.queue_redraw()
				return
	
	# 2. Search and erase editor_enemies markers
	for i in range(editor_enemies.size() - 1, -1, -1):
		var ep: Vector2 = editor_enemies[i]["pos"]
		if _is_pos_hitting_enemy(world_pos, ep):
			var etype: String = editor_enemies[i].get("type", "enemy")
			editor_enemies.remove_at(i)
			# Also free any corresponding stage node
			if stage != null:
				for child in stage.get_children():
					if _is_enemy_node(child) and child.global_position.distance_to(ep) < 55.0:
						child.queue_free()
			show_toast("✖ ERASED ENEMY: " + etype.to_upper())
			_apply_to_stage()
			overlay_control.queue_redraw()
			return
	
	# 3. Search and erase active powerup / sensor nodes in stage
	if stage != null:
		for child in stage.get_children():
			if _is_powerup_node(child) and (world_pos.distance_to(child.global_position) < 38.0 or Rect2(child.global_position.x - 24.0, child.global_position.y - 24.0, 48.0, 48.0).has_point(world_pos)):
				var c_pos: Vector2 = child.global_position
				for j in range(editor_powerups.size() - 1, -1, -1):
					if editor_powerups[j]["pos"].distance_to(c_pos) < 50.0:
						editor_powerups.remove_at(j)
				child.queue_free()
				show_toast("✖ ERASED POWERUP")
				_apply_to_stage()
				overlay_control.queue_redraw()
				return

	# 4. Search and erase editor_powerups
	for i in range(editor_powerups.size() - 1, -1, -1):
		var pp: Vector2 = editor_powerups[i]["pos"]
		if world_pos.distance_to(pp) < 38.0 or Rect2(pp.x - 24.0, pp.y - 24.0, 48.0, 48.0).has_point(world_pos):
			editor_powerups.remove_at(i)
			if stage != null:
				for child in stage.get_children():
					if _is_powerup_node(child) and child.global_position.distance_to(pp) < 50.0:
						child.queue_free()
			show_toast("✖ ERASED POWERUP")
			_apply_to_stage()
			overlay_control.queue_redraw()
			return
	
	# 5. Search and erase active bg_props in stage
	if stage != null:
		for child in stage.get_children():
			if _is_prop_node(child) and world_pos.distance_to(child.global_position) < 36.0:
				var c_pos: Vector2 = child.global_position
				for j in range(editor_bg_props.size() - 1, -1, -1):
					if editor_bg_props[j]["pos"].distance_to(c_pos) < 45.0:
						editor_bg_props.remove_at(j)
				child.queue_free()
				show_toast("✖ ERASED PROP")
				_apply_to_stage()
				overlay_control.queue_redraw()
				return

	# 6. Search and erase editor_bg_props
	for i in range(editor_bg_props.size() - 1, -1, -1):
		var bp: Vector2 = editor_bg_props[i]["pos"]
		if world_pos.distance_to(bp) < 36.0:
			var ptype: String = editor_bg_props[i].get("type", "prop")
			editor_bg_props.remove_at(i)
			if stage != null:
				for child in stage.get_children():
					if _is_prop_node(child) and child.global_position.distance_to(bp) < 45.0:
						child.queue_free()
			show_toast("✖ ERASED PROP: " + ptype.to_upper().replace("_", " "))
			_apply_to_stage()
			overlay_control.queue_redraw()
			return

	# 7. Erase platforms
	for i in range(editor_platforms.size() - 1, -1, -1):
		if editor_platforms[i]["rect"].grow(12.0).has_point(world_pos):
			editor_platforms.remove_at(i)
			show_toast("✖ ERASED PLATFORM")
			_apply_to_stage()
			overlay_control.queue_redraw()
			return
	
	# 8. Erase ground
	for i in range(editor_ground.size() - 1, -1, -1):
		if editor_ground[i].grow(8.0).has_point(world_pos):
			editor_ground.remove_at(i)
			show_toast("✖ ERASED GROUND")
			_apply_to_stage()
			overlay_control.queue_redraw()
			return

func _handle_toolbar_click(pos: Vector2) -> void:
	# Buttons on top bar (y: 4 to 36)
	if Rect2(12.0, 4.0, 110.0, 32.0).has_point(pos):
		start_test_play()
	elif Rect2(130.0, 4.0, 95.0, 32.0).has_point(pos):
		_cycle_theme()
	elif Rect2(232.0, 4.0, 90.0, 32.0).has_point(pos):
		_cycle_grid()
	elif Rect2(330.0, 4.0, 85.0, 32.0).has_point(pos):
		save_level_to_file(1)
	elif Rect2(422.0, 4.0, 85.0, 32.0).has_point(pos):
		load_level_from_file(1)
	elif Rect2(514.0, 4.0, 105.0, 32.0).has_point(pos):
		_load_current_stage_geometry()
		show_toast("RESET TO STAGE TEMPLATE")
	elif Rect2(626.0, 4.0, 85.0, 32.0).has_point(pos):
		editor_ground.clear()
		editor_platforms.clear()
		editor_enemies.clear()
		editor_powerups.clear()
		editor_bg_props.clear()
		_apply_to_stage()
		show_toast("CLEARED LEVEL")
	elif Rect2(860.0, 4.0, 85.0, 32.0).has_point(pos):
		close_editor()

func _handle_bottom_shelf_click(pos: Vector2) -> void:
	# Scrubber bar (y: 450 to 468)
	if pos.y >= 450.0 and pos.y <= 470.0:
		var scrub_ratio := clampf((pos.x - 40.0) / 880.0, 0.0, 1.0)
		cam_x = scrub_ratio * LevelMaps.BOSS_TRIGGER_X + 480.0
		if camera != null:
			camera.global_position.x = cam_x
		if stage != null:
			stage.queue_redraw()
		return
	
	# Primary tool buttons (y: 476 to 506)
	var tools_labels := ["1. SELECTOR", "2. PLATFORMS", "3. GROUND", "4. ENEMIES", "5. POWERUPS", "6. PROPS", "7. ERASE"]
	var tool_enum_list := [ToolType.SELECT_MOVE, ToolType.PLATFORM, ToolType.GROUND, ToolType.ENEMY, ToolType.POWERUP, ToolType.BG_PROP, ToolType.ERASE]
	var tools_x: float = 14.0
	var tool_w: float = 125.0
	for i in range(7):
		var btn_rect := Rect2(tools_x + float(i) * (tool_w + 5.0), 476.0, tool_w, 28.0)
		if btn_rect.has_point(pos):
			current_tool = tool_enum_list[i]
			show_toast("SELECTED: %s" % tools_labels[i])
			overlay_control.queue_redraw()
			return
	
	# Sub-palette options (y: 508 to 536)
	if current_tool == ToolType.SELECT_MOVE:
		if selected_item_idx >= 0:
			if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
				var sub_x: float = 20.0
				var sub_w: float = 72.0
				for k in range(PLATFORM_NAMES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 508.0, sub_w, 24.0)
					if sub_rect.has_point(pos):
						editor_platforms[selected_item_idx]["type"] = k
						_apply_to_stage()
						show_toast("CHANGED PLATFORM: " + PLATFORM_NAMES[k])
						overlay_control.queue_redraw()
						return
				if Rect2(700.0, 508.0, 95.0, 24.0).has_point(pos):
					_delete_selected_item()
					return
			elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
				var sub_x: float = 20.0
				var sub_w: float = 100.0
				for k in range(ENEMY_TYPES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 5.0), 508.0, sub_w, 24.0)
					if sub_rect.has_point(pos):
						editor_enemies[selected_item_idx]["type"] = ENEMY_TYPES[k]
						show_toast("CHANGED ENEMY: " + ENEMY_LABELS[k])
						overlay_control.queue_redraw()
						return
				if Rect2(660.0, 508.0, 95.0, 24.0).has_point(pos):
					_delete_selected_item()
					return
			elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
				var sub_x: float = 20.0
				var sub_w: float = 120.0
				for k in range(3):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 508.0, sub_w, 24.0)
					if sub_rect.has_point(pos):
						editor_powerups[selected_item_idx]["type"] = k + 1
						show_toast("CHANGED WEAPON: " + POWERUP_NAMES[k])
						overlay_control.queue_redraw()
						return
				if Rect2(410.0, 508.0, 95.0, 24.0).has_point(pos):
					_delete_selected_item()
					return
			elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
				var sub_x: float = 12.0
				var sub_w: float = 68.0
				for k in range(PROP_TYPES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 508.0, sub_w, 24.0)
					if sub_rect.has_point(pos):
						editor_bg_props[selected_item_idx]["type"] = PROP_TYPES[k]
						_apply_to_stage()
						show_toast("CHANGED PROP: " + PROP_LABELS[k])
						overlay_control.queue_redraw()
						return
				if Rect2(866.0, 508.0, 82.0, 24.0).has_point(pos):
					_delete_selected_item()
					return
			elif selected_item_type == "ground":
				if Rect2(20.0, 508.0, 125.0, 24.0).has_point(pos):
					_delete_selected_item()
					return
	elif current_tool == ToolType.PLATFORM:
		var sub_x: float = 20.0
		var sub_w: float = 75.0
		for k in range(PLATFORM_NAMES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 508.0, sub_w, 24.0)
			if sub_rect.has_point(pos):
				selected_platform_type = k
				show_toast("TYPE: " + PLATFORM_NAMES[k])
				overlay_control.queue_redraw()
				return
	elif current_tool == ToolType.ENEMY:
		var sub_x: float = 20.0
		var sub_w: float = 105.0
		for k in range(ENEMY_TYPES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 508.0, sub_w, 24.0)
			if sub_rect.has_point(pos):
				selected_enemy_type = ENEMY_TYPES[k]
				show_toast("ENEMY: " + ENEMY_LABELS[k])
				overlay_control.queue_redraw()
				return
	elif current_tool == ToolType.POWERUP:
		var sub_x: float = 20.0
		var sub_w: float = 120.0
		for k in range(3):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 508.0, sub_w, 24.0)
			if sub_rect.has_point(pos):
				selected_powerup_type = k + 1
				show_toast("POWERUP: " + POWERUP_NAMES[k])
				overlay_control.queue_redraw()
				return
	elif current_tool == ToolType.BG_PROP:
		var sub_x: float = 12.0
		var sub_w: float = 74.0
		for k in range(PROP_TYPES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 508.0, sub_w, 24.0)
			if sub_rect.has_point(pos):
				selected_prop_type = PROP_TYPES[k]
				show_toast("PROP: " + PROP_LABELS[k])
				overlay_control.queue_redraw()
				return

# Drawing Editor Interface
func _on_overlay_draw() -> void:
	if not is_active:
		return
	
	var font := ThemeDB.fallback_font
	
	if is_test_playing:
		# Test playing banner & stop button
		overlay_control.draw_rect(Rect2(800.0, 8.0, 150.0, 32.0), Color(0.85, 0.20, 0.20, 0.90))
		overlay_control.draw_rect(Rect2(800.0, 8.0, 150.0, 32.0), Color(1.0, 0.8, 0.8), false, 1.5)
		overlay_control.draw_string(font, Vector2(814.0, 29.0), "■ STOP TEST (F1)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		
		# Prominent God Mode / Invincible badge
		overlay_control.draw_rect(Rect2(16.0, 8.0, 240.0, 32.0), Color(0.08, 0.45, 0.80, 0.90))
		overlay_control.draw_rect(Rect2(16.0, 8.0, 240.0, 32.0), Color(0.4, 0.9, 1.0, 0.95), false, 1.5)
		overlay_control.draw_string(font, Vector2(28.0, 29.0), "★ GOD MODE • INVINCIBLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.95, 0.4))
		return
	
	# 1. Grid lines in world viewport
	if grid_snap > 0 and camera != null:
		var cam_left := camera.global_position.x - 480.0
		var cam_right := camera.global_position.x + 480.0
		var start_gx := floorf(cam_left / float(grid_snap)) * float(grid_snap)
		var grid_col := Color(0.2, 0.6, 0.9, 0.12)
		
		var gx := start_gx
		while gx <= cam_right:
			var sx := gx - cam_left
			overlay_control.draw_line(Vector2(sx, 44.0), Vector2(sx, 448.0), grid_col, 1.0)
			gx += float(grid_snap)
		
		for gy in range(48, 448, grid_snap):
			overlay_control.draw_line(Vector2(0.0, float(gy)), Vector2(960.0, float(gy)), grid_col, 1.0)
	
	# 2. Draw Enemy markers in World space
	for e in editor_enemies:
		var sp := _world_to_screen(e["pos"])
		if sp.x >= -40.0 and sp.x <= 1000.0:
			var etype: String = e["type"]
			var col := Color(1.0, 0.3, 0.3)
			if etype == "sniper": col = Color(0.3, 0.9, 0.4)
			elif etype == "turret": col = Color(0.9, 0.7, 0.2)
			elif etype == "grenadier": col = Color(1.0, 0.5, 0.1)
			elif etype == "crawler": col = Color(0.8, 0.3, 0.9)
			elif etype == "drone": col = Color(0.2, 0.8, 1.0)
			
			overlay_control.draw_circle(sp, 8.0, col)
			overlay_control.draw_circle(sp, 8.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, Vector2(sp.x - 18.0, sp.y - 12.0), etype.substr(0, 3).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	
	# 3. Draw Powerup markers
	for p in editor_powerups:
		var sp := _world_to_screen(p["pos"])
		if sp.x >= -40.0 and sp.x <= 1000.0:
			overlay_control.draw_circle(sp, 7.0, Color(1.0, 0.9, 0.2))
			overlay_control.draw_circle(sp, 7.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, Vector2(sp.x - 8.0, sp.y - 10.0), "[P]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.2))
	
	# 3.b Draw Background Prop markers in World space
	for bp in editor_bg_props:
		var sp := _world_to_screen(bp["pos"])
		if sp.x >= -40.0 and sp.x <= 1000.0:
			overlay_control.draw_circle(sp, 8.0, Color(0.2, 0.8, 1.0))
			overlay_control.draw_circle(sp, 8.0, Color.WHITE, false, 1.2)
			var pname: String = bp["type"].substr(0, 4).to_upper()
			overlay_control.draw_string(font, Vector2(sp.x - 14.0, sp.y - 10.0), pname, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.3, 0.9, 1.0))

	# 4. Live drawing box
	if is_drawing_rect:
		var p1 := _world_to_screen(draw_rect_start)
		var p2 := _world_to_screen(draw_rect_current)
		var rx := minf(p1.x, p2.x)
		var ry := minf(p1.y, p2.y)
		var rw := maxf(16.0, absf(p2.x - p1.x))
		var rh := 16.0 if current_tool == ToolType.PLATFORM else maxf(20.0, absf(p2.y - p1.y))
		var rect := Rect2(rx, ry, rw, rh)
		overlay_control.draw_rect(rect, Color(0.3, 0.8, 1.0, 0.35))
		overlay_control.draw_rect(rect, Color(0.6, 1.0, 1.0), false, 2.0)
	
	# 5. Active Selection & Viewport Cursor / Reticle
	_draw_selection_and_cursor(font)
	
	# 6. Top Bar Panel (Glossy tactical dark glass)
	overlay_control.draw_rect(Rect2(0.0, 0.0, 960.0, 42.0), Color(0.06, 0.09, 0.14, 0.95))
	overlay_control.draw_line(Vector2(0.0, 42.0), Vector2(960.0, 42.0), Color(0.20, 0.35, 0.55), 1.5)
	
	# Top bar buttons
	_draw_btn(Rect2(12.0, 5.0, 110.0, 30.0), "▶ TEST PLAY", Color(0.18, 0.70, 0.30), font)
	_draw_btn(Rect2(130.0, 5.0, 95.0, 30.0), "THEME: %d" % Global.current_stage, Color(0.20, 0.35, 0.55), font)
	_draw_btn(Rect2(232.0, 5.0, 90.0, 30.0), "GRID: " + ("OFF" if grid_snap == 0 else "%dpx" % grid_snap), Color(0.20, 0.35, 0.55), font)
	_draw_btn(Rect2(330.0, 5.0, 85.0, 30.0), "SAVE", Color(0.25, 0.50, 0.80), font)
	_draw_btn(Rect2(422.0, 5.0, 85.0, 30.0), "LOAD", Color(0.25, 0.50, 0.80), font)
	_draw_btn(Rect2(514.0, 5.0, 105.0, 30.0), "RESET MAP", Color(0.45, 0.30, 0.20), font)
	_draw_btn(Rect2(626.0, 5.0, 85.0, 30.0), "CLEAR", Color(0.55, 0.20, 0.20), font)
	_draw_btn(Rect2(860.0, 5.0, 85.0, 30.0), "EXIT", Color(0.60, 0.15, 0.15), font)
	
	# Coordinates & telemetry label
	overlay_control.draw_string(font, Vector2(722.0, 24.0), "POS: %d M" % int(cam_x), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.85, 1.0))
	
	# 7. Bottom Timeline Scrubber
	overlay_control.draw_rect(Rect2(0.0, 448.0, 960.0, 92.0), Color(0.05, 0.08, 0.12, 0.96))
	overlay_control.draw_line(Vector2(0.0, 448.0), Vector2(960.0, 448.0), Color(0.20, 0.35, 0.55), 1.5)
	
	# Scrub bar track
	var track_rect := Rect2(40.0, 454.0, 880.0, 14.0)
	overlay_control.draw_rect(track_rect, Color(0.12, 0.16, 0.22))
	overlay_control.draw_rect(track_rect, Color(0.30, 0.45, 0.65), false, 1.0)
	
	# Current camera scrubber thumb
	var thumb_x := 40.0 + clampf((cam_x - 480.0) / LevelMaps.BOSS_TRIGGER_X, 0.0, 1.0) * 880.0
	overlay_control.draw_rect(Rect2(thumb_x - 6.0, 451.0, 12.0, 20.0), Color(0.2, 0.9, 1.0))
	overlay_control.draw_rect(Rect2(thumb_x - 6.0, 451.0, 12.0, 20.0), Color.WHITE, false, 1.2)
	
	# 8. Primary Tool Buttons (row 1 of shelf)
	var tools_labels := ["1. SELECTOR", "2. PLATFORMS", "3. GROUND", "4. ENEMIES", "5. POWERUPS", "6. PROPS", "7. ERASE"]
	var tool_enum_list := [ToolType.SELECT_MOVE, ToolType.PLATFORM, ToolType.GROUND, ToolType.ENEMY, ToolType.POWERUP, ToolType.BG_PROP, ToolType.ERASE]
	var tools_x: float = 14.0
	var tool_w: float = 125.0
	for i in range(7):
		var btn_rect := Rect2(tools_x + float(i) * (tool_w + 5.0), 476.0, tool_w, 26.0)
		var is_cur: bool = (current_tool == tool_enum_list[i])
		var b_col := Color(0.2, 0.55, 0.85) if is_cur else Color(0.12, 0.16, 0.22)
		_draw_btn(btn_rect, tools_labels[i], b_col, font, is_cur)
	
	# 9. Sub-Palette Selector / Inspector (row 2 of shelf)
	if current_tool == ToolType.SELECT_MOVE:
		if selected_item_idx >= 0:
			if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
				var sub_x: float = 20.0
				var sub_w: float = 72.0
				var cur_ptype: int = editor_platforms[selected_item_idx]["type"]
				for k in range(PLATFORM_NAMES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 508.0, sub_w, 24.0)
					var is_cur_p: bool = (cur_ptype == k)
					var p_col := Color(0.18, 0.65, 0.40) if is_cur_p else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, PLATFORM_NAMES[k], p_col, font, is_cur_p, 10)
				_draw_btn(Rect2(700.0, 508.0, 95.0, 24.0), "✖ DELETE", Color(0.75, 0.2, 0.2), font, false, 11)
			elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
				var sub_x: float = 20.0
				var sub_w: float = 100.0
				var cur_etype: String = editor_enemies[selected_item_idx]["type"]
				for k in range(ENEMY_TYPES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 5.0), 508.0, sub_w, 24.0)
					var is_cur_e: bool = (cur_etype == ENEMY_TYPES[k])
					var e_col := Color(0.85, 0.35, 0.20) if is_cur_e else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, ENEMY_LABELS[k], e_col, font, is_cur_e, 10)
				_draw_btn(Rect2(660.0, 508.0, 95.0, 24.0), "✖ DELETE", Color(0.75, 0.2, 0.2), font, false, 11)
			elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
				var sub_x: float = 20.0
				var sub_w: float = 120.0
				var cur_pwtype: int = editor_powerups[selected_item_idx]["type"]
				for k in range(3):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 508.0, sub_w, 24.0)
					var is_cur_pw: bool = (cur_pwtype == k + 1)
					var pw_col := Color(0.85, 0.75, 0.15) if is_cur_pw else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, POWERUP_NAMES[k], pw_col, font, is_cur_pw, 10)
				_draw_btn(Rect2(410.0, 508.0, 95.0, 24.0), "✖ DELETE", Color(0.75, 0.2, 0.2), font, false, 11)
			elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
				var sub_x: float = 12.0
				var sub_w: float = 68.0
				var cur_proptype: String = editor_bg_props[selected_item_idx]["type"]
				for k in range(PROP_TYPES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 508.0, sub_w, 24.0)
					var is_cur_bp: bool = (cur_proptype == PROP_TYPES[k])
					var bp_col := Color(0.2, 0.75, 0.9) if is_cur_bp else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, PROP_LABELS[k], bp_col, font, is_cur_bp, 9)
				_draw_btn(Rect2(866.0, 508.0, 82.0, 24.0), "✖ DELETE", Color(0.75, 0.2, 0.2), font, false, 10)
			elif selected_item_type == "ground":
				_draw_btn(Rect2(20.0, 508.0, 125.0, 24.0), "✖ DELETE GROUND", Color(0.75, 0.2, 0.2), font, false, 11)
				overlay_control.draw_string(font, Vector2(160.0, 524.0), "SELECTED GROUND SEGMENT • DRAG TO MOVE OR RESIZE • [DEL] TO REMOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.85, 1.0))
		else:
			overlay_control.draw_string(font, Vector2(24.0, 524.0), "★ SELECTOR ACTIVE: CLICK ANY PLATFORM, GROUND, ENEMY OR POWERUP TO SELECT & MOVE • [DEL] TO REMOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.35, 0.85, 1.0))
	elif current_tool == ToolType.PLATFORM:
		var sub_x: float = 20.0
		var sub_w: float = 75.0
		for k in range(PLATFORM_NAMES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 508.0, sub_w, 24.0)
			var is_p_cur: bool = (selected_platform_type == k)
			var p_col := Color(0.18, 0.65, 0.40) if is_p_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, PLATFORM_NAMES[k], p_col, font, is_p_cur, 10)
	elif current_tool == ToolType.ENEMY:
		var sub_x: float = 20.0
		var sub_w: float = 105.0
		for k in range(ENEMY_TYPES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 508.0, sub_w, 24.0)
			var is_e_cur: bool = (selected_enemy_type == ENEMY_TYPES[k])
			var e_col := Color(0.85, 0.35, 0.20) if is_e_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, ENEMY_LABELS[k], e_col, font, is_e_cur, 10)
	elif current_tool == ToolType.POWERUP:
		var sub_x: float = 20.0
		var sub_w: float = 120.0
		for k in range(3):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 508.0, sub_w, 24.0)
			var is_pw_cur: bool = (selected_powerup_type == k + 1)
			var pw_col := Color(0.85, 0.75, 0.15) if is_pw_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, POWERUP_NAMES[k], pw_col, font, is_pw_cur, 10)
	elif current_tool == ToolType.BG_PROP:
		var sub_x: float = 12.0
		var sub_w: float = 74.0
		for k in range(PROP_TYPES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 508.0, sub_w, 24.0)
			var is_bp_cur: bool = (selected_prop_type == PROP_TYPES[k])
			var bp_col := Color(0.2, 0.75, 0.9) if is_bp_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, PROP_LABELS[k], bp_col, font, is_bp_cur, 9)
	elif current_tool == ToolType.ERASE:
		overlay_control.draw_string(font, Vector2(24.0, 524.0), "✖ ERASE TOOL ACTIVE: CLICK ANY PLATFORM, ENEMY, GROUND OR POWERUP TO REMOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.45, 0.45))
	
	# 10. Toast message
	if toast_message != "":
		var toast_rect := Rect2(260.0, 48.0, 440.0, 26.0)
		overlay_control.draw_rect(toast_rect, Color(0.05, 0.08, 0.12, 0.90))
		overlay_control.draw_rect(toast_rect, Color(0.3, 0.8, 1.0), false, 1.2)
		overlay_control.draw_string(font, Vector2(275.0, 66.0), toast_message, HORIZONTAL_ALIGNMENT_CENTER, 410.0, 11, Color(1.0, 0.95, 0.3))

func _draw_corner_brackets(rect: Rect2, color: Color, length: float = 8.0, thickness: float = 2.0) -> void:
	# Top-left
	overlay_control.draw_line(rect.position, rect.position + Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(rect.position, rect.position + Vector2(0.0, length), color, thickness)
	# Top-right
	var tr := Vector2(rect.end.x, rect.position.y)
	overlay_control.draw_line(tr, tr - Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(tr, tr + Vector2(0.0, length), color, thickness)
	# Bottom-left
	var bl := Vector2(rect.position.x, rect.end.y)
	overlay_control.draw_line(bl, bl + Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(bl, bl - Vector2(0.0, length), color, thickness)
	# Bottom-right
	overlay_control.draw_line(rect.end, rect.end - Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(rect.end, rect.end - Vector2(0.0, length), color, thickness)

func _draw_selection_and_cursor(font: Font) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(t * 8.0)
	
	# 1. Draw Active Selection Highlight Frame
	if selected_item_idx >= 0:
		if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
			var pr: Rect2 = editor_platforms[selected_item_idx]["rect"]
			var sr := Rect2(_world_to_screen(pr.position), pr.size)
			overlay_control.draw_rect(sr, Color(0.2, 0.8, 1.0, 0.22))
			overlay_control.draw_rect(sr, Color(0.4, 0.95, 1.0, 0.85 + 0.15 * pulse), false, 2.0)
			_draw_corner_brackets(sr.grow(3.0), Color(1.0, 0.88, 0.3), 8.0, 2.5)
			var p_name: String = PLATFORM_NAMES[editor_platforms[selected_item_idx]["type"]]
			var tag_y: float = clampf(sr.position.y - 8.0, 56.0, 436.0)
			overlay_control.draw_string(font, Vector2(sr.position.x, tag_y), "★ SELECTED: PLATFORM (%s) [%d x %d]" % [p_name, int(pr.size.x), int(pr.size.y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.3))
		elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
			var gr: Rect2 = editor_ground[selected_item_idx]
			var sr := Rect2(_world_to_screen(gr.position), gr.size)
			overlay_control.draw_rect(sr, Color(0.2, 0.8, 0.4, 0.20))
			overlay_control.draw_rect(sr, Color(0.3, 1.0, 0.5, 0.85 + 0.15 * pulse), false, 2.0)
			_draw_corner_brackets(sr.grow(3.0), Color(1.0, 0.88, 0.3), 10.0, 2.5)
			var tag_y: float = clampf(sr.position.y - 8.0, 56.0, 436.0)
			overlay_control.draw_string(font, Vector2(sr.position.x, tag_y), "★ SELECTED: GROUND [%d x %d]" % [int(gr.size.x), int(gr.size.y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 1.0, 0.6))
		elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
			var ep: Vector2 = editor_enemies[selected_item_idx]["pos"]
			var sp := _world_to_screen(ep)
			overlay_control.draw_arc(sp, 16.0 + 2.0 * pulse, 0.0, TAU, 24, Color(1.0, 0.4, 0.3, 0.95), 2.0)
			_draw_corner_brackets(Rect2(sp - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), Color(1.0, 0.88, 0.3), 7.0, 2.0)
			var tag_y: float = clampf(sp.y - 20.0, 56.0, 436.0)
			overlay_control.draw_string(font, Vector2(sp.x - 30.0, tag_y), "★ SELECTED: ENEMY (%s)" % editor_enemies[selected_item_idx]["type"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.3))
		elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
			var pp: Vector2 = editor_powerups[selected_item_idx]["pos"]
			var sp := _world_to_screen(pp)
			overlay_control.draw_arc(sp, 15.0 + 2.0 * pulse, 0.0, TAU, 24, Color(1.0, 0.85, 0.2, 0.95), 2.0)
			_draw_corner_brackets(Rect2(sp - Vector2(15.0, 15.0), Vector2(30.0, 30.0)), Color(1.0, 0.88, 0.3), 7.0, 2.0)
			var pw_name: String = POWERUP_NAMES[editor_powerups[selected_item_idx]["type"] - 1]
			var tag_y: float = clampf(sp.y - 18.0, 56.0, 436.0)
			overlay_control.draw_string(font, Vector2(sp.x - 30.0, tag_y), "★ SELECTED: POWERUP (%s)" % pw_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.3))
		elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
			var bp: Vector2 = editor_bg_props[selected_item_idx]["pos"]
			var sp := _world_to_screen(bp)
			overlay_control.draw_arc(sp, 16.0 + 2.0 * pulse, 0.0, TAU, 24, Color(0.2, 0.9, 1.0, 0.95), 2.0)
			_draw_corner_brackets(Rect2(sp - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), Color(1.0, 0.88, 0.3), 7.0, 2.0)
			var tag_y: float = clampf(sp.y - 20.0, 56.0, 436.0)
			overlay_control.draw_string(font, Vector2(sp.x - 30.0, tag_y), "★ SELECTED: PROP (%s)" % editor_bg_props[selected_item_idx]["type"].to_upper().replace("_", " "), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.3))
	
	# 2. Draw Hover Outline when not selected
	if hovered_item_idx >= 0 and (hovered_item_type != selected_item_type or hovered_item_idx != selected_item_idx):
		if hovered_item_type == "platform" and hovered_item_idx < editor_platforms.size():
			var pr: Rect2 = editor_platforms[hovered_item_idx]["rect"]
			var sr := Rect2(_world_to_screen(pr.position), pr.size)
			_draw_corner_brackets(sr.grow(3.0), Color(0.2, 0.8, 1.0, 0.7), 6.0, 1.5)
		elif hovered_item_type == "ground" and hovered_item_idx < editor_ground.size():
			var gr: Rect2 = editor_ground[hovered_item_idx]
			var sr := Rect2(_world_to_screen(gr.position), gr.size)
			_draw_corner_brackets(sr.grow(3.0), Color(0.3, 0.9, 0.5, 0.7), 6.0, 1.5)
		elif hovered_item_type == "enemy" and hovered_item_idx < editor_enemies.size():
			var sp := _world_to_screen(editor_enemies[hovered_item_idx]["pos"])
			_draw_corner_brackets(Rect2(sp - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), Color(1.0, 0.5, 0.4, 0.8), 5.0, 1.5)
		elif hovered_item_type == "powerup" and hovered_item_idx < editor_powerups.size():
			var sp := _world_to_screen(editor_powerups[hovered_item_idx]["pos"])
			_draw_corner_brackets(Rect2(sp - Vector2(13.0, 13.0), Vector2(26.0, 26.0)), Color(1.0, 0.85, 0.3, 0.8), 5.0, 1.5)
		elif hovered_item_type == "bg_prop" and hovered_item_idx < editor_bg_props.size():
			var sp := _world_to_screen(editor_bg_props[hovered_item_idx]["pos"])
			_draw_corner_brackets(Rect2(sp - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), Color(0.2, 0.9, 1.0, 0.8), 5.0, 1.5)
	
	# 3. Viewport Cursor / Selector Reticle
	if is_mouse_in_viewport and not is_drawing_rect and not is_moving_item and not is_panning_cam:
		var sp := _world_to_screen(snapped_world_pos)
		if current_tool == ToolType.SELECT_MOVE:
			var csize: float = maxf(22.0, float(grid_snap) if grid_snap > 0 else 24.0)
			var crect := Rect2(sp - Vector2(csize, csize) * 0.5, Vector2(csize, csize))
			_draw_corner_brackets(crect, Color(0.2, 0.9, 1.0, 0.95), 6.0, 2.0)
			overlay_control.draw_circle(sp, 2.5, Color(0.4, 0.95, 1.0))
			overlay_control.draw_string(font, sp + Vector2(12.0, -6.0), "SELECTOR [%d, %d]" % [int(snapped_world_pos.x), int(snapped_world_pos.y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.85, 1.0))
		elif current_tool == ToolType.PLATFORM:
			var g_rect := Rect2(sp, Vector2(64.0, 16.0))
			overlay_control.draw_rect(g_rect, Color(0.2, 0.8, 1.0, 0.25))
			overlay_control.draw_rect(g_rect, Color(0.3, 0.9, 1.0, 0.85), false, 1.5)
			overlay_control.draw_string(font, sp + Vector2(4.0, 12.0), "+ PLATFORM", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		elif current_tool == ToolType.GROUND:
			var g_rect := Rect2(sp, Vector2(96.0, 80.0))
			overlay_control.draw_rect(g_rect, Color(0.3, 0.7, 0.3, 0.22))
			overlay_control.draw_rect(g_rect, Color(0.4, 0.9, 0.4, 0.85), false, 1.5)
			overlay_control.draw_string(font, sp + Vector2(6.0, 18.0), "+ GROUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		elif current_tool == ToolType.ENEMY:
			overlay_control.draw_circle(sp, 8.0, Color(1.0, 0.3, 0.3, 0.6))
			overlay_control.draw_circle(sp, 8.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, sp + Vector2(12.0, 4.0), "+ %s" % selected_enemy_type.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.4, 0.4))
		elif current_tool == ToolType.POWERUP:
			overlay_control.draw_circle(sp, 7.0, Color(1.0, 0.85, 0.2, 0.6))
			overlay_control.draw_circle(sp, 7.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, sp + Vector2(12.0, 4.0), "+ POWERUP", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.85, 0.2))
		elif current_tool == ToolType.BG_PROP:
			overlay_control.draw_circle(sp, 8.0, Color(0.2, 0.8, 1.0, 0.6))
			overlay_control.draw_circle(sp, 8.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, sp + Vector2(12.0, 4.0), "+ %s" % selected_prop_type.to_upper().replace("_", " "), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.2, 0.9, 1.0))
		elif current_tool == ToolType.ERASE:
			overlay_control.draw_circle(sp, 20.0, Color(1.0, 0.2, 0.2, 0.18))
			overlay_control.draw_arc(sp, 20.0, 0.0, TAU, 24, Color(1.0, 0.3, 0.3, 0.85), 1.5)
			overlay_control.draw_line(sp - Vector2(10, 10), sp + Vector2(10, 10), Color(1.0, 0.2, 0.2), 2.2)
			overlay_control.draw_line(sp - Vector2(-10, 10), sp + Vector2(-10, 10), Color(1.0, 0.2, 0.2), 2.2)
			overlay_control.draw_string(font, sp + Vector2(16.0, 4.0), "ERASER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.35, 0.35))

func _draw_btn(rect: Rect2, text: String, base_col: Color, font: Font, is_highlight: bool = false, fsize: int = 11) -> void:
	overlay_control.draw_rect(rect, base_col)
	var border_col := Color.WHITE if is_highlight else Color(0.35, 0.50, 0.70)
	overlay_control.draw_rect(rect, border_col, false, 1.2 if not is_highlight else 2.0)
	var text_pos := Vector2(rect.position.x + 8.0, rect.position.y + rect.size.y * 0.65)
	overlay_control.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10.0, fsize, Color.WHITE)
