extends Node3D

@export var warnTime : float = 1.2
@export var damage : int = 14
@export var knockback : float = 11.0
@export var growTime : float = .18

var t : float = 0.0
var fired = false
var inside : Array = []
var orgScale : Vector3

@onready var ring = $ringMesh
@onready var fill = $fillMesh
@onready var burstParticles = preload("res://Particles/slamImpact.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")

var ringMat : StandardMaterial3D
var fillMat : StandardMaterial3D

func _ready() -> void:
	orgScale = scale
	scale = orgScale * .2
	if ring.material_override:
		ring.material_override = ring.material_override.duplicate()
		ringMat = ring.material_override
	if fill.material_override:
		fill.material_override = fill.material_override.duplicate()
		fillMat = fill.material_override
	fill.scale = Vector3(.02, 1, .02)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", orgScale, growTime)
	Audio.play("ui_hover", .7, -18.0)

func _process(delta: float) -> void:
	if fired:
		return
	t += delta
	var f = clamp(t / warnTime, 0.0, 1.0)
	fill.scale = Vector3(max(f, .02), 1, max(f, .02))
	rotation.y += delta * 1.6
	if fillMat != null:
		fillMat.emission_energy_multiplier = 1.0 + f * 5.0
	if ringMat != null:
		var pulse = 1.0 + sin(t * lerp(8.0, 34.0, f)) * .5
		ringMat.emission_energy_multiplier = 1.5 + pulse * f * 3.0
	if t >= warnTime:
		_erupt()

func _erupt():
	fired = true
	Audio.play("slam", 1.05, -3.0)
	Audio.play("shotgun", .7, -8.0)
	var p = burstParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	var d = dustParticles.instantiate()
	get_parent().add_child(d)
	d.global_position = global_position
	d.emitting = true
	for b in inside:
		if !is_instance_valid(b):
			continue
		if b.has_method("_takeDamage"):
			b._takeDamage(damage, global_position)
		if b.has_method("_applyForce"):
			b._applyForce(global_position, knockback, 8.0)
		if b.has_method("_addShake"):
			b._addShake(.12)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", orgScale * 1.25, .18)
	tw.tween_property(ring, "transparency", 1.0, .18)
	tw.tween_property(fill, "transparency", 1.0, .18)
	await tw.finished
	queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("player") and !inside.has(body):
		inside.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	inside.erase(body)
