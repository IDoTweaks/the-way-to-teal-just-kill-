extends CharacterBody3D
func _kettle():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const HOT_COL = Color(1,.38,0)
const WARN_COL = Color(1,.55,.08)

@export var player : Node3D
@export var scoreWorth = 9000
@export var health = 280
@export var sightRange : float = 26.0
@export var pressureTime : float = 5.0
@export var ventTime : float = 3.5
@export var staggerTime : float = 2.5
@export var stageDamage : float = .25
@export var maxHit : float = .35
@export var ventSlamDamage : float = 55.0
@export var slamBounce : float = 13.0
@export var ventLaunch : float = 12.0
@export var launchRadius : float = 8.0
@export var phase2At : float = .5
@export var acidRadius : float = 5.0
@export var acidCount : int = 8
@export var acidRamp : int = 2
@export var acidMaxCount : int = 16
@export var acidLife : float = 5.0
@export var hopGap : float = 1.0
@export var hopSpeed : float = 7.5
@export var hopUp : float = 8.0
@export var hopSlamDamage := 14
@export var atkGap : float = 2.4
@export var jetRange : float = 5.5
@export var jetWindUp : float = .45
@export var jetDamage := 9
@export var jetKb : float = 16.0
@export var spitCount : int = 2
@export var spitTime : float = 1.1
@export var globDamage := 10
@export var rocketEvery : int = 3
@export var rocketUp : float = 14.0
@export var rocketDamage := 22

