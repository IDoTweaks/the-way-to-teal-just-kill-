extends CharacterBody3D
func _sprinkler(): pass
func _enemy(): pass

@export var scoreWorth = 3000
@export var health = 60
@onready var body = $body
@onready var head = $body/head
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@onready var bulletSpawn = $body/head/bulletSpawn
@export var player : CharacterBody3D
@export_flags_3d_physics var wallLayer : int
@export var damage = 8
@export var bulletSpeed : float = 9.0
@export var fireGap : float = .35
@export var sweepArc : float = 70.0
@export var sweepSpeed : float = 1.4
@export var sightDist : float = 26.0
@onready var bullet = preload("res://ObjectScenes/greenBullet.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
var particleInstance
var maxHealth : float = 60.0
var target
var mode : String = "idle"
var gotShot = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var fireCd : float = 0.0
var headKick : float = 0.0
var headBaseZ : float = 0.0
const LOS_INTERVAL = 0.1
var losAccum : float = 0.0
var seesPlayer : bool = false
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "attack"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	headBaseZ = head.position.z
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
		body._hitPunch()
		body._updateMat(health / maxHealth)
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
	body._killTweens()
	var popHead = head
	popHead.reparent(get_parent())
	var htw = create_tween()
	htw.set_parallel(true)
	htw.set_trans(Tween.TRANS_QUAD)
	htw.set_ease(Tween.EASE_OUT)
	htw.tween_property(popHead, "position:y", popHead.position.y + 3.2, .5)
	htw.tween_property(popHead, "rotation:x", popHead.rotation.x + PI * 2.2, .5)
	htw.tween_property(popHead, "scale", Vector3.ZERO, .5)
	htw.finished.connect(popHead.queue_free)
	Audio.play("walljump", 1.5, -8.0)
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
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1, 0), tgt.global_position)
	query.exclude = [self]
	query.collision_mask = wallLayer
	var result := spaceState.intersect_ray(query)
	return result.is_empty()

func _fire():
	var dir = -head.global_transform.basis.z
	var myBullet = bullet.instantiate()
	myBullet.dest = bulletSpawn.global_position + dir * 40.0
	myBullet.damage = damage
	myBullet.speed = bulletSpeed
	myBullet.lifeTime = 3.0
	get_parent().add_child(myBullet)
	myBullet.global_position = bulletSpawn.global_position
	myBullet.add_collision_exception_with(self)
	add_collision_exception_with(myBullet)
	var muzzle = muzzleParticles.instantiate()
	get_parent().add_child(muzzle)
	muzzle.global_position = bulletSpawn.global_position
	muzzle.emitting = true
	headKick = 1.0
	Audio.play("rifle", 1.3, -14.0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	losAccum += delta
	if losAccum >= LOS_INTERVAL:
		losAccum = 0.0
		seesPlayer = _canSeePlayer()
		mode = "attack" if seesPlayer else "idle"
	if mode == "attack":
		fireCd -= delta * buffMult
		if fireCd <= 0:
			fireCd = fireGap
			_fire()
	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	headKick = move_toward(headKick, 0.0, delta * 6.0)
	head.position.z = headBaseZ + headKick * .12
	var tgt = _activeTarget()
	if mode == "attack" and tgt != null and is_instance_valid(tgt):
		var look = tgt.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			var bearing = atan2(-look.x, -look.z) - rotation.y
			head.rotation.y = bearing + sin(animTime * sweepSpeed) * deg_to_rad(sweepArc)
	else:
		head.rotation.y += delta * .8
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
