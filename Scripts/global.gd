extends Node
var _fade : ColorRect
var _fading := false
@onready var mainMenu = preload("res://Scenes/mainMenu.tscn")
@onready var level1 = preload("res://Scenes/level1.tscn")
@onready var level2 = preload("res://Scenes/level2.tscn")
@onready var level3 = preload("res://Scenes/level3.tscn")
@onready var level4 = preload("res://Scenes/level4.tscn")
@onready var level5 = preload("res://Scenes/level5.tscn")
@onready var level6 = preload("res://Scenes/level6.tscn")
@onready var level7 = preload("res://Scenes/level7.tscn")
@onready var level8 = preload("res://Scenes/level8.tscn")
@onready var level9 = preload("res://Scenes/level9.tscn")
@onready var snakeBoss = preload("res://Scenes/bossFloor.tscn")
@onready var tutorial = preload("res://Scenes/tutorial.tscn")
@onready var levels : Array
var bossLevels : Array = []
var bossNames : Dictionary = {}
var currentLevel = 1
var maxUnlocked = 1
var tutorialComplete := false

const GHOST_FILE = "user://ghosts.dat"
const GHOST_VERSION = 1
const GHOST_HZ = 20.0

var ghostPos : Dictionary = {}
var ghostRot : Dictionary = {}
var ghostCamPos : Dictionary = {}
var ghostCamRot : Dictionary = {}
var ghostWeapon : Dictionary = {}
var ghostScore : Dictionary = {}

var grades : Array[int] = []
var times : Array = []
var bestTimes : Dictionary = {}
var levelTries : Dictionary = {}

var masterVol := 1.0
var musicVol := 1.0
var sfxVol := 1.0
var displayMode := 1
var resIndex := 1
var sensitivity := 0.005
var scopedSens := 0.0022
var fov := 75.0
var screenShake := 1.0
var reducedFlash := false

const SETTINGS_RES : Array[Vector2i] = [
	Vector2i(2560, 1440),
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1152, 648),
	Vector2i(1024, 576),
	Vector2i(960, 540),
]

func _loadSettings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		masterVol = config.get_value("audio", "master", masterVol)
		musicVol = config.get_value("audio", "music", musicVol)
		sfxVol = config.get_value("audio", "sfx", sfxVol)
		displayMode = config.get_value("display", "mode", displayMode)
		resIndex = config.get_value("display", "res", resIndex)
		sensitivity = config.get_value("controls", "sensitivity", sensitivity)
		scopedSens = config.get_value("controls", "scopedSens", scopedSens)
		fov = config.get_value("display", "fov", fov)
		screenShake = config.get_value("display", "screenShake", screenShake)
		reducedFlash = config.get_value("display", "reducedFlash", reducedFlash)
	_applySettings()

func _saveSettings():
	var config = ConfigFile.new()
	config.set_value("audio", "master", masterVol)
	config.set_value("audio", "music", musicVol)
	config.set_value("audio", "sfx", sfxVol)
	config.set_value("display", "mode", displayMode)
	config.set_value("display", "res", resIndex)
	config.set_value("controls", "sensitivity", sensitivity)
	config.set_value("controls", "scopedSens", scopedSens)
	config.set_value("display", "fov", fov)
	config.set_value("display", "screenShake", screenShake)
	config.set_value("display", "reducedFlash", reducedFlash)
	config.save("user://settings.cfg")

func _resetDefaults():
	masterVol = 1.0
	musicVol = 1.0
	sfxVol = 1.0
	displayMode = 1
	resIndex = 0
	sensitivity = 0.005
	scopedSens = 0.0022
	fov = 75.0
	screenShake = 1.0
	reducedFlash = false
	resIndex = 1
	_applySettings()
	_saveSettings()

func _applySettings():
	_applyVol(0, masterVol)
	_applyVol(1, musicVol)
	_applyVol(2, sfxVol)
	_applyDisplay()

func _applyVol(bus : int, value : float):
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(bus, value <= 0.001)

func _applyDisplay():
	if OS.has_feature("web"):
		return
	match displayMode:
		0:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var scr = DisplayServer.window_get_current_screen()
			var sz = _windowedSize(SETTINGS_RES[clamp(resIndex, 0, SETTINGS_RES.size() - 1)])
			DisplayServer.window_set_size(sz)
			DisplayServer.window_set_position(DisplayServer.screen_get_position(scr) + (DisplayServer.screen_get_size(scr) - sz) / 2)
		1:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _windowedSize(sz : Vector2i) -> Vector2i:
	var scr = DisplayServer.window_get_current_screen()
	var avail = DisplayServer.screen_get_size(scr)
	if avail.x <= 0 or avail.y <= 0:
		return sz
	var maxW = int(avail.x * 0.95)
	var maxH = int(avail.y * 0.90)
	if sz.x <= maxW and sz.y <= maxH:
		return sz
	var ratio = min(float(maxW) / float(sz.x), float(maxH) / float(sz.y))
	return Vector2i(int(sz.x * ratio), int(sz.y * ratio))

