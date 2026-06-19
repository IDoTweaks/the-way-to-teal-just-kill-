extends Node3D

@export var expansionRate : float = 0.1
@export var maxExpansion : float = 10.0
@export var damage : int = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_expand()


func _expand():
	if self.scale.x < maxExpansion:
		self.scale.x += expansionRate
	if self.scale.z < maxExpansion:
		self.scale.z += expansionRate
	if self.scale.z >= maxExpansion and self.scale.x >= maxExpansion:
		queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("_damage"):
		body._damage(damage)
