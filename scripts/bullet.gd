extends Area2D

enum BulletOwner {
	PLAYER,
	ENEMY
}

@export var bullet_owner: BulletOwner = BulletOwner.PLAYER
@export var weapon_type: Global.WeaponType = Global.WeaponType.RIFLE
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 600.0
@export var damage: float = 1.0
@export var pierce_count: int = 1
@export var is_twisting: bool = false
@export var twist_phase: float = 0.0
@export var twist_amplitude: float = 16.0
@export var twist_frequency: float = 18.0

var lifetime: float = 2.5
var travel_time: float = 0.0
var base_fwd_pos: Vector2 = Vector2.ZERO
var tail_positions: Array[Vector2] = []

func _ready() -> void:
	base_fwd_pos = global_position
	add_to_group("bullet")
	monitoring = true
	monitorable = true
	if bullet_owner == BulletOwner.PLAYER:
		add_to_group("player_bullets")
		collision_layer = 1 << 3 # Layer 4: PlayerBullets
		collision_mask = (1 << 2) # Layer 3: Enemies
	else:
		add_to_group("enemy_bullets")
		collision_layer = 1 << 4 # Layer 5: EnemyBullets
		collision_mask = (1 << 0) # Layer 1: Player
		if speed == 600.0:
			speed = 260.0
		if damage == 1.0:
			damage = 1.0
	
	z_index = 5
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	travel_time += delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	if is_twisting:
		base_fwd_pos += direction * speed * delta
		var normal := Vector2(-direction.y, direction.x)
		var offset := normal * (sin(travel_time * twist_frequency + twist_phase) * twist_amplitude)
		global_position = base_fwd_pos + offset
		
		tail_positions.push_front(global_position)
		if tail_positions.size() > 6:
			tail_positions.pop_back()
	else:
		global_position += direction * speed * delta
	
	if weapon_type == Global.WeaponType.SPREAD or weapon_type == Global.WeaponType.FIRE:
		queue_redraw()

