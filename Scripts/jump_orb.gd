extends Node3D

@export var jumpForce: float = 14
@export var cooldown: float = .4
@export var keepHorizontal: bool = true
var onCd := false

func _on_jump_area_body_entered(body: Node3D) -> void:
	if onCd:
		return
	if body.has_method("player"):
		_launch(body)

func _launch(body: Node3D) -> void:
	onCd = true
	if keepHorizontal:
		body.velocity.y = jumpForce
	else:
		body.velocity = Vector3(0, jumpForce, 0)

	await get_tree().create_timer(cooldown).timeout
	onCd = false
