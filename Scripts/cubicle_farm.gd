extends CharacterBody3D
func _cubicleFarm():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(1,.55,.08)

@export var player : Node3D
@export var wallLayer : int = 16
@export var scoreWorth = 9500
@export var health = 320
@export var sightRange : float = 30.0
@export var stageDamage : float = .25
@export var maxHit : float = .35
@export var phase2At : float = .5
@export var hoverHeight : float = 6.0
@export var driftSpeed : float = 1.6
@export var perchDrift : float = 5.0
@export var breachHeight : float = 3.0
@export var windowReset : float = 2.0
@export var wallGap : float = 5.5
@export var wallH : float = 5.0
@export var wallW : float = 6.0
@export var wallThird : float = .75
@export var atkGap : float = 4.0
@export var memoCount : int = 5
@export var memoWarn : float = .9
@export var memoDamage := 14
@export var ringDamage := 16
@export var ringRate : float = 8.0
@export var ringMax : float = 14.0
@export var reorgGap : float = 9.0
@export var reorgTime : float = 1.2

@onready var body = $body
@onready var face = $body/face
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var runeScene = preload("res://ObjectScenes/runeMark.tscn")
@onready var ringScene = preload("res://ObjectScenes/slamRIng.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var hitParticles = preload("res://Particles/enemyBulletImpact.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var wallMat = preload("res://shaders/new_standard_material_3d.tres")
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
var reorgCd : float = 0.0
var lastAtk : String = ""
var floorY : float = 0.0
var walls : Array = []
var wallAngle : float = 0.0
var wallsUp : int = 0
var windowT : float = 0.0
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
	floorY = _floorLevel()
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE CUBICLE FARM")
	bossBar.visible = false
	bossIntro = CanvasLayer.new()
	bossIntro.set_script(introScript)
	add_child(bossIntro)
	bossIntro.camFocus = 0.1
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
	_raiseWalls(2)
	mode = "hover"
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
	var frac = float(health) / maxHealth
	if wallsUp < 3 and frac <= .75:
		_raiseWalls(3)
	if phase == 1 and frac <= phase2At:
		_enterPhase2()

func _enterPhase2():
	phase = 2
	atkGap *= .7
	memoCount += 2
	_raiseWalls(4)
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
		face._set_face("panic" if on else "ghost")
	if bossBar:
		if on:
			bossBar._setStatus("BREACHED", OPEN_COL, true)
		else:
			bossBar._setStatus("OPEN PLAN", SHUT_COL)

func _wallSpot(i : int, total : int) -> Dictionary:
	var ang = wallAngle + TAU * float(i) / float(total)
	var r = wallGap * 0.5 + wallThird * 0.5
	return {
		"pos": Vector3(cos(ang) * r, 0, sin(ang) * r),
		"yaw": -ang,
	}

func _buildWall(spot : Dictionary) -> StaticBody3D:
	var w = StaticBody3D.new()
	w.collision_layer = 17
	w.collision_mask = 0
	get_parent().add_child(w)
	w.global_position = Vector3(global_position.x, floorY + wallH * 0.5, global_position.z) + spot["pos"]
	w.rotation.y = spot["yaw"]
	var mesh = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(wallW, wallH, wallThird)
	mesh.mesh = bm
	mesh.material_override = wallMat
	w.add_child(mesh)
	var col = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = bm.size
	col.shape = sh
	w.add_child(col)
	add_collision_exception_with(w)
	mesh.scale = Vector3(1, .02, 1)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(mesh, "scale", Vector3.ONE, .45)
	walls.append(w)
	return w

func _raiseWalls(total : int):
	if dead or total <= wallsUp:
		return
	wallsUp = total
	for w in walls:
		if is_instance_valid(w):
			w.queue_free()
	walls.clear()
	for i in total:
		_buildWall(_wallSpot(i, total))
	Audio.play("slam", .7, -8.0)

func _liveWalls() -> Array:
	var out = []
	for w in walls:
		if is_instance_valid(w):
			out.append(w)
	return out

func _playerHigh() -> bool:
	if player == null or !is_instance_valid(player):
		return false
	return player.global_position.y >= floorY + breachHeight

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
			away = away.normalized() * 9.0 + Vector3(0, 7.5, 0)
			if bossIntro:
				bossIntro._play("THE CUBICLE FARM", "OPEN PLAN LIVING", self, away, 0)
			else:
				_onIntroDone()
		return
	if mode == "intro":
		return

	_drift(delta)
	_setExposed(_playerHigh())

	if exposed:
		windowT -= delta
		if windowT <= 0.0:
			windowT = windowReset
			stageDmg = 0.0

	if busy:
		return
	atkCd -= delta
	reorgCd -= delta
	if reorgCd <= 0.0 and _liveWalls().size() >= 3:
		reorgCd = reorgGap
		_reorg()
		return
	if atkCd <= 0.0:
		atkCd = atkGap
		_attack()

func _drift(delta : float):
	var to = player.global_position - global_position
	to.y = 0
	var d = to.length()
	var want = Vector3.ZERO
	if d > perchDrift + 1.0:
		want = to.normalized() * driftSpeed
	elif d < perchDrift - 1.0:
		want = -to.normalized() * driftSpeed
	velocity.x = move_toward(velocity.x, want.x, delta * 5.0)
	velocity.z = move_toward(velocity.z, want.z, delta * 5.0)
	var targY = floorY + hoverHeight + sin(animTime * 1.3) * .25
	velocity.y = (targY - global_position.y) * 2.5
	move_and_slide()
	if d > .3:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), delta * 4.0)

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	var lean = clamp(Vector2(velocity.x, velocity.z).length() * .03, 0.0, .12)
	body.position.y = bodyBaseY + sin(animTime * 1.6) * .14
	body.rotation.z = sin(animTime * 1.1) * .06 - lean
	body.rotation.x = sin(animTime * .8) * .045
	if exposed:
		body.rotation.y = sin(animTime * 9.0) * .06
	else:
		body.rotation.y = lerp(body.rotation.y, 0.0, clamp(delta * 5.0, 0.0, 1.0))

