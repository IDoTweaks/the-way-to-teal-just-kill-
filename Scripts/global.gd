extends Node
var _fade : ColorRect
var _fading := false
var _loading : Control
var _loadTitle : Label
var _loadSub : Label
var _loadBar : ColorRect
var _loadTween : Tween
var _loadStart : int = 0
const LOADING_MIN_MS = 450
const LOADING_SETTLE_FRAMES = 6
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
@onready var endlessScene = preload("res://Scenes/endless.tscn")
@onready var levels : Array
var bossLevels : Array = []
var bossNames : Dictionary = {}
var currentLevel = 1
var maxUnlocked = 1
var tutorialComplete := false
var menuTourPending := false
var storySeen : Dictionary = {}

var inTutorial := false
var endlessRun := false
var endlessSeed := 0
var endlessRoom := 0
var endlessBest := 0
var endlessScore := 0
var endlessKills := 0
var endlessUpgrades := 0

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
var musicVol := 0.3
var sfxVol := 1.0
var displayMode := 1
var resIndex := 1
var sensitivity := 0.005
var scopedSens := 0.0022
var fov := 75.0
var screenShake := 1.0
var reducedFlash := false
var renderScale := 1.0
var glowOn := true
var decalDensity := 1.0
var fpsCap := 0
var invertY := false
var toggleScope := false
var toggleSlide := false
var showGhost := true
var toonOutlines := true

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
		renderScale = config.get_value("graphics", "renderScale", renderScale)
		glowOn = config.get_value("graphics", "glow", glowOn)
		decalDensity = config.get_value("graphics", "decalDensity", decalDensity)
		fpsCap = config.get_value("graphics", "fpsCap", fpsCap)
		invertY = config.get_value("controls", "invertY", invertY)
		toggleScope = config.get_value("controls", "toggleScope", toggleScope)
		toggleSlide = config.get_value("controls", "toggleSlide", toggleSlide)
		showGhost = config.get_value("gameplay", "showGhost", showGhost)
		toonOutlines = config.get_value("graphics", "toonOutlines", toonOutlines)
		keybinds = config.get_value("controls", "keybinds", keybinds)
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
	config.set_value("graphics", "renderScale", renderScale)
	config.set_value("graphics", "glow", glowOn)
	config.set_value("graphics", "decalDensity", decalDensity)
	config.set_value("graphics", "fpsCap", fpsCap)
	config.set_value("controls", "invertY", invertY)
	config.set_value("controls", "toggleScope", toggleScope)
	config.set_value("controls", "toggleSlide", toggleSlide)
	config.set_value("gameplay", "showGhost", showGhost)
	config.set_value("graphics", "toonOutlines", toonOutlines)
	config.set_value("controls", "keybinds", keybinds)
	config.save("user://settings.cfg")

func _resetDefaultsNoSave():
	masterVol = 1.0
	musicVol = 0.3
	sfxVol = 1.0
	displayMode = 1
	resIndex = 0
	sensitivity = 0.005
	scopedSens = 0.0022
	fov = 75.0
	screenShake = 1.0
	reducedFlash = false
	renderScale = 1.0
	glowOn = true
	decalDensity = 1.0
	fpsCap = 0
	invertY = false
	toggleScope = false
	toggleSlide = false
	showGhost = true
	toonOutlines = true
	resIndex = 1
	_applySettings()

func _resetDefaults():
	_resetDefaultsNoSave()
	_saveSettings()

func _applySettings():
	_applyVol(0, masterVol)
	_applyVol(1, musicVol)
	_applyVol(2, sfxVol)
	_applyDisplay()
	_applyGraphics()
	_applyKeybinds()

func _applyGraphics():
	Engine.max_fps = fpsCap
	var tree = get_tree()
	if tree == null:
		return
	var vp = tree.root
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2 if renderScale < 0.999 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = renderScale
	_applyGlow()

func _applyGlow():
	var tree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	for env in _findEnvs(tree.current_scene):
		if env.environment:
			env.environment.glow_enabled = glowOn

func _findEnvs(node : Node, out : Array = []) -> Array:
	if node is WorldEnvironment:
		out.append(node)
	for c in node.get_children():
		_findEnvs(c, out)
	return out

const REBINDABLE = {
	"forward": "MOVE FORWARD", "backward": "MOVE BACK", "left": "MOVE LEFT", "right": "MOVE RIGHT",
	"jump": "JUMP", "dash": "DASH", "slide": "SLIDE / SLAM", "shoot": "SHOOT", "scope": "SCOPE",
	"gun1": "RIFLE", "gun2": "SHOTGUN", "gun3": "SNIPER", "restart": "RESTART LEVEL",
}
var keybinds : Dictionary = {}
var _defaultBinds : Dictionary = {}

