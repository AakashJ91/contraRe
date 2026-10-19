shader_type canvas_item;

// Stage 1 Jungle Living Background Shader
// Animates water caustics & flow, palm canopy wind sway, mountain valley mist drift, and sunset atmospheric pulse

uniform float water_speed : hint_range(0.0, 5.0) = 1.4;
uniform float sway_speed : hint_range(0.0, 5.0) = 1.8;
uniform float mist_speed : hint_range(0.0, 2.0) = 0.35;
uniform float sun_pulse_speed : hint_range(0.0, 3.0) = 0.85;

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	
	// -------------------------------------------------------------------------
	// 1. JUNGLE CANOPY WIND SWAY (0.26 <= UV.y < 0.80)
	// -------------------------------------------------------------------------
	if (uv.y >= 0.26 && uv.y < 0.80) {
		// All tree tops, high palm crowns, and branches sway consistently with the breeze
		float sway_weight = smoothstep(0.80, 0.40, uv.y) * smoothstep(0.25, 0.32, uv.y);
		// Harmonic tropical breeze wave
		float sway_x = (sin(t * sway_speed + uv.x * 9.0) * 0.0028 + 
		                sin(t * (sway_speed * 1.5) + uv.x * 16.0 + uv.y * 8.0) * 0.0014) * sway_weight;
		float sway_y = cos(t * (sway_speed * 1.2) + uv.x * 11.0) * 0.0008 * sway_weight;
		uv += vec2(sway_x, sway_y);
	}
	
	// -------------------------------------------------------------------------
	// 2. FLOWING RIVER WATER & SUNSET CAUSTIC RIPPLES (UV.y >= 0.81)
	// -------------------------------------------------------------------------
	if (uv.y >= 0.81) {
		float depth_weight = smoothstep(0.81, 0.95, uv.y);
		
		// Dual-frequency horizontal water displacement
		float wave1 = sin(uv.y * 65.0 + t * (water_speed * 2.8) + uv.x * 18.0) * 0.0032;
		float wave2 = cos(uv.y * 38.0 - t * (water_speed * 1.7) + uv.x * 28.0) * 0.0020;
		float wave_y = sin(uv.x * 40.0 + t * (water_speed * 2.2)) * 0.0015 * depth_weight;
		
		uv.x += (wave1 + wave2) * depth_weight;
		uv.y += wave_y;
	}
	
	// Sample background texture with animated UVs
	vec4 col = texture(TEXTURE, uv);
	
	// -------------------------------------------------------------------------
	// 3. RIVER SUNSET SPECULAR SHIMMER & FLOW HIGHLIGHTS (UV.y >= 0.82)
	// -------------------------------------------------------------------------
	if (UV.y >= 0.82) {
		float river_depth = smoothstep(0.82, 0.96, UV.y);
		
		// Travelling specular light ripples where golden sunset reflects
		float shimmer_wave = sin(UV.x * 85.0 + t * (water_speed * 3.4) + UV.y * 30.0) * 
		                     cos(UV.x * 42.0 - t * (water_speed * 2.1) + UV.y * 60.0);
		float glint = smoothstep(0.68, 0.96, shimmer_wave) * river_depth;
		
		// Secondary high-frequency sparkle
		float sparkle = smoothstep(0.86, 0.98, sin(UV.x * 160.0 - t * 4.5) * sin(UV.y * 110.0 + t * 3.2)) * river_depth;
		
		// Warm golden-amber specular glints matching the sunset tone
		vec3 sunset_gold = vec3(1.0, 0.78, 0.35);
		vec3 sky_cyan = vec3(0.45, 0.85, 1.0);
		col.rgb += sunset_gold * (glint * 0.36) + sky_cyan * (sparkle * 0.28);
	}
	
	// -------------------------------------------------------------------------
	// 4. MOUNTAIN VALLEY ROLLING MIST / FOG (0.23 <= UV.y <= 0.40)
	// -------------------------------------------------------------------------
	if (UV.y >= 0.23 && UV.y <= 0.40) {
		float mist_mask = smoothstep(0.23, 0.30, UV.y) * smoothstep(0.40, 0.33, UV.y);
		
		// Dual-layer slow drifting valley fog
		float m1 = sin(UV.x * 10.0 + t * mist_speed + UV.y * 6.0) * 0.5 + 0.5;
		float m2 = cos(UV.x * 18.0 - t * (mist_speed * 0.65) + UV.y * 12.0) * 0.5 + 0.5;
		float mist_density = (m1 * 0.55 + m2 * 0.45) * mist_mask * 0.22;
		
		// Translucent atmospheric mist tinted purple-lavender matching the distant peaks
		vec3 mist_color = vec3(0.72, 0.62, 0.82);
		col.rgb = mix(col.rgb, mist_color, mist_density);
	}
	
	// -------------------------------------------------------------------------
	// 5. SUNSET ATMOSPHERIC GLOW BREATHING (UV.y < 0.30)
	// -------------------------------------------------------------------------
	if (UV.y < 0.30) {
		float sun_height = 1.0 - (UV.y / 0.30);
		float pulse = sin(t * sun_pulse_speed) * 0.05 + 0.05;
		vec3 sunset_warmth = vec3(1.0, 0.45, 0.12);
		col.rgb += sunset_warmth * (sun_height * pulse);
	}
	
	COLOR = col;
}