func _draw() -> void:
	if bullet_owner == BulletOwner.PLAYER:
		match weapon_type:
			Global.WeaponType.RIFLE:
				# Sharp white-cyan energy pellet
				draw_circle(Vector2.ZERO, 3.5, Color(0.9, 0.95, 1.0))
				draw_circle(Vector2.ZERO, 1.8, Color(1.0, 1.0, 1.0))
			Global.WeaponType.SPREAD:
				# Classic Contra expanding fiery plasma spheres
				var growth: float = clampf(travel_time * 6.5, 0.0, 3.2)
				var r_outer: float = 4.8 + growth
				var r_mid: float = 3.4 + growth * 0.7
				var r_core: float = 2.0 + growth * 0.4
				var pulse: float = 0.88 + 0.12 * sin(travel_time * 26.0)
				
				# Outer fiery amber aura
				draw_circle(Vector2.ZERO, r_outer * pulse, Color(1.0, 0.25, 0.05, 0.42))
				# Mid incandescent plasma mantle
				draw_circle(Vector2.ZERO, r_mid, Color(1.0, 0.52, 0.12))
				# Inner fiery golden glow
				draw_circle(Vector2.ZERO, r_core * 1.3, Color(1.0, 0.85, 0.32))
				# Super-hot white-hot core
				draw_circle(Vector2.ZERO, r_core * 0.75, Color(1.0, 1.0, 0.95))
			Global.WeaponType.MACHINE:
				# Rapid fire yellow tracer
				var trail := -direction * 8.0
				draw_line(trail, Vector2.ZERO, Color(1.0, 0.8, 0.2), 3.0)
				draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 0.7))
			Global.WeaponType.LASER:
				# Long electric cyan beam
				var tail := -direction * 22.0
				draw_line(tail, Vector2.ZERO, Color(0.1, 0.8, 1.0, 0.6), 5.0)
				draw_line(tail, Vector2.ZERO, Color(0.7, 0.95, 1.0), 2.5)
			Global.WeaponType.FIRE:
				# Classic Contra Twisting Fireball / Corkscrew Flame
				# 1. Trailing fiery corkscrew tail
				for i in range(tail_positions.size()):
					var tp := to_local(tail_positions[i])
					var factor := 1.0 - float(i) / float(tail_positions.size())
					var trail_rad := 4.6 * factor
					var trail_alpha := 0.36 * factor
					draw_circle(tp, trail_rad, Color(1.0, 0.35, 0.05, trail_alpha))
					draw_circle(tp, trail_rad * 0.55, Color(1.0, 0.78, 0.18, trail_alpha * 1.4))
				
				# 2. Outer blazing corona with pulse
				var pulse: float = 0.9 + 0.1 * sin(travel_time * 28.0 + twist_phase)
				var r_outer: float = 7.5 * pulse
				draw_circle(Vector2.ZERO, r_outer, Color(1.0, 0.22, 0.04, 0.40))
				
				# 3. Swirling comet spurs / flame petals spinning around center
				var spin_angle: float = travel_time * 20.0 + twist_phase
				for k in range(3):
					var a: float = spin_angle + k * (TAU / 3.0)
					var spur_offset := Vector2(cos(a), sin(a)) * 4.2
					draw_circle(spur_offset, 2.8, Color(1.0, 0.45, 0.08, 0.75))
					draw_circle(spur_offset, 1.4, Color(1.0, 0.92, 0.35, 0.95))
				
				# 4. Mid incandescent mantle
				draw_circle(Vector2.ZERO, 5.2, Color(1.0, 0.52, 0.1))
				# 5. Inner fiery yellow glow
				draw_circle(Vector2.ZERO, 3.4, Color(1.0, 0.86, 0.25))
				# 6. Superheated white core
				draw_circle(Vector2.ZERO, 1.8, Color(1.0, 0.98, 0.92))
	else:
		# Enemy bullet: glowing red/orange pellet with pulsating core
		draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.1, 0.1, 0.6))
		draw_circle(Vector2.ZERO, 2.8, Color(1.0, 0.3, 0.2))
		draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.9, 0.8))

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area)

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _handle_hit(target: Node2D) -> void:
	if target == null:
		return
	
	# Resolve parent target if hitting child hurtbox / subpart
	var actual_target: Node2D = target
	if not actual_target.has_method("take_damage") and actual_target.get_parent() != null and actual_target.get_parent().has_method("take_damage"):
		actual_target = actual_target.get_parent()
	
	if target.name == "LeftCannon" and actual_target.has_method("_on_left_part_hit"):
		actual_target._on_left_part_hit(self)
		_spawn_hit_vfx(actual_target)
		_decrement_pierce()
	elif target.name == "RightCannon" and actual_target.has_method("_on_right_part_hit"):
		actual_target._on_right_part_hit(self)
		_spawn_hit_vfx(actual_target)
		_decrement_pierce()
	elif actual_target.has_method("take_damage"):
		actual_target.take_damage(damage)
		_spawn_hit_vfx(actual_target)
		_decrement_pierce()
	elif target.is_in_group("world_solid"):
		VFX.spawn_hit_sparks(global_position, -direction, Color(0.9, 0.85, 0.5))
		queue_free()

func _spawn_hit_vfx(hit_target: Node2D) -> void:
	if bullet_owner == BulletOwner.PLAYER:
		var hit_norm := -direction
		if weapon_type == Global.WeaponType.LASER:
			VFX.spawn_laser_hit(global_position, hit_norm)
		elif weapon_type == Global.WeaponType.FIRE:
			VFX.spawn_hit_sparks(global_position, hit_norm, Color(1.0, 0.45, 0.1))
			VFX.spawn_explosion(global_position, 0.75)
		else:
			var spk_col := Color(1.0, 0.9, 0.35)
			if weapon_type == Global.WeaponType.SPREAD:
				spk_col = Color(1.0, 0.5, 0.2)
			VFX.spawn_hit_sparks(global_position, hit_norm, spk_col)
		
		var is_alien := true
		var t_name := hit_target.name.to_lower()
		if t_name.contains("soldier") or t_name.contains("sniper"):
			is_alien = false
		VFX.spawn_blood_splatter(global_position, direction, is_alien)
	else:
		VFX.spawn_blood_splatter(global_position, direction, false)
		VFX.spawn_hit_sparks(global_position, -direction, Color(1.0, 0.3, 0.2))

func _decrement_pierce() -> void:
	pierce_count -= 1
	if pierce_count <= 0:
		queue_free()
