shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled;

// full-screen pass: ink outlines from depth+normal edges, plus colour posterisation.
// cartoons the whole world (CSG, models, props) without editing every material.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;

uniform vec4 ink : source_color = vec4(0.03, 0.13, 0.15, 1.0);
uniform float outline_thickness : hint_range(0.5, 4.0) = 1.4;
uniform float depth_sensitivity : hint_range(0.0, 60.0) = 18.0;
uniform float normal_sensitivity : hint_range(0.0, 4.0) = 1.1;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.9;
uniform int color_steps : hint_range(2, 24) = 10;
uniform float posterize : hint_range(0.0, 1.0) = 0.5;
uniform float saturate_amount : hint_range(0.5, 2.0) = 1.18;
uniform float far_fade : hint_range(5.0, 400.0) = 140.0;

float linear_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
	vec4 view = inv_proj * vec4(ndc, 1.0);
	return -(view.xyz / view.w).z;
}

void vertex() {
	// stretch the quad across the whole screen regardless of its transform
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = outline_thickness / VIEWPORT_SIZE;

	float dc = linear_depth(uv, INV_PROJECTION_MATRIX);
	float d1 = linear_depth(uv + vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float d2 = linear_depth(uv - vec2(px.x, 0.0), INV_PROJECTION_MATRIX);
	float d3 = linear_depth(uv + vec2(0.0, px.y), INV_PROJECTION_MATRIX);
	float d4 = linear_depth(uv - vec2(0.0, px.y), INV_PROJECTION_MATRIX);

	// scale the depth threshold with distance so far geometry doesn't turn to soup
	float depth_edge = (abs(d1 - dc) + abs(d2 - dc) + abs(d3 - dc) + abs(d4 - dc));
	depth_edge = depth_edge / max(dc, 0.5);
	depth_edge = smoothstep(0.012, 0.012 + 1.0 / max(depth_sensitivity, 0.001), depth_edge);

	vec3 nc = texture(normal_tex, uv).xyz * 2.0 - 1.0;
	vec3 n1 = texture(normal_tex, uv + vec2(px.x, 0.0)).xyz * 2.0 - 1.0;
	vec3 n2 = texture(normal_tex, uv - vec2(px.x, 0.0)).xyz * 2.0 - 1.0;
	vec3 n3 = texture(normal_tex, uv + vec2(0.0, px.y)).xyz * 2.0 - 1.0;
	vec3 n4 = texture(normal_tex, uv - vec2(0.0, px.y)).xyz * 2.0 - 1.0;
	float normal_edge = (1.0 - dot(nc, n1)) + (1.0 - dot(nc, n2)) + (1.0 - dot(nc, n3)) + (1.0 - dot(nc, n4));
	normal_edge = smoothstep(0.25, 0.25 + (2.0 - normal_sensitivity), normal_edge);

	float edge = clamp(max(depth_edge, normal_edge), 0.0, 1.0);
	// fade outlines out with distance and skip the skybox entirely
	edge *= 1.0 - smoothstep(far_fade * 0.55, far_fade, dc);
	if (dc > far_fade * 1.5) {
		edge = 0.0;
	}
	edge *= outline_strength;

	vec3 col = texture(screen_tex, uv).rgb;

	// punchier, flatter colour
	float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(lum), col, saturate_amount);
	vec3 steps = floor(col * float(color_steps) + 0.5) / float(color_steps);
	col = mix(col, steps, posterize);

	ALBEDO = mix(col, ink.rgb, edge);
	ALPHA = 1.0;
}