func _captureDefaultBinds():
	if not _defaultBinds.is_empty():
		return
	for action in REBINDABLE:
		if InputMap.has_action(action):
			_defaultBinds[action] = InputMap.action_get_events(action).duplicate()

func _applyKeybinds():
	_captureDefaultBinds()
	for action in REBINDABLE:
		if not InputMap.has_action(action):
			continue
		if not keybinds.has(action):
			continue
		InputMap.action_erase_events(action)
		var ev = _eventFromDict(keybinds[action])
		if ev != null:
			InputMap.action_add_event(action, ev)

func _rebind(action : String, event : InputEvent) -> bool:
	if not InputMap.has_action(action):
		return false
	var d = _eventToDict(event)
	if d.is_empty():
		return false
	var oldEvents = InputMap.action_get_events(action)
	var oldEvent = oldEvents[0] if oldEvents.size() > 0 else null
	for other in REBINDABLE:
		if other == action or not InputMap.has_action(other):
			continue
		var taken = false
		for e in InputMap.action_get_events(other):
			if _eventToDict(e) == d:
				taken = true
				break
		if not taken:
			continue
		InputMap.action_erase_events(other)
		if oldEvent != null:
			InputMap.action_add_event(other, oldEvent)
			keybinds[other] = _eventToDict(oldEvent)
		else:
			keybinds.erase(other)
	keybinds[action] = d
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	return true

func _resetKeybinds(save : bool = true):
	_captureDefaultBinds()
	keybinds.clear()
	for action in _defaultBinds:
		InputMap.action_erase_events(action)
		for ev in _defaultBinds[action]:
			InputMap.action_add_event(action, ev)
	if save:
		_saveSettings()

func _eventToDict(event : InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"t": "k", "c": event.physical_keycode if event.physical_keycode != 0 else event.keycode}
	if event is InputEventMouseButton:
		return {"t": "m", "c": event.button_index}
	return {}

func _eventFromDict(d) -> InputEvent:
	if typeof(d) != TYPE_DICTIONARY:
		return null
	if d.get("t", "") == "k":
		var k = InputEventKey.new()
		k.physical_keycode = int(d.get("c", 0))
		return k
	if d.get("t", "") == "m":
		var m = InputEventMouseButton.new()
		m.button_index = int(d.get("c", 1))
		return m
	return null

func _bindLabel(action : String) -> String:
	if not InputMap.has_action(action):
		return "-"
	var evs = InputMap.action_get_events(action)
	if evs.is_empty():
		return "UNBOUND"
	var e = evs[0]
	if e is InputEventKey:
		var code = e.physical_keycode if e.physical_keycode != 0 else e.keycode
		return OS.get_keycode_string(code)
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_LEFT: return "MOUSE 1"
			MOUSE_BUTTON_RIGHT: return "MOUSE 2"
			MOUSE_BUTTON_MIDDLE: return "MOUSE 3"
			MOUSE_BUTTON_WHEEL_UP: return "WHEEL UP"
			MOUSE_BUTTON_WHEEL_DOWN: return "WHEEL DOWN"
		return "MOUSE %d" % e.button_index
	return "?"

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
		storySeen = config.get_value("player", "storySeen", storySeen)
		endlessBest = config.get_value("player", "endlessBest", endlessBest)
	_loadGhosts()

func _localSave():
	var config = ConfigFile.new()
	config.set_value("player", "grades", grades)
	config.set_value("player", "times", times)
	config.set_value("player", "maxUnlocked", maxUnlocked)
	config.set_value("player", "tutorialComplete", tutorialComplete)
	config.set_value("player", "bestTimes", bestTimes)
	config.set_value("player", "levelTries", levelTries)
	config.set_value("player", "storySeen", storySeen)
	config.set_value("player", "endlessBest", endlessBest)
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
	_buildLoading()

