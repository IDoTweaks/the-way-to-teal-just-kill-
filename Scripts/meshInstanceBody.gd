extends MeshInstance3D


func _process(delta):
	pass
	
func _ready() -> void:pass
		
		
func _updateMat(perc):
	var mat = material_override
	if mat:
		mat.set_shader_parameter("fill_percent", perc)
