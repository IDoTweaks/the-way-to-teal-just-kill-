shader_type canvas_item;

uniform float health : hint_range(0.0, 1.0) = 1.0;
uniform vec4 full_col : source_color = vec4(0.15, 0.5, 1.0, 1.0);
uniform vec4 hurt_col : source_color = vec4(0.0, 1.0, 0.45, 1.0);
uniform vec4 back_col : source_color = vec4(0.02, 0.05, 0.12, 0.85);
uniform float skew = 0.14;
uniform float segments : hint_range(4.0, 24.0) = 10.0;
uniform vec4 ink : source_color = vec4(0.03, 0.13, 0.15, 1.0);
uniform float gap = 0.16;

void fragment(){
	vec2 uv = UV;

	float sx = uv.x - (uv.y - 0.5) * skew;
	if (sx < 0.0 || sx > 1.0){
		COLOR = vec4(0.0);
	} else {
		float filled = step(sx, health);

		vec3 energy = mix(hurt_col.rgb, full_col.rgb, health);

		float scan = sin((sx * 42.0) - TIME * 6.0) * 0.5 + 0.5;
		scan = 0.72 + 0.28 * scan;

		float danger = 1.0 - smoothstep(0.0, 0.35, health);
		float pulse = mix(1.0, 0.55 + 0.65 * (sin(TIME * 9.0) * 0.5 + 0.5), danger);

		float edge = smoothstep(health - 0.025, health, sx) * step(sx, health);

		vec3 col = energy * scan * pulse;
		col += vec3(0.8, 1.0, 1.0) * edge;
		float seg = fract(sx * segments);
		float notch = step(seg, gap);
		col = mix(col, ink.rgb, notch * 0.85);

		vec3 outc = mix(back_col.rgb, col, filled);
		float a = mix(back_col.a, 1.0, filled);
		COLOR = vec4(outc, a);
	}
}
