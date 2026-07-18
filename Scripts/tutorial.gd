extends Node3D

func _tutorial(): pass

@onready var player = $Player
@onready var objLabel = $TutorialHud/ObjectiveBox/Label

var phaseData = {}
var triggered = {}
var awaiting = false
var awaitingKills = false
var needKind = ""
var baseCount = 0
var moveStartX = 0.0
var activeGate = null
var activeEnemies = []
var phaseTotal = 0
var phaseBaseText = ""
var doneText = ""

var _enemyLayers = {}
var _openedGates = {}
var _guide : Array[MeshInstance3D] = []
var _guideT : float = 0.0
const GUIDE_COUNT = 7
const GUIDE_SPACING = 2.2
const GATE_ORDER = ["GateMove", "GateJump", "GateSlide", "GateDash", "GateWJ", "GateSlam", "GateShoot", "GateShotgun", "GateSniper", "GateOrb"]

var _ghost : MeshInstance3D
var _ghostTween : Tween
var _ghostPoints = {
	"move":[Vector3(9, 1, -3), Vector3(9, 1, 3)],
	"jump":[Vector3(17, 1, 0), Vector3(20, 2.2, 0), Vector3(23, 1, 0)],
	"slide":[Vector3(31, 0.55, 0), Vector3(40, 0.55, 0)],
	"dash":[Vector3(47, 1.6, 0), Vector3(56, 1.5, 0)],
	"walljump":[Vector3(68.5, 1, 0), Vector3(70, 2.4, -1.2), Vector3(71.5, 3.6, 1.2), Vector3(73, 2, 0), Vector3(75, 1, 0)],
	"slam":[Vector3(86, 1, 0), Vector3(86, 3.4, 0), Vector3(86, 0.5, 0)],
	"shoot":[Vector3(99, 1, 0), Vector3(99, 1.2, 0)],
	"orb":[Vector3(149, 1, 0), Vector3(152.2, 1.6, 0), Vector3(156, 5.4, 0), Vector3(160, 5.0, 0), Vector3(165, 1, 0)],
}
var _ghostSeg = {"move":1.2, "jump":0.38, "slide":0.9, "dash":0.28, "walljump":0.26, "slam":0.32, "shoot":0.1, "orb":0.34}
var _ghostPause = {"move":0.15, "jump":0.5, "slide":0.5, "dash":0.7, "walljump":0.5, "slam":0.55, "shoot":0.05, "orb":0.55}

