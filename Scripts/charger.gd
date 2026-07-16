extends CharacterBody3D
func _charger(): pass
func _enemy(): pass

const SPEED = 6.0
@onready var attackTimer = $attackCd
@export var scoreWorth = 5500
@export var health = 120
@onready var body = $body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 10
@export var damage = 25
@export var sightDist : float = 30.0
@export var attackRange : float = 13.0
@export var dashSpeed : float = 26.0
@export var telegraphTime : float = 0.55
@export var dashTime : float = 0.45
@export var recoverTime : float = 0.7
@export_flags_3d_physics var wallLayer : int
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var canAttack : bool = true
var textActive = false
var txt
var animTime : float = 0.0
var baseBodyY : float = 0.0
var baseBodyScale : Vector3 = Vector3.ONE
var dead = false
var chargeState : String = ""
var chargeTimer : float = 0.0
var dashDir : Vector3 = Vector3.ZERO

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"

func _ready() -> void:
	add_to_group("enemies")
	body._updateMat(1)
	baseBodyY = body.position.y
	baseBodyScale = body.scale
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
		body._updateMat(health / 120.0)
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

func _targetValid():
	return target != null and is_instance_valid(target)

func _flatDirTo(t) -> Vector3:
	var d = t.global_position - global_position
	d.y = 0
	return d.normalized() if d.length() > 0.01 else Vector3.ZERO

func _hasLoS() -> bool:
	if not _targetValid():
		return false
	var spaceState := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, target.global_position)
	query.exclude = [self]
	query.collision_mask = wallLayer
	return spaceState.intersect_ray(query).is_empty()

func _startCharge():
	chargeState = "telegraph"
	chargeTimer = telegraphTime
	mode = "charge"
	canAttack = false
	dashDir = _flatDirTo(target)

func _updateCharge(delta: float):
	chargeTimer -= delta
	match chargeState:
		"telegraph":
			if _targetValid():
				dashDir = _flatDirTo(target)
			velocity.x = move_toward(velocity.x, 0, 40 * delta)
			velocity.z = move_toward(velocity.z, 0, 40 * delta)
			if chargeTimer <= 0:
				chargeState = "dash"
				chargeTimer = dashTime
		"dash":
			velocity.x = dashDir.x * dashSpeed
			velocity.z = dashDir.z * dashSpeed
			if chargeTimer <= 0 or is_on_wall():
				chargeState = "recover"
				chargeTimer = recoverTime
		"recover":
			velocity.x = move_toward(velocity.x, 0, 30 * delta)
			velocity.z = move_toward(velocity.z, 0, 30 * delta)
			if chargeTimer <= 0:
				chargeState = ""
				mode = "chase"
				attackTimer.start()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if chargeState != "":
		_updateCharge(delta)
	elif canAttack and _targetValid() and mode == "chase":
		if global_position.distance_to(target.global_position) < attackRange and _hasLoS():
			_startCharge()

	if chargeState == "" and mode == "chase" and _targetValid():
		var hd = _flatDirTo(target)
		velocity.x = hd.x * SPEED
		velocity.z = hd.z * SPEED

	if chargeState != "dash":
		var horizontal = Vector3(velocity.x, 0, velocity.z).normalized()
		if horizontal.length() > 0.1:
			var space = get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * .6, global_position + horizontal * .6 + Vector3(0, -2, 0))
			ray.exclude = [self.get_rid()]
			if not space.intersect_ray(ray):
				velocity.x = 0
				velocity.z = 0

	move_and_slide()

	if chargeState == "dash" and _targetValid():
		if global_position.distance_to(target.global_position) < 2.0:
			target._takeDamage(damage, global_position)
			chargeState = "recover"
			chargeTimer = recoverTime

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	var targetPitch = 0.0
	var targetScale = baseBodyScale
	var bob = abs(sin(animTime * 3.0)) * 0.08
	match chargeState:
		"telegraph":
			targetPitch = -0.55
			targetScale = baseBodyScale * (1.0 + 0.16 * abs(sin(animTime * 24.0)))
			bob = abs(sin(animTime * 16.0)) * 0.06
		"dash":
			targetPitch = 0.4
		"recover":
			targetPitch = -0.12
	body.rotation.x = lerp_angle(body.rotation.x, targetPitch, delta * 13.0)
	body.scale = body.scale.lerp(targetScale, delta * 16.0)
	body.position.y = baseBodyY + bob
	var faceDir = dashDir if chargeState == "dash" else (_flatDirTo(target) if _targetValid() else Vector3.ZERO)
	if faceDir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-faceDir.x, -faceDir.z), delta * 9.0)
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

func _on_attack_cd_timeout() -> void:
	canAttack = true
