extends Node2D

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

var max_health: float = 35.0
var current_health: float = 35.0
var is_active: bool = false
var is_dead: bool = false

var core_flash_timer: float = 0.0
var cannon_shoot_timer: float = 1.6
var top_turret_timer: float = 2.4
var core_pulse: float = 0.0

var death_chain_timer: float = 0.0
var death_explosions_left: int = 14

@onready var core_area: Area2D = $CoreArea
@onready var left_cannon: Area2D = $LeftCannon
@onready var right_cannon: Area2D = $RightCannon

var left_cannon_hp: float = 12.0
var right_cannon_hp: float = 12.0

func _ready() -> void:
	Global.boss_health_changed.emit(current_health, max_health)
	core_area.area_entered.connect(_on_core_hit)
	left_cannon.area_entered.connect(_on_left_cannon_hit)
	right_cannon.area_entered.connect(_on_right_cannon_hit)
	queue_redraw()

func activate() -> void:
	if not is_active and not is_dead:
		is_active = true
		Global.play_sfx("boss_alarm")
		Global.shake_screen(8.0, 0.4)

func _physics_process(delta: float) -> void:
	core_pulse += delta * 6.0
	
	if is_dead:
		_process_death_sequence(delta)
		queue_redraw()
		return
	
	if not is_active:
		return
	
	if core_flash_timer > 0.0:
		core_flash_timer -= delta
	
	cannon_shoot_timer -= delta
	if cannon_shoot_timer <= 0.0:
		cannon_shoot_timer = 2.2
		_fire_cannons()
	
	top_turret_timer -= delta
	if top_turret_timer <= 0.0:
		top_turret_timer = 1.8
		_fire_top_turret()
	
	queue_redraw()

func _fire_cannons() -> void:
	if bullet_scene == null:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	
	if left_cannon_hp > 0.0:
		var dir: Vector2 = (player_node.global_position - (global_position + Vector2(-60.0, 40.0))).normalized()
		var b1 = bullet_scene.instantiate()
		b1.bullet_owner = b1.BulletOwner.ENEMY
		b1.direction = dir
		b1.speed = 280.0
		b1.global_position = global_position + Vector2(-60.0, 40.0) + dir * 16.0
		get_parent().add_child(b1)
	
	if right_cannon_hp > 0.0:
		var dir: Vector2 = (player_node.global_position - (global_position + Vector2(60.0, 40.0))).normalized()
		var b2 = bullet_scene.instantiate()
		b2.bullet_owner = b2.BulletOwner.ENEMY
		b2.direction = dir
		b2.speed = 280.0
		b2.global_position = global_position + Vector2(60.0, 40.0) + dir * 16.0
		get_parent().add_child(b2)

func _fire_top_turret() -> void:
	if bullet_scene == null:
		return
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node == null or not is_instance_valid(player_node):
		return
	var dir: Vector2 = (player_node.global_position - (global_position + Vector2(0.0, -50.0))).normalized()
	# Twin spread shot from top defense hatch
	for angle in [-0.2, 0.2]:
		var b = bullet_scene.instantiate()
		b.bullet_owner = b.BulletOwner.ENEMY
		b.direction = dir.rotated(angle)
		b.speed = 290.0
		b.global_position = global_position + Vector2(0.0, -50.0)
		get_parent().add_child(b)

func _on_core_hit(area: Area2D) -> void:
	if is_dead:
		return
	if area.is_in_group("bullet") or area.has_method("_handle_hit"):
		var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
		take_damage(dmg)

func _on_left_cannon_hit(area: Area2D) -> void:
	if left_cannon_hp <= 0.0:
		return
	var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
	left_cannon_hp -= dmg
	Global.play_sfx("hit")
	if left_cannon_hp <= 0.0:
		_destroy_sub_part(global_position + Vector2(-60.0, 40.0))

func _on_right_cannon_hit(area: Area2D) -> void:
	if right_cannon_hp <= 0.0:
		return
	var dmg: float = area.get("damage") if area.get("damage") != null else 1.0
	right_cannon_hp -= dmg
	Global.play_sfx("hit")
	if right_cannon_hp <= 0.0:
		_destroy_sub_part(global_position + Vector2(60.0, 40.0))

func _destroy_sub_part(pos: Vector2) -> void:
	Global.add_score(1500)
	Global.shake_screen(6.0, 0.3)
	if explosion_scene != null:
		var exp_node = explosion_scene.instantiate()
		exp_node.global_position = pos
		get_parent().add_child(exp_node)

func take_damage(dmg: float = 1.0) -> void:
	if not is_active or is_dead:
		return
	current_health -= dmg
	core_flash_timer = 0.08
	Global.play_sfx("hit")
	Global.boss_health_changed.emit(maxf(0.0, current_health), max_health)
	if current_health <= 0.0:
		_trigger_death()

