extends MeshInstance3D

@export var style : String = "angry"
@export var face_size : float = 0.9
@export var face_forward : float = 0.52
@export var face_height : float = 0.3

static var _tex_cache = {}

const INK = Color(0.031, 0.133, 0.149)
const CREAM = Color(1.0, 0.988, 0.941)
const TEAL = Color(0.0, 0.851, 0.78)

func _ready() -> void:
	var quad = QuadMesh.new()
	quad.size = Vector2(face_size, face_size)
	mesh = quad
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = _get_tex(style)
	mat.disable_receive_shadows = true
	material_override = mat
	_placeOnFront()

func _placeOnFront():
	var want = Transform3D(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(0, face_height, -face_forward))
	var chain = Transform3D.IDENTITY
	var n = get_parent()
	while n != null and n is Node3D and not (n is CharacterBody3D):
		chain = n.transform * chain
		n = n.get_parent()
	transform = chain.affine_inverse() * want

func _set_face(new_style : String) -> void:
	if new_style == style:
		return
	style = new_style
	if material_override:
		material_override.albedo_texture = _get_tex(style)

static func _get_tex(s : String) -> ImageTexture:
	if _tex_cache.has(s):
		return _tex_cache[s]
	var img = Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var shapes = _face_shapes(s)
	for y in 96:
		for x in 96:
			var p = Vector2(x + 0.5, y + 0.5)
			var col = Color(0, 0, 0, 0)
			for sh in shapes:
				var d = _shape_dist(p, sh)
				var a = clamp(0.5 - d / 1.6, 0.0, 1.0)
				if a > 0.0:
					var c : Color = sh["col"]
					col = Color(lerp(col.r, c.r, a), lerp(col.g, c.g, a), lerp(col.b, c.b, a), max(col.a, a * c.a))
			img.set_pixel(x, y, col)
	var tex = ImageTexture.create_from_image(img)
	_tex_cache[s] = tex
	return tex

