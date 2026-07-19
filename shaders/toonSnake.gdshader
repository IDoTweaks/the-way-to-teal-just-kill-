shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 body_color : source_color = vec4(0.13, 0.72, 0.28, 1.0);
uniform vec4 belly_color : source_color = vec4(0.55, 0.92, 0.45, 1.0);
uniform float belly_amount : hint_range(0.0, 1.0) = 0.45;

uniform float glow : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.85, 1.0);
uniform float glow_pulse_speed = 6.0;

uniform int bands : hint_range(2, 5) = 3;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 shade_tint : source_color = vec4(0.06, 0.3, 0.38, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.5;
uniform float rim_width : hint_range(0.5, 8.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(0.7, 1.0, 0.95, 1.0);

varying vec3 vNormal;

void vertex() {
	vNormal = NORMAL;
}

void fragment() {
	float belly = step(0.55, -vNormal.y) * belly_amount;
	vec3 col = mix(body_color.rgb, belly_color.rgb, belly);

	float pulse = 0.75 + 0.25 * sin(TIME * glow_pulse_speed);
	col = mix(col, glow_color.rgb, glow * pulse);

	ALBEDO = col;
	EMISSION = glow_color.rgb * glow * pulse * 1.6;
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
