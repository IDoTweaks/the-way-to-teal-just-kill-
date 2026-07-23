extends Node3D
func _endless(): pass

signal rewardGranted(room)

@export var player : CharacterBody3D

const WALL_LAYER = 16
const ROOM_LAYER = 17
const ROOM_GAP = 14.0
const DOOR_W = 6.0
const DOOR_H = 5.0
const STEP_RISE = 0.85
const CLEAR_POLL = 0.2
const SPAWN_CLEAR = 2.0
const VOID_Y = -60.0
const STRAY_STRIKES = 3
const SIZE_CLASSES = [0.6, 0.8, 0.8, 1.0, 1.0, 1.0, 1.3, 1.3, 1.7]
const PIT_MIN_W = 46.0
const CATWALK_MIN_W = 36.0
const CATWALK_MIN_D = 26.0

const ROSTER = [
	{"path": "res://ObjectScenes/gnat.tscn", "cost": 1, "from": 1, "fly": false},
	{"path": "res://ObjectScenes/walker.tscn", "cost": 2, "from": 1, "fly": false},
	{"path": "res://ObjectScenes/Xenon.tscn", "cost": 3, "from": 2, "fly": false},
	{"path": "res://ObjectScenes/Charger.tscn", "cost": 3, "from": 2, "fly": false},
	{"path": "res://ObjectScenes/Exploder.tscn", "cost": 3, "from": 3, "fly": false},
	{"path": "res://ObjectScenes/sprinkler.tscn", "cost": 3, "from": 3, "fly": false},
	{"path": "res://ObjectScenes/Drone.tscn", "cost": 4, "from": 3, "fly": true},
	{"path": "res://ObjectScenes/diver.tscn", "cost": 4, "from": 4, "fly": true},
	{"path": "res://ObjectScenes/lobber.tscn", "cost": 4, "from": 4, "fly": false},
	{"path": "res://ObjectScenes/splitter.tscn", "cost": 5, "from": 4, "fly": false},
	{"path": "res://ObjectScenes/stapler.tscn", "cost": 5, "from": 5, "fly": false},
	{"path": "res://ObjectScenes/intern.tscn", "cost": 4, "from": 5, "fly": false},
	{"path": "res://ObjectScenes/warden.tscn", "cost": 5, "from": 6, "fly": false},
	{"path": "res://ObjectScenes/SniperEnemy.tscn", "cost": 5, "from": 6, "fly": false},
	{"path": "res://ObjectScenes/printer.tscn", "cost": 6, "from": 7, "fly": false},
	{"path": "res://ObjectScenes/shredder.tscn", "cost": 7, "from": 8, "fly": false},
]

const BOSSES = [
	{"path": "res://ObjectScenes/kettle.tscn", "name": "THE KETTLE", "arena": "kettle"},
	{"path": "res://ObjectScenes/landlord.tscn", "name": "THE LANDLORD", "arena": "landlord"},
	{"path": "res://ObjectScenes/cubicleFarm.tscn", "name": "THE CUBICLE FARM", "arena": "cubicle"},
	{"path": "res://ObjectScenes/consultant.tscn", "name": "THE CONSULTANT", "arena": "consultant"},
	{"path": "res://ObjectScenes/complianceOfficer.tscn", "name": "THE COMPLIANCE OFFICER", "arena": "compliance"},
	{"path": "res://ObjectScenes/archive.tscn", "name": "THE ARCHIVE", "arena": "archive"},
	{"path": "res://ObjectScenes/notary.tscn", "name": "THE NOTARY", "arena": "notary"},
]

@onready var rooms = $Rooms
@onready var roomMat = preload("res://shaders/new_standard_material_3d.tres")
@onready var outlineMat = preload("res://shaders/toonOutline.tres")
@onready var upgradeList = preload("res://Scripts/upgrades.gd")

var taken : Dictionary = {}
var picker

