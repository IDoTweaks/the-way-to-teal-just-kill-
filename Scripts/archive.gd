extends CharacterBody3D
func _archive():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(1,.55,.08)

@export var player : Node3D
@export var wallLayer : int = 16
@export var scoreWorth = 9500
@export var health = 300
@export var sightRange : float = 26.0
@export var stageDamage : float = .25
@export var maxHit : float = .35
@export var phase2At : float = .5
@export var drawerGap : float = 3.6
@export var drawerWarn : float = .55
@export var drawerDamage := 16
@export var drawerReach : float = 9.0
@export var drawerSpeed : float = 26.0
@export var cavityTime : float = 2.5
@export var stackDamage := 14
@export var stackRate : float = 7.0
@export var stackMax : float = 12.0
@export var walkSpeed : float = 2.4
@export var keepDist : float = 7.0

@onready var body = $body
@onready var face = $body/face
@onready var drawer = $drawer
@onready var drawerMesh = $drawer/mesh
@onready var sweepArea = $drawer/sweepArea
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var ringScene = preload("res://ObjectScenes/slamRIng.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var hitParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")
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
var atkCd : float = 0.0
var busy = false
var drawerOut = false
var drawerHome : Vector3
var hitThisSweep : Array = []
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
	drawerHome = drawer.position
	sweepArea.monitoring = false
	sweepArea.body_entered.connect(_on_sweep_body_entered)
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE ARCHIVE")
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
	mode = "filing"
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
	drawerGap *= .7
	cavityTime = max(cavityTime - .5, 1.4)
	if bossBar:
		bossBar._setRage()

func _setExposed(on : bool):
	if exposed == on:
		return
	exposed = on
	if on:
		stageDmg = 0.0
	if face:
		face._set_face("panic" if on else "angry")
	if bossBar:
		if on:
			bossBar._setStatus("OPEN FILE", OPEN_COL, true)
		else:
			bossBar._setStatus("SEALED", SHUT_COL)

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
			away = away.normalized() * 10.0
			if bossIntro:
				bossIntro._play("THE ARCHIVE", "RECORDS RETENTION", self, away, 0)
			else:
				_onIntroDone()
		return
	if mode == "intro":
		return

	_walk(delta)

	if busy:
		return
	atkCd -= delta
	if atkCd <= 0.0:
		atkCd = drawerGap
		if randf() < .3:
			_stackSlam()
		else:
			_fireDrawer()

func _walk(delta : float):
	var to = player.global_position - global_position
	to.y = 0
	var d = to.length()
	var want = Vector3.ZERO
	if d > keepDist + 1.5:
		want = to.normalized() * walkSpeed
	elif d < keepDist - 2.5:
		want = -to.normalized() * walkSpeed
	velocity.x = move_toward(velocity.x, want.x, delta * 6.0)
	velocity.z = move_toward(velocity.z, want.z, delta * 6.0)
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if d > .3 and !drawerOut:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), delta * 4.0)

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	if drawerOut:
		body.position.y = bodyBaseY + sin(animTime * 26.0) * .04
		body.rotation.x = lerp(body.rotation.x, -.07, clamp(delta * 8.0, 0.0, 1.0))
		body.rotation.z = sin(animTime * 18.0) * .02
	else:
		var sway = clamp(Vector2(velocity.x, velocity.z).length() * .02, 0.0, .06)
		body.position.y = bodyBaseY + sin(animTime * 1.4) * .05
		body.rotation.x = lerp(body.rotation.x, 0.0, clamp(delta * 5.0, 0.0, 1.0))
		body.rotation.z = sin(animTime * .9) * .03 + sway

func _fireDrawer():
	busy = true
	if bossBar and !exposed:
		bossBar._setStatus("SLIDE UNDER", SHUT_COL, true)
	Audio.play("slam", 1.3, -12.0)
	var wind = create_tween()
	wind.set_trans(Tween.TRANS_BACK)
	wind.tween_property(drawer, "position", drawerHome + Vector3(0, 0, .35), drawerWarn)
	await get_tree().create_timer(drawerWarn).timeout
	if dead or !is_instance_valid(self):
		return

	hitThisSweep.clear()
	drawerOut = true
	sweepArea.monitoring = true
	Audio.play("shotgun", .55, -8.0)
	util.spawnParticleAt(self, dustParticles, drawer.global_position)
	var out = drawerHome + Vector3(0, 0, -drawerReach)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(drawer, "position", out, drawerReach / drawerSpeed)
	await tw.finished
	if dead or !is_instance_valid(self):
		return

	_setExposed(true)
	await get_tree().create_timer(cavityTime).timeout
	if dead or !is_instance_valid(self):
		return

	_setExposed(false)
	sweepArea.monitoring = false
	drawerOut = false
	var back = create_tween()
	back.set_trans(Tween.TRANS_BACK)
	back.set_ease(Tween.EASE_IN_OUT)
	back.tween_property(drawer, "position", drawerHome, .45)
	Audio.play("slam", 1.0, -10.0)
	await back.finished
	if dead or !is_instance_valid(self):
		return
	busy = false

func _on_sweep_body_entered(b : Node3D) -> void:
	if dead or !drawerOut:
		return
	if !b.has_method("player"):
		return
	if hitThisSweep.has(b):
		return
	if b.get("crouched") == true:
		return
	hitThisSweep.append(b)
	if b.has_method("_takeDamage"):
		b._takeDamage(drawerDamage, drawer.global_position)
	if b.has_method("_applyForce"):
		b._applyForce(drawer.global_position, 13.0, 8.0)
	if b.has_method("_addShake"):
		b._addShake(.1)

func _stackSlam():
	busy = true
	if bossBar and !exposed:
		bossBar._setStatus("FILING", SHUT_COL, true)
	Audio.play("slam", .7, -8.0)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(body, "scale", Vector3(1.18, .78, 1.18), .3)
	tw.tween_property(body, "scale", Vector3.ONE, .2)
	await get_tree().create_timer(.5).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	var ring = ringScene.instantiate()
	ring.damage = stackDamage
	ring.expansionRate = stackRate
	ring.maxExpansion = stackMax
	ring.source = self
	get_parent().add_child(ring)
	var base = util.floorPoint(self, global_position, _rayIgnore())
	ring.global_position = base if base != null else global_position
	util.spawnParticleAt(self, burstParticles, global_position)

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
	sweepArea.monitoring = false
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
	var spill = create_tween()
	spill.set_trans(Tween.TRANS_QUAD)
	spill.set_ease(Tween.EASE_IN)
	spill.tween_property(drawer, "position", drawerHome + Vector3(0, -1.2, -drawerReach), .5)
	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.8, .8), randf_range(0, 2.2), randf_range(-.8, .8))
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
