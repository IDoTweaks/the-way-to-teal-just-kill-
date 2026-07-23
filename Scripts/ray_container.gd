extends Node3D

@export var spread : float = 5
@onready var children = self.get_children()
@onready var orgPos : Array

func _ready() -> void:
	for ray in children:
		if ray is RayCast3D:
			orgPos.append(ray.target_position.x)
			orgPos.append(ray.target_position.y)
	randomizeRays()



func addRay():
	var src = null
	for ray in children:
		if ray is RayCast3D:
			src = ray
			break
	if src == null or orgPos.size() < 2:
		return
	var extra = src.duplicate()
	add_child(extra)
	children = get_children()
	orgPos.append(orgPos[0])
	orgPos.append(orgPos[1])
	extra.enabled = src.enabled
	randomizeRays()


func randomizeRays():
	var i : int = 0
	for ray in children:
		if ray is RayCast3D:
			ray.target_position.x = orgPos[i] + randf_range(-spread,spread)
			i+=1
			ray.target_position.y = orgPos[i] + randf_range(-spread,spread)
			i+=1
