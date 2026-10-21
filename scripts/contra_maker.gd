class_name ContraMaker
extends CanvasLayer

# =============================================================================
# CONTRA MAKER - IN-GAME TACTICAL LEVEL EDITOR (ENHANCED)
# Multi-Altitude Vertical & Horizontal Terrain Support, Full Unit & Platform Palette
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

enum EnemyCategory {
	CORE,
	SECTOR_1_4,
	SECTOR_5_8,
	HAZARDS,
	BOSS
}

var stage: Node2D = null
var camera: Camera2D = null

var is_active: bool = false
var is_test_playing: bool = false
var has_unsaved_changes: bool = false

# Current active tool selection
var current_tool: ToolType = ToolType.SELECT_MOVE
var selected_platform_type: int = 0
var selected_platform_is_drop: bool = false
var selected_enemy_category: EnemyCategory = EnemyCategory.CORE
var selected_enemy_type: String = "soldier"
var selected_powerup_type: int = 1 # 1: SPREAD, 2: MACHINE, 3: LASER, 4: BARRIER, 5: RAPID
var selected_prop_type: String = "radar_dish"
var grid_snap: int = 32 # 32, 16, 0

# Camera navigation in editor (Both Horizontal & Vertical)
var cam_x: float = 480.0
var cam_y: float = 270.0
var cam_pan_speed: float = 750.0

const CAM_MIN_X: float = 480.0
const CAM_MAX_X: float = 9320.0
const CAM_MIN_Y: float = 110.0
const CAM_MAX_Y: float = 310.0

var is_panning_cam: bool = false
var pan_drag_start: Vector2 = Vector2.ZERO
var pan_cam_start: Vector2 = Vector2.ZERO

# Scrollbar drag states
var is_dragging_h_scroll: bool = false
var is_dragging_v_scroll: bool = false

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
var selection_floating_del_rect: Rect2 = Rect2()
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
	"TURF", "GIRDER", "BRIDGE", "PERCH", "ICE", "LAVA", "ENERGY", "TECH", "BIO", "WATERFALL"
]

const ENEMY_CATEGORY_NAMES: Array[String] = [
	"CORE (6)", "SECTOR 1-4 (8)", "SECTOR 5-8 (8)", "HAZARDS (2)", "BOSS (1)"
]

const ENEMIES_BY_CATEGORY: Dictionary = {
	EnemyCategory.CORE: [
		{"id": "soldier", "label": "SOLDIER", "color": Color(1.0, 0.35, 0.35), "tag": "SOL"},
		{"id": "sniper", "label": "SNIPER", "color": Color(0.3, 0.9, 0.4), "tag": "SNP"},
		{"id": "turret", "label": "TURRET", "color": Color(0.9, 0.7, 0.2), "tag": "TUR"},
		{"id": "grenadier", "label": "GRENADIER", "color": Color(1.0, 0.5, 0.1), "tag": "GRN"},
		{"id": "crawler", "label": "CRAWLER", "color": Color(0.8, 0.3, 0.9), "tag": "CRW"},
		{"id": "drone", "label": "DRONE", "color": Color(0.2, 0.8, 1.0), "tag": "DRN"}
	],
	EnemyCategory.SECTOR_1_4: [
		{"id": "guerrilla_gunner", "label": "GUERRILLA", "color": Color(0.35, 0.85, 0.35), "tag": "GUN"},
		{"id": "flame_trooper", "label": "FLAME", "color": Color(1.0, 0.4, 0.1), "tag": "FLM"},
		{"id": "scuba_commando", "label": "SCUBA", "color": Color(0.25, 0.65, 0.95), "tag": "SCU"},
		{"id": "torpedo_drone", "label": "TORPEDO", "color": Color(0.2, 0.9, 0.9), "tag": "TOR"},
		{"id": "acid_spitter", "label": "ACID SPIT", "color": Color(0.9, 0.2, 0.4), "tag": "ACD"},
		{"id": "ceiling_stalker", "label": "STALKER", "color": Color(0.75, 0.25, 0.85), "tag": "STK"},
		{"id": "cryo_trooper", "label": "CRYO", "color": Color(0.6, 0.85, 1.0), "tag": "CRY"},
		{"id": "sled_raider", "label": "SLED RAIDER", "color": Color(0.7, 0.9, 1.0), "tag": "SLD"}
	],
	EnemyCategory.SECTOR_5_8: [
		{"id": "slag_mech", "label": "SLAG MECH", "color": Color(1.0, 0.45, 0.2), "tag": "MCH"},
		{"id": "conveyor_droid", "label": "CONVEYOR", "color": Color(0.85, 0.55, 0.3), "tag": "DRO"},
		{"id": "tesla_trooper", "label": "TESLA", "color": Color(0.4, 0.85, 1.0), "tag": "TSL"},
		{"id": "spark_drone", "label": "SPARK DRONE", "color": Color(0.3, 0.95, 1.0), "tag": "SPK"},
		{"id": "jetpack_marine", "label": "JETPACK", "color": Color(0.85, 0.7, 1.0), "tag": "JET"},
		{"id": "rail_turret", "label": "RAIL TURRET", "color": Color(0.5, 0.75, 1.0), "tag": "RAI"},
		{"id": "tentacle_whipper", "label": "WHIPPER", "color": Color(0.95, 0.3, 0.65), "tag": "TNT"},
		{"id": "psychic_orb", "label": "PSYCHIC ORB", "color": Color(1.0, 0.45, 1.0), "tag": "ORB"}
	],
	EnemyCategory.HAZARDS: [
		{"id": "spore_pod", "label": "SPORE POD", "color": Color(0.85, 0.3, 0.5), "tag": "POD"},
		{"id": "bio_eye", "label": "BIO EYE", "color": Color(0.95, 0.2, 0.35), "tag": "EYE"}
	],
	EnemyCategory.BOSS: [
		{"id": "mini_boss", "label": "★ MINI-BOSS", "color": Color(1.0, 0.85, 0.2), "tag": "BOSS"}
	]
}

