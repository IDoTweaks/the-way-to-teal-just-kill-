extends CharacterBody3D
func _drone(): pass
func _enemy(): pass

const SPEED = 6.0
@onready var attackTimer = $attackCd
@export var scoreWorth = 4000
@export var health = 30
@onready var body = $body
@onready var hoverRing = $body/HoverRing
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var sightDist : float = 35.0
@export var player : CharacterBody3D
@export_flags_3d_physics var wallLayer : int
@onready var bullet = preload("res://ObjectScenes/droneBullet.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var bulletSpawn = $body/bulletSpawn
var particleInstance
@export var hoverHeight : float = 4.0
@export var preferredDist : float = 12.0
@export var accel : float = 6.0
@export var strafeSpeed : float = 2.5
@export var damage = 25
var target
var gotShot = false
var canAttack : bool = true
var textActive = false
var txt
var animTime : float = 0.0
var baseBodyY : float = 0.0
var fireKick : float = 0.0
var hitKick : float = 0.0
var dead = false

var baseAttackWait : float = 0.0

func _buff(on):
	if baseAttackWait == 0.0:
		baseAttackWait = attackTimer.wait_time
	attackTimer.wait_time = baseAttackWait / (1.4 if on else 1.0)

func _makeTarg(targ):
	gotShot = true
	target = targ

func _ready() -> void:
	add_to_group("enemies")
	body._updateMat(1)
	baseBodyY = body.position.y
	await get_tree().physics_frame

func _activeTarget():
	if target != null and is_instance_valid(target):
		return target
	return player

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
		hitKick = 1.0
		body._updateMat(health / 30.0)
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
	var tgt = _activeTarget()
	if tgt == null:
		return false
	if global_position.distance_to(tgt.global_position) > sightDist:
		return false
	return _hasLineOfSight(tgt)

func _hasLineOfSight(tgt):
	var spaceState := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, tgt.global_position)
	query.exclude = [self]
	query.collision_mask = wallLayer
	var result := spaceState.intersect_ray(query)
	return result.is_empty()

func _shootAt(targetPos : Vector3):
	if bulletSpawn == null:
		return
	if canAttack:
		var myBullet = bullet.instantiate()
		myBullet.dest = targetPos
		get_parent().add_child(myBullet)
		myBullet.global_position = bulletSpawn.global_position
		var muzzle = muzzleParticles.instantiate()
		get_parent().add_child(muzzle)
		muzzle.global_position = bulletSpawn.global_position
		muzzle.emitting = true
		fireKick = 1.0
		canAttack = false
		attackTimer.start()

func _physics_process(delta: float) -> void:
	var tgt = _activeTarget()
	if tgt != null and is_instance_valid(tgt):
		var desired = tgt.global_position + Vector3(0, hoverHeight, 0)
		var toDesired = desired - global_position
		var flat = Vector3(toDesired.x, 0, toDesired.z)
		var dist = flat.length()
		var move = Vector3.ZERO
		if dist > 0.1:
			var fdir = flat / dist
			if dist > preferredDist + 1.0:
				move += fdir * SPEED
			elif dist < preferredDist - 1.0:
				move -= fdir * SPEED
			var strafe = fdir.cross(Vector3.UP)
			move += strafe * sin(animTime * 1.5) * strafeSpeed
		move.y = clamp(toDesired.y, -1.0, 1.0) * SPEED
		velocity = velocity.lerp(move, accel * delta)
		if _canSeePlayer() and canAttack:
			_shootAt(tgt.global_position)
	else:
		velocity = velocity.lerp(Vector3.ZERO, accel * delta)
	move_and_slide()
	if global_position.y < -80:
		_die()

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	body.position.y = baseBodyY + sin(animTime * 2.0) * 0.12
	hoverRing.rotation.y += delta * 4.0
	fireKick = move_toward(fireKick, 0.0, delta * 4.0)
	hitKick = move_toward(hitKick, 0.0, delta * 6.0)
	body.rotation.x = lerp_angle(body.rotation.x, fireKick * 0.5, delta * 14.0)
	body.rotation.z = sin(animTime * 40.0) * hitKick * 0.18
	body.scale = Vector3.ONE * (1.0 + fireKick * 0.15 + hitKick * 0.18)
	var tgt = _activeTarget()
	if tgt != null and is_instance_valid(tgt):
		var look = tgt.global_position - global_position
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
	txt.lookat = _activeTarget()

func _on_chase_body_entered(bod: Node3D) -> void:
	if bod.has_method("player"):
		target = bod

func _on_chase_body_exited(bod: Node3D) -> void:
	pass

func _on_attack_cd_timeout() -> void:
	canAttack = true
