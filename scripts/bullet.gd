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

var lifetime: float = 2.5

func _ready() -> void:
	monitoring = true
	monitorable = true
	if bullet_owner == BulletOwner.PLAYER:
		collision_layer = 1 << 3 # Layer 4: PlayerBullets
		collision_mask = (1 << 2) # Layer 3: Enemies
	else:
		collision_layer = 1 << 4 # Layer 5: EnemyBullets
		collision_mask = (1 << 0) # Layer 1: Player
		speed = 260.0
		damage = 1.0
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	if bullet_owner == BulletOwner.PLAYER:
		match weapon_type:
			Global.WeaponType.RIFLE:
				# Sharp white-cyan energy pellet
				draw_circle(Vector2.ZERO, 3.5, Color(0.9, 0.95, 1.0))
				draw_circle(Vector2.ZERO, 1.8, Color(1.0, 1.0, 1.0))
			Global.WeaponType.SPREAD:
				# Glowing red-orange plasma sphere
				draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.2, 0.1, 0.4))
				draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.45, 0.1))
				draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.9, 0.3))
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
	if target.has_method("take_damage"):
		target.take_damage(damage)
		
		if bullet_owner == BulletOwner.PLAYER:
			var hit_norm := -direction
			if weapon_type == Global.WeaponType.LASER:
				VFX.spawn_laser_hit(global_position, hit_norm)
			else:
				var spk_col := Color(1.0, 0.9, 0.35)
				if weapon_type == Global.WeaponType.SPREAD:
					spk_col = Color(1.0, 0.5, 0.2)
				VFX.spawn_hit_sparks(global_position, hit_norm, spk_col)
			
			var is_alien := true
			var t_name := target.name.to_lower()
			if t_name.contains("soldier") or t_name.contains("sniper"):
				is_alien = false
			VFX.spawn_blood_splatter(global_position, direction, is_alien)
		else:
			VFX.spawn_blood_splatter(global_position, direction, false)
			VFX.spawn_hit_sparks(global_position, -direction, Color(1.0, 0.3, 0.2))
		
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()
	elif target.is_in_group("world_solid"):
		VFX.spawn_hit_sparks(global_position, -direction, Color(0.9, 0.85, 0.5))
		queue_free()
