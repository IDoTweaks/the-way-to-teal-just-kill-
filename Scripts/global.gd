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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	levels.append(mainMenu);
	levels.append(level1)
	levels.append(level2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
