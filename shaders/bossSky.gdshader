shader_type sky;

uniform vec3 zenith : source_color = vec3(0.043, 0.180, 0.239);
uniform vec3 midSky : source_color = vec3(0.075, 0.360, 0.400);
uniform vec3 horizonCol : source_color = vec3(0.180, 0.640, 0.580);
uniform vec3 glowCol : source_color = vec3(0.349, 1.0, 0.859);
uniform vec3 venom : source_color = vec3(0.42, 0.24, 0.62);
uniform vec3 cloudDark : source_color = vec3(0.075, 0.290, 0.320);
uniform vec3 cloudLight : source_color = vec3(0.310, 0.780, 0.720);
uniform vec3 ink : source_color = vec3(0.024, 0.086, 0.098);
uniform vec3 moonCol : source_color = vec3(0.85, 1.0, 0.96);

uniform int bands : hint_range(3, 16) = 7;
uniform float horizonGlow : hint_range(0.0, 1.0) = 0.55;
uniform float cloudScale = 1.5;
uniform float cloudSpeed = 0.012;
uniform float cloudCover : hint_range(0.0, 1.0) = 0.52;
uniform float venomAmount : hint_range(0.0, 1.0) = 0.35;
uniform vec3 moonDir = vec3(-0.40, 0.20, -0.89);
uniform float moonSize : hint_range(0.0, 0.3) = 0.105;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

float quant(float v, int n) {
	return floor(v * float(n)) / float(n - 1);
}

void sky() {
	float hy = EYEDIR.y;
	// most of the time you are looking near the horizon, so put the whole
	// gradient in the first ~30 degrees instead of spreading it up the dome
	float t = clamp(hy * 2.0, 0.0, 1.0);

	float q = clamp(quant(t, bands), 0.0, 1.0);
	vec3 col = mix(horizonCol, midSky, clamp(q * 1.5, 0.0, 1.0));
	col = mix(col, zenith, clamp((q - 0.5) * 2.0, 0.0, 1.0));

	// stepped glow hugging the horizon line
	float hg = 1.0 - smoothstep(0.0, 0.14, abs(hy));
	hg = quant(hg, 3);
	col = mix(col, glowCol, clamp(hg, 0.0, 1.0) * horizonGlow * 0.40);

	// darken below the horizon so the arena reads against it
	col = mix(col, ink, clamp(-hy * 2.0, 0.0, 1.0) * 0.55);

	// a bruise of snake venom low in the sky
	float vz = clamp((0.30 - abs(hy)) / 0.30, 0.0, 1.0) * clamp(-EYEDIR.z * 0.5 + 0.5, 0.0, 1.0);
	col = mix(col, venom, quant(vz, 4) * venomAmount);

	// flat two-tone clouds on a sky plane
	if (hy > 0.02) {
		vec2 cuv = EYEDIR.xz / max(hy, 0.02);
		cuv = cuv * cloudScale + vec2(TIME * cloudSpeed, TIME * cloudSpeed * 0.35);
		float n = fbm(cuv);
		float fade = smoothstep(0.02, 0.16, hy) * (1.0 - smoothstep(0.80, 1.0, hy));
		float body = step(cloudCover, n);
		float core = step(cloudCover + 0.10, n);
		float edge = body - step(cloudCover + 0.035, n);
		vec3 cc = mix(cloudDark, cloudLight, core);
		cc = mix(cc, ink, edge * 0.55);
		col = mix(col, cc, body * fade * 0.9);
	}

	// big flat moon with a hard rim
	vec3 md = normalize(moonDir);
	float d = distance(EYEDIR, md);
	float disc = 1.0 - step(moonSize, d);
	float rim = step(moonSize, d) - step(moonSize * 1.16, d);
	col = mix(col, moonCol, disc);
	col = mix(col, ink, rim * 0.7);
	float halo = 1.0 - smoothstep(moonSize, moonSize * 3.4, d);
	col += glowCol * quant(halo, 3) * 0.18;

	COLOR = col;
}
