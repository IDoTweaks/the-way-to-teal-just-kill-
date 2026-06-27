
extends CharacterBody3D
 
@export var speed : float = 5.0
@export var damage : int = 20.0
@export var dest : Vector3
@export var lifeTime : float = 2.0
var dir = Vector3.ZERO
var launched = false
@onready var impactParticles = preload("res://Particles/enemyBulletImpact.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
 
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lifeTime -= delta
	if lifeTime <= 0:
		queue_free()
 
func _physics_process(delta: float) -> void:
	if not launched:
		dir = global_position.direction_to(dest)
		launched = true
	velocity.z = dir.z * speed
	velocity.y = dir.y * speed
	velocity.x = dir.x * speed
	var collision = move_and_collide(velocity * delta)
	if collision:
		var body = collision.get_collider()
		if body.has_method("player"):
			_spawnImpact()
			body._takeDamage(damage)
			queue_free()
		elif body.has_method("_enemy"):
			add_collision_exception_with(body)
		else:
			_bounce(collision)

func _spawnImpact():
	var p = impactParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
 
func _bounce(collision : KinematicCollision3D):
	dir = dir.bounce(collision.get_normal())
