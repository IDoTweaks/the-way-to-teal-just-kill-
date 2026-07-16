shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, unshaded;
uniform vec4 core_color : source_color = vec4(0.0, 0.15, 0.65, 1.0);    // saturated blue core
uniform vec4 mid_color  : source_color = vec4(0.0, 0.40, 1.0, 1.0);     // pure bright blue body
uniform vec4 rim_color  : source_color = vec4(0.4, 0.85, 1.0, 1.0);     // bright cyan rim
uniform vec4 wisp_color : source_color = vec4(0.2, 0.95, 1.0, 1.0);     // electric cyan
uniform vec4 arrow_color : source_color = vec4(0.7, 1.0, 1.0, 1.0);     // near-white cyan arrows
uniform float swirl_speed : hint_range(0.0, 3.0) = 0.6;
uniform float rise_speed : hint_range(0.0, 6.0) = 3.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.2;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.4;
uniform float band_count : hint_range(2.0, 12.0) = 6.0;
uniform float chevron_count : hint_range(2.0, 16.0) = 8.0;
uniform float chevron_strength : hint_range(0.0, 1.0) = 1.0;
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
uniform float distort_strength : hint_range(0.0, 0.5) = 0.08;
varying vec3 world_normal;
varying vec3 local_pos;
float hash(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}
float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}
void vertex() {
	local_pos = VERTEX;
	world_normal = NORMAL;
	float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_strength * 0.08;
	VERTEX *= pulse;
}
void fragment() {
	vec3 n = normalize(world_normal);
	if(!FRONT_FACING){
		n = -n;
	}
	vec3 v = normalize(VIEW);
	float t = TIME * swirl_speed;
	float rise = TIME * rise_speed;
	vec3 swirl_pos = local_pos * noise_scale;
	swirl_pos.xz += vec2(cos(t * 0.7), sin(t * 0.5)) * 1.5;
	swirl_pos.y  -= rise;
	float n1 = noise(swirl_pos);
	float n2 = noise(swirl_pos * 1.8 + vec3(t * 0.3, -rise, t * 0.6));
	float combined_noise = mix(n1, n2, 0.5);
	float bands = sin((local_pos.y * band_count) - rise + combined_noise * distort_strength * 8.0);
	bands = bands * 0.5 + 0.5;
	// --- upward chevrons wrapped around the whole sphere (spherical mapping) ---
	vec3 dir = normalize(local_pos);
	float lon = atan(dir.z, dir.x);                          // azimuth around Y, wraps seamlessly
	float lat = asin(clamp(dir.y, -1.0, 1.0)) / 1.5707963;   // -1 (bottom) .. 1 (top)

	float arrows_around = max(floor(chevron_count * 0.5), 2.0);     // how many V's around the equator
	float zig = abs(fract(lon / TAU * arrows_around) - 0.5) * 2.0;  // 0 at each arrow center, 1 between
	float chev_phase = (lat * chevron_count) - zig * 2.0 - rise * 1.5;
	float chev_wave = sin(chev_phase);
	float chev = smoothstep(0.5, 0.8, chev_wave * 0.5 + 0.5) * chevron_strength;
	float core_mix = smoothstep(0.2, 0.55, bands) * smoothstep(0.0, 0.4, combined_noise + 0.3);
	vec4 base = mix(core_color, mid_color, core_mix);
	float wisp_mask = smoothstep(0.55, 0.95, combined_noise) * smoothstep(0.3, 0.7, bands);
	base = mix(base, wisp_color, wisp_mask * 0.7);
	// arrows painted hard on top in near-white cyan
	base = mix(base, arrow_color, chev);
	float fresnel = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), rim_power);
	vec4 col = mix(base, rim_color, fresnel);
	float flicker = 0.92 + 0.08 * sin(TIME * pulse_speed * 2.3 + combined_noise * 6.0);
	col.rgb *= flicker;
	ALBEDO = col.rgb;
	EMISSION = col.rgb * (0.9 + fresnel * 1.5 + wisp_mask * 0.8 + chev * 2.5);
	ALPHA = clamp(0.95 + fresnel * 0.05, 0.0, 1.0);
}
