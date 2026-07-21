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
	{"path": "res://ObjectScenes/kettle.tscn", "name": "THE KETTLE"},
	{"path": "res://ObjectScenes/landlord.tscn", "name": "THE LANDLORD"},
]

@onready var rooms = $Rooms
@onready var roomMat = preload("res://shaders/new_standard_material_3d.tres")
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
var runKills : int = 0
var roomWorth : int = 0
var roomSpawned : int = 0

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
	scoreLabel.text = "%d PTS   %d KILLS   %d UPGRADES" % [runScore, runKills, _upgradeCount()]

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
	roomSpawned = 0

	var boss = _isBossRoom(n)
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

	if not boss:
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
		_spawnBoss(room, data, n)
	else:
		_spawnWave(room, data, n)

	nextOriginX = x + w + ROOM_GAP

	Global.endlessRoom = n
	Global.endlessScore = runScore
	Global.endlessUpgrades = _upgradeCount()
	if n > Global.endlessBest:
		Global.endlessBest = n
		Global._localSave()
	_updateHud()

func _box(parent : Node3D, pos : Vector3, size : Vector3):
	var b = CSGBox3D.new()
	b.size = size
	b.position = pos
	parent.add_child(b)
	return b

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

func _spawnBoss(room : Node3D, data : Dictionary, n : int):
	var pick = BOSSES[rng.randi_range(0, BOSSES.size() - 1)]
	_spawn(room, load(pick["path"]), Vector3(data["x"] + data["w"] * 0.7, 2.0, 0.0), n)
	_flash(pick["name"])

func _spawn(room : Node3D, scene : PackedScene, pos : Vector3, n : int):
	var inst = scene.instantiate()
	inst.position = pos
	_wire(inst, n)
	room.add_child(inst)
	if "floorY" in inst:
		_refloor.call_deferred(inst)
	roomSpawned += 1
	if "scoreWorth" in inst:
		roomWorth += inst.scoreWorth

func _refloor(inst):
	for i in 4:
		await get_tree().physics_frame
	if is_instance_valid(inst) and inst.has_method("_floorLevel"):
		inst.floorY = inst._floorLevel()

func _enemiesLeft() -> int:
	var c = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("dead") == true:
			continue
		if e is Node3D and e.global_position.y < VOID_Y:
			if e.has_method("_takeDamage"):
				e._takeDamage(100000)
			continue
		c += 1
	return c

func _process(delta: float) -> void:
	if cleared or current == null:
		return
	pollAccum += delta
	if pollAccum < CLEAR_POLL:
		return
	pollAccum = 0.0
	if _enemiesLeft() <= 0:
		_clearRoom()

func _clearRoom():
	cleared = true
	runScore += int(roomWorth * (player.scoreMult if player else 1.0))
	runKills += roomSpawned
	_updateHud()
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
	_updateHud()

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
