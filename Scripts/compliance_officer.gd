extends CharacterBody3D
func _compliance():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(1,.55,.08)

@export var player : Node3D
@export var wallLayer : int = 16
@export var scoreWorth = 9500
@export var health = 300
@export var sightRange : float = 28.0
@export var stageDamage : float = .25
@export var maxHit : float = .35
@export var phase2At : float = .5
@export var hoverHeight : float = 2.2
@export var driftSpeed : float = 2.0
@export var keepDist : float = 12.0
@export var serveGap : float = 3.4
@export var serveWindUp : float = 1.1
@export var orbSpeed : float = 7.0
@export var orbDamage := 20
@export var reverseAt : float = 6.0
@export var staggerTime : float = 2.5
@export var dodgeSpeed : float = 14.0
@export var dodgeAbove : float = 11.0

@onready var body = $body
@onready var face = $body/face
@onready var orbSpawn = $orbSpawn
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var orbScene = preload("res://ObjectScenes/complianceOrb.tscn")
@onready var ringScene = preload("res://ObjectScenes/slamRIng.tscn")
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
var serveCd : float = 0.0
var floorY : float = 0.0
var liveOrb
var busy = false
var dodgeVec : Vector3 = Vector3.ZERO
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
	floorY = _floorLevel()
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE COMPLIANCE OFFICER")
	bossBar.visible = false
	bossIntro = CanvasLayer.new()
	bossIntro.set_script(introScript)
	add_child(bossIntro)
	bossIntro.camFocus = 0.4
	bossIntro.done.connect(_onIntroDone)
	body._updateMat(1.0)
	_refloor.call_deferred()
	await get_tree().physics_frame

func _floorLevel() -> float:
	var space = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 2.0, 0)
	var ray = PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -60, 0))
	ray.exclude = _rayIgnore()
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position.y
	return global_position.y - hoverHeight

func _refloor():
	for i in 4:
		await get_tree().physics_frame
	if dead or !is_instance_valid(self):
		return
	floorY = _floorLevel()

func _onIntroDone():
	if dead:
		return
	if bossBar:
		bossBar.visible = true
	mode = "serving"
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
	serveGap *= .7
	orbSpeed += 2.0
	if bossBar:
		bossBar._setRage()

func _setExposed(on : bool):
	if exposed == on:
		return
	exposed = on
	if on:
		stageDmg = 0.0
	if face:
		face._set_face("panic" if on else "cyclops")
	if bossBar:
		if on:
			bossBar._setStatus("SIGNED", OPEN_COL, true)
		else:
			bossBar._setStatus("NON-COMPLIANT", SHUT_COL)

func _orbTurned(orb):
	if face:
		face._set_face("mad")
	if bossBar and !exposed:
		bossBar._setStatus("RETURN TO SENDER", OPEN_COL, true)
	var to = global_position - orb.global_position
	to.y = 0
	if to.length() < .1:
		to = Vector3.FORWARD
	if orb.speed < dodgeAbove:
		dodgeVec = to.normalized().cross(Vector3.UP).normalized() * dodgeSpeed
	else:
		dodgeVec = Vector3.ZERO

func _orbReturned(mult : float):
	if dead:
		return
	liveOrb = null
	dodgeVec = Vector3.ZERO
	mode = "stagger"
	busy = true
	_setExposed(true)
	util.spawnParticleAt(self, burstParticles, global_position)
	Audio.play("slam", .8, -3.0)
	body._hitPunch()
	if target and target.has_method("_addShake"):
		target._addShake(.12)
	await get_tree().create_timer(staggerTime).timeout
	if dead or !is_instance_valid(self):
		return
	_setExposed(false)
	busy = false
	mode = "serving"
	serveCd = serveGap

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
			away = away.normalized() * 10.0 + Vector3(0, 3.0, 0)
			if bossIntro:
				bossIntro._play("THE COMPLIANCE OFFICER", "REGULATORY AFFAIRS", self, away, 0)
			else:
				_onIntroDone()
		return
	if mode == "intro":
		return

	_drift(delta)
	dodgeVec = dodgeVec.lerp(Vector3.ZERO, clamp(delta * 2.2, 0.0, 1.0))

	if busy:
		return
	if liveOrb != null and !is_instance_valid(liveOrb):
		liveOrb = null
	if liveOrb != null:
		return
	serveCd -= delta
	if serveCd <= 0.0:
		serveCd = serveGap
		_serve()

func _drift(delta : float):
	var to = player.global_position - global_position
	to.y = 0
	var d = to.length()
	var want = dodgeVec
	if d > keepDist + 1.5:
		want += to.normalized() * driftSpeed
	elif d < keepDist - 1.5:
		want += -to.normalized() * driftSpeed
	velocity.x = move_toward(velocity.x, want.x, delta * 9.0)
	velocity.z = move_toward(velocity.z, want.z, delta * 9.0)
	var targY = floorY + hoverHeight + sin(animTime * 1.5) * .2
	velocity.y = (targY - global_position.y) * 2.5
	move_and_slide()
	if d > .3:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), delta * 5.0)

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	body.position.y = bodyBaseY + sin(animTime * 1.7) * .13
	body.rotation.z = sin(animTime * 1.2) * .06
	body.rotation.x = sin(animTime * .9) * .045
	if liveOrb != null and is_instance_valid(liveOrb):
		body.rotation.y = sin(animTime * 6.0) * .08
	else:
		body.rotation.y = lerp(body.rotation.y, 0.0, clamp(delta * 5.0, 0.0, 1.0))

func _serve():
	busy = true
	if bossBar and !exposed:
		bossBar._setStatus("SERVING NOTICE", SHUT_COL, true)
	util.spawnParticleAt(self, muzzleParticles, orbSpawn.global_position)
	Audio.play("rifle", .4, -10.0)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(body, "scale", Vector3(.82, 1.22, .82), serveWindUp * .6)
	tw.tween_property(body, "scale", Vector3.ONE, serveWindUp * .4)
	await get_tree().create_timer(serveWindUp).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	if player == null or !is_instance_valid(player):
		return
	var orb = orbScene.instantiate()
	orb.speed = orbSpeed
	orb.damage = orbDamage
	orb.reverseAt = reverseAt
	orb.owner_boss = self
	get_parent().add_child(orb)
	orb.global_position = orbSpawn.global_position
	orb.dir = orbSpawn.global_position.direction_to(player.global_position + Vector3(0, .8, 0)).normalized()
	orb.add_collision_exception_with(self)
	add_collision_exception_with(orb)
	liveOrb = orb
	if bossBar and !exposed:
		bossBar._setStatus("SHOOT THE ORB", SHUT_COL, true)

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
	Audio.play("enemy_death", .75, 0.0)
	if bossBar:
		bossBar.visible = false
	if target and target.has_method("_onKill"):
		target._onKill()
	if target and target.has_method("_addShake"):
		target._addShake(.2)
	set_physics_process(false)
	if liveOrb != null and is_instance_valid(liveOrb):
		liveOrb.queue_free()
	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.7, .7), randf_range(-.4, .8), randf_range(-.7, .7))
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
