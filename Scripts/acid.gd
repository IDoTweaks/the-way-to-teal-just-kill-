extends Node3D


func _ready() -> void:
	var mat = $MeshInstance3D.material_override
	if mat:
		mat.set_shader_parameter("emission_intensity", 1.4 if Global.reducedFlash else 2.5)




func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		body._takeDamage(1000, global_position)
