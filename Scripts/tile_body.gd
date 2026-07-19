extends StaticBody3D
@onready var deathArea = $deathArea

func _ready() -> void:
	pass

func _activate(type : int):
	deathArea._activate(type)
