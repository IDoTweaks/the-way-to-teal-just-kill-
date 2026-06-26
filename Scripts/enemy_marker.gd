extends Sprite3D

var baseY : float = 0.0
var basePixel : float = 0.0012

func _ready() -> void:
	texture = _makeTriangle()
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	shaded = false
	double_sided = true
	render_priority = 20
	pixel_size = basePixel
	baseY = position.y

func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.004
	position.y = baseY + sin(t) * 0.15
	pixel_size = basePixel * (1.0 + sin(t * 1.7) * 0.12)
	modulate = Color(0.1, 1.0, 0.45).lerp(Color(0.45, 1.0, 0.75), sin(t * 2.0) * 0.5 + 0.5)

func _makeTriangle():
	var s = 64
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var a = Vector2(s * 0.5, s * 0.84)
	var b = Vector2(s * 0.13, s * 0.18)
	var c = Vector2(s * 0.87, s * 0.18)
	var outline = s * 0.085
	var aa = 1.5
	for y in range(s):
		for x in range(s):
			var d = _triDist(Vector2(x, y), a, b, c)
			if d < -outline:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
			elif d < aa:
				var al = 1.0 if d <= 0.0 else clamp(1.0 - d / aa, 0.0, 1.0)
				img.set_pixel(x, y, Color(0, 0, 0, al))
	return ImageTexture.create_from_image(img)

func _triDist(p, p0, p1, p2):
	var e0 = p1 - p0
	var e1 = p2 - p1
	var e2 = p0 - p2
	var v0 = p - p0
	var v1 = p - p1
	var v2 = p - p2
	var pq0 = v0 - e0 * clamp(v0.dot(e0) / e0.dot(e0), 0.0, 1.0)
	var pq1 = v1 - e1 * clamp(v1.dot(e1) / e1.dot(e1), 0.0, 1.0)
	var pq2 = v2 - e2 * clamp(v2.dot(e2) / e2.dot(e2), 0.0, 1.0)
	var sgn = sign(e0.x * e2.y - e0.y * e2.x)
	var d0 = Vector2(pq0.dot(pq0), sgn * (v0.x * e0.y - v0.y * e0.x))
	var d1 = Vector2(pq1.dot(pq1), sgn * (v1.x * e1.y - v1.y * e1.x))
	var d2 = Vector2(pq2.dot(pq2), sgn * (v2.x * e2.y - v2.y * e2.x))
	var dx = min(d0.x, min(d1.x, d2.x))
	var dy = min(d0.y, min(d1.y, d2.y))
	return -sqrt(dx) * sign(dy)
