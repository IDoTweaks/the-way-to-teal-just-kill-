extends CharacterBody3D
func _notary():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(1,.55,.08)

@export var player : Node3D
@export var wallLayer : int = 16
@export var scoreWorth = 9500
@export var health = 290
@export var sightRange : float = 26.0
@export var stageDamage : float = .25
@export var maxHit : float = .35
@export var phase2At : float = .5
@export var walkSpeed : float = 3.0
@export var keepDist : float = 6.0
@export var turnRate : float = 2.6
@export var boardOpen : float = 1.1
@export var atkGap : float = 3.4
@export var windowReset : float = 2.0
@export var serveWindUp : float = .7
@export var serveDamage := 10
@export var serveRange : float = 4.2
@export var serveLunge : float = 17.0
@export var stampCost : float = 1.25
@export var stampMax : int = 3
@export var stampDrain : float = 35.0
@export var fileCount : int = 3
@export var fileSpread : float = .3
@export var fileDamage := 12
@export var initialDrain : float = 40.0
@export var initialWarn : float = 1.1

@onready var body = $body
@onready var face = $body/face
@onready var clipboard = $clipboard
@onready var noticeSpawn = $noticeSpawn
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var noticeScene = preload("res://ObjectScenes/evictionNotice.tscn")
@onready var runeScene = preload("res://ObjectScenes/runeMark.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var hitParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var barScript = preload("res://Scripts/boss_bar.gd")
@onready var introScript = preload("res://Scripts/boss_intro.gd")
@onready var util = preload("res://Scripts/boss_util.gd")

var maxHealth : float
var mode : String = "idle"
var stageDmg : float = 0.0
var windowT : float = 0.0
var dead = false
var phase = 1
var target
var gotShot = false
var aggro = false
var clinkCd : float = 0.0
var animTime : float = 0.0
var bodyBaseY : float = 0.0
var clipBaseY : float = 0.0
var walkPhase : float = 0.0
var boardTween : Tween
var atkCd : float = 0.0
var stamps : int = 0
var orgStamCost : float = -1.0
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
	clipBaseY = clipboard.position.y
	maxHealth = float(health)
	add_collision_exception_with(clipboard)
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE NOTARY")
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
	mode = "serving"
	_showStatus()

func _showStatus():
	if bossBar == null:
		return
	if stamps > 0:
		bossBar._setStatus("PAPERWORK x%d" % stamps, SHUT_COL)
	else:
		bossBar._setStatus("UNSIGNED", SHUT_COL)

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
		bossBar._setStatus("COUNTERSIGNED", OPEN_COL, true)
	if face:
		face._set_face("panic")
	if health <= 0:
		_die()
		return
	if phase == 1 and float(health) / maxHealth <= phase2At:
		_enterPhase2()

func _enterPhase2():
	phase = 2
	atkGap *= .75
	fileCount += 1
	if bossBar:
		bossBar._setRage()

func _stamp():
	if player == null or !is_instance_valid(player):
		return
	if !("upStamCost" in player):
		return
	if orgStamCost < 0.0:
		orgStamCost = player.upStamCost
	if stamps >= stampMax:
		return
	stamps += 1
	player.upStamCost *= stampCost
	Audio.play("ui_click", .5, -6.0)
	_showStatus()

func _clearStamps():
	if player != null and is_instance_valid(player) and orgStamCost >= 0.0 and ("upStamCost" in player):
		player.upStamCost = orgStamCost
	stamps = 0
	orgStamCost = -1.0

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
				bossIntro._play("THE NOTARY", "DEEDS AND SEALS", self, away, 0)
			else:
				_onIntroDone()
		return
	if mode == "intro":
		return

	windowT -= delta
	if windowT <= 0.0:
		windowT = windowReset
		stageDmg = 0.0
		if face and stamps < stampMax:
			face._set_face("grin")
		_showStatus()

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
	elif d < keepDist - 2.0:
		want = -to.normalized() * walkSpeed
	velocity.x = move_toward(velocity.x, want.x, delta * 7.0)
	velocity.z = move_toward(velocity.z, want.z, delta * 7.0)
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if d > .3:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), delta * turnRate)

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	var spd = Vector2(velocity.x, velocity.z).length()
	var stride = clamp(spd / max(walkSpeed, .01), 0.0, 1.0)
	walkPhase += delta * (4.5 + spd * 2.0)
	body.position.y = bodyBaseY + abs(sin(walkPhase)) * .09 * stride + sin(animTime * 1.2) * .03
	body.rotation.z = sin(walkPhase) * .06 * stride
	clipboard.rotation.z = sin(animTime * 1.3) * .07
	if boardTween == null or !boardTween.is_running():
		clipboard.position.y = clipBaseY + sin(animTime * 1.6) * .06