var rng = RandomNumberGenerator.new()
var runSeed : int = 0
var roomNum : int = 0
var nextOriginX : float = 0.0
var live : Array = []
var current = null
var cleared = false
var pollAccum : float = 0.0
var runScore : int = 0
var roomWorth : int = 0
var lastBoss : String = ""
var strays : Dictionary = {}
var bossPending = null
var propMats : Dictionary = {}

var hudLayer : CanvasLayer
var roomLabel : Label
var seedLabel : Label
var scoreLabel : Label
var banner : Label

func _ready() -> void:
	runSeed = Global.endlessSeed
	_buildHud()
	picker = preload("res://Scripts/upgrade_pick.gd").new()
	add_child(picker)
	picker.visible = false
	picker.picked.connect(_onUpgradePicked)
	_buildRoom(1)
	if player:
		var r = current["data"]
		player.global_position = Vector3(r["x"] + 5.0, 2.0, 0.0)

func _buildHud():
	hudLayer = CanvasLayer.new()
	hudLayer.layer = 50
	add_child(hudLayer)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = load("res://UI/funkyTheme.tres")
	hudLayer.add_child(root)

	roomLabel = _hudLabel(root, "H1", 18, 78)
	seedLabel = _hudLabel(root, "Micro", 82, 110)
	scoreLabel = _hudLabel(root, "Small", 112, 144)
	seedLabel.text = "SEED %d" % runSeed

	banner = Label.new()
	banner.theme_type_variation = "Display"
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -520
	banner.offset_right = 520
	banner.offset_top = -220
	banner.offset_bottom = -140
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a = 0.0
	root.add_child(banner)

func _hudLabel(root : Control, variation : String, top : float, bottom : float) -> Label:
	var l = Label.new()
	l.theme_type_variation = variation
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.offset_left = -300
	l.offset_right = 300
	l.offset_top = top
	l.offset_bottom = bottom
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l

func _upgradeCount() -> int:
	var n = 0
	for k in taken:
		n += taken[k]
	return n

func _updateHud():
	roomLabel.text = "ROOM %d" % roomNum
	scoreLabel.text = "%d PTS   %d KILLS   %d UPGRADES" % [runScore, _kills(), _upgradeCount()]

func _kills() -> int:
	return player.killCount if player else 0

func _syncGlobals():
	Global.endlessRoom = roomNum
	Global.endlessScore = runScore
	Global.endlessKills = _kills()
	Global.endlessUpgrades = _upgradeCount()
	_updateHud()

func _flash(txt : String):
	banner.text = txt
	banner.scale = Vector2(0.7, 0.7)
	banner.pivot_offset = banner.size * 0.5
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_ELASTIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.5)
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.chain().tween_interval(1.4)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.5)

func _isBossRoom(n : int) -> bool:
	return n % 5 == 0

func _pickArch(w : float, d : float) -> int:
	var pool = [0, 1]
	if w >= CATWALK_MIN_W and d >= CATWALK_MIN_D:
		pool.append(2)
	if w >= PIT_MIN_W:
		pool.append(3)
	return pool[rng.randi_range(0, pool.size() - 1)]

