shader_type canvas_item;

// Photorealistic Volumetric Ascending Canyon Fog Shader
// Uses domain-warped multi-octave Fractal Brownian Motion (fBm),
// fluid-like upward vapor advection, natural alpine wind turbulence,
// and 4-way hermite edge feathering for completely seamless chasm integration.

uniform vec4 fog_color_deep : source_color = vec4(0.60, 0.74, 0.90, 1.0);
uniform vec4 fog_color_crest : source_color = vec4(0.94, 0.97, 1.0, 1.0);
uniform float speed : hint_range(0.0, 2.0) = 0.36;
uniform float turbulence : hint_range(0.0, 2.0) = 0.35;
uniform float density : hint_range(0.0, 2.0) = 0.95;

// Pseudo-random 2D hash
vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Gradient Noise with quintic smooth hermite interpolation
float grad_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	
	return mix(mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
	               dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
	           mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
	               dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

// 3-octave Fractal Brownian Motion
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.50;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 3; i++) {
		v += a * grad_noise(p);
		p = rot * p * 2.06;
		a *= 0.50;
	}
	return v * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	
	// Natural thermal wind sway with harmonic altitude shifts
	float sway_amp = (1.1 - uv.y * 0.4) * turbulence;
	float sway = (sin(uv.y * 3.8 + t * 2.2) * 0.12 + cos(uv.y * 7.2 - t * 1.5) * 0.06) * sway_amp;
	
	// Coordinate domain: upward advection in world space (downward in UV)
	vec2 coord1 = vec2((uv.x + sway) * 2.4, uv.y * 1.6 - t * 1.05);
	vec2 coord2 = vec2((uv.x - sway * 0.6) * 3.4 + 4.1, uv.y * 2.2 - t * 1.45 + 2.7);
	
	// Domain Warping: realistic turbulent fluid curling
	vec2 warp = vec2(
		fbm(coord1 + vec2(0.0, t * 0.25)),
		fbm(coord1 + vec2(3.7, -t * 0.20))
	) * 0.38;
	
	float n1 = fbm(coord1 + warp);
	float n2 = fbm(coord2 - warp * 0.5);
	float smoke = mix(n1, n2, 0.48);
	
	// 4-Way Hermite Edge Feathering:
	// Eliminates any seams or cutoffs on top, bottom, left, and right
	float v_top = smoothstep(0.01, 0.28, uv.y);
	float v_bot = smoothstep(1.0, 0.82, uv.y);
	float v_envelope = v_top * v_bot;
	
	float h_mask = smoothstep(0.0, 0.22, uv.x) * smoothstep(1.0, 0.78, uv.x);
	h_mask = pow(h_mask, 0.85);
	
	// Density distribution: billows rise and diffuse naturally
	float alpha_raw = (smoke * 1.65 - 0.20) * v_envelope * h_mask * density;
	float alpha = clamp(alpha_raw, 0.0, 1.0);
	
	// Atmospheric light scattering:
	// Sunlit misty crests catch warm diffuse light, while deep cavern recesses remain cool
	float crest_scatter = smoothstep(0.40, 0.85, smoke + (1.0 - uv.y) * 0.15);
	vec3 col = mix(fog_color_deep.rgb, fog_color_crest.rgb, crest_scatter);
	
	COLOR = vec4(col, alpha * 0.85);
}
