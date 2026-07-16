extends Node3D

@export var jumpForce: float = 14
@export var cooldown: float = .4
@export var keepHorizontal: bool = true
var onCd := false
@onready var pickupParticles = preload("res://Particles/pickupBurst.tscn")
@onready var orbMeshes = [$MeshInstance3D, $MeshInstance3D2]
var orgScales : Array = []

func _ready() -> void:
	for m in orbMeshes:
		orgScales.append(m.scale)

func _on_jump_area_body_entered(body: Node3D) -> void:
	if onCd:
		return
	if body.has_method("player"):
		_launch(body)

func _launch(body: Node3D) -> void:
	onCd = true
	Audio.play("pickup", 1.0, -3.0)
	var burst = pickupParticles.instantiate()
	get_parent().add_child(burst)
	burst.global_position = global_position
	burst.emitting = true
	if keepHorizontal:
		body.velocity.y = jumpForce
	else:
		body.velocity = Vector3(0, jumpForce, 0)
	_scaleOrb(0.3, .1)

	await get_tree().create_timer(cooldown).timeout
	if !is_inside_tree():
		return
	onCd = false
	_scaleOrb(1.0, .25)
	Audio.play("pickup", 1.9, -18.0)

func _scaleOrb(mult : float, time : float):
	if !is_inside_tree():
		return
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	for i in orbMeshes.size():
		tw.tween_property(orbMeshes[i], "scale", orgScales[i] * mult, time)