static func _shape_dist(p : Vector2, sh : Dictionary) -> float:
	match sh["t"]:
		"circle":
			return p.distance_to(sh["c"]) - sh["r"]
		"ellipse":
			var q = (p - sh["c"]) / sh["rad"]
			return (q.length() - 1.0) * min(sh["rad"].x, sh["rad"].y)
		"seg":
			var a : Vector2 = sh["a"]
			var b : Vector2 = sh["b"]
			var ab = b - a
			var t = clamp((p - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
			return p.distance_to(a + ab * t) - sh["w"]
		"rect":
			var q = (p - sh["c"]).abs() - sh["half"]
			return Vector2(max(q.x, 0.0), max(q.y, 0.0)).length() + min(max(q.x, q.y), 0.0)
	return 999.0

static func _eye_pair(shapes : Array, lx : float, rx : float, y : float, r : float, pr : float, poff : Vector2):
	for cx in [lx, rx]:
		shapes.append({"t": "circle", "c": Vector2(cx, y), "r": r + 3.0, "col": INK})
	for cx in [lx, rx]:
		shapes.append({"t": "circle", "c": Vector2(cx, y), "r": r, "col": CREAM})
	shapes.append({"t": "circle", "c": Vector2(lx, y) + Vector2(poff.x, poff.y), "r": pr, "col": INK})
	shapes.append({"t": "circle", "c": Vector2(rx, y) + Vector2(-poff.x, poff.y), "r": pr, "col": INK})

static func _face_shapes(s : String) -> Array:
	var sh = []
	match s:
		"angry":
			_eye_pair(sh, 30, 66, 38, 12, 5, Vector2(3, 2))
			sh.append({"t": "seg", "a": Vector2(14, 18), "b": Vector2(42, 28), "w": 4.5, "col": INK})
			sh.append({"t": "seg", "a": Vector2(82, 18), "b": Vector2(54, 28), "w": 4.5, "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 68), "half": Vector2(24, 11), "col": INK})
			for tx in [34, 48, 62]:
				sh.append({"t": "rect", "c": Vector2(tx, 63), "half": Vector2(4.5, 4.5), "col": CREAM})
		"cyclops":
			sh.append({"t": "circle", "c": Vector2(48, 44), "r": 23, "col": INK})
			sh.append({"t": "circle", "c": Vector2(48, 44), "r": 19, "col": CREAM})
			sh.append({"t": "circle", "c": Vector2(45, 48), "r": 8, "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 28), "half": Vector2(24, 6), "col": INK})
			sh.append({"t": "seg", "a": Vector2(38, 77), "b": Vector2(58, 77), "w": 4, "col": INK})
		"mad":
			sh.append({"t": "seg", "a": Vector2(20, 32), "b": Vector2(38, 42), "w": 4.5, "col": INK})
			sh.append({"t": "seg", "a": Vector2(76, 32), "b": Vector2(58, 42), "w": 4.5, "col": INK})
			sh.append({"t": "circle", "c": Vector2(39, 57), "r": 4.5, "col": INK})
			sh.append({"t": "circle", "c": Vector2(57, 57), "r": 4.5, "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 74), "half": Vector2(23, 8), "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 74), "half": Vector2(19, 4.5), "col": CREAM})
			for tx in [38, 48, 58]:
				sh.append({"t": "seg", "a": Vector2(tx, 70), "b": Vector2(tx, 78), "w": 1.6, "col": INK})
		"dash":
			for ex in [29, 67]:
				sh.append({"t": "seg", "a": Vector2(ex - 8, 30), "b": Vector2(ex + 8, 46), "w": 4, "col": INK})
				sh.append({"t": "seg", "a": Vector2(ex + 8, 30), "b": Vector2(ex - 8, 46), "w": 4, "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 74), "half": Vector2(23, 8), "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 74), "half": Vector2(19, 4.5), "col": CREAM})
			for tx in [38, 48, 58]:
				sh.append({"t": "seg", "a": Vector2(tx, 70), "b": Vector2(tx, 78), "w": 1.6, "col": INK})
		"visor":
			sh.append({"t": "rect", "c": Vector2(48, 42), "half": Vector2(30, 12), "col": INK})
			sh.append({"t": "rect", "c": Vector2(48, 42), "half": Vector2(26, 8), "col": Color(0.02, 0.09, 0.1)})
			sh.append({"t": "seg", "a": Vector2(32, 42), "b": Vector2(52, 42), "w": 4.5, "col": TEAL})
		"grin":
			sh.append({"t": "ellipse", "c": Vector2(48, 66), "rad": Vector2(26, 15), "col": INK})
			sh.append({"t": "ellipse", "c": Vector2(48, 66), "rad": Vector2(22, 11), "col": CREAM})
			sh.append({"t": "seg", "a": Vector2(27, 63), "b": Vector2(69, 63), "w": 1.8, "col": INK})
			for tx in [36, 48, 60]:
				sh.append({"t": "seg", "a": Vector2(tx, 63), "b": Vector2(tx, 74), "w": 1.5, "col": INK})
		"ghost":
			for cx in [33, 63]:
				sh.append({"t": "ellipse", "c": Vector2(cx, 40), "rad": Vector2(10, 14), "col": INK})
			sh.append({"t": "ellipse", "c": Vector2(48, 68), "rad": Vector2(11, 14), "col": INK})
		"panic":
			sh.append({"t": "circle", "c": Vector2(48, 68), "r": 14, "col": INK})
			sh.append({"t": "circle", "c": Vector2(48, 68), "r": 8, "col": Color(0.05, 0.02, 0.03)})
			sh.append({"t": "circle", "c": Vector2(18, 22), "r": 4, "col": TEAL})
			sh.append({"t": "circle", "c": Vector2(78, 18), "r": 4, "col": TEAL})
	return sh
