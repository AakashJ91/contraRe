import os

script_template_header = """extends CharacterBody2D

@export var enemy_data: EnemyData = preload("res://resources/enemies/{enemy_id}_data.tres")
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

const SPEED: float = {speed}
const GRAVITY: float = {gravity}

var health: float = {hp}
var facing_dir: int = -1
var shoot_timer: float = {shoot_timer_init}
var anim_frame: float = 0.0
var flash_timer: float = 0.0

var base_texture: Texture2D = null
var walk_textures: Array[Texture2D] = []
var death_textures: Array[Texture2D] = []
var is_dying: bool = false
var death_frame: int = 0
var death_timer: float = 0.0
"""

# Let's write the generator script that outputs each enemy GDScript file with precision.
with open("scratch/generate_16_enemy_scripts.py", "w", encoding="utf-8") as f:
    f.write("# Helper to generate 16 enemy scripts\n")
