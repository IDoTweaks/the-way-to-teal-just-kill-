shader_type spatial;
render_mode blend_mix, cull_back, shadows_disabled, depth_draw_opaque, unshaded, fog_disabled;

uniform vec4 body_color : source_color = vec4(0.35, 0.64, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.82, 0.96, 1.0, 1.0);
uniform float ghost_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float rim_power : hint_range(0.5, 6.0) = 2.2;
uniform int cel_bands : hint_range(2, 8) = 4;

uniform float tail_top = -0.05;
uniform float tail_cut = -0.62;
uniform float wave_amp = 0.16;
uniform float wave_freq = 9.0;
uniform float wave_speed = 3.4;
uniform float sway_amp = 0.05;
uniform float sway_speed = 1.7;

varying vec3 vLocal;

void vertex() {
	vLocal = VERTEX;
	float t = clamp((tail_top - VERTEX.y) / max(tail_top - tail_cut, 0.001), 0.0, 1.0);
	VERTEX.x += sin(TIME * sway_speed + VERTEX.y * 2.0) * sway_amp * t;
}

void fragment() {
	float wave = sin(vLocal.x * wave_freq + TIME * wave_speed) * 0.5
	           + sin(vLocal.z * wave_freq * 0.8 - TIME * wave_speed * 1.3) * 0.5;
	float cut = tail_cut + wave * wave_amp;
	if (vLocal.y < cut) {
		discard;
	}

	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	fres = floor(fres * float(cel_bands)) / float(cel_bands - 1);
	fres = clamp(fres, 0.0, 1.0);

	vec3 col = mix(body_color.rgb, rim_color.rgb, fres);
	ALBEDO = col * (1.0 + fres * 0.85);

	float tailFade = smoothstep(cut, cut + 0.42, vLocal.y);
	ALPHA = ghost_alpha * mix(0.55, 1.0, tailFade) + fres * 0.25;
}
