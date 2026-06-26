extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var health = 100
@onready var body =$body
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance

func _ready() -> void:
	body._updateMat(1)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	if health >= 0:
		body._updateMat(health / 100)
	else:
		_die()

func _die():
	body._updateMat(0)
	Audio.play("enemy_death")
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
