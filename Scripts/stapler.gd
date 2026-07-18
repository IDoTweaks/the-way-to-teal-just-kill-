extends CharacterBody3D
func _stapler(): pass
func _enemy(): pass

const SPEED = 4.0
@export var scoreWorth = 5500
@export var health = 70
@onready var body = $body
@onready var jawPivot = $body/jawPivot
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 10
@export var damage = 22
@export var lungeSpeed : float = 20.0
@export var crankTime : float = .7
@export var recoverTime : float = 1.5
@export var blinkRange : float = 7.0
@export var retreatRange : float = 11.0
@export var player : CharacterBody3D
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var burstParticles = preload("res://Particles/wallJumpBurst.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")
var particleInstance
var maxHealth : float = 70.0
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
var baseBodyScale : Vector3 = Vector3.ONE
var jawOpen : float = 0.0
var blinkScale : float = 1.0
var blinkCd : float = 1.2
var stateTimer : float = 0.0
var lungeDir : Vector3 = Vector3.ZERO
var trailCd : float = 0.0
var buffMult : float = 1.0

func _buff(on):
	buffMult = 1.4 if on else 1.0

func _makeTarg(targ):
	gotShot = true
	target = targ
	if mode == "idle":
		mode = "stalk"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	baseBodyY = body.position.y
	baseBodyScale = body.scale
	await get_tree().physics_frame

func _targetValid():
	if target != null and is_instance_valid(target):
		return true
	if player != null and is_instance_valid(player):
		target = player
		return true
	return false

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.1, -4.0)
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
	body._updateMat(0)
	Audio.play("enemy_death", 1.1, -3.0)
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
	var jtw = create_tween()
	jtw.tween_property(self, "jawOpen", 1.0, .1)
	jtw.tween_property(self, "jawOpen", 0.0, .06)
	Audio.play("ui_click", .5, -4.0)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .25)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .25)
	await tw.finished
	queue_free()

func _floorPoint(from : Vector3):
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, 3, 0), from + Vector3(0, -8, 0))
	var ex : Array[RID] = [self.get_rid()]
	if _targetValid():
		ex.append(target.get_rid())
	ray.exclude = ex
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position
	return null

func _blocked(from : Vector3, to : Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	var ex : Array[RID] = [self.get_rid()]
	if _targetValid():
		ex.append(target.get_rid())
	ray.exclude = ex
	return space.intersect_ray(ray).size() > 0

func _blinkDest(radius : float):
	if !_targetValid():
		return null
	for i in 16:
		var r = radius if i < 10 else radius * .6
		var ang = randf() * TAU
		var at = target.global_position + Vector3(cos(ang) * r, 0, sin(ang) * r)
		var pnt = _floorPoint(at)
		if pnt == null:
			continue
		var dest = pnt + Vector3(0, .55, 0)
		if _blocked(target.global_position + Vector3(0, 1, 0), dest):
			continue
		return dest
	return null

func _blinkTo(dest : Vector3):
	Audio.play("dash", 1.4, -8.0)
	_spawnParticleAt(burstParticles, global_position)
	var out = create_tween()
	out.set_trans(Tween.TRANS_BACK)
	out.set_ease(Tween.EASE_IN)
	out.tween_property(self, "blinkScale", 0.0, .12)
	await out.finished
	if dead or !is_instance_valid(self):
		return false
	global_position = dest
	velocity = Vector3.ZERO
	_spawnParticleAt(burstParticles, global_position)
	Audio.play("walljump", 1.6, -10.0)
	var back = create_tween()
	back.set_trans(Tween.TRANS_BACK)
	back.set_ease(Tween.EASE_OUT)
	back.tween_property(self, "blinkScale", 1.0, .14)
	return true

func _spawnParticleAt(scene, at : Vector3):
	var p = scene.instantiate()
	get_parent().add_child(p)
	p.global_position = at
	p.emitting = true

func _crank():
	mode = "crank"
	stateTimer = crankTime / buffMult
	var jtw = create_tween()
	jtw.set_trans(Tween.TRANS_QUAD)
	jtw.set_ease(Tween.EASE_OUT)
	jtw.tween_property(self, "jawOpen", 1.0, crankTime / buffMult)
	_crankClicks()

func _crankClicks():
	for i in 3:
		if dead or mode != "crank":
			return
		Audio.play("ui_click", 1.0 + i * .35, -8.0)
		await get_tree().create_timer(crankTime / buffMult / 3.2).timeout
		if !is_instance_valid(self):
			return

func _snap():
	jawOpen = 0.0
	Audio.play("slam", 1.6, -4.0)
	Audio.play("ui_click", .7, -2.0)

func _startLunge():
	if !_targetValid():
		mode = "stalk"
		return
	mode = "lunge"
	stateTimer = 1.0
	lungeDir = target.global_position + Vector3(0, .3, 0) - global_position
	lungeDir.y = 0
	lungeDir = lungeDir.normalized()
	Audio.play("dash", .9, -4.0)

func _endLunge(hit : bool):
	_snap()
	if hit and _targetValid():
		target._takeDamage(damage, global_position)
	mode = "recover"
	stateTimer = recoverTime
	velocity.x = 0
	velocity.z = 0
	var jtw = create_tween()
	jtw.tween_interval(.25)
	jtw.tween_property(self, "jawOpen", .55, .3)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match mode:
		"stalk":
			if _targetValid():
				blinkCd -= delta * buffMult
				velocity.x = move_toward(velocity.x, 0, 20 * delta)
				velocity.z = move_toward(velocity.z, 0, 20 * delta)
				if blinkCd <= 0:
					mode = "blinking"
					_blinkStrike()
		"lunge":
			velocity.x = lungeDir.x * lungeSpeed
			velocity.z = lungeDir.z * lungeSpeed
			stateTimer -= delta
			trailCd -= delta
			if trailCd <= 0:
				trailCd = .05
				_spawnParticleAt(trailParticles, global_position)
			if _targetValid() and global_position.distance_to(target.global_position) < 1.9:
				_endLunge(true)
			elif stateTimer <= 0 or is_on_wall():
				_endLunge(false)
		"crank":
			velocity.x = move_toward(velocity.x, 0, 30 * delta)
			velocity.z = move_toward(velocity.z, 0, 30 * delta)
			stateTimer -= delta
			if stateTimer <= 0:
				_startLunge()
		"recover":
			velocity.x = 0
			velocity.z = 0
			stateTimer -= delta
			if stateTimer <= 0:
				mode = "blinking"
				_blinkAway()

	move_and_slide()

func _blinkStrike():
	var dest = _blinkDest(blinkRange)
	if dest == null:
		mode = "stalk"
		blinkCd = 1.0
		return
	var ok = await _blinkTo(dest)
	if !ok or dead:
		return
	_crank()

func _blinkAway():
	jawOpen = 0.0
	var dest = _blinkDest(retreatRange)
	if dest != null:
		var ok = await _blinkTo(dest)
		if !ok or dead:
			return
	mode = "stalk"
	blinkCd = randf_range(1.0, 1.8)

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	body.scale = baseBodyScale * blinkScale
	jawPivot.rotation.x = jawOpen * .85
	body.position.y = baseBodyY + sin(animTime * 2.6) * .04
	if _targetValid() and mode != "lunge":
		var look = target.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 10.0)
	elif mode == "lunge" and lungeDir.length() > .1:
		rotation.y = atan2(-lungeDir.x, -lungeDir.z)
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
		if mode == "idle":
			mode = "stalk"

func _on_chase_body_exited(bod: Node3D) -> void:
	pass
