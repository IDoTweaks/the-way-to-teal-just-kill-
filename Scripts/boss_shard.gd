extends CharacterBody3D
func _enemy(): pass
func _bossPart(): pass

@export var scoreWorth = 4000
@export var health = 130
@export var damage = 16
@export var beamDamage = 28
@export var player : CharacterBody3D
@export_flags_3d_physics var wallLayer : int

@onready var body = $body
@onready var muzzle = $muzzle
@onready var textSpawn = $textSpawn
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var bullet = preload("res://ObjectScenes/greenBullet.tscn")
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")

var core
var orbitAngle = 0.0
var orbitRadius = 12.0
var orbitHeight = 5.0
var orbitSpeed = 0.55
var fireGap = 2.6
var beamGap = 6.0
var maxHealth = 0
var dead = false
var textActive = false
var txt
var animTime = 0.0
var fireCd = 0.0
var beamCd = 0.0
var charging = false
var chargeTimer = 0.0
var chargeTime = 1.3
var lockTime = 0.4
var hitRadius = 1.3
var locked = false
var lockedTarget = Vector3.ZERO
var aimLine : MeshInstance3D
var aimMesh : ImmediateMesh
var aimMat : StandardMaterial3D

func _makeTarg(targ):
	pass

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(0.0)
	fireCd = fireGap * randf_range(0.4, 1.0)
	beamCd = beamGap * randf_range(0.6, 1.2)
	aimMesh = ImmediateMesh.new()
	aimMat = StandardMaterial3D.new()
	aimMat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	aimMat.albedo_color = Color(1, 0.12, 0.1)
	aimLine = MeshInstance3D.new()
	aimLine.mesh = aimMesh
	aimLine.material_override = aimMat
	aimLine.top_level = true
	add_child(aimLine)
	aimLine.global_transform = Transform3D.IDENTITY
	aimLine.visible = false

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	if dead:
		return
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._updateMat(1.0 - float(health) / float(maxHealth))
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(1.0)
	Audio.play("enemy_death")
	if aimLine:
		aimLine.queue_free()
	var p = explosionParticles.instantiate()
	p.position = global_position
	get_parent().add_child(p)
	p.emitting = true
	if core != null and is_instance_valid(core) and core.has_method("_onShardDown"):
		core._onShardDown(self)
	queue_free()

func _hasLineOfSight() -> bool:
	if player == null:
		return false
	var spaceState := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(muzzle.global_position, player.global_position)
	query.exclude = [self]
	query.collision_mask = wallLayer
	return spaceState.intersect_ray(query).is_empty()

func _volley():
	if player == null:
		return
	var n = 5
	var toP = player.global_position - muzzle.global_position
	var base = atan2(toP.x, toP.z)
	for i in range(n):
		var a = base + deg_to_rad((i - (n / 2)) * 9.0)
		var dir = Vector3(sin(a), 0, cos(a))
		var b = bullet.instantiate()
		b.dest = muzzle.global_position + dir * 60.0
		b.speed = 16.0
		b.damage = damage
		b.lifeTime = 5.0
		get_parent().add_child(b)
		b.global_position = muzzle.global_position
	Audio.play("shotgun", 0.8, -8.0)

func _startBeam():
	charging = true
	locked = false
	chargeTimer = chargeTime
	aimLine.visible = true

func _drawAimLineTo(pos : Vector3):
	aimMesh.clear_surfaces()
	aimMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	aimMesh.surface_add_vertex(muzzle.global_position)
	aimMesh.surface_add_vertex(pos)
	aimMesh.surface_end()

func _distToSegment(p : Vector3, a : Vector3, b : Vector3) -> float:
	var ab = b - a
	var t = 0.0
	var denom = ab.dot(ab)
	if denom > 0.0001:
		t = clamp((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _fireBeam():
	charging = false
	locked = false
	aimLine.visible = false
	aimMat.albedo_color = Color(1, 0.12, 0.1)
	Audio.play("shotgun", 0.7, -2.0)
	var origin = muzzle.global_position
	var dir = lockedTarget - origin
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	var endPoint = origin + dir * 300.0
	var spaceState := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, endPoint)
	query.exclude = [self]
	query.collision_mask = wallLayer
	var hit := spaceState.intersect_ray(query)
	if not hit.is_empty():
		endPoint = hit.position
	if player != null and player.has_method("_takeDamage"):
		if _distToSegment(player.global_position, origin, endPoint) <= hitRadius:
			player._takeDamage(beamDamage, global_position)
	_spawnBeam(origin, endPoint)

func _spawnBeam(a : Vector3, b : Vector3):
	var beam = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	var dist = a.distance_to(b)
	mesh.top_radius = 0.06
	mesh.bottom_radius = 0.06
	mesh.height = dist
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.15, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.1)
	mat.emission_energy_multiplier = 5.0
	beam.mesh = mesh
	beam.material_override = mat
	get_parent().add_child(beam)
	if dist > 0.001:
		var yd = (b - a).normalized()
		var xd = yd.cross(Vector3.UP)
		if xd.length() < 0.01:
			xd = yd.cross(Vector3.RIGHT)
		xd = xd.normalized()
		var zd = xd.cross(yd).normalized()
		beam.global_transform = Transform3D(Basis(xd, yd, zd), (a + b) * 0.5)
	get_tree().create_timer(0.22).timeout.connect(beam.queue_free)

func _physics_process(delta: float) -> void:
	if dead:
		return
	orbitAngle += orbitSpeed * delta
	var center = core.global_position if (core != null and is_instance_valid(core)) else global_position
	var pos = Vector3(center.x + cos(orbitAngle) * orbitRadius, orbitHeight, center.z + sin(orbitAngle) * orbitRadius)
	global_position = pos
	if charging:
		chargeTimer -= delta
		if not locked:
			if not _hasLineOfSight():
				charging = false
				aimLine.visible = false
				aimMat.albedo_color = Color(1, 0.12, 0.1)
				beamCd = beamGap
				return
			if player != null:
				lockedTarget = player.global_position
			_drawAimLineTo(lockedTarget)
			if chargeTimer <= lockTime:
				locked = true
				aimMat.albedo_color = Color(1, 0.85, 0.12)
		else:
			_drawAimLineTo(lockedTarget)
		if charging and chargeTimer <= 0:
			_fireBeam()
			beamCd = beamGap
	else:
		fireCd -= delta
		if fireCd <= 0 and _hasLineOfSight():
			_volley()
			fireCd = fireGap
		beamCd -= delta
		if beamCd <= 0 and _hasLineOfSight():
			_startBeam()

func _process(delta: float) -> void:
	animTime += delta
	body.rotation.y = animTime * 1.5
	if player != null and is_instance_valid(player):
		var look = player.global_position - global_position
		look.y = 0
		if look.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), delta * 6.0)
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
