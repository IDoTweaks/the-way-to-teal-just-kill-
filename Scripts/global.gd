extends Node
@onready var mainMenu = preload("res://Scenes/mainMenu.tscn")
@onready var level1 = preload("res://Scenes/level1.tscn")
@onready var level2 = preload("res://Scenes/level2.tscn")
@onready var bossArena = preload("res://Scenes/boss1Arena.tscn")
@onready var levels : Array
var currentLevel = 1

var ghostPos : Dictionary = {}
var ghostRot : Dictionary = {}
var ghostCamPos : Dictionary = {}
var ghostCamRot : Dictionary = {}
var ghostWeapon : Dictionary = {}
var ghostScore : Dictionary = {}

var grades : Array[int] = []
var times : Array = []

var masterVol := 1.0
var musicVol := 1.0
var sfxVol := 1.0
var displayMode := 1
var resIndex := 0
var sensitivity := 0.005
var scopedSens := 0.0022

const SETTINGS_RES : Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1152, 648),
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
	config.save("user://settings.cfg")

func _applySettings():
	_applyVol(0, masterVol)
	_applyVol(1, musicVol)
	_applyVol(2, sfxVol)
	_applyDisplay()

func _applyVol(bus : int, value : float):
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(bus, value <= 0.001)

func _applyDisplay():
	match displayMode:
		0:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var sz = SETTINGS_RES[clamp(resIndex, 0, SETTINGS_RES.size() - 1)]
			DisplayServer.window_set_size(sz)
			DisplayServer.window_set_position((DisplayServer.screen_get_size() - sz) / 2)
		1:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _localLoad():
	var config = ConfigFile.new()
	var err = config.load("user://save.cfg")
	if err == OK:
		grades = config.get_value("player", "grades", grades)
		times = config.get_value("player", "times", times)
		ghostPos = config.get_value("ghost", "ghostPos", ghostPos)
		ghostRot = config.get_value("ghost", "ghostRot", ghostRot)
		ghostCamPos = config.get_value("ghost", "ghostCamPos", ghostCamPos)
		ghostCamRot = config.get_value("ghost", "ghostCamRot", ghostCamRot)
		ghostWeapon = config.get_value("ghost", "ghostWeapon", ghostWeapon)
		ghostScore = config.get_value("ghost", "ghostScore", ghostScore)

func _localSave():
	var config = ConfigFile.new()
	config.set_value("player", "grades", grades)
	config.set_value("player", "times", times)
	config.set_value("ghost", "ghostPos", ghostPos)
	config.set_value("ghost", "ghostRot", ghostRot)
	config.set_value("ghost", "ghostCamPos", ghostCamPos)
	config.set_value("ghost", "ghostCamRot", ghostCamRot)
	config.set_value("ghost", "ghostWeapon", ghostWeapon)
	config.set_value("ghost", "ghostScore", ghostScore)
	config.save("user://save.cfg")

func _ready() -> void:
	levels.append(mainMenu)
	levels.append(level1)
	levels.append(level2)
	_localLoad()
	_loadSettings()

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
	_localSave()

func _ghostScore(level):
	return ghostScore.get(level, -1)

func _hasNextLevel(level):
	return level + 1 < levels.size()

func _goToLevel(idx):
	currentLevel = idx
	Audio.music_for_level(idx)
	get_tree().change_scene_to_packed(levels[idx])

func _process(delta: float) -> void:
	pass
