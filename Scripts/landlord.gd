extends CharacterBody3D
func _landlord():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(.62,.25,1)
const CAST_COL = Color(1,.55,.08)
const SPELL_NAMES = {
	"repossession": "REPOSSESSION",
	"notices": "EVICTION NOTICE",
	"hike": "RENT HIKE",
	"tenants": "SUBLETTING",
	"blink": "RELOCATION",
	"foreclosure": "FORECLOSURE",
	"audit": "AUDIT",
	"sweep": "CLEARANCE",
	"deposit": "DEPOSIT WITHHELD",
}

@export var player : Node3D
@export var walls : Array[NodePath] = []
@export var scoreWorth = 10000
@export var health = 320
@export var sightRange : float = 30.0
@export var maxHit : float = 60.0
@export var phase2At : float = .5
@export var hoverHeight : float = 3.4
@export var driftSpeed : float = 2.2
@export var keepDist : float = 8.0
@export var castGap : float = 2.2
@export var recoverTime : float = .55
@export var runeWarn : float = 1.2
@export var runeDamage := 14
@export var runeCount : int = 3
@export var noticeCount : int = 3
@export var noticeSpread : float = .35
@export var foreclosureWarn : float = 1.1
@export var foreclosureEvery : int = 5
@export var hikeDamage := 16
@export var hikeRings : int = 2
@export var tenantCount : int = 2
@export var tenantMax : int = 4
@export var blinkRange : float = 9.0
@export var auditCount : int = 3
@export var auditSpeed : float = 16.0
@export var auditDamage := 12
@export var auditStep : float = .18
@export var sweepCount : int = 10
@export var sweepRadius : float = 8.0
@export var sweepWarn : float = .9
@export var sweepStep : float = .1
@export var depositDrain : float = 35.0
@export var depositWarn : float = 1.15

@onready var body = $body
@onready var shieldMesh = $shield/shieldMesh
@onready var shield = $shield
@onready var staff = $body/staff
@onready var staffOrb = $body/staff/orb
@onready var textSpawn = $textSpawn
@onready var noticeSpawn = $noticeSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var noticeScene = preload("res://ObjectScenes/evictionNotice.tscn")
@onready var runeScene = preload("res://ObjectScenes/runeMark.tscn")
@onready var ringScene = preload("res://ObjectScenes/slamRIng.tscn")
@onready var tenantScene = preload("res://ObjectScenes/Drone.tscn")
@onready var burstParticles = preload("res://Particles/pickupBurst.tscn")
@onready var trailParticles = preload("res://Particles/dashTrail.tscn")
@onready var hitParticles = preload("res://Particles/bulletImpact.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")
@onready var barScript = preload("res://Scripts/boss_bar.gd")
@onready var introScript = preload("res://Scripts/boss_intro.gd")

var maxHealth : float
var exposed = false
var dead = false
var phase = 1
var target
var gotShot = false
var aggro = false
var mode : String = "idle"
var castCd : float = 0.0
var castCount : int = 0
var clinkCd : float = 0.0
var animTime : float = 0.0
var floorY : float = 0.0
var shieldMat : StandardMaterial3D
var orbMat : StandardMaterial3D
var shieldTween : Tween
var shieldFlash : float = 0.0
var castGlow : float = 0.0
var bossBar
var bossIntro
var gone : Array = []
var tenants : Array = []
var lastSpell : String = ""

func _onIntroDone():
	if dead:
		return
	mode = "shielded"
	castCd = castGap
	if bossBar:
		bossBar.visible = true
		bossBar._setStatus("SHIELDED", SHUT_COL)

func _makeTarg(targ):
	gotShot = true
	target = targ
	aggro = true
	if player == null:
		player = targ

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = float(health)
	floorY = _floorLevel()
	if shieldMesh.material_override:
		shieldMesh.material_override = shieldMesh.material_override.duplicate()
		shieldMat = shieldMesh.material_override
	if staffOrb.material_override:
		staffOrb.material_override = staffOrb.material_override.duplicate()
		orbMat = staffOrb.material_override
	bossBar = CanvasLayer.new()
	bossBar.set_script(barScript)
	add_child(bossBar)
	bossBar._setName("THE LANDLORD")
	bossBar.visible = false
	bossIntro = CanvasLayer.new()
	bossIntro.set_script(introScript)
	add_child(bossIntro)
	bossIntro.done.connect(_onIntroDone)
	body._updateMat(1.0)
	exposed = true
	_setExposed(false)
	castCd = castGap
	await get_tree().physics_frame

