extends CharacterBody3D

func _eviction():pass

@export var speed : float = 7.0
@export var turnRate : float = 1.6
@export var damage : int = 12
@export var knockback : float = 9.0
@export var lifeTime : float = 7.0
var target
var dir = Vector3.FORWARD
var spun : float = 0.0
@onready var impactParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var mesh = $MeshInstance3D

func _process(delta: float) -> void:
	lifeTime -= delta
	if lifeTime <= 0:
		_splat()
		return
	spun += delta
	mesh.rotation.y = spun * 5.0
	mesh.rotation.z = sin(spun * 3.0) * .35

func _physics_process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		var want = global_position.direction_to(target.global_position)
		dir = dir.slerp(want, clamp(turnRate * delta, 0.0, 1.0)).normalized()
	velocity = dir * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body.has_method("player"):
			_hitPlayer(body)
		elif body.has_method("_enemy") or body.has_method("_eviction"):
			add_collision_exception_with(body)
		else:
			_splat()

func _hitPlayer(body):
	if body.has_method("_takeDamage"):
		body._takeDamage(damage, global_position)
	if body.has_method("_applyForce"):
		body._applyForce(global_position - dir * 2.0, knockback, 12.0)
	_splat()

func _splat():
	var p = impactParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	Audio.play("enemy_hit", 1.3, -13.0)
	queue_free()