func _ready() -> void:
	Global.currentLevel = 0
	player._setUnlockedGuns(1)
	player._setGunLock(0)
	player._setAbilities(false, false, false, false, false, false)
	_buildGhost()
	_setText("MOVE: W A S D\nWalk to the gate to begin")
	phaseData = {
		"Zone1": {"text":"MOVE: W A S D   (everything else is locked for now)\nWalk up to the gate", "ab":[false,false,false,false,false,false], "guns":1, "gunLock":0, "gate":"GateMove", "need":"move", "ghost":"move", "done":"GOOD.  Keep going"},
		"Zone2": {"text":"JUMP: SPACE\nHop over the barrier", "ab":[true,false,false,false,false,false], "guns":1, "gunLock":0, "gate":"GateJump", "need":"jump", "ghost":"jump", "done":"NICE jump!"},
		"Zone3": {"text":"SLIDE: hold CTRL while running - it keeps your momentum", "ab":[false,false,true,false,false,false], "guns":1, "gunLock":0, "gate":"GateSlide", "need":"slide", "ghost":"slide", "done":"SMOOTH."},
		"Zone4": {"text":"DASH: jump, then tap SHIFT to dash across the gap\n(each dash spends a third of STAMINA, bottom-right)", "ab":[true,true,false,false,false,false], "guns":1, "gunLock":0, "gate":"GateDash", "need":"dash", "ghost":"dash", "done":"ZOOM!"},
		"Zone5": {"text":"WALL-JUMP: jump INTO a wall, then jump again to kick off it", "ab":[true,false,false,true,false,false], "guns":1, "gunLock":0, "gate":"GateWJ", "need":"walljump", "ghost":"walljump", "done":"UP YOU GO!"},
		"Zone6": {"text":"SLAM: jump up, then press CTRL in mid-air to smash down", "ab":[true,false,true,false,true,false], "guns":1, "gunLock":0, "gate":"GateSlam", "need":"slam", "ghost":"slam", "done":"BOOM!"},
		"Zone7": {"text":"SHOOT: LEFT MOUSE\nClear the enemies", "ab":[true,false,false,false,false,true], "guns":1, "gunLock":0, "gate":"GateShoot", "need":"kill", "enemies":["E7_1","E7_2"], "ghost":"shoot", "done":"The gate is open - move on"},
		"Zone8": {"text":"SHOTGUN ONLY: it's the only weapon that'll work here\nGet close and blast them", "ab":[true,false,false,false,false,true], "guns":2, "gunLock":1, "gate":"GateShotgun", "need":"kill", "enemies":["E8_1","E8_2","E8_3"], "ghost":"shoot", "done":"BOOM.  Keep going"},
		"Zone9": {"text":"SNIPER ONLY: hold RIGHT MOUSE to scope", "ab":[true,false,false,false,false,true], "guns":3, "gunLock":2, "gate":"GateSniper", "need":"kill", "enemies":["E9_1","E9_2"], "ghost":"shoot", "done":"BULLSEYE"},
		"Zone11": {"text":"JUMP ORB: run into the glowing orb - it launches you\nUse it to clear the pit", "ab":[true,false,false,false,false,true], "guns":3, "gunLock":-1, "gate":"GateOrb", "need":"orb", "ghost":"orb", "done":"WHEEE!"},
		"Zone10": {"text":"Everything is unlocked - grab the orb to finish!", "ab":[true,true,true,true,true,true], "guns":3, "gunLock":-1, "ghost":"", "done":""},
	}
	for z in phaseData.keys():
		var node = get_node_or_null(z)
		if node:
			node.body_entered.connect(_on_zone.bind(z))
	for z in phaseData.keys():
		for n in phaseData[z].get("enemies", []):
			var e = get_node_or_null(n)
			if e:
				_setEnemyActive(e, false)
	_buildGuide()

func _setEnemyActive(e, on):
	if not is_instance_valid(e):
		return
	e.visible = on
	e.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if on:
		e.collision_layer = _enemyLayers.get(e, e.collision_layer)
	else:
		if not _enemyLayers.has(e):
			_enemyLayers[e] = e.collision_layer
		e.collision_layer = 0

func _buildGhost() -> void:
	_ghost = MeshInstance3D.new()
	var m = CapsuleMesh.new()
	m.radius = 0.4
	m.height = 1.8
	_ghost.mesh = m
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 1, 0.85, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0, 1, 0.85)
	mat.emission_energy_multiplier = 0.6
	_ghost.material_override = mat
	_ghost.visible = false
	add_child(_ghost)

func _buildGuide() -> void:
	var mesh = PrismMesh.new()
	mesh.size = Vector3(0.9, 1.1, 0.12)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = StandardMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0, 1, 0.85, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0, 1, 0.85)
	mat.emission_energy_multiplier = 3.0
	for i in GUIDE_COUNT:
		var m = MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.rotation = Vector3(deg_to_rad(90), 0, 0)
		m.visible = false
		add_child(m)
		_guide.append(m)

func _guideTarget():
	for g in GATE_ORDER:
		if _openedGates.has(g):
			continue
		var node = get_node_or_null(g)
		if node and node.visible:
			return node.global_position
	var orb = get_node_or_null("FinishOrb")
	if orb:
		return orb.global_position
	return null

func _updateGuide(delta : float) -> void:
	if _guide.is_empty() or player == null:
		return
	var targ = _guideTarget()
	if targ == null:
		for m in _guide:
			m.visible = false
		return
	var from = player.global_position
	var to = Vector3(targ.x, from.y, targ.z)
	var dir = to - from
	var dist = dir.length()
	if dist < 2.0:
		for m in _guide:
			m.visible = false
		return
	dir = dir / dist
	var yaw = atan2(dir.x, dir.z)
	_guideT = fmod(_guideT + delta * 2.4, GUIDE_SPACING)
	for i in _guide.size():
		var along = 2.0 + _guideT + i * GUIDE_SPACING
		var m = _guide[i]
		if along > dist - 0.5:
			m.visible = false
			continue
		m.visible = true
		m.global_position = from + dir * along + Vector3(0, 0.12, 0)
		m.rotation = Vector3(deg_to_rad(90), yaw, 0)
		var fade = clamp(1.0 - along / max(dist, 0.01), 0.15, 1.0)
		m.scale = Vector3.ONE * (0.7 + fade * 0.5)

