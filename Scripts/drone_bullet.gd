extends CharacterBody3D
func _droneBullet(): pass

@export var speed : float = 14.0
@export var damage : int = 25
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
			body._takeDamage(damage, global_position - dir * 5.0)
			_impact()
			queue_free()
		elif body.has_method("_enemy"):
			add_collision_exception_with(body)
		else:
			_impact()
			queue_free()

func _impact():
	var p = impactParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
