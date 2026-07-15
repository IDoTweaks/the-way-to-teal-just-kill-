extends Node3D

@onready var player = $Player
@onready var objLabel = $TutorialHud/ObjectiveBox/Label

var phaseData = {}
var triggered = {}
var awaitingKills = false
var activeEnemies = []
var activeGate = null
var phaseBaseText = ""
var phaseTotal = 0
var doneText = ""

func _ready() -> void:
	Global.currentLevel = 0
	player._setUnlockedGuns(1)
	_setText("MOVE: W A S D      JUMP: SPACE\nHead right to begin")
	phaseData = {
		"Zone1": {"text":"MOVE: W A S D      JUMP: SPACE\nReach the next marker", "guns":1},
		"Zone2": {"text":"SLIDE: CTRL while moving      DASH: SHIFT\nWatch STAMINA (bottom-right): each dash spends a third, it refills when you stop", "guns":1},
		"Zone3": {"text":"WALL-JUMP: JUMP into a wall      SLAM: SLIDE in mid-air\nThese drain STAMINA too - don't run dry mid-air", "guns":1},
		"Zone4": {"text":"SHOOT: LEFT MOUSE\nKill the enemies", "guns":1, "enemies":["P4_1","P4_2"], "gate":"Gate4", "done":"NICE.  The gate is open - move on"},
		"Zone5": {"text":"SWITCH WEAPON: SCROLL WHEEL  or  1 / 2 / 3\nGet close and use the SHOTGUN", "guns":2, "enemies":["P5_1","P5_2","P5_3"], "gate":"Gate5", "done":"BOOM.  Keep going"},
		"Zone6": {"text":"Switch to the SNIPER      SCOPE: hold RIGHT MOUSE\nUnscoped shots are wild - scope to land them", "guns":3, "enemies":["P6_1","P6_2"], "gate":"Gate6", "done":"BULLSEYE.  Onward"},
		"Zone7": {"text":"STYLE: kill fast, airborne, and with varied weapons\nWatch the meter - clear them with STYLE!", "guns":3, "enemies":["P7_1","P7_2","P7_3","P7_4"], "gate":"Gate7", "done":"STYLISH!  Grab the orb to finish"},
	}
	for z in phaseData.keys():
		var node = get_node_or_null(z)
		if node:
			node.body_entered.connect(_on_zone.bind(z))

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
	if d.has("enemies"):
		activeEnemies = []
		for n in d["enemies"]:
			var e = get_node_or_null(n)
			if e:
				activeEnemies.append(e)
		activeGate = get_node_or_null(d.get("gate", ""))
		doneText = d.get("done", "")
		phaseBaseText = d["text"]
		phaseTotal = activeEnemies.size()
		awaitingKills = phaseTotal > 0
		_setText(phaseBaseText)
	else:
		_setText(d["text"])

func _process(_delta):
	if awaitingKills:
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

func _openGate(gate):
	gate.visible = false
	var col = gate.get_node_or_null("col")
	if col:
		col.disabled = true

func _unhandled_input(event):
	if Input.is_action_just_pressed("restart"):
		Global._goToTutorial()
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE:
		Global._finishTutorial()
