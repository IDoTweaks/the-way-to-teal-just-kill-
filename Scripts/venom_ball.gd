extends CharacterBody3D

func _venom():pass

@export var speed : float = 18.0
@export var damage : int = 10
@export var para : int = 1
@export var knockback : float = 8.0
@export var dest : Vector3
@export var lifeTime : float = 4.0
var dir = Vector3.ZERO
var launched = false
@onready var impactParticles = preload("res://Particles/enemyBulletImpact.tscn")

func _process(delta: float) -> void:
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	if not launched:
		dir = global_position.direction_to(dest)
		launched = true
	velocity = dir * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body.has_method("player"):
			_hitPlayer(body)
		elif body.has_method("_enemy") or body.has_method("_venom"):
			add_collision_exception_with(body)
		else:
			_splat()

func _hitPlayer(body):
	if body.has_method("_takeDamage"):
		body._takeDamage(damage, global_position - dir * 5.0)
	if body.has_method("_paralyze"):
		body._paralyze(para)
	if body.has_method("_applyForce"):
		body._applyForce(global_position - dir * 2.0, knockback, 12.0)
	_splat()

func _splat():
	var p = impactParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	Audio.play("slam", 1.7, -17.0)
	queue_free()
