shader_type canvas_item;
render_mode blend_add;

// Driven from player.gd: 0.0 = no fire (rank D), 1.0 = roaring (rank SSS)
uniform float fill : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ember : source_color = vec4(0.0, 0.45, 0.42, 1.0);
uniform vec4 flame : source_color = vec4(0.0, 0.85, 0.70, 1.0);
uniform vec4 hot   : source_color = vec4(0.55, 1.0, 0.92, 1.0);

float hash(vec2 p){
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p){
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p){
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++){
		v += a * vnoise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment(){
	vec2 uv = UV;
	float t = TIME * 2.0;

	// noise scrolls upward so the flames lick toward the top
	vec2 q = vec2(uv.x * 3.5, uv.y * 3.0 + t);
	float n = fbm(q + vec2(0.0, fbm(q)));

	float base = 1.0 - uv.y;            // 0 at the bottom, 1 at the top
	float reach = fill * 1.15;          // how high the flames climb
	float edge = reach - base + (n - 0.5) * 0.55;
	float intensity = smoothstep(0.0, 0.22, edge);

	// taper the sides so it reads as a tongue of fire, not a block
	float sides = smoothstep(0.0, 0.18, uv.x) * smoothstep(1.0, 0.82, uv.x);
	intensity *= sides;

	// colour shifts from ember (bottom) to white-hot teal (top)
	vec3 col = mix(ember.rgb, flame.rgb, smoothstep(0.0, 0.55, base));
	col = mix(col, hot.rgb, smoothstep(0.5, 1.0, base + n * 0.2));
	col *= 1.3 + intensity * 1.2;

	COLOR = vec4(col, intensity * (0.55 + 0.45 * fill));
}
