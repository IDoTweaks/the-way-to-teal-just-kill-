extends Node3D
@export var levelIndex : int = 1
var perfectTime = 10.0

func _ready() -> void:
	Global.currentLevel = levelIndex

func _reload():
	Global._goToLevel(Global.currentLevel)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		_reload()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
