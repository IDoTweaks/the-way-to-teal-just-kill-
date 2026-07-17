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
@export var hopGap : float = 1.7
@export var hopSpeed : float = 7.5
@export var hopUp : float = 8.0
@export var hopSlamDamage := 14

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
@onready var barScript = preload("res://Scripts/boss_bar.gd")

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
var clinkCd : float = 0.0
var tickCd : float = 0.0
var animTime : float = 0.0
var orgBodyScale : Vector3
var ventMat : StandardMaterial3D
var bossBar

func _makeTarg(targ):
	gotShot = true
	target = targ
	if player == null:
		player = targ

func _ready() -> void:
	add_to_group("enemies")
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
		velocity += get_gravity() * delta
	elif hopping:
		hopping = false
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
				if bossBar:
					bossBar.visible = true
				_startPressure()
		"pressure":
			pressure = min(pressure + delta / pressureTime, 1.0)
			_updateHeat(delta)
			_hopThink(delta)
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
	if hopping or !is_on_floor():
		return
	hopCd -= delta
	if hopCd <= 0.0:
		_hop()

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
	body.scale = orgBodyScale * (1.0 + pressure * .14)
	if pressure > .7 and bossBar:
		bossBar._setStatus("OVERPRESSURE", WARN_COL, true)
	tickCd -= delta
	if tickCd <= 0.0:
		tickCd = lerp(.7, .1, pressure)
		Audio.play("ui_hover", lerp(.6, 1.9, pressure), -20.0)

func _vent():
	mode = "vent"
	stateT = ventTime
	damageable = false
	_setExposed(true)
	body.scale = orgBodyScale
	Audio.play("enemy_death", .5, -3.0)
	Audio.play("shotgun", .45, -4.0)
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
	tw.tween_property(body, "scale", orgBodyScale * Vector3(1.15, .78, 1.15), .12)
	tw.tween_property(body, "scale", orgBodyScale, staggerTime - .12)

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
	var dir = player.global_position - global_position
	dir.y = 0
	if dir.length() > .5:
		dir = dir.normalized()
		velocity.x = dir.x * hopSpeed
		velocity.z = dir.z * hopSpeed
	velocity.y = hopUp
	hopping = true
	Audio.play("jump", .55, -9.0)

func _hopLand():
	Audio.play("slam", 1.1, -6.0)
	_spawnParticleAt(dustParticles, global_position)
	var ring = slamRing.instantiate()
	get_parent().add_child(ring)
	ring.global_position = global_position
	ring.source = self
	ring.damage = hopSlamDamage
	if player != null and player.has_method("_addShake"):
		player._addShake(.07)

func _spawnParticleAt(scene, pos : Vector3):
	var p = scene.instantiate()
	get_parent().add_child(p)
	p.global_position = pos
	p.emitting = true

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	if mode == "vent":
		var f = 1.0 + sin(animTime * 22.0) * .06
		ventMesh.scale = Vector3(f, 1.0, f)
		beacon.light_energy = 5.0 + sin(animTime * 18.0) * 1.5
	else:
		ventMesh.scale = Vector3.ONE

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
	for i in 4:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.9, .9), randf_range(.2, 1.8), randf_range(-.9, .9))
		p.emitting = true
		await get_tree().create_timer(.08).timeout
		if !is_instance_valid(self):
			return
	var ventCol = vent.get_node_or_null("CollisionShape3D")
	if ventCol:
		ventCol.set_deferred("disabled", true)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .25)
	tw.tween_property(ventMesh, "scale", Vector3.ZERO, .25)
	await tw.finished
	queue_free()