func _buildRoom(n : int):
	rng.seed = hash(runSeed) + n * 7919
	roomNum = n
	cleared = false
	roomWorth = 0
	bossPending = null

	var boss = _isBossRoom(n)
	var bossPick = _pickBoss() if boss else {}
	var sizeMul = SIZE_CLASSES[rng.randi_range(0, SIZE_CLASSES.size() - 1)]
	var stretch = rng.randf_range(0.75, 1.35)
	var w = clamp((32.0 + n * 1.7) * sizeMul * stretch, 24.0, 115.0)
	var d = clamp((22.0 + n * 1.0) * sizeMul / stretch, 18.0, 62.0)
	var h = rng.randf_range(7.5, 18.0)
	var density = rng.randf_range(0.35, 1.65)
	if boss:
		w = max(w, 54.0)
		d = max(d, 38.0)
		h = max(h, 15.0)

	var arch = 0 if boss else _pickArch(w, d)

	var room = Node3D.new()
	rooms.add_child(room)

	var solid = CSGCombiner3D.new()
	solid.use_collision = true
	solid.collision_layer = ROOM_LAYER
	solid.material_override = roomMat
	room.add_child(solid)

	var x = nextOriginX
	var data = {"x": x, "w": w, "d": d, "h": h, "density": density, "blocked": []}

	_shell(solid, x, w, d, h, arch != 3, n > 1)
	_corridor(solid, x + w)

	if boss:
		_bossArena(room, data, bossPick["arena"])
	else:
		match arch:
			1: _archPillars(solid, data)
			2: _archCatwalks(solid, data)
			3: _archPit(solid, data)
			_: _archArena(solid, data)

	var door = _door(room, x + w)
	_gate(room, x + w + 3.0)

	current = {"node": room, "data": data, "door": door, "n": n}
	live.append(current)

	if boss:
		_spawnBoss(room, data, n, bossPick)
	else:
		_spawnWave(room, data, n)

	nextOriginX = x + w + ROOM_GAP

	Audio.music_for_endless(n, boss)
	if n > Global.endlessBest:
		Global.endlessBest = n
		Global._localSave()
	_syncGlobals()

func _box(parent : Node3D, pos : Vector3, size : Vector3):
	var b = CSGBox3D.new()
	b.size = size
	b.position = pos
	parent.add_child(b)
	return b

func _propMat(col : Color) -> StandardMaterial3D:
	var key = col.to_html(false)
	if propMats.has(key):
		return propMats[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 1.0
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.next_pass = outlineMat
	propMats[key] = m
	return m

func _prop(room : Node3D, data, pos : Vector3, size : Vector3, col : Color) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = ROOM_LAYER
	body.position = pos
	room.add_child(body)

	var mesh = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _propMat(col)
	body.add_child(mesh)

	var col3 = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col3.shape = shape
	body.add_child(col3)

	if data != null:
		data["blocked"].append({
			"minX": pos.x - size.x * 0.5, "maxX": pos.x + size.x * 0.5,
			"minZ": pos.z - size.z * 0.5, "maxZ": pos.z + size.z * 0.5,
		})
	return body

func _solid(parent : Node3D, data : Dictionary, pos : Vector3, size : Vector3):
	data["blocked"].append({
		"minX": pos.x - size.x * 0.5, "maxX": pos.x + size.x * 0.5,
		"minZ": pos.z - size.z * 0.5, "maxZ": pos.z + size.z * 0.5,
	})
	return _box(parent, pos, size)

func _shell(solid : CSGCombiner3D, x : float, w : float, d : float, h : float, withFloor : bool, backDoor : bool):
	var cx = x + w * 0.5
	if withFloor:
		_box(solid, Vector3(cx, -0.5, 0), Vector3(w, 1, d))
	_box(solid, Vector3(cx, h + 0.5, 0), Vector3(w, 1, d))
	_box(solid, Vector3(cx, h * 0.5, -(d * 0.5 + 0.5)), Vector3(w, h, 1))
	_box(solid, Vector3(cx, h * 0.5, d * 0.5 + 0.5), Vector3(w, h, 1))

	if backDoor:
		_pierced(solid, x - 0.5, d, h)
	else:
		_box(solid, Vector3(x - 0.5, h * 0.5, 0), Vector3(1, h, d))
	_pierced(solid, x + w + 0.5, d, h)

func _pierced(solid : CSGCombiner3D, wallX : float, d : float, h : float):
	var sideZ = (d - DOOR_W) * 0.5
	var offZ = (DOOR_W + sideZ) * 0.5
	_box(solid, Vector3(wallX, h * 0.5, -offZ), Vector3(1, h, sideZ))
	_box(solid, Vector3(wallX, h * 0.5, offZ), Vector3(1, h, sideZ))
	_box(solid, Vector3(wallX, (DOOR_H + h) * 0.5, 0), Vector3(1, h - DOOR_H, DOOR_W))

func _corridor(solid : CSGCombiner3D, x : float):
	var len = ROOM_GAP - 1.0
	var cx = x + 1.0 + len * 0.5
	_box(solid, Vector3(cx, -0.5, 0), Vector3(len, 1, DOOR_W + 2))
	_box(solid, Vector3(cx, DOOR_H + 0.5, 0), Vector3(len, 1, DOOR_W + 2))
	_box(solid, Vector3(cx, DOOR_H * 0.5, -(DOOR_W * 0.5 + 0.5)), Vector3(len, DOOR_H, 1))
	_box(solid, Vector3(cx, DOOR_H * 0.5, DOOR_W * 0.5 + 0.5), Vector3(len, DOOR_H, 1))

func _door(room : Node3D, x : float):
	var body = StaticBody3D.new()
	body.collision_layer = ROOM_LAYER
	body.position = Vector3(x + 0.5, DOOR_H * 0.5, 0)
	room.add_child(body)

	var mesh = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(1, DOOR_H, DOOR_W)
	mesh.mesh = bm
	mesh.material_override = roomMat
	body.add_child(mesh)

	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, DOOR_H, DOOR_W)
	col.shape = shape
	body.add_child(col)
	return body

