
extends CharacterBody3D
func _xenon():pass
func _enemy():pass
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var attackTimer = $attackCd
@onready var animPlayer = $AnimationPlayer
@export var scoreWorth = 5000
@export var health = 50
@onready var body =$body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var sightDist :float = 30.0
@export var player : CharacterBody3D
@export_flags_3d_physics var wallLayer : int
@onready var bullet = preload("res://ObjectScenes/greenBullet.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var bulletSpawn =$body/wand/bulletSpawn
var particleInstance
@export var navAgent : NavigationAgent3D
@export var damage = 20
@export var accelaration = 10
@export var lifeTime : float = 0.0
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var canAttack : bool = true
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"
func _ready() -> void:
	add_to_group("enemies")
	body._updateMat(1)
	baseBodyY = body.position.y
	await get_tree().physics_frame
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
		body._updateMat(health / 50.0)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death")
	if target and target.has_method("_onKill"):
		target._onKill()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	queue_free()
func _canSeePlayer():
	if player == null:
		return false
	if global_position.distance_to(player.global_position) > sightDist:
		return false
	var tmp = _hasLineOfSIght(player)
	if tmp:
		mode = "attack"
	else:
		mode = "chase"
	return tmp
	
func _hasLineOfSIght(target : CharacterBody3D):
	var spaceState := get_world_3d().direct_space_state #hahaha := looks like a dick
	var query := PhysicsRayQueryParameters3D.create(global_position,target.global_position)#im starting to like this := thing
	query.exclude = [self]
	query.collision_mask = wallLayer
	var result := spaceState.intersect_ray(query)
	return result.is_empty()
 
func _shootAt(targetPos : Vector3):
	if bulletSpawn == null:
		return
	if canAttack:
		if animPlayer.has_animation("attack"):
			animPlayer.play("attack")
		var myBullet = bullet.instantiate()
		myBullet.dest = targetPos
		if lifeTime != 0.0:
			myBullet.lifeTime = lifeTime
		get_parent().add_child(myBullet)
		myBullet.global_position = bulletSpawn.global_position
		var muzzle = muzzleParticles.instantiate()
		get_parent().add_child(muzzle)
		muzzle.global_position = bulletSpawn.global_position
		muzzle.emitting = true
		canAttack = false
		attackTimer.start()
 
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if mode != "attack":
		var space = get_world_3d().direct_space_state
		var horizontal = Vector3(velocity.x,0,velocity.z).normalized()
		if horizontal.length() > 0.1:
			var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * .6, global_position + horizontal * .6 + Vector3(0,-2,0))
			ray.exclude = [self.get_rid()]
			var hit = space.intersect_ray(ray)
			if !hit:
				velocity.x = 0
				velocity.z = 0
	if _canSeePlayer():
		if canAttack:
			_shootAt(player.global_position)
			canAttack = false
			attackTimer.start()
	
	

	#if shouldMove:
	move_and_slide()
func _process(delta: float) -> void:
	animTime += delta
	body.position.y = baseBodyY + sin(animTime * 2.4) * 0.09
	var faceTarget = target if (target != null and is_instance_valid(target)) else player
	if faceTarget != null and is_instance_valid(faceTarget):
		var look = faceTarget.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 8.0)
	else:
		body.rotation.y = sin(animTime * 1.3) * 0.12
	if txt == null:
		textActive = false
	if not gotShot:
		if body.has_method("player"):
			mode = "chase"
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
func _on_chase_body_entered(body: Node3D) -> void:
	if not gotShot:
		if body.has_method("player"):
			target = body
			mode = "chase"
func _on_attack_cd_timeout() -> void:
	canAttack = true
