
extends Node2D

func _draw():
    var tex = load('res://assets/bg_sky/recon_blimp_0.png')
    print('Testing draw_texture_rect with negative width...')
    draw_texture_rect(tex, Rect2(100, 100, -60, 36), false)
    print('Testing draw_texture_rect_region or draw_texture...')

func _ready():
    queue_redraw()
    get_tree().create_timer(0.1).timeout.connect(func(): get_tree().quit(0))
