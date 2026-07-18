extends CharacterBody3D
func _diver(): pass
func _enemy(): pass

const SPEED = 8.0
@export var scoreWorth = 3500
@export var health = 20
@onready var body = $body
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var player : CharacterBody3D
@export var damage = 30
@export var blastRadius : float = 4.0
@export var orbitHeight : float = 8.0
@export var orbitRadius : float = 10.0
@export var diveSpeed : float = 22.0
@export var telegraphTime : float = .6
@export var accel : float = 5.0
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")
var particleInstance
var maxHealth : float = 20.0
var target
var mode : String = "orbit"
var gotShot = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var orbitAngle : float = 0.0
var diveCd : float = 0.0
var telegraphTimer : float = 0.0
var diveDir : Vector3 = Vector3.ZERO
var diveTimer : float = 0.0
var trailCd : float = 0.0
var flare : float = 0.0
var baseBodyScale : Vector3 = Vector3.ONE
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	baseBodyScale = body.scale
	orbitAngle = randf() * TAU
	diveCd = randf_range(2.0, 4.0)
	await get_tree().physics_frame

func _activeTarget():
	if target != null and is_instance_valid(target):
		return target
	return player

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.2, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._updateMat(health / maxHealth)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	var tgt = _activeTarget()
	if tgt and tgt.has_method("_onKill"):
		tgt._onKill()
	_boom(false)
	queue_free()

func _detonate():
	if dead:
		return
	dead = true
	_boom(true)
	queue_free()

func _boom(doDamage : bool):
	Audio.play("slam", 1.2, -2.0)
	Audio.play("enemy_death", .9, -6.0)
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	var tgt = _activeTarget()
	if doDamage and tgt != null and is_instance_valid(tgt):
		if global_position.distance_to(tgt.global_position) <= blastRadius and tgt.has_method("_takeDamage"):
			tgt._takeDamage(damage, global_position)
			if tgt.has_method("_applyForce"):
				tgt._applyForce(global_position, 12.0, blastRadius)

func _startTelegraph():
	mode = "telegraph"
	telegraphTimer = telegraphTime
	Audio.play("enemy_hit", .5, -8.0)
	Audio.play("ui_hover", .6, -10.0)

func _startDive(tgt):
	mode = "dive"
	diveTimer = 2.5
	diveDir = (tgt.global_position + Vector3(0, .8, 0) - global_position).normalized()
	Audio.play("dash", .6, -4.0)

func _physics_process(delta: float) -> void:
	var tgt = _activeTarget()
	match mode:
		"orbit":
			if tgt != null and is_instance_valid(tgt):
				orbitAngle += delta * .8 * buffMult
				var desired = tgt.global_position + Vector3(cos(orbitAngle) * orbitRadius, orbitHeight, sin(orbitAngle) * orbitRadius)
				velocity = velocity.lerp((desired - global_position).limit_length(1.0) * SPEED * 1.6, accel * delta)
				diveCd -= delta * buffMult
				if diveCd <= 0:
					_startTelegraph()
			else:
				velocity = velocity.lerp(Vector3.ZERO, accel * delta)
		"telegraph":
			velocity = velocity.lerp(Vector3.ZERO, 8.0 * delta)
			telegraphTimer -= delta
			if telegraphTimer <= 0:
				if tgt != null and is_instance_valid(tgt):
					_startDive(tgt)
				else:
					mode = "orbit"
					diveCd = randf_range(4.0, 6.0)
		"dive":
			velocity = diveDir * diveSpeed
			diveTimer -= delta
			trailCd -= delta
			if trailCd <= 0:
				trailCd = .05
				var t = trailParticles.instantiate()
				get_parent().add_child(t)
				t.global_position = global_position
				t.emitting = true
			if diveTimer <= 0:
				_detonate()
				return
	move_and_slide()
	if mode == "dive":
		if get_slide_collision_count() > 0:
			_detonate()
			return
		if tgt != null and is_instance_valid(tgt) and global_position.distance_to(tgt.global_position) < 1.7:
			_detonate()
			return

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	if mode == "telegraph":
		flare = 1.0 - telegraphTimer / max(telegraphTime, .01)
		body.scale = baseBodyScale * (1.0 + .25 * flare * abs(sin(animTime * 26.0)))
	else:
		flare = 0.0
		body.scale = baseBodyScale
	if mode == "dive":
		if diveDir.length() > .1:
			var flatD = Vector3(diveDir.x, 0, diveDir.z)
			if flatD.length() > .05:
				rotation.y = atan2(-diveDir.x, -diveDir.z)
			body.rotation.x = lerp_angle(body.rotation.x, asin(clamp(diveDir.y, -1, 1)), delta * 10.0)
	else:
		body.rotation.x = lerp_angle(body.rotation.x, 0.0, delta * 6.0)
		var flat = Vector3(velocity.x, 0, velocity.z)
		if flat.length() > .5:
			rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), delta * 5.0)
			body.rotation.z = lerp_angle(body.rotation.z, clamp(-velocity.cross(Vector3.UP).dot(flat.normalized()) * .04, -.6, .6), delta * 4.0)
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
