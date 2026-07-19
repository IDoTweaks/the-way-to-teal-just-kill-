extends CharacterBody3D
func _walker():pass
func _enemy():pass
const SPEED = 7.5
const JUMP_VELOCITY = 4.5
@onready var attackTimer = $attackCd
@onready var animPlayer = $AnimationPlayer

@export var scoreWorth = 5000
@export var health = 100
@onready var body =$body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn

@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
@export var navAgent : NavigationAgent3D
@export var damage = 5
@export var accelaration = 10
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
var lungeState : String = ""
var lungeTimer : float = 0.0
var lungeDir : Vector3 = Vector3.ZERO
var navAccum : float = 0.0
@export var lungeSpeed : float = 15.0
@export var lungeRange : float = 1.9
@export var windupTime : float = 0.35

var baseAttackWait : float = 0.0

func _selfDriven():pass

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
		body._updateMat(health / 100.0)
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


func _flatDirTo(t) -> Vector3:
	var d = t.global_position - global_position
	d.y = 0
	return d.normalized() if d.length() > 0.01 else Vector3.ZERO

func _targetValid():
	return target != null and is_instance_valid(target)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if lungeState != "":
		_updateLunge(delta)
	elif mode == "attack" and canAttack and _targetValid():
		lungeState = "windup"
		lungeTimer = windupTime
		canAttack = false
	elif mode == "chase" and _targetValid():
		navAccum += delta
		if navAccum >= 0.2:
			navAccum = 0.0
			navAgent.target_position = target.global_position
		var nxt = navAgent.get_next_path_position()
		var dir = nxt - global_position
		dir.y = 0
		if dir.length() < 0.05:
			dir = _flatDirTo(target)
		else:
			dir = dir.normalized()
		velocity.x = lerp(velocity.x, dir.x * SPEED, accelaration * delta)
		velocity.z = lerp(velocity.z, dir.z * SPEED, accelaration * delta)

	if lungeState != "lunge":
		var space = get_world_3d().direct_space_state
		var horizontal = Vector3(velocity.x,0,velocity.z).normalized()
		if horizontal.length() > 0.1:
			var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * .6, global_position + horizontal * .6 + Vector3(0,-2,0))
			ray.exclude = [self.get_rid()]
			var hit = space.intersect_ray(ray)
			if !hit:
				velocity.x = 0
				velocity.z = 0
	move_and_slide()
	if global_position.y < -80:
		_die()

func _updateLunge(delta: float):
	lungeTimer -= delta
	match lungeState:
		"windup":
			velocity.x = move_toward(velocity.x, 0, 30 * delta)
			velocity.z = move_toward(velocity.z, 0, 30 * delta)
			if lungeTimer <= 0:
				lungeState = "lunge"
				lungeTimer = 0.28
				lungeDir = _flatDirTo(target) if _targetValid() else Vector3.ZERO
				velocity.x = lungeDir.x * lungeSpeed
				velocity.z = lungeDir.z * lungeSpeed
				velocity.y = 2.5
				animPlayer.play("attack")
				Audio.play("dash", 0.7, -10.0)
		"lunge":
			if _targetValid() and global_position.distance_to(target.global_position) < lungeRange:
				target._takeDamage(damage, global_position)
				lungeState = "recover"
				lungeTimer = 0.35
				attackTimer.start()
			elif lungeTimer <= 0:
				lungeState = "recover"
				lungeTimer = 0.35
				attackTimer.start()
		"recover":
			velocity.x = move_toward(velocity.x, 0, 25 * delta)
			velocity.z = move_toward(velocity.z, 0, 25 * delta)
			if lungeTimer <= 0:
				lungeState = ""

func _process(delta: float) -> void:
	if dead:
		return
	var spd = Vector3(velocity.x, 0, velocity.z).length()
	animTime += delta * (1.0 + spd * 0.45)
	body.position.y = baseBodyY + abs(sin(animTime * 3.0)) * 0.10
	body.rotation.z = sin(animTime * 3.0) * 0.06
	var lean = 0.0
	if lungeState == "windup":
		lean = -0.45
	elif lungeState == "lunge":
		lean = 0.35
	body.rotation.x = lerp_angle(body.rotation.x, lean, delta * 12.0)
	if target != null and is_instance_valid(target):
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 8.0)
	if txt == null:
		textActive = false

func _on_attack_body_entered(body: Node3D) -> void:
	if body.has_method("player"):
		mode = "attack"
		if target == null:
			target = body


func _on_attack_body_exited(body: Node3D) -> void:
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
