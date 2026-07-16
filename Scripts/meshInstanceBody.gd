extends MeshInstance3D

var orgScale : Vector3
var fillTween : Tween
var punchTween : Tween

func _ready() -> void:
	if material_override:
		material_override = material_override.duplicate()
	orgScale = scale
	_updateMat(.33)


func _updateMat(perc):
	var mat = material_override
	if mat == null:
		return
	if fillTween:
		fillTween.kill()
	var from = mat.get_shader_parameter("fill_percent")
	if from == null:
		mat.set_shader_parameter("fill_percent", perc)
		return
	fillTween = create_tween()
	fillTween.set_trans(Tween.TRANS_CUBIC)
	fillTween.set_ease(Tween.EASE_OUT)
	fillTween.tween_method(
		func(v): mat.set_shader_parameter("fill_percent", v), float(from), float(perc), .18)

func _hitPunch():
	if punchTween:
		punchTween.kill()
	scale = orgScale * 1.16
	punchTween = create_tween()
	punchTween.set_trans(Tween.TRANS_BACK)
	punchTween.set_ease(Tween.EASE_OUT)
	punchTween.tween_property(self, "scale", orgScale, .16)

func _killTweens():
	if fillTween:
		fillTween.kill()
	if punchTween:
		punchTween.kill()
