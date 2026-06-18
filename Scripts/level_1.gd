extends Node3D
var perfectTime = 10.0
var reload = preload("res://Scenes/level1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().change_scene_to_packed(reload)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
