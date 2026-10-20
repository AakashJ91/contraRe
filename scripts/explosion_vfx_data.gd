class_name ExplosionVFXData
extends Resource

# =============================================================================
# CONTRA RE - EXPLOSION VFX RESOURCE CONFIGURATION
# =============================================================================
# Encapsulates data-driven attributes for high-impact 16-bit arcade explosions:
# - Custom themed animation frames (Fiery, Electric, Alien, Nuclear, Cryo, Magma, Mini)
# - Shockwave rings & radial blast expansion
# - Outward flying hot shrapnel & debris
# - Sizzling embers & electric spark discharge
# - Lingering cooling smoke clouds
# - Dynamic camera screenshake & dedicated retro SFX
# =============================================================================

@export var explosion_name: String = "Arcade Fiery"
@export var category: String = "Fiery" # Fiery, Electric, Alien, Nuclear, Cryo, Magma, Mini
@export var scale_mult: float = 1.0
@export var duration: float = 0.52
@export var is_electric: bool = false
@export var is_alien: bool = false

# Color styling
@export var primary_color: Color = Color(1.0, 0.85, 0.3) # Core explosion tint / animation modulation
@export var secondary_color: Color = Color(1.0, 0.45, 0.1) # Fire mantle / secondary glow
@export var shockwave_color: Color = Color(1.0, 0.85, 0.3, 0.85)

# Shockwave rings
@export var shockwave_radius: float = 58.0
@export var shockwave_ring_count: int = 2
@export var shockwave_ring_width: float = 3.5

# Flying debris / shrapnel
@export var debris_count: int = 7
@export var debris_speed_min: float = 90.0
@export var debris_speed_max: float = 240.0
@export var debris_color: Color = Color(1.0, 1.0, 1.0)
@export var debris_gravity: float = 450.0

# Embers & sparks
@export var sparks_count: int = 12
@export var sparks_speed_min: float = 70.0
@export var sparks_speed_max: float = 280.0
@export var sparks_color: Color = Color(1.0, 0.85, 0.25)

# Smoke & vapor
@export var smoke_count: int = 6
@export var smoke_color: Color = Color(0.2, 0.2, 0.25, 0.75)
@export var smoke_buoyancy: float = 25.0

# Screenshake & audio feedback
@export var screen_shake_intensity: float = 5.0
@export var screen_shake_duration: float = 0.25
@export var sfx_name: String = "explosion"

# Custom animation frame overrides
@export var explosion_frames: Array[Texture2D] = []
@export var frame_size: Vector2 = Vector2(96.0, 96.0)
