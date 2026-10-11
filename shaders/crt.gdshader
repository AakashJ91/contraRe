shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_count : hint_range(100.0, 1000.0) = 360.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.35;
uniform float warp_amount : hint_range(0.0, 0.1) = 0.02;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;

vec2 warp(vec2 uv) {
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta, delta);
	float delta4 = delta2 * delta2;
	return uv + delta * (delta4 * warp_amount);
}

void fragment() {
	vec2 uv = warp(SCREEN_UV);
	
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Chromatic aberration
		float r = texture(screen_texture, uv + vec2(chromatic_aberration, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(chromatic_aberration, 0.0)).b;
		vec3 color = vec3(r, g, b);
		
		// Scanlines
		float scanline = sin(uv.y * scanline_count * 3.14159265);
		color -= scanline * scanline_intensity * color;
		
		// Vignette
		vec2 vig_uv = (uv - 0.5) * 2.0;
		float vig = 1.0 - dot(vig_uv, vig_uv) * vignette_intensity;
		color *= clamp(vig, 0.0, 1.0);
		
		COLOR = vec4(color, 1.0);
	}
}
