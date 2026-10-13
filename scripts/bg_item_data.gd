class_name BgItemData
extends Resource

@export var item_id: String = "prop"
@export var display_name: String = "Background Prop"
@export var category: String = "Industrial"
@export var frames: Array[Texture2D] = []
@export var spritesheet: Texture2D = null
@export var frame_count: int = 4
@export var fps: float = 6.0
@export var loop: bool = true
@export var size: Vector2 = Vector2(32.0, 32.0)
@export var offset: Vector2 = Vector2.ZERO
@export var color_tint: Color = Color.WHITE
@export var has_light_glow: bool = false
@export var light_color: Color = Color(1.0, 0.8, 0.3, 0.3)
@export var light_radius: float = 24.0
@export var vfx_type: String = "none" # "steam", "sparks", "spores", "none"
@export var vfx_interval: float = 1.0
