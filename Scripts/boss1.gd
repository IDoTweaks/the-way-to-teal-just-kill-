extends CharacterBody3D
func _enemy(): pass
func _boss(): pass

@export var scoreWorth = 22000
@export var health = 900
@export var player : CharacterBody3D
@export_flags_3d_physics var wallLayer : int
@export var bossBar : ProgressBar
@export var bossName : Label
@export var finishOrb : Node3D

@onready var body = $body
@onready var shield = $Shield
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var shardScene = preload("res://ObjectScenes/bossShard.tscn")
@onready var chargerScene = preload("res://ObjectScenes/Charger.tscn")
@onready var bullet = preload("res://ObjectScenes/greenBullet.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")

const SHARD_COUNT = 4
const ORBIT_RADIUS = 12.0
const SHARD_HEIGHT = 5.0
const ARENA_RADIUS = 38.0

var maxHealth = 0
var phase = 1
var shielded = true
var shards = []
var dead = false
var damageable = false
var textActive = false
var txt
var animTime = 0.0
var baseBodyY = 0.0
var spin = 0.0
var fireCd = 2.0
var summonCd = 7.0
var slamCd = 4.0
var shockwaves = []
var blockFlash = 0.0

func _makeTarg(targ):
	pass

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	baseBodyY = body.position.y
	body._updateMat(0.0)
	if shield:
		shield.visible = true
	_updateBar()
	call_deferred("_initFight")

func _initFight():
	await get_tree().physics_frame
	if finishOrb:
		finishOrb.open = false
		finishOrb.visible = false
	damageable = true
	_spawnShards()

func _spawnShards():
	for i in SHARD_COUNT:
		var s = shardScene.instantiate()
		var ang = TAU * float(i) / float(SHARD_COUNT)
		s.core = self
		s.player = player
		s.wallLayer = wallLayer
		s.orbitAngle = ang
		s.orbitRadius = ORBIT_RADIUS
		s.orbitHeight = SHARD_HEIGHT
		s.fireGap = 2.6
		s.beamGap = 6.0
		get_parent().add_child(s)
		s.global_position = Vector3(global_position.x + cos(ang) * ORBIT_RADIUS, SHARD_HEIGHT, global_position.z + sin(ang) * ORBIT_RADIUS)
		shards.append(s)

func _onShardDown(s):
	shards.erase(s)
	_summonWave(2)
	Audio.play("enemy_death", 0.7, 0.0)
	if shards.is_empty() and phase == 1:
		_enterPhase2()

func _enterPhase2():
	phase = 2
	shielded = false
	if shield:
		shield.visible = false
	if bossName:
		bossName.text = "THE HEART OF THE GREEN - EXPOSED"
	fireCd = 1.5
	summonCd = 6.0
	slamCd = 3.0
	_addShakeSafe()

func _addShakeSafe():
	if player and player.has_method("_addShake"):
		player._addShake(0.18)

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	if shielded:
		blockFlash = 0.25
		Audio.play("enemy_hit", 1.4, -10.0)
		return
	health -= dmg
	Audio.play("enemy_hit", 1.0, -2.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._updateMat(1.0 - float(health) / float(maxHealth))
	else:
		_die()
	_updateBar()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(1.0)
	if shield:
		shield.visible = false
	Audio.play("enemy_death", 0.7, 2.0)
	if bossBar:
		bossBar.value = 0
	if bossName:
		bossName.text = "TEAL."
	_addShakeSafe()
	for i in 6:
		var p = explosionParticles.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-3, 3), randf_range(-2, 4), randf_range(-3, 3))
		p.emitting = true
	if finishOrb:
		finishOrb.global_position = global_position - Vector3(0, global_position.y - 1.5, 0)
		finishOrb.visible = true
		finishOrb.open = true
	queue_free()

func _updateBar():
	if bossBar:
		bossBar.max_value = maxHealth
		bossBar.value = max(health, 0)

func _summonWave(n):
	if dead:
		return
	for i in n:
		var c = chargerScene.instantiate()
		var ang = randf() * TAU
		c.wallLayer = wallLayer
		get_parent().add_child(c)
		c.global_position = global_position + Vector3(cos(ang), 0, sin(ang)) * 22.0 - Vector3(0, global_position.y - 2.0, 0)
		if c.has_method("_makeTarg"):
			c._makeTarg(player)
	Audio.play("slam", 1.2, -4.0)

func _coreVolley():
	if player == null:
		return
	var n = 16
	for i in range(n):
		var ang = TAU * float(i) / float(n) + spin
		var dir = Vector3(sin(ang), -0.35, cos(ang)).normalized()
		var b = bullet.instantiate()
		b.dest = global_position + dir * 60.0
		b.speed = 17.0
		b.damage = 14
		b.lifeTime = 5.0
		get_parent().add_child(b)
		b.global_position = global_position + dir * 3.0
	Audio.play("shotgun", 0.7, -6.0)

func _shockwave():
	var ring = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.85
	mesh.outer_radius = 1.0
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0, 0.9, 0.75, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0, 1, 0.8)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	ring.mesh = mesh
	ring.top_level = true
	add_child(ring)
	ring.global_position = Vector3(global_position.x, 0.4, global_position.z)
	shockwaves.append({"node": ring, "r": 2.0, "hit": false})
	Audio.play("slam", 0.8, -2.0)

func _updateShockwaves(delta):
	var center = Vector2(global_position.x, global_position.z)
	for w in shockwaves.duplicate():
		w["r"] += 20.0 * delta
		var r = w["r"]
		var ring = w["node"]
		if is_instance_valid(ring):
			ring.scale = Vector3(r, 1.0, r)
		if not w["hit"] and player != null:
			var pflat = Vector2(player.global_position.x, player.global_position.z)
			var d = pflat.distance_to(center)
			if abs(d - r) < 1.6 and player.global_position.y < global_position.y + 1.0:
				if player.has_method("_takeDamage"):
					player._takeDamage(18, global_position)
				w["hit"] = true
		if r > ARENA_RADIUS:
			if is_instance_valid(ring):
				ring.queue_free()
			shockwaves.erase(w)

func _physics_process(delta: float) -> void:
	if dead:
		return
	spin += delta * 0.6
	if phase == 2:
		var frac = clamp(float(health) / float(maxHealth), 0.0, 1.0)
		fireCd -= delta
		if fireCd <= 0:
			_coreVolley()
			fireCd = lerp(0.9, 2.0, frac)
		summonCd -= delta
		if summonCd <= 0:
			_summonWave(3)
			summonCd = lerp(6.0, 10.0, frac)
		slamCd -= delta
		if slamCd <= 0:
			_shockwave()
			slamCd = lerp(2.4, 4.5, frac)
	_updateShockwaves(delta)

func _process(delta: float) -> void:
	animTime += delta
	blockFlash = move_toward(blockFlash, 0.0, delta * 1.5)
	body.position.y = baseBodyY + sin(animTime * 1.4) * 0.25
	body.rotation.y = animTime * 0.4
	if shield and shield.visible:
		var s = 1.0 + sin(animTime * 3.0) * 0.03 + blockFlash * 0.25
		shield.scale = Vector3(s, s, s)
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
	txt.lookat = player