const POWERUP_NAMES: Array[String] = [
	"SPREAD GUN", "MACHINE GUN", "LASER BEAM", "BARRIER SHIELD", "RAPID FIRE"
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
		cam_x = clampf(camera.global_position.x, CAM_MIN_X, CAM_MAX_X)
		cam_y = clampf(camera.global_position.y, CAM_MIN_Y, CAM_MAX_Y)

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
		camera.zoom = Vector2.ONE
		camera.offset = Vector2.ZERO
		camera.limit_left = -10000000
		camera.limit_right = 10000000
		camera.limit_top = -10000000
		camera.limit_bottom = 10000000
		cam_x = clampf(camera.global_position.x, CAM_MIN_X, CAM_MAX_X)
		cam_y = clampf(camera.global_position.y, CAM_MIN_Y, CAM_MAX_Y)
		camera.global_position = Vector2(cam_x, cam_y)
	
	# Clear active enemy bullets when entering editor
	if stage != null:
		for child in stage.get_children():
			if child.is_in_group("bullet") or child.name.to_lower().contains("bullet"):
				child.queue_free()
	
	if editor_ground.is_empty() and editor_platforms.is_empty():
		_load_current_stage_geometry()
	
	show_toast("CONTRA MAKER ACTIVATED - MULTI-ALTITUDE EDITING READY")
	overlay_control.queue_redraw()

func close_editor() -> void:
	# DO NOT auto-save! Only save and update the game when the user clicks SAVE.
	is_active = false
	is_test_playing = false
	visible = false
	Global.is_maker_mode = false
	
	if camera != null:
		if Global.current_stage >= 2:
			camera.limit_top = -140
			camera.limit_bottom = 580
		else:
			camera.limit_top = 0
			camera.limit_bottom = 540
		camera.limit_left = 0
		camera.limit_right = 10000000
	
	# Restore touch controls for normal gameplay
	var tc = get_tree().root.find_child("TouchControls", true, false)
	if tc != null:
		tc.visible = true
	
	# If closed without saving, revert unsaved changes back to saved stage state
	if has_unsaved_changes:
		_load_current_stage_geometry(false)
		show_toast("EXITED EDITOR (UNSAVED CHANGES DISCARDED)")
	else:
		show_toast("EXITED CONTRA MAKER")
	
	overlay_control.queue_redraw()

func _load_current_stage_geometry(force_default: bool = false) -> void:
	editor_ground.clear()
	editor_platforms.clear()
	editor_enemies.clear()
	editor_powerups.clear()
	editor_bg_props.clear()
	
	var map_info: Dictionary
	if force_default:
		map_info = LevelMaps.get_default_map_data(Global.current_stage)
	else:
		map_info = LevelMaps.get_map_data(Global.current_stage)
	
	for g in map_info.get("ground_segments", []):
		editor_ground.append(g)
	for p in map_info.get("platforms", []):
		var p_copy: Dictionary = p.duplicate(true)
		p_copy["type"] = LevelMaps.parse_platform_type(p_copy.get("type", 0))
		editor_platforms.append(p_copy)
	
	# Load custom enemies if present in saved stage, else default landmarks
	if map_info.has("custom_enemies") and not force_default:
		for e in map_info["custom_enemies"]:
			editor_enemies.append({"type": e["type"], "pos": Vector2(e["x"], e["y"])})
	else:
		var g_list: Array = map_info.get("ground_segments", [])
		var p_list: Array = map_info.get("platforms", [])
		if not g_list.is_empty():
			for i in range(mini(8, g_list.size())):
				var g: Rect2 = g_list[i]
				editor_enemies.append({"type": "turret", "pos": Vector2(g.position.x + g.size.x * 0.65, g.position.y - 5.0)})
				if i % 2 == 1:
					editor_enemies.append({"type": "grenadier", "pos": Vector2(g.position.x + g.size.x * 0.35, g.position.y - 8.0)})
					editor_enemies.append({"type": "crawler", "pos": Vector2(g.position.x + g.size.x * 0.20, g.position.y - 6.0)})
		if not p_list.is_empty():
			for i in range(mini(6, p_list.size())):
				var p: Rect2 = p_list[i * 3 % p_list.size()]["rect"]
				editor_enemies.append({"type": "sniper", "pos": Vector2(p.position.x + p.size.x * 0.5, p.position.y - 6.0)})
	
	# Load custom powerups if present in saved stage, else default sensors
	if map_info.has("custom_powerups") and not force_default:
		for pw in map_info["custom_powerups"]:
			editor_powerups.append({"type": pw["type"], "pos": Vector2(pw["x"], pw["y"])})
	else:
		for k in range(5):
			editor_powerups.append({
				"type": (k % 5) + 1,
				"pos": Vector2(float(k) * 1600.0 + 500.0, 220.0)
			})
	
	# Load custom props if present in saved stage, else discover from stage
	if map_info.has("custom_bg_props") and not force_default:
		for bp in map_info["custom_bg_props"]:
			editor_bg_props.append({"type": bp["type"], "pos": Vector2(bp["x"], bp["y"])})
	elif stage != null:
		for child in stage.get_children():
			if child is AnimatedBgProp or child.is_in_group("bg_props") or child.is_in_group("custom_editor_props"):
				var ptype := "radar_dish"
				if child.has_meta("prop_type"):
					ptype = child.get_meta("prop_type")
				elif child.get("prop_data") != null and child.prop_data != null:
					var path: String = child.prop_data.resource_path
					for key in PROP_RESOURCES:
						if PROP_RESOURCES[key] == path:
							ptype = key
							break
				editor_bg_props.append({
					"type": ptype,
					"pos": child.global_position
				})
				child.add_to_group("custom_editor_props")
	
	_apply_to_stage()

func _apply_to_stage() -> void:
	if stage == null:
		return
	
	if "ground_segments" in stage and stage.ground_segments != null:
		stage.ground_segments.clear()
		for g in editor_ground:
			stage.ground_segments.append(g)
	
	if "platforms" in stage and stage.platforms != null:
		stage.platforms.clear()
		for p in editor_platforms:
			stage.platforms.append(p.duplicate(true))
	
	if stage.has_method("_setup_colliders"):
		stage._setup_colliders()
	
	_sync_editor_bg_props_to_stage()
	stage.queue_redraw()
	has_unsaved_changes = true
	level_data_modified.emit()

func _sync_editor_bg_props_to_stage() -> void:
	if stage == null:
		return
	
	for child in stage.get_children():
		if child is AnimatedBgProp or child.is_in_group("bg_props") or child.is_in_group("custom_editor_props"):
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
			inst.set_meta("prop_type", ptype)
			inst.add_to_group("bg_props")
			inst.add_to_group("custom_editor_props")
			stage.add_child(inst)

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_message = ""
	
	if not is_active or is_test_playing:
		return
	
	# 2D Camera keyboard navigation (Arrow keys or WASD)
	var move_x: float = 0.0
	var move_y: float = 0.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		move_x += 1.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		move_y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		move_y += 1.0
	
	if move_x != 0.0 or move_y != 0.0:
		cam_x = clampf(cam_x + move_x * cam_pan_speed * delta, CAM_MIN_X, CAM_MAX_X)
		cam_y = clampf(cam_y + move_y * cam_pan_speed * delta, CAM_MIN_Y, CAM_MAX_Y)
		if camera != null:
			camera.global_position = Vector2(cam_x, cam_y)
		if stage != null:
			stage.queue_redraw()
	
	overlay_control.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
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
	
	if is_test_playing and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		stop_test_play()
		get_viewport().set_input_as_handled()
		return
	
	if is_test_playing:
		return
	
	# Save shortcut Ctrl+S
	if event is InputEventKey and event.pressed and event.keycode == KEY_S and (event.ctrl_pressed or event.meta_pressed):
		save_level_to_file(1)
		get_viewport().set_input_as_handled()
		return
	
	# Hotkeys 1..7 for tools
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
		var p_name: String = PLATFORM_NAMES[editor_platforms[selected_item_idx].get("type", 0)]
		editor_platforms.remove_at(selected_item_idx)
		show_toast("✖ DELETED PLATFORM (" + p_name + ")")
	elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
		editor_ground.remove_at(selected_item_idx)
		show_toast("✖ DELETED GROUND")
	elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
		var ep: Vector2 = editor_enemies[selected_item_idx]["pos"]
		var etype: String = editor_enemies[selected_item_idx].get("type", "enemy")
		editor_enemies.remove_at(selected_item_idx)
		if stage != null:
			for child in stage.get_children():
				if _is_enemy_node(child) and child.global_position.distance_to(ep) < 55.0:
					child.queue_free()
		show_toast("✖ DELETED ENEMY: " + etype.to_upper())
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
		var ptype: String = editor_bg_props[selected_item_idx].get("type", "prop")
		editor_bg_props.remove_at(selected_item_idx)
		if stage != null:
			for child in stage.get_children():
				if child is AnimatedBgProp or child.is_in_group("bg_props") or child.is_in_group("custom_editor_props"):
					if _is_pos_hitting_prop(bp, child.global_position):
						child.queue_free()
		_sync_editor_bg_props_to_stage()
		show_toast("✖ DELETED PROP: " + ptype.to_upper().replace("_", " "))
	selected_item_idx = -1
	selected_item_type = ""
	_apply_to_stage()
	overlay_control.queue_redraw()

func _is_pos_hitting_platform(world_pos: Vector2, pr: Rect2) -> bool:
	var x_min := pr.position.x - 20.0
	var x_max := pr.end.x + 20.0
	var y_min := pr.position.y - 32.0
	var y_max := pr.position.y + maxf(pr.size.y, 36.0) + 18.0
	var hit_box := Rect2(x_min, y_min, x_max - x_min, y_max - y_min)
	return hit_box.has_point(world_pos)

func _get_platform_distance(world_pos: Vector2, pr: Rect2) -> float:
	var clamped_x := clampf(world_pos.x, pr.position.x, pr.end.x)
	var surface_pt := Vector2(clamped_x, pr.position.y)
	return world_pos.distance_to(surface_pt)

func _delete_platform_at(world_pos: Vector2) -> bool:
	var best_p_idx := -1
	var min_p_dist := 999999.0
	for i in range(editor_platforms.size() - 1, -1, -1):
		var pr: Rect2 = editor_platforms[i]["rect"]
		if _is_pos_hitting_platform(world_pos, pr):
			var d := _get_platform_distance(world_pos, pr)
			if d < min_p_dist:
				min_p_dist = d
				best_p_idx = i
	if best_p_idx >= 0:
		var p_name: String = PLATFORM_NAMES[editor_platforms[best_p_idx].get("type", 0)]
		editor_platforms.remove_at(best_p_idx)
		if selected_item_type == "platform" and selected_item_idx == best_p_idx:
			selected_item_idx = -1
			selected_item_type = ""
		elif selected_item_type == "platform" and selected_item_idx > best_p_idx:
			selected_item_idx -= 1
		_apply_to_stage()
		show_toast("✖ DELETED PLATFORM (" + p_name + ")")
		overlay_control.queue_redraw()
		return true
	return false

func _is_pos_hitting_prop(world_pos: Vector2, prop_pos: Vector2) -> bool:
	if world_pos.distance_to(prop_pos) <= 42.0:
		return true
	var prop_rect := Rect2(prop_pos.x - 36.0, prop_pos.y - 56.0, 72.0, 68.0)
	return prop_rect.has_point(world_pos)

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
	if n_name.contains("enemy") or n_name.contains("turret") or n_name.contains("sniper") or n_name.contains("grenadier") or n_name.contains("crawler") or n_name.contains("drone") or n_name.contains("soldier") or n_name.contains("boss") or n_name.contains("trooper") or n_name.contains("mech") or n_name.contains("droid"):
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
	
	# 1. Direct core hit on enemies
	for i in range(editor_enemies.size() - 1, -1, -1):
		if world_pos.distance_to(editor_enemies[i]["pos"]) <= 22.0:
			hovered_item_type = "enemy"
			hovered_item_idx = i
			return
	
	# 2. Platforms (reverse search + distance scoring)
	var best_p_idx := -1
	var min_p_dist := 999999.0
	for i in range(editor_platforms.size() - 1, -1, -1):
		var pr: Rect2 = editor_platforms[i]["rect"]
		if _is_pos_hitting_platform(world_pos, pr):
			var d := _get_platform_distance(world_pos, pr)
			if d < min_p_dist:
				min_p_dist = d
				best_p_idx = i
	if best_p_idx >= 0:
		hovered_item_type = "platform"
		hovered_item_idx = best_p_idx
		return
	
	# 3. Enemies (broader box)
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and _is_node_at_world_pos(child, world_pos):
				hovered_item_type = "enemy"
				for j in range(editor_enemies.size() - 1, -1, -1):
					if editor_enemies[j]["pos"].distance_to(child.global_position) < 50.0:
						hovered_item_idx = j
						return
	for i in range(editor_enemies.size() - 1, -1, -1):
		if _is_pos_hitting_enemy(world_pos, editor_enemies[i]["pos"]):
			hovered_item_type = "enemy"
			hovered_item_idx = i
			return
	
	# 4. Powerups
	for i in range(editor_powerups.size() - 1, -1, -1):
		var pp: Vector2 = editor_powerups[i]["pos"]
		if world_pos.distance_to(pp) < 32.0 or Rect2(pp.x - 22.0, pp.y - 22.0, 44.0, 44.0).has_point(world_pos):
			hovered_item_type = "powerup"
			hovered_item_idx = i
			return
	
	# 5. Ground
	for i in range(editor_ground.size() - 1, -1, -1):
		if editor_ground[i].grow_individual(8.0, 12.0, 8.0, 12.0).has_point(world_pos):
			hovered_item_type = "ground"
			hovered_item_idx = i
			return
	
	# 6. Background Props (checked last so foreground items have priority)
	for i in range(editor_bg_props.size() - 1, -1, -1):
		if _is_pos_hitting_prop(world_pos, editor_bg_props[i]["pos"]):
			hovered_item_type = "bg_prop"
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
	visible = true
	
	var spawn_pos := Vector2(camera.global_position.x - 120.0, 360.0)
	if stage.has_method("get_safe_respawn_position"):
		spawn_pos = stage.get_safe_respawn_position(camera.global_position.x)
	
	var player_node: CharacterBody2D = stage.get_node_or_null("Player") as CharacterBody2D
	if player_node != null:
		player_node.global_position = spawn_pos
		player_node.velocity = Vector2.ZERO
		if "state" in player_node:
			player_node.state = 0
	
	_spawn_editor_enemies_for_test()
	
	show_toast("★ LIVE TEST • PLAYER IS INVINCIBLE (GOD MODE) • PRESS F1 TO STOP")
	test_play_requested.emit(spawn_pos)
	overlay_control.queue_redraw()

func stop_test_play() -> void:
	is_test_playing = false
	visible = true
	
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
		
		# Direct scene resolution from stage exports or scenes directory
		if etype == "mini_boss":
			scn = load("res://scenes/mini_boss.tscn")
		elif etype == "spore_pod":
			var sp_script = stage.get("spore_pod_script")
			if sp_script != null:
				var pod = sp_script.new()
				pod.position = pos
				pod.add_to_group("enemies")
				stage.add_child(pod)
			continue
		elif etype == "bio_eye":
			var eye_script = stage.get("bio_eye_script")
			if eye_script != null:
				var eye = eye_script.new()
				eye.position = pos
				eye.add_to_group("enemies")
				stage.add_child(eye)
			continue
		else:
			var scene_prop_name := etype + "_scene"
			scn = stage.get(scene_prop_name)
			if scn == null:
				var fallback_path := "res://scenes/enemy_" + etype + ".tscn"
				if ResourceLoader.exists(fallback_path):
					scn = load(fallback_path)
		
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

# Save / Load
func save_level_to_file(slot_id: int = 1) -> void:
	var dir_path := "user://custom_levels"
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	var data: Dictionary = {
		"stage_theme": Global.current_stage,
		"cam_x": cam_x,
		"cam_y": cam_y,
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
		data["platforms"].append({
			"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y,
			"type": p.get("type", 0),
			"is_drop": p.get("is_drop", false),
			"variant": p.get("variant", "default")
		})
	for e in editor_enemies:
		data["enemies"].append({"type": e["type"], "x": e["pos"].x, "y": e["pos"].y})
	for pw in editor_powerups:
		data["powerups"].append({"type": pw["type"], "x": pw["pos"].x, "y": pw["pos"].y})
	for bp in editor_bg_props:
		data["bg_props"].append({"type": bp["type"], "x": bp["pos"].x, "y": bp["pos"].y})
	
	var json_str := JSON.stringify(data, "	")
	
	# 1. Save to persistent stage override file (permanently loaded into game)
	var stage_file_path := "%s/stage_%d.json" % [dir_path, Global.current_stage]
	var s_file := FileAccess.open(stage_file_path, FileAccess.WRITE)
	if s_file != null:
		s_file.store_string(json_str)
		s_file.close()
	
	# 2. Save to specified level slot file
	var file_path := "%s/level_slot_%d.json" % [dir_path, slot_id]
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
	
	# 3. Apply and update directly into the live game stage
	if stage != null:
		if "ground_segments" in stage and stage.ground_segments != null:
			stage.ground_segments.clear()
			for g in editor_ground:
				stage.ground_segments.append(g)
		if "platforms" in stage and stage.platforms != null:
			stage.platforms.clear()
			for p in editor_platforms:
				stage.platforms.append(p.duplicate(true))
		if stage.has_method("_setup_colliders"):
			stage._setup_colliders()
		
		_sync_editor_bg_props_to_stage()
		
		# Replace stage static enemies and powerups with editor layout
		for child in stage.get_children():
			if _is_enemy_node(child) or child.is_in_group("enemies") or child.is_in_group("powerup"):
				child.queue_free()
		_spawn_editor_enemies_for_test()
		
		stage.queue_redraw()
	
	has_unsaved_changes = false
	show_toast("✔ STAGE %d SAVED & UPDATED INTO GAME!" % Global.current_stage)
	overlay_control.queue_redraw()

func load_level_from_file(slot_id: int = 1) -> void:
	var file_path := "user://custom_levels/level_slot_%d.json" % slot_id
	if not FileAccess.file_exists(file_path):
		show_toast("NO SAVED FILE IN SLOT %d" % slot_id)
		return
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		show_toast("FAILED TO READ SLOT %d" % slot_id)
		return
	
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK or not (json.data is Dictionary):
		show_toast("CORRUPT SAVE FILE IN SLOT %d" % slot_id)
		return
	
	var data: Dictionary = json.data
	Global.current_stage = clampi(data.get("stage_theme", Global.current_stage), 1, 8)
	if stage != null and stage.has_method("_setup_background"):
		stage._setup_background()
	
	cam_x = clampf(data.get("cam_x", 480.0), CAM_MIN_X, CAM_MAX_X)
	cam_y = clampf(data.get("cam_y", 270.0), CAM_MIN_Y, CAM_MAX_Y)
	if camera != null:
		camera.global_position = Vector2(cam_x, cam_y)
	
	editor_ground.clear()
	for g_dict in data.get("ground_segments", []):
		editor_ground.append(Rect2(g_dict["x"], g_dict["y"], g_dict["w"], g_dict["h"]))
	
	editor_platforms.clear()
	for p_dict in data.get("platforms", []):
		editor_platforms.append({
			"rect": Rect2(p_dict["x"], p_dict["y"], p_dict["w"], p_dict["h"]),
			"type": LevelMaps.parse_platform_type(p_dict.get("type", 0)),
			"is_drop": p_dict.get("is_drop", false),
			"variant": p_dict.get("variant", "default")
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
	
	# Also update active stage file so game uses it
	var dir_path := "user://custom_levels"
	var stage_file_path := "%s/stage_%d.json" % [dir_path, Global.current_stage]
	var s_file := FileAccess.open(stage_file_path, FileAccess.WRITE)
	if s_file != null:
		s_file.store_string(json_str)
		s_file.close()
	
	_apply_to_stage()
	show_toast("✔ LOADED SLOT %d & APPLIED TO STAGE %d" % [slot_id, Global.current_stage])

func _snap_val(val: float) -> float:
	if grid_snap <= 0:
		return val
	return roundf(val / float(grid_snap)) * float(grid_snap)

func _snap_vec(vec: Vector2) -> Vector2:
	return Vector2(_snap_val(vec.x), _snap_val(vec.y))

# Exact 2D screen to world & world to screen transformations
func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam_pos := Vector2(cam_x, cam_y)
	if camera != null:
		cam_pos = camera.global_position
	return screen_pos + cam_pos - Vector2(480.0, 270.0)

func _world_to_screen(world_pos: Vector2) -> Vector2:
	var cam_pos := Vector2(cam_x, cam_y)
	if camera != null:
		cam_pos = camera.global_position
	return world_pos - cam_pos + Vector2(480.0, 270.0)

# Scrollbar math helpers
func _update_h_scroll_from_mouse(mouse_x: float) -> void:
	var track_x := 38.0
	var track_w := 874.0
	var thumb_w := 80.0
	var ratio := clampf((mouse_x - track_x - thumb_w * 0.5) / (track_w - thumb_w), 0.0, 1.0)
	cam_x = CAM_MIN_X + ratio * (CAM_MAX_X - CAM_MIN_X)
	if camera != null:
		camera.global_position.x = cam_x
	if stage != null:
		stage.queue_redraw()
	overlay_control.queue_redraw()

func _update_v_scroll_from_mouse(mouse_y: float) -> void:
	var track_y := 66.0
	var track_h := 352.0
	var thumb_h := 55.0
	var ratio := clampf((mouse_y - track_y - thumb_h * 0.5) / (track_h - thumb_h), 0.0, 1.0)
	cam_y = CAM_MIN_Y + ratio * (CAM_MAX_Y - CAM_MIN_Y)
	if camera != null:
		camera.global_position.y = cam_y
	if stage != null:
		stage.queue_redraw()
	overlay_control.queue_redraw()

func _get_enemy_def(etype: String) -> Dictionary:
	for cat in ENEMIES_BY_CATEGORY:
		for item in ENEMIES_BY_CATEGORY[cat]:
			if item["id"] == etype:
				return item
	return {"id": etype, "label": etype.to_upper(), "color": Color(1.0, 0.35, 0.35), "tag": etype.substr(0, 3).to_upper()}

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
	
	# Mouse button events
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# 0. Floating quick-delete button directly above selected item
				if selected_item_idx >= 0 and selection_floating_del_rect.size != Vector2.ZERO:
					if selection_floating_del_rect.has_point(mb.position):
						_delete_selected_item()
						get_viewport().set_input_as_handled()
						return
				
				# 1. Top toolbar (y: 0 to 42)
				if mb.position.y < 42.0:
					_handle_toolbar_click(mb.position)
					return
				
				# 2. Horizontal Scrollbar (y: 440 to 460)
				if mb.position.y >= 440.0 and mb.position.y <= 460.0:
					if Rect2(10.0, 440.0, 26.0, 20.0).has_point(mb.position):
						cam_x = maxf(CAM_MIN_X, cam_x - 500.0)
						if camera != null: camera.global_position.x = cam_x
						if stage != null: stage.queue_redraw()
						overlay_control.queue_redraw()
						return
					elif Rect2(912.0, 440.0, 26.0, 20.0).has_point(mb.position):
						cam_x = minf(CAM_MAX_X, cam_x + 500.0)
						if camera != null: camera.global_position.x = cam_x
						if stage != null: stage.queue_redraw()
						overlay_control.queue_redraw()
						return
					elif Rect2(36.0, 440.0, 874.0, 20.0).has_point(mb.position):
						is_dragging_h_scroll = true
						_update_h_scroll_from_mouse(mb.position.x)
						return
					return
				
				# 3. Bottom Tool Shelf (y > 460.0)
				if mb.position.y > 460.0:
					_handle_bottom_shelf_click(mb.position)
					return
				
				# 4. Vertical Scrollbar (x: 938 to 960, y: 42 to 440)
				if mb.position.x >= 938.0 and mb.position.y >= 42.0 and mb.position.y < 440.0:
					if Rect2(938.0, 42.0, 22.0, 22.0).has_point(mb.position):
						cam_y = maxf(CAM_MIN_Y, cam_y - 60.0)
						if camera != null: camera.global_position.y = cam_y
						if stage != null: stage.queue_redraw()
						overlay_control.queue_redraw()
						return
					elif Rect2(938.0, 416.0, 22.0, 24.0).has_point(mb.position):
						cam_y = minf(CAM_MAX_Y, cam_y + 60.0)
						if camera != null: camera.global_position.y = cam_y
						if stage != null: stage.queue_redraw()
						overlay_control.queue_redraw()
						return
					elif Rect2(938.0, 64.0, 22.0, 352.0).has_point(mb.position):
						is_dragging_v_scroll = true
						_update_v_scroll_from_mouse(mb.position.y)
						return
					return
			else:
				is_dragging_h_scroll = false
				is_dragging_v_scroll = false
		
		# Mouse Wheel Scrolling
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if Input.is_key_pressed(KEY_SHIFT):
				cam_x = maxf(CAM_MIN_X, cam_x - 180.0)
				if camera != null: camera.global_position.x = cam_x
			else:
				cam_y = maxf(CAM_MIN_Y, cam_y - 45.0)
				if camera != null: camera.global_position.y = cam_y
			if stage != null: stage.queue_redraw()
			overlay_control.queue_redraw()
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if Input.is_key_pressed(KEY_SHIFT):
				cam_x = minf(CAM_MAX_X, cam_x + 180.0)
				if camera != null: camera.global_position.x = cam_x
			else:
				cam_y = minf(CAM_MAX_Y, cam_y + 45.0)
				if camera != null: camera.global_position.y = cam_y
			if stage != null: stage.queue_redraw()
			overlay_control.queue_redraw()
			return
		
		# Right Click: Instant Delete Item under cursor!
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				var world_mouse := _screen_to_world(mb.position)
				if _erase_at(world_mouse):
					get_viewport().set_input_as_handled()
					return
				# If not clicking an item, right-click initiates camera pan
				is_panning_cam = true
				pan_drag_start = mb.position
				pan_cam_start = Vector2(cam_x, cam_y)
			else:
				is_panning_cam = false
		
		# Middle Mouse Button Drag Pan
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				is_panning_cam = true
				pan_drag_start = mb.position
				pan_cam_start = Vector2(cam_x, cam_y)
			else:
				is_panning_cam = false
	
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if is_dragging_h_scroll:
			_update_h_scroll_from_mouse(mm.position.x)
			return
		elif is_dragging_v_scroll:
			_update_v_scroll_from_mouse(mm.position.y)
			return
		elif is_panning_cam:
			var delta_p: Vector2 = pan_drag_start - mm.position
			cam_x = clampf(pan_cam_start.x + delta_p.x, CAM_MIN_X, CAM_MAX_X)
			cam_y = clampf(pan_cam_start.y + delta_p.y, CAM_MIN_Y, CAM_MAX_Y)
			if camera != null:
				camera.global_position = Vector2(cam_x, cam_y)
			if stage != null:
				stage.queue_redraw()
			overlay_control.queue_redraw()
			return
	
	# Canvas tool drawing & selection
	var world_mouse := _screen_to_world(event.position)
	var snapped_world := _snap_vec(world_mouse)
	
	if event is InputEventMouseMotion:
		mouse_screen_pos = event.position
		mouse_world_pos = world_mouse
		snapped_world_pos = snapped_world
		is_mouse_in_viewport = (event.position.y >= 42.0 and event.position.y <= 440.0 and event.position.x <= 938.0)
		_update_hover(world_mouse)
		_handle_canvas_motion(world_mouse, snapped_world)
		overlay_control.queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y >= 42.0 and event.position.y <= 440.0 and event.position.x <= 938.0:
			if event.pressed:
				_handle_canvas_press(world_mouse, snapped_world)
			else:
				_handle_canvas_release(world_mouse, snapped_world)
			overlay_control.queue_redraw()

func _handle_canvas_press(world_pos: Vector2, snapped_pos: Vector2) -> void:
	match current_tool:
		ToolType.PLATFORM:
			is_drawing_rect = true
			draw_rect_start = snapped_pos
			draw_rect_current = snapped_pos
		
		ToolType.GROUND:
			is_drawing_rect = true
			draw_rect_start = snapped_pos
			draw_rect_current = snapped_pos
		
		ToolType.ENEMY:
			editor_enemies.append({
				"type": selected_enemy_type,
				"pos": snapped_pos
			})
			show_toast("+ ADDED %s" % selected_enemy_type.to_upper().replace("_", " "))
			_apply_to_stage()
		
		ToolType.POWERUP:
			editor_powerups.append({
				"type": selected_powerup_type,
				"pos": snapped_pos
			})
			var pw_name: String = POWERUP_NAMES[clampi(selected_powerup_type - 1, 0, POWERUP_NAMES.size() - 1)]
			show_toast("+ ADDED POD: %s" % pw_name)
			_apply_to_stage()
		
		ToolType.BG_PROP:
			editor_bg_props.append({
				"type": selected_prop_type,
				"pos": snapped_pos
			})
			show_toast("+ ADDED %s" % selected_prop_type.to_upper().replace("_", " "))
			_sync_editor_bg_props_to_stage()
			has_unsaved_changes = true
			level_data_modified.emit()
		
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
			var p_dict: Dictionary = {
				"rect": Rect2(min_x, min_y, w, 16.0),
				"type": selected_platform_type
			}
			if selected_platform_is_drop:
				p_dict["is_drop"] = true
				p_dict["drop_delay"] = 0.5
				p_dict["respawn_time"] = 2.8
			editor_platforms.append(p_dict)
			show_toast("+ PLATFORM (%s)" % PLATFORM_NAMES[selected_platform_type])
		elif current_tool == ToolType.GROUND:
			editor_ground.append(Rect2(min_x, min_y, w, maxf(100.0, h)))
			show_toast("+ GROUND SEGMENT")
		
		_apply_to_stage()
	
	if is_moving_item:
		is_moving_item = false

func _select_item_at(world_pos: Vector2) -> void:
	# 1. Direct core hit on enemies (if user clicks directly on enemy body)
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and is_instance_valid(child):
				if world_pos.distance_to(child.global_position) <= 22.0:
					var c_pos: Vector2 = child.global_position
					var found_idx := -1
					for j in range(editor_enemies.size() - 1, -1, -1):
						if editor_enemies[j]["pos"].distance_to(c_pos) < 50.0:
							found_idx = j
							break
					if found_idx == -1:
						var e_type_str := "soldier"
						var n_name := child.name.to_lower()
						for cat in ENEMIES_BY_CATEGORY:
							for item in ENEMIES_BY_CATEGORY[cat]:
								if n_name.contains(item["id"]):
									e_type_str = item["id"]
									break
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

	for i in range(editor_enemies.size() - 1, -1, -1):
		if world_pos.distance_to(editor_enemies[i]["pos"]) <= 22.0:
			selected_item_type = "enemy"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_pos = editor_enemies[i]["pos"]
			show_toast("★ SELECTED ENEMY: " + editor_enemies[i]["type"].to_upper())
			overlay_control.queue_redraw()
			return

	# 2. Check PLATFORMS (Reverse search + minimum distance scoring)
	var best_platform_idx := -1
	var min_platform_dist := 999999.0
	for i in range(editor_platforms.size() - 1, -1, -1):
		var pr: Rect2 = editor_platforms[i]["rect"]
		if _is_pos_hitting_platform(world_pos, pr):
			var d := _get_platform_distance(world_pos, pr)
			if d < min_platform_dist:
				min_platform_dist = d
				best_platform_idx = i
	
	if best_platform_idx >= 0:
		selected_item_type = "platform"
		selected_item_idx = best_platform_idx
		is_moving_item = true
		move_start_mouse = _snap_vec(world_pos)
		move_original_rect = editor_platforms[best_platform_idx]["rect"]
		var p_name: String = PLATFORM_NAMES[editor_platforms[best_platform_idx].get("type", 0)]
		show_toast("★ SELECTED PLATFORM (" + p_name + ")")
		overlay_control.queue_redraw()
		return

	# 3. Check ENEMIES (Broader hitbox)
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and _is_node_at_world_pos(child, world_pos):
				var c_pos: Vector2 = child.global_position
				var found_idx := -1
				for j in range(editor_enemies.size() - 1, -1, -1):
					if editor_enemies[j]["pos"].distance_to(c_pos) < 50.0:
						found_idx = j
						break
				if found_idx == -1:
					var e_type_str := "soldier"
					var n_name := child.name.to_lower()
					for cat in ENEMIES_BY_CATEGORY:
						for item in ENEMIES_BY_CATEGORY[cat]:
							if n_name.contains(item["id"]):
								e_type_str = item["id"]
								break
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

	for i in range(editor_enemies.size() - 1, -1, -1):
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

	# 4. Check POWERUPS (Reverse search)
	for i in range(editor_powerups.size() - 1, -1, -1):
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

	# 5. Check GROUND (Reverse search)
	for i in range(editor_ground.size() - 1, -1, -1):
		var gr: Rect2 = editor_ground[i]
		if gr.grow_individual(12.0, 16.0, 12.0, 16.0).has_point(world_pos):
			selected_item_type = "ground"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_rect = gr
			show_toast("★ SELECTED GROUND SEGMENT")
			overlay_control.queue_redraw()
			return

	# 6. Check BACKGROUND PROPS (Reverse search, checked LAST so foreground platforms/enemies take priority!)
	for i in range(editor_bg_props.size() - 1, -1, -1):
		var bp: Vector2 = editor_bg_props[i]["pos"]
		if _is_pos_hitting_prop(world_pos, bp):
			selected_item_type = "bg_prop"
			selected_item_idx = i
			is_moving_item = true
			move_start_mouse = _snap_vec(world_pos)
			move_original_pos = bp
			show_toast("★ SELECTED PROP: " + editor_bg_props[i]["type"].to_upper().replace("_", " "))
			overlay_control.queue_redraw()
			return

	selected_item_idx = -1
	selected_item_type = ""
	show_toast("DESELECTED")
	overlay_control.queue_redraw()

func _erase_at(world_pos: Vector2) -> bool:
	# 1. Search and erase active enemy nodes in stage
	if stage != null:
		for child in stage.get_children():
			if _is_enemy_node(child) and _is_node_at_world_pos(child, world_pos):
				var c_pos: Vector2 = child.global_position
				for j in range(editor_enemies.size() - 1, -1, -1):
					if editor_enemies[j]["pos"].distance_to(c_pos) < 55.0:
						editor_enemies.remove_at(j)
				child.queue_free()
				show_toast("✖ ERASED ENEMY")
				_apply_to_stage()
				overlay_control.queue_redraw()
				return true
	
	# 2. Search and erase editor_enemies markers
	for i in range(editor_enemies.size() - 1, -1, -1):
		var ep: Vector2 = editor_enemies[i]["pos"]
		if _is_pos_hitting_enemy(world_pos, ep):
			var etype: String = editor_enemies[i].get("type", "enemy")
			editor_enemies.remove_at(i)
			if stage != null:
				for child in stage.get_children():
					if _is_enemy_node(child) and child.global_position.distance_to(ep) < 55.0:
						child.queue_free()
			show_toast("✖ ERASED ENEMY: " + etype.to_upper())
			_apply_to_stage()
			overlay_control.queue_redraw()
			return true
	
	# 3. Search and erase active powerups
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
			return true
	
	# 4. Search and erase platforms (Reverse search + minimum distance scoring)
	var best_p_idx := -1
	var min_p_dist := 999999.0
	for i in range(editor_platforms.size() - 1, -1, -1):
		var pr: Rect2 = editor_platforms[i]["rect"]
		if _is_pos_hitting_platform(world_pos, pr):
			var d := _get_platform_distance(world_pos, pr)
			if d < min_p_dist:
				min_p_dist = d
				best_p_idx = i
	if best_p_idx >= 0:
		var p_name: String = PLATFORM_NAMES[editor_platforms[best_p_idx].get("type", 0)]
		editor_platforms.remove_at(best_p_idx)
		if selected_item_type == "platform" and selected_item_idx == best_p_idx:
			selected_item_idx = -1
			selected_item_type = ""
		elif selected_item_type == "platform" and selected_item_idx > best_p_idx:
			selected_item_idx -= 1
		show_toast("✖ ERASED PLATFORM (" + p_name + ")")
		_apply_to_stage()
		overlay_control.queue_redraw()
		return true

	# 5. Search and erase ground
	for i in range(editor_ground.size() - 1, -1, -1):
		var gr: Rect2 = editor_ground[i]
		if gr.grow_individual(12.0, 16.0, 12.0, 16.0).has_point(world_pos):
			editor_ground.remove_at(i)
			if selected_item_type == "ground" and selected_item_idx == i:
				selected_item_idx = -1
				selected_item_type = ""
			elif selected_item_type == "ground" and selected_item_idx > i:
				selected_item_idx -= 1
			show_toast("✖ ERASED GROUND")
			_apply_to_stage()
			overlay_control.queue_redraw()
			return true

	# 6. Search and erase editor_bg_props (checked last so platforms take priority)
	for i in range(editor_bg_props.size() - 1, -1, -1):
		var bp: Vector2 = editor_bg_props[i]["pos"]
		if _is_pos_hitting_prop(world_pos, bp):
			var ptype: String = editor_bg_props[i].get("type", "prop")
			editor_bg_props.remove_at(i)
			if stage != null:
				for child in stage.get_children():
					if _is_prop_node(child) and child.global_position.distance_to(bp) < 45.0:
						child.queue_free()
			show_toast("✖ ERASED PROP: " + ptype.to_upper().replace("_", " "))
			_apply_to_stage()
			overlay_control.queue_redraw()
			return true

	return false

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
		LevelMaps.delete_custom_stage_data(Global.current_stage)
		_load_current_stage_geometry(true)
		show_toast("✔ STAGE %d RESET TO DEFAULT MAP" % Global.current_stage)
	elif Rect2(626.0, 4.0, 85.0, 32.0).has_point(pos):
		editor_ground.clear()
		editor_platforms.clear()
		editor_enemies.clear()
		editor_powerups.clear()
		editor_bg_props.clear()
		_apply_to_stage()
		show_toast("CLEARED ALL MAP ELEMENTS")
	elif Rect2(718.0, 4.0, 134.0, 32.0).has_point(pos):
		if selected_item_idx >= 0:
			_delete_selected_item()
	elif Rect2(860.0, 4.0, 85.0, 32.0).has_point(pos):
		close_editor()

func _handle_bottom_shelf_click(pos: Vector2) -> void:
	# 1. Primary Tool Buttons Row (y: 462 to 486)
	var tools_labels := ["1. SELECTOR", "2. PLATFORMS", "3. GROUND", "4. ENEMIES", "5. POWERUPS", "6. PROPS", "7. ERASE"]
	var tool_enum_list := [ToolType.SELECT_MOVE, ToolType.PLATFORM, ToolType.GROUND, ToolType.ENEMY, ToolType.POWERUP, ToolType.BG_PROP, ToolType.ERASE]
	var tools_x: float = 14.0
	var tool_w: float = 125.0
	for i in range(7):
		var btn_rect := Rect2(tools_x + float(i) * (tool_w + 5.0), 462.0, tool_w, 24.0)
		if btn_rect.has_point(pos):
			current_tool = tool_enum_list[i]
			show_toast("SELECTED: %s" % tools_labels[i])
			overlay_control.queue_redraw()
			return

	# 2. Sub-Palettes (y: 488 to 538)
	if current_tool == ToolType.SELECT_MOVE:
		if selected_item_idx >= 0:
			# Universal Prominent DELETE BUTTON on bottom shelf (right side: 750 to 945)
			if Rect2(750.0, 489.0, 195.0, 48.0).has_point(pos):
				_delete_selected_item()
				return
			
			if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
				# Row 1: Platform types (y: 489 to 510)
				var sub_x: float = 16.0
				var sub_w: float = 78.0
				for k in range(PLATFORM_NAMES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 489.0, sub_w, 20.0)
					if sub_rect.has_point(pos):
						editor_platforms[selected_item_idx]["type"] = k
						_apply_to_stage()
						show_toast("CHANGED PLATFORM TYPE: " + PLATFORM_NAMES[k])
						overlay_control.queue_redraw()
						return
				
				# Row 2: Modifiers & DELETE BUTTON (y: 513 to 536)
				# Drop Toggle
				if Rect2(16.0, 513.0, 110.0, 23.0).has_point(pos):
					var cur_drop: bool = editor_platforms[selected_item_idx].get("is_drop", false)
					editor_platforms[selected_item_idx]["is_drop"] = not cur_drop
					if not cur_drop:
						editor_platforms[selected_item_idx]["drop_delay"] = 0.5
						editor_platforms[selected_item_idx]["respawn_time"] = 2.8
					_apply_to_stage()
					show_toast("PLATFORM DROP: " + ("ENABLED" if not cur_drop else "DISABLED"))
					overlay_control.queue_redraw()
					return
				
				# Nudge Buttons
				if Rect2(130.0, 513.0, 65.0, 23.0).has_point(pos): # Left
					editor_platforms[selected_item_idx]["rect"].position.x -= 16.0
					_apply_to_stage()
					return
				elif Rect2(199.0, 513.0, 65.0, 23.0).has_point(pos): # Right
					editor_platforms[selected_item_idx]["rect"].position.x += 16.0
					_apply_to_stage()
					return
				elif Rect2(268.0, 513.0, 55.0, 23.0).has_point(pos): # Up
					editor_platforms[selected_item_idx]["rect"].position.y -= 16.0
					_apply_to_stage()
					return
				elif Rect2(327.0, 513.0, 55.0, 23.0).has_point(pos): # Down
					editor_platforms[selected_item_idx]["rect"].position.y += 16.0
					_apply_to_stage()
					return
				elif Rect2(386.0, 513.0, 70.0, 23.0).has_point(pos): # Width -
					editor_platforms[selected_item_idx]["rect"].size.x = maxf(32.0, editor_platforms[selected_item_idx]["rect"].size.x - 32.0)
					_apply_to_stage()
					return
				elif Rect2(460.0, 513.0, 70.0, 23.0).has_point(pos): # Width +
					editor_platforms[selected_item_idx]["rect"].size.x += 32.0
					_apply_to_stage()
					return
				elif Rect2(534.0, 513.0, 210.0, 23.0).has_point(pos) or Rect2(470.0, 513.0, 180.0, 23.0).has_point(pos):
					_delete_selected_item()
					return
			
			elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
				# Row 1: Category tabs
				var cat_x: float = 16.0
				var cat_w: float = 140.0
				for c in range(ENEMY_CATEGORY_NAMES.size()):
					var c_rect := Rect2(cat_x + float(c) * (cat_w + 5.0), 489.0, cat_w, 20.0)
					if c_rect.has_point(pos):
						selected_enemy_category = c as EnemyCategory
						overlay_control.queue_redraw()
						return
				
				# Row 2: Enemy buttons in active category
				var cur_list: Array = ENEMIES_BY_CATEGORY[selected_enemy_category]
				var sub_x: float = 16.0
				var sub_w: float = 85.0
				for k in range(cur_list.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 513.0, sub_w, 23.0)
					if sub_rect.has_point(pos):
						editor_enemies[selected_item_idx]["type"] = cur_list[k]["id"]
						show_toast("CHANGED ENEMY: " + cur_list[k]["label"])
						overlay_control.queue_redraw()
						return
				
				# DELETE BUTTON
				if Rect2(810.0, 513.0, 130.0, 23.0).has_point(pos):
					_delete_selected_item()
					return
			
			elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
				var sub_x: float = 16.0
				var sub_w: float = 135.0
				for k in range(POWERUP_NAMES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 489.0, sub_w, 22.0)
					if sub_rect.has_point(pos):
						editor_powerups[selected_item_idx]["type"] = k + 1
						show_toast("CHANGED WEAPON: " + POWERUP_NAMES[k])
						overlay_control.queue_redraw()
						return
				if Rect2(720.0, 489.0, 150.0, 24.0).has_point(pos):
					_delete_selected_item()
					return
			
			elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
				var sub_x: float = 12.0
				var sub_w: float = 68.0
				for k in range(PROP_TYPES.size()):
					var row_y: float = 489.0 if k < 8 else 513.0
					var col_x: float = sub_x + float(k % 8) * (sub_w + 4.0)
					var sub_rect := Rect2(col_x, row_y, sub_w, 21.0)
					if sub_rect.has_point(pos):
						editor_bg_props[selected_item_idx]["type"] = PROP_TYPES[k]
						_apply_to_stage()
						show_toast("CHANGED PROP: " + PROP_LABELS[k])
						overlay_control.queue_redraw()
						return
				if Rect2(588.0, 513.0, 160.0, 23.0).has_point(pos):
					_delete_selected_item()
					return
			
			elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
				if Rect2(16.0, 513.0, 75.0, 23.0).has_point(pos):
					editor_ground[selected_item_idx].position.x -= 32.0
					_apply_to_stage()
					return
				elif Rect2(95.0, 513.0, 75.0, 23.0).has_point(pos):
					editor_ground[selected_item_idx].position.x += 32.0
					_apply_to_stage()
					return
				elif Rect2(174.0, 513.0, 65.0, 23.0).has_point(pos):
					editor_ground[selected_item_idx].position.y -= 16.0
					_apply_to_stage()
					return
				elif Rect2(243.0, 513.0, 65.0, 23.0).has_point(pos):
					editor_ground[selected_item_idx].position.y += 16.0
					_apply_to_stage()
					return
				elif Rect2(312.0, 513.0, 75.0, 23.0).has_point(pos):
					editor_ground[selected_item_idx].size.x = maxf(64.0, editor_ground[selected_item_idx].size.x - 64.0)
					_apply_to_stage()
					return
				elif Rect2(391.0, 513.0, 75.0, 23.0).has_point(pos):
					editor_ground[selected_item_idx].size.x += 64.0
					_apply_to_stage()
					return
				elif Rect2(20.0, 510.0, 160.0, 24.0).has_point(pos):
					_delete_selected_item()
					return

	elif current_tool == ToolType.PLATFORM:
		# Row 1: Platform types (y: 489 to 510)
		var sub_x: float = 16.0
		var sub_w: float = 88.0
		for k in range(PLATFORM_NAMES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 489.0, sub_w, 20.0)
			if sub_rect.has_point(pos):
				selected_platform_type = k
				show_toast("TYPE: " + PLATFORM_NAMES[k])
				overlay_control.queue_redraw()
				return
		
		# Row 2: Drop toggle & presets (y: 513 to 536)
		if Rect2(16.0, 513.0, 180.0, 23.0).has_point(pos):
			selected_platform_is_drop = not selected_platform_is_drop
			show_toast("FALLING DROP PLATFORM: " + ("ENABLED" if selected_platform_is_drop else "DISABLED"))
			overlay_control.queue_redraw()
			return

	elif current_tool == ToolType.ENEMY:
		# Row 1: Category tabs
		var cat_x: float = 16.0
		var cat_w: float = 145.0
		for c in range(ENEMY_CATEGORY_NAMES.size()):
			var c_rect := Rect2(cat_x + float(c) * (cat_w + 6.0), 489.0, cat_w, 20.0)
			if c_rect.has_point(pos):
				selected_enemy_category = c as EnemyCategory
				overlay_control.queue_redraw()
				return
		
		# Row 2: Enemy buttons in active category
		var cur_list: Array = ENEMIES_BY_CATEGORY[selected_enemy_category]
		var sub_x: float = 16.0
		var sub_w: float = 95.0
		for k in range(cur_list.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 513.0, sub_w, 23.0)
			if sub_rect.has_point(pos):
				selected_enemy_type = cur_list[k]["id"]
				show_toast("ACTIVE ENEMY: " + cur_list[k]["label"])
				overlay_control.queue_redraw()
				return

	elif current_tool == ToolType.POWERUP:
		var sub_x: float = 16.0
		var sub_w: float = 140.0
		for k in range(POWERUP_NAMES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 498.0, sub_w, 24.0)
			if sub_rect.has_point(pos):
				selected_powerup_type = k + 1
				show_toast("POWERUP: " + POWERUP_NAMES[k])
				overlay_control.queue_redraw()
				return

	elif current_tool == ToolType.BG_PROP:
		var sub_x: float = 12.0
		var sub_w: float = 74.0
		for k in range(PROP_TYPES.size()):
			var row_y: float = 489.0 if k < 8 else 513.0
			var col_x: float = sub_x + float(k % 8) * (sub_w + 4.0)
			var sub_rect := Rect2(col_x, row_y, sub_w, 21.0)
			if sub_rect.has_point(pos):
				selected_prop_type = PROP_TYPES[k]
				show_toast("PROP: " + PROP_LABELS[k])
				overlay_control.queue_redraw()
				return

# Drawing
func _on_overlay_draw() -> void:
	if not is_active:
		return
	
	var font: Font = ThemeDB.fallback_font
	
	if is_test_playing:
		overlay_control.draw_rect(Rect2(800.0, 8.0, 150.0, 32.0), Color(0.85, 0.20, 0.20, 0.90))
		overlay_control.draw_rect(Rect2(800.0, 8.0, 150.0, 32.0), Color(1.0, 0.8, 0.8), false, 1.5)
		overlay_control.draw_string(font, Vector2(814.0, 29.0), "■ STOP TEST (F1)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		
		overlay_control.draw_rect(Rect2(16.0, 8.0, 240.0, 32.0), Color(0.08, 0.45, 0.80, 0.90))
		overlay_control.draw_rect(Rect2(16.0, 8.0, 240.0, 32.0), Color(0.4, 0.9, 1.0, 0.95), false, 1.5)
		overlay_control.draw_string(font, Vector2(28.0, 29.0), "★ GOD MODE • INVINCIBLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.95, 0.4))
		return
	
	# 1. Grid lines in world viewport
	if grid_snap > 0:
		var cam_left := cam_x - 480.0
		var cam_right := cam_x + 480.0
		var start_gx := floorf(cam_left / float(grid_snap)) * float(grid_snap)
		var grid_col := Color(0.2, 0.6, 0.9, 0.12)
		
		var gx := start_gx
		while gx <= cam_right:
			var sx := gx - cam_left
			if sx >= 0.0 and sx <= 938.0:
				overlay_control.draw_line(Vector2(sx, 42.0), Vector2(sx, 440.0), grid_col, 1.0)
			gx += float(grid_snap)
		
		var cam_top := cam_y - 270.0
		var cam_bottom := cam_y + 270.0
		var start_gy := floorf(cam_top / float(grid_snap)) * float(grid_snap)
		var gy := start_gy
		while gy <= cam_bottom:
			var sy := gy - cam_top
			if sy >= 42.0 and sy <= 440.0:
				overlay_control.draw_line(Vector2(0.0, sy), Vector2(938.0, sy), grid_col, 1.0)
			gy += float(grid_snap)
	
	# 2. Draw Enemy markers in World space
	for e in editor_enemies:
		var sp := _world_to_screen(e["pos"])
		if sp.x >= -40.0 and sp.x <= 960.0 and sp.y >= 30.0 and sp.y <= 460.0:
			var edef := _get_enemy_def(e["type"])
			var is_boss: bool = (e["type"] == "mini_boss")
			var r: float = 14.0 if is_boss else 8.0
			overlay_control.draw_circle(sp, r, edef["color"])
			overlay_control.draw_circle(sp, r, Color.WHITE, false, 1.4)
			overlay_control.draw_string(font, Vector2(sp.x - 14.0, sp.y - 10.0), edef["tag"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	
	# 3. Draw Powerup markers
	for p in editor_powerups:
		var sp := _world_to_screen(p["pos"])
		if sp.x >= -40.0 and sp.x <= 960.0 and sp.y >= 30.0 and sp.y <= 460.0:
			overlay_control.draw_circle(sp, 7.0, Color(1.0, 0.9, 0.2))
			overlay_control.draw_circle(sp, 7.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, Vector2(sp.x - 8.0, sp.y - 10.0), "[P]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.2))
	
	# 4. Draw Background Prop markers
	for bp in editor_bg_props:
		var sp := _world_to_screen(bp["pos"])
		if sp.x >= -40.0 and sp.x <= 960.0 and sp.y >= 30.0 and sp.y <= 460.0:
			overlay_control.draw_circle(sp, 8.0, Color(0.2, 0.8, 1.0))
			overlay_control.draw_circle(sp, 8.0, Color.WHITE, false, 1.2)
			var pname: String = bp["type"].substr(0, 4).to_upper()
			overlay_control.draw_string(font, Vector2(sp.x - 14.0, sp.y - 10.0), pname, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.3, 0.9, 1.0))

	# 5. Live drawing box
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
	
	# 6. Active Selection & Viewport Cursor / Reticle
	_draw_selection_and_cursor(font)
	
	# 7. Top Bar Panel
	overlay_control.draw_rect(Rect2(0.0, 0.0, 960.0, 42.0), Color(0.06, 0.09, 0.14, 0.95))
	overlay_control.draw_line(Vector2(0.0, 42.0), Vector2(960.0, 42.0), Color(0.20, 0.35, 0.55), 1.5)
	
	_draw_btn(Rect2(12.0, 5.0, 110.0, 30.0), "▶ TEST PLAY", Color(0.18, 0.70, 0.30), font)
	_draw_btn(Rect2(130.0, 5.0, 95.0, 30.0), "THEME: %d" % Global.current_stage, Color(0.20, 0.35, 0.55), font)
	_draw_btn(Rect2(232.0, 5.0, 90.0, 30.0), "GRID: " + ("OFF" if grid_snap == 0 else "%dpx" % grid_snap), Color(0.20, 0.35, 0.55), font)
	var save_col := Color(0.9, 0.55, 0.15) if has_unsaved_changes else Color(0.25, 0.50, 0.80)
	var save_text := "● SAVE" if has_unsaved_changes else "SAVE"
	_draw_btn(Rect2(330.0, 5.0, 85.0, 30.0), save_text, save_col, font, has_unsaved_changes)
	_draw_btn(Rect2(422.0, 5.0, 85.0, 30.0), "LOAD", Color(0.25, 0.50, 0.80), font)
	_draw_btn(Rect2(514.0, 5.0, 105.0, 30.0), "RESET MAP", Color(0.45, 0.30, 0.20), font)
	_draw_btn(Rect2(626.0, 5.0, 85.0, 30.0), "CLEAR", Color(0.55, 0.20, 0.20), font)
	if selected_item_idx >= 0:
		_draw_btn(Rect2(718.0, 5.0, 134.0, 30.0), "✖ DELETE (Del)", Color(0.85, 0.18, 0.18), font, true, 11)
	else:
		overlay_control.draw_string(font, Vector2(722.0, 24.0), "X:%d  Y:%d" % [int(cam_x), int(cam_y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.85, 1.0))
	_draw_btn(Rect2(860.0, 5.0, 85.0, 30.0), "EXIT", Color(0.60, 0.15, 0.15), font)
	
	# 8. Vertical Scrollbar (Right edge)
	_draw_vertical_scrollbar(font)
	
	# 9. Bottom Control Station Panel
	overlay_control.draw_rect(Rect2(0.0, 440.0, 960.0, 100.0), Color(0.05, 0.08, 0.12, 0.96))
	overlay_control.draw_line(Vector2(0.0, 440.0), Vector2(960.0, 440.0), Color(0.20, 0.35, 0.55), 1.5)
	
	# Horizontal Scrollbar Track & Thumb
	_draw_horizontal_scrollbar(font)
	
	# Primary Tool Buttons (row 1 of shelf)
	var tools_labels := ["1. SELECTOR", "2. PLATFORMS", "3. GROUND", "4. ENEMIES", "5. POWERUPS", "6. PROPS", "7. ERASE"]
	var tool_enum_list := [ToolType.SELECT_MOVE, ToolType.PLATFORM, ToolType.GROUND, ToolType.ENEMY, ToolType.POWERUP, ToolType.BG_PROP, ToolType.ERASE]
	var tools_x: float = 14.0
	var tool_w: float = 125.0
	for i in range(7):
		var btn_rect := Rect2(tools_x + float(i) * (tool_w + 5.0), 462.0, tool_w, 24.0)
		var is_cur: bool = (current_tool == tool_enum_list[i])
		var b_col := Color(0.2, 0.55, 0.85) if is_cur else Color(0.12, 0.16, 0.22)
		_draw_btn(btn_rect, tools_labels[i], b_col, font, is_cur, 11)
	
	# Sub-Palette Shelf (row 2 & 3)
	_draw_sub_palette_shelf(font)
	
	# Toast Notification
	if toast_message != "":
		var toast_rect := Rect2(260.0, 48.0, 440.0, 26.0)
		overlay_control.draw_rect(toast_rect, Color(0.05, 0.08, 0.12, 0.92))
		overlay_control.draw_rect(toast_rect, Color(0.3, 0.8, 1.0), false, 1.2)
		overlay_control.draw_string(font, Vector2(275.0, 66.0), toast_message, HORIZONTAL_ALIGNMENT_CENTER, 410.0, 11, Color(1.0, 0.95, 0.3))

func _draw_horizontal_scrollbar(font: Font) -> void:
	# Arrow buttons
	_draw_btn(Rect2(12.0, 442.0, 22.0, 16.0), "◀", Color(0.15, 0.20, 0.28), font, false, 10)
	_draw_btn(Rect2(916.0, 442.0, 22.0, 16.0), "▶", Color(0.15, 0.20, 0.28), font, false, 10)
	
	# Track
	var track_rect := Rect2(36.0, 443.0, 876.0, 14.0)
	overlay_control.draw_rect(track_rect, Color(0.10, 0.14, 0.20))
	overlay_control.draw_rect(track_rect, Color(0.25, 0.35, 0.50), false, 1.0)
	
	# Stage Sector Milestones tick marks
	var milestones: Array = [
		{"name": "S1", "x": 0.0},
		{"name": "S2", "x": 1240.0},
		{"name": "S3", "x": 2580.0},
		{"name": "S4", "x": 3920.0},
		{"name": "★MINI", "x": 5350.0},
		{"name": "S6", "x": 6400.0},
		{"name": "S7", "x": 7800.0},
		{"name": "BOSS", "x": 8800.0}
	]
	for ms in milestones:
		var ratio := clampf(ms["x"] / 9800.0, 0.0, 1.0)
		var mx := 36.0 + ratio * 876.0
		var m_col: Color = Color(1.0, 0.8, 0.2, 0.7) if ms["name"].begins_with("★") or ms["name"] == "BOSS" else Color(0.4, 0.6, 0.8, 0.45)
		overlay_control.draw_line(Vector2(mx, 444.0), Vector2(mx, 457.0), m_col, 1.5)
	
	# Moving Thumb
	var track_w := 876.0
	var thumb_w := 80.0
	var h_ratio := clampf((cam_x - CAM_MIN_X) / (CAM_MAX_X - CAM_MIN_X), 0.0, 1.0)
	var thumb_x := 36.0 + h_ratio * (track_w - thumb_w)
	var thumb_rect := Rect2(thumb_x, 442.0, thumb_w, 16.0)
	overlay_control.draw_rect(thumb_rect, Color(0.20, 0.70, 0.95, 0.85))
	overlay_control.draw_rect(thumb_rect, Color.WHITE, false, 1.2)
	overlay_control.draw_string(font, Vector2(thumb_x + 12.0, 454.0), "%d M" % int(cam_x), HORIZONTAL_ALIGNMENT_CENTER, thumb_w - 24.0, 9, Color.WHITE)

func _draw_vertical_scrollbar(font: Font) -> void:
	# Backing panel
	overlay_control.draw_rect(Rect2(938.0, 42.0, 22.0, 398.0), Color(0.06, 0.09, 0.14, 0.92))
	overlay_control.draw_line(Vector2(938.0, 42.0), Vector2(938.0, 440.0), Color(0.20, 0.35, 0.55), 1.0)
	
	# Arrow buttons
	_draw_btn(Rect2(940.0, 44.0, 18.0, 18.0), "▲", Color(0.15, 0.20, 0.28), font, false, 9)
	_draw_btn(Rect2(940.0, 420.0, 18.0, 18.0), "▼", Color(0.15, 0.20, 0.28), font, false, 9)
	
	# Track
	var track_rect := Rect2(941.0, 64.0, 16.0, 354.0)
	overlay_control.draw_rect(track_rect, Color(0.10, 0.14, 0.20))
	overlay_control.draw_rect(track_rect, Color(0.25, 0.35, 0.50), false, 1.0)
	
	# Moving Thumb
	var track_h := 354.0
	var thumb_h := 55.0
	var v_ratio := clampf((cam_y - CAM_MIN_Y) / (CAM_MAX_Y - CAM_MIN_Y), 0.0, 1.0)
	var thumb_y := 64.0 + v_ratio * (track_h - thumb_h)
	var thumb_rect := Rect2(940.0, thumb_y, 18.0, thumb_h)
	overlay_control.draw_rect(thumb_rect, Color(0.20, 0.70, 0.95, 0.85))
	overlay_control.draw_rect(thumb_rect, Color.WHITE, false, 1.2)

func _draw_sub_palette_shelf(font: Font) -> void:
	if current_tool == ToolType.SELECT_MOVE:
		if selected_item_idx >= 0:
			if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
				# Row 1: Platform types (16 to 745)
				var sub_x: float = 16.0
				var sub_w: float = 78.0
				var cur_ptype: int = editor_platforms[selected_item_idx].get("type", 0)
				for k in range(PLATFORM_NAMES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 489.0, sub_w, 20.0)
					var is_cur_p: bool = (cur_ptype == k)
					var p_col := Color(0.18, 0.65, 0.40) if is_cur_p else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, PLATFORM_NAMES[k], p_col, font, is_cur_p, 9)
				
				# Row 2: Modifiers & Nudges
				var is_drop: bool = editor_platforms[selected_item_idx].get("is_drop", false)
				_draw_btn(Rect2(16.0, 513.0, 110.0, 23.0), "DROP: " + ("ON" if is_drop else "OFF"), Color(0.8, 0.4, 0.1) if is_drop else Color(0.15, 0.2, 0.25), font, is_drop, 9)
				_draw_btn(Rect2(130.0, 513.0, 65.0, 23.0), "◀ LEFT", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(199.0, 513.0, 65.0, 23.0), "RIGHT ▶", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(268.0, 513.0, 55.0, 23.0), "▲ UP", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(327.0, 513.0, 55.0, 23.0), "DOWN ▼", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(386.0, 513.0, 70.0, 23.0), "WIDTH -", Color(0.25, 0.3, 0.38), font, false, 9)
				_draw_btn(Rect2(460.0, 513.0, 70.0, 23.0), "WIDTH +", Color(0.25, 0.3, 0.38), font, false, 9)
				_draw_btn(Rect2(534.0, 513.0, 210.0, 23.0), "✖ DELETE PLATFORM", Color(0.85, 0.20, 0.20), font, false, 10)
				
				# Large Prominent Right-Hand DELETE BUTTON
				_draw_btn(Rect2(750.0, 489.0, 195.0, 47.0), "✖ DELETE PLATFORM", Color(0.85, 0.18, 0.18), font, true, 11)
				overlay_control.draw_string(font, Vector2(765.0, 528.0), "PRESS [DEL] / CLICK", HORIZONTAL_ALIGNMENT_CENTER, 165.0, 9, Color(1.0, 0.85, 0.85))
			
			elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
				# Row 1: Category tabs
				var cat_x: float = 16.0
				var cat_w: float = 140.0
				for c in range(ENEMY_CATEGORY_NAMES.size()):
					var c_rect := Rect2(cat_x + float(c) * (cat_w + 5.0), 489.0, cat_w, 20.0)
					var is_cat_active: bool = (selected_enemy_category == c)
					var c_col := Color(0.3, 0.55, 0.85) if is_cat_active else Color(0.14, 0.18, 0.24)
					_draw_btn(c_rect, ENEMY_CATEGORY_NAMES[c], c_col, font, is_cat_active, 10)
				
				# Row 2: Enemy buttons
				var cur_list: Array = ENEMIES_BY_CATEGORY[selected_enemy_category]
				var sub_x: float = 16.0
				var sub_w: float = 85.0
				var cur_etype: String = editor_enemies[selected_item_idx]["type"]
				for k in range(cur_list.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 3.0), 513.0, sub_w, 23.0)
					var is_cur_e: bool = (cur_etype == cur_list[k]["id"])
					var e_col: Color = cur_list[k]["color"] * 0.8 if is_cur_e else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, cur_list[k]["label"], e_col, font, is_cur_e, 9)
				
				# Large Prominent Right-Hand DELETE BUTTON
				_draw_btn(Rect2(750.0, 489.0, 195.0, 47.0), "✖ DELETE ENEMY", Color(0.85, 0.18, 0.18), font, true, 11)
				overlay_control.draw_string(font, Vector2(765.0, 528.0), "PRESS [DEL] / CLICK", HORIZONTAL_ALIGNMENT_CENTER, 165.0, 9, Color(1.0, 0.85, 0.85))
			
			elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
				var sub_x: float = 16.0
				var sub_w: float = 135.0
				var cur_pwtype: int = editor_powerups[selected_item_idx]["type"]
				for k in range(POWERUP_NAMES.size()):
					var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 489.0, sub_w, 22.0)
					var is_cur_pw: bool = (cur_pwtype == k + 1)
					var pw_col := Color(0.85, 0.75, 0.15) if is_cur_pw else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, POWERUP_NAMES[k], pw_col, font, is_cur_pw, 10)
				overlay_control.draw_string(font, Vector2(24.0, 526.0), "SELECT WEAPON POD TYPE • DRAG CANVAS TO REPOSITION", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.85, 1.0))
				
				# Large Prominent Right-Hand DELETE BUTTON
				_draw_btn(Rect2(750.0, 489.0, 195.0, 47.0), "✖ DELETE POWERUP", Color(0.85, 0.18, 0.18), font, true, 11)
				overlay_control.draw_string(font, Vector2(765.0, 528.0), "PRESS [DEL] / CLICK", HORIZONTAL_ALIGNMENT_CENTER, 165.0, 9, Color(1.0, 0.85, 0.85))
			
			elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
				var cur_prop_type: String = editor_bg_props[selected_item_idx].get("type", "radar_dish")
				var sub_x: float = 12.0
				var sub_w: float = 68.0
				for k in range(PROP_TYPES.size()):
					var row_y: float = 489.0 if k < 8 else 513.0
					var col_x: float = sub_x + float(k % 8) * (sub_w + 4.0)
					var sub_rect := Rect2(col_x, row_y, sub_w, 21.0)
					var is_cur: bool = (cur_prop_type == PROP_TYPES[k])
					var b_col := Color(0.2, 0.75, 0.9) if is_cur else Color(0.14, 0.18, 0.24)
					_draw_btn(sub_rect, PROP_LABELS[k], b_col, font, is_cur, 9)
				
				# Large Prominent Right-Hand DELETE BUTTON
				_draw_btn(Rect2(750.0, 489.0, 195.0, 47.0), "✖ DELETE PROP", Color(0.85, 0.18, 0.18), font, true, 11)
				overlay_control.draw_string(font, Vector2(765.0, 528.0), "PRESS [DEL] / CLICK", HORIZONTAL_ALIGNMENT_CENTER, 165.0, 9, Color(1.0, 0.85, 0.85))
			
			elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
				var gr: Rect2 = editor_ground[selected_item_idx]
				overlay_control.draw_string(font, Vector2(24.0, 502.0), "★ SELECTED GROUND SEGMENT [%d x %d]" % [int(gr.size.x), int(gr.size.y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 1.0, 0.6))
				_draw_btn(Rect2(16.0, 513.0, 75.0, 23.0), "◀ LEFT", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(95.0, 513.0, 75.0, 23.0), "RIGHT ▶", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(174.0, 513.0, 65.0, 23.0), "▲ UP", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(243.0, 513.0, 65.0, 23.0), "DOWN ▼", Color(0.2, 0.3, 0.4), font, false, 9)
				_draw_btn(Rect2(312.0, 513.0, 75.0, 23.0), "WIDTH -", Color(0.25, 0.3, 0.38), font, false, 9)
				_draw_btn(Rect2(391.0, 513.0, 75.0, 23.0), "WIDTH +", Color(0.25, 0.3, 0.38), font, false, 9)
				_draw_btn(Rect2(470.0, 513.0, 270.0, 23.0), "✖ DELETE GROUND", Color(0.85, 0.20, 0.20), font, false, 10)
				
				# Large Prominent Right-Hand DELETE BUTTON
				_draw_btn(Rect2(750.0, 489.0, 195.0, 47.0), "✖ DELETE GROUND", Color(0.85, 0.18, 0.18), font, true, 11)
				overlay_control.draw_string(font, Vector2(765.0, 528.0), "PRESS [DEL] / CLICK", HORIZONTAL_ALIGNMENT_CENTER, 165.0, 9, Color(1.0, 0.85, 0.85))
		else:
			overlay_control.draw_string(font, Vector2(24.0, 502.0), "★ SELECTOR ACTIVE: CLICK ANY PLATFORM, GROUND, ENEMY OR PROP TO SELECT & MODIFY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.35, 0.85, 1.0))
			overlay_control.draw_string(font, Vector2(24.0, 524.0), "TIP: USE [DEL] OR CLICK DELETE BUTTON TO REMOVE • DRAG CANVAS (OR WASD) TO PAN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.85, 1.0))
	
	elif current_tool == ToolType.PLATFORM:
		# Row 1: Platform types
		var sub_x: float = 16.0
		var sub_w: float = 88.0
		for k in range(PLATFORM_NAMES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 489.0, sub_w, 20.0)
			var is_p_cur: bool = (selected_platform_type == k)
			var p_col := Color(0.18, 0.65, 0.40) if is_p_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, PLATFORM_NAMES[k], p_col, font, is_p_cur, 10)
		
		# Row 2: Drop modifier & draw instructions
		_draw_btn(Rect2(16.0, 513.0, 180.0, 23.0), "DROP PLATFORM: " + ("ON (FALL)" if selected_platform_is_drop else "OFF"), Color(0.85, 0.45, 0.15) if selected_platform_is_drop else Color(0.14, 0.18, 0.24), font, selected_platform_is_drop, 10)
		overlay_control.draw_string(font, Vector2(210.0, 528.0), "CLICK & DRAG ON CANVAS TO DRAW PLATFORM • RIGHT-CLICK ANY PLATFORM TO DELETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.65, 0.90, 1.0))
	
	elif current_tool == ToolType.ENEMY:
		# Row 1: Category tabs
		var cat_x: float = 16.0
		var cat_w: float = 145.0
		for c in range(ENEMY_CATEGORY_NAMES.size()):
			var c_rect := Rect2(cat_x + float(c) * (cat_w + 6.0), 489.0, cat_w, 20.0)
			var is_cat_active: bool = (selected_enemy_category == c)
			var c_col := Color(0.3, 0.55, 0.85) if is_cat_active else Color(0.14, 0.18, 0.24)
			_draw_btn(c_rect, ENEMY_CATEGORY_NAMES[c], c_col, font, is_cat_active, 10)
		
		# Row 2: Enemy buttons in active category
		var cur_list: Array = ENEMIES_BY_CATEGORY[selected_enemy_category]
		var sub_x: float = 16.0
		var sub_w: float = 95.0
		for k in range(cur_list.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 4.0), 513.0, sub_w, 23.0)
			var is_e_cur: bool = (selected_enemy_type == cur_list[k]["id"])
			var e_col: Color = cur_list[k]["color"] * 0.8 if is_e_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, cur_list[k]["label"], e_col, font, is_e_cur, 9)
	
	elif current_tool == ToolType.POWERUP:
		var sub_x: float = 16.0
		var sub_w: float = 140.0
		for k in range(POWERUP_NAMES.size()):
			var sub_rect := Rect2(sub_x + float(k) * (sub_w + 6.0), 498.0, sub_w, 24.0)
			var is_pw_cur: bool = (selected_powerup_type == k + 1)
			var pw_col := Color(0.85, 0.75, 0.15) if is_pw_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, POWERUP_NAMES[k], pw_col, font, is_pw_cur, 10)
	
	elif current_tool == ToolType.BG_PROP:
		var sub_x: float = 12.0
		var sub_w: float = 74.0
		for k in range(PROP_TYPES.size()):
			var row_y: float = 489.0 if k < 8 else 513.0
			var col_x: float = sub_x + float(k % 8) * (sub_w + 4.0)
			var sub_rect := Rect2(col_x, row_y, sub_w, 21.0)
			var is_bp_cur: bool = (selected_prop_type == PROP_TYPES[k])
			var bp_col := Color(0.2, 0.75, 0.9) if is_bp_cur else Color(0.14, 0.18, 0.24)
			_draw_btn(sub_rect, PROP_LABELS[k], bp_col, font, is_bp_cur, 9)
	
	elif current_tool == ToolType.ERASE:
		overlay_control.draw_string(font, Vector2(24.0, 502.0), "✖ ERASE TOOL ACTIVE: CLICK ANY PLATFORM, ENEMY, GROUND OR PROP TO DELETE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.45, 0.45))
		overlay_control.draw_string(font, Vector2(24.0, 524.0), "TIP: IN ANY OTHER TOOL, YOU CAN ALSO RIGHT-CLICK DIRECTLY ON AN ITEM TO INSTANTLY ERASE IT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.75, 0.75))

func _draw_corner_brackets(rect: Rect2, color: Color, length: float = 8.0, thickness: float = 2.0) -> void:
	overlay_control.draw_line(rect.position, rect.position + Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(rect.position, rect.position + Vector2(0.0, length), color, thickness)
	var tr := Vector2(rect.end.x, rect.position.y)
	overlay_control.draw_line(tr, tr - Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(tr, tr + Vector2(0.0, length), color, thickness)
	var bl := Vector2(rect.position.x, rect.end.y)
	overlay_control.draw_line(bl, bl + Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(bl, bl - Vector2(0.0, length), color, thickness)
	overlay_control.draw_line(rect.end, rect.end - Vector2(length, 0.0), color, thickness)
	overlay_control.draw_line(rect.end, rect.end - Vector2(0.0, length), color, thickness)

func _draw_selection_and_cursor(font: Font) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(t * 8.0)
	selection_floating_del_rect = Rect2()
	
	# Active Selection Highlight Frame
	if selected_item_idx >= 0:
		var del_tag_x: float = 0.0
		var del_tag_y: float = 0.0
		var badge_str: String = ""
		var badge_col: Color = Color(1.0, 0.9, 0.2)
		var badge_w: float = 230.0
		
		if selected_item_type == "platform" and selected_item_idx < editor_platforms.size():
			var pr: Rect2 = editor_platforms[selected_item_idx]["rect"]
			var sr := Rect2(_world_to_screen(pr.position), pr.size)
			var ptype: int = editor_platforms[selected_item_idx].get("type", 0)
			var p_name: String = PLATFORM_NAMES[clampi(ptype, 0, PLATFORM_NAMES.size() - 1)]
			var is_drop: bool = editor_platforms[selected_item_idx].get("is_drop", false)
			
			# Visual frame covering full platform extent
			var fill_top := sr.position.y - (16.0 if ptype == 2 else 8.0)
			var fill_h := maxf(sr.size.y, 26.0) + (22.0 if ptype == 2 else 12.0)
			var fill_rect := Rect2(sr.position.x - 6.0, fill_top, sr.size.x + 12.0, fill_h)
			
			# 1. Pulsing Translucent Aura Fill
			overlay_control.draw_rect(fill_rect, Color(0.12, 0.70, 1.0, 0.25 + 0.12 * pulse))
			# 2. Outer Pulsing Neon Border
			overlay_control.draw_rect(fill_rect, Color(0.35, 0.95, 1.0, 0.85 + 0.15 * pulse), false, 2.5)
			# 3. Inner walking rail bright line
			overlay_control.draw_line(Vector2(sr.position.x - 6.0, sr.position.y), Vector2(sr.end.x + 6.0, sr.position.y), Color(1.0, 0.96, 0.40, 0.95), 3.0)
			# 4. Heavy Neon Corner Brackets
			_draw_corner_brackets(fill_rect.grow(4.0), Color(1.0, 0.88, 0.15), 14.0, 3.0)
			# 5. Left & Right edge drag grips
			overlay_control.draw_rect(Rect2(sr.position.x - 9.0, sr.position.y - 2.0, 7.0, 18.0), Color(1.0, 0.90, 0.20))
			overlay_control.draw_rect(Rect2(sr.end.x + 2.0, sr.position.y - 2.0, 7.0, 18.0), Color(1.0, 0.90, 0.20))
			
			# Coordinates and badge
			del_tag_y = clampf(fill_rect.position.y - 26.0, 48.0, 412.0)
			del_tag_x = clampf(fill_rect.position.x, 16.0, 680.0)
			var drop_label := " [DROP]" if is_drop else ""
			badge_str = "★ PLATFORM: %s%s [%d x %d]" % [p_name, drop_label, int(pr.size.x), int(pr.size.y)]
			badge_col = Color(0.30, 0.95, 1.0)
			badge_w = 250.0
			
		elif selected_item_type == "ground" and selected_item_idx < editor_ground.size():
			var gr: Rect2 = editor_ground[selected_item_idx]
			var sr := Rect2(_world_to_screen(gr.position), gr.size)
			var fill_rect := Rect2(sr.position.x - 4.0, sr.position.y - 4.0, sr.size.x + 8.0, sr.size.y + 8.0)
			overlay_control.draw_rect(fill_rect, Color(0.15, 0.85, 0.40, 0.22 + 0.10 * pulse))
			overlay_control.draw_rect(fill_rect, Color(0.30, 1.0, 0.50, 0.85 + 0.15 * pulse), false, 2.5)
			overlay_control.draw_line(Vector2(sr.position.x - 4.0, sr.position.y), Vector2(sr.end.x + 4.0, sr.position.y), Color(1.0, 0.96, 0.40, 0.95), 3.0)
			_draw_corner_brackets(fill_rect.grow(4.0), Color(1.0, 0.88, 0.15), 14.0, 3.0)
			overlay_control.draw_rect(Rect2(sr.position.x - 8.0, sr.position.y - 2.0, 6.0, 20.0), Color(1.0, 0.90, 0.20))
			overlay_control.draw_rect(Rect2(sr.end.x + 2.0, sr.position.y - 2.0, 6.0, 20.0), Color(1.0, 0.90, 0.20))
			del_tag_y = clampf(fill_rect.position.y - 26.0, 48.0, 412.0)
			del_tag_x = clampf(fill_rect.position.x, 16.0, 680.0)
			badge_str = "★ GROUND [%d x %d]" % [int(gr.size.x), int(gr.size.y)]
			badge_col = Color(0.40, 1.0, 0.60)
			badge_w = 210.0
			
		elif selected_item_type == "enemy" and selected_item_idx < editor_enemies.size():
			var ep: Vector2 = editor_enemies[selected_item_idx]["pos"]
			var etype: String = editor_enemies[selected_item_idx].get("type", "soldier")
			var sp := _world_to_screen(ep)
			var box_rect := Rect2(sp.x - 26.0, sp.y - 38.0, 52.0, 52.0)
			overlay_control.draw_rect(box_rect, Color(1.0, 0.25, 0.20, 0.25 + 0.10 * pulse))
			overlay_control.draw_arc(sp, 24.0 + 3.0 * pulse, 0.0, TAU, 32, Color(1.0, 0.40, 0.30, 0.95), 2.5)
			overlay_control.draw_arc(sp, 14.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.20, 0.85), 1.8)
			overlay_control.draw_line(sp - Vector2(32.0, 0.0), sp + Vector2(32.0, 0.0), Color(1.0, 0.4, 0.3, 0.6), 1.5)
			overlay_control.draw_line(sp - Vector2(0.0, 32.0), sp + Vector2(0.0, 32.0), Color(1.0, 0.4, 0.3, 0.6), 1.5)
			_draw_corner_brackets(box_rect.grow(4.0), Color(1.0, 0.88, 0.2), 10.0, 2.5)
			del_tag_y = clampf(box_rect.position.y - 26.0, 48.0, 412.0)
			del_tag_x = clampf(box_rect.position.x - 50.0, 16.0, 680.0)
			badge_str = "★ ENEMY: %s" % etype.to_upper().replace("_", " ")
			badge_col = Color(1.0, 0.45, 0.40)
			badge_w = 220.0
			
		elif selected_item_type == "powerup" and selected_item_idx < editor_powerups.size():
			var pp: Vector2 = editor_powerups[selected_item_idx]["pos"]
			var sp := _world_to_screen(pp)
			var box_rect := Rect2(sp.x - 22.0, sp.y - 22.0, 44.0, 44.0)
			overlay_control.draw_rect(box_rect, Color(1.0, 0.85, 0.15, 0.25 + 0.10 * pulse))
			overlay_control.draw_arc(sp, 22.0 + 2.5 * pulse, 0.0, TAU, 28, Color(1.0, 0.88, 0.20, 0.95), 2.5)
			_draw_corner_brackets(box_rect.grow(4.0), Color(1.0, 0.95, 0.4), 10.0, 2.5)
			var pw_name: String = POWERUP_NAMES[clampi(editor_powerups[selected_item_idx]["type"] - 1, 0, POWERUP_NAMES.size() - 1)]
			del_tag_y = clampf(box_rect.position.y - 26.0, 48.0, 412.0)
			del_tag_x = clampf(box_rect.position.x - 45.0, 16.0, 680.0)
			badge_str = "★ POWERUP: %s" % pw_name
			badge_col = Color(1.0, 0.90, 0.30)
			badge_w = 210.0
			
		elif selected_item_type == "bg_prop" and selected_item_idx < editor_bg_props.size():
			var bp: Vector2 = editor_bg_props[selected_item_idx]["pos"]
			var ptype: String = editor_bg_props[selected_item_idx].get("type", "radar_dish")
			var sp := _world_to_screen(bp)
			var box_rect := Rect2(sp.x - 28.0, sp.y - 36.0, 56.0, 52.0)
			overlay_control.draw_rect(box_rect, Color(0.20, 0.80, 1.0, 0.22 + 0.10 * pulse))
			overlay_control.draw_rect(box_rect, Color(0.30, 0.90, 1.0, 0.85 + 0.15 * pulse), false, 2.2)
			_draw_corner_brackets(box_rect.grow(4.0), Color(1.0, 0.88, 0.2), 10.0, 2.5)
			del_tag_y = clampf(box_rect.position.y - 26.0, 48.0, 412.0)
			del_tag_x = clampf(box_rect.position.x - 45.0, 16.0, 680.0)
			badge_str = "★ PROP: %s" % ptype.to_upper().replace("_", " ")
			badge_col = Color(0.40, 0.90, 1.0)
			badge_w = 210.0
		
		# Draw the Unified Header Badge Pill & Floating [✖ DELETE] Button
		if badge_str != "":
			var pill_rect := Rect2(del_tag_x, del_tag_y, badge_w, 22.0)
			overlay_control.draw_rect(pill_rect, Color(0.06, 0.10, 0.16, 0.94))
			overlay_control.draw_rect(pill_rect, badge_col, false, 1.5)
			overlay_control.draw_string(font, Vector2(del_tag_x + 8.0, del_tag_y + 15.0), badge_str, HORIZONTAL_ALIGNMENT_LEFT, badge_w - 12.0, 10, badge_col)
			
			# Floating [✖ DELETE] Button
			var f_del_rect := Rect2(del_tag_x + badge_w + 6.0, del_tag_y, 82.0, 22.0)
			selection_floating_del_rect = f_del_rect
			var del_hover := f_del_rect.has_point(mouse_screen_pos)
			var del_bg := Color(0.95, 0.25, 0.25) if del_hover else Color(0.80, 0.15, 0.15, 0.95)
			overlay_control.draw_rect(f_del_rect, del_bg)
			overlay_control.draw_rect(f_del_rect, Color(1.0, 0.8, 0.8), false, 1.5)
			overlay_control.draw_string(font, Vector2(f_del_rect.position.x + 6.0, del_tag_y + 15.0), "✖ DELETE", HORIZONTAL_ALIGNMENT_CENTER, 70.0, 10, Color.WHITE)
	
	# Draw Hover Outline
	if hovered_item_idx >= 0 and (hovered_item_type != selected_item_type or hovered_item_idx != selected_item_idx):
		if hovered_item_type == "platform" and hovered_item_idx < editor_platforms.size():
			var pr: Rect2 = editor_platforms[hovered_item_idx]["rect"]
			var sr := Rect2(_world_to_screen(pr.position), pr.size)
			var h_rect := Rect2(sr.position.x - 4.0, sr.position.y - 6.0, sr.size.x + 8.0, maxf(sr.size.y, 24.0) + 8.0)
			overlay_control.draw_rect(h_rect, Color(0.2, 0.85, 1.0, 0.12))
			overlay_control.draw_rect(h_rect, Color(0.3, 0.9, 1.0, 0.65), false, 1.5)
			_draw_corner_brackets(h_rect.grow(2.0), Color(0.3, 0.95, 1.0, 0.85), 8.0, 1.8)
		elif hovered_item_type == "ground" and hovered_item_idx < editor_ground.size():
			var gr: Rect2 = editor_ground[hovered_item_idx]
			var sr := Rect2(_world_to_screen(gr.position), gr.size)
			_draw_corner_brackets(sr.grow(3.0), Color(0.3, 0.9, 0.5, 0.7), 6.0, 1.5)
		elif hovered_item_type == "enemy" and hovered_item_idx < editor_enemies.size():
			var sp := _world_to_screen(editor_enemies[hovered_item_idx]["pos"])
			_draw_corner_brackets(Rect2(sp - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), Color(1.0, 0.5, 0.4, 0.8), 6.0, 1.8)
		elif hovered_item_type == "powerup" and hovered_item_idx < editor_powerups.size():
			var sp := _world_to_screen(editor_powerups[hovered_item_idx]["pos"])
			_draw_corner_brackets(Rect2(sp - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), Color(1.0, 0.85, 0.3, 0.8), 6.0, 1.8)
		elif hovered_item_type == "bg_prop" and hovered_item_idx < editor_bg_props.size():
			var sp := _world_to_screen(editor_bg_props[hovered_item_idx]["pos"])
			_draw_corner_brackets(Rect2(sp - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), Color(0.2, 0.9, 1.0, 0.8), 6.0, 1.8)
	
	# Viewport Cursor Reticle
	if is_mouse_in_viewport and not is_drawing_rect and not is_moving_item and not is_panning_cam and not is_dragging_h_scroll and not is_dragging_v_scroll:
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
			var edef := _get_enemy_def(selected_enemy_type)
			overlay_control.draw_circle(sp, 8.0, edef["color"] * Color(1, 1, 1, 0.6))
			overlay_control.draw_circle(sp, 8.0, Color.WHITE, false, 1.2)
			overlay_control.draw_string(font, sp + Vector2(12.0, 4.0), "+ %s" % edef["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, edef["color"])
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
	var text_pos := Vector2(rect.position.x + 6.0, rect.position.y + rect.size.y * 0.68)
	overlay_control.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 8.0, fsize, Color.WHITE)
