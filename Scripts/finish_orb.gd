extends Node3D
@export var toLevel: int
var canvas
var open = false
@export var player: CharacterBody3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_finish_area_body_entered(body: Node3D) -> void:
	if open and body.has_method("player"):
		open = false
		player._finishLevel()

func _finishLevel():
	var level = Global.levels[toLevel]
	get_tree().change_scene_to_packed(level)
