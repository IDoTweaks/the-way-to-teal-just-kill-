extends CharacterBody3D
func _sniper(): pass
func _enemy(): pass

@onready var attackTimer = $attackCd
@export var scoreWorth = 6000
@export var health = 70
@onready var body = $body
@onready var eye = $body/Eye
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@onready var muzzle = $body/muzzle
@export var sightDist : float = 60.0
@export var player : CharacterBody3D
@export_flags_3d_physics var wallLayer : int
@export var damage = 35
@export var chargeTime : float = 1.1
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var target
var mode : String = "idle"
var gotShot = false
var canAttack : bool = true
var charging : bool = false
var chargeTimer : float = 0.0
var textActive = false
var txt
var animTime : float = 0.0
var baseBodyY : float = 0.0
var fireKick : float = 0.0
var dead = false
var aimLine : MeshInstance3D
var aimMesh : ImmediateMesh
var aimMat : StandardMaterial3D

func _makeTarg(targ):
	gotShot = true
	target = targ

func _ready() -> void:
	add_to_group("enemies")
	body._updateMat(1)
	baseBodyY = body.position.y
	if eye.material_override:
		eye.material_override = eye.material_override.duplicate()
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
	await get_tree().physics_frame

func _activeTarget():
	if target != null and is_instance_valid(target):
		return target
	return player

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.0, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._updateMat(health / 70.0)
	else:
		_die()

func _die():
	if dead:
		return
	dead = true
	body._updateMat(0)
	Audio.play("enemy_death")
	if target and target.has_method("_onKill"):
		target._onKill()
	if aimLine:
		aimLine.queue_free()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	queue_free()

func _canSeePlayer():
	var tgt = _activeTarget()
	if tgt == null:
		return false
	if global_position.distance_to(tgt.global_position) > sightDist:
		return false
	return _hasLineOfSight(tgt)

func _hasLineOfSight(tgt):
	var spaceState := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, tgt.global_position)
	query.exclude = [self]
	query.collision_mask = wallLayer
	return spaceState.intersect_ray(query).is_empty()

func _drawAimLine():
	var tgt = _activeTarget()
	if tgt == null:
		return
	aimMesh.clear_surfaces()
	aimMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	aimMesh.surface_add_vertex(muzzle.global_position)
	aimMesh.surface_add_vertex(tgt.global_position)
	aimMesh.surface_end()

func _fire():
	charging = false
	fireKick = 1.0
	aimLine.visible = false
	attackTimer.start()
	Audio.play("shotgun", 0.8, -3.0)
	var tgt = _activeTarget()
	if tgt == null:
		return
	if _hasLineOfSight(tgt) and tgt.has_method("_takeDamage"):
		tgt._takeDamage(damage)
	_spawnBeam(muzzle.global_position, tgt.global_position)

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
	var tgt = _activeTarget()
	if charging:
		if tgt == null or not _hasLineOfSight(tgt):
			charging = false
			aimLine.visible = false
			attackTimer.start()
		else:
			chargeTimer -= delta
			_drawAimLine()
			if chargeTimer <= 0:
				_fire()
	elif canAttack and _canSeePlayer():
		charging = true
		chargeTimer = chargeTime
		aimLine.visible = true
		canAttack = false

func _process(delta: float) -> void:
	animTime += delta
	body.position.y = baseBodyY + sin(animTime * 1.6) * 0.05
	fireKick = move_toward(fireKick, 0.0, delta * 5.0)
	var chargeP = 0.0
	if charging:
		chargeP = clamp(1.0 - chargeTimer / max(chargeTime, 0.01), 0.0, 1.0)
	if eye.material_override:
		eye.material_override.emission_energy_multiplier = 4.0 + chargeP * 12.0 + fireKick * 10.0
	var leanPitch = -0.25 * chargeP + fireKick * 0.4
	body.rotation.x = lerp_angle(body.rotation.x, leanPitch, delta * 12.0)
	var tgt = _activeTarget()
	if tgt != null and is_instance_valid(tgt):
		var look = tgt.global_position - global_position
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
	txt.lookat = _activeTarget()

func _on_chase_body_entered(bod: Node3D) -> void:
	if bod.has_method("player"):
		target = bod

func _on_chase_body_exited(bod: Node3D) -> void:
	pass

func _on_attack_cd_timeout() -> void:
	canAttack = true