func _floorLevel() -> float:
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3(0, -40, 0))
	ray.exclude = [self.get_rid()]
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position.y
	return global_position.y - hoverHeight

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	if !exposed:
		_clink()
		return
	dmg = min(dmg, maxHit)
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	body._hitPunch()
	_spawnParticleAt(hitParticles, textSpawn.global_position)
	_spawnDmgTxt(int(dmg))
	body._updateMat(clamp(float(health) / maxHealth, 0.0, 1.0))
	if bossBar:
		bossBar._setHealth(float(health) / maxHealth)
	if health <= 0:
		_die()
		return
	if phase == 1 and float(health) / maxHealth <= phase2At:
		_enterPhase2()

func _clink():
	shieldFlash = 1.0
	if clinkCd > 0.0:
		return
	clinkCd = .07
	Audio.play("enemy_hit", 1.6, -14.0)

func _spawnDmgTxt(dmg : int):
	var txt = dmgTxt.instantiate()
	get_parent().add_child(txt)
	txt.global_position = textSpawn.global_position
	txt.damage = dmg

func _enterPhase2():
	phase = 2
	castGap *= .6
	runeWarn *= .8
	runeCount += 2
	noticeCount += 2
	driftSpeed *= 1.3
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
	if player == null or !is_instance_valid(player):
		return
	if !aggro:
		if global_position.distance_to(player.global_position) <= sightRange:
			aggro = true
			mode = "intro"
			if bossIntro:
				var away = global_position - player.global_position
				away.y = 0
				if away.length() < .5:
					away = Vector3.BACK
				away = away.normalized() * 7.0 + Vector3(0, 7.5, 0)
				bossIntro.camFocus = 0.1
				bossIntro._play("THE LANDLORD", "SNEK & CO. PROPERTIES", self, away, 0)
			else:
				_onIntroDone()
		else:
			return
	if mode == "intro":
		return
	_drift(delta)
	if mode == "shielded":
		castCd -= delta
		if castCd <= 0.0:
			_beginCast()

func _drift(delta : float):
	var to = player.global_position - global_position
	to.y = 0
	var d = to.length()
	var want = Vector3.ZERO
	if d > keepDist + 1.0:
		want = to.normalized() * driftSpeed
	elif d < keepDist - 1.0:
		want = -to.normalized() * driftSpeed
	velocity.x = move_toward(velocity.x, want.x, delta * 6.0)
	velocity.z = move_toward(velocity.z, want.z, delta * 6.0)
	var targY = floorY + hoverHeight + sin(animTime * 1.4) * .3
	velocity.y = (targY - global_position.y) * 2.5
	move_and_slide()
	if d > .3:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), delta * 5.0)

func _setExposed(on : bool):
	if exposed == on:
		return
	exposed = on
	if orbMat != null:
		orbMat.emission = CAST_COL if on else SHUT_COL
		orbMat.emission_energy_multiplier = 6.0 if on else 1.2
	if on:
		_breakShield()
	else:
		_formShield()

func _breakShield():
	if shieldTween:
		shieldTween.kill()
	shieldMesh.visible = true
	Audio.play("enemy_hit", .45, -5.0)
	Audio.play("walljump", 1.5, -12.0)
	_spawnParticleAt(burstParticles, global_position)
	shieldTween = create_tween()
	shieldTween.set_parallel(true)
	shieldTween.set_trans(Tween.TRANS_BACK)
	shieldTween.set_ease(Tween.EASE_OUT)
	shieldTween.tween_property(shieldMesh, "scale", Vector3.ONE * 1.5, .22)
	shieldTween.tween_property(shieldMesh, "transparency", 1.0, .22)
	await shieldTween.finished
	if is_instance_valid(self) and exposed:
		shieldMesh.visible = false

func _formShield():
	if shieldTween:
		shieldTween.kill()
	shieldMesh.visible = true
	shieldMesh.scale = Vector3.ONE * 1.45
	shieldMesh.transparency = 1.0
	if shieldMat != null:
		shieldMat.emission = SHUT_COL
		shieldMat.emission_energy_multiplier = 1.0
	Audio.play("pickup", .55, -7.0)
	shieldTween = create_tween()
	shieldTween.set_parallel(true)
	shieldTween.set_trans(Tween.TRANS_BACK)
	shieldTween.set_ease(Tween.EASE_OUT)
	shieldTween.tween_property(shieldMesh, "scale", Vector3.ONE, .3)
	shieldTween.tween_property(shieldMesh, "transparency", 0.0, .3)

