extends CharacterBody3D


const SPEED = 7.5
const JUMP_VELOCITY = 4.5
@export var health = 100
@onready var body =$body
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
@export var navAgent : NavigationAgent3D
@export var damage = 10
@export var accelaration = 10
var target
var mode : String = "idle"

func _ready() -> void:
	body._updateMat(1)

func _damage(dmg):
	health -= dmg
	if health >= 0:
		body._updateMat(health / 100)
	else:
		_die()
		
func _die():
	body._updateMat(0)
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	queue_free()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if mode == "chase":
		navAgent.target_position = Vector3(target.global_position.x,target.global_position.y,target.global_position.z)
		var dir = (navAgent.get_next_path_position() - global_position).normalized()
		velocity = velocity.lerp(dir * SPEED, delta * accelaration)
		look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP,true)
	elif mode == "attack":
		navAgent.target_position = Vector3(target.global_position.x,target.global_position.y,target.global_position.z)
		var jumblePos = Vector3(global_position.x + randf_range(-3,3),global_position.y,global_position.z+ randf_range(-3,3))
		var dir = (navAgent.get_next_path_position() - jumblePos).normalized()
		velocity = velocity.lerp(dir * SPEED, delta * accelaration)
		look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z),Vector3.UP,true)
		target._takeDamage(10)

	move_and_slide()


func _on_attack_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		mode = "attack"
	if target == null:
		target = body


func _on_attack_body_exited(body: Node3D) -> void:
	if body.has_method("player"):
		mode = "chase"


func _on_chase_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		target = body
		mode = "chase"
