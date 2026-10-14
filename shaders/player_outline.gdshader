shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.92);
uniform float outline_width : hint_range(0.0, 5.0) = 1.35;
uniform float shimmer_speed : hint_range(0.0, 10.0) = 3.2;
uniform float shimmer_intensity : hint_range(0.0, 1.0) = 0.38;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a > 0.08) {
		COLOR = col * COLOR;
	} else {
		vec2 step_uv = fwidth(UV) * outline_width;
		if (step_uv.x <= 0.0 || step_uv.y <= 0.0) {
			step_uv = TEXTURE_PIXEL_SIZE * (outline_width * 6.0);
		}
		
		// Inner ring (core contour)
		float a_inner = 0.0;
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(0.0, -step_uv.y)).a);
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a);
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(-step_uv.x, 0.0)).a);
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a);
		
		vec2 diag = step_uv * 0.7071;
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(-diag.x, -diag.y)).a);
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(diag.x, -diag.y)).a);
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(-diag.x, diag.y)).a);
		a_inner = max(a_inner, texture(TEXTURE, UV + vec2(diag.x, diag.y)).a);
		
		// Outer ring for soft feathered glow & bloom
		vec2 step_outer = step_uv * 1.5;
		vec2 diag_outer = diag * 1.5;
		float a_outer = 0.0;
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(0.0, -step_outer.y)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(0.0, step_outer.y)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(-step_outer.x, 0.0)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(step_outer.x, 0.0)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(-diag_outer.x, -diag_outer.y)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(diag_outer.x, -diag_outer.y)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(-diag_outer.x, diag_outer.y)).a);
		a_outer = max(a_outer, texture(TEXTURE, UV + vec2(diag_outer.x, diag_outer.y)).a);
		
		float combined_a = max(a_inner, a_outer * 0.55);
		
		if (combined_a > 0.08) {
			// Diagonal travelling shimmer wave across silhouette
			float wave = sin((UV.x * 2.2 + UV.y * 3.0) * 4.0 - TIME * shimmer_speed);
			float glint = smoothstep(0.25, 0.95, wave) * shimmer_intensity;
			
			// Gentle breathing pulse
			float pulse = 0.82 + 0.18 * sin(TIME * (shimmer_speed * 0.75));
			
			// Silvery white shimmer tone
			vec3 final_rgb = outline_color.rgb * (1.0 + glint * 0.45);
			
			// Smooth feathered edge transition
			float edge_soft = smoothstep(0.08, 0.65, combined_a);
			float final_a = outline_color.a * edge_soft * (pulse + glint * 0.35);
			
			COLOR = vec4(final_rgb, clamp(final_a, 0.0, 1.0));
		} else {
			COLOR = vec4(0.0);
		}
	}
}