func _trigger_death() -> void:
	is_dead = true
	Global.add_score(10000)
	Global.is_victory = true
	Global.boss_defeated.emit()
	death_explosions_left = 16
	death_chain_timer = 0.05
	core_area.monitoring = false
	core_area.monitorable = false

func _process_death_sequence(delta: float) -> void:
	death_chain_timer -= delta
	if death_chain_timer <= 0.0 and death_explosions_left > 0:
		death_chain_timer = 0.12
		death_explosions_left -= 1
		Global.shake_screen(10.0, 0.25)
		if explosion_scene != null:
			var offset := Vector2(randf_range(-90.0, 90.0), randf_range(-70.0, 70.0))
			var exp_node = explosion_scene.instantiate()
			exp_node.global_position = global_position + offset
			get_parent().add_child(exp_node)

func _draw() -> void:
	# Heavy armored bunker wall
	var col_wall := Color(0.24, 0.27, 0.32)
	var col_wall_dark := Color(0.16, 0.18, 0.22)
	var col_plates := Color(0.35, 0.38, 0.44)
	var col_hazard := Color(0.9, 0.7, 0.1)
	
	# Wall foundation structure (220 x 180)
	draw_rect(Rect2(-110.0, -90.0, 220.0, 180.0), col_wall_dark)
	draw_rect(Rect2(-100.0, -80.0, 200.0, 160.0), col_wall)
	
	# Armor plating rivets & panels
	draw_rect(Rect2(-90.0, -70.0, 60.0, 45.0), col_plates)
	draw_rect(Rect2(30.0, -70.0, 60.0, 45.0), col_plates)
	draw_rect(Rect2(-90.0, 15.0, 50.0, 55.0), col_plates)
	draw_rect(Rect2(40.0, 15.0, 50.0, 55.0), col_plates)
	
	# Hazard warning stripes at bottom
	for i in range(10):
		var x_pos := -95.0 + float(i) * 19.0
		draw_line(Vector2(x_pos, 70.0), Vector2(x_pos + 10.0, 80.0), col_hazard, 3.0)
	
	# Left heavy cannon
	if left_cannon_hp > 0.0:
		draw_circle(Vector2(-60.0, 40.0), 16.0, Color(0.3, 0.32, 0.36))
		draw_rect(Rect2(-75.0, 34.0, -22.0, 12.0), Color(0.15, 0.17, 0.2)) # Barrels
		draw_circle(Vector2(-60.0, 40.0), 8.0, Color(0.8, 0.2, 0.2))
	else:
		# Burned wreckage
		draw_circle(Vector2(-60.0, 40.0), 14.0, Color(0.1, 0.1, 0.12))
	
	# Right heavy cannon
	if right_cannon_hp > 0.0:
		draw_circle(Vector2(60.0, 40.0), 16.0, Color(0.3, 0.32, 0.36))
		draw_rect(Rect2(75.0, 34.0, 22.0, 12.0), Color(0.15, 0.17, 0.2))
		draw_circle(Vector2(60.0, 40.0), 8.0, Color(0.8, 0.2, 0.2))
	else:
		draw_circle(Vector2(60.0, 40.0), 14.0, Color(0.1, 0.1, 0.12))
	
	# Top turret bunker hatch
	draw_rect(Rect2(-25.0, -85.0, 50.0, 22.0), Color(0.2, 0.22, 0.26))
	draw_circle(Vector2(0.0, -75.0), 12.0, Color(0.4, 0.42, 0.46))
	draw_line(Vector2(-6.0, -75.0), Vector2(-18.0, -58.0), Color(0.1, 0.1, 0.12), 4.0)
	draw_line(Vector2(6.0, -75.0), Vector2(18.0, -58.0), Color(0.1, 0.1, 0.12), 4.0)
	
	# Alien Defense Core in Center
	var core_color := Color(0.2, 0.8, 1.0)
	if core_flash_timer > 0.0:
		core_color = Color(1.0, 0.2, 0.2)
	elif is_dead:
		core_color = Color(0.15, 0.15, 0.15)
	
	# Glowing octagon frame
	draw_rect(Rect2(-24.0, -12.0, 48.0, 40.0), Color(0.1, 0.12, 0.15))
	var pulse_glow := (sin(core_pulse) + 1.0) * 0.5
	draw_circle(Vector2(0.0, 8.0), 16.0 + pulse_glow * 3.0, Color(core_color.r, core_color.g, core_color.b, 0.3))
	draw_circle(Vector2(0.0, 8.0), 13.0, core_color)
	draw_circle(Vector2(0.0, 8.0), 6.0, Color(1.0, 1.0, 1.0, 0.8))
