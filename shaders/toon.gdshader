shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.2, 0.85, 0.4, 1.0);
uniform int bands : hint_range(2, 5) = 3;
uniform float shade_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 shade_tint : source_color = vec4(0.05, 0.35, 0.45, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.45;
uniform float rim_width : hint_range(0.5, 8.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(0.65, 1.0, 0.95, 1.0);

varying vec3 world_normal;
varying vec3 world_pos;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = base_color.rgb;
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
