extends Node

enum WeaponType {
	RIFLE,
	SPREAD,
	MACHINE,
	LASER
}

var score: int = 0
var high_score: int = 20000
var lives: int = 3
const PLAYER_MAX_HEALTH: int = 3
var player_health: int = 3
var current_weapon: WeaponType = WeaponType.RIFLE
var is_game_over: bool = false
var is_victory: bool = false
var current_stage: int = 1
const MAX_STAGES: int = 8

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal player_health_changed(current: int, max_val: int)
signal weapon_changed(new_weapon: WeaponType)
signal screen_shake_requested(intensity: float, duration: float)
signal boss_health_changed(current: float, max_val: float)
signal boss_defeated()
signal mini_boss_defeated()
signal boss_cutscene_started(boss_name: String, subtitle: String)
signal boss_cutscene_ended()
signal map_toggled(is_open: bool)
signal maker_mode_toggled(is_open: bool)
signal stage_started(stage_idx: int)

var active_boss_name: String = ""

var is_map_open: bool = false
var is_maker_mode: bool = false
const STAGE_INTRO_DURATION: float = 3.2
var stage_intro_timer: float = 3.2

var is_boss_cutscene_active: bool = false
var boss_cutscene_timer: float = 0.0
const BOSS_CUTSCENE_DURATION: float = 3.2
var boss_cutscene_name: String = ""
var boss_cutscene_subtitle: String = ""

func is_stage_intro_active() -> bool:
	return stage_intro_timer > 0.0

func start_stage_intro() -> void:
	stage_intro_timer = STAGE_INTRO_DURATION

func start_boss_cutscene(b_name: String = "", b_sub: String = "") -> void:
	is_boss_cutscene_active = true
	boss_cutscene_timer = BOSS_CUTSCENE_DURATION
	boss_cutscene_name = b_name if b_name != "" else get_boss_name()
	boss_cutscene_subtitle = b_sub if b_sub != "" else get_stage_full_title()
	boss_cutscene_started.emit(boss_cutscene_name, boss_cutscene_subtitle)

func skip_boss_cutscene() -> void:
	if is_boss_cutscene_active:
		is_boss_cutscene_active = false
		boss_cutscene_timer = 0.0
		boss_cutscene_ended.emit()

func toggle_map() -> void:
	is_map_open = not is_map_open
	map_toggled.emit(is_map_open)

func toggle_maker_mode() -> void:
	is_maker_mode = not is_maker_mode
	maker_mode_toggled.emit(is_maker_mode)

var sfx: Node = null

const STAGE_NAMES: Array[String] = [
	"JUNGLE",
	"WATERFALL",
	"HIVE",
	"TUNDRA",
	"REFINERY",
	"DYNAMO",
	"HANGAR",
	"SANCTUM"
]

const STAGE_FULL_TITLES: Array[String] = [
	"JUNGLE PERIMETER",
	"WATERFALL FORTRESS",
	"ALIEN HIVE BIO-CAVERN",
	"SNOWFIELD TUNDRA",
	"STEEL REFINERY",
	"ELECTRIC DYNAMO",
	"ALIEN AEROSPACE HANGAR",
	"MOTHER BRAIN SANCTUM"
]

const BOSS_NAMES: Array[String] = [
	"RED FALCON DEFENSE WALL",
	"HYDRO MECH",
	"BIO-HEART",
	"SIEGE TANK",
	"MAGMA FORGE",
	"THUNDER DYNAMO",
	"STAR CRUISER",
	"MOTHER BRAIN"
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enforce_fullscreen()
	var sfx_script = load("res://scripts/sound_fx.gd")
	sfx = sfx_script.new()
	add_child(sfx)

func _process(delta: float) -> void:
	if stage_intro_timer > 0.0:
		stage_intro_timer = maxf(0.0, stage_intro_timer - delta)
	if is_boss_cutscene_active:
		boss_cutscene_timer = maxf(0.0, boss_cutscene_timer - delta)
		if boss_cutscene_timer <= 0.0:
			is_boss_cutscene_active = false
			boss_cutscene_ended.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_enforce_fullscreen()

func _enforce_fullscreen() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.get_name() == "Android":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		# Defer across initial frames to guarantee Android SurfaceView / WindowManager binds sticky immersive mode
		_deferred_enforce_fullscreen.call_deferred()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func is_mobile_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.get_name() == "Android"

func _deferred_enforce_fullscreen() -> void:
	for i in range(3):
		if not is_inside_tree():
			return
		await get_tree().process_frame
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var cur := DisplayServer.window_get_mode()
			if cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func get_stage_name(stage_idx: int = -1) -> String:
	var idx := (current_stage if stage_idx <= 0 else stage_idx) - 1
	if idx >= 0 and idx < STAGE_NAMES.size():
		return STAGE_NAMES[idx]
	return "ZONE"

func get_stage_full_title(stage_idx: int = -1) -> String:
	var idx := (current_stage if stage_idx <= 0 else stage_idx) - 1
	if idx >= 0 and idx < STAGE_FULL_TITLES.size():
		return STAGE_FULL_TITLES[idx]
	return get_stage_name(stage_idx)

func get_boss_name(stage_idx: int = -1) -> String:
	if active_boss_name != "":
		return active_boss_name
	var idx := (current_stage if stage_idx <= 0 else stage_idx) - 1
	if idx >= 0 and idx < BOSS_NAMES.size():
		return BOSS_NAMES[idx]
	return "BOSS CORE"

func add_score(amount: int) -> void:
	score += amount
	if score > high_score:
		high_score = score
	score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives < 0:
		is_game_over = true

func set_weapon(weapon: WeaponType) -> void:
	current_weapon = weapon
	weapon_changed.emit(current_weapon)
	play_sfx("powerup")

func play_sfx(name: String) -> void:
	if sfx != null:
		sfx.play(name)

func shake_screen(intensity: float = 6.0, duration: float = 0.25) -> void:
	screen_shake_requested.emit(intensity, duration)

func heal_player(amount: int = 1) -> void:
	player_health = mini(PLAYER_MAX_HEALTH, player_health + amount)
	player_health_changed.emit(player_health, PLAYER_MAX_HEALTH)

func set_player_health(amount: int) -> void:
	player_health = clampi(amount, 0, PLAYER_MAX_HEALTH)
	player_health_changed.emit(player_health, PLAYER_MAX_HEALTH)

func reset_game() -> void:
	score = 0
	lives = 3
	player_health = PLAYER_MAX_HEALTH
	current_weapon = WeaponType.RIFLE
	is_game_over = false
	is_victory = false
	is_map_open = false
	is_boss_cutscene_active = false
	boss_cutscene_timer = 0.0
	start_stage_intro()
	score_changed.emit(score)
	lives_changed.emit(lives)
	player_health_changed.emit(player_health, PLAYER_MAX_HEALTH)
	weapon_changed.emit(current_weapon)
	map_toggled.emit(false)

func start_game(stage_idx: int = 1) -> void:
	current_stage = clampi(stage_idx, 1, MAX_STAGES)
	reset_game()
	stage_started.emit(current_stage)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func advance_to_next_stage() -> void:
	if current_stage < MAX_STAGES:
		current_stage += 1
		is_victory = false
		is_game_over = false
		stage_started.emit(current_stage)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		go_to_level_select()

func go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func go_to_prologue() -> void:
	get_tree().change_scene_to_file("res://scenes/prologue.tscn")