func _beginCast():
	mode = "casting"
	castCount += 1
	_setExposed(true)
	Audio.play("pickup", .7, -8.0)
	Audio.play("ui_hover", .5, -14.0)
	_spawnParticleAt(burstParticles, staffOrb.global_position)
	var spell = _pickSpell()
	lastSpell = spell
	if bossBar:
		bossBar._setStatus(SPELL_NAMES.get(spell, "CASTING"), OPEN_COL, true)
	match spell:
		"foreclosure":
			await _foreclosure()
		"notices":
			await _notices()
		"hike":
			await _rentHike()
		"tenants":
			await _summonTenants()
		"blink":
			await _blink()
		"audit":
			await _audit()
		"sweep":
			await _sweep()
		"deposit":
			await _deposit()
		_:
			await _repossession()
	if dead or !is_instance_valid(self):
		return
	mode = "recover"
	await get_tree().create_timer(recoverTime).timeout
	if dead or !is_instance_valid(self):
		return
	_setExposed(false)
	mode = "shielded"
	castCd = castGap
	if bossBar:
		bossBar._setStatus("SHIELDED", SHUT_COL)

func _pickSpell() -> String:
	if castCount > 0 and castCount % foreclosureEvery == 0 and _liveWalls().size() > 0:
		return "foreclosure"
	_pruneTenants()
	var pool = ["repossession", "notices", "hike", "blink", "audit", "sweep", "deposit"]
	if tenants.size() + tenantCount <= tenantMax:
		pool.append("tenants")
	pool.erase(lastSpell)
	return pool[randi() % pool.size()]

func _pruneTenants():
	var live = []
	for t in tenants:
		if is_instance_valid(t):
			live.append(t)
	tenants = live

func _rentHike():
	_staffRaise()
	Audio.play("rifle", .35, -8.0)
	for i in hikeRings:
		if dead or !is_instance_valid(self):
			return
		var pnt = _floorPoint(global_position)
		if pnt == null:
			return
		var ring = ringScene.instantiate()
		get_parent().add_child(ring)
		ring.global_position = pnt
		ring.source = self
		ring.damage = hikeDamage
		ring.expansionRate = 8.0
		ring.maxExpansion = 14.0
		Audio.play("slam", .9, -6.0)
		if player != null and player.has_method("_addShake"):
			player._addShake(.07)
		await get_tree().create_timer(.55).timeout
	await get_tree().create_timer(.25).timeout

func _summonTenants():
	_staffRaise()
	Audio.play("pickup", .5, -4.0)
	for i in tenantCount:
		if dead or !is_instance_valid(self) or player == null:
			return
		var ang = randf() * TAU
		var at = global_position + Vector3(cos(ang) * 4.0, 0, sin(ang) * 4.0)
		var t = tenantScene.instantiate()
		get_parent().add_child(t)
		t.global_position = at
		t.scoreWorth = 0
		if "player" in t:
			t.player = player
		if t.has_method("_makeTarg"):
			t._makeTarg(player)
		tenants.append(t)
		_spawnParticleAt(muzzleParticles, at)
		Audio.play("enemy_hit", .7, -8.0)
		await get_tree().create_timer(.25).timeout
	await get_tree().create_timer(.3).timeout

func _blocked(from : Vector3, to : Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	ray.exclude = _rayIgnore()
	return space.intersect_ray(ray).size() > 0

func _blinkDest():
	for i in 20:
		var r = blinkRange if i < 12 else blinkRange * .55
		var ang = randf() * TAU
		var at = player.global_position + Vector3(cos(ang) * r, 0, sin(ang) * r)
		var pnt = _floorPoint(at)
		if pnt == null or abs(pnt.y - floorY) > 1.2:
			continue
		var dest = Vector3(at.x, floorY + hoverHeight, at.z)
		if _blocked(player.global_position + Vector3(0, 1, 0), dest):
			continue
		return dest
	return null

func _blink():
	_staffRaise()
	Audio.play("dash", .8, -6.0)
	var oldPos = global_position
	await get_tree().create_timer(.22).timeout
	if dead or !is_instance_valid(self) or player == null:
		return
	_spawnParticleAt(muzzleParticles, oldPos)
	var pnt = _floorPoint(oldPos)
	if pnt != null:
		var m = runeScene.instantiate()
		get_parent().add_child(m)
		m.global_position = pnt
		m.warnTime = runeWarn * .8
		m.damage = runeDamage
	var dest = _blinkDest()
	if dest == null:
		await get_tree().create_timer(.35).timeout
		return
	_spawnParticleAt(burstParticles, oldPos)
	for i in 6:
		_spawnParticleAt(trailParticles, oldPos.lerp(dest, float(i) / 6.0))
	global_position = dest
	velocity = Vector3.ZERO
	_spawnParticleAt(muzzleParticles, global_position)
	_spawnParticleAt(burstParticles, global_position)
	Audio.play("walljump", .9, -6.0)
	Audio.play("dash", 1.2, -9.0)
	var pop = create_tween()
	pop.set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)
	body.scale = Vector3(.4, 1.5, .4)
	pop.tween_property(body, "scale", Vector3.ONE, .3)
	await get_tree().create_timer(.35).timeout