func _gate(room : Node3D, x : float):
	var area = Area3D.new()
	area.position = Vector3(x, DOOR_H * 0.5, 0)
	room.add_child(area)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2, DOOR_H, DOOR_W)
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_onGate)
	return area

func _onGate(body : Node3D):
	if not body.has_method("player"):
		return
	if not cleared:
		return
	_advance()

func _archArena(solid : CSGCombiner3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var count = int(round(w * d / 190.0 * data["density"]))
	for i in clamp(count, 0, 14):
		var bx = x + rng.randf_range(10.0, max(11.0, w - 10.0))
		var bz = rng.randf_range(-d * 0.5 + 5.0, d * 0.5 - 5.0)
		var bh = rng.randf_range(0.85, 2.6)
		_solid(solid, data, Vector3(bx, bh * 0.5, bz), Vector3(rng.randf_range(3, 9), bh, rng.randf_range(3, 9)))

func _archPillars(solid : CSGCombiner3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var h = data["h"]
	var cols = clamp(int(round(w / 11.0 * data["density"])), 1, 8)
	var rowsZ = clamp(int(round(d / 11.0 * data["density"])), 1, 5)
	var skip = clamp(0.45 - data["density"] * 0.2, 0.05, 0.4)
	for i in cols:
		for j in rowsZ:
			if rng.randf() < skip:
				continue
			var px = x + (w / float(cols + 1)) * (i + 1) + rng.randf_range(-1.5, 1.5)
			var pz = (d / float(rowsZ + 1)) * (j + 1) - d * 0.5 + rng.randf_range(-1.5, 1.5)
			_solid(solid, data, Vector3(px, h * 0.5, pz), Vector3(rng.randf_range(2.5, 4.0), h, rng.randf_range(2.5, 4.0)))

func _archCatwalks(solid : CSGCombiner3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]

	var deckTop = STEP_RISE * 4.0
	var deckZ = -d * 0.5 + 5.0
	_solid(solid, data, Vector3(x + w * 0.5, deckTop - 0.5, deckZ), Vector3(w - 10.0, 1, 8))
	_rampZ(solid, data, x + w * 0.35, deckZ + 4.0, 4)

	var deck2Top = STEP_RISE * 2.0
	var deck2Z = d * 0.5 - 5.0
	_solid(solid, data, Vector3(x + w * 0.6, deck2Top - 0.5, deck2Z), Vector3(w * 0.5, 1, 7))
	_rampZ(solid, data, x + w * 0.6, deck2Z - 3.5, 2, -1.0)

func _rampZ(solid : CSGCombiner3D, data : Dictionary, x : float, zEdge : float, steps : int, dir : float = 1.0):
	for i in steps:
		var top = STEP_RISE * (i + 1)
		var z = zEdge + dir * (steps - i) * 3.0 - dir * 1.5
		_solid(solid, data, Vector3(x, top * 0.5, z), Vector3(7, top, 3))

func _archPit(solid : CSGCombiner3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var depth = STEP_RISE * 4.0
	var pitStart = x + w * 0.35
	var pitEnd = x + w * 0.65
	var pitW = pitEnd - pitStart

	_box(solid, Vector3(x + (pitStart - x) * 0.5, -0.5, 0), Vector3(pitStart - x, 1, d))
	_box(solid, Vector3(pitEnd + (x + w - pitEnd) * 0.5, -0.5, 0), Vector3(x + w - pitEnd, 1, d))
	_box(solid, Vector3(pitStart + pitW * 0.5, -depth - 0.5, 0), Vector3(pitW, 1, d))
	_box(solid, Vector3(pitStart - 0.5, -depth * 0.5, 0), Vector3(1, depth, d))
	_box(solid, Vector3(pitEnd + 0.5, -depth * 0.5, 0), Vector3(1, depth, d))

	for i in 4:
		var top = -depth + STEP_RISE * (i + 1)
		var sy = top + depth
		var sx = pitEnd - 1.5 - (3 - i) * 3.0
		_box(solid, Vector3(sx, top - sy * 0.5, d * 0.5 - 4.0), Vector3(3, sy, 6))

	data["blocked"].append({
		"minX": pitStart - 2.0, "maxX": pitEnd + 2.0,
		"minZ": -d * 0.5, "maxZ": d * 0.5,
	})

func _bossArena(room : Node3D, data : Dictionary, key : String):
	match key:
		"kettle": _arenaKettle(room, data)
		"landlord": _arenaLandlord(room, data)
		"cubicle": _arenaCubicle(room, data)
		"consultant": _arenaConsultant(room, data)
		"compliance": _arenaCompliance(room, data)
		"archive": _arenaArchive(room, data)
		"notary": _arenaNotary(room, data)

func _steps(room : Node3D, data : Dictionary, x : float, z : float, count : int, wide : float, deep : float, dir : float, col : Color):
	for i in count:
		var top = STEP_RISE * (i + 1)
		var sx = x + dir * (count - 1 - i) * deep
		_prop(room, data, Vector3(sx, top * 0.5, z), Vector3(deep, top, wide), col)

func _arenaKettle(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var cx = x + w * 0.5
	var METAL = Color(.42, .28, .18)
	var PIPE = Color(.88, .48, .17)
	var GRATE = Color(.17, .19, .18)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var px = cx + sx * w * 0.26
			var pz = sz * (d * 0.5 - 7.0)
			_prop(room, data, Vector3(px, STEP_RISE * 0.5, pz), Vector3(9, STEP_RISE, 9), GRATE)

	for sz in [-1.0, 1.0]:
		_prop(room, data, Vector3(x + 9.0, 5.0, sz * (d * 0.5 - 6.0)), Vector3(7, 10, 7), METAL)
		_prop(room, null, Vector3(cx, 4.2, sz * (d * 0.5 - 1.0)), Vector3(w - 6.0, 1.1, 1.1), PIPE)
		_prop(room, null, Vector3(cx, 6.6, sz * (d * 0.5 - 1.0)), Vector3(w - 16.0, .8, .8), PIPE)
		_prop(room, data, Vector3(x + w - 4.0, 2.0, sz * 6.5), Vector3(2.2, 4.0, 2.2), PIPE)

func _arenaLandlord(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var h = data["h"]
	var cx = x + w * 0.5
	var PURPLE = Color(.36, .2, .52)
	var BRASS = Color(.76, .62, .22)
	var CARPET = Color(.28, .16, .34)
	var MARBLE = Color(.82, .8, .74)

	_prop(room, null, Vector3(cx, .04, 0), Vector3(w - 4.0, .08, 11), CARPET)

	for i in 4:
		var px = x + w * (0.22 + i * 0.19)
		for sz in [-1.0, 1.0]:
			_prop(room, data, Vector3(px, h * 0.5, sz * (d * 0.5 - 5.0)), Vector3(2.4, h, 2.4), BRASS)

	for sz in [-1.0, 1.0]:
		_prop(room, data, Vector3(x + 11.0, .9, sz * (d * 0.5 - 9.0)), Vector3(13, 1.8, 3), MARBLE)

	_prop(room, null, Vector3(x + w - 1.4, h * 0.62, 0), Vector3(.4, h * 0.4, d * 0.5), PURPLE)

func _arenaCubicle(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var PART = Color(.85, .81, .68)
	var DESK = Color(.45, .38, .3)

	var gx0 = x + 8.0
	var gx1 = x + w - 8.0
	var cells = clamp(int((gx1 - gx0) / 10.0), 3, 6)
	var cw = (gx1 - gx0) / float(cells)
	var span = d - 12.0
	var rowsN = clamp(int(span / 10.0), 2, 4)
	var rh = span / float(rowsN)

	for i in cells:
		for j in rowsN:
			var px = gx0 + cw * (i + .5)
			var pz = -span * .5 + rh * (j + .5)
			_prop(room, data, Vector3(px - cw * .5, .4, pz), Vector3(.5, .8, rh - 1.5), PART)
			_prop(room, data, Vector3(px, .4, pz - rh * .5), Vector3(cw - 1.5, .8, .5), PART)
			if (i + j) % 2 == 0:
				_prop(room, data, Vector3(px + 1.2, .35, pz + 1.2), Vector3(3.4, .7, 2.2), DESK)

func _arenaConsultant(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var cx = x + w * 0.5
	var SLATE = Color(.24, .3, .31)
	var BOARD = Color(.9, .89, .82)

	var deckLen = w - 24.0
	var deckTop = STEP_RISE * 3.0
	for sz in [-1.0, 1.0]:
		var dz = sz * (d * 0.5 - 5.5)
		_prop(room, data, Vector3(cx, deckTop - .5, dz), Vector3(deckLen, 1.0, 9.0), SLATE)
		for e in [-1.0, 1.0]:
			_steps(room, data, cx + e * (deckLen * .5 + 1.5), dz, 3, 9.0, 3.0, e, SLATE)

	_prop(room, data, Vector3(x + w * .42, STEP_RISE * .5, 0), Vector3(11, STEP_RISE, 6), BOARD)
	_prop(room, data, Vector3(x + 7.0, STEP_RISE * .5, 0), Vector3(6, STEP_RISE, 8), BOARD)

func _arenaCompliance(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var h = data["h"]
	var cx = x + w * 0.5
	var STONE = Color(.34, .38, .38)
	var TAPE = Color(.66, .27, .22)
	var CREAM = Color(.88, .85, .76)

	for i in 4:
		var px = x + w * (0.24 + i * 0.17)
		for sz in [-1.0, 1.0]:
			_prop(room, data, Vector3(px, h * .38, sz * 8.5), Vector3(2.6, h * .76, 2.6), STONE)

	for sz in [-1.0, 1.0]:
		_prop(room, data, Vector3(cx, STEP_RISE * .5, sz * (d * .5 - 6.0)), Vector3(w - 18.0, STEP_RISE, 1.2), TAPE)
		_prop(room, data, Vector3(x + 9.0, 1.1, sz * (d * .5 - 4.0)), Vector3(6, 2.2, 3), CREAM)

func _arenaArchive(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var MANILA = Color(.78, .62, .3)
	var SHELF = Color(.33, .27, .21)

	for i in 4:
		var px = x + w * (0.16 + i * 0.13)
		for sz in [-1.0, 1.0]:
			_prop(room, data, Vector3(px, 2.0, sz * (d * .5 - 8.0)), Vector3(2.4, 4.0, d * .34), MANILA)

	for i in 3:
		var bx = x + w * (0.23 + i * 0.13)
		_prop(room, data, Vector3(bx, 2.6, 0), Vector3(2.0, 2.0, 13.0), SHELF)

	for sz in [-1.0, 1.0]:
		_prop(room, data, Vector3(x + w - 6.0, 1.4, sz * 6.5), Vector3(4, 2.8, 4), SHELF)

func _arenaNotary(room : Node3D, data : Dictionary):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var WOOD = Color(.36, .22, .13)
	var PEW = Color(.44, .3, .18)
	var PAPER = Color(.88, .85, .74)

	var benchTop = STEP_RISE * 3.0
	for sz in [-1.0, 1.0]:
		var bz = sz * (d * .25 + 3.0)
		_prop(room, data, Vector3(x + w - 8.0, benchTop - .5, bz), Vector3(10, 1.0, 10), WOOD)
		_steps(room, data, x + w - 14.5, bz, 3, 10.0, 3.0, -1.0, WOOD)
		_prop(room, null, Vector3(x + w - 8.0, benchTop + .5, bz), Vector3(6, 1.0, 1.0), PAPER)

	for i in 4:
		var px = x + 9.0 + i * 5.0
		_prop(room, data, Vector3(px, STEP_RISE * .5, 0), Vector3(1.8, STEP_RISE, d - 15.0), PEW)

func _free(data : Dictionary, px : float, pz : float, margin : float = SPAWN_CLEAR) -> bool:
	for b in data["blocked"]:
		if px > b["minX"] - margin and px < b["maxX"] + margin:
			if pz > b["minZ"] - margin and pz < b["maxZ"] + margin:
				return false
	return true

func _gridSpot(data : Dictionary, margin : float, y : float):
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var gx = x + 6.0
	while gx < x + w - 5.0:
		var gz = -d * 0.5 + 4.0
		while gz < d * 0.5 - 4.0:
			if _free(data, gx, gz, margin):
				return Vector3(gx, y, gz)
			gz += 2.0
		gx += 2.0
	return null

func _spot(data : Dictionary, fly : bool) -> Vector3:
	var x = data["x"]
	var w = data["w"]
	var d = data["d"]
	var y = 6.0 if fly else 1.5
	for attempt in 40:
		var px = x + rng.randf_range(8.0, w - 6.0)
		var pz = rng.randf_range(-d * 0.5 + 4.0, d * 0.5 - 4.0)
		if _free(data, px, pz):
			return Vector3(px, y, pz)

	for margin in [SPAWN_CLEAR, 1.0, 0.4]:
		var g = _gridSpot(data, margin, y)
		if g != null:
			return g
	return Vector3(x + w - 3.0, y, 0.0)

func _wire(inst : Node, n : int):
	if "player" in inst:
		inst.player = player
	if "wallLayer" in inst:
		inst.wallLayer = WALL_LAYER
	if n > 5 and "damage" in inst:
		inst.damage = int(inst.damage * min(1.0 + (n - 5) * 0.04, 1.5))

func _spawnWave(room : Node3D, data : Dictionary, n : int):
	var budget = 6.0 + n * 3.5
	var pool = []
	for e in ROSTER:
		if e["from"] <= n:
			pool.append(e)
	if pool.is_empty():
		pool.append(ROSTER[0])

	var guard = 0
	while budget > 0.0 and guard < 60:
		guard += 1
		var afford = []
		for e in pool:
			if e["cost"] <= budget:
				afford.append(e)
		if afford.is_empty():
			break
		var pick = afford[rng.randi_range(0, afford.size() - 1)]
		budget -= pick["cost"]
		_spawn(room, load(pick["path"]), _spot(data, pick["fly"]), n)

func _pickBoss() -> Dictionary:
	var pool = []
	for b in BOSSES:
		if b["name"] != lastBoss:
			pool.append(b)
	if pool.is_empty():
		pool = BOSSES
	return pool[rng.randi_range(0, pool.size() - 1)]

func _spawnBoss(room : Node3D, data : Dictionary, n : int, pick : Dictionary):
	lastBoss = pick["name"]
	var inst = _spawn(room, load(pick["path"]), Vector3(data["x"] + data["w"] * 0.7, 2.0, 0.0), n)
	if "sightRange" in inst:
		inst.sightRange = 0.0
		bossPending = inst

func _spawn(room : Node3D, scene : PackedScene, pos : Vector3, n : int):
	var inst = scene.instantiate()
	inst.position = pos
	_wire(inst, n)
	room.add_child(inst)
	if "floorY" in inst:
		_refloor.call_deferred(inst)
	if "scoreWorth" in inst:
		roomWorth += inst.scoreWorth
	return inst

func _refloor(inst):
	for i in 4:
		await get_tree().physics_frame
	if is_instance_valid(inst) and inst.has_method("_floorLevel"):
		inst.floorY = inst._floorLevel()

func _inAnyRoom(pos : Vector3) -> bool:
	for entry in live:
		var r = entry["data"]
		if pos.x < r["x"] - 2.0 or pos.x > r["x"] + r["w"] + ROOM_GAP + 3.0:
			continue
		if abs(pos.z) > r["d"] * 0.5 + 2.0:
			continue
		if pos.y < -6.0 or pos.y > r["h"] + 4.0:
			continue
		return true
	return false

func _rescue(e : Node3D) -> bool:
	var id = e.get_instance_id()
	strays[id] = strays.get(id, 0) + 1
	if strays[id] > STRAY_STRIKES or current == null:
		return false
	e.global_position = _spot(current["data"], false)
	if "velocity" in e:
		e.velocity = Vector3.ZERO
	return true

func _enemiesLeft() -> int:
	var c = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("dead") == true:
			continue
		if e is Node3D and e.global_position.y < VOID_Y:
			if e.has_method("_takeDamage"):
				e._takeDamage(100000)
			continue
		if e is Node3D and not _inAnyRoom(e.global_position):
			if not _rescue(e):
				if e.has_method("_takeDamage"):
					e._takeDamage(100000)
				continue
		c += 1
	return c

func _process(delta: float) -> void:
	if cleared or current == null:
		return
	if bossPending != null:
		if not is_instance_valid(bossPending):
			bossPending = null
		elif player != null and player.global_position.x > current["data"]["x"] + 2.5:
			bossPending.sightRange = 9999.0
			bossPending = null
	pollAccum += delta
	if pollAccum < CLEAR_POLL:
		return
	pollAccum = 0.0
	_syncGlobals()
	if _enemiesLeft() <= 0:
		_clearRoom()

func _clearRoom():
	cleared = true
	runScore += int(roomWorth * (player.scoreMult if player else 1.0))
	_syncGlobals()
	_openDoor()
	Audio.play("win", 1.5, -8.0)
	_grantReward(roomNum)

func _openDoor():
	var door = current["door"]
	if door == null or not is_instance_valid(door):
		return
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(door, "position:y", -DOOR_H * 0.5 - 0.6, 0.6)

func _grantReward(n : int):
	var count = 3 + (player.extraChoice if player else 0)
	var options = upgradeList.roll(rng, taken, count)
	if options.is_empty():
		_flash("ROOM CLEAR")
		rewardGranted.emit(n)
		return
	picker.open(options)
	rewardGranted.emit(n)

func _onUpgradePicked(u : Dictionary):
	taken[u["id"]] = taken.get(u["id"], 0) + 1
	upgradeList.apply(player, u)
	_flash(u["name"])
	_syncGlobals()

func _advance():
	var old = null
	if live.size() >= 2:
		old = live[live.size() - 2]
	_buildRoom(roomNum + 1)
	if old != null:
		live.erase(old)
		if is_instance_valid(old["node"]):
			old["node"].queue_free()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		Global._restartCurrent()
