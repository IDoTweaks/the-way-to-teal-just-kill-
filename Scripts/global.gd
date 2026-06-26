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
	levels.append(bossArena)
	_localLoad()

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
	get_tree().change_scene_to_packed(levels[idx])

func _process(delta: float) -> void:
	pass