func _spawnParticleAt(scene, pos : Vector3):
	var p = scene.instantiate()
	get_parent().add_child(p)
	p.global_position = pos
	p.emitting = true

func _staffRaise():
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(staff, "rotation:x", -1.1, .22)
	tw.tween_property(staff, "rotation:x", 0.0, .3)
	_spawnParticleAt(muzzleParticles, staffOrb.global_position)
	Audio.play("ui_click", 1.5, -16.0)

func _repossession():
	_staffRaise()
	Audio.play("rifle", .45, -10.0)
	for i in runeCount:
		if player == null or !is_instance_valid(player):
			return
		var at = player.global_position
		if i > 0:
			var ang = randf() * TAU
			var r = randf_range(2.5, 6.0)
			at += Vector3(cos(ang) * r, 0, sin(ang) * r)
		var pnt = _floorPoint(at)
		if pnt != null:
			var m = runeScene.instantiate()
			get_parent().add_child(m)
			m.global_position = pnt
			m.warnTime = runeWarn
			m.damage = runeDamage
		await get_tree().create_timer(.14).timeout
		if dead or !is_instance_valid(self):
			return
	await get_tree().create_timer(runeWarn).timeout

func _notices():
	_staffRaise()
	for i in noticeCount:
		if player == null or !is_instance_valid(player):
			return
		Audio.play("rifle", .6, -12.0)
		var p = muzzleParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = noticeSpawn.global_position
		p.emitting = true
		var n = noticeScene.instantiate()
		get_parent().add_child(n)
		n.global_position = noticeSpawn.global_position
		n.target = player
		var aim = noticeSpawn.global_position.direction_to(player.global_position)
		aim.x += randf_range(-noticeSpread, noticeSpread)
		aim.z += randf_range(-noticeSpread, noticeSpread)
		n.dir = aim.normalized()
		add_collision_exception_with(n)
		n.add_collision_exception_with(self)
		await get_tree().create_timer(.22).timeout
		if dead or !is_instance_valid(self):
			return
	await get_tree().create_timer(.3).timeout

func _audit():
	_staffRaise()
	for i in auditCount:
		if player == null or !is_instance_valid(player):
			return
		Audio.play("rifle", .85, -9.0)
		var n = noticeScene.instantiate()
		get_parent().add_child(n)
		n.global_position = noticeSpawn.global_position
		n.target = null
		n.speed = auditSpeed
		n.turnRate = 0.0
		n.damage = auditDamage
		n.dir = noticeSpawn.global_position.direction_to(player.global_position + Vector3(0, .8, 0))
		add_collision_exception_with(n)
		n.add_collision_exception_with(self)
		_spawnParticleAt(muzzleParticles, noticeSpawn.global_position)
		await get_tree().create_timer(auditStep).timeout
		if dead or !is_instance_valid(self):
			return
	await get_tree().create_timer(.3).timeout

func _sweep():
	_staffRaise()
	Audio.play("rifle", .3, -9.0)
	var ang0 = randf() * TAU
	var spin = 1.0 if randf() < .5 else -1.0
	for i in sweepCount:
		if dead or !is_instance_valid(self):
			return
		var ang = ang0 + spin * (TAU / float(sweepCount)) * float(i)
		var at = global_position + Vector3(cos(ang) * sweepRadius, 0, sin(ang) * sweepRadius)
		var pnt = _floorPoint(at)
		if pnt != null:
			var m = runeScene.instantiate()
			get_parent().add_child(m)
			m.global_position = pnt
			m.warnTime = sweepWarn
			m.damage = runeDamage
		await get_tree().create_timer(sweepStep).timeout
	await get_tree().create_timer(sweepWarn).timeout