func _buildLoading():
	var layer = CanvasLayer.new()
	layer.layer = 129
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	_loading = Control.new()
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.process_mode = Node.PROCESS_MODE_ALWAYS
	_loading.visible = false
	layer.add_child(_loading)

	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.19, 0.22, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.add_child(bg)

	_loading.theme = load("res://UI/funkyTheme.tres")

	_loadTitle = Label.new()
	_loadTitle.set_anchors_preset(Control.PRESET_CENTER)
	_loadTitle.offset_left = -460
	_loadTitle.offset_right = 460
	_loadTitle.offset_top = -110
	_loadTitle.offset_bottom = -30
	_loadTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loadTitle.theme_type_variation = "Display"
	_loading.add_child(_loadTitle)

	_loadSub = Label.new()
	_loadSub.set_anchors_preset(Control.PRESET_CENTER)
	_loadSub.offset_left = -460
	_loadSub.offset_right = 460
	_loadSub.offset_top = 40
	_loadSub.offset_bottom = 84
	_loadSub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loadSub.theme_type_variation = "H2"
	_loading.add_child(_loadSub)

	var track = ColorRect.new()
	track.color = Color(0.03, 0.13, 0.15, 1)
	track.set_anchors_preset(Control.PRESET_CENTER)
	track.offset_left = -260
	track.offset_right = 260
	track.offset_top = 108
	track.offset_bottom = 114
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.add_child(track)

	_loadBar = ColorRect.new()
	_loadBar.color = Color(0, 0.85, 0.78, 1)
	_loadBar.set_anchors_preset(Control.PRESET_CENTER)
	_loadBar.offset_top = 108
	_loadBar.offset_bottom = 114
	_loadBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.add_child(_loadBar)

func _levelLabel(idx) -> String:
	if endlessRun:
		return "ENDLESS"
	if idx == 0:
		return "MAIN MENU"
	if _isBoss(idx):
		return _bossName(idx)
	return "LEVEL %d" % idx

func _showLoading(title : String):
	if _loading == null:
		return
	_loadTitle.text = "LOADING"
	_loadSub.text = title
	_loading.visible = true
	_loadStart = Time.get_ticks_msec()
	if _loadTween:
		_loadTween.kill()
	_loadBar.offset_left = -260
	_loadBar.offset_right = -180
	_loadTween = create_tween().set_loops()
	_loadTween.tween_method(_setLoadBar, -260.0, 180.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_loadTween.tween_method(_setLoadBar, 180.0, -260.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setLoadBar(x : float):
	if _loadBar:
		_loadBar.offset_left = x
		_loadBar.offset_right = x + 80.0

func _hideLoading():
	if _loading == null:
		return
	var held = Time.get_ticks_msec() - _loadStart
	if held < LOADING_MIN_MS:
		await get_tree().create_timer((LOADING_MIN_MS - held) / 1000.0).timeout
	if _loadTween:
		_loadTween.kill()
		_loadTween = null
	_loading.visible = false

func _settleFrames():
	for i in LOADING_SETTLE_FRAMES:
		await get_tree().process_frame

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
	endlessRun = false
	inTutorial = false
	currentLevel = idx
	await _fadeTo(1.0, .2)
	_showLoading(_levelLabel(idx))
	Audio.music_for_level(idx)
	get_tree().change_scene_to_packed(levels[idx])
	await _settleFrames()
	_applyGlow()
	await _hideLoading()
	_fading = false
	await _fadeTo(0.0, .3)

func _restartCurrent():
	var scn = get_tree().current_scene
	if scn != null and scn.has_method("_tutorial"):
		_goToTutorial()
	elif scn != null and scn.has_method("_endless"):
		_goToEndless(endlessSeed)
	else:
		_goToLevel(currentLevel)

func _seedFrom(txt : String) -> int:
	txt = txt.strip_edges()
	if txt == "":
		return randi()
	if txt.is_valid_int():
		return abs(txt.to_int())
	return abs(hash(txt.to_upper()))

func _goToEndless(seedVal : int):
	if _fading:
		return
	_fading = true
	endlessRun = true
	endlessSeed = seedVal
	endlessRoom = 0
	await _fadeTo(1.0, .2)
	_showLoading("ENDLESS")
	Audio.music_for_level(1)
	get_tree().change_scene_to_packed(endlessScene)
	await _settleFrames()
	_applyGlow()
	await _hideLoading()
	_fading = false
	await _fadeTo(0.0, .3)

func _goToTutorial():
	if _fading:
		return
	_fading = true
	inTutorial = true
	await _fadeTo(1.0, .2)
	_showLoading("TUTORIAL")
	Audio.music_for_level(0)
	get_tree().change_scene_to_packed(tutorial)
	await _settleFrames()
	_applyGlow()
	await _hideLoading()
	_fading = false
	await _fadeTo(0.0, .3)

func _finishTutorial():
	tutorialComplete = true
	_localSave()
	menuTourPending = true
	_goToLevel(0)

