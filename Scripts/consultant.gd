extends CharacterBody3D
func _consultant():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(1,.55,.08)

@export var player : Node3D
@export var wallLayer : int = 16
@export var scoreWorth = 9500
@export var health = 300
@export var sightRange : float = 28.0
@export var stageDamage : float = .18
@export var maxHit : float = .35
@export var phase2At : float = .5
@export var speedGate : float = 8.0
@export var holdTime : float = 1.5
@export var windowReset : float = 1.6
@export var walkSpeed : float = 3.4
@export var keepDist : float = 9.0
@export var atkGap : float = 3.2
@export var deckCount : int = 3
@export var deckWarn : float = 1.1
@export var deckDamage := 14
@export var deckLead : float = 1.1
@export var reviewDamage := 16
@export var reviewRate : float = 8.0
@export var reviewMax : float = 12.0
@export var reviewRange : float = 11.0
@export var retainerDamage := 12

@onready var body = $body
@onready var face = $body/face
@onready var textSpawn = $textSpawn
@onready var handSpawn = $handSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var runeScene = preload("res://ObjectScenes/runeMark.tscn")
@onready var ringScene = preload("res://ObjectScenes/slamRIng.tscn")
@onready var noticeScene = preload("res://ObjectScenes/evictionNotice.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var hitParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var barScript = preload("res://Scripts/boss_bar.gd")
@onready var introScript = preload("res://Scripts/boss_intro.gd")
@onready var util = preload("res://Scripts/boss_util.gd")

var maxHealth : float
var mode : String = "idle"
var exposed = false
var stageDmg : float = 0.0
var dead = false
var phase = 1
var target
var gotShot = false
var aggro = false
var clinkCd : float = 0.0
var animTime : float = 0.0
var bodyBaseY : float = 0.0
var walkPhase : float = 0.0
var atkCd : float = 0.0
var fastT : float = 0.0
var windowT : float = 0.0
var lastAtk : String = ""
var busy = false
var bossBar
var bossIntro

func _makeTarg(targ):
	gotShot = true
	target = targ
	aggro = true
	if player == null:
		player = targ

func _ready() -> void:
	add_to_group("enemies")
	bodyBaseY = body.position.y
	maxHealth = float(health)
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE CONSULTANT")
	bossBar.visible = false
	bossIntro = CanvasLayer.new()
	bossIntro.set_script(introScript)
	add_child(bossIntro)
	bossIntro.done.connect(_onIntroDone)
	body._updateMat(1.0)
	await get_tree().physics_frame

func _onIntroDone():
	if dead:
		return
	if bossBar:
		bossBar.visible = true
	mode = "stalk"
	_setExposed(false)

func _takeDamage(dmg):
	if dead:
		return
	if dmg >= 9999.0 or global_position.y < -50.0:
		health = 0
		_die()
		return
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	if !exposed:
		_clink()
		return
	var got = util.windowDamage(self, dmg)
	if got <= 0.0:
		_clink()
		return
	_hurt(got)

func _clink():
	if clinkCd > 0.0:
		return
	clinkCd = .07
	Audio.play("enemy_hit", 1.6, -14.0)

func _hurt(dmg : float):
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	body._hitPunch()
	util.spawnParticleAt(self, hitParticles, textSpawn.global_position)
	util.spawnDmgTxt(self, dmgTxt, textSpawn.global_position, int(dmg))
	body._updateMat(clamp(float(health) / maxHealth, 0.0, 1.0))
	if bossBar:
		bossBar._setHealth(float(health) / maxHealth)
	if health <= 0:
		_die()
		return
	if phase == 1 and float(health) / maxHealth <= phase2At:
		_enterPhase2()

func _enterPhase2():
	phase = 2
	speedGate += 1.5
	holdTime = max(holdTime - .3, 1.0)
	atkGap *= .75
	deckCount += 1
	if bossBar:
		bossBar._setRage()

func _setExposed(on : bool):
	if exposed == on:
		return
	exposed = on
	if on:
		stageDmg = 0.0
		windowT = windowReset
	if face:
		face._set_face("panic" if on else "visor")
	if bossBar:
		if on:
			bossBar._setStatus("EXPOSED", OPEN_COL, true)
		else:
			bossBar._setStatus("UNIMPRESSED", SHUT_COL)

func _playerSpeed() -> float:
	if player == null or !is_instance_valid(player):
		return 0.0
	if !("velocity" in player):
		return 0.0
	return Vector2(player.velocity.x, player.velocity.z).length()

func _physics_process(delta: float) -> void:
	if dead:
		return
	if clinkCd > 0.0:
		clinkCd -= delta
	if player == null or !is_instance_valid(player):
		return
	if !aggro:
		if global_position.distance_to(player.global_position) <= sightRange:
			aggro = true
			mode = "intro"
			var away = global_position - player.global_position
			away.y = 0
			if away.length() < .5:
				away = Vector3.BACK
			away = away.normalized() * 11.0
			if bossIntro:
				bossIntro._play("THE CONSULTANT", "PRODUCTIVITY AUDIT", self, away, 0)
			else:
				_onIntroDone()
		return
	if mode == "intro":
		return

	if _playerSpeed() >= speedGate:
		fastT = holdTime
	else:
		fastT = max(fastT - delta, 0.0)
	_setExposed(fastT > 0.0)

	if exposed:
		windowT -= delta
		if windowT <= 0.0:
			windowT = windowReset
			stageDmg = 0.0

	_walk(delta)

	if busy:
		return
	atkCd -= delta
	if atkCd <= 0.0:
		atkCd = atkGap
		_attack()

func _walk(delta : float):
	var to = player.global_position - global_position
	to.y = 0
	var d = to.length()
	var want = Vector3.ZERO
	if d > keepDist + 1.5:
		want = to.normalized() * walkSpeed
	elif d < keepDist - 1.5:
		want = -to.normalized() * walkSpeed
	velocity.x = move_toward(velocity.x, want.x, delta * 8.0)
	velocity.z = move_toward(velocity.z, want.z, delta * 8.0)
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if d > .3:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), delta * 6.0)

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	var spd = Vector2(velocity.x, velocity.z).length()
	var stride = clamp(spd / max(walkSpeed, .01), 0.0, 1.0)
	walkPhase += delta * (5.0 + spd * 2.2)
	body.position.y = bodyBaseY + abs(sin(walkPhase)) * .11 * stride
	body.rotation.z = sin(walkPhase) * .075 * stride
	body.rotation.x = lerp(body.rotation.x, -stride * .08, clamp(delta * 5.0, 0.0, 1.0))
	if exposed:
		body.rotation.y = sin(animTime * 11.0) * .07
	else:
		body.rotation.y = lerp(body.rotation.y, 0.0, clamp(delta * 6.0, 0.0, 1.0))

