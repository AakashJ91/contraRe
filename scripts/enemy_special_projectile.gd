class_name EnemySpecialProjectile
extends Area2D

enum ProjectileType {
	FLAME,
	HARPOON,
	DEPTH_CHARGE,
	SHOCKWAVE,
	ACID_GLOB,
	ACID_PUDDLE,
	ICE_MORTAR,
	ICE_SHARD,
	SLAG_WAVE,
	RIVET,
	BALL_LIGHTNING,
	SPARK_CROSS,
	HOMING_MISSILE,
	NEEDLE_DART,
	PSYCHIC_RING
}

@export var proj_type: ProjectileType = ProjectileType.FLAME
@export var damage: float = 1.0

var velocity: Vector2 = Vector2.ZERO
var gravity_accel: float = 0.0
var lifetime: float = 3.0
var anim_timer: float = 0.0
var radius: float = 6.0
var col_shape: CollisionShape2D = null

func _ready() -> void:
	collision_layer = 1 << 4 # Layer 5: EnemyBullets
	collision_mask = (1 << 0) | (1 << 1) # Layer 1: Player, Layer 2: World
	z_index = 6
	
	col_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	
	match proj_type:
		ProjectileType.FLAME:
			radius = 8.0
			lifetime = 1.8
			gravity_accel = 280.0
		ProjectileType.HARPOON:
			radius = 6.0
			lifetime = 3.0
			gravity_accel = 0.0
		ProjectileType.DEPTH_CHARGE:
			radius = 9.0
			lifetime = 3.5
			gravity_accel = 620.0
		ProjectileType.SHOCKWAVE:
			radius = 12.0
			lifetime = 1.6
			gravity_accel = 0.0
		ProjectileType.ACID_GLOB:
			radius = 8.0
			lifetime = 3.0
			gravity_accel = 520.0
		ProjectileType.ACID_PUDDLE:
			radius = 16.0
			lifetime = 2.5
			gravity_accel = 0.0
		ProjectileType.ICE_MORTAR:
			radius = 8.0
			lifetime = 3.0
			gravity_accel = 580.0
		ProjectileType.ICE_SHARD:
			radius = 5.0
			lifetime = 1.8
			gravity_accel = 0.0
		ProjectileType.SLAG_WAVE:
			radius = 14.0
			lifetime = 2.0
			gravity_accel = 0.0
		ProjectileType.RIVET:
			radius = 5.0
			lifetime = 2.5
			gravity_accel = 0.0
		ProjectileType.BALL_LIGHTNING:
			radius = 10.0
			lifetime = 3.5
			gravity_accel = 0.0
		ProjectileType.SPARK_CROSS:
			radius = 6.0
			lifetime = 2.0
			gravity_accel = 0.0
		ProjectileType.HOMING_MISSILE:
			radius = 6.0
			lifetime = 3.2
			gravity_accel = 0.0
		ProjectileType.NEEDLE_DART:
			radius = 4.0
			lifetime = 2.2
			gravity_accel = 0.0
		ProjectileType.PSYCHIC_RING:
			radius = 24.0
			lifetime = 1.8
			gravity_accel = 0.0
			# Also collides with player bullets to deflect them
			collision_mask |= (1 << 3) # Layer 4: PlayerBullets
	
	shape.radius = radius
	col_shape.shape = shape
	add_child(col_shape)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	anim_timer += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_on_expire()
		queue_free()
		return
	
	# Homing behavior for missiles & ball lightning
	if proj_type == ProjectileType.HOMING_MISSILE or proj_type == ProjectileType.BALL_LIGHTNING:
		var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player_node != null and is_instance_valid(player_node):
			var to_player := (player_node.global_position - global_position).normalized()
			var turn_rate: float = 3.5 if proj_type == ProjectileType.HOMING_MISSILE else 1.8
			var cur_dir := velocity.normalized()
			var new_dir := cur_dir.lerp(to_player, turn_rate * delta).normalized()
			velocity = new_dir * velocity.length()
	
	velocity.y += gravity_accel * delta
	global_position += velocity * delta
	
	if proj_type == ProjectileType.PSYCHIC_RING:
		# Expand ring collision size
		radius += delta * 35.0
		if col_shape != null and col_shape.shape is CircleShape2D:
			(col_shape.shape as CircleShape2D).radius = radius
	
	# Out of bounds check
	if global_position.y > 620.0 or global_position.y < -150.0:
		queue_free()
		return
	
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if proj_type != ProjectileType.ACID_PUDDLE and proj_type != ProjectileType.PSYCHIC_RING:
			queue_free()
	elif body.collision_layer & (1 << 1): # World collision
		_handle_world_impact()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or (area.get_parent() != null and area.get_parent().is_in_group("player")):
		var p = area if area.is_in_group("player") else area.get_parent()
		if p.has_method("take_damage"):
			p.take_damage(damage)
		if proj_type != ProjectileType.ACID_PUDDLE and proj_type != ProjectileType.PSYCHIC_RING:
			queue_free()
	elif proj_type == ProjectileType.PSYCHIC_RING and (area.collision_layer & (1 << 3)):
		# Deflect player bullets
		VFX.spawn_hit_sparks(area.global_position, Vector2.UP, Color(0.8, 0.4, 1.0))
		area.queue_free()

