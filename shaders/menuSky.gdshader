shader_type canvas_item;
render_mode blend_mix;

uniform vec3 skyTop : source_color = vec3(0.012, 0.055, 0.070);
uniform vec3 skyLow : source_color = vec3(0.035, 0.165, 0.165);
uniform vec3 ink : source_color = vec3(0.024, 0.086, 0.098);
uniform vec3 teal : source_color = vec3(0.0, 0.851, 0.780);
uniform vec3 mint : source_color = vec3(0.349, 1.0, 0.859);
uniform vec3 worldGreen : source_color = vec3(0.180, 0.560, 0.330);
uniform vec3 cream : source_color = vec3(1.0, 0.988, 0.941);
uniform vec3 playerBlue : source_color = vec3(0.239, 0.545, 1.0);
uniform vec3 fire : source_color = vec3(1.0, 0.55, 0.18);

uniform float speed = 1.0;
uniform float paperAmount = 1.0;
uniform float grainAmount = 0.045;
uniform float towerX = 0.665;
uniform float horizon = 0.965;
uniform float actionLoop = 3.2;
uniform float frozenTime = -1.0;

float h11(float n) {
	return fract(sin(n * 12.9898) * 43758.5453123);
}

float h21(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453123);
}

float box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 rot(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * t);
}

vec4 skyline(vec2 p, float colW, float seed, float baseY, float varH, vec3 body, float winChance, float winGlow, float t) {
	float col = floor(p.x / colW);
	float top = baseY - (h11(col * 1.7 + seed) * 0.55 + h11(col * 4.3 + seed * 1.9) * 0.45) * varH;
	if (p.y < top) {
		return vec4(0.0);
	}
	vec3 c = body;
	vec2 g = vec2(p.x / (colW * 0.24), (p.y - top) / 0.026);
	vec2 gi = floor(g);
	vec2 gf = fract(g);
	float lit = step(1.0 - winChance, h21(gi + vec2(seed, seed * 2.1)));
	float flick = 0.72 + 0.28 * sin(t * 1.6 + h21(gi) * 40.0);
	float inWin = step(0.2, gf.x) * step(gf.x, 0.8) * step(0.25, gf.y) * step(gf.y, 0.75);
	float band = step(0.03, p.y - top);
	c += lit * inWin * band * winGlow * flick * mint;
	float rim = 1.0 - smoothstep(0.0, 0.006, p.y - top);
	c = mix(c, teal * 0.5, rim * 0.5);
	return vec4(c, 1.0);
}

float papers(vec2 p, float t, float scale, float sp, float seed) {
	vec2 q = p * scale;
	q.y += t * sp;
	q.x += sin(q.y * 0.5 + seed) * 0.4;
	vec2 gi = floor(q);
	vec2 gf = fract(q);
	float r = h21(gi + seed);
	if (r < 0.930) {
		return 0.0;
	}
	vec2 c = gf - vec2(h21(gi + 1.3), h21(gi + 2.7)) * 0.5 - 0.25;
	float a = r * 26.0 + sin(t * 0.9 + r * 40.0) * 0.45;
	vec2 rc = vec2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a));
	float d = max(abs(rc.x) / 0.055, abs(rc.y) / 0.072);
	return 1.0 - smoothstep(0.6, 1.0, d);
}

float towerHalf(float y) {
	float w = 0.078;
	w -= (1.0 - step(0.475, y)) * 0.013;
	w -= (1.0 - step(0.375, y)) * 0.016;
	w += (1.0 - step(y, 0.905)) * 0.020;
	return w;
}

// one blue-man silhouette, tilted into the dash
uniform float manScale = 1.85;

float manShape(vec2 uv, vec2 at, float tilt, float aspect) {
	vec2 mp = rot((uv - at) * vec2(aspect, 1.0), tilt) / manScale;
	float body = box(mp, vec2(0.0085, 0.022)) - 0.004;
	float head = length(mp - vec2(0.0, -0.032)) - 0.0125;
	return min(body, head) * manScale;
}