@onready var body = $body
@onready var vent = $vent
@onready var ventMesh = $vent/ventMesh
@onready var beacon = $vent/beacon
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var acidScene = preload("res://ObjectScenes/kettleAcid.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var slamParticles = preload("res://Particles/slamImpact.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")
@onready var steamParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var slamRing = preload("res://ObjectScenes/slamRIng.tscn")
@onready var globScene = preload("res://ObjectScenes/kettleGlob.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")
@onready var jumpPuffParticles = preload("res://Particles/jumpPuff.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var barScript = preload("res://Scripts/boss_bar.gd")
@onready var introScript = preload("res://Scripts/boss_intro.gd")

var maxHealth : float
var baseAcid : int
var mode : String = "idle"
var pressure : float = 0.0
var stateT : float = 0.0
var stageDmg : float = 0.0
var damageable = false
var dead = false
var phase = 1
var target
var gotShot = false
var hopCd : float = 0.0
var hopping = false
var hopAir = false
var atkCd : float = 0.0
var busy = false
var hopCount : int = 0
var rocketing = false
var clinkCd : float = 0.0
var tickCd : float = 0.0
var animTime : float = 0.0
var orgBodyScale : Vector3
var squash : Vector3 = Vector3.ONE
var trailCd : float = 0.0
var steamCd : float = 0.0
var whistled = false
var ventFlash : float = 0.0
var ventMat : StandardMaterial3D
var bossBar
var bossIntro

func _onIntroDone():
	if dead:
		return
	if bossBar:
		bossBar.visible = true
	_startPressure()

func _makeTarg(targ):
	gotShot = true
	target = targ
	if player == null:
		player = targ

func _ready() -> void:
	add_to_group("enemies")
	add_collision_exception_with(vent)
	maxHealth = float(health)
	baseAcid = acidCount
	orgBodyScale = body.scale
	if ventMesh.material_override:
		ventMesh.material_override = ventMesh.material_override.duplicate()
		ventMat = ventMesh.material_override
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE KETTLE")
	bossBar.visible = false
	bossIntro = CanvasLayer.new()
	bossIntro.set_script(introScript)
	add_child(bossIntro)
	bossIntro.done.connect(_onIntroDone)
	body._updateMat(1.0)
	_setExposed(false)
	await get_tree().physics_frame

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	_clink()

func _clink():
	if clinkCd > 0.0:
		return
	clinkCd = .07
	Audio.play("enemy_hit", 1.6, -14.0)

func _ventDamage(dmg):
	if dead:
		return
	var cap = maxHealth * stageDamage
	var left = cap - stageDmg
	if !damageable or left <= 0:
		_clink()
		return
	dmg = min(dmg, cap * maxHit)
	dmg = min(dmg, left)
	stageDmg += dmg
	_hurt(dmg)

func _hurt(dmg : float):
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	ventFlash = 1.0
	_spawnParticleAt(burstParticles, vent.global_position)
	_spawnDmgTxt(int(dmg))
	body._updateMat(clamp(float(health) / maxHealth, 0.0, 1.0))
	if bossBar:
		bossBar._setHealth(float(health) / maxHealth)
	if health <= 0:
		_die()
		return
	if phase == 1 and float(health) / maxHealth <= phase2At:
		_enterPhase2()

func _spawnDmgTxt(dmg : int):
	var txt = dmgTxt.instantiate()
	get_parent().add_child(txt)
	txt.global_position = textSpawn.global_position
	txt.damage = dmg

func _enterPhase2():
	phase = 2
	pressureTime *= .65
	hopGap *= .7
	Audio.play("enemy_death", .6, -2.0)
	if bossBar:
		bossBar._setRage()
	if player != null and player.has_method("_addShake"):
		player._addShake(.16)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if clinkCd > 0.0:
		clinkCd -= delta
	if not is_on_floor():
		hopAir = true
		velocity += get_gravity() * delta
	elif hopping and hopAir:
		hopping = false
		hopAir = false
		_hopLand()
	if !hopping:
		velocity.x = move_toward(velocity.x, 0.0, delta * 24.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 24.0)
	move_and_slide()
	_think(delta)

func _think(delta : float):
	match mode:
		"idle":
			if _playerNear(sightRange):
				mode = "intro"
				if bossIntro:
					var away = global_position - player.global_position
					away.y = 0
					if away.length() < .5:
						away = Vector3.BACK
					away = away.normalized() * 13.0
					bossIntro._play("THE KETTLE", "PRESSURE VESSEL", self, away, 3)
				else:
					_onIntroDone()
		"intro":
			pass
		"pressure":
			pressure = min(pressure + delta / pressureTime, 1.0)
			_updateHeat(delta)
			_hopThink(delta)
			_attackThink(delta)
			if pressure >= 1.0:
				_vent()
		"vent":
			stateT -= delta
			if stateT <= 0.0:
				_ventMissed()
		"stagger":
			stateT -= delta
			if stateT <= 0.0:
				_startPressure()

func _hopThink(delta : float):
	if hopping or busy or !is_on_floor():
		return
	hopCd -= delta
	if hopCd <= 0.0:
		hopCount += 1
		if phase == 2 and hopCount % rocketEvery == 0:
			_rocketHop()
		else:
			_hop()

func _attackThink(delta : float):
	if busy or hopping:
		return
	atkCd -= delta
	if atkCd <= 0.0:
		atkCd = atkGap
		if _playerNear(jetRange):
			_steamJet()
		else:
			_spit()

func _steamJet():
	busy = true
	Audio.play("rifle", .5, -13.0)
	_spawnParticleAt(steamParticles, global_position + Vector3(0, 1.6, 0))
	await get_tree().create_timer(jetWindUp).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	if !_playerNear(jetRange) or player == null:
		return
	Audio.play("shotgun", 1.25, -7.0)
	_spawnParticleAt(dustParticles, global_position)
	if player.has_method("_takeDamage"):
		player._takeDamage(jetDamage, global_position)
	if player.has_method("_applyForce"):
		player._applyForce(global_position, jetKb, jetRange)
	if player.has_method("_addShake"):
		player._addShake(.09)

func _spit():
	if player == null or !is_instance_valid(player):
		return
	busy = true
	Audio.play("ui_hover", .5, -14.0)
	for i in spitCount:
		if dead or !is_instance_valid(self) or player == null:
			return
		var from = vent.global_position
		var to = player.global_position
		if i > 0:
			var ang = randf() * TAU
			to += Vector3(cos(ang) * 2.4, 0, sin(ang) * 2.4)
		var g = instantiate_glob(from, to)
		Audio.play("shotgun", 1.5, -12.0)
		_spawnParticleAt(steamParticles, from)
		await get_tree().create_timer(.22).timeout
	if !is_instance_valid(self):
		return
	busy = false

func instantiate_glob(from : Vector3, to : Vector3):
	var g = globScene.instantiate()
	get_parent().add_child(g)
	g.global_position = from
	g.damage = globDamage
	g.velocity = _lobVelocity(from, to, spitTime)
	add_collision_exception_with(g)
	g.add_collision_exception_with(self)
	g.add_collision_exception_with(vent)
	return g

func _lobVelocity(from : Vector3, to : Vector3, t : float) -> Vector3:
	var g = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var d = to - from
	var v = Vector3.ZERO
	v.x = d.x / t
	v.z = d.z / t
	v.y = (d.y + .5 * g * t * t) / t
	return v

func _rocketHop():
	hopCd = hopGap
	rocketing = true
	busy = true
	Audio.play("ui_hover", 1.6, -10.0)
	Audio.play("walljump", 1.7, -10.0)
	_spawnParticleAt(steamParticles, global_position + Vector3(0, .4, 0))
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "squash", Vector3(1.3, .62, 1.3), .28)
	await tw.finished
	if dead or !is_instance_valid(self):
		return
	busy = false
	if player == null or !is_instance_valid(player):
		rocketing = false
		return
	var dir = player.global_position - global_position
	dir.y = 0
	if dir.length() > .5:
		dir = dir.normalized()
		velocity.x = dir.x * hopSpeed * 1.3
		velocity.z = dir.z * hopSpeed * 1.3
	velocity.y = rocketUp
	hopping = true
	hopAir = false
	Audio.play("jump", .4, -4.0)
	_spawnParticleAt(dustParticles, global_position)

func _playerNear(r : float) -> bool:
	if player == null or !is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= r

func _startPressure():
	mode = "pressure"
	pressure = 0.0
	damageable = false
	stageDmg = 0.0
	hopCd = hopGap
	_setExposed(false)
	if bossBar:
		bossBar._setStatus("ARMOURED", WARN_COL)

func _updateHeat(delta : float):
	if ventMat != null:
		ventMat.emission = HOT_COL
		ventMat.emission_energy_multiplier = pressure * 3.0
	beacon.light_energy = pressure * 2.0
	beacon.light_color = HOT_COL
	if pressure > .7 and bossBar:
		bossBar._setStatus("OVERPRESSURE", WARN_COL, true)
	if pressure > .82 and !whistled:
		whistled = true
		Audio.play("walljump", 1.9, -6.0)
		Audio.play("ui_hover", 2.0, -12.0)
		if player != null and player.has_method("_addShake"):
			player._addShake(.04)
	if pressure > .82:
		steamCd -= delta
		if steamCd <= 0.0:
			steamCd = .13
			_spawnParticleAt(steamParticles, vent.global_position)
	tickCd -= delta
	if tickCd <= 0.0:
		tickCd = lerp(.7, .1, pressure)
		Audio.play("ui_hover", lerp(.6, 1.9, pressure), -20.0)

func _vent():
	mode = "vent"
	stateT = ventTime
	whistled = false
	damageable = false
	_setExposed(true)
	var bt = create_tween()
	bt.set_trans(Tween.TRANS_ELASTIC)
	bt.set_ease(Tween.EASE_OUT)
	bt.tween_property(self, "squash", Vector3(.82, 1.24, .82), .1)
	bt.tween_property(self, "squash", Vector3.ONE, .5)
	Audio.play("enemy_death", .5, -3.0)
	Audio.play("shotgun", .45, -4.0)
	Audio.play("walljump", 2.0, -4.0)
	if bossBar:
		bossBar._setStatus("SLAM THE VENT", OPEN_COL, true)
	if player != null and player.has_method("_addShake"):
		player._addShake(.12)
	_spawnParticleAt(dustParticles, global_position)
	_spawnParticleAt(steamParticles, vent.global_position)
	_spawnAcid()
	_launchPlayer()

func _launchPlayer():
	if !_playerNear(launchRadius) or player == null:
		return
	if "slamming" in player:
		player.slamming = false
	if "velocity" in player:
		player.velocity.y = ventLaunch
	Audio.play("jump", .8, -4.0)

func _ventMissed():
	acidCount = min(acidCount + acidRamp, acidMaxCount)
	Audio.play("enemy_hit", .5, -10.0)
	_startPressure()

func _ventSlammed(by):
	if dead or mode != "vent":
		return
	if by != null:
		_makeTarg(by)
	mode = "stagger"
	stateT = staggerTime
	damageable = true
	stageDmg = 0.0
	pressure = 0.0
	acidCount = baseAcid
	Audio.play("slam", .8, 0.0)
	Audio.play("enemy_death", .4, -4.0)
	if bossBar:
		bossBar._setStatus("EXPOSED", OPEN_COL)
	_spawnParticleAt(slamParticles, vent.global_position)
	_spawnParticleAt(dustParticles, global_position)
	if by != null:
		if by.has_method("_addShake"):
			by._addShake(.14)
		if "slamming" in by:
			by.slamming = false
		if "velocity" in by:
			by.velocity.y = slamBounce
	_hurt(ventSlamDamage)
	if !dead:
		_droop()

func _droop():
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "squash", Vector3(1.18, .74, 1.18), .12)
	tw.tween_property(self, "squash", Vector3.ONE, staggerTime - .12)