func _attack():
	var pool = ["deck", "review", "retainer"]
	pool.erase(lastAtk)
	var pick = pool[randi() % pool.size()]
	lastAtk = pick
	match pick:
		"deck": _slideDeck()
		"review": _performanceReview()
		_: _retainer()

func _slideDeck():
	busy = true
	if bossBar and !exposed:
		bossBar._setStatus("SLIDE DECK", SHUT_COL, true)
	util.spawnParticleAt(self, muzzleParticles, handSpawn.global_position)
	Audio.play("rifle", .55, -12.0)
	await get_tree().create_timer(.3).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	if player == null or !is_instance_valid(player):
		return
	var lead = Vector3.ZERO
	if "velocity" in player:
		lead = Vector3(player.velocity.x, 0, player.velocity.z) * deckLead
	var base = player.global_position + lead
	var step = Vector3.ZERO
	if lead.length() > .5:
		step = lead.normalized() * 3.2
	else:
		step = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 3.2
	for i in deckCount:
		if dead or !is_instance_valid(self):
			return
		var at = base + step * (float(i) - float(deckCount - 1) * .5)
		var spot = util.floorPoint(self, at, _rayIgnore())
		if spot == null:
			spot = Vector3(at.x, global_position.y - 1.0, at.z)
		var m = runeScene.instantiate()
		m.warnTime = deckWarn
		m.damage = deckDamage
		get_parent().add_child(m)
		m.global_position = spot
		await get_tree().create_timer(.1).timeout

func _performanceReview():
	busy = true
	if bossBar and !exposed:
		bossBar._setStatus("PERFORMANCE REVIEW", SHUT_COL, true)
	Audio.play("slam", .85, -7.0)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(body, "scale", Vector3(1.2, .72, 1.2), .3)
	tw.tween_property(body, "scale", Vector3.ONE, .2)
	await get_tree().create_timer(.5).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	var ring = ringScene.instantiate()
	ring.damage = reviewDamage
	ring.expansionRate = reviewRate
	ring.maxExpansion = reviewMax
	ring.source = self
	get_parent().add_child(ring)
	var base = util.floorPoint(self, global_position, _rayIgnore())
	ring.global_position = base if base != null else global_position
	util.spawnParticleAt(self, burstParticles, global_position)

func _retainer():
	busy = true
	if bossBar and !exposed:
		bossBar._setStatus("RETAINER", SHUT_COL, true)
	util.spawnParticleAt(self, muzzleParticles, handSpawn.global_position)
	Audio.play("rifle", .7, -10.0)
	await get_tree().create_timer(.35).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	if player == null or !is_instance_valid(player):
		return
	var n = noticeScene.instantiate()
	n.damage = retainerDamage
	n.target = player
	get_parent().add_child(n)
	n.global_position = handSpawn.global_position
	var dir = (player.global_position - handSpawn.global_position).normalized()
	if "dir" in n:
		n.dir = dir
	if n is CollisionObject3D:
		n.add_collision_exception_with(self)
		add_collision_exception_with(n)

func _rayIgnore() -> Array[RID]:
	var skip : Array[RID] = [self.get_rid()]
	if player != null and is_instance_valid(player):
		skip.append(player.get_rid())
	return skip

func _die():
	if dead:
		return
	dead = true
	exposed = false
	mode = "dead"
	body._killTweens()
	body._updateMat(0)
	Audio.play("enemy_death", .9, 0.0)
	if bossBar:
		bossBar.visible = false
	if target and target.has_method("_onKill"):
		target._onKill()
	if target and target.has_method("_addShake"):
		target._addShake(.2)
	set_physics_process(false)
	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.6, .6), randf_range(-.3, 1.0), randf_range(-.6, .6))
		p.emitting = true
		await get_tree().create_timer(.09).timeout
		if !is_instance_valid(self):
			return
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ONE * .01, .35)
	await tw.finished
	if is_instance_valid(self):
		queue_free()