void fragment() {
	vec2 uv = UV;
	vec2 px = 1.0 / SCREEN_PIXEL_SIZE;
	float aspect = max(px.x / max(px.y, 1.0), 0.5);
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = (frozenTime >= 0.0 ? frozenTime : TIME) * speed;

	// action loop: 0 -> 1 each pass
	float loopT = fract(t / actionLoop);

	vec3 col = mix(skyTop, skyLow, pow(clamp(uv.y / horizon, 0.0, 1.0), 1.6));

	float glow = 1.0 - smoothstep(0.0, 0.55, length((uv - vec2(towerX, 0.62)) * vec2(aspect * 0.55, 1.0)));
	col += teal * glow * 0.085;

	vec4 l1 = skyline(p + vec2(sin(t * 0.02) * 0.01, 0.0), 0.085, 3.7, horizon - 0.045, 0.16, mix(skyLow, ink, 0.45), 0.10, 0.30, t);
	col = mix(col, l1.rgb, l1.a * 0.75);

	vec4 l2 = skyline(p + vec2(11.3, 0.0), 0.135, 9.1, horizon - 0.015, 0.30, mix(ink, worldGreen * 0.35, 0.35), 0.16, 0.55, t);
	col = mix(col, l2.rgb, l2.a * 0.9);

	float tx = uv.x - towerX;
	float towerTop = 0.300;
	float hw = towerHalf(uv.y);
	float inTower = step(abs(tx), hw) * step(towerTop, uv.y);

	float spire = step(abs(tx), 0.0045) * step(0.168, uv.y) * step(uv.y, towerTop);
	float mast = step(abs(tx), 0.019) * step(0.255, uv.y) * step(uv.y, towerTop);

	vec3 towerCol = ink * 1.15;
	vec2 wg = vec2((tx + 0.10) / 0.0142, (uv.y - towerTop) / 0.0212);
	vec2 wi = floor(wg);
	vec2 wf = fract(wg);
	float winMask = step(0.24, wf.x) * step(wf.x, 0.76) * step(0.26, wf.y) * step(wf.y, 0.74);
	float r = h21(wi + 17.0);
	float on = step(0.34, r);
	float pulse = 0.72 + 0.28 * sin(t * 1.4 + r * 50.0);
	vec3 winCol = mix(worldGreen * 1.5, mint * 1.1, step(0.88, r));
	towerCol += winMask * on * pulse * winCol * 1.15;

	vec2 blueCell = vec2(4.0, 11.0);
	float isBlue = step(abs(wi.x - blueCell.x), 0.5) * step(abs(wi.y - blueCell.y), 0.5);
	towerCol += winMask * isBlue * playerBlue * (2.0 + 0.6 * sin(t * 2.6));

	float signTop = 0.386;
	float signBot = 0.432;
	float inSign = step(signTop, uv.y) * step(uv.y, signBot);
	towerCol = mix(towerCol, ink * 0.35, inSign);
	float signRule = (1.0 - smoothstep(0.0, 0.0028, abs(uv.y - signTop))) + (1.0 - smoothstep(0.0, 0.0028, abs(uv.y - signBot)));
	towerCol = mix(towerCol, mint * 0.85, clamp(signRule, 0.0, 1.0) * 0.8);

	float edge = 1.0 - smoothstep(0.0, 0.0035, abs(abs(tx) - hw));
	towerCol = mix(towerCol, teal * 0.85, edge * 0.85);
	float ledge = (1.0 - smoothstep(0.0, 0.0035, abs(uv.y - 0.475))) + (1.0 - smoothstep(0.0, 0.0035, abs(uv.y - 0.375))) + (1.0 - smoothstep(0.0, 0.0035, abs(uv.y - 0.905)));
	towerCol = mix(towerCol, teal * 0.75, clamp(ledge, 0.0, 1.0) * 0.7);
	float topRim = 1.0 - smoothstep(0.0, 0.004, uv.y - towerTop);
	towerCol = mix(towerCol, mint * 0.9, topRim * 0.85);

	col = mix(col, towerCol, clamp(inTower, 0.0, 1.0));
	col = mix(col, ink * 1.1, clamp(spire + mast, 0.0, 1.0));

	float beaconPulse = 0.5 + 0.5 * sin(t * 2.2);
	float bd = length((uv - vec2(towerX, 0.163)) * vec2(aspect, 1.0));
	col += teal * (1.0 - smoothstep(0.0, 0.045, bd)) * (0.30 + 0.70 * beaconPulse);
	col += mint * (1.0 - smoothstep(0.0, 0.007, bd)) * 1.4;

	float ground = step(horizon, uv.y);
	col = mix(col, ink * 0.5, ground);
	float curb = 1.0 - smoothstep(0.0, 0.003, abs(uv.y - horizon));
	col = mix(col, teal * 0.4, curb * 0.55);

	// ---- action ----------------------------------------------------------
	// the blast he is running from, on the street to his right
	vec2 boomAt = vec2(0.532, horizon - 0.088);
	float boomK = clamp(loopT / 0.42, 0.0, 1.0);
	float boomFade = pow(1.0 - boomK, 1.7);
	float bdist = length((uv - boomAt) * vec2(aspect, 1.0));
	col += fire * (1.0 - smoothstep(0.0, 0.17 + boomK * 0.14, bdist)) * boomFade * 1.8;
	col += cream * (1.0 - smoothstep(0.0, 0.030 + boomK * 0.070, bdist)) * boomFade * 1.9;
	float ring = 1.0 - smoothstep(0.0, 0.007, abs(bdist - (0.025 + boomK * 0.155)));
	col += mint * ring * boomFade * 0.7;

	// gibs thrown out of it
	for (int i = 0; i < 9; i++) {
		float fi = float(i);
		float ang = h11(fi * 3.1) * 6.2831;
		float sp2 = 0.075 + h11(fi * 7.7) * 0.10;
		vec2 gp = boomAt + vec2(cos(ang), sin(ang) * 0.7) * sp2 * boomK * 1.8;
		gp.y += boomK * boomK * 0.045;
		float gs = 0.0070 + h11(fi * 5.3) * 0.0055;
		float gd = box(rot((uv - gp) * vec2(aspect, 1.0), loopT * 6.0 + fi), vec2(gs, gs * 0.8));
		float gm = 1.0 - smoothstep(0.0, 0.0022, gd);
		col = mix(col, worldGreen * 1.7, gm * boomFade);
	}

	// the blue man, airborne, dashing away from it
	float run = clamp(loopT / 0.85, 0.0, 1.0);
	float ease = 1.0 - pow(1.0 - run, 2.2);
	vec2 manAt = mix(vec2(0.452, horizon - 0.050), vec2(0.378, horizon - 0.225), ease);
	float tilt = -0.55 - ease * 0.25;

	// dash ghosts
	for (int i = 1; i < 5; i++) {
		float fi = float(i);
		float bt = clamp(ease - fi * 0.055, 0.0, 1.0);
		vec2 gAt = mix(vec2(0.452, horizon - 0.050), vec2(0.378, horizon - 0.225), bt);
		float gm = 1.0 - smoothstep(0.0, 0.0030, manShape(uv, gAt, tilt, aspect));
		col += playerBlue * gm * (0.30 - fi * 0.055);
	}

	// tracers he is firing back at the blast
	float shot = smoothstep(0.0, 0.12, loopT) * (1.0 - smoothstep(0.18, 0.42, loopT));
	vec2 gunAt = manAt + rot(vec2(0.045, 0.018), tilt) / vec2(aspect, 1.0);
	for (int i = 0; i < 2; i++) {
		float fi = float(i);
		vec2 aP = (gunAt) * vec2(aspect, 1.0);
		vec2 bP = (boomAt + vec2(0.0, fi * 0.018 - 0.009)) * vec2(aspect, 1.0);
		float sd = seg(uv * vec2(aspect, 1.0), aP, bP);
		col += mint * (1.0 - smoothstep(0.0, 0.0026, sd)) * shot * 1.0;
		col += teal * (1.0 - smoothstep(0.0, 0.008, sd)) * shot * 0.4;
	}
	// muzzle flash
	float md = length((uv - gunAt) * vec2(aspect, 1.0));
	col += mint * (1.0 - smoothstep(0.0, 0.032, md)) * shot * 1.2;
	col += cream * (1.0 - smoothstep(0.0, 0.013, md)) * shot * 1.4;

	float man = 1.0 - smoothstep(0.0, 0.0022, manShape(uv, manAt, tilt, aspect));
	col = mix(col, playerBlue * 1.05, man);
	col += playerBlue * (1.0 - smoothstep(0.0, 0.10, length((uv - manAt) * vec2(aspect, 1.0)))) * 0.20;
	// ----------------------------------------------------------------------

	float pap = 0.0;
	pap += papers(p, t, 5.5, 0.16, 1.0) * 0.55;
	pap += papers(p, t, 9.0, 0.28, 7.0) * 0.40;
	pap += papers(p, t, 14.0, 0.45, 13.0) * 0.28;
	col = mix(col, cream, clamp(pap, 0.0, 1.0) * 0.55 * paperAmount);

	float scan = 0.97 + 0.03 * sin(uv.y * px.y * 1.6);
	col *= scan;

	float g = h21(uv * px + vec2(fract(t) * 91.0, fract(t * 1.3) * 47.0));
	col += (g - 0.5) * grainAmount;

	float vig = 1.0 - smoothstep(0.45, 1.15, length((uv - 0.5) * vec2(aspect * 0.62, 1.0)) * 1.6);
	col *= mix(0.42, 1.0, vig);

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