func _attack():
	var pool = ["serve", "file", "initial"]
	pool.erase(lastAtk)
	var pick = pool[randi() % pool.size()]
	lastAtk = pick
	match pick:
		"serve": _serve()
		"file": _file()
		_: _initialHere()

func _serve():
	busy = true
	if bossBar:
		bossBar._setStatus("SERVE", SHUT_COL, true)
	Audio.play("dash", .7, -9.0)
	var rear = create_tween()
	rear.set_trans(Tween.TRANS_BACK)
	rear.tween_property(clipboard, "position:z", clipboard.position.z + .5, serveWindUp)
	await get_tree().create_timer(serveWindUp).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	if player == null or !is_instance_valid(player):
		return
	var to = player.global_position - global_position
	to.y = 0
	velocity.x = to.normalized().x * serveLunge
	velocity.z = to.normalized().z * serveLunge
	var back = create_tween()
	back.set_trans(Tween.TRANS_BACK)
	back.tween_property(clipboard, "position:z", clipboard.position.z, .25)
	util.spawnParticleAt(self, burstParticles, clipboard.global_position)
	_dropBoard()
	await get_tree().create_timer(.22).timeout
	if dead or !is_instance_valid(self) or player == null or !is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) <= serveRange:
		if player.has_method("_takeDamage"):
			player._takeDamage(serveDamage, global_position)
		if player.has_method("_drainStamina"):
			player._drainStamina(stampDrain)
		if player.has_method("_applyForce"):
			player._applyForce(global_position, 11.0, serveRange + 2.0)
		_stamp()
		Audio.play("slam", 1.1, -6.0)

func _dropBoard():
	if dead or boardTween != null and boardTween.is_running():
		return
	boardTween = create_tween()
	boardTween.set_trans(Tween.TRANS_BACK)
	boardTween.set_ease(Tween.EASE_OUT)
	boardTween.tween_property(clipboard, "position:y", clipBaseY - 1.5, .18)
	boardTween.parallel().tween_property(clipboard, "rotation:x", 1.25, .18)
	boardTween.tween_interval(boardOpen)
	boardTween.tween_property(clipboard, "position:y", clipBaseY, .3)
	boardTween.parallel().tween_property(clipboard, "rotation:x", 0.0, .3)

func _file():
	busy = true
	if bossBar:
		bossBar._setStatus("FILE", SHUT_COL, true)
	for i in fileCount:
		if dead or !is_instance_valid(self):
			return
		if player == null or !is_instance_valid(player):
			break
		Audio.play("rifle", .6, -12.0)
		util.spawnParticleAt(self, muzzleParticles, noticeSpawn.global_position)
		var n = noticeScene.instantiate()
		get_parent().add_child(n)
		n.global_position = noticeSpawn.global_position
		n.target = player
		n.damage = fileDamage
		var aim = noticeSpawn.global_position.direction_to(player.global_position + Vector3(0, .8, 0))
		aim.x += randf_range(-fileSpread, fileSpread)
		aim.z += randf_range(-fileSpread, fileSpread)
		n.dir = aim.normalized()
		add_collision_exception_with(n)
		n.add_collision_exception_with(self)
		await get_tree().create_timer(.2).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false

func _initialHere():
	busy = true
	if bossBar:
		bossBar._setStatus("INITIAL HERE", SHUT_COL, true)
	Audio.play("ui_click", .6, -9.0)
	await get_tree().create_timer(.3).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	if player == null or !is_instance_valid(player):
		return
	var pnt = util.floorPoint(self, player.global_position, _rayIgnore())
	if pnt == null:
		return
	var m = runeScene.instantiate()
	m.drain = initialDrain
	m.warnTime = initialWarn
	get_parent().add_child(m)
	m.global_position = pnt

func _rayIgnore() -> Array[RID]:
	var skip : Array[RID] = [self.get_rid()]
	if player != null and is_instance_valid(player):
		skip.append(player.get_rid())
	if clipboard != null and clipboard is CollisionObject3D:
		skip.append(clipboard.get_rid())
	return skip

func _die():
	if dead:
		return
	dead = true
	mode = "dead"
	_clearStamps()
	body._killTweens()
	body._updateMat(0)
	Audio.play("enemy_death", .85, 0.0)
	if bossBar:
		bossBar.visible = false
	if target and target.has_method("_onKill"):
		target._onKill()
	if target and target.has_method("_addShake"):
		target._addShake(.2)
	set_physics_process(false)
	var col = clipboard.get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	var drop = create_tween()
	drop.set_parallel(true)
	drop.set_trans(Tween.TRANS_QUAD)
	drop.set_ease(Tween.EASE_IN)
	drop.tween_property(clipboard, "rotation:x", 1.9, .5)
	drop.tween_property(clipboard, "position:y", clipboard.position.y - 1.6, .5)
	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.6, .6), randf_range(-.3, 1.2), randf_range(-.6, .6))
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

func _exit_tree() -> void:
	_clearStamps()
