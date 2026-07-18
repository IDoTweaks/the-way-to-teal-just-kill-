extends CharacterBody3D
func _gnat(): pass
func _enemy(): pass

const SPEED = 9.0
@export var scoreWorth = 1000
@export var health = 10
@onready var body = $body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 12
@export var damage = 3
@export var biteRange : float = 1.5
@export var hopPower : float = 4.6
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var maxHealth : float = 10.0
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
var baseBodyScale : Vector3 = Vector3.ONE
var squash : Vector3 = Vector3.ONE
var punch : float = 0.0
var hopCd : float = 0.0
var winding = false
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "chase"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	baseBodyY = body.position.y
	baseBodyScale = body.scale
	hopCd = randf_range(.1, .5)
	await get_tree().physics_frame

func _targetValid():
	return target != null and is_instance_valid(target)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.3, -6.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		punch = 1.0
		body._updateMat(health / maxHealth)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death", 1.6, -4.0)
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
	tw.tween_property(body, "scale", Vector3.ZERO, .18)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .18)
	await tw.finished
	queue_free()

func _hop():
	if dead or !_targetValid():
		return
	winding = true
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "squash", Vector3(1.25, .55, 1.25), .12)
	await tw.finished
	if dead or !_targetValid() or !is_instance_valid(self):
		winding = false
		return
	var hd = target.global_position - global_position
	hd.y = 0
	hd = hd.normalized()
	velocity.x = hd.x * SPEED * buffMult
	velocity.z = hd.z * SPEED * buffMult
	velocity.y = hopPower
	Audio.play("jump", randf_range(1.6, 1.9), -22.0)
	var tw2 = create_tween()
	tw2.set_trans(Tween.TRANS_BACK)
	tw2.set_ease(Tween.EASE_OUT)
	tw2.tween_property(self, "squash", Vector3(.75, 1.35, .75), .1)
	tw2.tween_property(self, "squash", Vector3.ONE, .16)
	winding = false
	hopCd = randf_range(.2, .45) / buffMult

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if !winding:
			velocity.x = move_toward(velocity.x, 0, 30 * delta)
			velocity.z = move_toward(velocity.z, 0, 30 * delta)
		if mode == "chase" and _targetValid() and !winding:
			hopCd -= delta
			if hopCd <= 0:
				_hop()

	if _targetValid() and canAttack and global_position.distance_to(target.global_position) < biteRange:
		canAttack = false
		target._takeDamage(damage, global_position)
		Audio.play("enemy_hit", 1.8, -12.0)
		var sq = create_tween()
		sq.set_trans(Tween.TRANS_BACK)
		sq.set_ease(Tween.EASE_OUT)
		sq.tween_property(self, "squash", Vector3(1.3, .7, 1.3), .08)
		sq.tween_property(self, "squash", Vector3.ONE, .12)
		get_tree().create_timer(.9 / buffMult).timeout.connect(func(): canAttack = true)

	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	punch = move_toward(punch, 0.0, delta * 6.0)
	body.scale = baseBodyScale * squash * (1.0 + punch * .16)
	body.position.y = baseBodyY + abs(sin(animTime * 6.0)) * 0.05
	if _targetValid():
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 10.0)
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
