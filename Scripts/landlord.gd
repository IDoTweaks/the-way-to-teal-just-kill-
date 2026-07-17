extends CharacterBody3D
func _landlord():pass
func _enemy():pass

const OPEN_COL = Color(0,1,.85)
const SHUT_COL = Color(.62,.25,1)
const CAST_COL = Color(1,.55,.08)

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
@export var foreclosureEvery : int = 4

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
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
@onready var muzzleParticles = preload("res://Particles/enemyMuzzle.tscn")
@onready var dustParticles = preload("res://Particles/landDust.tscn")
@onready var barScript = preload("res://Scripts/boss_bar.gd")

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
var bossBar
var gone : Array = []

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
			mode = "shielded"
			if bossBar:
				bossBar.visible = true
				bossBar._setStatus("SHIELDED", SHUT_COL)
		else:
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
	if shieldMat != null:
		shieldMat.emission = OPEN_COL if on else SHUT_COL
		shieldMat.emission_energy_multiplier = 2.8 if on else 1.0
	shieldMesh.visible = !on
	if orbMat != null:
		orbMat.emission = CAST_COL if on else SHUT_COL
		orbMat.emission_energy_multiplier = 6.0 if on else 1.2

func _beginCast():
	mode = "casting"
	castCount += 1
	_setExposed(true)
	Audio.play("pickup", .7, -8.0)
	if bossBar:
		bossBar._setStatus("CASTING", OPEN_COL, true)
	var spell = _pickSpell()
	match spell:
		"foreclosure":
			await _foreclosure()
		"notices":
			await _notices()
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
	if castCount % foreclosureEvery == 0 and _liveWalls().size() > 0:
		return "foreclosure"
	if randf() < .5:
		return "notices"
	return "repossession"

func _staffRaise():
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(staff, "rotation:x", -1.1, .22)
	tw.tween_property(staff, "rotation:x", 0.0, .3)

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
		await get_tree().create_timer(.22).timeout
		if dead or !is_instance_valid(self):
			return
	await get_tree().create_timer(.3).timeout

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

func _floorPoint(from : Vector3):
	var space = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(from + Vector3(0, 3, 0), from + Vector3(0, -8, 0))
	ray.exclude = [self.get_rid()]
	var hit = space.intersect_ray(ray)
	if hit:
		return hit.position + Vector3(0, .05, 0)
	return null

func _process(delta: float) -> void:
	if dead:
		return
	animTime += delta
	shield.rotation.y = animTime * 1.2
	body.position.y = sin(animTime * 1.6) * .12
	if orbMat != null and mode == "casting":
		orbMat.emission_energy_multiplier = 5.0 + sin(animTime * 20.0) * 2.0

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
	for i in 3:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-.7, .7), randf_range(-.4, .8), randf_range(-.7, .7))
		p.emitting = true
		await get_tree().create_timer(.09).timeout
		if !is_instance_valid(self):
			return
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .28)
	tw.tween_property(shieldMesh, "scale", Vector3.ZERO, .28)
	await tw.finished
	queue_free()