func _setExposed(on : bool):
	beacon.light_energy = 6.0 if on else 0.0
	beacon.light_color = OPEN_COL if on else HOT_COL
	if ventMat == null:
		return
	ventMat.emission_enabled = true
	ventMat.emission = OPEN_COL if on else HOT_COL
	ventMat.emission_energy_multiplier = 5.0 if on else 0.0

func _spawnAcid():
	for i in acidCount:
		var ang = TAU * float(i) / float(acidCount) + randf_range(-.25, .25)
		var r = acidRadius + randf_range(-1.2, 1.2)
		var from = global_position + Vector3(cos(ang) * r, 0, sin(ang) * r)
		var pnt = _floorPoint(from)
		if pnt == null:
			continue
		var a = acidScene.instantiate()
		get_parent().add_child(a)
		a.global_position = pnt
		a.lifeTime = acidLife

func _floorPoint(from : Vector3):
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, 2.5, 0), from + Vector3(0, -6, 0))
	ray.exclude = [self.get_rid()]
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position + Vector3(0, .04, 0)
	return null

func _hop():
	hopCd = hopGap
	if player == null or !is_instance_valid(player):
		return
	busy = true
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "squash", Vector3(1.2, .74, 1.2), .13)
	await tw.finished
	if dead or !is_instance_valid(self) or player == null:
		return
	busy = false
	var dir = player.global_position - global_position
	dir.y = 0
	if dir.length() > .5:
		dir = dir.normalized()
		velocity.x = dir.x * hopSpeed
		velocity.z = dir.z * hopSpeed
	velocity.y = hopUp
	hopping = true
	hopAir = false
	Audio.play("jump", .55, -9.0)
	Audio.play("ui_hover", 1.4, -18.0)
	_spawnParticleAt(jumpPuffParticles, global_position)
	var st = create_tween()
	st.set_trans(Tween.TRANS_BACK)
	st.set_ease(Tween.EASE_OUT)
	st.tween_property(self, "squash", Vector3(.86, 1.2, .86), .16)
	st.tween_property(self, "squash", Vector3.ONE, .22)