func _handle_world_impact() -> void:
	match proj_type:
		ProjectileType.FLAME:
			VFX.spawn_dust_puff(global_position, 3, Color(1.0, 0.5, 0.2))
			queue_free()
		ProjectileType.HARPOON, ProjectileType.RIVET, ProjectileType.NEEDLE_DART, ProjectileType.SPARK_CROSS:
			VFX.spawn_hit_sparks(global_position, -velocity.normalized(), Color(0.9, 0.9, 0.9))
			queue_free()
		ProjectileType.DEPTH_CHARGE:
			_detonate_depth_charge()
			queue_free()
		ProjectileType.ACID_GLOB:
			_spawn_acid_puddle()
			queue_free()
		ProjectileType.ICE_MORTAR:
			_detonate_ice_mortar()
			queue_free()
		ProjectileType.HOMING_MISSILE:
			VFX.spawn_explosion(global_position)
			Global.shake_screen(4.0, 0.2)
			queue_free()
		ProjectileType.BALL_LIGHTNING:
			VFX.spawn_hit_sparks(global_position, Vector2.UP, Color(0.4, 0.8, 1.0))
			queue_free()
		ProjectileType.SHOCKWAVE, ProjectileType.SLAG_WAVE, ProjectileType.ACID_PUDDLE:
			# Stay on floor
			pass
		_:
			queue_free()

func _on_expire() -> void:
	if proj_type == ProjectileType.DEPTH_CHARGE:
		_detonate_depth_charge()
	elif proj_type == ProjectileType.ICE_MORTAR:
		_detonate_ice_mortar()

func _detonate_depth_charge() -> void:
	VFX.spawn_explosion(global_position)
	Global.shake_screen(5.0, 0.25)
	Global.play_sfx("explosion")
	# Spawn shockwaves left and right
	var parent_node = get_parent()
	if parent_node == null: return
	for dir_x in [-1.0, 1.0]:
		var sw = EnemySpecialProjectile.new()
		sw.proj_type = ProjectileType.SHOCKWAVE
		sw.damage = 1.0
		sw.velocity = Vector2(dir_x * 160.0, 0.0)
		sw.global_position = global_position + Vector2(dir_x * 12.0, -4.0)
		parent_node.add_child(sw)

func _spawn_acid_puddle() -> void:
	var parent_node = get_parent()
	if parent_node == null: return
	VFX.spawn_dust_puff(global_position, 4, Color(0.2, 0.9, 0.3))
	Global.play_sfx("hit")
	var puddle = EnemySpecialProjectile.new()
	puddle.proj_type = ProjectileType.ACID_PUDDLE
	puddle.damage = 1.0
	puddle.velocity = Vector2.ZERO
	puddle.global_position = global_position + Vector2(0.0, -2.0)
	parent_node.add_child(puddle)

func _detonate_ice_mortar() -> void:
	VFX.spawn_hit_sparks(global_position, Vector2.UP, Color(0.6, 0.95, 1.0))
	Global.play_sfx("hit")
	var parent_node = get_parent()
	if parent_node == null: return
	for i in range(8):
		var angle := i * (PI / 4.0)
		var dir := Vector2(cos(angle), sin(angle))
		var shard = EnemySpecialProjectile.new()
		shard.proj_type = ProjectileType.ICE_SHARD
		shard.damage = 1.0
		shard.velocity = dir * 210.0
		shard.global_position = global_position
		parent_node.add_child(shard)

