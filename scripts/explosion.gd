extends Node2D

@export var duration: float = 0.4
@export var radius: float = 24.0
@export var color1: Color = Color(1.0, 0.9, 0.2)
@export var color2: Color = Color(1.0, 0.3, 0.1)
@export var color3: Color = Color(0.3, 0.3, 0.3, 0.8)

var elapsed: float = 0.0
var sparks: Array[Dictionary] = []

func _ready() -> void:
	Global.play_sfx("explosion")
	Global.shake_screen(5.0, 0.2)
	# Generate random spark particles
	for i in range(12):
		var angle := randf_range(0.0, TAU)
		var spd := randf_range(40.0, 160.0)
		sparks.append({
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"pos": Vector2.ZERO,
			"size": randf_range(2.0, 4.0)
		})
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	
	for s in sparks:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.92
	queue_redraw()

func _draw() -> void:
	var t := elapsed / duration
	var current_radius := radius * (0.3 + 0.7 * sqrt(t))
	var alpha := 1.0 - t
	
	# Expanding fireball ring
	draw_circle(Vector2.ZERO, current_radius * 1.2, Color(color2.r, color2.g, color2.b, alpha * 0.4))
	draw_circle(Vector2.ZERO, current_radius * 0.8, Color(color1.r, color1.g, color1.b, alpha * 0.8))
	draw_circle(Vector2.ZERO, current_radius * 0.4, Color(1.0, 1.0, 1.0, alpha))
	
	# Flying sparks
	for s in sparks:
		var col := color1 if randf() > 0.4 else color2
		col.a = alpha
		draw_circle(s["pos"], s["size"] * (1.0 - t * 0.5), col)
