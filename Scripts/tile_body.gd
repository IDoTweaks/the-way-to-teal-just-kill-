extends StaticBody3D
@onready var deathArea = $deathArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _activate(type : int):
	deathArea._activate(type)