func _draw() -> void:
	match proj_type:
		ProjectileType.FLAME:
			var s := sin(anim_timer * 20.0) * 2.0
			draw_circle(Vector2.ZERO, 7.0 + s, Color(1.0, 0.3, 0.1, 0.7))
			draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.7, 0.15, 0.9))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 0.8))
		ProjectileType.HARPOON:
			var dir_f := velocity.normalized()
			var tail := -dir_f * 18.0
			draw_line(tail, Vector2.ZERO, Color(0.3, 0.7, 0.9, 0.6), 4.0)
			draw_line(-dir_f * 12.0, Vector2.ZERO, Color(0.9, 0.95, 1.0), 2.5)
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		ProjectileType.DEPTH_CHARGE:
			draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.25, 0.3))
			draw_circle(Vector2.ZERO, 5.0, Color(0.8, 0.2, 0.1))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.9, 0.3) if fmod(anim_timer, 0.2) < 0.1 else Color.WHITE)
		ProjectileType.SHOCKWAVE:
			var alpha := clampf(lifetime / 1.6, 0.2, 0.9)
			draw_arc(Vector2.ZERO, radius, -PI * 0.7, -PI * 0.3, 8, Color(0.3, 0.8, 1.0, alpha), 4.0)
			draw_arc(Vector2.ZERO, radius * 0.6, -PI * 0.7, -PI * 0.3, 6, Color(1.0, 1.0, 1.0, alpha), 2.5)
		ProjectileType.ACID_GLOB:
			draw_circle(Vector2.ZERO, 7.0, Color(0.2, 0.85, 0.25, 0.85))
			draw_circle(Vector2(1.5, -1.5), 3.5, Color(0.7, 1.0, 0.4))
		ProjectileType.ACID_PUDDLE:
			var pulse := sin(anim_timer * 10.0) * 1.5
			_draw_filled_ellipse(Vector2.ZERO, 15.0 + pulse, 5.0, Color(0.25, 0.9, 0.3, 0.65))
			_draw_filled_ellipse(Vector2.ZERO, 10.0, 3.0, Color(0.6, 1.0, 0.5, 0.85))
			# Bubbles
			var bx := sin(anim_timer * 8.0) * 8.0
			draw_circle(Vector2(bx, -3.0), 2.0, Color(0.8, 1.0, 0.7))
		ProjectileType.ICE_MORTAR:
			draw_circle(Vector2.ZERO, 7.5, Color(0.3, 0.75, 0.95))
			draw_circle(Vector2.ZERO, 4.0, Color(0.9, 0.98, 1.0))
		ProjectileType.ICE_SHARD:
			var v_dir := velocity.normalized()
			draw_line(-v_dir * 8.0, v_dir * 8.0, Color(0.5, 0.9, 1.0), 3.5)
			draw_line(-v_dir * 4.0, v_dir * 4.0, Color.WHITE, 1.5)
		ProjectileType.SLAG_WAVE:
			draw_arc(Vector2.ZERO, radius, -PI * 0.8, -PI * 0.2, 8, Color(1.0, 0.35, 0.1), 5.0)
			draw_arc(Vector2.ZERO, radius * 0.7, -PI * 0.8, -PI * 0.2, 6, Color(1.0, 0.85, 0.2), 3.0)
		ProjectileType.RIVET:
			var dir_f := velocity.normalized()
			draw_line(-dir_f * 10.0, Vector2.ZERO, Color(1.0, 0.45, 0.15), 3.5)
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.9, 0.5))
		ProjectileType.BALL_LIGHTNING:
			var s := sin(anim_timer * 25.0) * 2.0
			draw_circle(Vector2.ZERO, 9.0 + s, Color(0.2, 0.6, 1.0, 0.45))
			draw_circle(Vector2.ZERO, 6.0, Color(0.4, 0.85, 1.0, 0.85))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
			# Arcs
			for a in [0.0, 1.5, 3.14, 4.7]:
				var ap := Vector2(cos(a + anim_timer * 15.0), sin(a + anim_timer * 15.0)) * (7.0 + s)
				draw_line(Vector2.ZERO, ap, Color(0.7, 0.95, 1.0), 1.5)
		ProjectileType.SPARK_CROSS:
			draw_circle(Vector2.ZERO, 5.0, Color(0.3, 0.8, 1.0, 0.7))
			draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
			draw_line(Vector2(-7.0, 0.0), Vector2(7.0, 0.0), Color.CYAN, 2.0)
			draw_line(Vector2(0.0, -7.0), Vector2(0.0, 7.0), Color.CYAN, 2.0)
		ProjectileType.HOMING_MISSILE:
			var v_dir := velocity.normalized()
			draw_line(-v_dir * 10.0, v_dir * 4.0, Color(0.3, 0.35, 0.4), 4.0)
			draw_circle(v_dir * 4.0, 2.5, Color(0.9, 0.2, 0.1))
			draw_circle(-v_dir * 10.0, 2.0, Color(1.0, 0.8, 0.2)) # Rocket exhaust
		ProjectileType.NEEDLE_DART:
			var v_dir := velocity.normalized()
			draw_line(-v_dir * 12.0, Vector2.ZERO, Color(0.8, 0.2, 0.4), 2.5)
			draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.6, 0.8))
		ProjectileType.PSYCHIC_RING:
			var alpha := clampf(lifetime / 1.8, 0.1, 0.85)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.8, 0.2, 0.9, alpha * 0.4), 6.0)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.5, 1.0, alpha), 2.5)
			draw_arc(Vector2.ZERO, radius * 0.85, 0.0, TAU, 24, Color(0.4, 0.9, 1.0, alpha * 0.6), 1.5)

func _draw_filled_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 20
	for i in range(segs):
		var th := i * (TAU / segs)
		pts.append(center + Vector2(cos(th) * rx, sin(th) * ry))
	draw_colored_polygon(pts, color)
