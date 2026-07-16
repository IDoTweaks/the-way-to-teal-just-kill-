extends Node3D

@export var expansionRate : float = 6.0
@export var maxExpansion : float = 10.0
@export var damage : float = 15.0
var source

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_expand(delta)


func _expand(delta):
	if self.scale.x < maxExpansion:
		self.scale.x += expansionRate * delta
	if self.scale.z < maxExpansion:
		self.scale.z += expansionRate * delta
	if self.scale.z >= maxExpansion and self.scale.x >= maxExpansion:
		queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("_damage") and !body.has_method("player"):
		if source != null and body.has_method("_makeTarg"):
			body._makeTarg(source)
		body._damage(damage)
