shader_type canvas_item;

// Animated holographic gradient for text. It swings each label's OWN colour
// through nearby hues and brightness, then rakes a bright sheen across it, so
// every label keeps its identity (green timer, blue score, gold S grade...)
// but stops being a flat dead fill. Dark outlines are left alone.
uniform float flow_speed = 1.0;
uniform float hue_range = 0.14;
uniform float gradient_scale = 1.2;
uniform float sheen = 0.5;

vec3 rgb2hsv(vec3 c){
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c){
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment(){
	vec4 tex = texture(TEXTURE, UV);
	vec3 base = COLOR.rgb;

	// fills are bright, outlines are dark - only mess with the bright bits
	float lum = dot(base, vec3(0.299, 0.587, 0.114));
	float fillMask = smoothstep(0.12, 0.45, lum);

	float t = TIME * flow_speed;
	float phase = sin((SCREEN_UV.x + SCREEN_UV.y) * gradient_scale * 6.2831 + t) * 0.5 + 0.5;

	vec3 hsv = rgb2hsv(base);
	hsv.x = fract(hsv.x + (phase - 0.5) * hue_range);
	hsv.z = clamp(hsv.z * (0.82 + 0.45 * phase), 0.0, 1.0);
	vec3 shifted = hsv2rgb(hsv);

	vec3 col = mix(base, shifted, fillMask);

	// thin specular band raking diagonally across the glyphs
	float band = 1.0 - smoothstep(0.0, 0.05, abs(fract((SCREEN_UV.x - SCREEN_UV.y) - t * 0.12) - 0.5));
	col += band * fillMask * sheen;

	COLOR = vec4(col, tex.a * COLOR.a);
}
