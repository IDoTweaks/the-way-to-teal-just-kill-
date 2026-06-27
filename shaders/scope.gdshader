shader_type canvas_item;

uniform vec4 body_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 line_color : source_color = vec4(0.0, 0.85, 0.78, 0.9);
uniform float radius = 0.34;

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	float aspect = res.x / res.y;
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect;
	float d = length(uv);

	vec4 col = vec4(0.0);
	if (d > radius) {
		col = body_color;
	} else {
		if (abs(uv.x) < 0.0014 || abs(uv.y) < 0.0014) {
			col = line_color;
		}
		float dot_a = step(d, 0.006);
		col = mix(col, line_color, dot_a);
	}
	if (d < radius && d > radius - 0.014) {
		col = vec4(0.0, 0.0, 0.0, 1.0);
	}
	if (d < radius && d > radius - 0.02) {
		col = mix(col, line_color, 0.5);
	}
	COLOR = col;
}
