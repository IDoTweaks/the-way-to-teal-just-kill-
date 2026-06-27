extends CharacterBody3D
func _exploder(): pass
func _enemy(): pass

const SPEED = 8.0
@export var scoreWorth = 4500
@export var health = 25
@onready var body = $body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 12
@export var damage = 45
@export var blastRadius : float = 4.5
@export var triggerDist : float = 2.6
@export_flags_3d_physics var wallLayer : int
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var textActive = false
var txt
var animTime : float = 0.0
var baseBodyY : float = 0.0
var detonated = false

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"

func _ready() -> void:
	add_to_group("enemies")
	body._updateMat(1)
	baseBodyY = body.position.y
	await get_tree().physics_frame

func _targetValid():
	return target != null and is_instance_valid(target)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._updateMat(health / 25.0)
	else:
		_die()

func _die():
	if detonated:
		return
	detonated = true
	if target and target.has_method("_onKill"):
		target._onKill()
	_boom(false)
	queue_free()

func _detonate():
	if detonated:
		return
	detonated = true
	_boom(true)
	queue_free()

func _boom(doDamage : bool):
	Audio.play("slam", 1.1, -2.0)
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	if doDamage and _targetValid():
		if global_position.distance_to(target.global_position) <= blastRadius and target.has_method("_takeDamage"):
			target._takeDamage(damage)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not detonated and _targetValid() and global_position.distance_to(target.global_position) < triggerDist:
		_detonate()
		return

	if mode == "chase" and _targetValid():
		var hd = target.global_position - global_position
		hd.y = 0
		hd = hd.normalized()
		velocity.x = hd.x * SPEED
		velocity.z = hd.z * SPEED

	if mode != "attack":
		var horizontal = Vector3(velocity.x, 0, velocity.z).normalized()
		if horizontal.length() > 0.1:
			var space = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * .6, global_position + horizontal * .6 + Vector3(0, -2, 0))
			ray.exclude = [self.get_rid()]
			if not space.intersect_ray(ray):
				velocity.x = 0
				velocity.z = 0

	move_and_slide()

func _process(delta: float) -> void:
	animTime += delta
	var prox = 0.0
	if _targetValid():
		var d = global_position.distance_to(target.global_position)
		prox = clamp(1.0 - d / 15.0, 0.0, 1.0)
	var rate = lerp(3.0, 22.0, prox)
	var pulse = 1.0 + 0.12 * prox * abs(sin(animTime * rate))
	body.scale = Vector3(pulse, pulse, pulse)
	var shake = prox * 0.06
	body.position.x = randf_range(-shake, shake)
	body.position.z = randf_range(-shake, shake)
	body.position.y = baseBodyY + abs(sin(animTime * 3.0)) * 0.08
	body.rotation.z = sin(animTime * rate) * prox * 0.25
	if _targetValid():
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 8.0)
	if txt == null:
		textActive = false

func _updateDmgTxt(moreDamage:int):
	if txt != null:
		txt.damage += moreDamage
		txt.global_position = textSpawn.global_position
		txt._resetScale()

func _spawnDmgTxt(damage:int):
	txt = dmgTxt.instantiate()
	get_parent().add_child(txt)
	txt.damage = damage
	txt.global_position = textSpawn.global_position
	textActive = true
	txt.lookat = target

func _on_chase_body_entered(bod: Node3D) -> void:
	if bod.has_method("player"):
		target = bod
		mode = "chase"

func _on_chase_body_exited(bod: Node3D) -> void:
	pass