func _setText(t):
	objLabel.text = t

func _on_zone(body, zoneName):
	if triggered.get(zoneName, false):
		return
	if not body.has_method("player"):
		return
	triggered[zoneName] = true
	var d = phaseData[zoneName]
	player._setUnlockedGuns(d.get("guns", 1))
	player._setGunLock(d.get("gunLock", -1))
	var ab = d.get("ab", [true, true, true, true, true, true])
	player._setAbilities(ab[0], ab[1], ab[2], ab[3], ab[4], ab[5])
	doneText = d.get("done", "")
	activeGate = get_node_or_null(d["gate"]) if d.has("gate") else null
	needKind = d.get("need", "")
	phaseBaseText = d["text"]
	_setText(phaseBaseText)
	var g = d.get("ghost", "")
	if g != "" and _ghostPoints.has(g):
		_playGhost(g)
	else:
		_hideGhost()
	awaiting = false
	awaitingKills = false
	if needKind == "kill":
		activeEnemies = []
		for n in d.get("enemies", []):
			var e = get_node_or_null(n)
			if e:
				_setEnemyActive(e, true)
				activeEnemies.append(e)
		phaseTotal = activeEnemies.size()
		awaitingKills = phaseTotal > 0
		if phaseTotal == 0 and activeGate:
			_openGate(activeGate)
	elif needKind == "move":
		moveStartX = body.global_position.x
		awaiting = true
	elif needKind != "":
		baseCount = _counterFor(needKind)
		awaiting = true

func _counterFor(kind):
	match kind:
		"jump": return player.jumpCount
		"dash": return player.dashCount
		"slide": return player.slideCount
		"walljump": return player.wallJumpCount
		"slam": return player.slamCount
		"orb": return player.orbCount
	return 0

func _process(_delta):
	_updateGuide(_delta)
	if awaiting:
		var done = false
		if needKind == "move":
			if player.global_position.x > moveStartX + 5.0:
				done = true
		elif _counterFor(needKind) > baseCount:
			done = true
		if done:
			awaiting = false
			if activeGate:
				_openGate(activeGate)
			if doneText != "":
				_setText(doneText)
			_hideGhost()
	elif awaitingKills:
		var alive = 0
		for e in activeEnemies:
			if is_instance_valid(e):
				alive += 1
		_setText("%s\n[ %d / %d ]" % [phaseBaseText, phaseTotal - alive, phaseTotal])
		if alive == 0:
			awaitingKills = false
			if activeGate:
				_openGate(activeGate)
			if doneText != "":
				_setText(doneText)
			_hideGhost()

func _playGhost(name):
	if _ghostTween:
		_ghostTween.kill()
	var pts = _ghostPoints[name]
	var seg = _ghostSeg.get(name, 0.4)
	var pause = _ghostPause.get(name, 0.4)
	_ghost.visible = true
	_ghost.position = pts[0]
	_ghostTween = create_tween().set_loops()
	_ghostTween.tween_callback(func(): _ghost.position = pts[0])
	for i in range(1, pts.size()):
		_ghostTween.tween_property(_ghost, "position", pts[i], seg)
	_ghostTween.tween_interval(pause)

func _hideGhost():
	if _ghostTween:
		_ghostTween.kill()
	if _ghost:
		_ghost.visible = false

func _openGate(gate):
	gate.visible = false
	_openedGates[gate.name] = true
	var col = gate.get_node_or_null("col")
	if col:
		col.disabled = true

func _unhandled_input(event):
	if Input.is_action_just_pressed("restart"):
		Global._restartCurrent()
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE:
		Global._finishTutorial()
