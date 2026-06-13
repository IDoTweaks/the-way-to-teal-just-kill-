extends CSGCombiner3D

func _ready() -> void:
	# 1. Check if a material exists, then duplicate it so it's unique to this instance
	if material_override:
		material_override = material_override.duplicate()
		
	_updateMat(.33)
		
		
func _updateMat(perc):
	var mat = material_override
	if mat:
		mat.set_shader_parameter("fill_percent", perc)
