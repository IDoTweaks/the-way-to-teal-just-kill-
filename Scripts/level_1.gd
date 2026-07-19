extends Node3D
@export var levelIndex : int = 1
var perfectTime = 10.0
var freezer

func _ready() -> void:
	Global.currentLevel = levelIndex
	Story._spawn.call_deferred(self, levelIndex, _startFreeze)

func _startFreeze():
	freezer = preload("res://Scripts/level_freeze.gd").new()
	add_child(freezer)

func _reload():
	Global._restartCurrent()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		_reload()