func _attack():
	var pool = ["memo", "deadline"]
	pool.erase(lastAtk)
	var pick = pool[randi() % pool.size()]
	lastAtk = pick
	match pick:
		"memo": _memoSweep()
		_: _deadline()

func _memoSweep():
	busy = true
	if bossBar:
		bossBar._setStatus("MEMO SWEEP" if !exposed else "BREACHED", OPEN_COL if exposed else SHUT_COL, exposed)
	util.spawnParticleAt(self, muzzleParticles, global_position)
	Audio.play("rifle", .5, -12.0)
	await get_tree().create_timer(.35).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	var base = randf() * TAU
	for i in memoCount:
		if dead or !is_instance_valid(self):
			return
		var ang = base + TAU * float(i) / float(memoCount)
		var r = wallGap * 0.5 + randf_range(1.5, 5.0)
		var at = Vector3(global_position.x + cos(ang) * r, floorY, global_position.z + sin(ang) * r)
		var spot = util.floorPoint(self, at, _rayIgnore())
		if spot == null:
			spot = at + Vector3(0, .05, 0)
		var m = runeScene.instantiate()
		m.warnTime = memoWarn
		m.damage = memoDamage
		get_parent().add_child(m)
		m.global_position = spot
		await get_tree().create_timer(.08).timeout

func _deadline():
	busy = true
	Audio.play("slam", .8, -6.0)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(body, "scale", Vector3(1.25, .7, 1.25), .22)
	tw.tween_property(body, "scale", Vector3.ONE, .18)
	await get_tree().create_timer(.4).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	var ring = ringScene.instantiate()
	ring.damage = ringDamage
	ring.expansionRate = ringRate
	ring.maxExpansion = ringMax
	ring.source = self
	get_parent().add_child(ring)
	ring.global_position = Vector3(global_position.x, floorY + .1, global_position.z)
	util.spawnParticleAt(self, burstParticles, global_position)

func _reorg():
	busy = true
	if bossBar:
		bossBar._setStatus("REORG", SHUT_COL, true)
	Audio.play("walljump", .6, -10.0)
	var live = _liveWalls()
	wallAngle += PI * 0.25
	var total = live.size()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN_OUT)
	for i in total:
		var spot = _wallSpot(i, total)
		var to = Vector3(global_position.x, floorY + wallH * 0.5, global_position.z) + spot["pos"]
		tw.tween_property(live[i], "global_position", to, reorgTime)
		tw.tween_property(live[i], "rotation:y", spot["yaw"], reorgTime)
	await get_tree().create_timer(reorgTime + .1).timeout
	if dead or !is_instance_valid(self):
		return
	busy = false
	_setExposed(_playerHigh())

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
	Audio.play("enemy_death", .8, 0.0)
	if bossBar:
		bossBar.visible = false
	if target and target.has_method("_onKill"):
		target._onKill()
	if target and target.has_method("_addShake"):
		target._addShake(.2)
	set_physics_process(false)
	for w in walls:
		if is_instance_valid(w):
			var mesh = w.get_child(0)
			var wt = create_tween()
			wt.set_trans(Tween.TRANS_BACK)
			wt.set_ease(Tween.EASE_IN)
			wt.tween_property(mesh, "scale", Vector3(1, .02, 1), .4)
			wt.tween_callback(w.queue_free)
	walls.clear()
	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.9, .9), randf_range(-.4, .8), randf_range(-.9, .9))
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
	for w in walls:
		if is_instance_valid(w):
			w.queue_free()
