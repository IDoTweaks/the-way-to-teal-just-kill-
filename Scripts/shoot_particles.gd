extends GPUParticles3D


func _ready() -> void:
	pass



func _on_finished() -> void:
	queue_free()
