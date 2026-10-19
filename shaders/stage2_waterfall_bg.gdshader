shader_type canvas_item;

// Stage 2 Waterfall Living Background Shader
// Animates distant mountain valley fog drift, alpine canopy wind sway, and atmospheric mountain glow

uniform float mist_speed : hint_range(0.0, 2.0) = 0.28;
uniform float sway_speed : hint_range(0.0, 3.0) = 1.4;
uniform float atmospheric_pulse : hint_range(0.0, 2.0) = 0.70;

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	
	// 1. ALPINE FOREST CANOPY SWAY (0.35 <= UV.y < 0.78)
	if (uv.y >= 0.35 && uv.y < 0.78) {
		float sway_weight = smoothstep(0.78, 0.45, uv.y) * smoothstep(0.32, 0.40, uv.y);
		float sway_x = (sin(t * sway_speed + uv.x * 11.0) * 0.0022 + 
		                cos(t * (sway_speed * 1.4) + uv.x * 19.0) * 0.0011) * sway_weight;
		uv.x += sway_x;
	}
	
	vec4 col = texture(TEXTURE, uv);
	
	// 2. DISTANT VALLEY ROLLING MIST / FOG (0.30 <= UV.y <= 0.62)
	if (UV.y >= 0.30 && UV.y <= 0.62) {
		float mist_mask = smoothstep(0.30, 0.42, UV.y) * smoothstep(0.62, 0.50, UV.y);
		float m1 = sin(UV.x * 8.0 + t * mist_speed + UV.y * 5.0) * 0.5 + 0.5;
		float m2 = cos(UV.x * 14.0 - t * (mist_speed * 0.7) + UV.y * 9.0) * 0.5 + 0.5;
		float mist_density = (m1 * 0.55 + m2 * 0.45) * mist_mask * 0.18;
		
		vec3 valley_mist = vec3(0.72, 0.82, 0.94);
		col.rgb = mix(col.rgb, valley_mist, mist_density);
	}
	
	// 3. MOUNTAIN SKY ATMOSPHERIC DIFFUSION (UV.y < 0.28)
	if (UV.y < 0.28) {
		float sky_h = 1.0 - (UV.y / 0.28);
		float pulse = sin(t * atmospheric_pulse) * 0.04 + 0.04;
		vec3 alpine_glow = vec3(0.55, 0.75, 1.0);
		col.rgb += alpine_glow * (sky_h * pulse);
	}
	
	COLOR = col;
}