func _localLoad():
	var config = ConfigFile.new()
	var err = config.load("user://save.cfg")
	if err == OK:
		grades = config.get_value("player", "grades", grades)
		times = config.get_value("player", "times", times)
		maxUnlocked = config.get_value("player", "maxUnlocked", maxUnlocked)
		tutorialComplete = config.get_value("player", "tutorialComplete", tutorialComplete)
		bestTimes = config.get_value("player", "bestTimes", bestTimes)
		levelTries = config.get_value("player", "levelTries", levelTries)
	_loadGhosts()

func _localSave():
	var config = ConfigFile.new()
	config.set_value("player", "grades", grades)
	config.set_value("player", "times", times)
	config.set_value("player", "maxUnlocked", maxUnlocked)
	config.set_value("player", "tutorialComplete", tutorialComplete)
	config.set_value("player", "bestTimes", bestTimes)
	config.set_value("player", "levelTries", levelTries)
	config.save("user://save.cfg")

func _loadGhosts():
	var f = FileAccess.open(GHOST_FILE, FileAccess.READ)
	if f == null:
		return
	var data = f.get_var()
	f.close()
	if typeof(data) != TYPE_DICTIONARY or data.get("v", 0) != GHOST_VERSION:
		return
	ghostPos = data.get("pos", {})
	ghostRot = data.get("rot", {})
	ghostCamPos = data.get("camPos", {})
	ghostCamRot = data.get("camRot", {})
	ghostWeapon = data.get("weapon", {})
	ghostScore = data.get("score", {})

func _saveGhosts():
	var f = FileAccess.open(GHOST_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({
		"v": GHOST_VERSION,
		"pos": ghostPos,
		"rot": ghostRot,
		"camPos": ghostCamPos,
		"camRot": ghostCamRot,
		"weapon": ghostWeapon,
		"score": ghostScore,
	})
	f.close()

func _ready() -> void:
	levels.append(mainMenu)
	levels.append(level1)
	levels.append(level2)
	levels.append(level3)
	levels.append(level4)
	levels.append(level5)
	levels.append(level6)
	levels.append(level7)
	levels.append(level8)
	levels.append(level9)
	levels.append(snakeBoss)
	bossLevels = [levels.find(snakeBoss)]
	bossNames = {levels.find(snakeBoss): "THE SNAKE"}
	_localLoad()
	_loadSettings()
	_buildFade()

func _buildFade():
	var layer = CanvasLayer.new()
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_fade)

func _fadeTo(a : float, t : float):
	if _fade == null:
		return
	var tw = _fade.create_tween()
	tw.tween_property(_fade, "color:a", a, t)
	await tw.finished

func _isBoss(idx):
	return bossLevels.has(idx)

func _bossName(idx):
	return bossNames.get(idx, "BOSS")

func _snakeLevel():
	return levels.find(snakeBoss)

func _addRun(score, time):
	grades.append(score)
	times.append(time)

func _saveGhost(level, pos, rot, camPos, camRot, weapon, score):
	ghostPos[level] = pos
	ghostRot[level] = rot
	ghostCamPos[level] = camPos
	ghostCamRot[level] = camRot
	ghostWeapon[level] = weapon
	ghostScore[level] = score
	_saveGhosts()

func _ghostScore(level):
	return ghostScore.get(level, -1)

func _hasNextLevel(level):
	return level + 1 < levels.size()

func _completeLevel(level):
	if level + 1 > maxUnlocked:
		maxUnlocked = level + 1

func _isUnlocked(level):
	return level <= maxUnlocked

func _bestTime(level):
	return bestTimes.get(level, -1.0)

func _tries(level):
	return levelTries.get(level, 0)

func _addTry(level):
	levelTries[level] = _tries(level) + 1

func _recordTime(level, t):
	if not bestTimes.has(level) or t < bestTimes[level]:
		bestTimes[level] = t

func _goToLevel(idx):
	if _fading:
		return
	_fading = true
	currentLevel = idx
	await _fadeTo(1.0, .2)
	Audio.music_for_level(idx)
	get_tree().change_scene_to_packed(levels[idx])
	await get_tree().process_frame
	_fading = false
	await _fadeTo(0.0, .3)

func _goToTutorial():
	if _fading:
		return
	_fading = true
	await _fadeTo(1.0, .2)
	Audio.music_for_level(0)
	get_tree().change_scene_to_packed(tutorial)
	await get_tree().process_frame
	_fading = false
	await _fadeTo(0.0, .3)

func _finishTutorial():
	tutorialComplete = true
	_localSave()
	_goToLevel(1)

