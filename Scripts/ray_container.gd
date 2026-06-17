extends Node3D

@export var spread : float = 5
@onready var children = self.get_children()
@onready var orgPos : Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for ray in children:
		if ray is RayCast3D:
			orgPos.append(ray.target_position.x)
			orgPos.append(ray.target_position.y)
	randomizeRays()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func randomizeRays():
	var i : int = 0
	for ray in children:
		if ray is RayCast3D:
			ray.target_position.x = orgPos[i] + randf_range(-spread,spread)
			i+=1
			ray.target_position.y = orgPos[i] + randf_range(-spread,spread)
			i+=1