func _hopLand():
	var rocket = rocketing
	rocketing = false
	Audio.play("slam", .8 if rocket else 1.1, -2.0 if rocket else -6.0)
	_spawnParticleAt(dustParticles, global_position)
	_spawnParticleAt(jumpPuffParticles, global_position)
	var lt = create_tween()
	lt.set_trans(Tween.TRANS_BACK)
	lt.set_ease(Tween.EASE_OUT)
	lt.tween_property(self, "squash", Vector3(1.3, .68, 1.3) if rocket else Vector3(1.16, .82, 1.16), .09)
	lt.tween_property(self, "squash", Vector3.ONE, .26)
	if rocket:
		_spawnParticleAt(slamParticles, global_position)
	var ring = slamRing.instantiate()
	get_parent().add_child(ring)
	ring.global_position = global_position
	ring.source = self
	ring.damage = rocketDamage if rocket else hopSlamDamage
	if rocket:
		ring.expansionRate = 9.0
	if player != null and player.has_method("_addShake"):
		player._addShake(.16 if rocket else .07)
	if rocket:
		for i in 3:
			var ang = randf() * TAU
			var pnt = _floorPoint(global_position + Vector3(cos(ang) * 3.0, 0, sin(ang) * 3.0))
			if pnt == null:
				continue
			var a = acidScene.instantiate()
			get_parent().add_child(a)
			a.global_position = pnt
			a.lifeTime = acidLife * .7
			a.scale = Vector3(.7, 1, .7)

