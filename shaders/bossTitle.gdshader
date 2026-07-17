shader_type canvas_item;

uniform float reveal : hint_range(-0.2, 1.4) = 0.0;
uniform float skew : hint_range(-0.5, 0.5) = 0.13;
uniform vec4 edgeCol : source_color = vec4(0.0, 1.0, 0.85, 1.0);
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

float rnd(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

void fragment() {
	float sk = (UV.y - 0.5) * skew;
	float x = UV.x + sk;
	float y = UV.y;

	float g = step(0.86, rnd(floor(y * 48.0) * 3.7 + floor(TIME * 26.0)));
	x += g * glitch * 0.06;

	float d = abs(y - 0.5) * 2.0;
	float core = smoothstep(1.0, 0.58, d);
	float ends = smoothstep(0.0, 0.16, x) * smoothstep(1.02, 0.84, x);
	float w = smoothstep(reveal + 0.02, reveal - 0.06, x);
	float lead = smoothstep(reveal - 0.10, reveal - 0.01, x) * w;
	float rule = smoothstep(0.60, 0.68, d) * smoothstep(0.84, 0.74, d);
	float scan = 0.88 + 0.12 * sin(y * 420.0 + TIME * 5.0);

	vec3 col = vec3(0.015, 0.03, 0.028) * scan;
	float a = core * 0.94;

	col = mix(col, edgeCol.rgb, rule * 0.95);
	a = max(a, rule * 0.95);

	col = mix(col, mix(edgeCol.rgb, vec3(1.0), 0.6), lead * 0.9);
	a = max(a, lead * 0.85);

	COLOR = vec4(col, a * ends * w * fade);
}
