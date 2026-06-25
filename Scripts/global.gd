extends Node
@onready var mainMenu = preload("res://Scenes/mainMenu.tscn")
@onready var level1 = preload("res://Scenes/level1.tscn")
@onready var level2 = preload("res://Scenes/boss1Arena.tscn")
@onready var levels : Array
var currentLevel = 1

var positionSave : Array[Vector3] = []
var rotationSave : Array[Vector3] = []
var camPositionSave : Array[Vector3] = []
var camRotationSave : Array[Vector3] = []
var weaponSave : Array[int] = []
var maxScore = -1;

var grades : Array[int] = []
var times : Array = []

func _localLoad():
	var config = ConfigFile.new()
	var err = config.load("user://save.cfg")
	if err == OK:
		print("loaded")
		grades = config.get_value("player", "grades", grades)
		times = config.get_value("player", "times",times)
		positionSave = config.get_value("ghost","positionSave",positionSave)
		rotationSave =config.get_value("ghost","rotationSave",rotationSave)
		camPositionSave = config.get_value("ghost","camPositionSave",camPositionSave)
		camRotationSave = config.get_value("ghost","camRotationSave",camRotationSave)
		maxScore = config.get_value("ghost", "maxScore", -1)
		weaponSave = config.get_value("ghost", "weaponSave", weaponSave)


func _localSave():
	var config = ConfigFile.new()
	config.set_value("player", "grades", grades)
	config.set_value("player", "times",times)
	config.set_value("ghost","positionSave",positionSave)
	config.set_value("ghost","rotationSave",rotationSave)
	config.set_value("ghost","camPositionSave",camPositionSave)
	config.set_value("ghost","camRotationSave",camRotationSave)
	config.set_value("ghost", "maxScore", maxScore)
	config.set_value("ghost", "weaponSave", weaponSave)
	config.save("user://save.cfg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	levels.append(mainMenu);
	levels.append(level1)
	levels.append(level2)
	_localLoad()

func _addRun(score,time):
	grades.append(score)
	times.append(time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
