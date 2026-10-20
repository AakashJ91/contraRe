class_name PowerupSensorData
extends Resource

@export var sensor_name: String = "Defense Sensor Pod"
@export var max_health: float = 3.0
@export var score_reward: int = 500
@export var default_weapon: Global.WeaponType = Global.WeaponType.SPREAD
@export var frame_textures: Array[Texture2D] = []
@export var animation_fps: float = 7.0
@export var sprite_size: Vector2 = Vector2(40.0, 48.0)
@export var core_color: Color = Color(1.0, 0.25, 0.15)
@export var pulse_glow_color: Color = Color(1.0, 0.55, 0.2)
@export var thruster_color: Color = Color(1.0, 0.55, 0.12)
@export var hover_amplitude: float = 6.5
@export var hover_speed: float = 3.2
@export var theme_tag: String = "military"
