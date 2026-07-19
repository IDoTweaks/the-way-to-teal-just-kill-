extends Node3D
@export var levelIndex : int = 1
var perfectTime = 10.0
var freezer

func _ready() -> void:
	Global.currentLevel = levelIndex
	freezer = preload("res://Scripts/level_freeze.gd").new()
	add_child.call_deferred(freezer)

func _reload():
	Global._restartCurrent()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		_reload()

