extends Node3D
@export var toLevel: int
var canvas
var open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_finish_area_body_entered(body: Node3D) -> void:
	if open and body.has_method("player"):
		canvas.visible = true

func _finishLevel():
	var level = Global.levels[toLevel]
	get_tree().change_scene_to_packed(level)