func _deposit():
	_staffRaise()
	Audio.play("ui_click", .6, -9.0)
	if player == null or !is_instance_valid(player):
		return
	var pnt = _floorPoint(player.global_position)
	if pnt == null:
		await get_tree().create_timer(.3).timeout
		return
	var m = runeScene.instantiate()
	m.drain = depositDrain
	get_parent().add_child(m)
	m.global_position = pnt
	m.warnTime = depositWarn
	await get_tree().create_timer(depositWarn + .25).timeout

func _liveWalls() -> Array:
	var live = []
	for w in walls:
		var node = get_node_or_null(w)
		if node != null and is_instance_valid(node) and !gone.has(node):
			live.append(node)
	return live

func _foreclosure():
	_staffRaise()
	var live = _liveWalls()
	if live.size() == 0:
		return
	var wall = live[randi() % live.size()]
	gone.append(wall)
	Audio.play("enemy_death", .5, -4.0)
	if player != null and player.has_method("_addShake"):
		player._addShake(.08)
	var mark = wall.get_node_or_null("Mesh")
	if mark:
		var tw = create_tween()
		tw.set_loops(3)
		tw.tween_property(mark, "transparency", .7, foreclosureWarn / 6.0)
		tw.tween_property(mark, "transparency", 0.0, foreclosureWarn / 6.0)
	await get_tree().create_timer(foreclosureWarn).timeout
	if dead or !is_instance_valid(self) or !is_instance_valid(wall):
		return
	Audio.play("slam", .7, -2.0)
	var p = dustParticles.instantiate()
	get_parent().add_child(p)
	p.global_position = wall.global_position
	p.emitting = true
	if player != null and player.has_method("_addShake"):
		player._addShake(.14)
	wall.queue_free()

func _rayIgnore() -> Array[RID]:
	var skip : Array[RID] = [self.get_rid()]
	if player != null and is_instance_valid(player):
		skip.append(player.get_rid())
	for t in tenants:
		if is_instance_valid(t) and t is CollisionObject3D:
			skip.append(t.get_rid())
	return skip

func _floorPoint(from : Vector3):
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, 3, 0), from + Vector3(0, -8, 0))
	ray.exclude = _rayIgnore()
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position + Vector3(0, .05, 0)
	return null

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	shield.rotation.y = animTime * 1.2
	shield.rotation.x = sin(animTime * .8) * .18
	body.position.y = sin(animTime * 1.6) * .12
	body.rotation.z = sin(animTime * 1.1) * .05
	shieldFlash = move_toward(shieldFlash, 0.0, delta * 4.5)
	if shieldMat != null and !exposed:
		shieldMat.emission_energy_multiplier = 1.0 + shieldFlash * 5.0
		shieldMat.emission = SHUT_COL.lerp(Color.WHITE, shieldFlash * .7)
	if orbMat != null and mode == "casting":
		orbMat.emission_energy_multiplier = 5.0 + sin(animTime * 20.0) * 2.0
		castGlow -= delta
		if castGlow <= 0.0:
			castGlow = .1
			_spawnParticleAt(trailParticles, staffOrb.global_position)

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
	if shieldTween:
		shieldTween.kill()
	shieldMesh.visible = true
	shieldMesh.transparency = 0.0
	Audio.play("enemy_hit", .4, -2.0)
	_spawnParticleAt(burstParticles, global_position)
	var sh = create_tween()
	sh.set_parallel(true)
	sh.set_trans(Tween.TRANS_BACK)
	sh.set_ease(Tween.EASE_OUT)
	sh.tween_property(shieldMesh, "scale", Vector3.ONE * 2.2, .3)
	sh.tween_property(shieldMesh, "transparency", 1.0, .3)

	var drop = create_tween()
	drop.set_parallel(true)
	drop.set_trans(Tween.TRANS_QUAD)
	drop.set_ease(Tween.EASE_IN)
	drop.tween_property(staff, "rotation:z", 2.4, .5)
	drop.tween_property(staff, "position:y", staff.position.y - 2.5, .5)

	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.7, .7), randf_range(-.4, .8), randf_range(-.7, .7))
		p.emitting = true
		Audio.play("enemy_death", randf_range(.6, .9), -6.0)
		_spawnParticleAt(trailParticles, global_position)
		await get_tree().create_timer(.09).timeout
		if !is_instance_valid(self):
			return
	_spawnParticleAt(burstParticles, global_position)
	Audio.play("slam", .7, -3.0)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .28)
	tw.tween_property(shieldMesh, "scale", Vector3.ZERO, .28)
	await tw.finished
	queue_free()
