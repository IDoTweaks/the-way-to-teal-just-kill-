
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
@export var damage = 14
@export var accelaration = 10
@export var lifeTime : float = 0.0
var target
var mode : String = "idle"
const LOS_INTERVAL = 0.1
var losAccum : float = 0.0
var seesPlayer : bool = false
var gotShot = false
var shouldMove = false
var canAttack : bool = true
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
var baseBodyRotY : float = 0.0
var baseAttackWait : float = 0.0
var burstLeft : int = 0
var burstTimer : float = 0.0
var hopCd : float = 0.0
@export var burstCount : int = 3
@export var burstGap : float = 0.14
@export var scareDist : float = 4.5

func _buff(on):
	if baseAttackWait == 0.0:
		baseAttackWait = attackTimer.wait_time
	attackTimer.wait_time = baseAttackWait / (1.4 if on else 1.0)

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"
func _ready() -> void:
	add_to_group("enemies")
	body._updateMat(1)
	baseBodyY = body.position.y
	baseBodyRotY = body.rotation.y
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
		body._hitPunch()
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
	_deathAnim()
func _deathAnim():
	set_physics_process(false)
	velocity = Vector3.ZERO
	body._killTweens()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .22)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .22)
	await tw.finished
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
		canAttack = false
		burstLeft = burstCount
		burstTimer = 0.0

func _fireOne(targetPos : Vector3):
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
	Audio.play("rifle", 0.75 + randf_range(0.0, 0.12), -9.0)
 
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
	losAccum += delta
	if losAccum >= LOS_INTERVAL:
		losAccum = 0.0
		seesPlayer = _canSeePlayer()
	if seesPlayer:
		if canAttack:
			_shootAt(player.global_position)

	if burstLeft > 0:
		burstTimer -= delta
		if burstTimer <= 0:
			var aimAt = player.global_position if (seesPlayer and player != null) else Vector3.ZERO
			if aimAt != Vector3.ZERO:
				_fireOne(aimAt)
			burstLeft -= 1
			burstTimer = burstGap
			if burstLeft <= 0:
				attackTimer.start()

	hopCd -= delta
	if hopCd <= 0 and is_on_floor() and player != null and is_instance_valid(player):
		var away = global_position - player.global_position
		away.y = 0
		if away.length() < scareDist and away.length() > 0.05:
			away = away.normalized()
			var probe = global_position + away * 1.8
			var space = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(probe + Vector3.UP, probe + Vector3(0, -3, 0))
			ray.exclude = [self.get_rid()]
			if space.intersect_ray(ray):
				velocity.x = away.x * 7.0
				velocity.z = away.z * 7.0
				velocity.y = 3.5
				hopCd = 1.6
				Audio.play("boing", 1.3, -14.0)

	move_and_slide()
	if global_position.y < -80:
		_die()
func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	body.position.y = baseBodyY + sin(animTime * 2.4) * 0.09
	var faceTarget = target if (target != null and is_instance_valid(target)) else player
	if faceTarget != null and is_instance_valid(faceTarget):
		var look = faceTarget.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 8.0)
	else:
		body.rotation.y = baseBodyRotY + sin(animTime * 1.3) * 0.12
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
func _on_chase_body_entered(body: Node3D) -> void:
	if not gotShot:
		if body.has_method("player"):
			target = body
			mode = "chase"
func _on_attack_cd_timeout() -> void:
	canAttack = true
