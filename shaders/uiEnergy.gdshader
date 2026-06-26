shader_type canvas_item;

// Animated, self-driving background. No code needed - pure TIME.
uniform vec4 deep : source_color = vec4(0.02, 0.05, 0.12, 1.0);
uniform vec4 glow_blue : source_color = vec4(0.04, 0.25, 0.6, 1.0);
uniform vec4 glow_green : source_color = vec4(0.0, 0.45, 0.3, 1.0);

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
	float t = TIME * 0.08;

	// slow drifting energy clouds
	float n1 = fbm(uv * 3.0 + vec2(t, t * 0.5));
	float n2 = fbm(uv * 5.0 - vec2(t * 0.7, t));

	vec3 col = deep.rgb;
	col = mix(col, glow_blue.rgb, smoothstep(0.4, 0.9, n1));
	col = mix(col, glow_green.rgb, smoothstep(0.5, 1.0, n2) * 0.6);

	// vignette toward the edges
	float vig = smoothstep(1.1, 0.2, length(uv - 0.5));
	col *= 0.55 + 0.45 * vig;

	// faint moving scanline band for a "tech" feel
	float band = sin(uv.y * 9.0 - TIME * 1.2) * 0.5 + 0.5;
	col += glow_blue.rgb * band * 0.05;

	COLOR = vec4(col, 1.0);
}