func _spawnParticleAt(scene, pos : Vector3):
	var p = scene.instantiate()
	get_parent().add_child(p)
	p.global_position = pos
	p.emitting = true

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	var wob = 1.0 + sin(animTime * 2.2) * .012
	body.scale = orgBodyScale * (1.0 + pressure * .14) * squash * wob
	body.rotation.z = sin(animTime * 1.7) * .025
	ventFlash = move_toward(ventFlash, 0.0, delta * 4.0)
	if hopping:
		trailCd -= delta
		if trailCd <= 0.0:
			trailCd = .07
			_spawnParticleAt(trailParticles, global_position + Vector3(0, .5, 0))
	if mode == "vent":
		var f = 1.0 + sin(animTime * 22.0) * .06
		ventMesh.scale = Vector3(f, 1.0, f)
		beacon.light_energy = 5.0 + sin(animTime * 18.0) * 1.5
		steamCd -= delta
		if steamCd <= 0.0:
			steamCd = .09
			_spawnParticleAt(steamParticles, vent.global_position + Vector3(0, .3, 0))
	else:
		ventMesh.scale = Vector3.ONE
	if ventMat != null and ventFlash > 0.0:
		ventMat.emission_energy_multiplier += ventFlash * 6.0

func _on_slam_area_body_entered(body: Node3D) -> void:
	if dead or mode != "vent":
		return
	if body.has_method("player") and "slamming" in body and body.slamming:
		_ventSlammed(body)

func _die():
	if dead:
		return
	dead = true
	damageable = false
	_setExposed(false)
	body._killTweens()
	body._updateMat(0)
	Audio.play("enemy_death", .7, 0.0)
	if bossBar:
		bossBar.visible = false
	if target and target.has_method("_onKill"):
		target._onKill()
	if target and target.has_method("_addShake"):
		target._addShake(.2)
	set_physics_process(false)
	var ventCol = vent.get_node_or_null("CollisionShape3D")
	if ventCol:
		ventCol.set_deferred("disabled", true)

	Audio.play("walljump", 2.0, -2.0)
	Audio.play("shotgun", .5, -2.0)
	_spawnParticleAt(steamParticles, vent.global_position)
	_spawnParticleAt(burstParticles, vent.global_position)
	var lid = create_tween()
	lid.set_parallel(true)
	lid.set_trans(Tween.TRANS_QUAD)
	lid.set_ease(Tween.EASE_OUT)
	lid.tween_property(vent, "position:y", vent.position.y + 7.0, .55)
	lid.tween_property(vent, "position:x", randf_range(-2.5, 2.5), .55)
	lid.tween_property(vent, "rotation:x", randf_range(6.0, 10.0), .55)

	var shake = create_tween()
	shake.set_loops(4)
	shake.tween_property(body, "scale", orgBodyScale * Vector3(1.14, .9, 1.14), .05)
	shake.tween_property(body, "scale", orgBodyScale * Vector3(.9, 1.12, .9), .05)

	for i in 4:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.9, .9), randf_range(.2, 1.8), randf_range(-.9, .9))
		p.emitting = true
		Audio.play("enemy_death", randf_range(.5, .9), -6.0)
		await get_tree().create_timer(.09).timeout
		if !is_instance_valid(self):
			return
	_spawnParticleAt(slamParticles, global_position)
	_spawnParticleAt(dustParticles, global_position)
	Audio.play("slam", .6, 0.0)
	if shake:
		shake.kill()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .25)
	tw.tween_property(ventMesh, "scale", Vector3.ZERO, .25)
	await tw.finished
	queue_free()
