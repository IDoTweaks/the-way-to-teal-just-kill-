shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// keeps the original health-fill behaviour, but cel-shaded
uniform vec4 base_color : source_color = vec4(0.15, 0.95, 0.35, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 0.82, 0.25, 1.0);
uniform float fill_percent : hint_range(0.0, 1.0) = 0.5;
uniform float min_y = -0.5;
uniform float max_y = 0.5;

uniform int bands : hint_range(2, 5) = 3;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 shade_tint : source_color = vec4(0.06, 0.3, 0.38, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.5;
uniform float rim_width : hint_range(0.5, 8.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(0.7, 1.0, 0.95, 1.0);

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	float height = max(max_y - min_y, 0.0001);
	float normalized_y = (local_y - min_y) / height;
	float stretched_fill = (fill_percent * 1.2) - 0.1;
	// hard edge instead of a soft gradient - reads as painted-on, not blended
	float mask = step(normalized_y, stretched_fill);
	ALBEDO = mix(base_color.rgb, fill_color.rgb, mask);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(normalize(NORMAL), normalize(LIGHT));
	float lit = clamp(ndl, 0.0, 1.0);
	float stepped = floor(lit * float(bands) + 0.5) / float(bands);
	stepped = mix(1.0, stepped, shade_strength);
	vec3 shaded = mix(shade_tint.rgb * ALBEDO, ALBEDO, stepped);
	DIFFUSE_LIGHT += shaded * LIGHT_COLOR * ATTENUATION / 3.14159;

	float rim = 1.0 - clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);
	rim = pow(rim, rim_width);
	rim = smoothstep(0.35, 0.65, rim) * rim_amount;
	DIFFUSE_LIGHT += rim_color.rgb * rim * ATTENUATION;
}
