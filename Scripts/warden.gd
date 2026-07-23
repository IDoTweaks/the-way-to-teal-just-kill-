extends CharacterBody3D
func _warden(): pass
func _enemy(): pass

const SPEED = 3.5
const SHUT_COL = Color(1, .38, 0)
const OPEN_COL = Color(0, .9, .6)
@onready var attackTimer = $attackCd
@export var scoreWorth = 5000
@export var health = 140
@onready var body = $body
@onready var shield = $body/shield
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 8
@export var damage = 12
@export var blockArc : float = 42.0
@export var player : CharacterBody3D
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var maxHealth : float = 140.0
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
var clinkCd : float = 0.0
var shieldFlash : float = 0.0
var baseShieldScale : Vector3 = Vector3.ONE
var buffMult : float = 1.0
var shieldMat : StandardMaterial3D
var shieldLit : float = 1.0
var shieldDown : float = 0.0
@export var shoveOpen : float = 0.9
@onready var sparkParticles = preload("res://Particles/enemyBulletImpact.tscn")

func _buff(on):
	buffMult = 1.4 if on else 1.0
	attackTimer.wait_time = 1.2 / buffMult

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	baseBodyY = body.position.y
	baseShieldScale = shield.scale
	if shield.material_override:
		shield.material_override = shield.material_override.duplicate()
		shieldMat = shield.material_override
	await get_tree().physics_frame

func _targetValid():
	return target != null and is_instance_valid(target)

func _hurter():
	if _targetValid():
		return target
	if player != null and is_instance_valid(player):
		return player
	return null

func _blocked() -> bool:
	if shieldDown > 0.0:
		return false
	var p = _hurter()
	if p == null:
		return false
	var facing = -global_transform.basis.z
	facing.y = 0
	facing = facing.normalized()
	var toP = p.global_position - global_position
	toP.y = 0
	if toP.length() < 0.1:
		return false
	return facing.dot(toP.normalized()) > cos(deg_to_rad(blockArc))

func _clink():
	shieldFlash = 1.0
	if clinkCd > 0.0:
		return
	clinkCd = .09
	Audio.play("enemy_hit", 1.75, -6.0)
	Audio.play("slam", 1.9, -14.0)
	var s = sparkParticles.instantiate()
	get_parent().add_child(s)
	s.global_position = shield.global_position - global_transform.basis.z * .35
	s.emitting = true

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	if _blocked():
		_clink()
		return
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._hitPunch()
		body._updateMat(health / maxHealth)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death", .85, -2.0)
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
	shield.reparent(get_parent())
	var stw = create_tween()
	stw.set_parallel(true)
	stw.set_trans(Tween.TRANS_QUAD)
	stw.set_ease(Tween.EASE_IN)
	stw.tween_property(shield, "position:y", .1, .45)
	stw.tween_property(shield, "rotation:x", shield.rotation.x - PI * .5, .45)
	stw.chain().tween_interval(1.2)
	stw.chain().tween_property(shield, "scale", Vector3.ZERO, .25)
	stw.finished.connect(shield.queue_free)
	Audio.play("slam", 1.4, -12.0)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .22)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .22)
	await tw.finished
	queue_free()

func _shove():
	canAttack = false
	attackTimer.start()
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(shield, "position:z", shield.position.z - .55, .12)
	tw.tween_property(shield, "position:z", shield.position.z, .25)
	Audio.play("slam", 1.2, -10.0)
	shieldDown = shoveOpen
	if _targetValid():
		target._takeDamage(damage, global_position)
		if target.has_method("_applyForce"):
			target._applyForce(global_position, 9.0, 4.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if mode == "chase" and _targetValid():
		var hd = target.global_position - global_position
		hd.y = 0
		hd = hd.normalized()
		velocity.x = hd.x * SPEED * buffMult
		velocity.z = hd.z * SPEED * buffMult

	if _targetValid() and canAttack and global_position.distance_to(target.global_position) < 2.6:
		_shove()

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
	if dead:
		return
	clinkCd -= delta
	if shieldDown > 0.0:
		shieldDown -= delta
	animTime += delta * (1.0 + Vector3(velocity.x, 0, velocity.z).length() * .3)
	body.position.y = baseBodyY + abs(sin(animTime * 2.2)) * 0.07
	body.rotation.z = sin(animTime * 2.2) * 0.05
	shieldFlash = move_toward(shieldFlash, 0.0, delta * 5.0)
	shield.scale = baseShieldScale * (1.0 + shieldFlash * .22)
	var want = 1.0 if _blocked() else 0.0
	shieldLit = lerp(shieldLit, want, clamp(delta * 7.0, 0.0, 1.0))
	if shieldMat != null:
		shieldMat.emission = SHUT_COL.lerp(OPEN_COL, 1.0 - shieldLit).lerp(Color.WHITE, shieldFlash * .8)
		shieldMat.emission_energy_multiplier = lerp(.15, 3.6, shieldLit) + shieldFlash * 5.0
		shieldMat.albedo_color = SHUT_COL.lerp(OPEN_COL, 1.0 - shieldLit)
	if _targetValid():
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 3.2)
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
