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
var current_weapon: WeaponType = WeaponType.RIFLE
var is_game_over: bool = false
var is_victory: bool = false
var current_stage: int = 1

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal weapon_changed(new_weapon: WeaponType)
signal screen_shake_requested(intensity: float, duration: float)
signal boss_health_changed(current: float, max_val: float)
signal boss_defeated()

var sfx: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sfx_script = load("res://scripts/sound_fx.gd")
	sfx = sfx_script.new()
	add_child(sfx)

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

func reset_game() -> void:
	score = 0
	lives = 3
	current_weapon = WeaponType.RIFLE
	is_game_over = false
	is_victory = false
	score_changed.emit(score)
	lives_changed.emit(lives)
	weapon_changed.emit(current_weapon)

func start_game(stage_idx: int = 1) -> void:
	current_stage = stage_idx
	reset_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

