class_name EnemyData
extends Resource

@export var enemy_name: String = "Enemy"
@export var max_health: float = 1.0
@export var move_speed: float = 100.0
@export var score_reward: int = 100
@export var contact_damage: float = 1.0
@export var sprite_texture: Texture2D = null
@export var sprite_size: Vector2 = Vector2(34.0, 34.0)
@export var attack_interval_min: float = 2.0
@export var attack_interval_max: float = 3.5
