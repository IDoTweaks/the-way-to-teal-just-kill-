extends CharacterBody3D
func _intern(): pass
func _enemy(): pass

const SPEED = 8.0
@export var scoreWorth = 4500
@export var health = 40
@onready var body = $body
@onready var cup = $body/cup
@onready var dmgTxt = preload("res://ObjectScenes/damageText.tscn")
@onready var textSpawn = $body/textSpawn
@export var navAgent : NavigationAgent3D
@export var accelaration = 12
@export var buffRange : float = 20.0
@export var fleeDist : float = 14.0
@export var player : CharacterBody3D
@onready var explosionParticles = preload("res://Particles/enemyExplode.tscn")
var particleInstance
var maxHealth : float = 40.0
var target
var mode : String = "idle"
var gotShot = false
var shouldMove = false
var textActive = false
var txt
var dead = false
var animTime : float = 0.0
var baseBodyY : float = 0.0
var buddy = null
var retargetCd : float = 0.0
var beamLine : MeshInstance3D
var beamMesh : ImmediateMesh
var beamMat : StandardMaterial3D

func _makeTarg(targ):
	gotShot = true
	target = targ
	mode = "flee"

func _ready() -> void:
	add_to_group("enemies")
	maxHealth = health
	body._updateMat(1)
	baseBodyY = body.position.y
	beamMesh = ImmediateMesh.new()
	beamMat = StandardMaterial3D.new()
	beamMat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	beamMat.albedo_color = Color(0, 1, 0.8)
	beamMat.emission_enabled = true
	beamMat.emission = Color(0, 1, 0.8)
	beamMat.emission_energy_multiplier = 3.0
	beamLine = MeshInstance3D.new()
	beamLine.mesh = beamMesh
	beamLine.material_override = beamMat
	beamLine.top_level = true
	add_child(beamLine)
	beamLine.global_transform = Transform3D.IDENTITY
	beamLine.visible = false
	await get_tree().physics_frame

func _activeTarget():
	if target != null and is_instance_valid(target):
		return target
	return player

func _takeDamage(dmg):
	_damage(dmg)

func _damage(dmg):
	health -= dmg
	Audio.play("enemy_hit", 1.2, -4.0)
	if !textActive:
		_spawnDmgTxt(dmg)
	else:
		_updateDmgTxt(dmg)
	if health >= 0:
		body._hitPunch()
		body._updateMat(health / maxHealth)
	else:
		_die()

func _dropBuff():
	if buddy != null and is_instance_valid(buddy) and buddy.has_method("_buff"):
		buddy._buff(false)
	buddy = null

func _die():
	if dead:
		return
	dead = true
	_dropBuff()
	if beamLine:
		beamLine.queue_free()
	body._updateMat(0)
	Audio.play("enemy_death", .7, -4.0)
	var tgt = _activeTarget()
	if tgt and tgt.has_method("_onKill"):
		tgt._onKill()
	particleInstance = explosionParticles.instantiate()
	particleInstance.position = global_position
	get_parent().add_child(particleInstance)
	particleInstance.emitting = true
	cup.reparent(get_parent())
	var ctw = create_tween()
	ctw.set_parallel(true)
	ctw.set_trans(Tween.TRANS_QUAD)
	ctw.set_ease(Tween.EASE_OUT)
	ctw.tween_property(cup, "position:y", cup.position.y + 2.4, .4)
	ctw.tween_property(cup, "rotation:x", cup.rotation.x + PI * 3.0, .8)
	ctw.chain().set_ease(Tween.EASE_IN)
	ctw.chain().tween_property(cup, "position:y", .1, .4)
	ctw.chain().tween_property(cup, "scale", Vector3.ZERO, .2)
	ctw.finished.connect(cup.queue_free)
	_deathAnim()

func _deathAnim():
	set_physics_process(false)
	velocity = Vector3.ZERO
	body._killTweens()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(body, "scale", Vector3.ZERO, .22)
	tw.tween_property(body, "rotation:z", body.rotation.z + PI * .7, .22)
	await tw.finished
	queue_free()

func _pickBuddy():
	var best = null
	var bestDist = buffRange
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or !is_instance_valid(e):
			continue
		if e.has_method("_intern") or !e.has_method("_buff"):
			continue
		if "dead" in e and e.dead:
			continue
		var d = global_position.distance_to(e.global_position)
		if d < bestDist:
			bestDist = d
			best = e
	if best != buddy:
		_dropBuff()
		buddy = best
		if buddy != null:
			buddy._buff(true)
			Audio.play("pickup", 1.6, -14.0)

func _drawBeam():
	if buddy == null or !is_instance_valid(buddy):
		beamLine.visible = false
		return
	beamLine.visible = true
	beamMesh.clear_surfaces()
	beamMesh.surface_begin(Mesh.PRIMITIVE_LINES)
	beamMesh.surface_add_vertex(cup.global_position)
	beamMesh.surface_add_vertex(buddy.global_position + Vector3(0, 1, 0))
	beamMesh.surface_end()
	beamMat.emission_energy_multiplier = 3.0 + sin(animTime * 12.0) * 1.5

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var tgt = _activeTarget()
	if tgt != null and is_instance_valid(tgt):
		if mode == "idle":
			mode = "flee"
		var dist = global_position.distance_to(tgt.global_position)
		if dist < fleeDist:
			var away = global_position - tgt.global_position
			away.y = 0
			away = away.normalized()
			var side = away.cross(Vector3.UP) * sin(animTime * 1.7) * .5
			var dir = (away + side).normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 25 * delta)
			velocity.z = move_toward(velocity.z, 0, 25 * delta)

	retargetCd -= delta
	if retargetCd <= 0:
		retargetCd = 2.0
		_pickBuddy()
	if buddy != null and !is_instance_valid(buddy):
		buddy = null

	var horizontal = Vector3(velocity.x, 0, velocity.z).normalized()
	if horizontal.length() > 0.1:
		var space = get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.create(global_position + horizontal * .6, global_position + horizontal * .6 + Vector3(0, -2, 0))
		ray.exclude = [self.get_rid()]
		if not space.intersect_ray(ray):
			velocity.x = 0
			velocity.z = 0

	move_and_slide()

func _process(delta: float) -> void:
	if dead:
		return
	var spd = Vector3(velocity.x, 0, velocity.z).length()
	animTime += delta * (1.0 + spd * .3)
	body.position.y = baseBodyY + abs(sin(animTime * 6.0)) * 0.12 * clamp(spd / SPEED, .2, 1.0)
	body.rotation.z = sin(animTime * 6.0) * 0.08
	cup.rotation.z = sin(animTime * 6.0 + 1.2) * .25
	_drawBeam()
	var flat = Vector3(velocity.x, 0, velocity.z)
	if flat.length() > .5:
		rotation.y = lerp_angle(rotation.y, atan2(-flat.x, -flat.z), delta * 9.0)
	elif _activeTarget() != null and is_instance_valid(_activeTarget()):
		var look = _activeTarget().global_position - global_position
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
		mode = "flee"

func _on_chase_body_exited(bod: Node3D) -> void:
	pass
